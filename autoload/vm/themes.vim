let s:Themes = {}

fun! vm#themes#init()
  let default = &background == 'light' ? 'lightblue1' : 'blue1'
  let theme = get(g:, 'VM_theme', default)

  silent! hi clear VM_Mono
  silent! hi clear VM_Cursor
  silent! hi clear VM_Extend
  silent! hi clear VM_Insert
  exe "highlight VM_Mono"   s:Themes[theme].mono
  exe "highlight VM_Cursor" s:Themes[theme].cursor
  exe "highlight VM_Extend" s:Themes[theme].extend
  exe "highlight VM_Insert" s:Themes[theme].insert
  let g:VM_Message_hl = get(g:, 'VM_Message_hl', 'WarningMsg')
  highlight link MultiCursor VM_Cursor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#themes#load(theme)
  """Load a theme."""
  if empty(a:theme) | echo "Theme name required" | return
  elseif index(keys(s:Themes), a:theme) < 0 | echo "No such theme." | return | endif
  let g:VM_theme = a:theme
  call vm#themes#init()
endfun

fun! vm#themes#complete(A, L, P)
  let valid = []
  for k in keys(s:Themes)
    if     &background=='light' && s:Themes[k].type != 'light'
    elseif &background=='dark'  && s:Themes[k].type != 'dark'
    else
      call add(valid, k)
    endif
  endfor
  return sort(valid)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"old mono #F2C38F
"missing: grey(see neodark), acqua/lightacqua(see seoul)
let s:Themes.blue1 = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=24  guibg=#005f87",
      \ 'cursor': "ctermbg=31  guibg=#0087af ctermfg=237 guifg=#3a3a3a",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=180 guibg=#dfaf87 ctermfg=235 guifg=#262626",
      \}

let s:Themes.blue2 = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=25  guibg=#005faf",
      \ 'cursor': "ctermbg=39  guibg=#00afff ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=186 guibg=#dfdf87 ctermfg=239 guifg=#4e4e4e",
      \}

let s:Themes.blue3 = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=26  guibg=#005fdf",
      \ 'cursor': "ctermbg=39  guibg=#00afff ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=221 guibg=#ffdf5f ctermfg=239 guifg=#4e4e4e",
      \}

let s:Themes.lightblue1 = {
      \ 'type':   "light",
      \ 'extend': "ctermbg=153 guibg=#afdfff",
      \ 'cursor': "ctermbg=111 guibg=#87afff ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=180 guibg=#dfaf87 ctermfg=235 guifg=#262626",
      \ 'mono':   "ctermbg=167 guibg=#df5f5f ctermfg=253 guifg=#dadada cterm=bold term=bold gui=bold",
      \}

let s:Themes.lightblue2 = {
      \ 'type':   "light",
      \ 'extend': "ctermbg=117 guibg=#87dfff",
      \ 'cursor': "ctermbg=111 guibg=#87afff ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=180 guibg=#dfaf87 ctermfg=235 guifg=#262626",
      \ 'mono':   "ctermbg=167 guibg=#df5f5f ctermfg=253 guifg=#dadada cterm=bold term=bold gui=bold",
      \}

let s:Themes.purple1 = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=60  guibg=#544a65",
      \ 'cursor': "ctermbg=103 guibg=#8787af ctermfg=54  guifg=#5f0087",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=135 guibg=#af5fff ctermfg=235 guifg=#262626",
      \}

let s:Themes.purple2 = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=60  guibg=#5f5f87",
      \ 'cursor': "ctermbg=103 guibg=#8787af ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=135 guibg=#af5fff ctermfg=235 guifg=#262626",
      \}

let s:Themes.lightpurple1 = {
      \ 'type':   "light",
      \ 'extend': "ctermbg=225 guibg=#ffdfff",
      \ 'cursor': "ctermbg=183 guibg=#dfafff ctermfg=54  guifg=#5f0087 cterm=bold term=bold gui=bold",
      \ 'insert': "ctermbg=146 guibg=#afafdf ctermfg=235 guifg=#262626",
      \ 'mono':   "ctermbg=135 guibg=#af5fff ctermfg=225 guifg=#ffdfff cterm=bold term=bold gui=bold",
      \}

let s:Themes.lightpurple2 = {
      \ 'type':   "light",
      \ 'extend': "ctermbg=189 guibg=#dfdfff",
      \ 'cursor': "ctermbg=183 guibg=#dfafff ctermfg=54  guifg=#5f0087 cterm=bold term=bold gui=bold",
      \ 'insert': "ctermbg=225 guibg=#ffdfff ctermfg=235 guifg=#262626",
      \ 'mono':   "ctermbg=135 guibg=#af5fff ctermfg=225 guifg=#ffdfff cterm=bold term=bold gui=bold",
      \}

