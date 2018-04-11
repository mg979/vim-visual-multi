let s:motion = 0 | let s:current_i = 0 | let s:starting_col = 0
let s:Extend = { -> g:VM.extend_mode }

fun! s:init(whole, cursor, extend_mode)
    if a:extend_mode | let g:VM.extend_mode = 1 | endif

    "return if already initialized
    if g:VM.is_active | return 1 | endif

    if g:VM.motions_at_start | call vm#maps#motions(1) | endif

    let s:V       = vm#init_buffer(a:cursor)
    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:v.whole_word = a:whole
    let s:v.nav_direction = 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#change_mode()
    let g:VM.extend_mode = !s:Extend()

    if s:Extend()
        call s:Funcs.msg('Switched to Extend Mode')
        call s:Global.update_regions()
    else
        call s:Funcs.msg('Switched to Cursor Mode')
        call s:Global.collapse_regions()
    endif
    call s:Funcs.count_msg(0)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Add cursor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:check_extend_default(X)
    """If just starting, enable extend mode if option is set."""

    if s:Extend()                            | return s:init(0, 1, 1)
    elseif ( a:X || g:VM.extend_by_default ) | return s:init(0, 1, 1)
    else                                     | return s:init(0, 1, 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_at_word(yank, search)
    call s:check_extend_default(0)

    if a:yank | call s:yank(0) | endif
    normal! `[
    call s:Global.new_cursor()

    if a:search | call s:Search.set() | endif
    call s:Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_at_pos(where, extend, ...)
    call s:check_extend_default(a:extend)
    if a:where && !s:starting_col | let s:starting_col = col('.') | endif

    "silently add one cursor at pos
    if !a:0 | call s:Global.new_cursor() | endif

    if a:where == 1
        normal! j
        let R = s:Global.new_cursor()
    elseif a:where == 2
        normal! k
        let R = s:Global.new_cursor()
    endif

    "when adding cursors below or above, don't add on empty lines
    if g:VM.cursors_skip_shorter_lines && a:where && R.a < s:starting_col
        call R.remove()
        call vm#commands#add_cursor_at_pos(a:where, 0, 1) | return | endif
    let s:starting_col = 0
    call s:Funcs.count_msg(0)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find by regex
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#regex_reset(...)
    silent! cunmap <buffer> <cr>
    silent! cunmap <buffer> <esc>
    if a:0 | return a:1 | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#regex_abort()
    let @/ = s:regex_reg
    call s:Funcs.msg('Regex search aborted.') | call s:Funcs.count_msg(1)
    call setpos('.', s:regex_pos)
    call vm#commands#regex_reset()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#regex_done()
    call vm#commands#regex_reset()

    normal! gny`]
    call s:Search.get_slash_reg()

    if s:Extend() | call s:Global.get_region() | call s:Funcs.count_msg(0)
    else          | call vm#commands#add_cursor_at_word(0, 0)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_by_regex(...)
    if !g:VM.is_active | call vm#commands#regex_reset() | return | endif

    "store reg and position, to check if the search will be aborted
    let s:regex_pos = getpos('.')
    let s:regex_reg = @/

    cnoremap <silent> <buffer> <cr> <cr>:call vm#commands#regex_done()<cr>
    cnoremap <buffer> <esc> <cr>:call vm#commands#regex_abort()<cr>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find under commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: don't call s:Funcs.count_msg() after merging regions, or it will be
" called twice.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:yank(inclusive)
    if a:inclusive | normal! yiW`]
    else           | normal! yiw`]
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_under(visual, whole, inclusive)
    call s:init(a:whole, 0, 1)

    " yank and create region
    if !a:visual | call s:yank(a:inclusive) | endif

    call s:Search.set()
    call s:Global.get_region()
    call s:Funcs.count_msg(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_under(visual, whole, inclusive, ...)
    call s:init(a:whole, 0, 1)

    if !a:visual
        let R = s:Global.is_region_at_pos('.')

        "only yank if not on an existing region
        if empty(R) | call s:yank(a:inclusive)
        else | call s:Funcs.set_reg(R.txt) | endif
    endif

    call s:Search.set()
    let R = s:Global.get_region()
    call s:Global.merge_regions(R.l)
    if !a:0 | call vm#commands#find_next(0, 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_all(visual, whole, inclusive)
    call s:init(a:whole, 0, 1)

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
    call s:Funcs.count_msg(1)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find next/previous
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_next(n)
    if s:Extend()
        silent exe "normal! ".a:n."g".a:n."y`]"
        call s:Global.get_region()
        call s:Funcs.count_msg(0)
    else
        silent exe "normal! ".a:n."g".a:n."y`]"
        call vm#commands#add_cursor_at_word(0, 0)
    endif
    if a:n ==# 'n' | let s:v.nav_direction = 1
    else | let s:v.nav_direction = 0 | endif
endfun

fun! s:navigate(force, dir)
    if a:force && s:v.nav_direction != a:dir
        call s:Funcs.msg('Reversed direction.')
        let s:v.nav_direction = a:dir
        return 1
    elseif a:force || @/==''
        let i = a:dir? s:v.index+1 : s:v.index-1
        call s:Global.select_region(i)
        "redraw!
        call s:Funcs.count_msg(0)
        return 1
    endif
endfun

fun! s:skip()
    let r = s:Global.is_region_at_pos('.')
    if empty(r) | call s:navigate(1, s:v.nav_direction)
    else        | call r.remove()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#invert_direction()
    """Invert direction and reselect region."""

    "invert anchor
    if s:v.direction
        let s:v.direction = 0
        for r in s:Regions | let r.h = r.b | endfor
    else
        let s:v.direction = 1
        for r in s:Regions | let r.h = r.a | endfor
    endif

    call s:Global.update_highlight()
    call s:Global.select_region(s:v.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_next(skip, nav)
    call s:Search.validate()

    "just navigate to next
    if s:navigate(a:nav, 1) | return

    elseif a:skip | call s:skip() | endif
    "skip current match

    call s:get_next('n')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_prev(skip, nav)
    call s:Search.validate() | let r = s:Global.is_region_at_pos('.')

    "just navigate to previous
    if s:navigate(a:nav, 0) | return

    elseif a:skip | call s:skip() | endif
    "skip current match

    "move to the beginning of the current match
    if s:Extend() | call cursor(r.l, r.a) | endif

    call s:get_next('N')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#skip(just_remove)
    if a:just_remove
        let r = s:Global.is_region_at_pos('.')
        if !empty(r) | call r.remove() | endif
        call s:Funcs.count_msg(0)

    elseif s:v.nav_direction
        call vm#commands#find_next(1, 0)
    else
        call vm#commands#find_prev(1, 0)
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extend regions commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: always call s:extend_vars() before the motion, but after any other
" function that moves the cursor, else the autocmd will be triggered for the
" wrong function.

fun! s:extend_vars(n, this)
    let s:v.extending = a:n
    let s:current_i = s:v.index
    if a:this | let s:v.only_this = a:n | endif
    let s:v.silence = 1
    "let b:VM_backup = copy(b:VM_Selection)
endfun

let s:sublime = { -> !g:VM.is_active && g:VM.sublime_mappings }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion, this)
    if s:sublime() | call s:init(0, 1, 1) | call s:Global.new_cursor() | endif

    call s:extend_vars(1, a:this)
    let s:motion = a:motion
    call vm#commands#move(0, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#end_back(fast, this)
    if s:sublime() | call s:init(0, 1, 1) | call s:Global.new_cursor() | endif

    call s:extend_vars(1, a:this)
    let s:motion = a:fast? 'BBE' : 'bbbe'
    call vm#commands#move(0, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#merge_to_beol(eol, this)
    call s:extend_vars(1, a:this)
    let s:motion = a:eol? "\<End>" : '0'
    let s:v.merge_to_beol = 1
    let g:VM.extend_mode = 0
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

    if     index(['[', ']'], c) != -1 | let c = '[' | let d = ']'
    elseif index(['(', ')'], c) != -1 | let c = '(' | let d = ')'
    elseif index(['{', '}'], c) != -1 | let c = '{' | let d = '}'
    elseif index(['<', '>'], c) != -1 | let c = '<' | let d = '>'
    else
        let d = nr2char(getchar())
    endif
    return [c, d]
endfun

fun! vm#commands#select_motion(inclusive, this)
    if !s:Extend() | call vm#commands#change_mode() | endif
    let merge = 0 | let s:v.silence = 1
    if a:this     | call s:Global.new_cursor() | let merge = 1 | endif

    call s:extend_vars(2, a:this)

    let c = nr2char(getchar())
    let a = a:inclusive ? 'F' : 'T'

    if index(['"', "'", '`', '_', '-'], c) != -1
        let d = c

    elseif a:inclusive
        let x = s:inclusive(c) | let c = x[0] | let d = x[1]

    elseif c == '[' | let a = 'T' | let c = '[' | let d = ']'
    elseif c == ']' | let a = 'F' | let c = '[' | let d = ']'
    elseif c == '{' | let a = 'T' | let c = '{' | let d = '}'
    elseif c == '}' | let a = 'F' | let c = '{' | let d = '}'
    elseif c == '(' | let a = 'T' | let c = '(' | let d = ')'
    elseif c == ')' | let a = 'F' | let c = '(' | let d = ')'
    elseif c == '<' | let a = 'T' | let c = '<' | let d = '>'
    elseif c == '>' | let a = 'F' | let c = '<' | let d = '>'

    else
        let d = nr2char(getchar())
    endif

    let b = a==#'F' ? 'f' : 't'

    let s:motion = a.c
    call vm#commands#move(merge, 1)
    let s:motion = b.d
    call vm#commands#move(merge, 0)

    let s:v.silence = 0
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion event
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:can_from_back    = { -> s:motion == '$' && !s:v.direction }
let s:only_this        = { -> s:v.only_this || s:v.only_this_always }
let s:always_from_back = { -> index(['^', '0', 'F', 'T'],                     s:motion) >= 0 }
let s:forward          = { -> index(['w', 'W', 'e', 'E', 'l', 'f', 't'],      s:motion)  >= 0 }

fun! vm#commands#move(merge, restore_pos, ...)
    if !s:v.extending | return | endif
    let s:v.extending -= 1 | let merge = a:merge

    "store orientation of currently selected region
    let prev = s:Regions[s:current_i].dir

    if s:v.merge_to_beol
        let merge = 1

    elseif s:v.direction && s:always_from_back()
        call vm#commands#invert_direction()

    elseif s:can_from_back()
        call vm#commands#invert_direction()
    endif

    "select motion: store position to move to, in between the 2 motions
    if a:restore_pos | let pos = getpos('.') | endif

    if !len(s:Regions) | call vm#commands#add_cursor_at_pos('.', 0) | endif

    if s:only_this()
        call s:Regions[s:v.index].move(s:motion) | let s:v.only_this -= 1
        if a:restore_pos | call setpos('.', pos) | endif
    else
        for r in s:Regions
            call r.move(s:motion)
            if a:restore_pos | call setpos('.', pos) | endif
        endfor | endif

    "some motions will call this function more than once
    if s:v.extending | return | endif

    "update variables, facing direction, highlighting
    if merge | call s:Global.merge_regions() | endif

    let r = s:Global.select_region(s:current_i)

    "invert direction if regions orientation has changed
    if r.dir != prev | call vm#commands#invert_direction()
    else             | call s:Global.update_highlight() | endif

    call s:Funcs.count_msg(1)
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

