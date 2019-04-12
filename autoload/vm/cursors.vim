""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Operations at cursors (yank, delete, change)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#cursors#operation(op, n, register, ...)
  call s:init()
  let reg = a:register   | let r = "\"".reg
  let hl1 = 'WarningMsg' | let hl2 = 'Label'

  "shortcut for command in a:1
  if a:0 | call vm#cursors#process(a:op, a:1, reg, 0) | return | endif

  let s = a:op==#'d'? [['Delete ', hl1], ['([n] d/w/e/b/$...) ?  ',   hl2]] :
        \ a:op==#'c'? [['Change ', hl1], ['([n] c/w/e/b/$...) ?  ',   hl2]] :
        \ a:op==#'y'? [['Yank   ', hl1], ['([n] y/w/e/b/$...) ?  ',   hl2]] : 'Aborted.'

  call s:F.msg(s, 1)

  "starting string
  let M = (a:n>1? a:n : '').( reg == s:v.def_reg? '' : '"'.reg ).a:op

  "preceding count
  let n = a:n>1? a:n : 1

  echon M
  while 1
    let c = nr2char(getchar())
    if str2nr(c) > 0                | echon c | let M .= c
    elseif s:double(c)              | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif s:ia(c)                  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif a:op ==# 'c' && c==?'r'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif a:op ==# 'c' && c==?'s'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif a:op ==# 'y' && c==?'s'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c
      if s:ia(c)
        let c = nr2char(getchar())  | echon c | let M .= c | endif
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif a:op ==# 'd' && c==#'s'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif s:single(c)                        | let M .= c | break
    elseif a:op ==# c                         | let M .= c | break

    else | echon ' ...Aborted'      | return  | endif
  endwhile

  call vm#cursors#process(a:op, M, reg, n)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#cursors#process(op, M, reg, n)
  call s:init() | let s:init_done = 0
  let s:v.dot = a:M

  if a:op ==# 'd'     | call s:d_cursors(a:M, a:reg, a:n)
  elseif a:op ==# 'c' | call s:c_cursors(a:M, a:reg, a:n)
  elseif a:op ==# 'y' | call s:y_cursors(a:M, a:reg, a:n)
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:reorder_cmd(M, r, n, op)
  """Reorder command, so that the exact count is found.
  "remove register
  let S = substitute(a:M, a:r, '', '')
  "what comes after operator
  let S = substitute(S, '^\d*'.a:op.'\(.*\)$', '\1', '')

  if S ==? 'n' && empty(@/)
    let @/ = s:v.oldsearch[0]
  endif

  "count that comes after operator
  let x = match(S, '\d') >= 0? substitute(S, '\D', '', 'g') : 0
  if x | let S = substitute(S, x, '', '') | endif

  "final count
  let n = a:n
  let N = x? n*x : n>1? n : 1 | let N = N>1? N : ''

  return [S, N, S[0]==#a:op]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"delete
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:d_cursors(M, reg, n)
  let M = a:M | let r = '"'.a:reg

  "ds surround
  if M[:1] ==# 'ds' | return s:V.Edit.run_normal(M) | endif

  "reorder command; DD = 'dd'
  let [S, N, DD] = s:reorder_cmd(M, r, a:n, 'd')

  "for D, d$, dd: ensure there is only one region per line
  if (S == '$' || S == 'd') | call s:G.one_region_per_line() | endif

  "no matter the entered register, we're using default register
  "we're passing the register in the options dictionary instead
  "fill_register function will be called and take care of it, if appropriate
  call s:V.Edit.run_normal('d'.S, {'count': N, 'store': a:reg})
  call s:G.reorder_regions()
  call s:G.merge_regions()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"yank
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:y_cursors(M, reg, n)
  let M = a:M | let r = '"'.a:reg

  "ys surround
  if M[:1] ==? 'ys' | return s:V.Edit.run_normal(M) | endif

  "reset dot for yank command
  let s:v.dot = ''

  call s:G.change_mode()

  "reorder command; Y = 'yy'
  let [S, N, YY] = s:reorder_cmd(M, r, a:n, 'y')

  "for Y, y$, yy, ensure there is only one region per line
  if (S == '$' || S == 'y') | call s:G.one_region_per_line() | endif

  "NOTE: yy doesn't accept count.
  if YY
    call vm#commands#motion('0', 1, 0, 0)
    call vm#commands#motion('$', 1, 0, 0)
    let s:v.multiline = 1
    call vm#commands#motion('l', 1, 0, 0)
    call feedkeys('y')
  else
    call vm#operators#select(1, 1, N.S)
    if s:back(S)
        normal h
    endif
    let r = a:reg == s:v.def_reg ? '' : "\"".a:reg
    call feedkeys(r.'y')
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:c_cursors(M, reg, n)
  let M = a:M | let r = '"'.a:reg

  "cs surround
  if M[:1] ==? 'cs' | return s:V.Edit.run_normal(M) | endif

  "cr coerce (vim-abolish)
  if M[:1] ==? 'cr' | return feedkeys("\<Plug>(VM-Run-Normal)".M."\<cr>") | endif

  "reorder command; CC = 'cc'
  let [S, N, CC] = s:reorder_cmd(M, r, a:n, 'c')

  "convert w,W to e,E (if motions), also in dot
  if     S ==# 'w' | let S = 'e' | call substitute(s:v.dot, 'w', 'e', '')
  elseif S ==# 'W' | let S = 'E' | call substitute(s:v.dot, 'W', 'E', '') | endif

  "for c$, cc, ensure there is only one region per line
  if (S == '$' || S == 'c') | call s:G.one_region_per_line() | endif

  "replace c with d because we're doing a delete followed by multi insert
  let S = substitute(S, '^c', 'd', '')

  "we're using _ register, unless a register has been specified
  let reg = a:reg != s:v.def_reg? a:reg : "_"

  if CC
    call vm#operators#select(1, 1, '$')
    call vm#commands#motion('^', 1, 0, 0)
    call s:V.Edit.delete(1, reg, 1, 0)
    call s:V.Insert.key('a')

  elseif index(['ip', 'ap'] + vm#comp#add_line(), S) >= 0
    call s:V.Edit.run_normal('d'.S, {'count': N, 'store': reg})
    call s:V.Insert.key('O')

  elseif S=='$'
    call vm#operators#select(1, 1, '$')
    call s:V.Edit.delete(1, reg, 1, 0)
    call s:V.Insert.key('a')

  elseif S=='l'
    let oldmultiline = s:v.multiline
    let s:v.multiline = 1
    call vm#operators#select(1, 1, N.S)
    call vm#commands#motion('h', 1, 0, 0)
    let s:v.multiline = 0
    call feedkeys('"'.reg."c")
    let s:v.multiline = oldmultiline

  elseif s:forw(S)
    call vm#operators#select(1, 1, N.S)
    call feedkeys('"'.reg."c")

  else
    call s:V.Edit.run_normal('d'.S, {'count': N, 'store': reg})
    call s:G.merge_regions()
    call feedkeys("i")
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:init_done = 0

fun! s:init()
  if s:init_done | return | endif
  let s:V         = b:VM_Selection
  let s:v         = s:V.Vars
  let s:G         = s:V.Global
  let s:F         = s:V.Funcs
  let s:Search    = s:V.Search
  let s:R         = function('vm#v74#regions')
  let s:init_done = 1
  call s:G.cursor_mode()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
  let s:R      = { -> s:V.Regions      }
  let s:forw   = { c -> index(split('weWE%', '\zs'), c) >= 0                }
  let s:back   = { c -> index(split('FThbB0N^{(', '\zs'), c[0]) >= 0        }
  let s:ia     = { c -> index(['i', 'a'], c) >= 0                           }
  let s:single = { c -> index(split('hljkwebWEB$^0{}()%nN', '\zs'), c) >= 0 }
  let s:double = { c -> index(split('iafFtTg', '\zs'), c) >= 0              }
else
  let s:R                = function('vm#v74#regions')
  let s:forw   = function('vm#v74#forw')
  let s:back   = function('vm#v74#back')
  let s:ia     = function('vm#v74#ia')
  let s:single = function('vm#v74#single')
  let s:double = function('vm#v74#double')
endif
