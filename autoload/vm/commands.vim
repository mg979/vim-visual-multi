let s:motion = ''
let s:X    = { -> g:VM.extend_mode }
let s:B    = { -> g:VM.is_active && s:v.block_mode && g:VM.extend_mode }
let s:is_r = { -> g:VM.is_active && !empty(s:G.is_region_at_pos('.')) }

fun! s:init(whole, cursor, extend_mode)
    if a:extend_mode | let g:VM.extend_mode = 1 | endif

    "return if already initialized
    if g:VM.is_active

        if s:v.using_regex | call vm#commands#regex_reset() | endif
        let s:v.whole_word = a:whole
        return 1 | endif

    let s:V       = vm#init_buffer(a:cursor)

    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs
    let s:Search  = s:V.Search
    let s:Block   = s:V.Block

    let s:R    = { -> s:V.Regions }

    let s:v.whole_word = a:whole
    let s:v.nav_direction = 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#select_operator(all, count, ...)
    """Perform a yank, the autocmd will create the region.

    if !a:all
        if !g:VM.is_active     | call s:init(0, 0, 1)   | endif
        if g:VM.oldupdate      | let &updatetime = 10   | endif
        let g:VM.selecting = 1 | let g:VM.extend_mode = 1
        silent! nunmap <buffer> y
        return
    endif

    let s:v.storepos = getpos('.')[1:2]

    if a:0 | call s:V.Edit.select_op('y'.a:1) | return | endif

    let abort = 0
    let s = ''                     | let n = ''
    let x = a:count>1? a:count : 1 | echo "Selecting: s"

    let l:Single = { c -> index(split('webWEB$0^', '\zs'), c) >= 0 }
    let l:Double = { c -> index(split('iaftFT', '\zs'), c) >= 0    }

    while 1
        let c = nr2char(getchar())
        if c == "\<esc>"                 | let abort = 1 | break

        elseif str2nr(c) > 1 && empty(s) | let n .= c    | echon c

        elseif str2nr(c) > 0             | let s .= c    | echon c
            break

        elseif l:Single(c)               | let s .= c    | echon c
            break

        elseif l:Double(c)
            let s .= c                   | echon c
            let s .= nr2char(getchar())  | echon c
            break

        else                             | let abort = 1  | break    | endif
    endwhile

    if abort | return | endif

    let n = n*x>1? n*x : ''
    call s:V.Edit.select_op('y'.n.s)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Add cursor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:check_extend_default(X)
    """If just starting, enable extend mode if option is set."""

    if s:X()                                 | return s:init(0, 1, 1)
    elseif ( a:X || g:VM_extend_by_default ) | return s:init(0, 1, 1)
    else                                     | return s:init(0, 1, 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_at_word(yank, search)
    call s:init(0, 1, 0)

    if a:yank   | call s:yank(0)      | exe "keepjumps normal! `[" | endif
    if a:search | call s:Search.add() | endif

    let R = s:G.new_cursor() | let R.pat = s:v.search[0]
    call s:F.restore_reg()
    call s:F.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:skip_shorter_lines(where)
    let vcol    = s:v.vertical_col
    let col     = col('.')
    "we don't want cursors on final column('$'), except when adding at column 1
    "in this case, moving to an empty line would give:
    "   vcol     = 1
    "   col      = 1
    "   endline  = 1
    "and the line would be skipped. 'Push' endline, so that the cursor is added
    if g:VM_skip_empty_lines
        let endline = col('$')
    else
        let endline = (col('$') > 1)? col('$') : 2
    endif

    "when adding cursors below or above, don't add on shorter lines
    if ( col < vcol || col == endline )
        call vm#commands#add_cursor_at_pos(a:where, 0, 1) | return 1
    endif

    if !s:V.Block.vertical() | call s:G.new_cursor() | else | return 1 | endif
endfun

fun! vm#commands#add_cursor_at_pos(where, extend, ...)
    "stop at first and last line if adding cursors vertically
    if     a:where == 2 && line('.') == 1         | return
    elseif a:where == 1 && line('.') == line('$') | return | endif

    call s:check_extend_default(a:extend)

    if a:where
        if (!s:v.vertical_col || (col('.') > 1 && s:v.vertical_col > 1))
            let s:v.vertical_col = col('.') | endif

    else | call s:Block.stop() | endif

    "add one cursor at pos, if not adding vertically from callback function
    if !a:0 | call s:G.new_cursor() | endif

    if a:where == 1
        keepjumps normal! j
        if s:skip_shorter_lines(a:where) | return | endif
    elseif a:where == 2
        keepjumps normal! k
        if s:skip_shorter_lines(a:where) | return | endif
    endif

    call s:F.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#erase_regions(...)
    """Clear all regions, but stay in visual-multi mode.

    "empty start
    if !g:VM.is_active | call s:init(0,1,0) | return | endif

    let s:V.Regions = []
    call clearmatches()
    let s:v.index = -1
    call s:V.Block.stop()
    if !a:0 | call s:F.count_msg(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#expand_line(down)
    call s:check_extend_default(1)
    if !s:v.multiline | call s:F.toggle_option('multiline') | endif

    let R = s:G.is_region_at_pos('.')
    if empty(R)
        let eol = col('$') | let ln = line('.')
        let l = eol>1? ln : a:down? ln   : ln-1
        let L = eol>1? ln : a:down? ln+1 : ln
        call vm#region#new(0, l, L, 1, col([L, '$']))
        if !a:down | call vm#commands#invert_direction() | endif
    elseif a:down
        call vm#commands#motion('j', 1, 1, 1)
        call R.update_region(R.l, R.L, 1, col([R.L, '$']))
    elseif !a:down
        call vm#commands#motion('k', 1, 1, 1)
        let b = len(getline(R.L))
        call R.update_region(R.l, R.L, 1, col([R.L, '$']))
    endif
    call s:G.select_region_at_pos('.')
    call s:G.update_highlight()
    call s:F.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find by regex
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#regex_reset(...)
    silent! cunmap <buffer> <cr>
    let s:v.using_regex = 0
    if a:0 | return a:1 | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#regex_abort()
    let @/ = s:regex_reg
    call s:F.msg('Regex search aborted. ', 0) | call s:F.count_msg(0)
    call setpos('.', s:regex_pos)             | call vm#commands#regex_reset()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#regex_done()
    call vm#commands#regex_reset()

    if s:X() | silent keepjumps normal! gny`]
    else     | silent keepjumps normal! gny
    endif
    call s:Search.get_slash_reg()

    if s:X() | call s:G.new_region()                     | call s:F.count_msg(0)
    else     | call vm#commands#add_cursor_at_word(0, 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_by_regex(...)
    if !g:VM.is_active | call s:init(0, 0, 1) | endif
    let s:v.using_regex = 1

    "store reg and position, to check if the search will be aborted
    let s:regex_pos = getpos('.') | let s:regex_reg = @/

    cnoremap <silent> <buffer> <cr>  <cr>:call vm#commands#regex_done()<cr>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find under commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NOTE: don't call s:F.count_msg() after merging regions, or it will be
" called twice.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:yank(inclusive)
    if a:inclusive | silent keepjumps normal! yiW`]
    else           | silent keepjumps normal! yiw`]
    endif
endfun

fun! s:check_overlap(R)
    if s:G.overlapping_regions(a:R) | return s:G.merge_regions() | endif
    return a:R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_under(visual, whole, inclusive, ...)
    call s:init(a:whole, 0, 1)

    "C-d command
    if a:0 && s:is_r() | return vm#commands#find_next(0, 0) | endif

    " yank and create region
    if !a:visual | call s:yank(a:inclusive)                 | endif

    "replace region if calling the command on an existing region
    if s:is_r()  | call s:G.is_region_at_pos('.').remove()  | endif

    call s:Search.add()
    let R = s:G.new_region()
    if R.h && !s:v.multiline | call s:F.toggle_option('multiline') | endif
    call s:F.count_msg(1)
    return (a:0 && a:visual)? vm#commands#find_next(0, 0) : R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_all(visual, whole, inclusive)
    call s:init(a:whole, 0, 1)

    let storepos = getpos('.')
    let s:v.eco = 1
    let seen = []

    if !a:visual | let R = s:G.is_region_at_pos('.')
        if empty(R) | let R = vm#commands#find_under(0, a:whole, a:inclusive) | endif
    else
        let R = vm#commands#find_under(1, a:whole, a:inclusive) | endif

    while index(seen, R.id) == -1
        call add(seen, R.id)
        let R = vm#commands#find_next(0, 0)
    endwhile

    call setpos('.', storepos)
    call s:G.eco_off()
    call s:G.reset_byte_map(1)
    call s:G.update_highlight()
    call s:G.select_region_at_pos('.')
    call s:F.count_msg(1)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find next/previous
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_next()
    if s:X()
        silent keepjumps normal! ngny`]
        let R = s:G.new_region()
        call s:F.count_msg(1)
    else
        silent keepjumps normal! ngny`[
        let R = vm#commands#add_cursor_at_word(0, 0)
    endif
    let s:v.nav_direction = 1
    return R
endfun

fun! s:get_prev()
    if s:X()
        silent keepjumps normal! NgNy`]
        let R = s:G.new_region()
        call s:F.count_msg(1)
    else
        silent keepjumps normal! NgNy`[
        let R = vm#commands#add_cursor_at_word(0, 0)
    endif
    let s:v.nav_direction = 0
    return R
endfun

fun! s:navigate(force, dir)
    if a:force && s:v.nav_direction != a:dir
        call s:F.msg('Reversed direction.', 1)
        let s:v.nav_direction = a:dir
        return s:keep_block()
    elseif a:force || @/==''
        let i = a:dir? s:v.index+1 : s:v.index-1
        call s:G.select_region(i)
        call s:F.count_msg(1)
        return s:keep_block() | endif
endfun

fun! s:skip()
    let r = s:G.is_region_at_pos('.')
    if empty(r) | call s:navigate(1, s:v.nav_direction)
    else        | call r.remove()
    endif
endfun

fun! s:keep_block()
    if s:v.block_mode | let s:v.block[3] = 1 | endif | return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_next(skip, nav)
    if ( a:nav || a:skip ) && s:F.no_regions()                          | return | endif
    if !s:X() && a:skip && s:is_r()          | call vm#commands#skip(1) | return | endif

    "write search pattern if not navigating and no search set
    if s:X() && !a:nav && @/=='' | let s:motion = '' | call s:Search.rewrite(1) | endif

    call s:Search.validate()

    "just navigate to next
    if s:navigate(a:nav, 1) | return

    elseif a:skip | call s:skip() | endif
    "skip current match

    return s:get_next()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_prev(skip, nav)
    if ( a:nav || a:skip ) && s:F.no_regions()                          | return | endif
    if !s:X() && a:skip && s:is_r()          | call vm#commands#skip(1) | return | endif

    "write search pattern if not navigating and no search set
    if s:X() && !a:nav && @/=='' | let s:motion = '' | call s:Search.rewrite(1) | endif

    call s:Search.validate()

    let r = s:G.is_region_at_pos('.')
    if empty(r)  | let r = s:G.select_region(s:v.index) | endif
    if !empty(r) | let pos = [r.l, r.a]
    else         | let pos = getpos('.')[1:2] | endif

    "just navigate to previous
    if s:navigate(a:nav, 0) | return

    elseif a:skip | call s:skip() | endif
    "skip current match

    "move to the beginning of the current match
    call cursor(pos)
    return s:get_prev()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#skip(just_remove)
    if s:F.no_regions() | return | endif

    if a:just_remove
        let r = s:G.is_region_at_pos('.')
        if !empty(r)
            call s:G.remove_last_region(r.id)
            call s:keep_block()
        endif

    elseif s:v.nav_direction
        call vm#commands#find_next(1, 0)
    else
        call vm#commands#find_prev(1, 0)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#invert_direction()
    """Invert direction and reselect region."""
    if s:v.auto | return | endif

    for r in s:R() | let r.dir = !r.dir | endfor

    "invert anchor
    if s:v.direction
        let s:v.direction = 0
        for r in s:R() | let r.k = r.b | let r.K = r.B | endfor
    else
        let s:v.direction = 1
        for r in s:R() | let r.k = r.a | let r.K = r.A | endfor
    endif

    call s:G.update_highlight()
    call s:G.select_region(s:v.index)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:sublime = { -> !g:VM.is_active && g:VM_sublime_mappings }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion, count, select, this)

    let s:motion = a:count>1? a:count.a:motion : a:motion

    "-----------------------------------------------------------------------

    "start if sublime mappings are set;
    "reselect region on motion unless a:this (eg M-<> adds a new region)
    if s:sublime()          | call s:init(0, 1, 1)     | call s:G.new_cursor()
    elseif s:F.no_regions() || ( a:this && !s:is_r() ) | call s:G.new_cursor() | endif

    "-----------------------------------------------------------------------

    if s:symbol()          | let s:v.merge = 1          | endif
    if a:select && !s:X()  | let g:VM.extend_mode = 1   | endif

    if a:select && !s:v.multiline && s:vertical()
        call s:F.toggle_option('multiline') | endif

    call s:V.Block.horizontal(1)
    call s:call_motion(a:this)
    call s:V.Block.horizontal(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#remap_motion(motion)
    if s:F.no_regions() | return | endif
    let s:motion = a:motion
    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#end_back(fast, this, ...)
    if s:sublime()      | call s:init(0, 1, 1)     | call s:G.new_cursor() | endif
    if s:F.no_regions() | return                   | endif
    if a:0 && !s:X()    | let g:VM.extend_mode = 1 | endif

    let s:motion = a:fast? 'BBW' : 'bbbe'
    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#merge_to_beol(eol, this)
    if s:F.no_regions() | return                  | endif
    if s:X()            | call s:G.change_mode(1) | endif

    let s:motion = a:eol? "\<End>" : '0'
    let s:v.merge = 1
    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_motion(motion, char, this, ...)
    if s:F.no_regions() | return | endif

    if a:char != ''
        let s:motion = a:motion.a:char
    else
        let s:motion = a:motion.nr2char(getchar())
    endif

    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#shrink_or_enlarge(shrink, this)
    """Reduce/enlarge selection size by 1."""
    if s:F.no_regions() | return                  | endif
    if !s:X()           | call s:G.change_mode(1) | endif

    let dir = s:v.direction

    let s:motion = a:shrink? (dir? 'h':'l') : (dir? 'l':'h')
    call s:call_motion(a:this)

    call vm#commands#invert_direction()

    let s:motion = a:shrink? (dir? 'l':'h') : (dir? 'h':'l')
    call s:call_motion(a:this)

    if s:v.direction != dir | call vm#commands#invert_direction() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion event
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:only_this        = {   -> s:v.only_this || s:v.only_this_always               }
let s:can_from_back    = {   -> s:X() && s:motion == '$' && !s:v.direction          }
let s:always_from_back = {   -> s:X() && index(['^', '0', 'F', 'T'], s:motion) >= 0 }
let s:symbol           = {   -> index(['^', '0', '%', '$'],          s:motion) >= 0 }
let s:horizontal       = {   -> index(['h', 'l'],                    s:motion) >= 0 }
let s:vertical         = {   -> index(['j', 'k'],                    s:motion) >= 0 }
let s:simple           = { m -> index(split('hlwebWEB', '\zs'),      m)        >= 0 }

fun! s:call_motion(this)
    let s:v.moving = 1
    let s:v.only_this = a:this
    "let b:VM_backup = copy(b:VM_Selection)

    call vm#commands#move()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#move(...)
    if !s:v.moving || s:F.no_regions() | return | endif

    let R = s:R()[ s:v.index ]

    call s:before_move()

    if s:only_this()
        call R.move(s:motion) | let s:v.only_this = 0
    else
        for r in s:R()        | call r.move(s:motion) | endfor | endif

    "update variables, facing direction, highlighting
    call s:after_move(R)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_move()
    let s:v.moving -= 1
    call s:G.reset_byte_map(0)

    if s:v.direction && s:always_from_back()
        call vm#commands#invert_direction()

    elseif s:can_from_back()
        call vm#commands#invert_direction()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_move(R)
    let s:v.direction = a:R.dir

    if s:always_from_back() | call vm#commands#invert_direction() | endif

    if s:v.merge
        call s:G.select_region(a:R.index)
        call s:G.update_and_select_region(a:R.A)
    else
        call s:F.restore_reg()
        call s:G.update_highlight()
        call s:G.select_region(a:R.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Align
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#align(count, regex)
    if s:X() | call s:G.change_mode(1) | endif

    if !a:regex
        let n = a:count | let s = n>1? 's' : ''
        echohl Label    | echo 'Align with '.n.' char'.s.' > '   | echohl None

        let C = [] | let s = 'czp'
        while n
            let c = nr2char(getchar())
            if c == "\<esc>" | echohl WarningMsg | echon ' ...Aborted' | return
            else             | call add(C, c) | let n -= 1 | echon c
            endif
        endwhile

        let s:v.silence = 1
        while !empty(C)
            let c = remove(C, 0)

            "remove region if a match isn't found, otherwise it will be aligned
            for r in s:R()
                call cursor(r.l, r.a)
                if !search(c, s, r.l) | call r.remove() | continue | endif
                call r.update_cursor([r.l, getpos('.')[2]])
            endfor

            "TODO: strip white spaces preceding the shortest columns
            call s:V.Edit.align()
            let s = 'zp'
        endwhile
        let s:v.silence = 0
        call s:F.count_msg(0)
        return
    endif

    echohl Label | let rx = input('Align with regex > ')   | echohl None
    if empty(rx) | echohl WarningMsg | echon ' ...Aborted' | return  | endif

    set nohlsearch
    for r in s:R()
        call cursor(r.l, r.a)
        if !search(rx, 'czp', r.l) | call r.remove() | continue | endif
        call r.update_cursor([r.l, getpos('.')[2]])
    endfor
    call s:V.Edit.align()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#undo()
    call clearmatches()
    echom b:VM_backup == b:VM_Selection
    let b:VM_Selection = copy(b:VM_backup)
    call s:G.update_highlight()
    call s:G.select_region(s:v.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

