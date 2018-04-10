fun! vm#region#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:Extend = { -> g:VM_Global.extend_mode }
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existant

" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global holds the Global class methods
" s:Regions contains the regions with their contents
" s:Matches contains the matches as they are registered with matchaddpos()
" s:v.matches contains the current matches as read with getmatches()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#region#new(cursor)
    return s:Region.new(a:cursor)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Region = {}

fun! s:Region.new(cursor)
    let R         = copy(self)
    let R.index   = len(s:Regions)
    let s:v.index = R.index

    let R.A_ = { -> eval(line2byte(R.l) + R.a) }
    let R.B_ = { -> eval(line2byte(R.L) + R.b) }

    if a:cursor    "/////////// CURSOR ///////////

        let R.l     = getpos(".")[1]        " line
        let R.L     = R.l
        let R.a     = getpos(".")[2]        " position
        let R.b     = R.a
        let R.w     = 1
        let R.A     = R.A_()                " byte offset
        let R.B     = R.A
        let R.h     = R.a                   " anchor (unused for cursors)
        let R.H     = R.A
        let R.txt   = ''
        let R.pat   = ''

    else            "/////////// REGION ///////////

        let R.l     = getpos("'[")[1]       " starting line
        let R.L     = getpos("']")[1]       " ending line
        let R.a     = getpos("'[")[2]       " begin
        let R.b     = getpos("']")[2]       " end
        let R.w     = R.b - R.a + 1         " width
        let R.A     = R.A_()                " byte offset a
        let R.B     = R.B_()                " byte offset b
        let R.h     = R.a                   " anchor
        let R.H     = R.A                   " anchor offset
        let R.txt   = getreg(s:v.def_reg)   " text content
        let R.pat   = R.pattern()           " associated search pattern
    endif

    "highlight entry
    let region  = [R.l, R.a, R.w]
    let cursor  = [R.l, R.b, 1]

    let match   = matchaddpos(g:VM_Selection_hl, [region], 30)
    let cursor  = matchaddpos('MultiCursor',     [cursor], 40)
    call add(s:Matches, [match, cursor])
    call add(s:Regions, R)
    call s:Global.update_cursor_highlight()

    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.empty() dict
    return self.A == self.B
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.pattern() dict
    """Find the search pattern associated with the region."""

    if empty(s:v.search) | return '' | endif

    for p in s:v.search | if self.txt =~ p | return p | endif | endfor
    return ''
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.remove() dict
    let i = self.index
    call remove(s:Regions, i)
    let m = s:Matches[i][0]
    let c = s:Matches[i][1]
    call remove(s:Matches, i)
    call matchdelete(m)
    call matchdelete(c)

    let s:v.matches = getmatches()
    call s:Global.update_indices()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region motions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"NOTE: these lambdas aren't really used much for now.

let s:forward   = {m -> index(['w', 'W', 'e', 'E', 'l', 'j', 'f', 't', '$'], m)  >= 0}
let s:backwards = {m -> index(['b', 'B', 'F', 'T', 'h', 'k', '0', '^'], m)       >= 0}
let s:simple    = {m -> index(['h', 'j', 'k', 'l'], m)                           >= 0}
let s:extreme   = {m -> index(['$', '0', '^'], m)                                >= 0}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move(motion) dict
    if s:v.move_from_back
        call self.move_from_back(a:motion)

    elseif s:backwards(a:motion[0])
        call self.move_back(a:motion)

    else
        call self.move_forward(a:motion)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_cursor(motion) dict
    """If not in extend mode, just move the cursors."""
    if s:Extend() | return | endif

    call cursor(self.l, self.a)
    exe "normal! ".a:motion

    let self.a = self.end()
    let self.b = self.a
    call self.update_vars()
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.end() dict
    """Ensure line boundaries aren't crossed."""
    let r = self | let p = getpos('.')[1]

    if     ( p > r.l ) | return col([r.l, '$'])-1
    elseif ( p < r.l ) | return col([r.l, 1])
    else               | return col('.')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extend mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_forward(motion) dict
    let r = self | if self.move_cursor(a:motion) | return | endif

    "move to the end of the region and perform the motion
    call cursor(r.l, r.b)
    exe "normal! ".a:motion

    let r.b = self.end()

    "merge to eol motion
    if a:motion == "\<End>"
        let s:v.merge_to_beol = 0
        let r.a = r.b
    endif

    call self.update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_from_back(motion) dict
    let r = self | if self.move_cursor(a:motion) | return | endif

    "set a mark and perform the motion
    call cursor(r.l, r.b+1)
    normal! m]
    call cursor(r.l, r.a)
    exe "normal! ".a:motion

    let r.a = self.end()

    call self.update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_back(motion) dict
    let r = self | if self.move_cursor(a:motion) | return | endif

    "move to the end of the region and perform the motion
    call cursor(r.l, r.b)
    exe "normal! ".a:motion

    "merge to bol motion
    if s:v.merge_to_beol
        let s:v.merge_to_beol = 0
        let s:v.direction = 1
        let r.a = 1
        let r.b = 1
    else
        let r.b = self.end()
    endif

    "collapse if there's been inversion
    if g:VM.keep_collapsed_while_moving_back
        if r.a > r.b | let r.a = r.b | endif | endif

    call self.update()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.yank()
    """Yank region content if in extend mode."""

    let r = self

    "if not in extend mode, the cursor will stay at r.a
    call cursor(r.l, r.a)
    if s:Extend()
        normal! m[
        call cursor(r.l, r.b+1)
        normal! m]`[y`]
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update(...) dict
    """Update the region position and text."""
    let r = self
    if a:0 | let l = a:1 | let L = a:2 | let a = a:3 | let b = a:4
    else   | let l = r.l | let L = r.L | let a = r.a | let b = r.b | endif

    let r.l   = l                 " starting line
    let r.L   = L                 " end line
    let r.a   = min([a, b])       " begin
    let r.b   = max([a, b])       " end

    call self.yank()
    call self.update_vars()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_vars() dict
    """Update the rest of the region vars."""

    let r         = self
    let s:v.index = r.index

    let r.A       = r.A_()
    let r.B       = r.B_()

    "update anchor if in cursor mode
    if !s:Extend() | let r.h = r.a | let r.H = r.A | endif

    let r.w       = r.b - r.a + 1
    let r.txt     = s:Extend()? getreg(s:v.def_reg) : ''
    let r.pat     = r.pattern()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_highlight() dict
    """Update the highlight match."""

    let r = self | let i = r.index

    let s:v.matches[i].pos1 = [r.l, r.a, r.w]
    let cursor = len(s:Matches) + i
    let s:v.matches[cursor].pos1 = [r.l, r.b, 1]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

