""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Live Insert
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Live = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#live#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs
    let s:Search  = s:V.Search

    let s:R       = {      -> s:V.Regions               }
    let s:X       = {      -> g:VM.extend_mode          }
    let s:size    = {      -> line2byte(line('$') + 1)  }
    let s:Byte    = { pos  -> s:F.pos2byte(pos)         }
    let s:Pos     = { byte -> s:F.byte2pos(byte)        }
    let s:Cur     = { byte -> s:F.Cursor(byte)          }
    let s:newline = { m    -> index(['o', 'O'], m) >= 0 }

    let s:v.restart_insert = 0
    return s:Live
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.start(mode) dict
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'begin' is the initial ln/col, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------
    let I = self

    let I.mode      = a:mode
    let I.append    = index(['a', 'A'], I.mode) >= 0

    if s:V.Insert.is_active
        let R = s:G.select_region(I.index)
    else
        let R = s:G.select_region_at_pos('.')
    endif

    let I.index     = R.index
    let I.begin     = [R.l, I.append? R.a+1 : R.a]
    let I.size      = s:size()
    let I.cursors   = []
    let I.lines     = {}
    let I.change    = 0
    let s:C         = { -> I.cursors }
    let I.col       = getpos('.')[2]

    let s:V.Insert.is_active = 1

    call clearmatches()

    for r in s:R()
        let A = I.append? r.A+1 : r.A
        let C = s:Cursor.new(A, r.l, I.append? r.a+1 : r.a)

        let E = col([r.l, '$'])
        let eol = r.b == (E>1? E-1 : E)

        call add(I.cursors, C)

        "if (I.append && eol) || E == 1 | call s:V.Edit.extra_spaces(r, 0) | endif
        if I.append || eol | call s:V.Edit.extra_spaces(r, 0) | endif

        if !has_key(I.lines, r.l)
            let I.lines[r.l] = s:Line.new(r.l, C)
            let nth = 0 | let C.nth = 0
        else
            let nth += 1
            let C.nth = nth
            call add(I.lines[r.l].cursors, C)
        endif
        if C.index == I.index | let I.nth = C.nth | endif
    endfor

    "start tracking text changes
    call I.auto_start()

    inoremap <silent> <expr> <buffer> <esc>   pumvisible()?
                \ "\<esc>:call b:VM_Selection.Live.insert(1)\<cr>:call b:VM_Selection.Live.stop()\<cr>" :
                \ "\<esc>:call b:VM_Selection.Live.stop()\<cr>"

    call s:G.update_cursor_highlight()

    "start insert mode and break the undo point
    let keys = (I.mode=='c'? 'i': I.mode)."\<c-g>u"
    call feedkeys(keys, 'n')

    "check if there are insert marks that must be cleared
    if !empty(s:v.insert_marks)
        for l in keys(s:v.insert_marks)
            call setline(l, substitute(getline(l), '^\(\s*\)_', '\1', ''))
            call remove(s:v.insert_marks, l)
        endfor
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Live insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.insert(...) dict
    "TextChangedI

    let I        = self
    let L        = I.lines
    let ln       = getpos('.')[1]
    let pos      = I.begin[1]

    "popup eats one char on esc, give one more space
    let cur      = a:0? getpos('.')[2]+1 : getpos('.')[2]
    let pos      = pos + I.change*I.nth
    let I.change = cur - pos
    let text     = getline(ln)[(pos-1):(cur-2)]

    for l in keys(L)
        call L[l].update(I.change, text)
    endfor
    call cursor(ln, I.col)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.paste() dict
    call s:G.select_region(-1)
    let b:VM_Selection.Vars.restart_insert = 1
    call s:V.Edit.paste(1, 1, 1)
    let b:VM_Selection.Vars.restart_insert = 0
    call s:G.select_region(self.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.return() dict
    "NOTE: this function could probably be simplified, only 'end' seems necessary

    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    let app = self.append | let nR = len(s:R())-1

    for r in s:R()
        "these vars will be used to see what must be done (read NOTE)
        let eol = col([r.l, '$']) | let end = (r.a >= eol-1)
        let ind = indent(r.l)     | let ok = ind && !end

        call cursor(r.l, r.a)

        "append new line with mark/extra space if needed
        if ok          | call append(line('.'), '')
        elseif !ind    | call append(line('.'), ' ')
        else           | call append(line('.'), '_ ')
        endif

        "cut and paste below, or just move down if at eol, then reindent
        if !end && app | normal! ld$jp==
        elseif !end    | normal! d$jp==
        elseif end     | normal! j==
        endif

        "cursor line will be moved down by the next cursors
        call r.update_cursor([r.l + 1 + r.index, getpos('.')[2]])
        if !ok | call add(s:v.extra_spaces, nR - r.index) | endif

        "remember which lines have been marked
        if !ok | let s:v.insert_marks[r.l] = indent(r.l) | endif
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "reindent all and move back cursors to indent level
    normal ^
    for r in s:R()
        call cursor(r.l, r.a) | normal! ==
    endfor
    normal ^
    silent! undojoin
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.return_above() dict
    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    let nR = len(s:R())-1

    for r in s:R()
        call cursor(r.l, r.a)

        "append new line above, with mark/extra space
        call append(line('.')-1, '_ ')

        "move up, then reindent
        normal! k==

        "cursor line will be moved down by the next cursors
        call r.update_cursor([r.l + r.index, getpos('.')[2]])
        call add(s:v.extra_spaces, nR - r.index)

        "remember which lines have been marked
        let s:v.insert_marks[r.l] = indent(r.l)
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "move back all cursors to indent level
    normal ^
    silent! undojoin
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.stop() dict
    silent! iunmap <buffer> <esc>
    call self.auto_end() | let i = 0

    "should the cursor step back when exiting insert mode?
    let back = self.append

    for r in s:R()
        let c = self.cursors[i]
        let a = back? c.a-1 : c.a
        call r.update_cursor([c.l, a + self.change + self.change*c.nth])
        if r.index == self.index | let s:v.storepos = [r.l, r.a] | endif
        let i += 1
    endfor

    "NOTE: restart_insert is set in plugs, to avoid postprocessing, but it will
    "be reset on <esc>, in scripts check for Insert.is_active instead
    if s:v.restart_insert | let s:v.restart_insert = 0 | return | endif

    let s:v.eco = 1 | let s:V.Insert.is_active = 0

    call s:V.Edit.post_process(0,0)
    set hlsearch
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Cursor = {}

"--------------------------------------------------------------------------

"in Insert Mode we will forget about the regions, and work with cursors at
"byte offsets; from the final offset, we'll update the real regions later

"--------------------------------------------------------------------------


fun! s:Cursor.new(byte, ln, col) dict
    "Create new cursor.
    let C        = copy(self)
    let C.index  = len(s:Live.cursors)
    let C.A      = a:byte
    let C.txt    = ''
    let C.l      = a:ln
    let C.L      = a:ln
    let C.a      = a:col
    let C._a    = C.a
    let C.active = ( C.index == s:Live.index )
    let C.hl  = matchaddpos('MultiCursor', [[C.l, C.a]], 40)

    return C
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Cursor.update(l, c) dict
    "Update cursors positions and highlight.
    let C = self
    let C.A = s:Byte([C.l, a:c])
    let C._a = a:c

    call matchdelete(C.hl)
    let C.hl  = matchaddpos('MultiCursor', [[C.l, a:c]], 40)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Line class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Line = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Line.new(line, cursor) dict
    let L         = copy(self)
    let L.l       = a:line
    let L.txt     = getline(a:line)
    let L.cursors = [a:cursor]

    "check if there are insert marks that must be cleared
    if has_key(s:v.insert_marks, L.l)
        let L.txt = substitute(L.txt, '^\(\s*\)_', '\1', '')
    endif

    return L
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Line.update(change, text) dict
    let change = 0
    let text = self.txt
    let I    = s:V.Live

    for c in self.cursors
        let a = c.a>1? c.a-2 : c.a-1
        let b = c.a-1
        let t1   = text[:a+change]
        let t2   = text[b+change:]
        let text = t1 . a:text . t2
        if c.a==1 | let text = text[1:] | endif
        "echom t1 "|||" t2 "///" text
        let change += a:change
        call c.update(self.l, c.a+change)
        if c.index == I.index | let I.col = c._a | endif
    endfor
    call setline(self.l, text)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.auto_start() dict
    set nohlsearch
    augroup plugin-vm-insert
        au!
        au TextChangedI * call b:VM_Selection.Live.insert()
    augroup END
endfun

fun! s:Live.auto_end() dict
    augroup plugin-vm-insert
        au!
    augroup END
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_inserted_text(a, b)
    "Yank between the offsets and return the yanked text

    let pos = s:Pos(a:a)
    call cursor(pos[0], pos[1])
    normal! `[
    let pos = s:Pos(a:b)
    call cursor(pos[0], pos[1]+1)
    normal! `]`[y`]`]
    return getreg(s:v.def_reg)
endfun


