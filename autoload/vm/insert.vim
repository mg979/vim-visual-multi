""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Insert = {'index': -1, 'cursors': []}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#insert#init()
    let s:V    = b:VM_Selection
    let s:v    = s:V.Vars
    let s:G    = s:V.Global
    let s:F    = s:V.Funcs
    let s:v.restart_insert = 0
    let s:v.complete_done  = 0
    return s:Insert
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:R    = { -> s:V.Regions }
    let s:X    = { -> g:Vm.extend_mode }
    let s:size = { -> line2byte(line('$')) }
else
    let s:R    = function('vm#v74#regions')
    let s:X    = function('vm#v74#extend_mode')
    let s:size = function('vm#v74#size')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.key(type) abort
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
        call self.start()

    elseif a:type ==# 'O'
        call vm#commands#merge_to_beol(0, 0)
        call vm#icmds#return_above()
        call self.start()

    elseif a:type ==# 'a'
        if s:X()
            if s:v.direction | call vm#commands#invert_direction() | endif
            call s:G.change_mode()
            let s:v.direction = 1
        endif
        for r in s:R() | call s:V.Edit.extra_spaces.add(r) | endfor
        normal l
        call self.start()

    else
        if s:X()
            if !s:v.direction | call vm#commands#invert_direction() | endif
            call s:G.change_mode()
        endif

        call self.start()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.start() abort
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'begin' is the initial ln/col, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------
    let I = self
    let I._index = get(I, '_index', -1)

    " get winline and backup regions when insert mode is entered the first time
    if !exists('s:v.winline_insert')
      let s:v.winline_insert = winline()
      call s:G.backup_regions()
    endif

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
    let I.col       = getpos('.')[2]

    " remove regular regions highlight
    call s:G.remove_highlight()

    for r in s:R()
        let C = s:Cursor.new(r.A, r.l, r.a)

        let E = col([r.l, '$'])
        let eol = r.a == (E>1? E-1 : E)

        call add(I.cursors, C)

        if eol | call s:V.Edit.extra_spaces.add(r) | endif

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

    "start insert mode
    call feedkeys("i", 'n')

    "check if there are insert marks that must be cleared
    if !empty(s:v.insert_marks)
        for l in keys(s:v.insert_marks)
            call setline(l, substitute(getline(l), '^\(\s*\)°', '\1', ''))
            call remove(s:v.insert_marks, l)
        endfor
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode update
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.insert(...) abort
    """Update the text on TextChangedI event, and just after InsertLeave.

    call vm#comp#TextChangedI()  "compatibility tweaks

    let I        = self
    let L        = I.lines

    " this is the current cursor position
    let ln       = getpos('.')[1]
    let coln     = getpos('.')[2]

    " we're now evaluating the current (original) line
    " we're only interested in column changes, since we insert text horizontally

    " I.begin is the starting column, when insert mode is entered
    " I.change is the total length of the newly inserted text up to this moment
    " I.nth refers to the n. of cursors in the same line: it's 0 if there is only
    " a cursor, but if there are more cursors in the line, their changes add up
    " In fact, even if it's the original cursor, there may be cursors behind it,
    " and it will be 'pushed' forward by them

    " Given the above, the adjusted initial position will then be:
    "   initial position + ( current change  * number of cursors behind it)
    let pos      = I.begin[1] + I.change*I.nth

    " find out the actual text that has been inserted up to this point:
    " it's a slice of the current line, between the updated initial position
    " (pos) and the current cursor position (coln)

    " coln needs some adjustments though:
    "   in insert mode, 1 is subtracted to find the current cursor position
    "   but when insert mode stops (a:0 == 1) this isn't true
    let text     = getline(ln)[(pos-1):(coln-2+a:0)]

    " now update the current change: secondary cursors need this value updated
    let I.change = coln - pos + a:0

    " update the lines (also the current line is updated with setline())
    for l in sort(keys(L))
        call L[l].update(I.change, text)
    endfor

    " put the cursor where it should stay after the lines update
    call cursor(ln, I.col)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode stop
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.stop(...) abort
    " text can be updated again after complete_done
    if &modified && s:v.complete_done
      call self.insert(1)
    endif
    let s:v.complete_done = 0

    call self.clear_hi() | call self.auto_end() | let i = 0

    for r in s:R()
        let c = self.cursors[i]
        call r.update_cursor([c.l, c.a + self.change + self.change*c.nth])
        if r.index == self.index | let s:v.storepos = [r.l, r.a] | endif
        let i += 1
    endfor

    "NOTE: restart_insert is set in plugs, to avoid postprocessing, but it will be reset on <esc>
    "check for s:v.insert instead, it will be true until insert session is really over
    if s:v.restart_insert | let s:v.restart_insert = 0 | return | endif

    let s:v.eco = 1 | let s:v.insert = 0

    call s:step_back()
    call s:V.Edit.post_process(0,0)
    set hlsearch

    let &indentkeys = s:v.indentkeys
    let &synmaxcol = s:v.synmaxcol

    "reindent all and adjust cursors position, only if filetype/options allow
    if s:do_reindent() | call s:V.Edit.run_normal('==', {'recursive': 0, 'stay_put': 1}) | endif

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

fun! s:Insert.clear_hi() abort
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


fun! s:Cursor.new(byte, ln, col) abort
    "Create new cursor.
    let C        = copy(self)
    let C.index  = len(s:Insert.cursors)
    let C.A      = a:byte
    let C.txt    = ''
    let C.l      = a:ln
    let C.L      = a:ln
    let C.a      = a:col
    let C._a     = C.a
    let C.active = ( C.index == s:Insert.index )
    let C.hl     = matchaddpos('MultiCursor', [[C.l, C.a]], 40)

    return C
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Cursor.update(l, c) abort
    "Update cursors positions and highlight.
    let C = self
    let C.A = s:F.pos2byte([C.l, a:c])
    let C._a = a:c

    call matchdelete(C.hl)
    let C.hl  = matchaddpos('MultiCursor', [[C.l, a:c]], 40)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Line class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Line = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Line.new(line, cursor) abort
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

fun! s:Line.update(change, text) abort
    let change   = 0
    let text     = self.txt
    let I        = s:V.Insert

    for c in self.cursors
        let a    = c.a > 1 ? (c.a - 2) : (c.a - 1)
        let b    = c.a - 1
        let t1   = text[:(a+change)]
        let t2   = text[(b+change):]
        let text = t1 . a:text . t2
        if c.a==1 | let text = text[1:] | endif
        "echom t1 "|||" t2 "///" text
        let change += a:change
        call c.update(self.l, c.a + change)
        if c.index == I.index | let I.col = c._a | endif
    endfor
    call setline(self.l, text)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.auto_start() abort
    set nohlsearch
    augroup VM_insert
        au!
        au TextChangedI * call b:VM_Selection.Insert.insert()
        au InsertLeave  * call b:VM_Selection.Insert.stop()
        au CompleteDone * let s:v.complete_done = 1
    augroup END
endfun

fun! s:Insert.auto_end()
    autocmd! VM_insert
    augroup! VM_insert
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

fun! s:step_back()
    """Go back one char after exiting insert mode, as vim does.
    for r in s:R()
        if r.a != col([r.l, '$']) && r.a > 1
            call r.shift(-1,-1)
        endif
    endfor
endfun
