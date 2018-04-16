fun! vm#region#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search
    let s:Edit    = s:V.Edit

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
" s:v.matches : contains the current matches as read with getmatches()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#region#new(cursor, ...)
    if !a:0 | let R = s:Region.new(a:cursor)
    else    | let R = s:Region.new(a:cursor, a:1, a:2, a:3, a:4)
    endif

    "update region index and ID count
    let s:v.index = R.index | let s:v.ID += 1

    "keep regions list ordered
    if empty(s:Regions) || s:Regions[s:v.index-1].A < R.A
        call add(s:Regions, R)
    else
        let i = 0
        for r in s:Regions
            if r.A > R.A
                call insert(s:Regions, R, r.index)
                break
            endif
            let i += 1
        endfor
        let s:v.index = i
        call s:Global.update_indices()
    endif
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Region = {}

fun! s:Region.new(cursor, ...)
    """Initialize region variables and methods.
    "
    " Uppercase variables (A,B,K) are for byte offsets, except L (end line).

    " a/b/k/l/L    : start, end, anchor, first line, end line
    " R.cur_col()  : returns the current cursor column(a or b), based on direction.
    " R.cur_Col()  : cur_col() in byte offset form
    " R.cur_ln()   : the line where cur_col() is located
    " R.char()     : returns the char under the active head, '' in cursor mode.
    " R.id         : is used to retrieve highlighting matches.
    " R.dir        : is the current orientation for the region.
    " R.txt        : is the text content.
    " R.pat        : is the search pattern associated with the region
    " R.matches    : holds the highlighting matches

    let R         = copy(self)
    let R.index   = len(s:Regions)
    let R.dir     = 1
    let R.id      = s:v.ID + 1

    let R.A_      = { -> line2byte(R.l) + R.a }
    let R.B_      = { -> line2byte(R.L) + R.b }
    let R._a      = { -> byte2line(R.A) + R.a }
    let R._b      = { -> byte2line(R.B) + R.b }
    let R.cur_ln  = { -> R.dir ? R.L : R.l }
    let R.cur_col = { -> R.dir ? R.b : R.a }
    let R.cur_Col = { -> R.cur_col() == R.b ? R.B : R.A }
    let R.char    = { -> s:X()? getline(R.l)[R.cur_col()-1] : '' }


    if a:cursor        "/////////// CURSOR ////////////

        let R.l     = getpos('.')[1]        " line
        let R.L     = R.l
        let R.a     = getpos('.')[2]        " position
        let R.b     = R.a
        let R.w     = 1
        let R.h     = 0
        let R.A     = R.A_()                " byte offset
        let R.B     = R.A
        let R.k     = R.a                   " anchor (unused for cursors)
        let R.K     = R.A
        let R.txt   = R.char()              " character under cursor in extend mode
        let R.pat   = ''


    elseif !a:0        "/////////// REGION ////////////

        let R.l     = getpos("'[")[1]       " starting line
        let R.L     = getpos("']")[1]       " ending line
        let R.a     = getpos("'[")[2]       " begin
        let R.b     = getpos("']")[2]       " end
        let R.A     = R.A_()                " byte offset a
        let R.B     = R.B_()                " byte offset b
        let R.w     = R.B - R.A + 1         " width
        let R.h     = R.L - R.l             " height
        let R.k     = R.a                   " anchor
        let R.K     = R.A                   " anchor offset
        let R.txt   = getreg(s:v.def_reg)   " text content
        let R.pat   = R.pattern()           " associated search pattern


    else               "///////// FROM ARGS ///////////

        let R.l     = a:1
        let R.L     = a:4
        let R.a     = a:2
        let R.b     = a:3
        let R.A     = R.A_()
        let R.B     = R.B_()
        let R.w     = R.B - R.A + 1
        let R.h     = R.L - R.l
        let R.k     = R.a
        let R.K     = R.A
        let R.txt   = getline(R.l)[R._a():R._b()]
        let R.pat   = s:Funcs.get_pattern(R.txt)
    endif

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
    call self.remove_highlight()
    let R = remove(s:Regions, i)
    call s:Global.update_indices()
    return R
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
    let self.L = self.l
    let self.a = pos[2]
    let self.b = self.a
    call self.update_vars()
    return 1
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.keep_line(ln) dict
    """Ensure line boundaries aren't crossed."""
    let r = self

    if     ( a:ln > r.l ) | call cursor ( r.l, col([r.l, '$'])-1 )
    elseif ( a:ln < r.l ) | call cursor ( r.l, col([r.l, 1]) )
    else                  | call cursor ( r.l, col('.') )
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:move(r)
    let r = a:r | let a = r.a | let b = r.b | let up = 0 | let down = 0

    "move the cursor to the current head and perform the motion
    call cursor(r.cur_ln(), r.cur_col())
    exe "keepjumps normal! ".s:motion

    "in cursor mode, just set new positions
    if !s:X() | let p = getpos('.')
        call r.update_cursor(p[1], p[2]) | return | endif

    "check the line
    let nl = line('.')

    if !g:VM.multiline  | call r.keep_line(nl)

    elseif   nl < r.l                        |   let r.l = nl
    elseif   nl > r.L                        |   let r.L = nl
    elseif   nl > r.l && r.cur_ln() == r.l   |   let r.l = nl
    elseif   nl < r.L && r.cur_ln() == r.L   |   let r.L = nl
    endif

    "get the new position and see if there's been inversion
    let new = col('.') | let New = s:Byte('.')

    let went_back  =   ( New <  r.K )  &&  ( New <  r.cur_Col() )
    let went_forth =   ( New >= r.K )  &&  ( New >= r.cur_Col() )

    "assign new values
    if went_back
        let r.dir = 0
        let r.a = new
        let r.b = r.k

    elseif went_forth
        let r.dir = 1
        let r.b = new
        let r.a = r.k

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
        silent keepjumps normal! m]`[y`]
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_cursor(ln, col) dict
    let r = self
    let r.l = a:ln | let r.a = a:col
    let r.L = r.l  | let r.b = r.a
    let r.k = r.b  | let r.w = 1
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
    if !s:X() | let r.k = r.a | let r.K = r.A | let r.L = r.l | endif

    let r.w       = r.B - r.A + 1
    let r.h       = r.L - r.l
    let r.txt     = s:X()? getreg(s:v.def_reg) : ''
    let r.pat     = r.pattern()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.highlight() dict
    """Create the highlight entries."""

    let R      = self

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    if !s:X()   "cursor mode
        let R.matches        = {'region': [], 'cursor': 0}
        let R.matches.cursor = matchaddpos('MultiCursor', [[R.l, R.a]], 40)
        return
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    let max    = R.L - R.l
    let region = []
    let cursor = [R.cur_ln(), R.cur_col()]

    "single line skip the for loop
    if !max | let region = [[R.l, R.a, R.w]] | else | let max += 1 | endif

    "define highlight
    for n in range(max)
        let line = n==0    ? [R.l, R.a, len(getline(R.l))] :
              \    n<max-1 ? [R.l + n]        :
              \              [R.L, 1, R.b]

        call add(region, line)
    endfor

    "build a list of highlight entries, one for each possible line
    let R.matches        = {'region': [], 'cursor': 0}
    for line in region
        call add(R.matches.region, matchaddpos(g:VM_Selection_hl, [line], 30))
    endfor
    let R.matches.cursor = matchaddpos('MultiCursor', [cursor], 40)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.remove_highlight() dict
    """Remove the highlight entries."""

    let r       = self.matches.region
    let c       = self.matches.cursor

    for m in r | call matchdelete(m) | endfor | call matchdelete(c)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_highlight() dict
    """Update the region highlight."""

    call self.remove_highlight()
    call self.highlight()
    let s:v.matches = getmatches()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

