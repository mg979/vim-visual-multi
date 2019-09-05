"script to handle several insert mode commands

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#init() abort
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:R = { -> s:V.Regions }
let s:X = { -> g:Vm.extend_mode }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#x(cmd) abort
    let size = s:F.size()
    let change = 0 | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif
    let active = s:R()[s:V.Insert.index]

    for r in s:R()
        if s:v.single_region && r isnot active
            if r.l == active.l
                call r.shift(change, change)
            endif
            continue
        endif

        call r.shift(change, change)
        call s:F.Cursor(r.A)

        " we want to emulate the behaviour that <del> and <bs> have in insert
        " mode, but implemented as normal mode commands

        if a:cmd ==# 'x' && s:eol(r)        "at eol, join lines
            normal! gJ
        elseif a:cmd ==# 'x'                "normal delete
            normal! x
        elseif a:cmd ==# 'X' && r.a == 1    "at bol, go up and join lines
            normal! kgJ
            call r.shift(-1,-1)
        else                                "normal backspace
            normal! X
            call r.update_cursor_pos()
        endif

        "update changed size
        let change = s:F.size() - size
    endfor

    call s:G.merge_regions()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#cw(ctrlu) abort
    let size = s:F.size()
    let change = 0 | let s:v.eco = 1
    let s:v.storepos = getpos('.')[1:2]
    let keep_line = get(g:, 'VM_icw_keeps_line', 1)

    for r in s:R()
        call r.shift(change, change)

        "TODO: deletion to line above can be bugged for now
        if keep_line && r.a == 1 | continue | endif

        call s:F.Cursor(r.A)

        if r.a > 1 && s:eol(r) "add extra space and move right
            call s:V.Edit.extra_spaces.add(r)
            call r.move('l')
        endif

        let L = getline(r.l)
        let ws_only = r.a > 1 && match(L[:(r.a-2)], '[^ \t]') < 0

        if a:ctrlu          "ctrl-u
            normal! d^
        elseif r.a == 1     "at bol, go up and join lines
            normal! kgJ
        elseif ws_only      "whitespace only before, delete it
            normal! d0
        else                "normal deletion
            normal! db
        endif
        call r.update_cursor_pos()

        "update changed size
        let change = s:F.size() - size
    endfor
    call s:V.Insert.start(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#paste() abort
    call s:G.select_region(-1)
    call s:V.Edit.paste(1, 0, 1, '"')
    call s:G.select_region(s:V.Insert.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#return() abort
    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    for r in s:R()
        call cursor(r.l, r.a)
        let rline = getline('.')

        "we also consider at EOL cursors that have trailing spaces after them
        "if not at EOL, CR will cut the line and carry over the remaining text
        let at_eol = match(strpart(rline, r.a-1, len(rline)), ' *$') == 0

        "if carrying over some text, delete it now, for better indentexpr
        "otherwise delete the trailing spaces that would be left at EOL
        if !at_eol  | normal! d$
        else        | normal! "_d$
        endif

        "append a line and get the indent
        noautocmd exe "silent normal! o\<C-R>=<SID>get_indent()\<CR>"

        "fill the line with tabs or spaces, according to the found indent
        "an extra space must be added, if not carrying over any text
        "also keep the indent whitespace only, removing any non-space character
        "such as comments, and everything after them
        let extra_space = at_eol ? ' ' : ''
        let indent = substitute(g:Vm.indent, '[^ \t].*', '', 'g')
        call setline('.', indent . extra_space)

        "if carrying over some text, paste it after the indent
        "but strip preceding whitespace found in the text
        if !at_eol
            let @" = substitute(@", '^ *', '', '')
            normal! $p
        endif

        "cursor line will be moved down by the next cursors
        call r.update_cursor([line('.') + r.index, len(indent) + 1])
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "ensure cursors are at indent level
    normal ^
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#insert_line(above) abort
    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    for r in s:R()
        "append a line below or above
        call cursor(r.l, r.a)
        noautocmd exe "silent normal!" (a:above ? 'O' : 'o')."\<C-R>=<SID>get_indent()\<CR>"

        "remove comment or other chars, fill the line with tabs or spaces
        let indent = substitute(g:Vm.indent, '[^ \t].*', '', 'g')
        call setline('.', indent . ' ')

        "cursor line will be moved down by the next cursors
        call r.update_cursor([line('.') + r.index, len(indent) + 1])
        call add(s:v.extra_spaces, r.index)
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "ensure cursors are at indent level
    normal ^
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#goto(next) abort
  """Used in single region mode.
  let s:v.single_mode_running = 1
  let t = ":call b:VM_Selection.Insert.key('".s:V.Insert.type."')\<cr>"
  if a:next
      return "\<Esc>:call vm#commands#find_next(0,1)\<cr>".t
  else
      return "\<Esc>:call vm#commands#find_prev(0,1)\<cr>".t
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_indent() abort
    let g:Vm.indent = getline('.')
    return ''
endfun

if v:version >= 800
    let s:E   = { r -> col([r.l, '$']) }
    let s:eol = { r -> r.a == (s:E(r) - 1) }
    finish
endif

fun! s:E(r) abort
    return col([a:r.l, '$'])
endfun

fun! s:eol(r) abort
    return a:r.a == (s:E(a:r) - 1)
endfun
" vim: et ts=4 sw=4 sts=4 :
