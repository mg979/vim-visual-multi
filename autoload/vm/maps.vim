let s:NVIM = has('gui_running') || has('nvim')

let s:motions  = ['w', 'W', 'b', 'B', 'e', 'E', 'x']
let s:find     = ['f', 'F', 't', 'T', '$', '0', '^', '%']
let s:simple   = ['H', 'J', 'K', 'L', 'h', 'j', 'k', 'l', 'n', 'N', 'q', 'Q', 'U', '*', '@', '/']
let s:brackets = ['[', ']', '{', '}']

let s:noremaps = get(g:, 'VM_Custom_Noremaps', {})
let s:remaps   = get(g:, 'VM_Custom_Remaps', [])

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nmap     <silent> <nowait> <buffer>            <M-C-Down>  <Plug>(VM-Add-Cursor-Down)
    nmap     <silent> <nowait> <buffer>            <M-C-Up>    <Plug>(VM-Add-Cursor-Up)
    nmap     <silent> <nowait> <buffer>            <C-Down>    <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer>            <C-Up>      <Plug>(VM-Find-Prev)
    nnoremap <silent> <nowait> <buffer>            <S-Right>   :call vm#commands#motion('l', 0)<cr>
    nnoremap <silent> <nowait> <buffer>            <S-Left>    :call vm#commands#motion('h', 0)<cr>
    nnoremap <silent> <nowait> <buffer>            <C-S-Right> :call vm#commands#motion('e', 0)<cr>
    nnoremap <silent> <nowait> <buffer>            <C-S-Left>  :call vm#commands#motion('b', 0)<cr>
endfun

fun! s:hjkl()
    nmap     <silent> <nowait> <buffer>            <M-j>       <Plug>(VM-Add-Cursor-Down)
    nmap     <silent> <nowait> <buffer>            <M-k>       <Plug>(VM-Add-Cursor-Up)
    nmap     <silent> <nowait> <buffer>            <C-j>       <Plug>(VM-Goto-Next)
    nmap     <silent> <nowait> <buffer>            <C-k>       <Plug>(VM-Goto-Prev)
    nmap     <silent> <nowait> <buffer>            <S-End>     <Plug>(VM-Merge-To-Eol)
    nmap     <silent> <nowait> <buffer>            <S-Home>    <Plug>(VM-Merge-To-Bol)

    nnoremap <silent> <nowait> <buffer>            H           :call vm#commands#motion('h', 0)<cr>

    "multiline disabled for now
    "nnoremap     <silent> <nowait> <buffer>            J           :call vm#commands#motion('j', 0)<cr>
    "nnoremap     <silent> <nowait> <buffer>            K           :call vm#commands#motion('k', 0)<cr>
    nnoremap <silent> <nowait> <buffer>            J           J
    nnoremap <silent> <nowait> <buffer>            K           K

    nnoremap <silent> <nowait> <buffer>            L           :call vm#commands#motion('l', 0)<cr>
    nnoremap <silent> <nowait> <buffer>            h           h
    nnoremap <silent> <nowait> <buffer>            j           j
    nnoremap <silent> <nowait> <buffer>            k           k
    nnoremap <silent> <nowait> <buffer>            l           l
    nnoremap <silent> <nowait> <buffer>            <C-h>       :call vm#commands#motion('h', 1)<cr>
    nnoremap <silent> <nowait> <buffer>            <C-l>       :call vm#commands#motion('l', 1)<cr>
    nnoremap <silent> <nowait> <buffer>            <M-J>       :call vm#commands#motion('J', 0)<cr>
endfun

fun! vm#maps#start()
    nmap     <silent> <nowait> <buffer> <Tab>      <Plug>(VM-Switch-Mode)
    nmap     <silent> <nowait> <buffer> <c-c>      <Plug>(VM-Case-Setting)
    nmap     <silent> <nowait> <buffer> <c-]>      <Plug>(VM-Update-Search)
    nmap     <silent> <nowait> <buffer> <M-/>      <Plug>(VM-Read-From-Search)
    nmap              <nowait> <buffer> /          <Plug>(VM-Start-Regex-Search)

    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <c-w>      <Plug>(VM-Toggle-Whole-Word)
    nmap     <silent> <nowait> <buffer> <c-o>      <Plug>(VM-Toggle-Only-This-Region)
    nmap     <silent> <nowait> <buffer> <M-m>      <Plug>(VM-Merge-Regions)
    nmap     <silent> <nowait> <buffer> <c-a>      <Plug>(VM-Select-All)
    nmap     <silent> <nowait> <buffer> q          <Plug>(VM-Skip-Region)
    nmap     <silent> <nowait> <buffer> Q          <Plug>(VM-Remove-Region)
    nnoremap <silent> <nowait> <buffer> U          :call vm#commands#undo()<cr>
    nnoremap <silent> <nowait> <buffer> *          :call vm#commands#add_under(0, 1, 0, 1)<cr>
    nnoremap <silent> <nowait> <buffer> @          :call vm#commands#add_under(0, 1, 1, 1)<cr>
    nmap     <silent> <nowait> <buffer> ]          <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer> [          <Plug>(VM-Find-Prev)
    nnoremap <silent> <nowait> <buffer> }          :call vm#commands#add_under(0, 0, 0)<cr>
    nnoremap <silent> <nowait> <buffer> {          :call vm#commands#add_under(0, 1, 0)<cr>

    xmap     <silent> <nowait> <buffer> <c-a>      <Plug>(VM-Select-All)
    xnoremap <silent> <nowait> <buffer> *          y:call vm#commands#add_under(1, 0, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> ]          y:call vm#commands#add_under(1, 0, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> [          boey:call vm#commands#add_under(1, 1, 0)<cr>`]
    xnoremap <silent> <nowait> <buffer> }          BoEy:call vm#commands#add_under(1, 0, 1)<cr>`]
    xnoremap <silent> <nowait> <buffer> {          BoEy:call vm#commands#add_under(1, 1, 1)<cr>`]

    nnoremap <silent> <nowait> <buffer> n          n
    nnoremap <silent> <nowait> <buffer> N          N

    if s:NVIM
        nnoremap <silent> <nowait> <buffer> <c-space>  :call vm#commands#add_cursor_at_pos(0)<cr>
    else
        nnoremap <silent> <nowait> <buffer> <nul>      :call vm#commands#add_cursor_at_pos(0)<cr>
    endif

    for m in s:motions
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
    endfor
    for m in keys(s:noremaps)
        exe "nnoremap <silent> <nowait> <buffer> ".m." :call vm#commands#motion('".s:noremaps[m]."', 0)\<cr>"
    endfor
    for m in s:remaps
        exe "nmap <silent> <nowait> <buffer>     ".m." :call vm#commands#motion('".m."', 0)\<cr>"
    endfor
    for m in s:find
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
    endfor

    call s:arrows()
    call s:hjkl()

    "select
    nmap <silent> <nowait> <buffer> g  <Plug>(VM-Select-One-Inside)
    nmap <silent> <nowait> <buffer> gi <Plug>(VM-Select-One-Inside)
    nmap <silent> <nowait> <buffer> ga <Plug>(VM-Select-One-Around)
    nmap <silent> <nowait> <buffer> G  <Plug>(VM-Select-All-Inside)
    nmap <silent> <nowait> <buffer> Gi <Plug>(VM-Select-All-Inside)
    nmap <silent> <nowait> <buffer> Ga <Plug>(VM-Select-All-Around)

    "utility
    nmap              <nowait> <buffer> <M-v>t <Plug>(VM-Show-Regions-Text)
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

    call s:arrows_end()
    call s:hjkl_end()

    xunmap <buffer> *
    nunmap <buffer> <Tab>
    nunmap <buffer> <esc>
    nunmap <buffer> <c-w>
    nunmap <buffer> <c-o>
    nunmap <buffer> <c-c>
    nunmap <buffer> <c-a>
    xunmap <buffer> <c-a>
    nunmap <buffer> <M-m>
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
    nunmap <buffer> <M-v>t
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

