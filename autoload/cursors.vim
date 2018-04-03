let s:motion = 0 | let s:extending = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#find_under(visual, wrap)

    if a:visual                     " yank has already happened here
        let s:V = cursors#funcs#init(0) | let s:v = s:V.Vars

    else                            " start whole word search
        let s:V = cursors#funcs#init(1) | let s:v = s:V.Vars
        if a:wrap
            normal! yiW`]
        else
            normal! yiw`]
        endif
    endif

    call cursors#funcs#set_search()
    call s:create_region(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:create_region(down)
    call cursors#regions#new()
    let s:v.going_down = a:down
endfun

fun! cursors#find_next(...)

    "skip current match
    if a:0 | call s:remove_match(s:v.index) | endif

    normal! ngny`]
    call s:create_region(1)
endfun

fun! cursors#find_prev(...)

    "move to the beginning of the current match
    let i = s:v.index
    let current = s:V.Regions[i]
    let pos = [current.l, current.a]
    call cursor(pos)

    "skip current match
    if a:0 | call s:remove_match(s:v.index) | endif

    normal! NgNy`]
    call s:create_region(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:remove_match(i)
    call remove(s:V.Regions, a:i)
    let m = s:V.Matches[a:i][0]
    let c = s:V.Matches[a:i][1]
    call remove(s:V.Matches, a:i)
    call matchdelete(m)
    call matchdelete(c)
endfun

fun! cursors#skip()
    if s:v.going_down
        call cursors#find_next(1)
    else
        call cursors#find_prev(1)
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor moving
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#motion(motion)
    let s:extending = 1
    let s:motion = a:motion
    if a:motion ==# 'x'
        let s:v.move_from_back = 1
        let s:motion = 'b'
        return 'b'
    endif
    return a:motion
endfun

fun! cursors#find_motion(motion, ...)
    let s:extending = 1
    if a:0
        let s:motion = a:motion.a:1
    else
        let s:motion = a:motion.nr2char(getchar())
    endif
    return s:motion
endfun

fun! cursors#select_motion(inclusive)
    let s:extending = 2
    let c = nr2char(getchar())

    "wrong command
    "if index(['a', 'i'], c[0]) == -1 | return '' | endif

    let a = a:inclusive ? 'F' : 'T'
    let b = a:inclusive ? 'f' : 't'

    if index(['"', "'", '`', '_', '-'], c) != -1
        exe "normal ".a.c
        call cursors#move()
        exe "normal ".b.c
    elseif index(['[', ']'], c) != -1
        exe "normal ".a.'['
        call cursors#move()
        exe "normal ".b.']'
    elseif index(['(', ')'], c) != -1
        exe "normal ".a.'('
        call cursors#move()
        exe "normal ".b.')'
    elseif index(['{', '}'], c) != -1
        exe "normal ".a.'{'
        call cursors#move()
        exe "normal ".b.'}'
    elseif index(['<', '>'], c) != -1
        exe "normal ".a.'<'
        call cursors#move()
        exe "normal ".b.'>'
    endif

    "TODO select inside/around brackets/quotes/etc.
endfun

fun! cursors#move()
    if !s:extending | return | endif
    let s:extending -= 1

    let i = 0
    for c in s:V.Regions
        call cursors#regions#move(i, s:motion, s:v.move_from_back)
        let i += 1
    endfor

    normal! `]
    call setmatches(s:v.matches)
    let s:v.move_from_back = 0
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#toggle_whole_word()
    let s:v.whole_word = !s:v.whole_word
endfun

fun! cursors#toggle_move_from_back()
    let s:v.move_from_back = !s:v.move_from_back
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

