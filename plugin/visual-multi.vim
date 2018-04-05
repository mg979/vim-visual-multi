let g:VM_Selection = {}

" Set up highlighting
let g:VM_Selection_hl     = get(g:, 'VM_Selection_hl', 'Visual')
let g:VM_Mono_Cursor_hl   = get(g:, 'VM_Mono_Cursor_hl', 'DiffChange')
let g:VM_Normal_Cursor_hl = get(g:, 'VM_Normal_Cursor_hl', 'term=reverse cterm=reverse gui=reverse')

nmap s] :call vm#commands#find_under(0, 0, 0)<cr>
nmap s[ :call vm#commands#find_under(0, 1, 0)<cr>
nmap s} :call vm#commands#find_under(0, 0, 1)<cr>
nmap s{ :call vm#commands#find_under(0, 1, 1)<cr>
xmap s] y:call vm#commands#find_under(1, 0, 0)<cr>`]
xmap s[ y:call vm#commands#find_under(1, 1, 0)<cr>`]

