""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Insert = {'index': -1, 'cursors': [], 'replace': 0, 'type': ''}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#insert#init() abort
    " Init script variables.
    let s:V    = b:VM_Selection
    let s:v    = s:V.Vars
    let s:G    = s:V.Global
    let s:F    = s:V.Funcs
    let s:v.restart_insert = 0
    return s:Insert
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:R = { -> s:V.Regions }
let s:X = { -> g:Vm.extend_mode }



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode start
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.key(type) abort
    " Starting insert mode with a key (i,I,a,A...), make adjustments if needed.
    if empty(self.type)
        let self.type = a:type
    endif

    if self.replace
        call s:G.one_region_per_line()
    endif

    call vm#comp#icmds()        "compatibility tweaks
    call s:map_single_mode(0)

    if a:type ==# 'I'
        call vm#commands#merge_to_beol(0)
        call self.key('i')

    elseif a:type ==# 'A'
        call vm#commands#merge_to_beol(1)
        call self.key('a')

    elseif a:type ==# 'o'
        call vm#commands#merge_to_beol(1)
        call vm#icmds#insert_line(0)
        call self.start(1)

    elseif a:type ==# 'O'
        call vm#commands#merge_to_beol(0)
        call vm#icmds#insert_line(1)
        call self.start(1)

    elseif a:type ==# 'a'
        if s:X()
            if s:v.direction | call vm#commands#invert_direction() | endif
            call s:G.change_mode()
            let s:v.direction = 1
        endif
        for r in s:R() | call s:V.Edit.extra_spaces.add(r) | endfor
        call vm#commands#motion('l', 1, 0, 0)
        call self.start(1)

    else
        if s:X()
            if !s:v.direction | call vm#commands#invert_direction() | endif
            call s:G.change_mode()
        endif

        call self.start()
    endif
endfun


fun! s:Insert.start(...) abort
    " Initialize and then start insert mode.
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'begin' is the initial ln/col, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------
    call s:G.merge_cursors()

    let I = self
    let I._index = get(I, '_index', -1)

    let R = I.apply_settings()

    let I.index     = R.index
    let I.begin     = [R.l, R.a]
    let I.cursors   = []
    let I.lines     = {}
    let I.change    = 0         " text change, only if g:VM_live_editing
    let I.col       = col('.')
    let I.reupdate  = v:false   " set by InsertCharPre and CompleteDone

    " remove current regions highlight
    call s:G.remove_highlight()

    " create cursors and line objects
    for r in s:R()
        let C = s:Cursor.new(r.l, r.a)
        call add(I.cursors, C)

        " if cursor is at EOL/empty line, an extra space will be added
        " if starting with keys 'a/A', spaces have been added already
        if !a:0
            call s:V.Edit.extra_spaces.add(r)
        endif

        if !has_key(I.lines, r.l)
            let I.lines[r.l] = s:Line.new(r.l, C)
            let nth = 0 | let C.nth = 0
        else
            if !s:v.single_region
                let nth += 1
            endif
            let C.nth = nth
            call add(I.lines[r.l].cursors, C)
        endif
        if C.index == I.index | let I.nth = C.nth | endif
    endfor

    " create a backup of the original lines
    if self.replace && !exists('I._lines')
        let I._lines = map(copy(I.lines), 'v:val.txt')
    endif

    "start tracking text changes
    let s:v.insert = 1 | call I.auto_start()

    "change/update cursor highlight
    call s:G.update_cursor_highlight()

    "start insert mode
    if self.replace
        startreplace
    else
        startinsert
    endif
endfun


fun! s:Insert.apply_settings() abort
    " Apply/disable settings related to insert mode. Return current region.

    " get winline and backup regions when insert mode is entered the first time
    if !exists('s:v.winline_insert')
        let s:v.winline_insert = winline()
        call s:G.backup_regions()
    endif

    " syn minlines/synmaxcol settings
    if !s:v.insert
        if g:VM_disable_syntax_in_imode
            let &l:synmaxcol = 1
        elseif get(g:, 'VM_reduce_sync_minlines', 1) && len(b:VM_sync_minlines)
            if get(b:, 'VM_minlines', 0)
                exe 'syn sync minlines='.b:VM_minlines
            else
                syn sync minlines=1
            endif
        endif
    endif

    if g:VM_use_first_cursor_in_line || self.replace
        let R = s:G.select_region_at_pos('.')
        let ix = s:G.lines_with_regions(0, R.l)[R.l][0]
        let R = s:G.select_region(ix)
    elseif s:v.insert
        let i = self.index >= len(s:R())? len(s:R())-1 : self.index
        let R = s:G.select_region(i)
    else
        let R = s:G.select_region_at_pos('.')
    endif

    " restore winline anyway, because it could have been auto-restarted
    call s:F.Scroll.force(s:v.winline_insert)
    call s:F.Scroll.get(1)

    "disable indentkeys and other settings that may mess up the text
    "keep o,O to detect indent for <CR>, though
    setlocal indentkeys=o,O
    setlocal cinkeys=o,O
    setlocal textwidth=0
    if !&expandtab
        setlocal softtabstop=0
    endif
    return R
endfun




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode update
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.update_text(insert_leave) abort
    " Update the text on TextChangedI event, and just after InsertLeave.

    if s:F.not_VM() || !g:VM_live_editing && !a:insert_leave | return | endif

    call vm#comp#TextChangedI()  "compatibility tweaks

    let I = self
    let L = I.lines

    " this is the current cursor position
    let ln   = line('.')
    let coln = col('.')

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
    let pos = I.begin[1] + I.change*I.nth

    " find out the actual text that has been inserted up to this point:
    " it's a slice of the current line, between the updated initial position
    " (pos) and the current cursor position (coln)

    " coln needs some adjustments though:
    "   -  in insert mode, 1 is subtracted to find the current cursor position
    "   -  but when insert mode stops (a:insert_leave == 1) this isn't true

    " when exiting insert mode (a:insert_leave), if the last last inserted
    " character is multibyte, any extra bytes will have to be added to the
    " final column
    if a:insert_leave
        let extra = s:cur_char_bytes() - 1
        let text = getline(ln)[ (pos-1) : (coln-1 + extra) ]
        let coln += extra
    elseif coln > 1
        let text = getline(ln)[ (pos-1) : (coln-2) ]
    else
        let text = ''
    endif

    " now update the current change: secondary cursors need this value updated
    let I.change = coln - pos + a:insert_leave

    " update the lines (also the current line is updated with setline(), this
    " should ensure that the same text is entered everywhere)
    if I.replace
        let width = strwidth(text)
        for l in sort(keys(L))
            call L[l].replace(I.change, text, width)
        endfor
    else
        for l in sort(keys(L))
            call L[l].update(I.change, text)
        endfor
    endif

    " put the cursor where it should stay after the lines update
    " as said before, the actual cursor can be pushed by cursors behind it
    call cursor(ln, I.col)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode stop
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.stop(...) abort
    " Called on InsertLeave.
    if s:F.not_VM() | return | endif

    " text must be updated again after InsertLeave, to take into account
    " changes that don't trigger TextChangedI, for example when exiting
    " insert mode immediately after CompleteDone or abbreviation expansion
    " the only case we don't do this, it's when no characters are typed, nor
    " completion has been performed
    if self.reupdate
        call self.update_text(1)
        let self.reupdate = v:false
    endif

    call self.clear_hi() | call self.auto_end() | let i = 0

    if s:v.single_region
        let active_line = 0
        let s:cursors_after = []
        for r in s:R()
            let c = self.cursors[i]
            if c.active
                let active_line = c.l
                call r.update_cursor([c.l, c._a])
                let s:v.storepos = [r.l, r.a]
            elseif active_line == c.l
                call r.update_cursor([c.l, c._a])
                call add(s:cursors_after, c)
            endif
            let i += 1
        endfor
    else
        for r in s:R()
            let c = self.cursors[i]
            call r.update_cursor([c.l, c._a])
            if r.index == self.index | let s:v.storepos = [r.l, r.a] | endif
            let i += 1
        endfor
    endif

    " NOTE:
    " - s:v.insert is true if re-entering insert mode after BS/CR/arrows etc;
    "   it is true until an insert session is really over.
    "
    " - s:v.restart_insert is only temporarily true when commands need to exit
    "   insert mode to update cursors, and enter it again; it is set in plugs,
    "   to avoid postprocessing.

    if s:v.restart_insert | let s:v.restart_insert = 0 | return | endif

    " reset insert mode variables
    let s:v.eco    = 1
    let s:v.insert = 0

    call s:step_back()
    call s:V.Edit.post_process(0,0)

    let &l:indentkeys   = s:v.indentkeys
    let &l:cinkeys      = s:v.cinkeys
    let &l:synmaxcol    = s:v.synmaxcol
    let &l:textwidth    = s:v.textwidth
    let &l:softtabstop  = s:v.softtabstop

    "restore sync minlines if possible
    if len(b:VM_sync_minlines)
        exe 'syn sync minlines='.b:VM_sync_minlines
    endif

    "reindent all and adjust cursors position, only if filetype/options allow
    if s:do_reindent() | call s:V.Edit.run_normal('==', {'recursive': 0, 'stay_put': 1}) | endif

    if g:VM_reselect_first
        call s:G.select_region(0)
    elseif self._index >= 0
        call s:G.select_region(self._index)
    else
        call s:G.select_region(self.index)
    endif

    " now insert mode has really ended, restore winline and clear variable
    if !g:VM_reselect_first
        call s:F.Scroll.force(s:v.winline_insert)
    endif
    unlet s:v.winline_insert
    silent! unlet s:v.smart_case_change

    " unmap single mode mappings, if they had been mapped
    call s:map_single_mode(1)

    " reset type and replace mode last, but not in single region mode
    if !s:v.single_region
        let self.replace = 0
        let self.type = ''
        silent! unlet self._lines
    endif

    if get(g:, 'VM_quit_after_leaving_insert_mode', 0)
        call vm#reset()
    endif
endfun


fun! s:Insert.clear_hi() abort
    " Clear cursors highlight.
    for c in self.cursors
        silent! call matchdelete(c.hl)
    endfor
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Cursor = {}

"--------------------------------------------------------------------------

"in Insert Mode we will forget about the regions, and work with cursors at
"positions; from the final positions, we'll update the real regions later

"--------------------------------------------------------------------------


fun! s:Cursor.new(ln, col) abort
    " Create new cursor.
    let C        = copy(self)
    let C.index  = len(s:Insert.cursors)
    let C.txt    = ''
    let C.l      = a:ln
    let C.L      = a:ln
    let C.a      = a:col
    let C._a     = C.a
    let C.active = ( C.index == s:Insert.index )
    let C.hl     = matchaddpos('MultiCursor', [[C.l, C.a]], 40)

    return C
endfun


fun! s:Cursor.update(ln, change) abort
    " Update cursor position and highlight.
    let C = self
    let C._a = C.a + a:change

    silent! call matchdelete(C.hl)
    let C.hl  = matchaddpos('MultiCursor', [[C.l, C._a]], 40)
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Line class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Line = {}


fun! s:Line.new(line, cursor) abort
    " Line object constructor.
    let L         = copy(self)
    let L.l       = a:line
    let L.txt     = getline(a:line)
    let L.cursors = [a:cursor]
    return L
endfun


fun! s:Line.update(change, text) abort
    " Update a line in insert mode.
    let text     = self.txt
    let I        = s:V.Insert
    let extraChg = 0  " cumulative change for additional cursors in same line

    " self.txt is the initial text of the line, when insert mode starts
    " it is not updated: the new text will be inserted inside of it
    " 'text' is the updated content of the line

    " self.cursors are the cursors in this line

    " when created, cursors are relative to normal mode, but in insert mode
    " 1 must be subtracted from their column (c.a)

    " a:change is the length of the text inserted by the main cursor
    " if there are more cursors in the same line, changes add up (== extraChg)

    " to sum it up, if:
    "     t1 is the original line, before the insertion point
    "     t2 is the original line, after the insertion point
    "     // is the insertion point (== c.a - 1 + nth*a:change)
    "     \\ is the end of the inserted text
    " then:
    "     line = t1 // inserted text \\ t2

    for c in self.cursors
        if s:v.single_region && !c.active
            call c.update(self.l, extraChg)
            continue
        endif

        let inserted = exists('s:v.smart_case_change') ?
                    \ s:smart_case_change(c, a:text) : a:text

        if c.a > 1
            let insPoint = c.a + extraChg - 1
            let t1 = text[ 0 : (insPoint - 1) ]
            let t2 = text[ insPoint : ]
            let text = t1 . inserted . t2
            " echo strtrans(t1) . "█" . strtrans(inserted) . "█" . strtrans(t2)
        else
            " echo "█" . strtrans(inserted) . "█" . strtrans(text)
            let text = inserted . text
        endif

        " increase the cumulative extra change
        let extraChg += a:change
        call c.update(self.l, extraChg)

        " c._a is the updated cursor position, c.a stays the same
        if c.active | let I.col = c._a | endif
    endfor
    call setline(self.l, text)
endfun


fun! s:Line.replace(change, replacementText, width) abort
    " Update a line in replace mode.
    let c        = self.cursors[0]         " there's a single cursor in replace mode
    let original = s:Insert._lines[self.l] " the original line
    let replaced = a:replacementText       " the typed replacement

    if c.a > 1
        let t1 = strpart(getline(c.l), 0, c.a - 1)
        let t2 = strcharpart(original, strwidth(t1) + a:width)
        let text = t1 . replaced . t2
    else
        let text = replaced . strcharpart(original, a:width)
    endif

    call c.update(self.l, a:change)

    " c._a is the updated cursor position, c.a stays the same
    if c.active | let s:Insert.col = c._a | endif
    call setline(self.l, text)

    if c._a >= col([c.l, '$'])
        call s:V.Edit.extra_spaces.add(c, 1)
    endif
endfun



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.auto_start() abort
    " Initialize autocommands.
    augroup VM_insert
        au!
        au TextChangedI  <buffer> call b:VM_Selection.Insert.update_text(0)
        au InsertLeave   <buffer> call b:VM_Selection.Insert.stop()
        au InsertCharPre <buffer> let b:VM_Selection.Insert.reupdate = v:true
        au CompleteDone  <buffer> let b:VM_Selection.Insert.reupdate = v:true
    augroup END
endfun


fun! s:Insert.auto_end() abort
    " Terminate autocommands.
    autocmd! VM_insert
    augroup! VM_insert
endfun



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:smart_case_change(cursor, txt) abort
    " the active cursor isn't affected, text is entered as typed
    if a:cursor.active
        return a:txt
    endif
    try
        let original = s:v.changed_text[a:cursor.index]
        if match(original, '\u') >= 0 && match(original, '\U') < 0
            return toupper(a:txt)
        elseif match(original, '\u') == 0
            return toupper(a:txt[:0]) . a:txt[1:]
        else
            return a:txt
        endif
    catch
        return a:txt
    endtry
endfun


fun! s:cur_char_bytes()
    " Bytesize of character under cursor
    return strlen(matchstr(getline('.'), '\%' . col('.') . 'c.'))
endfun


fun! s:do_reindent() abort
    " Check if lines must be reindented when exiting insert mode.
    if empty(&ft) | return | endif

    return index(vm#comp#no_reindents(), &ft) < 0 &&
                \ index(g:VM_reindent_filetypes, &ft) >= 0
endfun


fun! s:step_back() abort
    " Go back one char after exiting insert mode, as vim does.
    if s:v.single_region && s:Insert.type ==? 'i'
        return
    endif

    for r in s:v.single_region ? [s:R()[s:Insert.index]] : s:R()
        if r.a != col([r.l, '$']) && r.a > 1
            " move one byte back
            call r.shift(-1,-1)
            " fix column in case of multibyte chars by using a motion
            call r.move('lh')
        endif
    endfor
endfun


fun! s:map_single_mode(stop) abort
    " If single_region is active, map Tab to cycle regions.
    if !s:v.single_region || !get(g:, 'VM_single_mode_maps', 1) | return | endif

    let next = get(g:VM_maps, 'I Next', '<Tab>')
    let prev = get(g:VM_maps, 'I Prev', '<S-Tab>')

    if a:stop
        exe 'iunmap <buffer>' next
        exe 'iunmap <buffer>' prev
        if exists('s:v.single_mode_running')
            if s:v.single_mode_running
                let s:v.single_mode_running = 0
            else
                if get(g:, 'VM_single_mode_auto_reset', 1)
                    call s:F.toggle_option('single_region')
                endif
                unlet s:v.single_mode_running
            endif
        endif
    else
        exe 'imap <buffer>' next '<Plug>(VM-I-Next)'
        exe 'imap <buffer>' prev '<Plug>(VM-I-Prev)'
    endif
endfun

" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
