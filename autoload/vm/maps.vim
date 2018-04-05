let s:NVIM = has('gui_running') || has('nvim')

let s:motions = ['w', 'W', 'b', 'B', 'e', 'E', '$', '0', '^', 'x']
let s:find = ['f', 'F', 't', 'T']
let s:simple = ['h', 'j', 'k', 'l']


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nmap     <silent> <nowait> <buffer>        <M-C-Down>  :call vm#commands#add_cursor_at_pos(1)<cr>
    nmap     <silent> <nowait> <buffer>        <M-C-Up>    :call vm#commands#add_cursor_at_pos(2)<cr>
    nmap     <silent> <nowait> <buffer>        <C-Down>    :call vm#commands#find_next(0, 1)<cr>
    nmap     <silent> <nowait> <buffer>        <C-Up>      :call vm#commands#find_prev(0, 1)<cr>
    nmap     <silent> <nowait> <buffer> <expr> <S-Right>   vm#commands#motion('l')
    nmap     <silent> <nowait> <buffer> <expr> <S-Left>    vm#commands#motion('h')
    nmap     <silent> <nowait> <buffer> <expr> <C-S-Right> vm#commands#motion('e')
    nmap     <silent> <nowait> <buffer> <expr> <C-S-Left>  vm#commands#motion('b')
endfun

fun! s:hjkl()
    nmap     <silent> <nowait> <buffer>        <M-j>       :call vm#commands#add_cursor_at_pos(1)<cr>
    nmap     <silent> <nowait> <buffer>        <M-k>       :call vm#commands#add_cursor_at_pos(2)<cr>
    nmap     <silent> <nowait> <buffer>        J           :call vm#commands#find_next(0, 1)<cr>
    nmap     <silent> <nowait> <buffer>        K           :call vm#commands#find_prev(0, 1)<cr>
    nmap     <silent> <nowait> <buffer> <expr> h           vm#commands#motion('h')
    nmap     <silent> <nowait> <buffer> <expr> j           vm#commands#motion('j')
    nmap     <silent> <nowait> <buffer> <expr> k           vm#commands#motion('k')
    nmap     <silent> <nowait> <buffer> <expr> l           vm#commands#motion('l')
    nnoremap <silent> <nowait> <buffer>        <C-h>       h
    nnoremap <silent> <nowait> <buffer>        <C-j>       j
    nnoremap <silent> <nowait> <buffer>        <C-k>       k
    nnoremap <silent> <nowait> <buffer>        <C-l>       l
    nmap     <silent> <nowait> <buffer> <expr> <M-J>       vm#commands#motion('J')
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
    nunmap <buffer> J
    nunmap <buffer> K
    nunmap <buffer> h
    nunmap <buffer> j
    nunmap <buffer> k
    nunmap <buffer> l
    silent! nunmap <buffer> <C-h>
    silent! nunmap <buffer> <C-j>
    silent! nunmap <buffer> <C-k>
    silent! nunmap <buffer> <C-l>
    nunmap <buffer> <M-J>
endfun

fun! vm#maps#start()
    nmap <silent> <nowait> <buffer> <esc> :call vm#funcs#reset()<cr>
    nmap <silent> <nowait> <buffer> <c-w> :call vm#commands#toggle_whole_word()<cr>
    nmap <silent> <nowait> <buffer> <c-m> :call vm#merge_regions()<cr>
    nmap <silent> <nowait> <buffer> <c-]> :call vm#funcs#update_search()<cr>
    nmap <silent> <nowait> <buffer> s     :call vm#commands#skip()<cr>
    nmap <silent> <nowait> <buffer> *     :call vm#commands#find_under(0, 0, 0, 1)<cr>
    nmap <silent> <nowait> <buffer> @     :call vm#commands#find_under(0, 1, 0, 1)<cr>
    nmap <silent> <nowait> <buffer> ]     :call vm#commands#find_next(0, 0)<cr>
    nmap <silent> <nowait> <buffer> [     :call vm#commands#find_prev(0, 0)<cr>
    nmap <silent> <nowait> <buffer> }     :call vm#commands#find_under(0, 0, 0, 1)<cr>
    nmap <silent> <nowait> <buffer> {     :call vm#commands#find_under(0, 1, 0, 1)<cr>
    xmap <silent> <nowait> <buffer> ]     y:call vm#commands#find_under(1, 0, 0, 1)<cr>`]
    xmap <silent> <nowait> <buffer> [     boey:call vm#commands#find_under(1, 1, 0, 1)<cr>`]
    xmap <silent> <nowait> <buffer> }     BoEy:call vm#commands#find_under(1, 0, 1, 1)<cr>`]
    xmap <silent> <nowait> <buffer> {     BoEy:call vm#commands#find_under(1, 1, 1, 1)<cr>`]

    if s:NVIM
        nmap <silent> <nowait> <buffer> <c-space>  :call vm#commands#add_cursor_at_pos(0)<cr>
    else
        nmap <silent> <nowait> <buffer> <nul>      :call vm#commands#add_cursor_at_pos(0)<cr>
    endif

    for m in s:motions
        exe "nmap <silent> <nowait> <buffer> <expr> ".m." vm#commands#motion('".m."')"
    endfor
    for m in s:find
        exe "nmap <silent> <nowait> <buffer> <expr> ".m." vm#commands#find_motion('".m."')"
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
    nmap <silent> <nowait> <buffer> q :call vm#commands#select_motion(0)<cr>
    nmap <silent> <nowait> <buffer> Q :call vm#commands#select_motion(1)<cr>
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps remove
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#end()
    nunmap <buffer> <esc>
    nunmap <buffer> <c-w>
    nunmap <buffer> <c-m>
    nunmap <buffer> <c-]>
    nunmap <buffer> *
    nunmap <buffer> @
    silent! nunmap <buffer> <c-space>
    silent! nunmap <buffer> <nul>
    nunmap <buffer> s
    nunmap <buffer> q
    nunmap <buffer> Q
    nunmap <buffer> [
    nunmap <buffer> ]
    nunmap <buffer> {
    nunmap <buffer> }
    xunmap <buffer> [
    xunmap <buffer> ]
    xunmap <buffer> {
    xunmap <buffer> }

    for m in (s:motions + s:find + s:simple)
        exe "nunmap <buffer> ".m
    endfor

    if g:VM_use_arrow_keys == 1
        call s:arrows_end()
    elseif g:VM_use_arrow_keys == 2
        call s:arrows_end()
        call s:hjkl_end()
    else
        call s:hjkl_end()
    endif
endfun
