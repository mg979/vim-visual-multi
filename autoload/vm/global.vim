"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global class
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Global = {}

fun! vm#global#init() abort
    " Store Global class in buffer VM dictionary.

    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:F = s:V.Funcs

    let s:X = { -> g:Vm.extend_mode }
    let s:R = { -> s:V.Regions      }

    return s:Global
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions creation and access
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.new_region() abort
    " Get the region under cursor, or create a new one if there is none.

    let R = self.region_at_pos()
    if empty(R)
        let R = vm#region#new(0)
        let s:v.was_region_at_pos = 0
    else
        let s:v.was_region_at_pos = 1
    endif

    if !s:v.eco
        call self.select_region(R.index)
        call s:V.Search.update_patterns()
        call s:F.restore_reg()
    endif
    return R
endfun


fun! s:Global.new_cursor(...) abort
    " Create a new cursor if there isn't already a region.

    let R = self.region_at_pos()

    if empty(R)
        return vm#region#new(1)
    elseif a:0  " toggle cursor
        call R.clear()
    endif
    return s:F.should_quit() ? vm#reset() : R
endfun


fun! s:Global.active_regions(...) abort
    " Return current working set of regions.

    if s:v.single_region    | return [s:V.Regions[s:v.index]]
    else                    | return s:V.Regions
    endif
endfun


fun! s:Global.get_all_regions(...) abort
    " Get all regions, optionally between two byte offsets.

    let ows = &wrapscan
    set nowrapscan
    let [l:start, l:end] = a:0 ? [a:1, a:2] : [1, 0]
    call s:F.Cursor(l:start)
    silent keepjumps normal! ygn
    let R = self.new_region()
    while 1
        try
            silent keepjumps normal! nygn
            if a:0 && s:F.pos2byte("'[") > l:end
                break
            endif
            let R = self.new_region()
            if !s:v.find_all_overlap && self.overlapping_regions(R)
                let s:v.find_all_overlap = 1
            endif
        catch
            break
        endtry
    endwhile
    let &wrapscan = ows
    return R
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change mode
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Global.change_mode(...) abort
    " Change from extend to cursor mode and viceversa.
    " Merge cursors if transitioning from cursor mode, but reset direction
    " transitioning from extend mode.

    if !s:X() | call self.merge_cursors()
    else      | call self.backup_last_regions()
    endif

    let g:Vm.extend_mode = !s:X()

    let ix = s:v.index
    call s:F.Scroll.get()
    if s:X()
        call self.update_regions()
    else
        call self.collapse_regions()
    endif

    let R = self.select_region(ix)

    if a:0  "called manually
        let s:v.restore_scroll = 1
        call s:F.Scroll.restore()
    endif
    return R
endfun


fun! s:Global.cursor_mode() abort
    " Set cursor mode. Return 1 if mode had to be changed.
    if s:X() | call self.change_mode() | return 1 | endif
endfun


fun! s:Global.extend_mode() abort
    " Set extend mode. Return 1 if mode had to be changed.
    if !s:X() | call self.change_mode() | return 1 | endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Global.update_highlight(...) abort
    " Update highlight for all regions.
    if s:v.eco | return | endif

    call self.remove_highlight()
    for r in s:R()
        call r.highlight()
    endfor

    call self.update_cursor_highlight()
endfun


fun! s:Global.update_cursor_highlight(...) abort
    " Set cursor highlight, depending on extending mode.
    if s:v.eco | return | endif

    highlight clear MultiCursor

    if s:v.insert
        exe "highlight link MultiCursor ".g:Vm.hi.insert

    elseif !s:X() && self.all_empty()
        exe "highlight link MultiCursor ".g:Vm.hi.mono

    else
        exe "highlight link MultiCursor ".g:Vm.hi.cursor
    endif
endfun


fun! s:Global.remove_highlight() abort
    " Remove all regions' highlight.
    for r in s:R()
        call r.remove_highlight()
    endfor
    call vm#clearmatches()
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Global.all_empty() abort
    " If not all regions are empty, turn on extend mode.
    for r in s:R()
        if r.a != r.b
            if !s:X() | let g:Vm.extend_mode = 1 | endif
            return 0
        endif
    endfor
    return 1
endfun


fun! s:Global.update_regions() abort
    " Force regions update.
    if s:v.eco | return | endif

    if s:X()
        for r in s:R() | call r.update_region() | endfor
    else
        for r in s:R() | call r.update_cursor() | endfor
    endif
    call self.update_highlight()
    call s:F.restore_reg()
endfun


fun! s:Global.update_and_select_region(...) abort
    " Update regions and select region at position, index or id.
    if s:v.merge
        let s:v.merge = 0 | return self.merge_regions()
    endif

    call self.remove_highlight()

    call self.reset_byte_map(0)
    call self.reset_vars()
    call self.update_indices()
    call self.update_regions()

    "a region is going to be reselected:
    "   no arguments        ->  position '.'
    "   a:1 not a dict      ->  position (a string, a list [ln, col], an offset)
    "   {'index': i}        ->  index
    "   {'id': i}           ->  id

    let nR = len(s:R())
    if !nR | return vm#reset() | endif

    if !g:VM_reselect_first
        if exists('s:v.restore_index')
            let i = s:v.restore_index >= nR? nR - 1 : s:v.restore_index
            let R = self.select_region(i)
            unlet s:v.restore_index
        elseif a:0
            if type (a:1) != v:t_dict
                let R = self.select_region_at_pos(a:1)
            elseif  has_key(a:1, 'index')
                let i = a:1.index >= nR? nR - 1 : a:1.index
                let R = self.select_region(i)
            elseif has_key(a:1, 'id')
                let R = self.select_region(s:F.region_with_id(a:1.id).index)
            else
                return s:F.msg('[visual-multi] '.
                            \  'update_and_select_region() '.
                            \  'called with wrong arguments')
            endif
        else
            let R = self.select_region_at_pos('.')
        endif
    else
        let R = self.select_region(0)
    endif

    return s:F.should_quit() ? vm#reset() : R
endfun


fun! s:Global.update_map_and_select_region(...) abort
    " Update only the bytes map, skipping region update.
    " Regions have been just created and there's no need to update them.
    if s:v.find_all_overlap
        let s:v.find_all_overlap = 0
        return self.merge_regions()
    endif

    call self.reset_vars()
    call self.update_indices()
    call self.reset_byte_map(1)
    call self.update_highlight()
    let R = self.select_region_at_pos(a:0? a:1 : '.')

    return s:F.should_quit() ? vm#reset() : R
endfun


fun! s:Global.erase_regions() abort
    " Erase all regions.
    call self.remove_highlight()
    let s:V.Regions = []
    let s:V.Bytes = {}
    let s:v.index = -1
endfun


fun! s:Global.restore_regions(index) abort
    " Restore previous regions from backup.
    let backup = b:VM_Backup | call self.erase_regions()

    let tick = backup.ticks[a:index]
    let s:V.Regions = deepcopy(backup[tick].regions)
    let g:Vm.extend_mode = backup[tick].X
    return self.update_and_select_region()
endfun


fun! s:Global.backup_regions() abort
    " Store a copy of the current regions.

    let tick   = undotree().seq_cur
    let backup = b:VM_Backup
    let index  = index(backup.ticks, backup.last)

    if index < len(backup.ticks) - 1
        let backup.ticks = backup.ticks[:index]
    endif

    call add(backup.ticks, tick)
    let backup[tick] = { 'regions': deepcopy(s:R()), 'X': s:X() }
    let backup.last = tick
endfun


fun! s:Global.backup_last_regions() abort
    " Create a backup of last set of regions.

    let b:VM_LastBackup = {}
    let b:VM_LastBackup.extend = g:Vm.extend_mode
    let b:VM_LastBackup.regions = map(deepcopy(s:R()), "{'A': v:val.A, 'B': v:val.B}")
    let b:VM_LastBackup.search = s:v.search
    let b:VM_LastBackup.index = s:v.index
    let s:v.direction = 1
endfun


fun! s:Global.collapse_regions() abort
    " Collapse regions to cursors and turn off extend mode.

    call self.reset_byte_map(0)

    for r in s:R() | call r.update_cursor([r.l, (r.dir? r.a : r.b)]) | endfor
    let g:Vm.extend_mode = 0
    call self.update_highlight()
endfun


fun! s:Global.select_region(i) abort
    " Adjust cursor position of the region at index, then return region.

    if !len(s:R()) | return | endif

    let i = a:i >= len(s:R())? 0 : a:i

    let R = s:R()[i]
    call cursor(R.cur_ln(), R.cur_col())
    call s:F.Scroll.restore()
    let s:v.index = R.index
    return R
endfun


fun! s:Global.select_region_at_pos(pos) abort
    " Try to select a region at the given position.

    let r = self.region_at_pos(a:pos)
    if !empty(r)
        return self.select_region(r.index)
    else
        return self.select_region(self.nearest_region().index)
    endif
endfun


fun! s:Global.region_at_pos(...) abort
    " Return the region at position, or an empty dict if not found.

    let pos = a:0 ? s:F.pos2byte(a:1) : s:F.curs2byte()
    if s:X() && !has_key(s:V.Bytes, pos) | return {} | endif

    for r in s:R()
        if pos >= r.A && pos <= r.B
            return r
        endif
    endfor
    return {}
endfun


fun! s:Global.nearest_region(...) abort
    " Return the nearest region at position.

    let Rs = s:R() | if !len(Rs) | return {} | endif

    let pos = a:0 ? s:F.pos2byte(a:1) : s:F.curs2byte()

    if pos <= Rs[0].A  | return Rs[0]  | endif
    if pos >= Rs[-1].B | return Rs[-1] | endif

    for r in Rs
        if pos <= r.B
            return r
        endif
    endfor
endfun


fun! s:Global.reset_index() abort
    " Reset index to current region, 0, or max - 1.

    if !len(s:R())
        let s:v.index = -1
        return
    endif
    let r = self.region_at_pos()
    if !empty(r)
        let s:v.index = r.index
    elseif line('.') >= s:R()[-1].L
        let s:v.index = len(s:R()) - 1
    else
        let s:v.index = 0
    endif
endfun


fun! s:Global.overlapping_regions(R) abort
    " Check if two regions are overlapping.

    let B = range(a:R.A, a:R.B)
    for b in B
        if s:V.Bytes[b] > 1 | return 1 | endif
    endfor
endfun


fun! s:Global.merge_overlapping(R) abort
    " Return merged regions if region had overlapping regions.

    let overlap = self.overlapping_regions(a:R)
    return overlap ? self.merge_regions() : a:R
endfun


fun! s:Global.remove_empty_lines() abort
    " Remove regions that consist of the endline marker only.

    for r in self.active_regions()
        if r.a == 1 && r.A == r.B && col([r.l, '$']) == 1
            call r.clear()
        endif
    endfor
endfun


fun! s:Global.reset_byte_map(update) abort
    " Reset byte map for all regions.

    let s:V.Bytes = {}

    if a:update
        for r in self.active_regions() | call r.update_bytes_map() | endfor
    endif
endfun


fun! s:Global.reset_vars() abort
    " Reset variables during final regions update.
    "Note: this eco/auto check is old and seems wrong. Keeping for now but it should go

    if !( s:v.eco || s:v.auto ) | return | endif

    let s:v.auto = 0    | let s:v.eco = 0
    let s:v.no_search = 0
    call s:F.restore_reg()
endfun


fun! s:Global.remove_last_region(...) abort
    " Remove last region and reselect the previous one.
    for r in s:R()
        if r.id == ( a:0? a:1 : s:v.IDs_list[-1] )
            call r.clear()
            break
        endif
    endfor

    if s:F.should_quit()
        return vm#reset()
    else
        "reselect previous region
        let i = a:0? (r.index > 0? r.index-1 : 0) : s:v.index
        return self.select_region(i)
    endif
endfun


fun! s:Global.update_indices(...) abort
    " Adjust region indices.

    if a:0
        let i = a:1
        for r in s:R()[i:]
            let r.index = i
            let i += 1
        endfor
        return
    endif

    let i = 0
    for r in s:R()
        let r.index = i
        let i += 1
    endfor
endfun


fun! s:Global.update_region_patterns(pat) abort
    " Update the patterns for the appropriate regions.

    for r in s:R()
        if a:pat =~ r.pat || r.pat =~ a:pat
            let r.pat = a:pat
        endif
    endfor
endfun


fun! s:Global.regions_text() abort
    " Return a list with all regions' contents.

    let t = []
    for r in self.active_regions() | call add(t, r.txt) | endfor
    return t
endfun


fun! s:Global.check_mutliline(all, ...) abort
    " Check if multiline must be enabled.

    for r in a:0? [a:1] : s:R()
        if !s:v.multiline && r.h
            call s:F.toggle_option('multiline') | break
        endif
    endfor
endfun


fun! s:Global.lines_with_regions(reverse, ...) abort
    " Find lines with regions.""

    let lines = {}
    for r in s:R()
        "called for a specific line
        if a:0 && r.l != a:1 | continue | endif

        "add region index to indices for that line
        let lines[r.l] = get(lines, r.l, [])
        call add(lines[r.l], r.index)
    endfor

    for line in keys(lines)
        "sort list so that lower indices are put farther in the list

        if len(lines[line]) > 1
            if a:reverse | call reverse(sort(lines[line], 'n'))
            else         | call sort(lines[line], 'n')
            endif
        endif
    endfor
    return lines
endfun


fun! s:Global.one_region_per_line() abort
    " Remove all regions in each line, except the first one.

    let new_regions = []
    let lines = []
    for r in s:R()
        if index(lines, r.l) < 0
            call add(new_regions, r)
            call add(lines, r.l)
        endif
    endfor
    call self.erase_regions()
    let s:V.Regions = new_regions
    call self.update_indices()
endfun


fun! s:Global.reorder_regions() abort
    " Reorder regions, so that their byte offsets are consecutive.

    let As = sort(map(copy(s:R()), 'v:val.A'), 'n')
    let Regions = []
    while 1
        for r in s:R()
            if r.A == As[0]
                call add(Regions, r)
                call remove(As, 0)
                break
            endif
        endfor
        if !len(As) | break | endif
    endwhile
    let s:V.Regions = Regions
    call self.update_indices()
    call self.reset_index()
endfun


fun! s:Global.split_lines() abort
    " Split regions, so that each is contained in a single line.

    let prev = s:v.index

    "make a list of regions to split
    let lts = filter(copy(self.active_regions()), 'v:val.h')

    for r in lts
        let R = s:R()[r.index].remove()

        for n in range(R.h+1)
            if n == 0  "first line
                call vm#region#new(0, R.l, R.l, R.a, len(getline(R.l)))
            elseif n < R.h
                call vm#region#new(0, R.l+n, R.l+n, 1, len(getline(R.l+n)))
            else
                call vm#region#new(0, R.L, R.L, 1, R.b)
            endif
        endfor
    endfor
endfun


fun! s:Global.filter_by_expression(exp, type) abort
    " Filter out regions that don't match an expression or a pattern.

    let ids_to_remove = []
    if a:type == 'pattern'
        let exp = "r.txt =~ '".a:exp."'"
    elseif a:type == '!pattern'
        let exp = "r.txt !~ '".a:exp."'"
    else
        let exp = s:F.get_expr(a:exp)
    endif
    try
        for r in s:R()
            if !eval(exp)
                call add(ids_to_remove, r.id)
            endif
        endfor
    catch
        echohl ErrorMsg | echo "\tinvalid expression" | echohl None | return
    endtry
    call self.remove_regions_by_id(ids_to_remove)
endfun


fun! s:Global.remove_regions_by_id(list) abort
    " Remove a list of regions by id.

    for id in a:list
        call s:F.region_with_id(id).remove()
    endfor
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Merging regions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Global.merge_cursors() abort
    " Merge overlapping cursors.

    let ids_to_remove = [] | let last_A = 0 | let pos = getpos('.')[1:2]

    " we only check offset r.A, since for cursors r.A == r.B
    for r in s:R()
        if r.A == last_A | call add(ids_to_remove, r.id) | endif
        let last_A = r.A
    endfor

    call self.remove_regions_by_id(ids_to_remove)
    return self.update_and_select_region(pos)
endfun


fun! s:Global.merge_regions(...) abort
    " Merge overlapping regions.

    if !len(s:R()) | return {}                   | endif
    if !s:X()      | return self.merge_cursors() | endif

    let s:v.eco = 1
    let pos = getpos('.')[1:2]
    call self.rebuild_from_map(s:V.Bytes)
    return self.update_map_and_select_region(pos)
endfun


fun! s:Global.merge_maps(map) abort
    " Merge temporary and primary regions maps.

    for b in keys(a:map)
        let s:V.Bytes[b] = get(s:V.Bytes, b, 0) + a:map[b]
    endfor
    if empty(s:V.Bytes) | return {} | endif
    let pos = getpos('.')[1:2]
    call self.rebuild_from_map(s:V.Bytes)
    return self.update_map_and_select_region(pos)
endfun


fun! s:Global.subtract_maps(map) abort
    " Subtract temporary map from primary region map.

    for b in keys(a:map)
        silent! unlet s:V.Bytes[b]
    endfor
    return self.merge_regions()
endfun


fun! s:Global.rebuild_from_map(map, ...) abort
    " Rebuild regions from bytes map.

    let By = sort(map(keys(a:map), 'str2nr(v:val)'), 'n')
    if a:0
        let [start, end] = a:1
        call filter(By, 'v:val >= start && v:val <= end')
    endif
    let A = By[0] | let B = By[0]

    call self.erase_regions()

    for i in By[1:]
        if i == B+1
            let B = i
        else
            call vm#region#new(0, A, B)
            let A = i | let B = i
        endif
    endfor
    call vm#region#new(0, A, B)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" python section (functions here will overwrite previous ones)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


if !g:VM_use_python | finish | endif

fun! s:Global.rebuild_from_map(map, ...) abort
    let l:dict = a:map
    let l:range = a:0 ? a:1 : []
    python3 vm.py_rebuild_from_map()
endfun

fun! s:Global.lines_with_regions(reverse, ...) abort
    let l:specific_line = a:0 ? a:1 : 0
    python3 vm.py_lines_with_regions()
    return lines
endfun

" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
