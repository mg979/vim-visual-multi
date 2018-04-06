let s:motion = 0 | let s:extending = 0 | let s:current_i = 0

fun! s:init(whole)
    let was_active = g:VM_Global.is_active
    let s:V       = vm#init_buffer()

    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:v.whole_word = a:whole
    return was_active
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Start empty
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#start()
    call s:init(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Add cursor command
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_at_pos(pos)
    call s:init(0)

    "try to create cursor
    call s:Global.new_cursor()

    if a:pos == 1
        normal! j
        call s:Global.new_cursor()
    elseif a:pos == 2
        normal! k
        call s:Global.new_cursor()
    endif
    call s:Funcs.count_msg()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find by regex
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_regex()
    cunmap <buffer> <cr>
    if @/ == s:regex_reg | call setpos('.', s:regex_pos) | return | endif

    normal gny`]
    call s:Search.read()
    call s:Global.get_region(1)
    call s:Funcs.count_msg()
endfun

fun! vm#commands#find_by_regex(...)
    call s:init(0)
    let s:regex_pos = getpos('.')
    let s:regex_reg = @/
    call s:Funcs.msg('Enter regex:')
    call s:Funcs.msg('Enter regex:')
    cnoremap <buffer> <cr> <cr>:call vm#commands#find_regex()<cr>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find under commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_under(visual, whole, inclusive)
    call s:init(a:whole)

    if !a:visual           " yank and create region
        if a:inclusive
            normal! yiW`]
        else
            normal! yiw`]
        endif
    endif

    call s:Search.set()
    call s:Global.get_region(1)
    call s:Funcs.count_msg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_under(visual, whole, inclusive, ...)

    if !a:visual
        let R = s:Global.is_region_at_pos('.')

        "only yank if not on an existing region
        if empty(R)
            if a:inclusive
                normal! yiW`]
            else
                normal! yiw`]
            endif
        else
            call s:Funcs.set_reg(R.txt)
        endif
    endif

    let s:v.whole = a:whole
    call s:Search.set()
    let R = s:Global.get_region(1)
    call s:Global.merge_regions(R.l)
    if !a:0 | call vm#commands#find_next(0, 0) | endif
    call s:Funcs.count_msg()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_next(skip, nav)
    let i = s:v.index

    "just reverse direction if going ip
    if !s:v.direction
        let s:v.direction = 1
        call s:Global.select_region(i)
        return
    endif

    "just navigate to next
    if a:nav | call s:Global.select_region(s:v.index+1) | return | endif

    "skip current match
    if a:skip | call s:Regions[i].remove() | endif

    silent normal! ngny`]
    call s:Global.get_region(1)
    call s:Funcs.count_msg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_prev(skip, nav)
    let i = s:v.index

    "just reverse direction if going down
    if s:v.direction
        let s:v.direction = 0
        call s:Global.select_region(i)
        return
    endif

    "just navigate to previous
    if a:nav | call s:Global.select_region(s:v.index-1) | return | endif

    "move to the beginning of the current match
    let current = s:Regions[i]
    let pos = [current.l, current.a]
    call cursor(pos)

    "skip current match
    if a:skip | call s:Regions[i].remove() | endif

    silent normal! NgNy`[
    call s:Global.get_region(0)
    call s:Funcs.count_msg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_all(visual, whole, inclusive)
    call s:init(a:whole)

    let storepos = getpos('.')
    let oldredraw = &lz | set lz
    let s:v.silence = 1
    let seen = []

    call vm#commands#find_under(a:visual, a:whole, a:inclusive)

    while index(seen, s:v.index) == -1
        call add(seen, s:v.index)
        call vm#commands#find_next(0, 0)
    endwhile

    call setpos('.', storepos)
    let &lz = oldredraw
    let s:v.silence = 0
    call s:Funcs.count_msg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#skip()
    if s:v.direction
        call vm#commands#find_next(1, 0)
    else
        call vm#commands#find_prev(1, 0)
    endif
    call s:Funcs.count_msg()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extend regions commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:extend_vars(n, this)
    let s:extending = a:n
    let s:current_i = s:v.index
    if a:this | let s:v.only_this = 1 | endif
    "let b:VM_backup = copy(b:VM_Selection)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion, this)
    call s:extend_vars(1, a:this)
    let s:motion = a:motion
    return a:motion
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_motion(motion, char, this)
    call s:extend_vars(1, a:this)
    if a:char != ''
        let s:motion = a:motion.a:char
    else
        let s:motion = a:motion.nr2char(getchar())
    endif
    return s:motion
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#select_motion(inclusive, this)
    let was_active = s:init(0)
    let s:v.silence = 1
    call s:extend_vars(2, a:this)
    let c = nr2char(getchar())

    let a = a:inclusive ? 'F' : 'T'
    let b = a:inclusive ? 'f' : 't'

    if index(['"', "'", '`', '_', '-'], c) != -1
        let d = c
    elseif index(['[', ']'], c) != -1
        let c = '[' | let d = ']'
    elseif index(['(', ')'], c) != -1
        let c = '(' | let d = ')'
    elseif index(['{', '}'], c) != -1
        let c = '[' | let d = '}'
    elseif index(['<', '>'], c) != -1
        let c = '<' | let d = '>'
    else
        let d = nr2char(getchar())
    endif

    exe "normal ".a.c
    call vm#commands#move(1)
    exe "normal ".b.d
    call vm#commands#move()

    let s:v.silence = 0
    if !was_active | call vm#commands#add_under(0, 0, 0, 1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion event
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#move(...)
    if !s:extending | return | endif
    let s:extending -= 1
    let s:v.move_from_back = !s:v.direction

    "select motion: store position to move to, in between the 2 motions
    if a:0 | let pos = getpos('.') | endif

    if !len(s:Regions) | call vm#commands#add_cursor_at_pos('.') | endif

    if (s:v.only_this || s:v.only_this_all) | let s:v.only_this = 0
        call s:Regions[s:v.index].move(s:motion)
    else
        for r in s:Regions
            call r.move(s:motion)
            if a:0 | call setpos('.', pos) | endif
        endfor | endif

    normal! `]

    call setmatches(s:v.matches)
    let s:v.move_from_back = 0
    call s:Global.update_cursor_highlight()
    call s:Global.select_region(s:current_i)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#undo()
    call clearmatches()
    echom b:VM_backup == b:VM_Selection
    let b:VM_Selection = copy(b:VM_backup)
    call setmatches(s:v.matches)
    call s:Global.update_cursor_highlight()
    call s:Global.select_region(s:current_i)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle options
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#toggle_option(option)
    let s = "s:v.".a:option
    exe "let" s "= !".s

    if a:option == 'whole_word'
        let s = s:v.search[0]

        if s:v.whole_word
            if s[:1] != '\<' | let s:v.search[0] = '\<'.s.'\>' | endif
            call s:Funcs.msg('Search ->  whole word')
        else
            if s[:1] == '\<' | let s:v.search[0] = s[2:-3] | endif
            call s:Funcs.msg('Search ->  not whole word')
        endif
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

