""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Set up highlighting

let g:Vm.hi.extend  = get(g:, 'VM_Selection_hl',     'Visual')
let g:Vm.hi.mono    = get(g:, 'VM_Mono_Cursor_hl',   'DiffChange')
let g:Vm.hi.insert  = get(g:, 'VM_Ins_Mode_hl',      'Pmenu')
let g:Vm.hi.cursor  = get(g:, 'VM_Normal_Cursor_hl', 'ToolbarLine')
let g:Vm.hi.message = get(g:, 'VM_Message_hl',       'WarningMsg')

exe "highlight link MultiCursor ".g:Vm.hi.cursor

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Themes = {}

fun! vm#themes#init() abort
  if !exists('g:Vm') | return | endif
  let default = &background == 'light' ? 'lightblue1' : 'blue1'
  let theme = get(g:, 'VM_theme', 'default')

  silent! hi clear VM_Mono
  silent! hi clear VM_Cursor
  silent! hi clear VM_Extend
  silent! hi clear VM_Insert
  silent! hi clear MultiCursor

  if !empty(g:VM_highlight_matches)
    let out = execute('highlight Search')
    let hi = strtrans(substitute(out, '^.*xxx ', '', ''))
    let hi = substitute(hi, '\^.', '', 'g')
    if match(hi, ' links to ') >= 0
      let hi = substitute(out, '^.*links to ', '', '')
      let g:Vm.search_hi = "hi! link Search ".hi
    else
      let g:Vm.search_hi = "hi! Search ".hi
    endif

    call vm#themes#hi()
  endif

  let g:Vm.hi.mono    = 'VM_Mono'
  let g:Vm.hi.cursor  = 'VM_Cursor'
  let g:Vm.hi.extend  = 'VM_Extend'
  let g:Vm.hi.insert  = 'VM_Insert'

  if theme == 'default'
    exe "highlight! link VM_Mono     ".get(g:, 'VM_Mono_hl',   'DiffText')
    exe "highlight! link VM_Cursor   ".get(g:, 'VM_Cursor_hl', 'Visual')
    exe "highlight! link VM_Extend   ".get(g:, 'VM_Extend_hl', 'DiffAdd')
    exe "highlight! link VM_Insert   ".get(g:, 'VM_Insert_hl', 'DiffChange')
    exe "highlight! link MultiCursor ".get(g:, 'VM_Cursor_hl', 'Visual')
    return
  endif

  exe "highlight! VM_Extend" s:Themes[theme].extend
  exe "highlight! VM_Mono"   s:Themes[theme].mono
  exe "highlight! VM_Insert" s:Themes[theme].insert
  exe "highlight! VM_Cursor" s:Themes[theme].cursor
  let g:Vm.hi.extend  = 'VM_Extend'
  let g:Vm.hi.mono    = 'VM_Mono'
  let g:Vm.hi.insert  = 'VM_Insert'
  let g:Vm.hi.cursor  = 'VM_Cursor'
  highlight! link MultiCursor VM_Cursor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#themes#hi() abort
  """Init Search highlight.
  let g:Vm.Search = g:VM_highlight_matches == 'underline' ? 'hi Search term=underline cterm=underline gui=underline' :
        \           g:VM_highlight_matches == 'red'       ? 'hi Search ctermfg=196 guifg=#ff0000' : g:VM_highlight_matches
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#themes#load(theme) abort
  """Load a theme."""
  if empty(a:theme)
    let g:VM_theme = 'default'
    echo 'Theme set to default'
  elseif index(keys(s:Themes), a:theme) < 0
    echo "No such theme."
    return
  else
    let g:VM_theme = a:theme
  endif
  call vm#themes#init()
endfun

fun! vm#themes#complete(A, L, P) abort
  let valid = []
  for k in keys(s:Themes)
    if     &background=='light' && has_key(s:Themes[k], 'type') && s:Themes[k].type != 'light'
    elseif &background=='dark'  && has_key(s:Themes[k], 'type') && s:Themes[k].type != 'dark'
    else
      call add(valid, k)
    endif
  endfor
  return filter(sort(valid), 'v:val=~#a:A')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#themes#statusline() abort
  let v = b:VM_Selection.Vars
  let vm = VMInfos()
  let color  = '%#VM_Extend#'
  let single = b:VM_Selection.Vars.single_region ? '%#VM_Mono# SINGLE ' : ''
  try
    if v.insert
      if b:VM_Selection.Insert.replace
        let [ mode, color ] = [ 'V-R', '%#VM_Mono#' ]
      else
        let [ mode, color ] = [ 'V-I', '%#VM_Cursor#' ]
      endif
    else
      let mode = { 'n': 'V-M', 'v': 'V', 'V': 'V-L', "\<C-v>": 'V-B' }[mode()]
    endif
  catch
    let mode = 'V-M'
  endtry
  let mode = exists('v.statusline_mode') ? v.statusline_mode : mode
  let patterns = string(vm.patterns)[:(winwidth(0)-30)]
  return printf("%s %s %s %s %s%s %s %%=%%l:%%c %s %s",
        \ color, mode, '%#VM_Insert#', vm.ratio, single, '%#TabLine#',
        \ patterns, color, vm.status . ' ')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"old mono #F2C38F
"missing: grey(see neodark), acqua/lightacqua(see seoul)
let s:Themes.iceblue = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=24  guibg=#005f87",
      \ 'cursor': "ctermbg=31  guibg=#0087af ctermfg=237 guifg=#87dfff",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=180 guibg=#dfaf87 ctermfg=235 guifg=#262626",
      \}

let s:Themes.ocean = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=25  guibg=#005faf",
      \ 'cursor': "ctermbg=39  guibg=#87afff ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=186 guibg=#dfdf87 ctermfg=239 guifg=#4e4e4e",
      \}

let s:Themes.neon = {
      \ 'type':   "dark",
      \ 'extend': "ctermfg=109 guifg=#89afaf ctermbg=26  guibg=#005fdf",
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

let s:Themes.purplegray = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=60  guibg=#544a65",
      \ 'cursor': "ctermbg=103 guibg=#8787af ctermfg=54  guifg=#5f0087",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermbg=141 guibg=#af87ff ctermfg=235 guifg=#262626",
      \}

let s:Themes.nord = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=239 guibg=#434C5E",
      \ 'cursor': "ctermbg=245 guibg=#8a8a8a ctermfg=24 guifg=#005f87",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermfg=235 guifg=#262626 ctermbg=131 guibg=#AF5F5F",
      \}

let s:Themes.codedark = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=242 guibg=#264F78",
      \ 'cursor': "ctermbg=239 ctermfg=252 guifg=#C5D4DD guibg=#6A7D89",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermfg=235 guifg=#262626 ctermbg=131 guibg=#AF5F5F",
      \}

let s:Themes.spacegray = {
      \ 'type':   "dark",
      \ 'extend': "ctermbg=237 guibg=#404040",
      \ 'cursor': "ctermbg=242 guibg=Grey50 ctermfg=239 guifg=#4e4e4e",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermfg=235 guifg=#262626 ctermbg=131 guibg=#AF5F5F",
      \}

let s:Themes.sand = {
      \ 'extend': "ctermbg=143 ctermfg=0 guibg=darkkhaki guifg=black",
      \ 'cursor': "ctermbg=64 guibg=olivedrab ctermfg=186 guifg=khaki",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermfg=235 guifg=#262626 ctermbg=131 guibg=#AF5F5F",
      \}

let s:Themes.olive = {
      \ 'extend': "ctermbg=3 guibg=olive ctermfg=0 guifg=black",
      \ 'cursor': "ctermbg=64 guibg=olivedrab ctermfg=186 guifg=khaki",
      \ 'insert': "ctermbg=239 guibg=#4c4e50",
      \ 'mono':   "ctermfg=235 guifg=#262626 ctermbg=131 guibg=#AF5F5F",
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

" vim: et ts=2 sw=2 sts=2 :
