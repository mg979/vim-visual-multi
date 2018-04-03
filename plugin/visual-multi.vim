let g:VM_Selection = {}

" Set up highlighting
highlight MultiCursor term=reverse cterm=reverse gui=reverse
highlight link Selection Visual

nmap s] :call vm#commands#find_under(0, 0, 0)<cr>
nmap s[ :call vm#commands#find_under(0, 1, 0)<cr>
nmap s} :call vm#commands#find_under(0, 0, 1)<cr>
nmap s{ :call vm#commands#find_under(0, 1, 1)<cr>
xmap s] y:call vm#commands#find_under(1, 0, 0)<cr>`]
xmap s[ y:call vm#commands#find_under(1, 1, 0)<cr>`]

