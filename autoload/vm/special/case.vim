"mostly from abolish.vim, with some minor additions
"abolish.vim by Tim Pope <http://tpo.pe/>
"https://github.com/tpope/vim-abolish

fun! vm#special#case#init() abort
  let s:V = b:VM_Selection
  return s:Case
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X = { -> g:Vm.extend_mode }
let s:R = { -> s:V.Regions }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Case = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Case.pascal(word) abort
  return substitute(self.camel(a:word),'^.','\u&','')
endfun

fun! s:Case.camel(word) abort
  let word = substitute(a:word,'[.-]','_','g')
  let word = substitute(word,' ','_','g')
  if word !~# '_' && word =~# '\l'
    return substitute(word,'^.','\l&','')
  else
    return substitute(word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfun

fun! s:Case.snake(word) abort
  let word = substitute(a:word,'::','/','g')
  let word = substitute(word,'\(\u\+\)\(\u\l\)','\1_\2','g')
  let word = substitute(word,'\(\l\|\d\)\(\u\)','\1_\2','g')
  let word = substitute(word,'[.-]','_','g')
  let word = substitute(word,' ','_','g')
  let word = tolower(word)
  return word
endfun

fun! s:Case.snake_upper(word) abort
  return toupper(self.snake(a:word))
endfun

fun! s:Case.dash(word) abort
  return substitute(self.snake(a:word),'_','-','g')
endfun

fun! s:Case.space(word) abort
  return substitute(self.snake(a:word),'_',' ','g')
endfun

fun! s:Case.dot(word) abort
  return substitute(self.snake(a:word),'_','.','g')
endfun

fun! s:Case.title(word) abort
  return substitute(self.space(a:word), '\(\<\w\)','\=toupper(submatch(1))','g')
endfun

fun! s:Case.lower(word) abort
  return tolower(a:word)
endfun

fun! s:Case.upper(word) abort
  return toupper(a:word)
endfun

fun! s:Case.capitalize(word) abort
  return toupper(a:word[0:0]) . tolower(a:word[1:])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Case.menu() abort
  if get(g:, 'VM_verbose_commands', 0)
    echohl WarningMsg | echo "\tCase Conversion\n---------------------------------"
    echohl WarningMsg | echo "u         " | echohl Type | echon "lowercase"       | echohl None
    echohl WarningMsg | echo "U         " | echohl Type | echon "UPPERCASE"       | echohl None
    echohl WarningMsg | echo "C         " | echohl Type | echon "Captialize"      | echohl None
    echohl WarningMsg | echo "t         " | echohl Type | echon "Title Case"      | echohl None
    echohl WarningMsg | echo "c         " | echohl Type | echon "camelCase"       | echohl None
    echohl WarningMsg | echo "P         " | echohl Type | echon "PascalCase"      | echohl None
    echohl WarningMsg | echo "s         " | echohl Type | echon "snake_case"      | echohl None
    echohl WarningMsg | echo "S         " | echohl Type | echon "SNAKE_UPPERCASE" | echohl None
    echohl WarningMsg | echo "-         " | echohl Type | echon "dash-case"       | echohl None
    echohl WarningMsg | echo ".         " | echohl Type | echon "dot.case"        | echohl None
    echohl WarningMsg | echo "<space>   " | echohl Type | echon "space case"      | echohl None
    echohl WarningMsg | echo "---------------------------------"
    echohl Directory  | echo "Enter an option: " | echohl None
  else
    echohl Constant   | echo "Case conversion: " | echohl None | echon '(u/U/C/t/c/P/s/S/-/./ )'
  endif
  let c = nr2char(getchar())
  let case = {
        \ "u": 'lower',      "U": 'upper',
        \ "C": 'capitalize', "t": 'title',
        \ "c": 'camel',      "P": 'pascal',
        \ "s": 'snake',      "S": 'snake_upper',
        \ "-": 'dash',       "k": 'remove',
        \ ".": 'dot',        " ": 'space',
        \}
  if has_key(case, c)
    call self.convert(case[c])
  endif
  if get(g:, 'VM_verbose_commands', 0)
    call feedkeys("\<cr>", 'n')
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Case.convert(type) abort
  if !len(s:R()) | return | endif
  if !s:X()
    call vm#operators#select(1, 'iw')
  endif

  let text = [] | let g:Vm.registers['"'] = text
  for r in s:R()
    call add(text, eval("self.".a:type."(r.txt)"))
  endfor
  call b:VM_Selection.Edit.paste(1, 0, 1, '"')
endfun
" vim: et ts=2 sw=2 sts=2 :
