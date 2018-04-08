let s:motion = 0 | let s:current_i = 0

fun! s:init(whole, empty)
    if g:VM_Global.is_active | return 1 | endif

    let s:V       = vm#init_buffer(a:empty)
    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:v.whole_word = a:whole
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Start empty
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#start()
    call s:init(0, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Add cursor command
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_at_pos(pos)
    let was_active = s:init(0, 1)

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
    call s:init(0, 0)
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
    call s:init(a:whole, 0)

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
    if !a:nav && @/ == '' | return | endif
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
    if !a:nav && @/ == '' | return | endif
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
    call s:init(a:whole, 0)

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

fun! vm#commands#skip(just_remove)
    if a:just_remove
        let r = s:Global.is_region_at_pos('.')
        if !empty(r) | call r.remove() | endif

    elseif s:v.direction
        call vm#commands#find_next(1, 0)
    else
        call vm#commands#find_prev(1, 0)
    endif
    call s:Funcs.count_msg()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extend regions commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: always call s:extend_vars() just the real motion, but after any other
" function that moves the cursor, or the autocmd will be triggered for the
" wrong function.

fun! s:extend_vars(n, this)
    let s:v.extending = a:n
    let s:current_i = s:v.index
    if a:this | let s:v.only_this = a:n | endif
    "let b:VM_backup = copy(b:VM_Selection)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion, this)
    call s:extend_vars(1, a:this)
    let s:motion = a:motion
    call vm#commands#move(0, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#merge_to_beol(eol, this)
    call s:extend_vars(1, a:this)
    let s:motion = a:eol? "\<End>" : '0'
    let s:v.merge_to_beol = 1
    call vm#commands#move(1, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_motion(motion, char, this, ...)
    call s:extend_vars(1, a:this) | let merge = 0

    if index(['$', '0', '^', '%'], a:motion) >= 0
        let s:motion = a:motion | let merge = 1
    elseif a:char != ''
        let s:motion = a:motion.a:char
    else
        let s:motion = a:motion.nr2char(getchar())
    endif

    call vm#commands#move(merge, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:inclusive(c)
    let c = a:c

    if index(['[', ']'], c) != -1
        let c = '[' | let d = ']'
    elseif index(['(', ')'], c) != -1
        let c = '(' | let d = ')'
    elseif index(['{', '}'], c) != -1
        let c = '{' | let d = '}'
    elseif index(['<', '>'], c) != -1
        let c = '<' | let d = '>'
    else
        let d = nr2char(getchar())
    endif
    return [c, d]
endfun

fun! vm#commands#select_motion(inclusive, this)
    let was_active = s:init(0, 0) | let merge = 0
    let s:v.silence = 1
    if a:this | call s:Global.new_cursor() | let merge = 1 | endif
    call s:extend_vars(2, a:this)

    let c = nr2char(getchar())
    let a = a:inclusive ? 'F' : 'T'

    if index(['"', "'", '`', '_', '-'], c) != -1
        let d = c

    elseif a:inclusive
        let x = s:inclusive(c) | let c = x[0] | let d = x[1]

    elseif c == '['
        let a = 'T' | let c = '[' | let d = ']'

    elseif c == ']'
        let a = 'F' | let c = '[' | let d = ']'

    elseif c == '{'
        let a = 'T' | let c = '{' | let d = '}'

    elseif c == '}'
        let a = 'F' | let c = '{' | let d = '}'

    elseif c == '('
        let a = 'T' | let c = '(' | let d = ')'

    elseif c == ')'
        let a = 'F' | let c = '(' | let d = ')'

    elseif c == '<'
        let a = 'T' | let c = '<' | let d = '>'

    elseif c == '>'
        let a = 'F' | let c = '<' | let d = '>'

    else
        let d = nr2char(getchar())
    endif

    let b = a==#'F' ? 'f' : 't'

    let s:motion = a.c
    call vm#commands#move(merge, 1)
    let s:motion = b.d
    call vm#commands#move(merge, 0)

    if !was_active
        if !s:Global.all_empty()
            call vm#commands#add_under(0, 0, 0, 1)
            let s:v.silence = 0
        else
            let s:v.silence = 0
            call s:Funcs.msg('Not found. Exiting Visual-multi.')
            let s:v.silence = 1
            call vm#funcs#reset()
        endif
    else
        let s:v.silence = 0
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion event
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:always_from_back = { -> index(['^', '0'], s:motion) >= 0 }
let s:can_from_back    = { -> index(['$'], s:motion) == -1 && !s:v.direction }
let s:only_this        = { -> s:v.only_this || s:v.only_this_always }

fun! vm#commands#move(merge, restore_pos, ...)
    if !s:v.extending | return | endif
    let s:v.extending -= 1 | let merge = a:merge

    if s:v.merge_to_beol
        let merge = 1
    elseif s:v.direction && s:always_from_back()
        call vm#commands#find_prev(0, 0)
        let s:v.move_from_back = 1
    else
        let s:v.move_from_back = s:can_from_back()
    endif

    "select motion: store position to move to, in between the 2 motions
    if a:restore_pos | let pos = getpos('.') | endif

    if !len(s:Regions) | call vm#commands#add_cursor_at_pos('.') | endif

    if s:only_this()
        call s:Regions[s:v.index].move(s:motion) | let s:v.only_this -= 1
    else
        for r in s:Regions
            call r.move(s:motion)
            if a:restore_pos | call setpos('.', pos) | endif
        endfor | endif

    normal! `]

    let s:v.move_from_back = 0
    if merge | call s:Global.merge_regions() | endif
    call s:Global.update_highlight()
    call s:Global.select_region(s:current_i)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#undo()
    call clearmatches()
    echom b:VM_backup == b:VM_Selection
    let b:VM_Selection = copy(b:VM_backup)
    call s:Global.update_highlight()
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

