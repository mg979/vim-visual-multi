""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#init()
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
    let s:v.finding = 0
endfun

fun! s:init()
    let g:Vm.extend_mode = 1
    if !g:Vm.is_active       | call vm#init_buffer(0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:R      = { -> s:V.Regions }
    let s:single = { c -> index(split('hljkwebWEB$^0{}()%nN', '\zs'), c) >= 0 }
    let s:double = { c -> index(split('iafFtTg', '\zs'), c) >= 0              }
else
    let s:R      = function('vm#v74#regions')
    let s:single = function('vm#v74#single')
    let s:double = function('vm#v74#double')
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#select(all, count, ...)
    """Perform a yank, the autocmd will create the region.
    call s:init()

    if !a:all
        let g:Vm.selecting = 1
        call s:updatetime()
        silent! nunmap <buffer> y
        return
    endif

    let s:v.storepos = getpos('.')[1:2]
    call s:F.Scroll.get()

    if a:0 | return s:select('y'.a:1) | endif

    let abort = 0
    let s = ''                     | let n = ''
    let x = a:count>1? a:count : 1 | echo "Selecting: ".(x>1? x : '')

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

    let n = n<1? 1 : n
    let n = n*x>1? n*x : ''
    call s:select('y'.n.s)
    call s:G.select_region_at_pos('.')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:select(cmd)

    call s:updatetime()
    call s:V.Maps.disable(1)

    silent! nunmap <buffer> y

    let Rs = map(copy(s:R()), '[v:val.l, v:val.a]')
    call vm#commands#erase_regions()

    " issue #44: when using quotes text objects (i', i", etc), the marker ']
    " is positioned on the quote, not on the end of the yanked region
    " to correct this, select visually, then yank

    let cmd = index(['''', '"', '`'], a:cmd[-1:-1]) >= 0 ?
                \ 'v' . a:cmd[1:] . 'y' : a:cmd

    for r in Rs
        call cursor(r[0], r[1])
        exe "normal ".cmd
        call s:get_region(0)
    endfor

    call s:V.Maps.enable()
    let s:v.silence    = 0

    if !s:v.multiline
        for r in s:R()
            if r.h | call s:F.toggle_option('multiline') | break | endif
        endfor | endif

    nmap <silent><nowait><buffer> y <Plug>(VM-Yank)

    if empty(s:v.search) | let @/ = '' | endif
    call s:old_updatetime()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_region(add_pattern)
    """Create region with select operator.
    let R = s:G.is_region_at_pos('.')
    if !empty(R) | return R | endif

    let R = vm#region#new(0)
    if a:add_pattern
        call s:V.Search.add_if_empty()
    endif
    call s:F.restore_reg()
    return R
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#find(start, visual, ...)
    if a:start
        if !g:Vm.is_active
            call s:init()
            if a:visual
                "use search register if just starting from visual mode
                call s:V.Search.get_slash_reg(s:v.oldsearch[0])
            endif
        else
            call s:init()
        endif

        "ensure there is an active search
        if empty(s:v.search)
            if !len(s:R()) | call s:V.Search.get_slash_reg()
            else           | call s:V.Search.get() | endif
        endif

        call s:updatetime()
        let s:v.finding = 1
        let s:vblock = a:visual && mode() == "\<C-v>"
        let g:Vm.selecting = 1
        silent! nunmap <buffer> y
        return 'y'
    endif

    "set the cursor to the start of the yanked region, then find occurrences until end mark is met
    let [endline, endcol] = getpos("']")[1:2]
    keepjumps normal! `[
    let [startline, startcol] = getpos('.')[1:2]

    if !search(join(s:v.search, '\|'), 'znp', endline)
        call s:F.msg('No matches found.', 0)
        if !len(s:R())
            call vm#reset(1)
        else
            call s:G.update_map_and_select_region()
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

    if !len(s:R())
        call s:F.msg('No matches found. Exiting VM.', 0)
        call cursor(startline, startcol)
        call vm#reset(1)
    else
        call s:G.update_map_and_select_region()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#after_yank()
    if g:Vm.selecting
        let g:Vm.selecting = 0

        "find operator
        if s:v.finding
            let s:v.finding = 0
            call vm#operators#find(0, s:v.visual_regex)
            let s:v.visual_regex = 0
        else
            "select operator
            call s:get_region(1)
            let R = s:G.select_region_at_pos('.')
            call s:G.check_mutliline(0, R)
        endif

        call s:old_updatetime()
        nmap <silent> <nowait> <buffer> y <Plug>(VM-Yank)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:updatetime()
    """If not using TextYankPost, use CursorHold and reduce &updatetime.
    if g:Vm.oldupdate
        let &updatetime = 100
    endif
endfun

fun! s:old_updatetime()
    """Restore old &updatetime value.
    if g:Vm.oldupdate
        let &updatetime = g:Vm.oldupdate
    endif
endfun
