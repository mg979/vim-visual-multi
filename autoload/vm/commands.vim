"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions in this script are associated with plugs, all commands that can
" start VM have their entry point here.

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function: s:init
" Most commands call this function to ensure VM is initialized.
" @param whole: use word boundaries
" @param type: 0 if a pattern will be added, 1 if not, 2 if using regex
" @param extend_mode: 1 if forcing extend mode
" Returns: 1 if VM was already active when called
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""
fun! s:init(whole, type, extend_mode) abort
    " Ensure the buffer is initialized, set starting options.
    if a:extend_mode | let g:Vm.extend_mode = 1 | endif

    if g:Vm.buffer
        call s:F.Scroll.get()
        if s:v.using_regex | call vm#commands#regex_reset() | endif
        let s:v.whole_word = a:whole
        return 1    " return true if already initialized
    else
        let error = vm#init_buffer(a:type)
        if type(error) == v:t_string | throw error | endif
        call s:F.Scroll.get()
        let s:v.whole_word = a:whole
    endif
endfun


fun! vm#commands#init() abort
    " Variables initialization.
    let s:V        = b:VM_Selection
    let s:v        = s:V.Vars
    let s:G        = s:V.Global
    let s:F        = s:V.Funcs
    let s:Search   = s:V.Search
    let s:v.motion = ''
endfun


fun! s:set_extend_mode(X) abort
    " If just starting, enable extend mode if appropriate.

    if s:X() || a:X | return s:init(0, 1, 1)
    else            | return s:init(0, 1, 0)
    endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Add cursor
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:skip_shorter_lines() abort
    " When adding cursors below or above, don't add on shorter lines.
    " we don't want cursors on final column('$'), except when adding at column 1
    " in this case, moving to an empty line would give:
    "   vcol     = 1
    "   col      = 1
    "   endline  = 1
    " and the line would be skipped: check endline as 2, so that the cursor is added

    if get(g:, 'VM_skip_shorter_lines', 1)
        let vcol    = s:v.vertical_col
        let col     = virtcol('.')
        let endline = get(g:, 'VM_skip_empty_lines', 0) ? virtcol('$') :
                    \                                     virtcol('$') > 1 ?
                    \                                     virtcol('$') : 2

        "skip line
        if ( col < vcol || col == endline ) | return 1 | endif
    endif

    call s:G.new_cursor()
endfun


fun! s:went_too_far() abort
    " If gone too far, because it skipped all lines, reselect region.
    if empty(s:G.region_at_pos())
        call s:G.select_region(s:v.index)
    endif
endfun


fun! vm#commands#add_cursor_at_pos(extend) abort
    " Add/toggle a single cursor at current position.
    call s:set_extend_mode(a:extend)
    call s:G.new_cursor(1)
endfun


fun! vm#commands#add_cursor_down(extend, count) abort
    " Add cursors vertically, downwards.
    if s:last_line() | return | endif
    call s:set_extend_mode(a:extend)
    let s:v.vertical_col = s:F.get_vertcol()
    call s:G.new_cursor()
    let N = a:count

    while N
        normal! j
        if !s:skip_shorter_lines() | let N -= 1 | endif
        if s:last_line()           | break      | endif
    endwhile

    call s:went_too_far()
endfun


fun! vm#commands#add_cursor_up(extend, count) abort
    " Add cursors vertically, upwards.
    if s:first_line() | return | endif
    call s:set_extend_mode(a:extend)
    let s:v.vertical_col = s:F.get_vertcol()
    call s:G.new_cursor()
    let N = a:count

    while N
        normal! k
        if !s:skip_shorter_lines() | let N -= 1 | endif
        if s:first_line()          | break      | endif
    endwhile

    call s:went_too_far()
endfun


fun! vm#commands#add_cursor_at_word(yank, search) abort
    " Add a pattern for current word, place cursor at word begin.
    call s:init(0, 1, 0)

    if a:yank
        keepjumps normal! viwy`[
    endif
    if a:search | call s:Search.add() | endif

    let R = s:G.new_cursor() | let R.pat = s:v.search[0]
    call s:F.restore_reg()
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find by regex
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_by_regex(mode) abort
    " Entry point for VM regex search.
    if !g:Vm.buffer | call s:init(0, 2, 1) | endif
    let s:v.using_regex = a:mode
    let s:v.regex_backup = empty(@/) ? '\%^' : @/

    "if visual regex, reposition cursor to the beginning of the selection
    if a:mode == 2
        keepjumps normal! `<
    endif

    "store position, restored if the search will be aborted
    let s:regex_pos = winsaveview()

    cnoremap <silent> <buffer> <cr>  <cr>:call vm#commands#regex_done()<cr>
    cnoremap <silent><nowait><buffer> <esc><esc> <C-u><C-r>=b:VM_Selection.Vars.regex_backup<cr><esc>:call vm#commands#regex_abort()<cr>
    cnoremap <silent><nowait><buffer> <esc>      <C-u><C-r>=b:VM_Selection.Vars.regex_backup<cr><esc>:call vm#commands#regex_abort()<cr>
    call s:F.special_statusline('VM-REGEX')
    return '/'
endfun


fun! vm#commands#regex_done() abort
    " Terminate the VM regex mode after having entered search a pattern.
    let s:v.visual_regex = s:v.using_regex == 2
    call vm#commands#regex_reset()

    if s:v.visual_regex
        call s:Search.get_slash_reg()
        let g:Vm.finding = 1
        silent keepjumps normal! gv
        exe "silent normal \<Plug>(VM-Visual-Find)"
        return

    elseif s:X() | silent keepjumps normal! gny`]
    else         | silent keepjumps normal! gny
    endif
    call s:Search.get_slash_reg()

    if s:X()
        call s:G.new_region()
    else
        call vm#commands#add_cursor_at_word(0, 0)
    endif
endfun


fun! vm#commands#regex_abort()
    " Abort the VM regex mode.
    call winrestview(s:regex_pos)
    call vm#commands#regex_reset()
    if !len(s:R())
        call feedkeys("\<esc>")
    else
        call s:F.msg('Regex search aborted. ')
    endif
endfun


fun! vm#commands#regex_reset(...) abort
    " Reset the VM regex mode.
    silent! cunmap <buffer> <cr>
    silent! cunmap <buffer> <esc>
    silent! cunmap <buffer> <esc><esc>
    let s:v.using_regex = 0
    silent! unlet s:v.statusline_mode
    if a:0 | return a:1 | endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! vm#commands#ctrln(count) abort
    " Ctrl-N command: find word under cursor.
    call s:init(1, 0, 0)
    let no_reselect = get(g:, 'VM_notify_previously_selected', 0) == 2

    if !s:X() && s:is_r()
        let pos = getpos('.')[1:2]
        call vm#operators#select(1, "iw")
        call s:G.update_and_select_region(pos)
    else
        for i in range(a:count)
            call vm#commands#find_under(0, 1, 1)
            if no_reselect && s:v.was_region_at_pos
                break
            endif
        endfor
    endif
endfun


fun! vm#commands#find_under(visual, whole, ...) abort
    " Generic command that adds word under cursor. Used by C-N and variations.
    call s:init(a:whole, 0, 1)

    "Ctrl-N command
    if a:0 && s:is_r() | return vm#commands#find_next(0, 0) | endif

    " yank and create region
    if !a:visual | exe 'normal! viwy`]' | endif

    "replace region if calling the command on an existing region
    if s:is_r() | call s:G.region_at_pos().remove() | endif

    call s:Search.add()
    let R = s:G.new_region()
    call s:G.check_mutliline(0, R)
    return (a:0 && a:visual)? s:G.region_at_pos() : s:G.merge_overlapping(R)
endfun


fun! vm#commands#find_all(visual, whole) abort
    " Find all words under cursor or occurrences of visual selection.
    call s:init(a:whole, 0, 1)

    let pos = getpos('.')[1:2]
    let s:v.eco = 1

    if !a:visual
        let R = s:G.region_at_pos()
        if empty(R)
            let R = vm#commands#find_under(0, a:whole)
        endif
        call s:Search.update_patterns(R.pat)
    else
        let R = vm#commands#find_under(1, a:whole)
    endif

    call s:Search.join()
    let s:v.nav_direction = 1
    call s:G.erase_regions()
    call s:G.get_all_regions()

    let s:v.restore_scroll = 1
    return s:G.update_map_and_select_region(pos)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find next/previous
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_region(next) abort
    " Call the needed function and notify if reselecting a region.
    if !get(g:, 'VM_notify_previously_selected', 0)
        return a:next ? s:get_next() : s:get_prev()
    endif
    normal! m`
    echo "\r"
    let R = a:next ? s:get_next() : s:get_prev()
    if s:v.was_region_at_pos
        if g:VM_notify_previously_selected == 2
            normal! ``
            call s:F.msg('Already selected')
            return s:G.region_at_pos()
        endif
        call s:F.msg('Already selected')
    endif
    return R
endfun

fun! s:get_next() abort
    if s:X()
        silent keepjumps normal! ngny`]
        let R = s:G.new_region()
    else
        silent keepjumps normal! ngny`[
        let R = vm#commands#add_cursor_at_word(0, 0)
    endif
    let s:v.nav_direction = 1
    return R
endfun

fun! s:get_prev() abort
    if s:X()
        silent keepjumps normal! NgNy`]
        let R = s:G.new_region()
    else
        silent keepjumps normal! NgNy`[
        let R = vm#commands#add_cursor_at_word(0, 0)
    endif
    let s:v.nav_direction = 0
    return R
endfun

fun! s:navigate(force, dir) abort
    if a:force || @/==''
        let s:v.nav_direction = a:dir
        let r = s:G.region_at_pos()
        if empty(r)
            let i = s:G.nearest_region().index
        else
            let i = a:dir? r.index+1 : r.index-1
        endif
        call s:G.select_region(i)
        return 1
    endif
endfun

fun! s:skip() abort
    let r = s:G.region_at_pos()
    if empty(r) | call s:navigate(1, s:v.nav_direction)
    else        | call r.clear()
    endif
endfun

fun! vm#commands#find_next(skip, nav) abort
    " Find next region, always downwards.
    if ( a:nav || a:skip ) && s:F.no_regions() | return | endif

    "write search pattern if not navigating and no search set
    if s:X() && !a:nav | call s:Search.add_if_empty() | endif

    call s:Search.validate()

    if s:navigate(a:nav, 1) | return 0        "just navigate to previous
    elseif a:skip           | call s:skip()   "skip current match
    endif

    return s:get_region(1)
endfun


fun! vm#commands#find_prev(skip, nav) abort
    " Find previous region, always upwards.
    if ( a:nav || a:skip ) && s:F.no_regions() | return | endif

    "write search pattern if not navigating and no search set
    if s:X() && !a:nav | call s:Search.add_if_empty() | endif

    call s:Search.validate()

    let r = s:G.region_at_pos()
    if empty(r)  | let r = s:G.select_region(s:v.index) | endif
    if !empty(r) | let pos = [r.l, r.a]
    else         | let pos = getpos('.')[1:2]
    endif

    if s:navigate(a:nav, 0) | return 0        "just navigate to previous
    elseif a:skip           | call s:skip()   "skip current match
    endif

    "move to the beginning of the current match
    call cursor(pos)
    return s:get_region(0)
endfun


fun! vm#commands#skip(just_remove) abort
    " Skip region and get next, respecting current direction.
    if s:F.no_regions() | return | endif

    if a:just_remove
        let r = s:G.region_at_pos()
        if !empty(r)
            return s:G.remove_last_region(r.id)
        endif

    elseif s:v.nav_direction
        return vm#commands#find_next(1, 0)
    else
        return vm#commands#find_prev(1, 0)
    endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cycle regions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#seek_down() abort
    let nR = len(s:R())
    if !nR | return | endif

    " don't jump down if nothing else to seek
    if !s:F.Scroll.can_see_eof()
        let r = s:G.region_at_pos()
        if !empty(r) && r.index != nR - 1
            exe "keepjumps normal! \<C-f>"
        endif
    endif

    let end = getpos('.')[1]
    for r in s:R()
        if r.l >= end
            return s:G.select_region(r.index)
        endif
    endfor
    return s:G.select_region(nR - 1)
endfun

fun! vm#commands#seek_up() abort
    if !len(s:R()) | return | endif

    " don't jump up if nothing else to seek
    if !s:F.Scroll.can_see_bof()
        let r = s:G.region_at_pos()
        if !empty(r) && r.index != 0
            exe "keepjumps normal! \<C-b>"
        endif
    endif

    let end = getpos('.')[1]

    for r in reverse(copy(s:R()))
        if r.l <= end
            return s:G.select_region(r.index)
        endif
    endfor
    return s:G.select_region(0)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion, count, select, single) abort
    " Entry point for motions in VM.
    call s:init(0, 1, a:select)

    "create cursor if needed:
    " - VM hasn't started yet
    " - there are no regions
    " - called with (single_region) and cursor not on a region

    if !g:Vm.buffer || s:F.no_regions() || ( a:single && !s:is_r() )
        call s:G.new_cursor()
    endif

    "-----------------------------------------------------------------------

    if a:motion == '|' && a:count <= 1
        let s:v.motion = virtcol('.').a:motion
    else
        let s:v.motion = a:count>1? a:count.a:motion : a:motion
    endif

    "-----------------------------------------------------------------------

    if s:symbol()          | let s:v.merge = 1          | endif
    if a:select && !s:X()  | let g:Vm.extend_mode = 1   | endif

    if a:select && !s:v.multiline && s:vertical()
        call s:F.toggle_option('multiline')
    endif

    call s:call_motion(a:single)
endfun


fun! vm#commands#merge_to_beol(eol) abort
    " Entry point for 0/^/$ motions.
    if s:F.no_regions() | return | endif
    call s:G.cursor_mode()

    let s:v.motion = a:eol? "\<End>" : '^'
    let s:v.merge = 1
    call s:call_motion()
endfun


fun! vm#commands#find_motion(motion, char) abort
    " Entry point for f/F/t/T motions.
    if s:F.no_regions() | return | endif

    if a:char != ''
        let s:v.motion = a:motion.a:char
    else
        let s:v.motion = a:motion.nr2char(getchar())
    endif

    call s:call_motion()
endfun


fun! vm#commands#regex_motion(regex, count, remove) abort
    " Entry point for Goto-Regex motion.
    if s:F.no_regions() | return | endif

    let regex = empty(a:regex) ? s:F.search_chars(a:count) : a:regex
    let case =    g:VM_case_setting == 'smart'  ? '' :
                \ g:VM_case_setting == 'ignore' ? '\c' : '\C'

    if empty(regex)
      return s:F.msg('Cancel')
    endif

    call s:F.Scroll.get()
    let [ R, X ] = [ s:R()[ s:v.index ], s:X() ]
    call s:before_move()

    for r in ( s:v.single_region ? [R] : s:R() )
        call cursor(r.l, r.a)
        if !search(regex.case, 'zp', r.l)
            if a:remove | call r.remove() | endif
            continue
        endif
        if X
            let r.b = getpos('.')[2]
            call r.update_region()
        else
            call r.update_cursor_pos()
        endif
    endfor

    "update variables, facing direction, highlighting
    call s:after_move(R)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion event
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:call_motion(...) abort
    if s:F.no_regions() | return | endif
    call s:F.Scroll.get()
    let R = s:R()[ s:v.index ]

    let regions = (a:0 && a:1) || s:v.single_region ? [R] : s:R()

    call s:before_move()

    for r in regions | call r.move() | endfor

    "update variables, facing direction, highlighting
    call s:after_move(R)
endfun


fun! s:before_move() abort
    call s:G.reset_byte_map(0)
    if !s:X() | let s:v.merge = 1 | endif
endfun


fun! s:after_move(R) abort
    let s:v.direction = a:R.dir
    let s:v.restore_scroll = !s:v.insert

    if s:v.merge
        call s:G.select_region(a:R.index)
        call s:F.Scroll.get(1)
        call s:G.update_and_select_region(a:R.A)
    else
        call s:F.restore_reg()
        call s:G.update_highlight()
        call s:G.select_region(a:R.index)
    endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Align
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#align() abort
    if s:F.no_regions() | return | endif
    let s:v.restore_index = s:v.index
    call s:F.Scroll.get(1)
    call s:V.Edit.align()
    call s:F.Scroll.restore()
endfun


fun! vm#commands#align_char(count) abort
    if s:F.no_regions() | return | endif
    call s:G.cursor_mode()

    let s:v.restore_index = s:v.index
    call s:F.Scroll.get(1)
    let n = a:count | let s = n>1? 's' : ''
    echohl Label    | echo 'Align with '.n.' char'.s.' > ' | echohl None

    let C = []
    while n
        let c = nr2char(getchar())
        if c == "\<esc>" | echohl WarningMsg | echon ' ...Aborted' | return
        else             | call add(C, c) | let n -= 1 | echon c
        endif
    endwhile

    let s = 'czp'    "search method: accept at cursor position

    while !empty(C)
        let c = remove(C, 0)

        "remove region if a match isn't found, otherwise it will be aligned
        for r in s:R()
            call cursor(r.l, r.a)
            if !search(c, s, r.l) | call r.remove() | continue | endif
            call r.update_cursor([r.l, getpos('.')[2]])
        endfor

        "TODO: strip white spaces preceding the shortest columns
        call s:V.Edit.align()
        let s = 'zp'    "change search method: don't accept at cursor position
    endwhile
    call s:F.Scroll.restore()
endfun


fun! vm#commands#align_regex() abort
    if s:F.no_regions() | return | endif
    call s:G.cursor_mode()
    let s:v.restore_index = s:v.index
    call s:F.Scroll.get(1)

    echohl Label | let rx = input('Align with regex > ')   | echohl None
    if empty(rx) | echohl WarningMsg | echon ' ...Aborted' | return | endif

    for r in s:R()
        call cursor(r.l, r.a)
        if !search(rx, 'czp', r.l) | call r.remove() | continue | endif
        call r.update_cursor([r.l, getpos('.')[2]])
    endfor
    call s:V.Edit.align()
    call s:F.Scroll.restore()
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Miscellaneous commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#invert_direction(...) abort
    " Invert direction and reselect region.
    if s:F.no_regions() || s:v.auto | return | endif

    for r in s:R() | let r.dir = !r.dir | endfor

    "invert anchor
    if s:v.direction
        let s:v.direction = 0
        for r in s:R() | let r.k = r.b | let r.K = r.B | endfor
    else
        let s:v.direction = 1
        for r in s:R() | let r.k = r.a | let r.K = r.A | endfor
    endif

    if !a:0 | return | endif
    call s:G.update_highlight()
    call s:G.select_region(s:v.index)
endfun


fun! vm#commands#split_lines() abort
    " Split regions so that they don't cross line boundaries.
    if s:F.no_regions() | return | endif
    call s:G.split_lines()
    if get(g:, 'VM_autoremove_empty_lines', 1)
        call s:G.remove_empty_lines()
    endif
    call s:G.update_and_select_region()
endfun


fun! vm#commands#remove_empty_lines() abort
    " Remove selections that consist of empty lines.
    call s:G.remove_empty_lines()
    call s:G.update_and_select_region()
endfun


fun! vm#commands#visual_cursors() abort
    " Create a column of cursors from visual mode.
    call s:set_extend_mode(0)
    call vm#visual#cursors(visualmode())
endfun


fun! vm#commands#visual_add() abort
    " Convert a visual selection to a VM selection.
    call s:set_extend_mode(1)
    call vm#visual#add(visualmode())
endfun


fun! vm#commands#remove_every_n_regions(count) abort
    " Remove every n regions, given by [count], min 2.
    if s:F.no_regions() | return | endif
    let R = s:R() | let i = 1 | let cnt = a:count < 2 ? 2 : a:count
    for n in range(1, len(R))
        if n % cnt == 0
            call R[n-i].remove()
            let i += 1
        endif
    endfor
    call s:G.update_and_select_region({'index': 0})
endfun


fun! vm#commands#mouse_column() abort
    " Create a column of cursors with the mouse.
    call s:set_extend_mode(0)
    let start = getpos('.')[1:2]
    exe "normal! \<LeftMouse>"
    let end = getpos('.')[1:2]

    if start[0] < end[0]
        call cursor(start[0], start[1])
        while getpos('.')[1] < end[0]
            call vm#commands#add_cursor_down(0, 1)
        endwhile
        if getpos('.')[1] > end[0]
            call vm#commands#skip(1)
        endif
    else
        call cursor(start[0], start[1])
        while getpos('.')[1] > end[0]
            call vm#commands#add_cursor_up(0, 1)
        endwhile
        if getpos('.')[1] < end[0]
            call vm#commands#skip(1)
        endif
    endif
endfun


fun! vm#commands#shrink_or_enlarge(shrink) abort
    " Reduce/enlarge selection size by 1.
    if s:F.no_regions() | return | endif
    call s:G.extend_mode()

    let dir = s:v.direction

    let s:v.motion = a:shrink? (dir? 'h':'l') : (dir? 'l':'h')
    call s:call_motion()

    call vm#commands#invert_direction()

    let s:v.motion = a:shrink? (dir? 'l':'h') : (dir? 'h':'l')
    call s:call_motion()

    if s:v.direction != dir | call vm#commands#invert_direction(1) | endif
endfun


fun! vm#commands#increase_or_decrease(increase, all_types, count)
    let oldnr = &nrformats
    if a:all_types
        setlocal nrformats+=alpha
    endif
    let map = a:increase ? "\<c-a>" : "\<c-x>"
    call s:V.Edit.run_normal(map, {'count': a:count, 'recursive': 0})
    if a:all_types
        let &nrformats = oldnr
    endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reselect last regions, undo, redo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#reselect_last()
    let was_active = s:init(0, 1, 0)
    if empty(get(b:, 'VM_LastBackup', {})) || empty(get(b:VM_LastBackup, 'regions', []))
        return s:F.exit('No regions to restore')
    endif

    if was_active && !s:X()
        call s:G.erase_regions()
    elseif was_active
        return s:F.msg('Not in extend mode.')
    endif

    try
        for r in b:VM_LastBackup.regions
            call vm#region#new(1, r.A, r.B)
        endfor
        let g:Vm.extend_mode = b:VM_LastBackup.extend
        let s:v.search = b:VM_LastBackup.search
    catch
        return s:F.exit('Error while restoring regions.')
    endtry

    call s:G.update_and_select_region({'index': b:VM_LastBackup.index})
endfun



fun! vm#commands#undo() abort
    let first = b:VM_Backup.first
    let ticks = b:VM_Backup.ticks
    let index = index(ticks, b:VM_Backup.last)

    try
        if index <= 0
            if undotree().seq_cur != first
                exe "undo" first
                call s:G.restore_regions(0)
            endif
        else
            exe "undo" ticks[index-1]
            call s:G.restore_regions(index-1)
            let b:VM_Backup.last = ticks[index - 1]
        endif
    catch
        call s:V.Funcs.msg('[visual-multi] errors during undo operation.')
    endtry
endfun


fun! vm#commands#redo() abort
    let ticks = b:VM_Backup.ticks
    let index = index(ticks, b:VM_Backup.last)

    try
        if index != len(ticks) - 1
            exe "undo" ticks[index+1]
            call s:G.restore_regions(index+1)
            let b:VM_Backup.last = ticks[index + 1]
        endif
    catch
        call s:V.Funcs.msg('[visual-multi] errors during redo operation.')
    endtry
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X                = { -> g:Vm.extend_mode }
let s:R                = { -> s:V.Regions      }
let s:is_r             = { -> g:Vm.buffer && !empty(s:G.region_at_pos()) }
let s:first_line       = { -> line('.') == 1 }
let s:last_line        = { -> line('.') == line('$') }
let s:symbol           = {   -> index(['^', '0', '%', '$'],     s:v.motion) >= 0 }
let s:horizontal       = {   -> index(['h', 'l'],               s:v.motion) >= 0 }
let s:vertical         = {   -> index(['j', 'k'],               s:v.motion) >= 0 }
let s:simple           = { m -> index(split('hlwebWEB', '\zs'), m)          >= 0 }

" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
