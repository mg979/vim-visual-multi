fun! vm#region#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:X    = { -> g:VM.extend_mode }
    let s:Byte = { pos -> s:Funcs.pos2byte(pos) }
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existant
" Each region will receive an individual incremental id, that will never change.

" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global    : holds the Global class methods
" s:Regions   : contains the regions with their contents
" s:Matches   : contains the matches as they are registered with matchaddpos()
" s:v.matches : contains the current matches as read with getmatches()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#region#new(cursor)
    return s:Region.new(a:cursor)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Region = {}

fun! s:Region.new(cursor)
    """Initialize region variables and methods.
    "
    " Uppercase variables (A,B,H) are for byte offsets, except L (end line).
    " R.edge() : returns the current active edge(a or b), based on direction.
    " R.char() : returns the char under the active edge, '' in cursor mode.
    " R.id     : is used to retrieve highlighting matches.
    " R.dir    : is the current orientation for the region.
    " R.txt    : is the text content.
    " R.pat    : is the search pattern associated with the region

    let R         = copy(self)
    let R.index   = len(s:Regions)
    let R.dir     = 1
    let R.id      = s:v.ID + 1

    "update region index and ID count
    let s:v.index = R.index | let s:v.ID += 1

    let R.A_   = { -> line2byte(R.l) + R.a }
    let R.B_   = { -> line2byte(R.L) + R.b }
    let R.edge = { -> R.dir ? R.b : R.a }
    let R.Edge = { -> R.edge() == R.b ? R.B : R.A }
    let R.char = { -> s:X()? getline(R.l)[R.edge()-1] : '' }

    if a:cursor    "/////////// CURSOR ///////////

        let R.l     = getpos('.')[1]        " line
        let R.L     = R.l
        let R.a     = getpos('.')[2]        " position
        let R.b     = R.a
        let R.w     = 1
        let R.A     = R.A_()                " byte offset
        let R.B     = R.A
        let R.h     = R.a                   " anchor (unused for cursors)
        let R.H     = R.A
        let R.txt   = R.char()              " character under cursor in extend mode
        let R.pat   = ''

    else            "/////////// REGION ///////////

        let R.l     = getpos("'[")[1]       " starting line
        let R.L     = getpos("']")[1]       " ending line
        let R.a     = getpos("'[")[2]       " begin
        let R.b     = getpos("']")[2]       " end
        let R.A     = R.A_()                " byte offset a
        let R.B     = R.B_()                " byte offset b
        let R.w     = R.B - R.A + 1         " width
        let R.h     = R.a                   " anchor
        let R.H     = R.A                   " anchor offset
        let R.txt   = getreg(s:v.def_reg)   " text content
        let R.pat   = R.pattern()           " associated search pattern
    endif

    call add(s:Regions, R)
    call R.highlight()
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
    call self.remove_highlight()
    call s:Global.update_indices()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region motions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"NOTE: these lambdas aren't really used much for now.

let s:forward   = { -> index(['w', 'W', 'e', 'E', 'l', 'j', 'f', 't', '$'], s:motion[0]) >=0}
let s:backwards = { -> index(['b', 'B', 'F', 'T', 'h', 'k', '0', '^'],      s:motion[0]) >=0}
let s:simple    = { -> index(['h', 'j', 'k', 'l'],                          s:motion[0]) >=0}
let s:extreme   = { -> index(['$', '0', '^'],                               s:motion[0]) >=0}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move(motion) dict
    let s:motion = a:motion
    if s:backwards()
        call self.move_back()
    else
        call self.move_forward()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_cursor() dict
    """If not in extend mode, just move the cursors."""
    if s:X() | return | endif

    call cursor(self.l, self.a)
    exe "keepjumps normal! ".s:motion

    let pos = getpos('.')
    let self.l = pos[1]
    let self.L = self.L
    let self.a = pos[2]
    let self.b = self.a
    call self.update_vars()
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:move(r)
    let r = a:r | let a = r.a | let b = r.b | let up = 0 | let down = 0

    "move the cursor to the current edge and perform the motion
    call cursor(r.l, r.edge())
    exe "keepjumps normal! ".s:motion

    "check the line
    let nl = line('.')

    if       nl < r.l   |   let up   = 1   |   let r.l = nl
    elseif   nl > r.L   |   let down = 1   |   let r.L = nl
    endif

    "get the new position and see if there's been inversion
    let new = col('.') | let New = s:Byte('.')

    let went_back  =   ( New <  r.H )  &&  ( New <  r.Edge() )
    let went_forth =   ( New >= r.H )  &&  ( New >= r.Edge() )

    "assign new values
    if went_back
        let r.dir = 0
        let r.a = new
        let r.b = r.h

    elseif went_forth
        let r.dir = 1
        let r.b = new
        let r.a = r.h

    elseif r.dir
        let r.b = new
    else
        let r.a = new
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extend mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_forward() dict
    let r = self | if self.move_cursor() | return | endif

    "move to the end of the region and perform the motion
    call s:move(r)

    "merge to eol motion
    if s:motion == "\<End>"
        let s:v.merge_to_beol = 0
        let r.a = r.b
    endif

    call self.update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_back() dict
    let r = self | if self.move_cursor() | return | endif

    "move to the end of the region and perform the motion
    call s:move(r)

    "merge to bol motion
    if s:v.merge_to_beol
        let s:v.merge_to_beol = 0
        call self.update(r.l, r.l, 1, 1)
    else
        call self.update()
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.yank() dict
    """Yank region content if in extend mode."""

    let r = self

    "if not in extend mode, the cursor will stay at r.a
    call cursor(r.l, r.a)
    if s:X()
        keepjumps normal! m[
        call cursor(r.L, r.b+1)
        keepjumps normal! m]`[y`]
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update(...) dict
    """Update the main region positions."""
    let r = self

    if a:0 | let r.l = a:1 | let r.L = a:2 | let r.a = a:3 | let r.b = a:4 | endif

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
    if !s:X() | let r.h = r.a | let r.H = r.A | endif

    let r.w       = r.b - r.a + 1
    let r.txt     = s:X()? getreg(s:v.def_reg) : ''
    let r.pat     = r.pattern()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.highlight() dict
    """Create the highlight entries."""

    let R      = self

    if !s:X()   "cursor mode
        let s:Matches[R.id] = {'region': [], 'cursor': 0}
        let s:Matches[R.id].cursor = matchaddpos('MultiCursor', [[R.l, R.a]], 40)
        return
    endif

    let max    = R.L - R.l
    let region = []
    let cursor = [R.l, R.edge(), 1]

    "single line skip the for loop
    if !max | let region = [[R.l, R.a, R.w]] | else | let max += 1 | endif

    "define highlight
    for n in range(max)
        let line = n==0  ? [R.l, R.a, len(getline(R.l))] :
              \    n<max ? [R.l + n]        :
              \            [R.L, 1, R.b]

        call add(region, line)
    endfor

    "build a list of highlight entries, one for each possible line
    let s:Matches[R.id] = {'region': [], 'cursor': 0}
    for line in region
        call add(s:Matches[R.id].region, matchaddpos(g:VM_Selection_hl, [line], 30))
    endfor
    let s:Matches[R.id].cursor = matchaddpos('MultiCursor', [cursor], 40)
    "echo max region s:Matches map(getmatches(), 'getmatches()[v:key].id')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.remove_highlight() dict
    """Remove the highlight entries."""

    "echo string(s:Matches)
    let matches = remove(s:Matches, self.id)
    let R       = matches.region
    let c       = matches.cursor

    for m in R | call matchdelete(m) | endfor | call matchdelete(c)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_highlight() dict
    """Update the region highlight."""

    if has_key(s:Matches, self.id) | call self.remove_highlight() | endif
    call self.highlight()
    let s:v.matches = getmatches()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

