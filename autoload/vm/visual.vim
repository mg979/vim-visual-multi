"commands to add/subtract regions with visual selection
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#add(mode) abort
    " Add visually selected region to current regions.
    call s:backup_map()
    let pos = getpos('.')[1:2]

    if a:mode ==# 'v'     | call s:vchar()
    elseif a:mode ==# 'V' | call s:vline()
    else                  | let s:v.direction = s:vblock(1)
    endif

    call s:visual_merge()

    if a:mode ==# 'V'
        call s:G.split_lines()
        call s:G.remove_empty_lines()
    elseif a:mode ==# 'v'
        for r in s:R()
            if r.h | let s:v.multiline = 1 | break | endif
        endfor
    endif

    call s:G.update_and_select_region(pos)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#subtract(mode) abort
    " Subtract visually selected region from current regions.
    let X = s:backup_map()

    if a:mode ==# 'v'     | call s:vchar()
    elseif a:mode ==# 'V' | call s:vline()
    else                  | call s:vblock(1)
    endif

    call s:visual_subtract()
    call s:G.update_and_select_region({'id': s:v.IDs_list[-1]})
    if X | call s:G.cursor_mode() | endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#reduce() abort
    " Remove regions outside of visual selection.
    let X = s:backup_map()
    call s:G.rebuild_from_map(s:Bytes, [s:F.pos2byte("'<"), s:F.pos2byte("'>")])
    if X | call s:G.cursor_mode() | endif
    call s:G.update_and_select_region()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#cursors(mode) abort
    " Create cursors, one for each line of the visual selection.
    call s:init()
    let [pos, start, end] = [getpos('.')[1:2],
                \            getpos("'<")[1:2], getpos("'>")[1:2]]

    call s:create_cursors(start, end)

    if a:mode ==# 'V' && get(g:, 'VM_autoremove_empty_lines', 1)
        call s:G.remove_empty_lines()
    endif

    call s:G.update_and_select_region(pos)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#split() abort
    " Split regions with regex pattern.
    call s:init()
    if !len(s:R()) | return
    elseif !s:X()  | return s:F.msg('Not in cursor mode.')  | endif

    echohl Type   | let pat = input('Pattern to remove > ') | echohl None
    if empty(pat) | return s:F.msg('Command aborted.')      | endif

    let start = s:R()[0]                "first region
    let stop = s:R()[-1]                "last region

    call s:F.Cursor(start.A)            "check for a match first
    if !search(pat, 'nczW', stop.L)     "search method: accept at cursor position
        call s:F.msg("\t\tPattern not found")
        return s:G.select_region(s:v.index)
    endif

    call s:backup_map()

    "backup old patterns and create new regions
    let oldsearch = copy(s:v.search)
    call s:V.Search.get_slash_reg(pat)

    call s:G.get_all_regions(start.A, stop.B)

    "subtract regions and rebuild from map
    call s:visual_subtract()
    call s:V.Search.join(oldsearch)
    call s:G.update_and_select_region()
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:vchar() abort
    "characterwise selection
    silent keepjumps normal! `<y`>`]
    call s:G.check_mutliline(0, s:G.new_region())
endfun


fun! s:vline() abort
    "linewise selection
    silent keepjumps normal! '<y'>`]
    call s:G.new_region()
endfun


fun! s:vblock(extend) abort
    "blockwise selection
    let start = getpos("'<")[1:2]
    let end = getpos("'>")[1:2]

    if ( start[1] > end[1] )
        " swap columns because top-right or bottom-left corner is selected
        let temp = start[1]
        let start[1] = end[1]
        let end[1] = temp
        let inverted = line(".") == line("'>")
    else
        let inverted = line(".") == line("'<")
    endif

    let block_width = abs(virtcol("'>") - virtcol("'<"))

    call s:create_cursors(start, end)

    if a:extend && block_width
        call vm#commands#motion('l', block_width, 1, 0)
    endif
    return !inverted
endfun


fun! s:backup_map() abort
    "use temporary regions, they will be merged later
    call s:init()
    let X = s:G.extend_mode()
    let s:Bytes = copy(s:V.Bytes)
    call s:G.erase_regions()
    let s:v.no_search = 1
    let s:v.eco = 1
    return X
endfun


fun! s:visual_merge() abort
    "merge regions
    let new_map = copy(s:V.Bytes)
    let s:V.Bytes = s:Bytes
    call s:G.merge_maps(new_map)
    unlet new_map
endfun


fun! s:visual_subtract() abort
    "subtract regions
    let new_map = copy(s:V.Bytes)
    let s:V.Bytes = s:Bytes
    call s:G.subtract_maps(new_map)
    unlet new_map
endfun


fun! s:init() abort
    "init script vars
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
endfun


fun! s:create_cursors(start, end) abort
    "create cursors that span over visual selection
    call cursor(a:start)

    if ( a:end[0] > a:start[0] )
        while line('.') < a:end[0]
            call vm#commands#add_cursor_down(0, 1)
        endwhile

    elseif empty(s:G.region_at_pos())
        " ensure there's at least a cursor
        call s:G.new_cursor()
    endif
endfun


let s:R = { -> s:V.Regions }
let s:X = { -> g:Vm.extend_mode }


" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
