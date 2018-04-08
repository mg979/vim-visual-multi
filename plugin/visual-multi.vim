""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Initialize variables

let s:NVIM                = has('gui_running') || has('nvim')

let g:VM_Global           = {'is_active': 0, 'extend_mode': 0}
let b:VM_Selection        = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Custom variables
"NOT YET: sublime_mappings

call vm#plugs#init()
let g:VM_sublime_mappings  = get(g:, 'VM_sublime_mappings', 0)
let g:VM_custom_mappings   = get(g:, 'VM_custom_mappings', 0)
let g:VM_Custom_Noremaps   = get(g:, 'VM_Custom_Noremaps', {',': ';', ';': ','})
let g:VM_Custom_Remaps     = get(g:, 'VM_Custom_Remaps', [])
let g:VM_Extend_By_Default = get(g:, 'VM_Extend_By_Default', 0)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Set up highlighting

let g:VM_Selection_hl     = get(g:, 'VM_Selection_hl',     'Visual')
let g:VM_Mono_Cursor_hl   = get(g:, 'VM_Mono_Cursor_hl',   'DiffChange')
let g:VM_Normal_Cursor_hl = get(g:, 'VM_Normal_Cursor_hl', 'DiffAdd')
let g:VM_Message_hl       = get(g:, 'VM_Message_hl',       'WarningMsg')
exe "highlight link MultiCursor ".g:VM_Normal_Cursor_hl

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Global mappings

nmap <silent> g<space> <Plug>(VM-Add-Cursor-At-Pos)
nmap <silent> g<cr>    <Plug>(VM-Add-Cursor-At-Word)

nmap <silent> <M-A>    <Plug>(VM-Select-All)
xmap <silent> <M-A>    <Plug>(VM-Select-All)
nmap <silent> <M-j>    <Plug>(VM-Add-Cursor-Down)
nmap <silent> <M-k>    <Plug>(VM-Add-Cursor-Up)

nmap <silent> s]       <Plug>(VM-Find-I-Word)
nmap <silent> s[       <Plug>(VM-Find-A-Word)
nmap <silent> s}       <Plug>(VM-Find-I-Whole-Word)
nmap <silent> s{       <Plug>(VM-Find-A-Whole-Word)
xmap <silent> s]       <Plug>(VM-Find-A-Subword)
xmap <silent> s[       <Plug>(VM-Find-A-Whole-Subword)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Autocommands

au BufLeave * call vm#funcs#buffer_leave()
au BufEnter * call vm#funcs#buffer_enter()
