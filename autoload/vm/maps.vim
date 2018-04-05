let s:NVIM = has('gui_running') || has('nvim')

let s:motions  = ['w', 'W', 'b', 'B', 'e', 'E', '$', '0', '^', 'x']
let s:find     = ['f', 'F', 't', 'T']
let s:simple   = ['H', 'J', 'K', 'L', 'h', 'j', 'k', 'l', 'n', 'N', 'q', 'Q', 's', 'U', '*', '@']
let s:brackets = ['[', ']', '{', '}']


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nnoremap     <silent> <nowait> <buffer>        <M-C-Down>  :call vm#commands#add_cursor_at_pos(1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <M-C-Up>    :call vm#commands#add_cursor_at_pos(2)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-Down>    :call vm#commands#find_next(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-Up>      :call vm#commands#find_prev(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer> <expr> <S-Right>   vm#commands#motion('l')
    nnoremap     <silent> <nowait> <buffer> <expr> <S-Left>    vm#commands#motion('h')
    nnoremap     <silent> <nowait> <buffer> <expr> <C-S-Right> vm#commands#motion('e')
    nnoremap     <silent> <nowait> <buffer> <expr> <C-S-Left>  vm#commands#motion('b')
endfun

fun! s:hjkl()
    nnoremap     <silent> <nowait> <buffer>        <M-j>       :call vm#commands#add_cursor_at_pos(1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <M-k>       :call vm#commands#add_cursor_at_pos(2)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-j>       :call vm#commands#find_next(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer>        <C-k>       :call vm#commands#find_prev(0, 1)<cr>
    nnoremap     <silent> <nowait> <buffer> <expr> H           vm#commands#motion('h')
    nnoremap     <silent> <nowait> <buffer> <expr> J           vm#commands#motion('j')
    nnoremap     <silent> <nowait> <buffer> <expr> K           vm#commands#motion('k')
    nnoremap     <silent> <nowait> <buffer> <expr> L           vm#commands#motion('l')
    nnoremap     <silent> <nowait> <buffer>        h           h
    nnoremap     <silent> <nowait> <buffer>        j           j
    nnoremap     <silent> <nowait> <buffer>        k           k
    nnoremap     <silent> <nowait> <buffer>        l           l
    nnoremap     <silent> <nowait> <buffer> <expr> <M-J>       vm#commands#motion('J')
endfun

fun! vm#maps#start()
    nnoremap <silent> <nowait> <buffer> <esc> :call vm#funcs#reset()<cr>
    nnoremap <silent> <nowait> <buffer> <c-w> :call vm#commands#toggle_whole_word()<cr>
    nnoremap <silent> <nowait> <buffer> <c-m> :call vm#merge_regions()<cr>
    nnoremap <silent> <nowait> <buffer> <c-]> :call vm#funcs#update_search()<cr>
    nnoremap <silent> <nowait> <buffer> <c-a> :call vm#commands#find_all(0, 1, 0)<cr>
    nnoremap <silent> <nowait> <buffer> s     :call vm#commands#skip()<cr>
    nnoremap <silent> <nowait> <buffer> U     :call vm#commands#undo()<cr>
    nnoremap <silent> <nowait> <buffer> *     :call vm#commands#add_under(0, 1, 0)<cr>
    nnoremap <silent> <nowait> <buffer> @     :call vm#commands#add_under(0, 1, 1)<cr>
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
        exe "nnoremap <silent> <nowait> <buffer> <expr> ".m." vm#commands#motion('".m."')"
    endfor
    for m in s:find
        exe "nnoremap <silent> <nowait> <buffer> <expr> ".m." vm#commands#find_motion('".m."')"
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
    nnoremap <silent> <nowait> <buffer> q :call vm#commands#select_motion(0)<cr>
    nnoremap <silent> <nowait> <buffer> Q :call vm#commands#select_motion(1)<cr>
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps remove
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#end()
    for m in (s:motions + s:find + s:simple)
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
    nunmap <buffer> <c-a>
    xunmap <buffer> <c-a>
    nunmap <buffer> <c-m>
    nunmap <buffer> <c-]>
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
    "nunmap <buffer> <C-h>
    nunmap <buffer> <C-j>
    nunmap <buffer> <C-k>
    "nunmap <buffer> <C-l>
    nunmap <buffer> <M-J>
endfun

