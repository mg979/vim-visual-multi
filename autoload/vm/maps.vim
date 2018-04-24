let s:NVIM = has('gui_running') || has('nvim')

let s:simple   = ['d', 'c', 'p', 'P', 'y', 'n', 'N', 'q', 'Q', 'U', '*', '#', 'o', '[', ']', '{', '}', '?', '/', ':', '-', '+', 'u', 'x', 'X', 'r', 'M', 'a', 'A', 'i', 'I', 'O', 'J' ]

let s:zeta     = ['zz', 'za', 'zA', 'Z', 'zq', 'zQ', 'zv', 'zV', 'z@']
let s:ctr_maps = ['h', 'l', 'w', 'c', 't' ]
let s:cx_maps  = ['t', '/', ']', '}', 's', 'S', '<F12>', '"']
let s:alt_maps = ['j', 'k', ']', 'q', 'o', 'BS', 'm' ]
let s:leader   = ['y', 'p', 'P']
let s:leader2  = []

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#start()

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)

    "basic mappings
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Tab>      <Plug>(VM-Switch-Mode)
    nmap     <silent> <nowait> <buffer> <M-BS>     <Plug>(VM-Erase-Regions)
    nmap     <silent> <nowait> <buffer> <BS>       <Plug>(VM-Toggle-Block)
    nmap     <silent> <nowait> <buffer> <Space>    <Plug>(VM-Toggle-Motions)
    nmap     <silent> <nowait> <buffer> <CR>       <Plug>(VM-Toggle-Only-This-Region)

    nmap     <silent> <nowait> <buffer> o          <Plug>(VM-Invert-Direction)
    nmap     <silent> <nowait> <buffer> q          <Plug>(VM-Skip-Region)
    nmap     <silent> <nowait> <buffer> Q          <Plug>(VM-Remove-Region)
    nmap     <silent> <nowait> <buffer> <M-q>      <Plug>(VM-Remove-Last-Region)
    nmap     <silent> <nowait> <buffer> <M-m>      <Plug>(VM-Merge-Regions)
    nmap     <silent> <nowait> <buffer> M          <Plug>(VM-Toggle-Multiline)
    nmap     <silent> <nowait> <buffer> u          <Plug>(VM-Undo)
    nmap     <silent> <nowait> <buffer> U          <Plug>(VM-Undo-Visual)
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

    nmap     <silent> <nowait> <buffer> <S-End>    <Plug>(VM-Merge-To-Eol)
    nmap     <silent> <nowait> <buffer> <S-Home>   <Plug>(VM-Merge-To-Bol)

    "search
    nmap     <silent> <nowait> <buffer> <c-x>]     <Plug>(VM-Add-Search)
    nmap     <silent> <nowait> <buffer> <C-x>/     <Plug>(VM-Read-From-Search)
    nmap     <silent> <nowait> <buffer> <c-x>}     <Plug>(VM-Rewrite-All-Search)
    nmap     <silent> <nowait> <buffer> <M-]>      <Plug>(VM-Rewrite-Last-Search)

    "utility
    nmap              <nowait> <buffer> <C-x>t     <Plug>(VM-Show-Regions-Text)
    nmap              <nowait> <buffer> <C-x>"     <Plug>(VM-Show-Registers)
    nmap     <silent> <nowait> <buffer> <C-x>s     <Plug>(VM-Remove-Search)
    nmap     <silent> <nowait> <buffer> <C-x>S     <Plug>(VM-Remove-Search-Regions)
    nmap     <silent> <nowait> <buffer> <c-x><F12> <Plug>(VM-Toggle-Debug)

    "ctrl
    nmap     <silent> <nowait> <buffer> <c-c>      <Plug>(VM-Case-Setting)
    nmap     <silent> <nowait> <buffer> <c-w>      <Plug>(VM-Toggle-Whole-Word)


    call s:arrows()

    nmap     <silent> <nowait> <buffer> <C-h>       <Plug>(VM-This-Motion-h)
    nmap     <silent> <nowait> <buffer> <C-l>       <Plug>(VM-This-Motion-l)

    nmap     <silent> <nowait> <buffer> <M-j>       <Plug>(VM-Add-Cursor-Down)
    nmap     <silent> <nowait> <buffer> <M-k>       <Plug>(VM-Add-Cursor-Up)

    "select
    nmap <silent>          <buffer> s               <Plug>(VM-Select-Operator)

    nmap <silent> <nowait> <buffer> za              <Plug>(VM-Select-All-Inside)
    nmap <silent> <nowait> <buffer> zA              <Plug>(VM-Select-All-Around)

    "shrink/enlarge
    nmap <silent> <nowait> <buffer> -               <Plug>(VM-Motion-Shrink)
    nmap <silent> <nowait> <buffer> +               <Plug>(VM-Motion-Enlarge)

    "normal/ex/visual
    nmap          <nowait> <buffer> zz              <Plug>(VM-Run-Normal)
    nmap <silent> <nowait> <buffer> Z               <Plug>(VM-Run-Last-Normal)
    nmap          <nowait> <buffer> zv              <Plug>(VM-Run-Visual)
    nmap <silent> <nowait> <buffer> zV              <Plug>(VM-Run-Last-Visual)
    nmap          <nowait> <buffer> zq              <Plug>(VM-Run-Ex)
    nmap <silent> <nowait> <buffer> zQ              <Plug>(VM-Run-Last-Ex)
    nmap <silent> <nowait> <buffer> z@              <Plug>(VM-Run-Macro)

    "edit
    nmap <silent> <nowait> <buffer> i               <Plug>(VM-Edit-i-Insert)
    nmap <silent> <nowait> <buffer> I               <Plug>(VM-Edit-I-Insert)
    nmap <silent> <nowait> <buffer> a               <Plug>(VM-Edit-a-Append)
    nmap <silent> <nowait> <buffer> A               <Plug>(VM-Edit-A-Append)
    nmap <silent> <nowait> <buffer> O               <Plug>(VM-Edit-o-New-Line)
    nmap <silent> <nowait> <buffer> <M-o>           <Plug>(VM-Edit-O-New-Line)
    nmap <silent> <nowait> <buffer> x               <Plug>(VM-Edit-x)
    nmap <silent> <nowait> <buffer> X               <Plug>(VM-Edit-X)
    nmap <silent> <nowait> <buffer> J               <Plug>(VM-Edit-J)
    nmap <silent> <nowait> <buffer> <del>           <Plug>(VM-Edit-Del)
    nmap <silent> <nowait> <buffer> r               <Plug>(VM-Edit-Replace)
    nmap <silent> <nowait> <buffer> c               <Plug>(VM-Edit-Change)
    nmap <silent> <nowait> <buffer> d               <Plug>(VM-Edit-Delete)
    nmap <silent> <nowait> <buffer> y               <Plug>(VM-Edit-Yank)
    nmap <silent> <nowait> <buffer> <leader>y       <Plug>(VM-Edit-Soft-Yank)
    nmap <silent> <nowait> <buffer> <C-t>           <Plug>(VM-Edit-Transpose)

    nmap <silent> <nowait> <buffer> p               <Plug>(VM-Edit-p-Paste)
    nmap <silent> <nowait> <buffer> P               <Plug>(VM-Edit-P-Paste)
    nmap <silent> <nowait> <buffer> <leader>p       <Plug>(VM-Edit-p-Paste-Block)
    nmap <silent> <nowait> <buffer> <leader>P       <Plug>(VM-Edit-P-Paste-Block)

    "double leader
    "nmap     <silent> <nowait> <buffer> <leader><leader>@ <Plug>(VM-Run-Macro-Replace)

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nmap     <silent> <nowait> <buffer> <M-C-Down>  <Plug>(VM-Select-Down)
    nmap     <silent> <nowait> <buffer> <M-C-Up>    <Plug>(VM-Select-Up)
    nmap     <silent> <nowait> <buffer> <C-S-Down>  <Plug>(VM-Select-Line-Down)
    nmap     <silent> <nowait> <buffer> <C-S-Up>    <Plug>(VM-Select-Line-Up)

    nmap     <silent> <nowait> <buffer> <C-Down>    <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer> <C-Up>      <Plug>(VM-Find-Prev)
    nmap     <silent> <nowait> <buffer> <M-Down>    <Plug>(VM-Goto-Next)
    nmap     <silent> <nowait> <buffer> <M-Up>      <Plug>(VM-Goto-Prev)

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
    nmap     <silent> <nowait> <buffer> <M-S-Right> <Plug>(VM-Edit-Shift-Right)
    nmap     <silent> <nowait> <buffer> <M-S-Left>  <Plug>(VM-Edit-Shift-Left)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps remove
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#end()
    for m in (s:simple + s:zeta)
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

    for m in (s:leader2)
        exe "nunmap <buffer> <leader><leader>".m
    endfor

    call s:arrows_end()

    nunmap <buffer> s

    nunmap <buffer> <Tab>
    nunmap <buffer> <esc>
    nunmap <buffer> <BS>
    nunmap <buffer> <CR>
    nunmap <buffer> <Space>

    xunmap <buffer> *
    xunmap <buffer> #

    nunmap <buffer> <S-End>
    nunmap <buffer> <S-Home>
    nunmap <buffer> <Del>

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
    nunmap <buffer> <M-S-Right>
    nunmap <buffer> <M-S-Left>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#motions(activate, ...)
    let s:noremaps = g:VM_custom_noremaps
    let s:remaps   = g:VM_custom_remaps

    if a:activate && !g:VM.motions_enabled
        let g:VM.motions_enabled = 1
        for m in (g:VM.motions + g:VM.find_motions)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
        endfor
        for m in keys(s:noremaps)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".s:noremaps[m].")"
        endfor
        for m in keys(s:remaps)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Remap-Motion-".s:remaps[m].")"
        endfor
    elseif !a:activate && g:VM.motions_enabled
        let g:VM.motions_enabled = 0
        for m in (g:VM.motions + g:VM.find_motions)
            exe "nunmap <buffer> ".m
        endfor
        for m in ( keys(s:noremaps) + keys(s:remaps) )
            exe "silent! nunmap <buffer> ".m
        endfor
    endif
endfun

fun! vm#maps#motions_toggle()
    let activate = !g:VM.motions_enabled
    call vm#maps#motions(activate)
    call b:VM_Selection.Funcs.count_msg(1)
endfun

