"script to handle BS/C-d in insert mode

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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#icmds#x(cmd)
    let size = s:size()    | let s:change = 0 | let s:v.eco = 1  | let app = s:V.Live.append
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    for r in s:R()

        if a:cmd ==# 'x' | let done = s:del(r)
        else             | let done = s:bs(r)  | endif

        if !done
            call r.bytes([s:change, s:change])
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
            if r.a > 1 || col([r.L, '$'])>(1+app)
                call r.bytes([-1,-1])
            endif
        endfor

    else
        for r in s:R()
            "
            if r.a > 1 && r.a == col([r.L, '$'])-app
                call r.bytes([-1,-1])
            endif
        endfor
    endif

    call s:G.merge_cursors()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:del(r)
    let r = a:r | let E = col([r.l, '$']) | let app = s:V.Live.append

    let eol = r.a == E - 1

    if app && r.a + 1 == E-1 | return 1
        "don't allow delete
    elseif !eol && !app | return
        "no adjustments
    endif

    "in append mode, after <esc> cursors have been moved back by 1
    if app | call r.bytes([s:change+1, s:change+1]) | endif

    call cursor(r.l, r.a)

    normal! x

    if app | call r.bytes([-1, -1]) | endif

    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs(r)
    let r = a:r | let E = col([r.l, '$']) | let app = s:V.Live.append

    let eol = r.a == E - 1

    "no adjustments
    if !eol && !app | return | endif

    "in append mode, after <esc> cursors have been moved back by 1
    if app | call r.bytes([s:change+1, s:change+1]) | endif

    call cursor(r.l, r.a)

    if eol && !app
        call s:V.Edit.extra_spaces(r, 0)
        call r.bytes([1, 1])
        normal! x
    else
        normal! X
    endif

    if app | call r.bytes([-1, -1]) | endif

    return 1
endfun
