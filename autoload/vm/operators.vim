""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#init() abort
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
endfun

fun! s:init() abort
    let g:Vm.extend_mode = 1
    if !g:Vm.buffer | call vm#init_buffer(0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:R      = { -> s:V.Regions }
let s:single = { c -> index(split('hljkwebWEB$^0{}()%nN', '\zs'), c) >= 0 }
let s:double = { c -> index(split('iafFtTg', '\zs'), c) >= 0              }


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#select(count, ...) abort
    call s:init()
    let pos = getpos('.')[1:2]
    call s:F.Scroll.get(1)

    if a:0 | return s:select(a:1) | endif

    let [ abort, s, n ] = [ 0, '', '' ]
    let x = a:count>1? a:count : 1
    echo "Selecting: ".(x>1? x : '')

    while 1
        let c = getchar()

        if c == 27 | let abort = 1      | break
        else       | let c = nr2char(c) | endif

        if str2nr(c) > 0
            let n .= c    | echon c

        elseif s:single(c)
            let s .= c    | echon c | break

        elseif s:double(c) || len(s)
            let s .= c    | echon c
            if len(s) > 1 | break   | endif

        else
            let abort = 1 | break
        endif
    endwhile

    if abort | return | endif

    " change $ in g_
    let s = substitute(s, '\$', 'g_', 'g')

    let n = n<1? 1 : n
    let n = n*x>1? n*x : ''
    call s:select(n . s)
    call s:G.update_and_select_region(pos)
    call s:F.Scroll.restore()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:select(obj) abort
    call s:updatetime()
    call s:V.Maps.disable(1)

    if a:obj =~ '"' || a:obj =~ "'"
        let cmd = 'v' . a:obj . 'y'
    else
        let cmd = 'y' . a:obj
    endif

    silent! nunmap <buffer> y

    let Rs = map(copy(s:R()), '[v:val.l, v:val.a]')
    call s:G.erase_regions()

    for r in Rs
        call cursor(r[0], r[1])
        exe "normal" cmd
        call s:get_region(0)
    endfor

    call s:V.Maps.enable()
    call s:G.check_mutliline(1)

    nmap <silent><nowait><buffer> y <Plug>(VM-Yank)

    if empty(s:v.search) | let @/ = '' | endif
    call s:old_updatetime()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#after_yank() abort
    "find operator
    if g:Vm.finding
        let g:Vm.finding = 0
        call vm#operators#find(0, s:v.visual_regex)
        let s:v.visual_regex = 0
        call s:old_updatetime()
        nmap <silent> <nowait> <buffer> y <Plug>(VM-Yank)
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_region(add_pattern) abort
    """Create region with select operator.
    let R = s:G.region_at_pos()
    if !empty(R) | return R | endif

    let R = vm#region#new(0)
    "R.txt can be different because yank != visual yank
    call R.update_content()
    if a:add_pattern
        call s:V.Search.add_if_empty()
    endif
    call s:F.restore_reg()
    return R
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#find(start, visual, ...) abort
    if a:start
        if !g:Vm.buffer
            call s:backup_map_find()
            if a:visual
                "use search register if just starting from visual mode
                call s:V.Search.get_slash_reg(s:v.oldsearch[0])
            endif
        else
            call s:V.Search.ensure_is_set()
            call s:backup_map_find()
        endif

        call s:updatetime()
        let g:Vm.finding = 1
        let s:vblock = a:visual && mode() == "\<C-v>"
        silent! nunmap <buffer> y
        return 'y'
    endif

    "set the cursor to the start of the yanked region, then find occurrences until end mark is met
    let [endline, endcol] = getpos("']")[1:2]
    keepjumps normal! `[
    let [startline, startcol] = getpos('.')[1:2]

    if !search(join(s:v.search, '\|'), 'znp', endline)
        call s:merge_find()
        if !len(s:R())
            call vm#reset(1)
        endif
        return
    endif

    let ows = &wrapscan
    set nowrapscan
    silent keepjumps normal! ygn
    if s:vblock
        let R = getpos('.')[2]
        if !( R < startcol || R > endcol )
            call s:G.new_region()
        endif
    else
        call s:G.new_region()
    endif

    while 1
        if !search(join(s:v.search, '\|'), 'znp', endline) | break | endif
        silent keepjumps normal! nygn
        if getpos("'[")[1] > endline
            break
        elseif s:vblock
            let R = getpos('.')[2]
            if ( R < startcol || R > endcol )
                continue
            endif
        endif
        call s:G.new_region()
    endwhile
    let &wrapscan = ows
    call s:merge_find()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:updatetime() abort
    """If not using TextYankPost, use CursorHold and reduce &updatetime.
    if g:Vm.oldupdate
        let &updatetime = 100
    endif
endfun

fun! s:old_updatetime() abort
    """Restore old &updatetime value.
    if g:Vm.oldupdate
        let &updatetime = g:Vm.oldupdate
    endif
endfun

fun! s:backup_map_find() abort
    "use temporary regions, they will be merged later
    call s:init()
    let s:Bytes = copy(s:V.Bytes)
    let s:V.Regions = []
    let s:V.Bytes = {}
    let s:v.index = -1
    let s:v.no_search = 1
    let s:v.eco = 1
endfun

fun! s:merge_find() abort
    let new_map = copy(s:V.Bytes)
    let s:V.Bytes = s:Bytes
    call s:G.merge_maps(new_map)
    unlet new_map
endfun

" vim: et ts=4 sw=4 sts=4 :
