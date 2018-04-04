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

    let s:v = s:V.Vars
    let s:Regions = s:V.Regions | let s:Matches = s:V.Matches
    let s:Global = s:V.Global | let s:Funcs = s:V.Funcs

    call s:Funcs.set_search()
    call s:Global.new_region(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_next(...)
    let i = s:v.index

    "just reverse direction if going ip
    if !s:v.direction
        let s:v.direction = 1
        call s:Global.select_region(i)
        return
    endif

    "skip current match
    if a:0 | call s:Regions[i].remove() | endif

    normal! ngny`]
    call s:Global.new_region(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_prev(...)
    let i = s:v.index

    "just reverse direction if going down
    if s:v.direction
        let s:v.direction = 0
        call s:Global.select_region(i)
        return
    endif

    "move to the beginning of the current match
    let current = s:Regions[i]
    let pos = [current.l, current.a]
    call cursor(pos)

    "skip current match
    if a:0 | call s:Regions[i].remove() | endif

    normal! NgNy`[
    call s:Global.new_region(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#skip()
    if s:v.direction
        call vm#commands#find_next(1)
    else
        call vm#commands#find_prev(1)
    endif
    echom s:v.index
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor moving
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion)
    let s:extending = 1
    let s:current_i = s:v.index
    let s:motion = a:motion
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

    let s:extending = 0
    "TODO select inside/around brackets/quotes/etc.
endfun

fun! vm#commands#move()
    if !s:extending | return | endif
    let s:extending -= 1
    let s:v.move_from_back = !s:v.direction

    for r in s:Regions
        call r.move(s:motion)
    endfor

    normal! `]
    call setmatches(s:v.matches)
    let s:v.move_from_back = 0
    call s:Global.select_region(s:current_i)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#toggle_whole_word()
    let s:v.whole_word = !s:v.whole_word
endfun

fun! vm#commands#toggle_case_ignore()
    let s:v.case_ignore = !s:v.case_ignore
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

