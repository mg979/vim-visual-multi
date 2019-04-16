"script to handle several insert mode commands

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#init()
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:R    = { -> s:V.Regions }
    let s:X    = { -> g:Vm.extend_mode }
    let s:size = { -> line2byte(line('$')) }
else
    let s:R    = function('vm#v74#regions')
    let s:X    = function('vm#v74#extend_mode')
    let s:size = function('vm#v74#size')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#x(cmd)
    let size = s:size()    | let s:change = 0 | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    for r in s:R()

        call r.shift(s:change, s:change)
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
            call r.shift(-1,-1)
        endif

        "update changed size
        let s:change = s:size() - size
    endfor

    call s:G.merge_regions()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#cw()
    let s:v.storepos = getpos('.')[1:2]
    let s:v.direction = 1 | let n = 0

    for r in s:R()
        if s:eol(r)
            call s:V.Edit.extra_spaces.add(r, 1)
        endif
    endfor
    call vm#operators#select(1, 1, 'b')
    normal h"_d
    call s:G.merge_regions()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#paste()
    call s:G.select_region(-1)
    call s:V.Edit.paste(1, 0, 1, '"')
    call s:G.select_region(s:V.Insert.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#return()
    "NOTE: this function could probably be simplified, only 'end' seems necessary

    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R()) | let nR = len(s:R())-1

    for r in s:R()
        "these vars will be used to see what must be done (read NOTE)
        let eol = col([r.l, '$']) | let end = (r.a >= eol-1)
        let ind = indent(r.l)     | let ok = ind && !end

        call cursor(r.l, r.a)

        "append new line with mark/extra space if needed
        if ok          | call append(line('.'), '')
        elseif !ind    | call append(line('.'), ' ')
        else           | call append(line('.'), '° ')
        endif

        "cut and paste below, or just move down if at eol, then reindent
        if !end    | normal! d$jp==
        else       | normal! j==
        endif

        "cursor line will be moved down by the next cursors
        call r.update_cursor([r.l + 1 + r.index, getpos('.')[2]])
        if !ok | call add(s:v.extra_spaces, nR - r.index) | endif

        "remember which lines have been marked
        if !ok | let s:v.insert_marks[r.l] = indent(r.l) | endif
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "reindent all and move back cursors to indent level
    normal ^
    for r in s:R()
        call cursor(r.l, r.a) | normal! ==
    endfor
    normal ^
    call s:V.Edit.extra_spaces.remove(-1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#return_above()
    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R()) | let nR = len(s:R())-1

    for r in s:R()
        call cursor(r.l, r.a)

        "append new line above, with mark/extra space
        call append(line('.')-1, '° ')

        "move up, then reindent
        normal! k==

        "cursor line will be moved down by the next cursors
        call r.update_cursor([r.l + r.index, getpos('.')[2]])
        call add(s:v.extra_spaces, nR - r.index)

        "remember which lines have been marked
        let s:v.insert_marks[r.l] = indent(r.l)
    endfor

    "reorder regions
    let s:V.Regions = reverse(s:R())

    "move back all cursors to indent level
    normal ^
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:E         = { r -> col([r.l, '$'])          }
    let s:eol       = { r -> r.a == (s:E(r) - 1)      }
    finish
endif

fun! s:E(r)
    return col([a:r.l, '$'])
endfun

fun! s:eol(r)
    return r.a == (s:E(a:r) - 1)
endfun

