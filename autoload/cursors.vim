let s:started = 0 | let s:whole_word = 0 | let s:last_motion = 0 | let s:extending = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#find_under(visual, wrap)
    let s:started = 1

    if a:visual                     " yank has already happened here
        call cursors#misc#init(0)

    else                            " start whole word search
        let s:whole_word = 1
        call cursors#misc#init(1)
        if a:wrap
            normal! yiW`]
        else
            normal! yiw`]
        endif
    endif

    call cursors#misc#set_search()
    call s:create_region(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:create_region(down)
    let s:current_index = cursors#regions#new()
    let s:going_down = a:down
    let s:current_matches = getmatches()
endfun

fun! cursors#find_next(...)

    "skip current match
    if a:0 | call s:remove_match(s:current_index) | endif

    normal! ngny`]
    call s:create_region(1)
endfun

fun! cursors#find_prev(...)

    "move to the beginning of the current match
    let current = g:Regions[s:current_index]
    let pos = [current.l, current.a]
    call cursor(pos)

    "skip current match
    if a:0 | call s:remove_match(s:current_index) | endif

    normal! NgNy`]
    call s:create_region(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#clear()
    let s:started = 0
    let s:whole_word = 0
    call cursors#misc#reset()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:remove_match(i)
    call remove(g:Regions, a:i)
    let m = g:VisualMatches[a:i]
    call remove(g:VisualMatches, a:i)
    call matchdelete(m)
endfun

fun! cursors#skip()
    if s:going_down
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
    for c in g:Regions
        echom string(c)
        call cursor(c.l, c.a)
        exe "normal! v".c['w']."l".s:last_motion
        let i += 1
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#toggle_whole_word()
    let s:whole_word = !s:whole_word
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

