let s:NVIM = has('gui_running') || has('nvim')

" Set up highlighting
let g:VM_Selection_hl     = get(g:, 'VM_Selection_hl', 'Visual')
let g:VM_Mono_Cursor_hl   = get(g:, 'VM_Mono_Cursor_hl', 'DiffChange')
let g:VM_Normal_Cursor_hl = get(g:, 'VM_Normal_Cursor_hl', 'term=reverse cterm=reverse gui=reverse')

" mappings styles
let g:VM_use_arrow_keys   = get(g:, 'VM_use_arrow_keys', 2)
let g:VM_sublime_mappings = get(g:, 'VM_sublime_mappings', 0)

if s:NVIM
    nmap <c-space>  :call vm#commands#add_cursor_at_pos(0)<cr>
else
    nmap <nul>      :call vm#commands#add_cursor_at_pos(0)<cr>
endif

nmap <c-j>  :call vm#commands#add_cursor_at_pos(1)<cr>
nmap <c-k>  :call vm#commands#add_cursor_at_pos(2)<cr>
nmap s] :call vm#commands#find_under(0, 0, 0, 0)<cr>
nmap s[ :call vm#commands#find_under(0, 1, 0, 0)<cr>
nmap s} :call vm#commands#find_under(0, 0, 1, 0)<cr>
nmap s{ :call vm#commands#find_under(0, 1, 1, 0)<cr>
xmap s] y:call vm#commands#find_under(1, 0, 0, 0)<cr>`]
xmap s[ y:call vm#commands#find_under(1, 1, 0, 0)<cr>`]

au BufEnter * let b:VM_Selection = {}
