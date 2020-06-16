
fun! vm#region#init() abort
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X = { -> g:Vm.extend_mode }
let s:R = { -> s:V.Regions }



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existent at position.

" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:V.Global    : holds the Global class methods
" s:V.Regions   : contains the regions with their contents


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! vm#region#new(cursor, ...) abort
    " Create region from marks, offsets or positions.

    "----------------------------------------------------------------------

    if a:0
        if a:0 == 2             "making a new region from offsets
            let a = byte2line(a:1) | let c = a:1 - line2byte(a) + 1
            let b = byte2line(a:2) | let d = a:2 - line2byte(b) + 1

        else                    "making a new region from positions
            let a = a:1 | let b = a:2 | let c = a:3 | let d = a:4
        endif
    endif

    "----------------------------------------------------------------------

    let cursor = a:cursor || ( a:0 && c==d && a==b )          "cursor or region?

    if !g:Vm.buffer | call vm#init_buffer(cursor) | endif     "activate if needed

    if !a:0 | let R = s:Region.new(cursor)                    "create region
    else    | let R = s:Region.new(0, a, b, c, d)
    endif

    "----------------------------------------------------------------------

    "update region index and ID count
    let s:v.index = R.index | let s:v.ID += 1

    "keep regions list ordered
    if empty(s:R()) || s:R()[s:v.index-1].A < R.A
        call add(s:R(), R)
    else
        let i = 0
        for r in s:R()
            if r.A > R.A
                call insert(s:R(), R, i)
                break
            endif
            let i += 1
        endfor
        let s:v.index = i
        call s:G.update_indices(i)
    endif

    call s:G.update_cursor_highlight()
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Region = {}


fun! s:Region.new(cursor, ...) abort
    " Initialize region variables and methods.
    "
    " Uppercase variables (A,B,K) are for byte offsets, except L (end line).

    " a/b/k/l/L    : start, end, anchor, first line, end line
    " R.cur_col()  : returns the current cursor column(a or b), based on direction.
    " R.cur_Col()  : cur_col() in byte offset form
    " R.cur_ln()   : the line where cur_col() is located
    " R.char()     : returns the char under the active head, '' in cursor mode.
    " R.id         : an individual incremental id, that will never change.
    " R.dir        : is the current orientation for the region.
    " R.txt        : is the text content.
    " R.pat        : is the search pattern associated with the region
    " R.matches    : holds the highlighting matches

    let R         = copy(self)
    let R.index   = len(s:R())
    let R.dir     = s:v.direction
    let R.id      = s:v.ID + 1

    let R.matches = {'region': [], 'cursor': 0}

    if !a:0                "/////// FROM MAPPINGS ///////

        call s:region_vars(R, a:cursor)

    else                   "///////// FROM ARGS ///////////

        call s:region_vars(R, a:cursor, a:1, a:2, a:3, a:4)
    endif

    call add(s:v.IDs_list, R.id)

    if !s:v.eco
        call R.highlight()
    endif
    call R.update_bytes_map()

    return R
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region methods
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Region.empty() abort
    return self.A == self.B
endfun


fun! s:Region.A_() abort
    return line2byte(self.l) + self.a - 1
endfun


fun! s:Region.B_() abort
    " Last byte of the last character in the region.
    " This will be greater than the column, if character is multibyte.
    let bytes = len(self.txt) ? strlen(self.txt[-1:-1]) : 1
    return line2byte(self.L) + self.b + bytes - 2
endfun


fun! s:Region.cur_ln() abort
    return self.dir ? self.L : self.l
endfun


fun! s:Region.cur_col() abort
    return self.dir ? self.b : self.a
endfun


fun! s:Region.cur_Col() abort
    return self.cur_col() == self.b ? self.B : self.A
endfun


fun! s:Region.char() abort
    return s:X()? s:F.char_at_pos(self.l, self.cur_col()) : ''
endfun


fun! s:Region.shift(x, y) abort
    " Shift region offsets by integer values.
    "TODO: this will surely cause trouble in insert mode with multibyte chars
    "all r.shift() in insert mode should be replaced with r.update_cursor()
    let r = self

    let r.A += a:x | let r.B += a:y

    let r.l = byte2line(r.A)
    let r.L = byte2line(r.B)
    let r.a = r.A - line2byte(r.l) + 1
    let r.b = r.B - line2byte(r.L) + 1

    if !s:v.eco | call r.update() | endif
    return [r.l, r.L, r.a, r.b]
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remove region
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Region.remove() abort
    " Remove a region and its id, then update indices.
    call self.remove_highlight()
    call remove(s:R(), self.index)
    call remove(s:v.IDs_list, index(s:v.IDs_list, self.id))

    if len(s:R()) | call s:G.update_indices()
    else          | let s:v.index = -1
    endif

    if s:v.index >= len(s:R()) | let s:v.index = len(s:R()) - 1 | endif
    return self
endfun


fun! s:Region.clear(...) abort
    " Called if it's necessary to clear the byte map as well.
    call self.remove_from_byte_map(a:0)
    return self.remove()
endfun


fun! s:Region.remove_from_byte_map(all) abort
    " Remove a region from the bytes map.
    if !s:X() | return | endif

    if a:all
        for b in range(self.A, self.B) | call remove(s:V.Bytes, b) | endfor
    else
        for b in range(self.A, self.B)
            if s:V.Bytes[b] > 1 | let s:V.Bytes[b] -= 1
            else                | call remove(s:V.Bytes, b)
            endif
        endfor
    endif
endfun




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region motions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Region.move(...) abort
    " Move cursors, or extend regions by motion.
    let s:motion = a:0? a:1 : s:v.motion

    if !s:X()
        call s:move_cursor(self)
    else
        call s:move_region(self)
    endif
endfun


fun! s:Region.set_vcol(...) abort
    " Set vertical column if motion is j or k, and vcol not previously set.
    if !s:vertical()
        let self.vcol = 0
    elseif !self.vcol
        let self.vcol = virtcol('.')
    endif
endfun


fun! s:vertical() abort
    return index(['j', 'k'], s:motion[0]) >=0
endfun


fun! s:move_cursor(r) abort
    " If not in extend mode, just move the cursors.

    call cursor(a:r.l, a:r.a)
    call a:r.set_vcol()
    exe "keepjumps normal! ".s:motion

    "keep line or column
    if s:vertical()       | call s:keep_vertical_col(a:r)
    elseif !s:v.multiline | call s:keep_line(a:r, line('.'))
    endif

    call a:r.update_cursor_pos()
endfun


fun! s:keep_line(r, ln) abort
    " Ensure line boundaries aren't crossed. Force cursor merging.
    let r = a:r

    if     ( a:ln > r.l ) | call cursor ( r.l, col([r.l, '$'])-1 ) | let s:v.merge = s:X()? s:v.merge : 1
    elseif ( a:ln < r.l ) | call cursor ( r.l, col([r.l, 1]) )     | let s:v.merge = s:X()? s:v.merge : 1
    else                  | call cursor ( r.l, col('.') )
    endif
endfun


fun! s:keep_vertical_col(r) abort
    " Keep the vertical column if moving vertically.
    let vcol    = a:r.vcol
    let lnum    = line('.')
    let endline = (col('$') > 1)? col('$') - 1 : 1

    if ( vcol < endline )
        call cursor ( lnum, vcol )
    elseif ( a:r.cur_col() < endline )
        call cursor ( lnum, endline )
    endif
endfun


fun! s:move_region(r) abort
    " Perform the motion.
    let r = a:r | let a = r.a | let b = r.b | let up = 0 | let down = 0

    "move the cursor to the current head and perform the motion
    call cursor(r.cur_ln(), r.cur_col())
    call a:r.set_vcol()
    exe "keepjumps normal! ".s:motion

    if s:vertical() | call s:keep_vertical_col(r) | endif

    "check the line
    let nl = line('.')

    if !s:v.multiline  | call s:keep_line(r, nl)

    elseif   nl < r.l                        |   let r.l = nl
    elseif   nl > r.L                        |   let r.L = nl
    elseif   nl > r.l && r.cur_ln() == r.l   |   let r.l = nl
    elseif   nl < r.L && r.cur_ln() == r.L   |   let r.L = nl
    endif

    "get the new position and see if there's been inversion
    let newcol = col('.')
    if !s:v.multiline
        let went_back  =   newcol < r.k
        let went_forth =   newcol > r.k
    else
        let New = s:F.curs2byte()
        let went_back  =   ( New <  r.K )  &&  ( New <  r.cur_Col() )
        let went_forth =   ( New >= r.K )  &&  ( New >= r.cur_Col() )
    endif

    "assign new values
    if went_back
        let r.dir = 0
        let r.a = newcol
        let r.b = r.k

    elseif went_forth
        let r.dir = 1
        let r.b = newcol
        let r.a = r.k

    elseif r.dir
        let r.b = col('.')
    else
        let r.a = col('.')
    endif

    call r.update_region()
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Region.update() abort
    " Update region.
    if s:X() | call self.update_region()
    else     | call self.update_cursor()
    endif
endfun


fun! s:Region.update_cursor(...) abort
    " Update cursor vars from position [line, col] or offset.
    let r = self

    if a:0 && !type(a:1)
        let r.l = byte2line(a:1)
        let r.a = a:1 - line2byte(r.l) + 1
    elseif a:0
        let r.l = a:1[0]
        let r.a = a:1[1]
    endif

    call s:fix_pos(r)
    call self.update_vars()
endfun


fun! s:Region.update_cursor_pos() abort
    " Update cursor to current position.
    let [ self.l, self.a ] = getpos('.')[1:2]
    call s:fix_pos(self)
    call self.update_vars()
endfun


fun! s:Region.update_content() abort
    " Get region content if in extend mode.
    let r = self
    call cursor(r.l, r.a)   | keepjumps normal! m[
    call cursor(r.L, r.b+1) | silent keepjumps normal! m]`[y`]
    let r.txt = getreg(s:v.def_reg)

    if s:v.multiline && r.b == col([r.L, '$'])
        let r.txt .= "\n"
    else
        " if last character is multibyte, it won't be yanked, add it manually
        let lastchar = s:F.char_at_pos(r.L, r.b)
        if strlen(lastchar) > 1
            let r.txt .= lastchar
        endif
    endif
    let r.pat = s:pattern(r)
endfun


fun! s:Region.update_region(...) abort
    " Update the main region positions.
    let r = self

    if a:0 == 4
        let [ r.l, r.L, r.a, r.b ] = [ a:1, a:2, a:3, a:4 ]
    endif

    call s:fix_pos(r)
    call self.update_content()
    call self.update_vars()
endfun


fun! s:Region.update_vars() abort
    " Update the rest of the region variables.

    let r         = self
    let s:v.index = r.index

    "   "--------- cursor mode ----------------------------

    if !s:X()
        let r.L   = r.l              | let r.b = r.a
        let r.A   = r.A_()           | let r.B = r.A
        let r.k   = r.a              | let r.K = r.A
        let r.w   = 0                | let r.h = 0
        let r.txt = ''               | let r.pat = s:pattern(r)

        "--------- extend mode ----------------------------

    else
        let r.A   = r.A_()           | let r.B = r.B_()
        let r.w   = r.B - r.A + 1    | let r.h = r.L - r.l
        let r.k   = r.dir? r.a : r.b | let r.K   = r.dir? r.A : r.B

        call r.update_bytes_map()
    endif
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Region.highlight() abort
    " Create the highlight entries.

    if s:v.eco | return | endif
    let R = self

    "------------------ cursor mode ----------------------------

    if !s:X()
        let R.matches.cursor = matchaddpos('MultiCursor', [[R.l, R.a]], 40)
        return
    endif

    "------------------ extend mode ----------------------------

    let max    = R.L - R.l
    let region = []
    let cursor = [R.cur_ln(), R.cur_col()]

    "skip the for loop if single line
    if !max | let region = [[R.l, R.a, R.w]] | else | let max += 1 | endif

    "define highlight
    for n in range(max)
        let line =    n==0    ? [R.l, R.a, len(getline(R.l))] :
                    \ n<max-1 ? [R.l + n] :
                    \           [R.L, 1, R.b]

        call add(region, line)
    endfor

    "build a list of highlight entries, one for each possible line
    for line in region
        call add(R.matches.region, matchaddpos(g:Vm.hi.extend, [line], 30))
    endfor
    let R.matches.cursor = matchaddpos('MultiCursor', [cursor], 40)
endfun


fun! s:Region.remove_highlight() abort
    " Remove the highlight entries.
    let r       = self.matches.region
    let c       = self.matches.cursor

    for m in r | silent! call matchdelete(m) | endfor
    silent! call matchdelete(c)
endfun


fun! s:Region.update_highlight() abort
    " Update the region highlight.
    call self.remove_highlight()
    call self.highlight()
endfun


fun! s:Region.update_bytes_map() abort
    " Update bytes map for region.
    if !s:X() | return | endif

    for b in range(self.A, self.B)
        let s:V.Bytes[b] = get(s:V.Bytes, b, 0) + 1
    endfor
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:pattern(r) abort
    " Find the search pattern associated with the region.

    if empty(s:v.search) | return s:V.Search.escape_pattern(a:r.txt) | endif

    for p in s:v.search
        if a:r.txt =~ p | return p | endif
    endfor

    "return current search pattern in regex mode
    if !has_key(a:r, 'pat')
        return s:v.using_regex ? s:v.search[0] : ''
    endif

    "return current pattern if one is present (in cursor mode text is empty)
    return a:r.pat
endfun


fun! s:fix_pos(r) abort
    " Fix positions at end of line.
    let r = a:r
    let eol = col([r.l, '$']) - 1
    let eoL = col([r.L, '$']) - 1

    if !s:v.multiline
        if r.a > eol    | let r.a = eol? eol : 1 | endif
        if r.b > eoL    | let r.b = eoL? eoL : 1 | endif
    else
        if r.a > eol+1  | let r.a = eol? eol+1 : 1 | endif
        if r.b > eoL+1  | let r.b = eoL? eoL+1 : 1 | endif
    endif
endfun


fun! s:region_vars(r, cursor, ...) abort
    " Update region variables.
    let R = a:r

    if !a:0 && a:cursor    "/////////// CURSOR ////////////

        let R.l     = line('.')
        let R.L     = R.l
        let R.a     = col('.')
        let R.b     = R.a

        call s:fix_pos(R)

        let R.txt   = R.char()              " character under cursor in extend mode
        let R.pat   = s:pattern(R)

        let R.A     = R.A_()                " byte offset a
        let R.B     = s:X() ? R.B_() : R.A  " byte offset b
        let R.w     = R.B - R.A + 1         " width
        let R.h     = R.L - R.l             " height
        let R.k     = R.dir? R.a : R.b      " anchor
        let R.K     = R.dir? R.A : R.B      " anchor offset
        let R.vcol  = 0                     " vertical column

    elseif !a:0            "/////////// REGION ////////////

        let R.l     = line("'[")            " starting line
        let R.L     = line("']")            " ending line
        let R.a     = col("'[")             " begin
        let R.b     = col("']")             " end

        call s:fix_pos(R)

        let R.txt   = getreg(s:v.def_reg)   " text content
        let R.pat   = s:pattern(R)          " associated search pattern

        let R.A     = R.A_()                " byte offset a
        let R.B     = R.B_()                " byte offset b
        let R.w     = R.B - R.A + 1         " width
        let R.h     = R.L - R.l             " height
        let R.k     = R.dir? R.a : R.b      " anchor
        let R.K     = R.dir? R.A : R.B      " anchor offset
        let R.vcol  = 0                     " vertical column

    else                   "///////// FROM ARGS ///////////

        let R.l     = a:1
        let R.L     = a:2
        let R.a     = a:3
        let R.b     = a:4

        call s:fix_pos(R)
        call R.update_content()

        let R.A     = R.A_()                " byte offset a
        let R.B     = R.B_()                " byte offset b
        let R.w     = R.B - R.A + 1         " width
        let R.h     = R.L - R.l             " height
        let R.k     = R.dir? R.a : R.b      " anchor
        let R.K     = R.dir? R.A : R.B      " anchor offset
        let R.vcol  = 0                     " vertical column
    endif
endfun


" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
