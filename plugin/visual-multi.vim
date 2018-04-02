let g:VM_Selection = {}

" Set up highlighting
highlight MultiCursor term=reverse cterm=reverse gui=reverse
highlight link Selection Visual

nmap s] :call cursors#find_under(0, 0)<cr>
nmap s[ :call cursors#find_under(0, 1)<cr>
xmap s] y:call cursors#find_under(1, 0)<cr>`]

