let s:NVIM = has('gui_running') || has('nvim')

let s:motions  = ['w', 'W', 'b', 'B', 'e', 'E']
let s:signs    = ['$', '0', '^', '%']
let s:find     = ['f', 'F', 't', 'T']
let s:simple   = ['h', 'j', 'k', 'l', 'd', 'p', 'P', 'y', 'n', 'N', 'q', 'Q', 'U', '*', '#', 'o', '[', ']', '{', '}', 'g', 'G', '?', '/', ':', '-', '+', 'M']

let s:ctr_maps = ['h', 'l', 'w', 'o', 'c', ]
let s:cx_maps  = ['t', 'm', '/', ']', '}', 's', 'S', '<F12>']
let s:alt_maps = ['j', 'k', 'J', '{', '}', ']']
let s:leader   = ['@', '/', 'y']

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#start()

    let s:noremaps = g:VM_custom_noremaps
    let s:remaps   = g:VM_custom_remaps

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)

    "basic mappings
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Tab>      <Plug>(VM-Switch-Mode)
    nmap     <silent> <nowait> <buffer> <BS>       <Plug>(VM-Erase-Regions)
    nmap     <silent> <nowait> <buffer> <CR>       <Plug>(VM-Toggle-Motions)
    nmap     <silent> <nowait> <buffer> <leader>/  <Plug>(VM-Start-Regex-Search)
    nmap     <silent> <nowait> <buffer> <leader>@  <Plug>(VM-Run-Macro)

    nmap     <silent> <nowait> <buffer> o          <Plug>(VM-Invert-Direction)
    nmap     <silent> <nowait> <buffer> q          <Plug>(VM-Skip-Region)
    nmap     <silent> <nowait> <buffer> Q          <Plug>(VM-Remove-Region)
    nmap     <silent> <nowait> <buffer> M          <Plug>(VM-Toggle-Multiline)
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

    "search
    nmap     <silent> <nowait> <buffer> <c-x>]     <Plug>(VM-Add-Search)
    nmap     <silent> <nowait> <buffer> <C-x>/     <Plug>(VM-Read-From-Search)
    nmap     <silent> <nowait> <buffer> <c-x>}     <Plug>(VM-Rewrite-All-Search)
    nmap     <silent> <nowait> <buffer> <M-]>      <Plug>(VM-Rewrite-Last-Search)

    "utility
    nmap              <nowait> <buffer> <C-x>t     <Plug>(VM-Show-Regions-Text)
    nmap     <silent> <nowait> <buffer> <C-x>m     <Plug>(VM-Merge-Regions)
    nmap     <silent> <nowait> <buffer> <C-x>s     <Plug>(VM-Remove-Search)
    nmap     <silent> <nowait> <buffer> <C-x>S     <Plug>(VM-Remove-Search-Regions)
    nmap     <silent> <nowait> <buffer> <c-x><F12> <Plug>(VM-Toggle-Debug)

    "ctrl
    nmap     <silent> <nowait> <buffer> <c-c>      <Plug>(VM-Case-Setting)
    nmap     <silent> <nowait> <buffer> <c-w>      <Plug>(VM-Toggle-Whole-Word)
    nmap     <silent> <nowait> <buffer> <c-o>      <Plug>(VM-Toggle-Only-This-Region)


    for m in keys(s:noremaps)
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".s:noremaps[m].")"
    endfor
    for m in keys(s:remaps)
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Remap-Motion-".s:remaps[m].")"
    endfor
    for m in s:signs
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
    endfor

    call s:arrows()
    call s:hjkl()

    "select
    nmap <silent>          <buffer> g               <Plug>(VM-Select-One-Inside)
    nmap <silent> <nowait> <buffer> G               <Plug>(VM-Select-All-Inside)

    "shrink/enlarge
    nmap <silent> <nowait> <buffer> -               <Plug>(VM-Motion-Shrink)
    nmap <silent> <nowait> <buffer> +               <Plug>(VM-Motion-Enlarge)

    nmap <silent> <nowait> <buffer> d               <Plug>(VM-Edit-Delete)
    nmap <silent> <nowait> <buffer> p               <Plug>(VM-Edit-Paste)
    nmap <silent> <nowait> <buffer> P               <Plug>(VM-Edit-Paste-Block)
    nmap <silent> <nowait> <buffer> y               <Plug>(VM-Edit-Yank)
    nmap <silent> <nowait> <buffer> <leader>y       <Plug>(VM-Edit-Hard-Yank)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nmap     <silent> <nowait> <buffer> <M-C-Down>  <Plug>(VM-Select-Down)
    nmap     <silent> <nowait> <buffer> <M-C-Up>    <Plug>(VM-Select-Up)

    nmap     <silent> <nowait> <buffer> <C-Down>    <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer> <C-Up>      <Plug>(VM-Find-Prev)
    nmap     <silent> <nowait> <buffer> <M-Down>      <Plug>(VM-Goto-Next)
    nmap     <silent> <nowait> <buffer> <M-Up>        <Plug>(VM-Goto-Prev)

    nmap     <silent> <nowait> <buffer> <S-Down>    <Plug>(VM-Motion-j)
    nmap     <silent> <nowait> <buffer> <S-Up>      <Plug>(VM-Motion-k)
    nmap     <silent> <nowait> <buffer> <S-Right>   <Plug>(VM-Motion-l)
    nmap     <silent> <nowait> <buffer> <S-Left>    <Plug>(VM-Motion-h)

    nmap     <silent> <nowait> <buffer> <C-Right>   <Plug>(VM-Select-e)
    nmap     <silent> <nowait> <buffer> <C-Left>    <Plug>(VM-End-Back)
    nmap     <silent> <nowait> <buffer> <C-S-Right> <Plug>(VM-Select-w)
    nmap     <silent> <nowait> <buffer> <C-S-Left>  <Plug>(VM-Select-b)
    nmap     <silent> <nowait> <buffer> <M-C-Right> <Plug>(VM-Select-E)
    nmap     <silent> <nowait> <buffer> <M-C-Left>  <Plug>(VM-Fast-Back)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:hjkl()
    nnoremap <silent> <nowait> <buffer> h           h
    nnoremap <silent> <nowait> <buffer> j           j
    nnoremap <silent> <nowait> <buffer> k           k
    nnoremap <silent> <nowait> <buffer> l           l

    "nmap     <silent> <nowait> <buffer> J           <Plug>(VM-Motion-j)
    "nmap     <silent> <nowait> <buffer> K           <Plug>(VM-Motion-k)
    "nmap     <silent> <nowait> <buffer> H           <Plug>(VM-Motion-h)
    "nmap     <silent> <nowait> <buffer> L           <Plug>(VM-Motion-l)

    nmap     <silent> <nowait> <buffer> <C-h>       <Plug>(VM-This-Motion-h)
    nmap     <silent> <nowait> <buffer> <C-l>       <Plug>(VM-This-Motion-l)

    nmap     <silent> <nowait> <buffer> <M-j>       <Plug>(VM-Add-Cursor-Down)
    nmap     <silent> <nowait> <buffer> <M-k>       <Plug>(VM-Add-Cursor-Up)

    nmap     <silent> <nowait> <buffer> <M-J>       <Plug>(VM-Motion-J)
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps remove
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#end()
    for m in (s:simple)
        exe "silent! nunmap <buffer> ".m
    endfor

    for m in (s:signs)
        exe "nunmap <buffer> ".m
    endfor

    for m in ( keys(s:noremaps) + keys(s:remaps) )
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

    for m in (s:leader)
        exe "nunmap <buffer> <leader>".m
    endfor

    call s:arrows_end()

    nunmap <buffer> <Tab>
    nunmap <buffer> <esc>
    nunmap <buffer> <BS>
    nunmap <buffer> <CR>

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
    nunmap <buffer> <M-Down>
    nunmap <buffer> <M-Up>
    nunmap <buffer> <S-Right>
    nunmap <buffer> <S-Left>
    nunmap <buffer> <S-Down>
    nunmap <buffer> <S-Up>
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

