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

        if s:V.Insert.replace
            " in replace mode, we don't allow line joining
            if a:cmd ==# 'X' && r.a > 1
                let original = s:V.Insert._lines[r.l] " the original line
                if strpart(getline(r.l), r.a) =~ '\s*$' " at EOL
                    call search('\s*$', '', r.l)
                endif
                "FIXME this part is bugged with multibyte chars
                call r.shift(-1,-1)
                if r.a > 1
                    let t1 = strpart(getline('.'), 0, r.a - 1)
                    let wd = strwidth(t1)
                    let tc = strcharpart(original, wd, 1)
                    let t2 = strcharpart(original, wd + 1)
                    call setline(r.l, t1 . tc . t2)
                else
                    let pre = ''
                    let post = original
                    call setline(r.l, pre . post)
                endif
            endif
        elseif a:cmd ==# 'x' && s:eol(r)    "at eol, join lines
            keepjumps normal! gJ
        elseif a:cmd ==# 'x'                "normal delete
            keepjumps normal! x
        elseif a:cmd ==# 'X' && r.a == 1    "at bol, go up and join lines
            keepjumps normal! kgJ
            call r.shift(-1,-1)
        else                                "normal backspace
            keepjumps normal! X
            let w = strlen(@-)
            call r.shift(-w, -w)
        endif

        "update changed size
        let change = s:F.size() - size
    endfor

    call s:G.merge_regions()
    call s:G.select_region(s:V.Insert.index)
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
            keepjumps normal! d^
        elseif r.a == 1     "at bol, go up and join lines
            keepjumps normal! kgJ
        elseif ws_only      "whitespace only before, delete it
            keepjumps normal! d0
        else                "normal deletion
            keepjumps normal! db
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
        let at_eol = match(strpart(rline, r.a-1, len(rline)), '\s*$') == 0

        "if carrying over some text, delete it now, for better indentexpr
        "otherwise delete the trailing spaces that would be left at EOL
        if !at_eol  | keepjumps normal! d$
        else        | keepjumps normal! "_d$
        endif

        "append a line and get the indent
        noautocmd exe "silent keepjumps normal! o\<C-R>=<SID>get_indent()\<CR>"

        "fill the line with tabs or spaces, according to the found indent
        "an extra space must be added, if not carrying over any text
        "also keep the indent whitespace only, removing any non-space character
        "such as comments, and everything after them
        let extra_space = at_eol ? ' ' : ''
        let indent = substitute(g:Vm.indent, '\S\+.*', '', 'g')
        call setline('.', indent . extra_space)

        "if carrying over some text, paste it after the indent
        "but strip preceding whitespace found in the text
        if !at_eol
            let @" = substitute(@", '^\s*', '', '')
            keepjumps normal! $p
        endif

        "cursor line will be moved down by the next cursors
        call r.update_cursor([line('.') + r.index, len(indent) + 1])
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "ensure cursors are at indent level
    keepjumps normal ^
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#insert_line(above) abort
    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    for r in s:R()
        "append a line below or above
        call cursor(r.l, r.a)
        noautocmd exe "silent keepjumps normal!" (a:above ? 'O' : 'o')."\<C-R>=<SID>get_indent()\<CR>"

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
    keepjumps normal ^
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

fun! s:eol(r)
    return a:r.a == (col([a:r.l, '$']) - 1)
endfun
" vim: et ts=4 sw=4 sts=4 :
