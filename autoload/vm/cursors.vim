""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Operations at cursors (yank, delete, change)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#cursors#operation(op, n, register, ...) abort
  " Operations at cursors (yank, delete, change)
  call s:init()
  let reg = a:register | let oper = a:op

  "shortcut for command in a:1
  if a:0 | call s:process(oper, a:1, reg, 0) | return | endif

  call s:F.msg('[VM] ')

  "starting string
  let M = (a:n>1? a:n : '') . (reg == s:v.def_reg? '' : '"'.reg) . oper

  "preceding count
  let n = a:n>1? a:n : 1

  echon M
  while 1
    let c = nr2char(getchar())
    let is_user_op = index(keys(g:Vm.user_ops), M . c) >= 0

    if is_user_op
      " let the entered characters be our operator
      echon c | let M .= c | let oper = M
      if !g:Vm.user_ops[M]
        " accepts a regular text object
        continue
      else
        " accepts a specific number of any characters
        let chars2read = g:Vm.user_ops[M]
        while chars2read
          let c = nr2char(getchar())
          echon c | let M .= c
          let chars2read -= 1
        endwhile
        break
      endif

    elseif s:double(c)              | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif oper ==# 'c' && c==?'r'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif oper ==# 'c' && c==?'s'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif oper ==# 'y' && c==?'s'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c
      if s:double(c)
        let c = nr2char(getchar())  | echon c | let M .= c
      endif
      let c = nr2char(getchar())    | echon c
      if c == '<' || c == 't'
        redraw
        let tag = s:V.Edit.surround_tags()
        if tag == ''
          echon ' ...Aborted'       | return
        else
          let M .= tag              | echon c | break
        endif
      else
        let M .= c                  | echon c | break
      endif

    elseif oper ==# 'd' && c==#'s'  | echon c | let M .= c
      let c = nr2char(getchar())    | echon c | let M .= c | break

    elseif s:single(c)              | echon c | let M .= c | break

    elseif str2nr(c) > 0            | echon c | let M .= c

    " if the entered char is the last character of the operator (eg 'yy', 'gUU')
    elseif oper[-1:-1] ==# c        | echon c | let M .= '_' | break

    else | echon ' ...Aborted'      | return
    endif
  endwhile

  call s:process(oper, M, reg, n)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function: s:process
" @param op: the operator
" @param M: the whole command
" @param reg: the register
" @param n: the count
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""
fun! s:process(op, M, reg, n) abort
  " Process the whole command
  let s:v.dot = a:M
  let s:v.deleting = a:op == 'd' || a:op == 'c'

  if a:op ==# 'd'     | call s:delete_at_cursors(a:M, a:reg, a:n)
  elseif a:op ==# 'c' | call s:change_at_cursors(a:M, a:reg, a:n)
  elseif a:op ==# 'y' | call s:yank_at_cursors(a:M, a:reg, a:n)
  else
    " if it's a custom operator, pass the mapping as-is, and hope for the best
    call s:V.Edit.run_normal(a:M, {'count': a:n, 'recursive': 1})
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function: s:parse_cmd
" @param M: the whole command
" @param r: the register
" @param n: count that comes before the operator
" @param op: the operator
" Returns: [ text object, count ]
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""
fun! s:parse_cmd(M, r, n, op) abort
  " Parse command, so that the exact count is found.

  "remove register
  let Cmd = substitute(a:M, a:r, '', '')

  "what comes after operator
  let Obj = substitute(Cmd, '^\d*'.a:op.'\(.*\)$', '\1', '')

  "if object is n/N, ensure there is a search pattern
  if Obj ==? 'n' && empty(@/)
    let @/ = s:v.oldsearch[0]
  endif

  "count that comes after operator
  let x = match(Obj, '^\d') >= 0? substitute(Obj, '^\d\zs.*', '', 'g') : 0
  if x | let Obj = substitute(Obj, '^' . x, '', '') | endif

  "final count
  let n = a:n
  let N = x? n*x : n>1? n : 1
  let N = N>1? N : ''

  " if the text object is the last character of the operator (eg 'yy')
  if Obj ==# a:op[-1:-1]
    let Obj = '_'
  endif

  return [Obj, N]
endfun


fun! s:delete_at_cursors(M, reg, n) abort
  " delete operation at cursors
  let Cmd = a:M

  "ds surround
  if Cmd[:1] ==# 'ds' | return s:V.Edit.run_normal(Cmd) | endif

  let [Obj, N] = s:parse_cmd(Cmd, '"'.a:reg, a:n, 'd')

  "for D, d$, dd: ensure there is only one region per line
  if (Obj == '$' || Obj == '_') | call s:G.one_region_per_line() | endif

  "no matter the entered register, we're using default register
  "we're passing the register in the options dictionary instead
  "fill_register function will be called and take care of it, if appropriate
  call s:V.Edit.run_normal('d'.Obj, {'count': N, 'store': a:reg, 'recursive': s:recursive})
  call s:G.reorder_regions()
  call s:G.merge_regions()
endfun


fun! s:yank_at_cursors(M, reg, n) abort
  " yank operation at cursors
  let Cmd = a:M

  "ys surround
  if Cmd[:1] ==? 'ys' | return s:V.Edit.run_normal(Cmd) | endif

  "reset dot for yank command
  let s:v.dot = ''

  call s:G.change_mode()

  let [Obj, N] = s:parse_cmd(Cmd, '"'.a:reg, a:n, 'y')

  "for Y, y$, yy, ensure there is only one region per line
  if (Obj == '$' || Obj == '_') | call s:G.one_region_per_line() | endif

  call s:V.Edit.run_normal('y'.Obj, {'count': N, 'store': a:reg, 'vimreg': 1})
endfun


fun! s:change_at_cursors(M, reg, n) abort
  " change operation at cursors
  let Cmd = a:M

  "cs surround
  if Cmd[:1] ==? 'cs' | return s:V.Edit.run_normal(Cmd) | endif

  "cr coerce (vim-abolish)
  if Cmd[:1] ==? 'cr' | return feedkeys("\<Plug>(VM-Run-Normal)".Cmd."\<cr>") | endif

  let [Obj, N] = s:parse_cmd(Cmd, '"'.a:reg, a:n, 'c')

  "convert w,W to e,E (if motions), also in dot
  if     Obj ==# 'w' | let Obj = 'e' | call substitute(s:v.dot, 'w', 'e', '')
  elseif Obj ==# 'W' | let Obj = 'E' | call substitute(s:v.dot, 'W', 'E', '')
  endif

  "for c$, cc, ensure there is only one region per line
  if (Obj == '$' || Obj == '_') | call s:G.one_region_per_line() | endif

  "replace c with d because we're doing a delete followed by multi insert
  let Obj = substitute(Obj, '^c', 'd', '')

  "we're using _ register, unless a register has been specified
  let reg = a:reg != s:v.def_reg? a:reg : "_"

  if Obj == '_'
    call vm#commands#motion('^', 1, 0, 0)
    call vm#operators#select(1, '$')
    let s:v.changed_text =  s:V.Edit.delete(1, reg, 1, 0)
    call s:V.Insert.key('i')

  elseif index(['ip', 'ap'], Obj) >= 0
    call s:V.Edit.run_normal('d'.Obj, {'count': N, 'store': reg, 'recursive': s:recursive})
    call s:V.Insert.key('O')

  elseif s:recursive && index(vm#comp#add_line(), Obj) >= 0
    call s:V.Edit.run_normal('d'.Obj, {'count': N, 'store': reg})
    call s:V.Insert.key('O')

  elseif Obj=='$'
    call vm#operators#select(1, '$')
    let s:v.changed_text =  s:V.Edit.delete(1, reg, 1, 0)
    call s:V.Insert.key('i')

  elseif Obj=='l'
    call s:G.extend_mode()
    if N > 1
      call vm#commands#motion('l', N-1, 0, 0)
    endif
    call feedkeys('"'.reg."c")

  elseif s:forward(Obj) || s:ia(Obj) && !s:inside(Obj)
    call vm#operators#select(1, N.Obj)
    call feedkeys('"'.reg."c")

  else
    call s:V.Edit.run_normal('d'.Obj, {'count': N, 'store': reg, 'recursive': s:recursive})
    call s:G.merge_regions()
    call s:V.Insert.key('i')
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:init() abort
  "set up script variables
  let s:V         = b:VM_Selection
  let s:v         = s:V.Vars
  let s:G         = s:V.Global
  let s:F         = s:V.Funcs
  let s:Search    = s:V.Search

  let s:recursive = get(g:, 'VM_recursive_operations_at_cursors', 1)
  call s:G.cursor_mode()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:R = { -> s:V.Regions }

" motions that move the cursor forward
let s:forward = { c -> index(split('weWE%', '\zs'), c) >= 0 }

" text objects starting with 'i' or 'a'
let s:ia = { c -> index(['i', 'a'], c[:0]) >= 0 }

" inside brackets/quotes/tags
let s:inside = { c -> c[:0] == 'i' && index(split('bBt[](){}"''`<>', '\zs') + vm#comp#iobj(), c[1:1]) >= 0 }

" single character motions
let s:single = { c -> index(split('hljkwebWEB$^0{}()%nN_', '\zs'), c) >= 0 }

" motions that expect a second character
let s:double = { c -> index(split('iafFtTg', '\zs'), c) >= 0 }

" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
