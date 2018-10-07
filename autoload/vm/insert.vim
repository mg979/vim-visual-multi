""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Insert = {'index': -1, 'cursors': [], 'append': 0}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#insert#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R       = {      -> s:V.Regions               }
    let s:X       = {      -> g:VM.extend_mode          }
    let s:Byte    = { pos  -> s:F.pos2byte(pos)         }
    let s:Pos     = { byte -> s:F.byte2pos(byte)        }
    let s:Cur     = { byte -> s:F.Cursor(byte)          }
    let s:size    = {      -> line2byte(line('$') + 1) }

    let s:v.restart_insert = 0
    return s:Insert
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.key(type) dict
    call vm#comp#icmds()  "compatibility tweaks

    if a:type ==# 'I'
        call vm#commands#merge_to_beol(0, 0)
        call self.key('i')

    elseif a:type ==# 'A'
        call vm#commands#merge_to_beol(1, 0)
        call self.key('a')

    elseif a:type ==# 'o'
        call vm#commands#merge_to_beol(1, 0)
        call vm#icmds#return()
        call self.start(0)

    elseif a:type ==# 'O'
        call vm#commands#merge_to_beol(0, 0)
        call vm#icmds#return_above()
        call self.start(0)

    elseif a:type ==# 'a'
        if s:X()
            if s:v.direction        | call vm#commands#invert_direction() | endif
            call s:G.change_mode()  | let s:v.direction = 1               | endif

        for r in s:R() | call s:V.Edit.extra_spaces.add(r) | endfor
        normal l
        let self.append = 1
        call self.start(1)

    else
        if s:X()
            if !s:v.direction       | call vm#commands#invert_direction() | endif
            call s:G.change_mode()  | endif

        call self.start(0)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.start(append) dict
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'begin' is the initial ln/col, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------
    let I = self
    let I._index = get(I, '_index', -1)

    " get winline when insert mode is entered the first time
    if !exists('s:v.winline_insert') | let s:v.winline_insert = winline() | endif

    " check synmaxcol settings
    if !s:v.insert
        if g:VM_disable_syntax_in_imode
            let &synmaxcol = 1
        elseif g:VM_dynamic_synmaxcol && s:v.index > g:VM_dynamic_synmaxcol
            let scol = 40 - s:v.index + g:VM_dynamic_synmaxcol
            let &synmaxcol = scol>1? scol : 1
        endif
    endif

    if s:v.insert
        let i = I.index >= len(s:R())? len(s:R())-1 : I.index
        let R = s:G.select_region(i)
    elseif g:VM_pick_first_after_n_cursors && len(s:R()) > g:VM_pick_first_after_n_cursors
        let self._index = s:v.index
        let R = s:G.select_region(0)
    elseif g:VM_use_first_cursor_in_line
        let R = s:G.select_region_at_pos('.')
        let ix = s:G.lines_with_regions(0, R.l)[R.l][0]
        let R = s:G.select_region(ix)
    else
        let R = s:G.select_region_at_pos('.')
    endif

    " restore winline anyway, because it could have been auto-restarted
    call s:F.Scroll.force(s:v.winline_insert)

    let I.index     = R.index
    let I.begin     = [R.l, R.a]
    let I.size      = s:size()
    let I.cursors   = []
    let I.lines     = {}
    let I.change    = 0
    let s:C         = { -> I.cursors }
    let I.col       = getpos('.')[2]

    " remove regular regions highlight
    call s:G.remove_highlight()

    for r in s:R()
        let C = s:Cursor.new(r.A, r.l, r.a)

        let E = col([r.l, '$'])
        let eol = r.a == (E>1? E-1 : E)

        call add(I.cursors, C)

        "if (I.append && eol) || E == 1 || Key == 'l' | call s:V.Edit.extra_spaces(r, 0) | endif
        if eol && !a:append | call s:V.Edit.extra_spaces.add(r) | endif

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
    let s:v.insert = 1 | call I.auto_start()

    "change cursor highlight
    call s:G.update_cursor_highlight()

    "disable indentkeys
    set indentkeys=

    "start insert mode and break the undo point
    call feedkeys("i\<c-g>u", 'n')

    "check if there are insert marks that must be cleared
    if !empty(s:v.insert_marks)
        for l in keys(s:v.insert_marks)
            call setline(l, substitute(getline(l), '^\(\s*\)°', '\1', ''))
            call remove(s:v.insert_marks, l)
        endfor
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.insert(...) dict
    "TextChangedI

    call vm#comp#TextChangedI()  "compatibility tweaks

    let I        = self
    let L        = I.lines
    let ln       = getpos('.')[1]
    let pos      = I.begin[1]

    let cur      = getpos('.')[2]
    let pos      = pos + I.change*I.nth
    let I.change = cur - pos
    let text     = getline(ln)[(pos-1):(cur-2)]

    for l in keys(L)
        call L[l].update(I.change, text)
    endfor
    call cursor(ln, I.col)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.stop() dict
    call self.clear_hi() | call self.auto_end() | let i = 0

    for r in s:R()
        let c = self.cursors[i]
        call r.update_cursor([c.l, c.a + self.change + self.change*c.nth])
        if r.index == self.index | let s:v.storepos = [r.l, r.a] | endif
        let i += 1
    endfor

    "NOTE: restart_insert is set in plugs, to avoid postprocessing, but it will be reset on <esc>
    "check for s:v.insert instead, it will be true until insert session is really over
    if s:v.restart_insert
        let s:v.restart_insert = 0 | return | endif

    let s:v.eco = 1 | let s:v.insert = 0

    if self.append | call s:back() | endif
    call s:V.Edit.post_process(0,0)
    set hlsearch

    let &indentkeys = s:v.indentkeys
    let &synmaxcol = s:v.synmaxcol

    "reindent all and adjust cursors position, only if filetype/optioons allow
    if s:do_reindent() | call s:V.Edit.run_normal('==', 0, 1, 0) | endif

    if g:VM_reselect_first_insert
        call s:G.select_region(0)
    elseif self._index >= 0
        call s:G.select_region(self._index)
    else
        call s:G.select_region(self.index)
    endif

    " now insert mode has really ended, restore winline and clear variable
    if !g:VM_reselect_first_insert
        call s:F.Scroll.force(s:v.winline_insert)
    endif
    unlet s:v.winline_insert
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.clear_hi() dict
    """Clear cursors highlight.
    if s:v.clearmatches
        call clearmatches()
    else
        for c in self.cursors
            call matchdelete(c.hl)
        endfor
    endif
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
    let C.index  = len(s:Insert.cursors)
    let C.A      = a:byte
    let C.txt    = ''
    let C.l      = a:ln
    let C.L      = a:ln
    let C.a      = a:col
    let C._a    = C.a
    let C.active = ( C.index == s:Insert.index )
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
        let L.txt = substitute(L.txt, '^\(\s*\)°', '\1', '')
    endif

    return L
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Line.update(change, text) dict
    let change = 0
    let text = self.txt
    let I    = s:V.Insert

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

fun! s:Insert.auto_start() dict
    set nohlsearch
    augroup plugin-vm-insert
        au!
        au TextChangedI * call b:VM_Selection.Insert.insert()
        au CompleteDone * call b:VM_Selection.Insert.insert()
        au InsertLeave  * call b:VM_Selection.Insert.stop()
    augroup END
endfun

fun! s:Insert.auto_end() dict
    augroup plugin-vm-insert
        au!
    augroup END
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_inserted_text(a, b)
    "UNUSED: Yank between the offsets and return the yanked text

    let pos = s:Pos(a:a)
    call cursor(pos[0], pos[1])
    normal! `[
    let pos = s:Pos(a:b)
    call cursor(pos[0], pos[1]+1)
    normal! `]`[y`]`]
    return getreg(s:v.def_reg)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:do_reindent()
    """Check if lines must be reindented when exiting insert mode.
    if empty(&ft) | return | endif

    return index(vm#comp#no_reindents(), &ft) < 0 &&
                \ index(g:VM_reindent_filetype, &ft) >= 0 ||
                \ g:VM_reindent_all_filetypes
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:back()
    for r in s:R()
        if r.a != col([r.l, '$']) && r.a > 1
            call r.bytes([-1,-1])
        endif
    endfor

    let s:V.Insert.append = 0
endfun
