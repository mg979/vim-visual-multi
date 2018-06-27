"commands to add/subtract visual selection
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#add(mode)

    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
    let w   = 0

    call s:create_group()

    if a:mode ==# 'v'     | call s:vchar()
    elseif a:mode ==# 'V' | call s:vline()

        call s:G.split_lines()
        call s:G.remove_empty_lines()

    else
        let w = s:vblock()
        if w | exe "normal ".w."l" | endif
    endif

    call s:remove_group(0)
    call s:G.update_and_select_region(0, s:v.IDs_list[-1])
    if w | call s:F.toggle_option('block_mode', 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#visual#subtract(mode)

    call s:create_group()

    if a:mode ==# 'v'     | call s:vchar()
    elseif a:mode ==# 'V' | call s:vline()
    else
        let w = s:vblock()
        if w | exe "normal ".w."l" | endif
    endif

    call s:remove_group(1)
    call s:G.rebuild_from_map()
    call s:G.update_and_select_region(0, s:v.IDs_list[-1])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:vchar()
    "characterwise
    silent keepjumps normal! `<y`>`]
    call s:G.new_region()
endfun

fun! s:vline()
    "linewise
    silent keepjumps normal! '<y'>`]
    call s:G.new_region()
endfun

fun! s:vblock()
    "blockwise
    let start = getpos('.')[1:2]
    keepjumps normal! `>
    let end = getpos('.')[1:2]
    let w = end[1] - start[1]

    "create cursors downwards until end of block
    call cursor([start[0], start[1]])
    let r = s:G.new_cursor()

    while getpos('.')[1] < end[0]
        call vm#commands#add_cursor_down(0, 1)
    endwhile

    return w
endfun

fun! s:create_group()
    "use a temporary regions group, so that it won't interfere with previous regions
    let s:old_group = s:v.active_group
    let s:v.active_group = -1
    let s:V.Groups[-1] = []
endfun

fun! s:remove_group(subtract)
    "remove temporary region group
    for r in s:V.Groups[-1]
        if a:subtract | call r.clear(1)
        else          | let r.group = s:old_group | endif
    endfor

    let s:v.active_group = s:old_group | call remove(s:V.Groups, -1)
    let s:v.silence = 0
endfun
