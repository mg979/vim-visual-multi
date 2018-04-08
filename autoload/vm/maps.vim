let s:NVIM = has('gui_running') || has('nvim')

let s:motions  = ['w', 'W', 'b', 'B', 'e', 'E', 'x']
let s:find     = ['f', 'F', 't', 'T', '$', '0', '^', '%']
let s:simple   = ['H', 'J', 'K', 'L', 'h', 'j', 'k', 'l', 'n', 'N', 'q', 'Q', 'U', '*', '@', '/']
let s:brackets = ['[', ']', '{', '}']

let s:noremaps = get(g:, 'VM_Custom_Noremaps', {})
let s:remaps   = get(g:, 'VM_Custom_Remaps', [])

nnoremap        <Plug>(VM-Case-Setting)       :call b:VM_Selection.Search.case()<cr>
nnoremap        <Plug>(VM-Update-Search)      :call b:VM_Selection.Search.update()<cr>
nnoremap        <Plug>(VM-Read-From-Search)   :call b:VM_Selection.Search.read()<cr>
nnoremap        <Plug>(VM-Start-Regex-Search) :call vm#commands#find_by_regex()<cr>/

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nnoremap     <silent> <nowait> <buffer>        <M-C-Down>  :call vm#commands#add_cursor_at_pos(1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <M-C-Up>    :call vm#commands#add_cursor_at_pos(2)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-Down>    :call vm#commands#find_next(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-Up>      :call vm#commands#find_prev(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <S-Right>   :call vm#commands#motion('l', 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        <S-Left>    :call vm#commands#motion('h', 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-S-Right> :call vm#commands#motion('e', 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-S-Left>  :call vm#commands#motion('b', 0)<cr>
endfun

fun! s:hjkl()
    nnoremap     <silent> <nowait> <buffer>        <M-j>       :call vm#commands#add_cursor_at_pos(1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <M-k>       :call vm#commands#add_cursor_at_pos(2)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-j>       :call vm#commands#find_next(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-k>       :call vm#commands#find_prev(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        H           :call vm#commands#motion('h', 0)<cr>

    "multiline disabled for now
    "nnoremap     <silent> <nowait> <buffer>        J           :call vm#commands#motion('j', 0)<cr>
    "nnoremap     <silent> <nowait> <buffer>        K           :call vm#commands#motion('k', 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        J           J
    nnoremap     <silent> <nowait> <buffer>        K           K

    nnoremap     <silent> <nowait> <buffer>        L           :call vm#commands#motion('l', 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        h           h
    nnoremap     <silent> <nowait> <buffer>        j           j
    nnoremap     <silent> <nowait> <buffer>        k           k
    nnoremap     <silent> <nowait> <buffer>        l           l
    nnoremap     <silent> <nowait> <buffer>        <C-h>       :call vm#commands#motion('h', 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-l>       :call vm#commands#motion('l', 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <M-J>       :call vm#commands#motion('J', 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        <S-End>     :call vm#commands#merge_to_beol(1, 0)<cr>
    nnoremap     <silent> <nowait> <buffer>        <S-Home>    :call vm#commands#merge_to_beol(0, 0)<cr>
endfun

fun! vm#maps#start()
    nmap <silent> <nowait> <buffer> <c-c> <Plug>(VM-Case-Setting)
    nmap <silent> <nowait> <buffer> <c-]> <Plug>(VM-Update-Search)
    nmap <silent> <nowait> <buffer> <M-/> <Plug>(VM-Read-From-Search)
    nmap          <nowait> <buffer> /     <Plug>(VM-Start-Regex-Search)

    nnoremap <silent> <nowait> <buffer> <esc> :call vm#funcs#reset()<cr>
    nnoremap <silent> <nowait> <buffer> <c-w> :call vm#commands#toggle_option('whole_word')<cr>
    nnoremap <silent> <nowait> <buffer> <c-o> :call vm#commands#toggle_option('only_this_always')<cr>
    nnoremap <silent> <nowait> <buffer> <c-m> :call vm#merge_regions()<cr>
    nnoremap <silent> <nowait> <buffer> <c-a> :call vm#commands#find_all(0, 1, 0)<cr>
    nnoremap <silent> <nowait> <buffer> q     :call vm#commands#skip(0)<cr>
    nnoremap <silent> <nowait> <buffer> Q     :call vm#commands#skip(1)<cr>
    nnoremap <silent> <nowait> <buffer> U     :call vm#commands#undo()<cr>
    nnoremap <silent> <nowait> <buffer> *     :call vm#commands#add_under(0, 1, 0, 1)<cr>
    nnoremap <silent> <nowait> <buffer> @     :call vm#commands#add_under(0, 1, 1, 1)<cr>
    nnoremap <silent> <nowait> <buffer> ]     :call vm#commands#find_next(0, 0)<cr>
    nnoremap <silent> <nowait> <buffer> [     :call vm#commands#find_prev(0, 0)<cr>
    nnoremap <silent> <nowait> <buffer> }     :call vm#commands#add_under(0, 0, 0)<cr>
    nnoremap <silent> <nowait> <buffer> {     :call vm#commands#add_under(0, 1, 0)<cr>

    xnoremap <silent> <nowait> <buffer> <c-a> y:call vm#commands#find_all(0, 1, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> *     y:call vm#commands#add_under(1, 0, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> ]     y:call vm#commands#add_under(1, 0, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> [     boey:call vm#commands#add_under(1, 1, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> }     BoEy:call vm#commands#add_under(1, 0, 1)<cr>`]
    xnoremap <silent> <nowait> <buffer> {     BoEy:call vm#commands#add_under(1, 1, 1)<cr>`]

    nnoremap <silent> <nowait> <buffer> n     n
    nnoremap <silent> <nowait> <buffer> N     N

    if s:NVIM
        nnoremap <silent> <nowait> <buffer> <c-space>  :call vm#commands#add_cursor_at_pos(0)<cr>
    else
        nnoremap <silent> <nowait> <buffer> <nul>      :call vm#commands#add_cursor_at_pos(0)<cr>
    endif

    for m in s:motions
        exe "nnoremap <silent> <nowait> <buffer> ".m." :call vm#commands#motion('".m."', 0)\<cr>"
    endfor
    for m in keys(s:noremaps)
        exe "nnoremap <silent> <nowait> <buffer> ".m." :call vm#commands#motion('".s:noremaps[m]."', 0)\<cr>"
    endfor
    for m in s:remaps
        exe "nmap <silent> <nowait> <buffer>     ".m." :call vm#commands#motion('".m."', 0)\<cr>"
    endfor
    for m in s:find
        exe "nnoremap <silent> <nowait> <buffer> ".m." :call vm#commands#find_motion('".m."', '', 0)\<cr>"
    endfor

    if g:VM_use_arrow_keys == 1
        call s:arrows()
    elseif g:VM_use_arrow_keys == 2
        call s:arrows()
        call s:hjkl()
    else
        call s:hjkl()
    endif

    "select
    nnoremap <silent> <nowait> <buffer> g  :call vm#commands#select_motion(0, 1)<cr>
    nnoremap <silent> <nowait> <buffer> gi :call vm#commands#select_motion(0, 1)<cr>
    nnoremap <silent> <nowait> <buffer> ga :call vm#commands#select_motion(1, 1)<cr>
    nnoremap <silent> <nowait> <buffer> G  :call vm#commands#select_motion(0, 0)<cr>
    nnoremap <silent> <nowait> <buffer> Gi :call vm#commands#select_motion(0, 0)<cr>
    nnoremap <silent> <nowait> <buffer> Ga :call vm#commands#select_motion(1, 0)<cr>
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps remove
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#end()
    for m in (s:motions + s:find + s:simple + s:remaps)
        exe "nunmap <buffer> ".m
    endfor

    for m in keys(s:noremaps)
        exe "nunmap <buffer> ".m
    endfor

    for m in (s:brackets)
        exe "nunmap <buffer> ".m
        exe "xunmap <buffer> ".m
    endfor

    if g:VM_use_arrow_keys == 1
        call s:arrows_end()
    elseif g:VM_use_arrow_keys == 2
        call s:arrows_end()
        call s:hjkl_end()
    else
        call s:hjkl_end()
    endif

    xunmap <buffer> *
    nunmap <buffer> <esc>
    nunmap <buffer> <c-w>
    nunmap <buffer> <c-o>
    nunmap <buffer> <c-c>
    nunmap <buffer> <c-a>
    xunmap <buffer> <c-a>
    nunmap <buffer> <c-m>
    nunmap <buffer> <c-]>
    nunmap <buffer> <M-/>
    nunmap <buffer> <S-End>
    nunmap <buffer> <S-Home>
    nunmap <buffer> g
    nunmap <buffer> gi
    nunmap <buffer> ga
    nunmap <buffer> G
    nunmap <buffer> Gi
    nunmap <buffer> Ga
    silent! nunmap <buffer> <c-space>
    silent! nunmap <buffer> <nul>
endfun

fun! s:arrows_end()
    nunmap <buffer> <M-C-Down>
    nunmap <buffer> <M-C-Up>
    nunmap <buffer> <C-Down>
    nunmap <buffer> <C-Up>
    nunmap <buffer> <S-Right>
    nunmap <buffer> <S-Left>
    nunmap <buffer> <C-S-Right>
    nunmap <buffer> <C-S-Left>
endfun

fun! s:hjkl_end()
    nunmap <buffer> <M-j>
    nunmap <buffer> <M-k>
    nunmap <buffer> <C-h>
    nunmap <buffer> <C-j>
    nunmap <buffer> <C-k>
    nunmap <buffer> <C-l>
    nunmap <buffer> <M-J>
endfun

