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
    let s:E         = { r    -> col([r.l, '$']) }
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#x(cmd)
    let size = s:size()    | let s:change = 0 | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    for r in s:R()

        call r.bytes([s:change, s:change])

        if a:cmd ==# 'x' | let done = s:del(r)
        else             | let done = s:bs(r)  | endif

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
            if r.a > 1 || col([r.L, '$'])>1
                call r.bytes([-1,-1])
            endif
        endfor

    else
        for r in s:R()
            "
            if r.a > 1 && r.a == col([r.L, '$'])
                call r.bytes([-1,-1])
            endif
        endfor
    endif

    call s:G.merge_cursors()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:del(r)
    let r = a:r

    "no adjustments
    if !s:eol(r) | return | endif

    call cursor(r.l, r.a)

    if r.a == s:E(r)-1 | normal! Jhx
    else               | normal! x
    endif

    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs(r)
    let r = a:r

    "no adjustments
    if !s:eol(r) | return | endif

    call cursor(r.l, r.a) | normal! X

    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#cw()
    let s:v.storepos = getpos('.')[1:2]
    let s:v.direction = 1

    call vm#commands#select_operator(1, 1, 'b')
    normal hd
    call s:G.merge_cursors()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#paste()
    call s:G.select_region(-1)
    let s:v.restart_insert = 1
    call s:V.Edit.paste(1, 1, 1)
    let s:v.restart_insert = 0
    call s:G.select_region(s:V.Insert.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#return()
    "NOTE: this function could probably be simplified, only 'end' seems necessary

    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    let nR = len(s:R())-1

    for r in s:R()
        "these vars will be used to see what must be done (read NOTE)
        let eol = col([r.l, '$']) | let end = (r.a >= eol-1)
        let ind = indent(r.l)     | let ok = ind && !end

        call cursor(r.l, r.a)

        "append new line with mark/extra space if needed
        if ok          | call append(line('.'), '')
        elseif !ind    | call append(line('.'), ' ')
        else           | call append(line('.'), '_ ')
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#return_above()
    "invert regions order, so that they are processed from bottom to top
    let s:V.Regions = reverse(s:R())

    let nR = len(s:R())-1

    for r in s:R()
        call cursor(r.l, r.a)

        "append new line above, with mark/extra space
        call append(line('.')-1, '_ ')

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

fun! s:eol(r)
    if index(s:v.extra_spaces, a:r.index)
        return a:r.a == (s:E(a:r) - 2)
    else
        return a:r.a == (s:E(a:r) - 1)
    endif
endfun

