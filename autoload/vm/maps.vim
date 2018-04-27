""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#init()
    let s:V = b:VM_Selection
    return s:Maps
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Global mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#default()
    if g:VM_sublime_mappings
        nmap <silent> <M-C-Down>  <Plug>(VM-Select-Cursor-Down)
        nmap <silent> <M-C-Up>    <Plug>(VM-Select-Cursor-Up)
        nmap <silent> <S-Down>    <Plug>(VM-Select-j)
        nmap <silent> <S-Up>      <Plug>(VM-Select-k)
        nmap <silent> <S-Right>   <Plug>(VM-Select-l)
        nmap <silent> <S-Left>    <Plug>(VM-Select-h)
        nmap <silent> <C-S-Right> <Plug>(VM-Select-w)
        nmap <silent> <C-S-Left>  <Plug>(VM-Select-b)
        nmap <silent> <C-S-Down>  <Plug>(VM-Select-Line-Down)
        nmap <silent> <C-S-Up>    <Plug>(VM-Select-Line-Up)
        nmap <silent> <M-C-Right> <Plug>(VM-Select-E)
        nmap <silent> <M-C-Left>  <Plug>(VM-Fast-Back)
        nmap <silent> <C-d>       <Plug>(VM-Find-I-Word)
    endif

    if g:VM_default_mappings

        nmap <silent> gs         <Plug>(VM-Select-Operator)

        nmap <silent> g<space>   <Plug>(VM-Add-Cursor-At-Pos)
        nmap <silent> g<cr>      <Plug>(VM-Add-Cursor-At-Word)
        nmap <silent> g/         <Plug>(VM-Start-Regex-Search)

        nmap <silent> <M-A>      <Plug>(VM-Select-All)
        xmap <silent> <M-A>      <Plug>(VM-Select-All)
        nmap <silent> <M-j>      <Plug>(VM-Add-Cursor-Down)
        nmap <silent> <M-k>      <Plug>(VM-Add-Cursor-Up)

        nmap <silent> s]         <Plug>(VM-Find-I-Word)
        nmap <silent> s[         <Plug>(VM-Find-A-Word)
        nmap <silent> s}         <Plug>(VM-Find-I-Whole-Word)
        nmap <silent> s{         <Plug>(VM-Find-A-Whole-Word)
        xmap <silent> s]         <Plug>(VM-Find-A-Subword)
        xmap <silent> s[         <Plug>(VM-Find-A-Whole-Subword)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:NVIM = has('gui_running') || has('nvim')

let s:simple   = split('nNqQU*#o[]{}?/:uMS', '\zs')

let s:zeta     = ['Z', 'z0n', 'z0N'] + map(split('z-+qQvVnN@.', '\zs'), '"z".v:val')
let s:ctr_maps = ['h', 'l', 'w', 'c' ]
let s:cx_maps  = ['t', '/', ']', '}', 's', 'S', '<F12>', '"']
let s:alt_maps = ['j', 'k', ']', 'q', 'BS', 'm' ]
let s:leader   = []
let s:leader2  = []
let s:fkeys    = ['1', '2']
let s:sfkeys   = ['2']
let s:edit     = split('dcpPyxXraAiIOJ', '\zs')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer maps init
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Maps = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.mappings(activate, ...) dict
    let s:noremaps = g:VM_custom_noremaps
    let s:remaps   = g:VM_custom_remaps

    if a:activate && !g:VM.mappings_enabled
        let g:VM.mappings_enabled = 1
        call self.start()
        call self.default_stop()
        for m in (g:VM.motions + g:VM.find_motions)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
        endfor
        for m in keys(s:noremaps)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".s:noremaps[m].")"
        endfor
        for m in keys(s:remaps)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Remap-Motion-".s:remaps[m].")"
        endfor
    elseif !a:activate && g:VM.mappings_enabled
        call self.end()
        call vm#maps#default()
        let g:VM.mappings_enabled = 0
        for m in (g:VM.motions + g:VM.find_motions)
            exe "nunmap <buffer> ".m
        endfor
        for m in ( keys(s:noremaps) + keys(s:remaps) )
            exe "silent! nunmap <buffer> ".m
        endfor
    endif
endfun

fun! s:Maps.mappings_toggle() dict
    let activate = !g:VM.mappings_enabled
    call self.mappings(activate)
    call s:V.Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.start() dict

    if g:VM_sublime_mappings
        nmap     <silent> <nowait> <buffer> <C-s>  <Plug>(VM-Skip-Region)
        nmap     <silent> <nowait> <buffer> <F2>   <Plug>(VM-Goto-Next)
        nmap     <silent> <nowait> <buffer> <S-F2> <Plug>(VM-Goto-Prev)
    endif

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)

    "basic mappings
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Tab>      <Plug>(VM-Switch-Mode)
    nmap     <silent> <nowait> <buffer> <M-BS>     <Plug>(VM-Erase-Regions)
    nmap     <silent> <nowait> <buffer> <BS>       <Plug>(VM-Toggle-Block)
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
    nmap     <silent> <nowait> <buffer> <F1>       <Plug>(VM-Show-Help)
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
    nmap <silent>          <buffer> s               <Plug>(VM-Select-All-Operator)

    "shrink/enlarge
    nmap <silent> <nowait> <buffer> z-              <Plug>(VM-Motion-Shrink)
    nmap <silent> <nowait> <buffer> z+              <Plug>(VM-Motion-Enlarge)

    "normal/ex/visual
    nmap <silent> <nowait> <buffer> S               <Plug>(VM-Run-Surround)
    nmap          <nowait> <buffer> zz              <Plug>(VM-Run-Normal)
    nmap <silent> <nowait> <buffer> Z               <Plug>(VM-Run-Last-Normal)
    nmap          <nowait> <buffer> zv              <Plug>(VM-Run-Visual)
    nmap <silent> <nowait> <buffer> zV              <Plug>(VM-Run-Last-Visual)
    nmap          <nowait> <buffer> zq              <Plug>(VM-Run-Ex)
    nmap <silent> <nowait> <buffer> zQ              <Plug>(VM-Run-Last-Ex)
    nmap <silent> <nowait> <buffer> z@              <Plug>(VM-Run-Macro)
    nmap <silent> <nowait> <buffer> z.              <Plug>(VM-Run-Dot)
    nmap          <nowait> <buffer> zn              <Plug>(VM-Numbers)
    nmap <silent> <nowait> <buffer> zN              <Plug>(VM-Numbers-Append)
    nmap          <nowait> <buffer> z0n             <Plug>(VM-Zero-Numbers)
    nmap <silent> <nowait> <buffer> z0N             <Plug>(VM-Zero-Numbers-Append)

    "edit
    call self.edit_start()

    "double leader
    "nmap     <silent> <nowait> <buffer> <leader><leader>@ <Plug>(VM-Run-Macro-Replace)

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:arrows()
    nmap     <silent> <nowait> <buffer> <M-C-Down>  <Plug>(VM-Select-Cursor-Down)
    nmap     <silent> <nowait> <buffer> <M-C-Up>    <Plug>(VM-Select-Cursor-Up)
    nmap     <silent> <nowait> <buffer> <C-S-Down>  <Plug>(VM-Select-Line-Down)
    nmap     <silent> <nowait> <buffer> <C-S-Up>    <Plug>(VM-Select-Line-Up)

    nmap     <silent> <nowait> <buffer> <C-Down>    <Plug>(VM-Find-Next)
    nmap     <silent> <nowait> <buffer> <C-Up>      <Plug>(VM-Find-Prev)
    nmap     <silent> <nowait> <buffer> <M-Down>    <Plug>(VM-Goto-Next)
    nmap     <silent> <nowait> <buffer> <M-Up>      <Plug>(VM-Goto-Prev)

    nmap     <silent> <nowait> <buffer> <S-Down>    <Plug>(VM-Select-j)
    nmap     <silent> <nowait> <buffer> <S-Up>      <Plug>(VM-Select-k)
    nmap     <silent> <nowait> <buffer> <S-Right>   <Plug>(VM-Select-l)
    nmap     <silent> <nowait> <buffer> <S-Left>    <Plug>(VM-Select-h)
    nmap     <silent> <nowait> <buffer> <M-Right>   <Plug>(VM-This-Select-l)
    nmap     <silent> <nowait> <buffer> <M-Left>    <Plug>(VM-This-Select-h)


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

fun! s:Maps.end() dict
    for m in (s:simple + s:zeta)
        exe "nunmap <buffer> ".m
    endfor

    for m in (s:alt_maps)
        exe "nunmap <buffer> <M-".m.">"
    endfor

    for m in (s:ctr_maps)
        exe "nunmap <buffer> <C-".m.">"
    endfor

    for m in (s:fkeys)
        exe "nunmap <buffer> <F".m.">"
    endfor

    for m in (s:sfkeys)
        exe "nunmap <buffer> <S-F".m.">"
    endfor

    for m in (s:cx_maps)
        exe "nunmap <buffer> <C-x>".m
    endfor

    call self.edit_stop()

    for m in (s:leader2)
        exe "nunmap <buffer> <leader><leader>".m
    endfor

    if g:VM_sublime_mappings
        nunmap <buffer> <C-s>
    endif

    call s:arrows_end()

    nunmap <buffer> s

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
    nunmap <buffer> <C-S-Down>
    nunmap <buffer> <C-S-Up>
    nunmap <buffer> <M-Down>
    nunmap <buffer> <M-Up>
    nunmap <buffer> <S-Right>
    nunmap <buffer> <S-Left>
    nunmap <buffer> <M-Right>
    nunmap <buffer> <M-Left>
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

fun! s:Maps.edit_start() dict
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.edit_stop() dict
    for m in (s:edit)
        exe "silent! nunmap <buffer> ".m
    endfor
    silent! nunmap <buffer> <M-o>
    silent! nunmap <buffer> <del>
    silent! nunmap <buffer> <leader>y
    silent! nunmap <buffer> <C-t>
    silent! nunmap <buffer> <leader>p
    silent! nunmap <buffer> <leader>P
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.default_stop() dict
    if g:VM_sublime_mappings
        nunmap <M-C-Down>
        nunmap <M-C-Up>
        nunmap <S-Down>
        nunmap <S-Up>
        nunmap <S-Right>
        nunmap <S-Left>
        nunmap <C-S-Right>
        nunmap <C-S-Left>
        nunmap <C-S-Down>
        nunmap <C-S-Up>
        nunmap <M-C-Right>
        nunmap <M-C-Left>
        nunmap <C-d>
    endif

    if g:VM_default_mappings

        nunmap gs

        nunmap g<space>
        nunmap g<cr>
        nunmap g/

        nunmap <M-A>
        xunmap <M-A>
        nunmap <M-j>
        nunmap <M-k>

        nunmap s]
        nunmap s[
        nunmap s}
        nunmap s{
        xunmap s]
        xunmap s[
    endif
endfun
