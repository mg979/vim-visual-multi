"script to handle several insert mode commands

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R         = {      -> s:V.Regions              }
    let s:X         = {      -> g:VM.extend_mode         }
    let s:size      = {      -> line2byte(line('$') + 1) }
    let s:Byte      = { pos  -> s:F.pos2byte(pos)        }
    let s:Pos       = { byte -> s:F.byte2pos(byte)       }
    let s:E         = { r    -> col([r.l, '$'])          }
    let s:eol       = { r    -> r.a == (s:E(r) - 1)      }
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#x(cmd)
    let size = s:size()    | let s:change = 0 | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    for r in s:R()

        call r.bytes([s:change, s:change])

        if a:cmd ==# 'x' | let done = s:del(r)
        else             | let done = 0         | endif

        if !done
            call cursor(r.l, r.a)
            exe "normal! ".a:cmd
        endif

        "update changed size
        let s:change = s:size() - size
        if !has('nvim') | doautocmd CursorMoved
        endif
    endfor

    if a:cmd ==# 'X'
        for r in s:R()
            if r.a > 1 || s:E(r)>1
                call r.bytes([-1,-1])
            endif
        endfor

    else
        for r in s:R()
            if r.a > 1 && r.a == s:E(r)
                call r.bytes([-1,-1])
            endif
        endfor
    endif

    call s:G.merge_regions()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:del(r)
    let r = a:r

    "no adjustments
    if !s:eol(r) | return | endif

    "at eol, join lines and del 1 char
    call cursor(r.l, r.a)
    normal! Jhx

    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs(r)
    "UNUSED: for now
    let r = a:r

    "no adjustments
    if !s:eol(r) | return | endif

    "add an extra space and push cursor
    call cursor(r.l, r.a)
    normal! X
    call s:V.Edit.extra_spaces.add(r)
    call r.bytes([1,1])

    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#cw()
    let s:v.storepos = getpos('.')[1:2]
    let s:v.direction = 1 | let n = 0

    for r in s:R()
        if s:eol(r)
            call s:V.Edit.extra_spaces.add(r, 1)
            call r.bytes([2+n,2+n])
            let n += 2
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
    silent! undojoin
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
    silent! undojoin
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
