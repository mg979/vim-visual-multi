""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Set up highlighting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Themes = {}

fun! vm#themes#init() abort
  if !exists('g:Vm') | return | endif
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
  let g:Vm.hi.message = get(g:, 'VM_Message_hl', 'WarningMsg')


  if theme == 'default'
    exe "highlight! link VM_Mono     ".get(g:, 'VM_Mono_hl',   'ErrorMsg')
    exe "highlight! link VM_Cursor   ".get(g:, 'VM_Cursor_hl', 'Visual')
    exe "highlight! link VM_Extend   ".get(g:, 'VM_Extend_hl', 'DiffAdd')
    exe "highlight! link VM_Insert   ".get(g:, 'VM_Insert_hl', 'DiffChange')
    exe "highlight! link MultiCursor ".get(g:, 'VM_Cursor_hl', 'Visual')
    return
  endif

  call s:Themes[theme]()
  highlight! link MultiCursor VM_Cursor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#themes#hi() abort
  " Init Search highlight.
  let g:Vm.Search = g:VM_highlight_matches == 'underline' ? 'hi Search term=underline cterm=underline gui=underline' :
        \           g:VM_highlight_matches == 'red'       ? 'hi Search ctermfg=196 guifg=#ff0000' :
        \           g:VM_highlight_matches =~ '^hi!\? '   ? g:VM_highlight_matches
        \                                                 : 'hi Search term=underline cterm=underline gui=underline'
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#themes#load(theme) abort
  " Load a theme.
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
  if &background=='light'
    let valid = ['sand', 'paper', 'lightblue1', 'lightblue2', 'lightpurple1', 'lightpurple2']
  elseif &background=='dark'
    let valid = ['iceblue', 'ocean', 'neon', 'purplegray', 'nord', 'codedark', 'spacegray', 'olive', 'sand']
  endif
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

fun! s:Themes.iceblue()
  hi! VM_Extend ctermbg=24                   guibg=#005f87
  hi! VM_Cursor ctermbg=31    ctermfg=237    guibg=#0087af    guifg=#87dfff
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=180   ctermfg=235    guibg=#dfaf87    guifg=#262626
endfun

fun! s:Themes.ocean()
  hi! VM_Extend ctermbg=25                   guibg=#005faf
  hi! VM_Cursor ctermbg=39    ctermfg=239    guibg=#87afff    guifg=#4e4e4e
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=186   ctermfg=239    guibg=#dfdf87    guifg=#4e4e4e
endfun

fun! s:Themes.neon()
  hi! VM_Extend ctermbg=26    ctermfg=109    guibg=#005fdf    guifg=#89afaf
  hi! VM_Cursor ctermbg=39    ctermfg=239    guibg=#00afff    guifg=#4e4e4e
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=221   ctermfg=239    guibg=#ffdf5f    guifg=#4e4e4e
endfun

fun! s:Themes.lightblue1()
  hi! VM_Extend ctermbg=153                  guibg=#afdfff
  hi! VM_Cursor ctermbg=111   ctermfg=239    guibg=#87afff    guifg=#4e4e4e
  hi! VM_Insert ctermbg=180   ctermfg=235    guibg=#dfaf87    guifg=#262626
  hi! VM_Mono   ctermbg=167   ctermfg=253    guibg=#df5f5f    guifg=#dadada cterm=bold term=bold gui=bold
endfun

fun! s:Themes.lightblue2()
  hi! VM_Extend ctermbg=117                  guibg=#87dfff
  hi! VM_Cursor ctermbg=111   ctermfg=239    guibg=#87afff    guifg=#4e4e4e
  hi! VM_Insert ctermbg=180   ctermfg=235    guibg=#dfaf87    guifg=#262626
  hi! VM_Mono   ctermbg=167   ctermfg=253    guibg=#df5f5f    guifg=#dadada cterm=bold term=bold gui=bold
endfun

fun! s:Themes.purplegray()
  hi! VM_Extend ctermbg=60                   guibg=#544a65
  hi! VM_Cursor ctermbg=103   ctermfg=54     guibg=#8787af    guifg=#5f0087
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=141   ctermfg=235    guibg=#af87ff    guifg=#262626
endfun

fun! s:Themes.nord()
  hi! VM_Extend ctermbg=239                  guibg=#434C5E
  hi! VM_Cursor ctermbg=245   ctermfg=24     guibg=#8a8a8a    guifg=#005f87
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=131   ctermfg=235    guibg=#AF5F5F    guifg=#262626
endfun

fun! s:Themes.codedark()
  hi! VM_Extend ctermbg=242                  guibg=#264F78
  hi! VM_Cursor ctermbg=239   ctermfg=252    guibg=#6A7D89    guifg=#C5D4DD
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=131   ctermfg=235    guibg=#AF5F5F    guifg=#262626
endfun

fun! s:Themes.spacegray()
  hi! VM_Extend ctermbg=237                  guibg=#404040
  hi! VM_Cursor ctermbg=242   ctermfg=239    guibg=Grey50     guifg=#4e4e4e
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=131   ctermfg=235    guibg=#AF5F5F    guifg=#262626
endfun

fun! s:Themes.sand()
  hi! VM_Extend ctermbg=143   ctermfg=0      guibg=darkkhaki  guifg=black
  hi! VM_Cursor ctermbg=64    ctermfg=186    guibg=olivedrab  guifg=khaki
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=131   ctermfg=235    guibg=#AF5F5F    guifg=#262626
endfun

fun! s:Themes.paper()
  hi! VM_Extend ctermbg=250   ctermfg=16     guibg=#bfbcaf    guifg=black
  hi! VM_Cursor ctermbg=239   ctermfg=188    guibg=#4c4e50    guifg=#d8d5c7
  hi! VM_Insert ctermbg=167   ctermfg=253    guibg=#df5f5f    guifg=#dadada cterm=bold term=bold gui=bold
  hi! VM_Mono   ctermbg=16    ctermfg=188    guibg=#000000    guifg=#d8d5c7
endfun

fun! s:Themes.olive()
  hi! VM_Extend ctermbg=3     ctermfg=0      guibg=olive      guifg=black
  hi! VM_Cursor ctermbg=64    ctermfg=186    guibg=olivedrab  guifg=khaki
  hi! VM_Insert ctermbg=239                  guibg=#4c4e50
  hi! VM_Mono   ctermbg=131   ctermfg=235    guibg=#AF5F5F    guifg=#262626
endfun

fun! s:Themes.lightpurple1()
  hi! VM_Extend ctermbg=225                  guibg=#ffdfff
  hi! VM_Cursor ctermbg=183   ctermfg=54     guibg=#dfafff    guifg=#5f0087 cterm=bold term=bold gui=bold
  hi! VM_Insert ctermbg=146   ctermfg=235    guibg=#afafdf    guifg=#262626
  hi! VM_Mono   ctermbg=135   ctermfg=225    guibg=#af5fff    guifg=#ffdfff cterm=bold term=bold gui=bold
endfun

fun! s:Themes.lightpurple2()
  hi! VM_Extend ctermbg=189                  guibg=#dfdfff
  hi! VM_Cursor ctermbg=183   ctermfg=54     guibg=#dfafff    guifg=#5f0087 cterm=bold term=bold gui=bold
  hi! VM_Insert ctermbg=225   ctermfg=235    guibg=#ffdfff    guifg=#262626
  hi! VM_Mono   ctermbg=135   ctermfg=225    guibg=#af5fff    guifg=#ffdfff cterm=bold term=bold gui=bold
endfun

" vim: et ts=2 sw=2 sts=2 :
