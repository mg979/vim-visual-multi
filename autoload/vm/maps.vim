let s:NVIM = has('gui_running') || has('nvim')

let s:motions  = ['w', 'W', 'b', 'B', 'e', 'E', 'x']
let s:signs    = ['$', '0', '^', '%']
let s:find     = ['f', 'F', 't', 'T']
let s:simple   = ['H', 'J', 'K', 'L', 'h', 'j', 'k', 'l', 'n', 'N', 'q', 'Q', 'U', '*', '#', 'o', '[', ']', '{', '}', 'g', 'ga', 'gi', 'G', 'Ga', 'Gi', '?', '/', ':']

let s:ctr_maps = ['h', 'l', 'w', 'o', 'c', ]
let s:cx_maps  = ['t', 'm', '/', ']', 's', 'S']
let s:alt_maps = ['j', 'k', 'J', '{', '}', ]

let s:noremaps = get(g:VM, 'custom_noremaps', {})
let s:remaps   = get(g:VM, 'custom_remaps', [])

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:sublime()

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#start()

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)

    "basic mappings
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Tab>      <Plug>(VM-Switch-Mode)
    nmap     <silent> <nowait> <buffer> <BS>       <Plug>(VM-Motions-Toggle)
    nmap     <silent> <nowait> <buffer> <leader>/  <Plug>(VM-Start-Regex-Search)

    nmap     <silent> <nowait> <buffer> o          <Plug>(VM-Invert-Direction)
    nmap     <silent> <nowait> <buffer> q          <Plug>(VM-Skip-Region)
    nmap     <silent> <nowait> <buffer> Q          <Plug>(VM-Remove-Region)
    nmap     <silent> <nowait> <buffer> U          <Plug>(VM-Undo-Last)
    nnoremap <silent> <nowait> <buffer> n          n
    nnoremap <silent> <nowait> <buffer> N          N

    "movement / selection
    nmap     <silent> <nowait> <buffer> ]          <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer> [          <Plug>(VM-Find-Prev)
    nmap     <silent> <nowait> <buffer> }          <Plug>(VM-Goto-Next)
    nmap     <silent> <nowait> <buffer> {          <Plug>(VM-Goto-Prev)

    nmap     <silent> <nowait> <buffer> *          <Plug>(VM-Star)
    nmap     <silent> <nowait> <buffer> #          <Plug>(VM-Hash)
    xmap     <silent> <nowait> <buffer> *          <Plug>(VM-Star)
    xmap     <silent> <nowait> <buffer> #          <Plug>(VM-Hash)

    nmap     <silent> <nowait> <buffer> <M-}>      <Plug>(VM-Add-I-Word)
    nmap     <silent> <nowait> <buffer> <M-{>      <Plug>(VM-Add-A-Word)
    nmap     <silent> <nowait> <buffer> <S-End>    <Plug>(VM-Merge-To-Eol)
    nmap     <silent> <nowait> <buffer> <S-Home>   <Plug>(VM-Merge-To-Bol)

    "utility
    nmap              <nowait> <buffer> <C-x>t     <Plug>(VM-Show-Regions-Text)
    nmap     <silent> <nowait> <buffer> <C-x>m     <Plug>(VM-Merge-Regions)
    nmap     <silent> <nowait> <buffer> <C-x>/     <Plug>(VM-Read-From-Search)
    nmap     <silent> <nowait> <buffer> <c-x>]     <Plug>(VM-Rewrite-Search-Index)
    nmap     <silent> <nowait> <buffer> <C-x>s     <Plug>(VM-Remove-Search)
    nmap     <silent> <nowait> <buffer> <C-x>S     <Plug>(VM-Remove-Search-Regions)

    "ctrl
    nmap     <silent> <nowait> <buffer> <c-c>      <Plug>(VM-Case-Setting)
    nmap     <silent> <nowait> <buffer> <c-w>      <Plug>(VM-Toggle-Whole-Word)
    nmap     <silent> <nowait> <buffer> <c-o>      <Plug>(VM-Toggle-Only-This-Region)

    for m in keys(s:noremaps)
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".s:noremaps[m].")"
    endfor
    for m in s:remaps
        exe "nmap <silent> <nowait> <buffer>     ".m." :call vm#commands#motion('".m."', 0)\<cr>"
    endfor
    for m in s:signs
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nmap     <silent> <nowait> <buffer> <M-C-Down>  <Plug>(VM-Select-Down)
    nmap     <silent> <nowait> <buffer> <M-C-Up>    <Plug>(VM-Select-Up)

    nmap     <silent> <nowait> <buffer> <C-Down>    <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer> <C-Up>      <Plug>(VM-Find-Prev)
    nmap     <silent> <nowait> <buffer> <C-S-Down>  <Plug>(VM-Goto-Next)
    nmap     <silent> <nowait> <buffer> <C-S-Up>    <Plug>(VM-Goto-Prev)

    nmap     <silent> <nowait> <buffer> <S-Right>   <Plug>(VM-Motion-l)
    nmap     <silent> <nowait> <buffer> <S-Left>    <Plug>(VM-Motion-h)
    nmap     <silent> <nowait> <buffer> <C-Right>   <Plug>(VM-Motion-e)
    nmap     <silent> <nowait> <buffer> <C-Left>    <Plug>(VM-End-Back)
    nmap     <silent> <nowait> <buffer> <C-S-Right> <Plug>(VM-Motion-w)
    nmap     <silent> <nowait> <buffer> <C-S-Left>  <Plug>(VM-Motion-b)
    nmap     <silent> <nowait> <buffer> <M-C-Right> <Plug>(VM-Motion-E)
    nmap     <silent> <nowait> <buffer> <M-C-Left>  <Plug>(VM-Fast-Back)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:hjkl()
    nnoremap <silent> <nowait> <buffer> h           h
    nnoremap <silent> <nowait> <buffer> j           j
    nnoremap <silent> <nowait> <buffer> k           k
    nnoremap <silent> <nowait> <buffer> l           l

    nmap     <silent> <nowait> <buffer> <M-j>       <Plug>(VM-Add-Cursor-Down)
    nmap     <silent> <nowait> <buffer> <M-k>       <Plug>(VM-Add-Cursor-Up)


    "multiline disabled for now
    "nmap     <silent> <nowait> <buffer> J           <Plug>(VM-Motion-j)
    "nmap     <silent> <nowait> <buffer> K           <Plug>(VM-Motion-k)
    nnoremap <silent> <nowait> <buffer> J           J
    nnoremap <silent> <nowait> <buffer> K           K

    nmap     <silent> <nowait> <buffer> H           <Plug>(VM-Motion-h)
    nmap     <silent> <nowait> <buffer> L           <Plug>(VM-Motion-l)
    nmap     <silent> <nowait> <buffer> <C-h>       <Plug>(VM-This-Motion-h)
    nmap     <silent> <nowait> <buffer> <C-l>       <Plug>(VM-This-Motion-l)
    nmap     <silent> <nowait> <buffer> <M-J>       <Plug>(VM-Motion-J)
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps remove
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#end()
    for m in (s:simple + s:remaps)
        exe "nunmap <buffer> ".m
    endfor

    for m in (s:signs)
        exe "nunmap <buffer> ".m
    endfor

    for m in keys(s:noremaps)
        exe "nunmap <buffer> ".m
    endfor

    for m in (s:alt_maps)
        exe "nunmap <buffer> <M-".m.">"
    endfor

    for m in (s:ctr_maps)
        exe "nunmap <buffer> <C-".m.">"
    endfor

    for m in (s:cx_maps)
        exe "nunmap <buffer> <C-x>".m
    endfor

    call s:arrows_end()

    nunmap <buffer> <Tab>
    nunmap <buffer> <esc>
    nunmap <buffer> <BS>
    nunmap <buffer> <leader>/

    xunmap <buffer> *
    xunmap <buffer> #

    nunmap <buffer> <S-End>
    nunmap <buffer> <S-Home>

    silent! cunmap <buffer> <cr>
    silent! cunmap <buffer> <esc>
endfun

fun! s:arrows_end()
    nunmap <buffer> <M-C-Down>
    nunmap <buffer> <M-C-Up>
    nunmap <buffer> <C-Down>
    nunmap <buffer> <C-Up>
    nunmap <buffer> <C-S-Down>
    nunmap <buffer> <C-S-Up>
    nunmap <buffer> <S-Right>
    nunmap <buffer> <S-Left>
    nunmap <buffer> <C-Right>
    nunmap <buffer> <C-Left>
    nunmap <buffer> <C-S-Right>
    nunmap <buffer> <C-S-Left>
    nunmap <buffer> <M-C-Right>
    nunmap <buffer> <M-C-Left>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#motions(activate, ...)
    if a:activate && !g:VM.motions_enabled
        let g:VM.motions_enabled = 1
        for m in (s:motions + s:find)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
        endfor
    elseif !a:activate && g:VM.motions_enabled
        let g:VM.motions_enabled = 0
        for m in (s:motions + s:find)
            exe "nunmap <buffer> ".m
        endfor
    endif
endfun

fun! vm#maps#motions_toggle()
    let activate = !g:VM.motions_enabled
    call vm#maps#motions(activate)
    redraw! | call b:VM_Selection.Funcs.count_msg(0)
endfun

