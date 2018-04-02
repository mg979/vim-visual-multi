let s:last_motion = 0 | let s:extending = 0

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
    let m = s:V.Matches[a:i]
    call remove(s:V.Matches, a:i)
    call matchdelete(m)
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
    let s:last_motion = a:motion
    return a:motion
endfun

fun! cursors#move()
    if !s:extending | return | endif
    let s:extending = 0

    let i = 0
    for c in s:V.Regions
        call cursor(c.l, c.a)
        call s:remove_match(i)
        exe "normal! v".c['w']."l".s:last_motion."y`]"
        call cursors#regions#new()
        let i += 1
    endfor

    let s:current_matches = getmatches()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#toggle_whole_word()
    let s:v.whole_word = !s:v.whole_word
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

