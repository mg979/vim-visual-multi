let s:NVIM = has('gui_running') || has('nvim')

"load custom mappings file
let g:VM_custom_mappings  = get(g:, 'VM_custom_mappings', 0)

" Set up highlighting
let g:VM_Selection_hl     = get(g:, 'VM_Selection_hl', 'Visual')
let g:VM_Mono_Cursor_hl   = get(g:, 'VM_Mono_Cursor_hl', 'DiffChange')
let g:VM_Normal_Cursor_hl = get(g:, 'VM_Normal_Cursor_hl', 'term=reverse cterm=reverse gui=reverse')
exe "highlight MultiCursor ".g:VM_Normal_Cursor_hl

" mappings styles
let g:VM_use_arrow_keys   = get(g:, 'VM_use_arrow_keys', 2)
let g:VM_sublime_mappings = get(g:, 'VM_sublime_mappings', 0)

if s:NVIM
    nnoremap <c-space>  :call vm#commands#add_cursor_at_pos(0)<cr>
else
    nnoremap <nul>      :call vm#commands#add_cursor_at_pos(0)<cr>
endif

nnoremap <M-j>  :call vm#commands#add_cursor_at_pos(1)<cr>
nnoremap <M-k>  :call vm#commands#add_cursor_at_pos(2)<cr>
xnoremap <c-a> y:call vm#commands#find_all(0, 1, 0)<cr>`]
nnoremap <c-a> :call vm#commands#find_all(0, 1, 0)<cr>
nnoremap s] :call vm#commands#find_under(0, 0, 0)<cr>
nnoremap s[ :call vm#commands#find_under(0, 1, 0)<cr>
nnoremap s} :call vm#commands#find_under(0, 0, 1)<cr>
nnoremap s{ :call vm#commands#find_under(0, 1, 1)<cr>
xnoremap s] y:call vm#commands#find_under(1, 0, 0)<cr>`]
xnoremap s[ y:call vm#commands#find_under(1, 1, 0)<cr>`]

au BufEnter * let b:VM_Selection = {}
