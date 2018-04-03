let s:motion = 0 | let s:extending = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_under(visual, whole, inclusive)

    if a:visual                     " yank has already happened here
        let s:V = vm#init(a:whole)

    else                            " start whole word search
        let s:V = vm#init(a:whole)
        if a:inclusive
            normal! yiW`]
        else
            normal! yiw`]
        endif
    endif

    let s:v = s:V.Vars | let s:Regions = s:V.Regions | let s:Matches = s:V.Matches
    call vm#funcs#set_search()
    call vm#new_region(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_next(...)

    "skip current match
    if a:0 | call s:remove_match(s:v.index) | endif

    normal! ngny`]
    call vm#new_region(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_prev(...)

    "move to the beginning of the current match
    let i = s:v.index
    let current = s:Regions[i]
    let pos = [current.l, current.a]
    call cursor(pos)

    "skip current match
    if a:0 | call s:remove_match(s:v.index) | endif

    normal! NgNy`]
    call vm#new_region(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:remove_match(i)
    call remove(s:Regions, a:i)
    let m = s:Matches[a:i][0]
    let c = s:Matches[a:i][1]
    call remove(s:Matches, a:i)
    call matchdelete(m)
    call matchdelete(c)
endfun

fun! vm#commands#skip()
    if s:v.going_down
        call vm#commands#find_next(1)
    else
        call vm#commands#find_prev(1)
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor moving
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion)
    let s:extending = 1
    let s:motion = a:motion
    if a:motion ==# 'x'
        let s:v.move_from_back = 1
        let s:motion = 'b'
        return 'b'
    endif
    return a:motion
endfun

fun! vm#commands#find_motion(motion, ...)
    let s:extending = 1
    if a:0
        let s:motion = a:motion.a:1
    else
        let s:motion = a:motion.nr2char(getchar())
    endif
    return s:motion
endfun

fun! vm#commands#select_motion(inclusive)
    let s:extending = 2
    let c = nr2char(getchar())

    "wrong command
    "if index(['a', 'i'], c[0]) == -1 | return '' | endif

    let a = a:inclusive ? 'F' : 'T'
    let b = a:inclusive ? 'f' : 't'

    if index(['"', "'", '`', '_', '-'], c) != -1
        exe "normal ".a.c
        call vm#commands#move()
        exe "normal ".b.c
    elseif index(['[', ']'], c) != -1
        exe "normal ".a.'['
        call vm#commands#move()
        exe "normal ".b.']'
    elseif index(['(', ')'], c) != -1
        exe "normal ".a.'('
        call vm#commands#move()
        exe "normal ".b.')'
    elseif index(['{', '}'], c) != -1
        exe "normal ".a.'{'
        call vm#commands#move()
        exe "normal ".b.'}'
    elseif index(['<', '>'], c) != -1
        exe "normal ".a.'<'
        call vm#commands#move()
        exe "normal ".b.'>'
    endif

    "TODO select inside/around brackets/quotes/etc.
endfun

fun! vm#commands#move()
    if !s:extending | return | endif
    let s:extending -= 1

    let i = 0
    for c in s:Regions
        call vm#region#move(i, s:motion, s:v.move_from_back)
        let i += 1
    endfor

    normal! `]
    call setmatches(s:v.matches)
    let s:v.move_from_back = 0
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#toggle_whole_word()
    let s:v.whole_word = !s:v.whole_word
endfun

fun! vm#commands#toggle_move_from_back()
    let s:v.move_from_back = !s:v.move_from_back
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

