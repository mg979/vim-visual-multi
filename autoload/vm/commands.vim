let s:X          = { -> g:VM.extend_mode }
let s:B          = { -> g:VM.is_active && s:v.block_mode && g:VM.extend_mode }
let s:is_r       = { -> g:VM.is_active && !empty(s:G.is_region_at_pos('.')) }
let s:first_line = { -> line('.') == 1 }
let s:last_line  = { -> line('.') == line('$') }

fun! vm#commands#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs
    let s:Search  = s:V.Search
    let s:Block   = s:V.Block
    let s:R       = { -> s:V.Regions }    "all regions
    let s:RS      = { -> s:G.regions() }  "current regions set
    let s:Group   = { -> s:V.Groups[s:v.active_group] }

    let s:v.motion = ''
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:init(whole, empty, extend_mode)
    if a:extend_mode | let g:VM.extend_mode = 1 | endif

    "return true if already initialized
    if g:VM.is_active
        call s:F.Scroll.get()
        if s:v.using_regex | call vm#commands#regex_reset() | endif
        let s:v.whole_word = a:whole
        return 1
    else
        call vm#init_buffer(a:empty)
        call s:F.Scroll.get()
        let s:v.whole_word = a:whole
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:check_extend_default(X)
    """If just starting, enable extend mode if option is set."""

    if s:X()                                 | return s:init(0, 1, 1)
    elseif ( a:X || g:VM_extend_by_default ) | return s:init(0, 1, 1)
    else                                     | return s:init(0, 1, 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Add cursor
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

fun! s:set_vcol()
    let is_tab = s:F.char_under_cursor() == "\t"
    let vcol   = s:v.vertical_col

    if !is_tab && ( !vcol || ( col('.') > 1 && vcol > 1 ) )
        let s:v.vertical_col = virtcol('.')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:skip_shorter_lines()
    "when adding cursors below or above, don't add on shorter lines
    "we don't want cursors on final column('$'), except when adding at column 1
    "in this case, moving to an empty line would give:
    "   vcol     = 1
    "   col      = 1
    "   endline  = 1
    "and the line would be skipped: check endline as 2, so that the cursor is added

    let vcol    = s:v.vertical_col
    let col     = virtcol('.')
    let endline = g:VM_skip_empty_lines? virtcol('$') : ((virtcol('$') > 1)? virtcol('$') : 2)

    "skip line
    if ( col < vcol || col == endline ) | return 1              | endif

    "in block mode, cursor add is handled in block script
    if !s:V.Block.vertical()            | call s:G.new_cursor() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_at_pos(extend)
    call s:check_extend_default(a:extend)
    call s:Block.stop()
    call s:G.new_cursor(1)
    call s:F.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_down(extend, count)
    if s:last_line() | return | endif
    call s:check_extend_default(a:extend)
    call s:set_vcol()
    call s:G.new_cursor()
    let N = a:count>1? a:count-1 : 1

    while N
        keepjumps normal! j
        if !s:skip_shorter_lines() | let N -= 1 | endif
        if s:last_line()           | break      | endif
    endwhile
    call s:F.count_msg(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#add_cursor_up(extend, count)
    if s:first_line() | return | endif
    call s:check_extend_default(a:extend)
    call s:set_vcol()
    call s:G.new_cursor()
    let N = a:count>1? a:count-1 : 1

    while N
        keepjumps normal! k
        if !s:skip_shorter_lines() | let N -= 1 | endif
        if s:first_line()          | break      | endif
    endwhile
    call s:F.count_msg(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#erase_regions(...)
    """Clear all regions, but stay in visual-multi mode.

    "empty start
    if !g:VM.is_active | call s:init(0,1,0) | return | endif

    call s:G.remove_highlight()
    let s:V.Regions = []
    let s:V.Bytes = {}
    let s:V.Groups = {}
    let s:v.index = -1
    call s:V.Block.stop()
    if a:0 | call s:F.count_msg(1) | endif
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
    let s:v.visual_regex = s:v.using_regex == 2
    call vm#commands#regex_reset()

    if s:v.visual_regex
        call s:Search.get_slash_reg()
        let g:VM.selecting = 1 | let s:v.finding = 1
        silent keepjumps normal! gvy
        return

    elseif s:X() | silent keepjumps normal! gny`]
    else         | silent keepjumps normal! gny
    endif
    call s:Search.get_slash_reg()

    if s:X() | call s:G.new_region()                     | call s:F.count_msg(0)
    else     | call vm#commands#add_cursor_at_word(0, 0) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_by_regex(mode)
    if !g:VM.is_active | call s:init(0, 0, 1) | endif
    let s:v.using_regex = a:mode

    "if visual regex, reposition cursor to the beginning of the selection
    if a:mode == 2 | exe "normal! `<" | endif

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

fun! s:check_overlap(R, ...)
    "if a:1 is given, just check without merging
    if s:G.overlapping_regions(a:R) | return a:0? 1 : s:G.merge_regions() | endif
    return a:0? 0 : a:R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#ctrld(count)
    call s:init(1, 0, 0)

    if !s:X() && s:is_r()
        call vm#operators#select(1, 1, "iw")
    else
        let s:v.silence = 1
        for i in range(a:count)
            call vm#commands#find_under(0, 1, 0, 1, 1)
        endfor
        let s:v.silence = 0
        call s:F.count_msg(0)
    endif
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
    call s:G.check_mutliline(0, R)
    call s:F.count_msg(0)
    return (a:0 && a:visual)? vm#commands#find_next(0, 0) : s:check_overlap(R)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find all
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_all(visual, whole, inclusive)
    call s:init(a:whole, 0, 1)

    let pos = getpos('.')[1:2]
    let s:v.eco = 1 | let s:v.multi_find = 1
    let seen = []

    if !a:visual | let R = s:G.is_region_at_pos('.')
        if empty(R) | let R = vm#commands#find_under(0, a:whole, a:inclusive) | endif
        call s:Search.check_pattern(R.pat)
    else
        let R = vm#commands#find_under(1, a:whole, a:inclusive) | endif

    while index(seen, R.id) == -1
        call add(seen, R.id)
        let R = vm#commands#find_next(0, 0, 1)
    endwhile

    let s:v.restore_scroll = 1
    call s:G.update_map_and_select_region(pos)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find next/previous
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_next_all()
    "variant for multiple searches (find_all, find_op, ...)
    silent keepjumps normal! ngny`]
    let R = s:G.new_region()
    if s:check_overlap(R, 1)
        let s:v.find_all_overlap = 1
    endif
    let s:v.nav_direction = 1
    return R
endfun

fun! s:get_next()
    "variant for single search (find_next)
    if s:X()
        silent keepjumps normal! ngny`]
        let R = s:G.new_region()
        call s:F.count_msg(0)
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
        call s:F.count_msg(0, ['Reversed direction. ', 'WarningMsg'])
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
    else        | call r.clear()
    endif
endfun

fun! s:keep_block()
    if s:v.block_mode | let s:v.block[3] = 1 | endif | return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_next(skip, nav, ...)
    if a:0 | return s:get_next_all() | endif       "multiple calls: shortcut and no message

    if ( a:nav || a:skip ) && s:F.no_regions()                          | return | endif
    if !s:X() && a:skip && s:is_r()          | call vm#commands#skip(1) | return | endif

    "write search pattern if not navigating and no search set
    if s:X() && !a:nav && @/=='' | let s:v.motion = '' | call s:Search.rewrite(1) | endif

    call s:Search.validate()

    if s:navigate(a:nav, 1) | return 0                    "just navigate to previous
    elseif a:skip           | call s:skip() | endif       "skip current match

    return s:get_next()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_prev(skip, nav)
    if ( a:nav || a:skip ) && s:F.no_regions()                          | return | endif
    if !s:X() && a:skip && s:is_r()          | call vm#commands#skip(1) | return | endif

    "write search pattern if not navigating and no search set
    if s:X() && !a:nav && @/=='' | let s:v.motion = '' | call s:Search.rewrite(1) | endif

    call s:Search.validate()

    let r = s:G.is_region_at_pos('.')
    if empty(r)  | let r = s:G.select_region(s:v.index) | endif
    if !empty(r) | let pos = [r.l, r.a]
    else         | let pos = getpos('.')[1:2] | endif

    if s:navigate(a:nav, 0) | return 0                    "just navigate to previous
    elseif a:skip           | call s:skip() | endif       "skip current match

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
        return vm#commands#find_next(1, 0)
    else
        return vm#commands#find_prev(1, 0)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#invert_direction(...)
    """Invert direction and reselect region."""
    if s:v.auto | return | endif

    for r in s:RS() | let r.dir = !r.dir | endfor

    "invert anchor
    if s:v.direction
        let s:v.direction = 0
        for r in s:RS() | let r.k = r.b | let r.K = r.B | endfor
    else
        let s:v.direction = 1
        for r in s:RS() | let r.k = r.a | let r.K = r.A | endfor
    endif

    if !a:0 | return | endif
    call s:G.update_highlight()
    call s:G.select_region(s:v.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#split_lines()
    call s:G.split_lines()
    if g:VM_autoremove_empty_lines
        call s:G.remove_empty_lines()
    endif
    call s:G.update_and_select_region()
endfun

fun! vm#commands#remove_empty_lines()
    call s:G.remove_empty_lines()
    call s:G.update_and_select_region()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#from_visual(t)
    let mode = visualmode()
    call s:check_extend_default(1)
    let s:v.silence = 1

    if a:t ==# 'subtract' | call vm#visual#subtract(mode)
    elseif a:t ==# 'add'  | call vm#visual#add(mode)
    else                  | call vm#visual#cursors(mode)
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#remove_every_n_regions(count)
  """Remove every n regions, given by [count] (min 2).
  let R = s:R() | let i = 1 | let cnt = a:count < 2 ? 2 : a:count
  for n in range(1, len(R))
      if n % cnt == 0
          call R[n-i].remove()
          let i += 1
      endif
  endfor
  call s:G.update_and_select_region(1, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#mouse_column()
    call s:check_extend_default(0)
    let start = getpos('.')[1:2]
    exe "normal! \<LeftMouse>"
    let end = getpos('.')[1:2]

    let s:v.silence = 1
    if start[0] < end[0]
        call cursor(start[0], start[1])
        while getpos('.')[1] < end[0]
            call vm#commands#add_cursor_down(0, 1)
        endwhile
        if getpos('.')[1] > end[0]
            call vm#commands#skip(1)
        endif
    else
        call cursor(start[0], start[1])
        while getpos('.')[1] > end[0]
            call vm#commands#add_cursor_up(0, 1)
        endwhile
        if getpos('.')[1] < end[0]
            call vm#commands#skip(1)
        endif
    endif
    let s:v.silence = 0
    call s:F.count_msg(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#motion(motion, count, select, this)

    "create cursor if needed
    if !g:VM.is_active      | call s:init(0, 1, 1)     | call s:G.new_cursor()
    elseif s:F.no_regions() || ( a:this && !s:is_r() ) | call s:G.new_cursor() | endif

    "-----------------------------------------------------------------------

    let s:v.motion = a:count>1? a:count.a:motion : a:motion

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
    let s:v.motion = a:motion
    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#merge_to_beol(eol, this)
    if s:F.no_regions() | return                  | endif
    if s:X()            | call s:G.change_mode()  | endif

    let s:v.motion = a:eol? "\<End>" : '^'
    let s:v.merge = 1
    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#find_motion(motion, char, this, ...)
    if s:F.no_regions() | return | endif

    if a:char != ''
        let s:v.motion = a:motion.a:char
    else
        let s:v.motion = a:motion.nr2char(getchar())
    endif

    call s:call_motion(a:this)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#shrink_or_enlarge(shrink, this)
    """Reduce/enlarge selection size by 1."""
    if s:F.no_regions() | return                  | endif
    if !s:X()           | call s:G.change_mode()  | endif

    let dir = s:v.direction

    let s:v.motion = a:shrink? (dir? 'h':'l') : (dir? 'l':'h')
    call s:call_motion(a:this)

    call vm#commands#invert_direction()

    let s:v.motion = a:shrink? (dir? 'l':'h') : (dir? 'h':'l')
    call s:call_motion(a:this)

    if s:v.direction != dir | call vm#commands#invert_direction(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Motion event
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:only_this        = {   -> s:v.only_this || s:v.only_this_always                 }
let s:can_from_back    = {   -> s:X() && s:v.motion == '$' && !s:v.direction          }
let s:always_from_back = {   -> s:X() && index(['^', '0', 'F', 'T'], s:v.motion) >= 0 }
let s:symbol           = {   -> index(['^', '0', '%', '$'],          s:v.motion) >= 0 }
let s:horizontal       = {   -> index(['h', 'l'],                    s:v.motion) >= 0 }
let s:vertical         = {   -> index(['j', 'k'],                    s:v.motion) >= 0 }
let s:simple           = { m -> index(split('hlwebWEB', '\zs'),      m)        >= 0   }

fun! s:call_motion(this)
    if s:F.no_regions() | return | endif
    let s:v.only_this = a:this
    call s:F.Scroll.get()
    let R = s:R()[ s:v.index ]

    call s:before_move()

    for r in s:RS() | call r.move() | endfor

    "update variables, facing direction, highlighting
    call s:after_move(R)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_move()
    call s:G.reset_byte_map(0)
    if !s:X() | let s:v.merge = 1 | endif

    if s:v.direction && s:always_from_back()
        call vm#commands#invert_direction()

    elseif s:can_from_back()
        call vm#commands#invert_direction()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_move(R)
    let s:v.direction = a:R.dir
    let s:v.only_this = 0
    let s:v.restore_scroll = !s:v.insert

    if s:always_from_back() | call vm#commands#invert_direction() | endif

    if s:v.merge
        call s:G.select_region(a:R.index)
        call s:F.Scroll.get(1)
        call s:G.update_and_select_region(a:R.A)
    else
        call s:F.restore_reg()
        call s:G.update_highlight()
        call s:G.select_region(a:R.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cycle regions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:seek_select(i)
    normal! z.
    call s:G.select_region(a:i)
endfun

fun! vm#commands#seek_down()
    if !len(s:R()) | return | endif

    exe "normal! \<C-f>"
    let end = getpos('.')[1]
    for r in s:R()
        if r.l >= end
            call s:seek_select(r.index)
            return
        endif
    endfor
    call s:seek_select(len(s:R()) - 1)
endfun

fun! vm#commands#seek_up()
    if !len(s:R()) | return | endif

    exe "normal! \<C-b>"
    let end = getpos('.')[1]

    for r in reverse(copy(s:R()))
        if r.l <= end
            call s:seek_select(r.index)
            return
        endif
    endfor
    call s:seek_select(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Align
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#align()
    let s:v.restore_index = s:v.index
    let winline = winline()
    call s:V.Edit.align()
    call s:F.Scroll.force(winline)
endfun

fun! vm#commands#align_char(count)
    if s:X() | call s:G.change_mode() | endif

    let s:v.restore_index = s:v.index
    let winline      = winline()
    let n = a:count | let s = n>1? 's' : ''
    echohl Label    | echo 'Align with '.n.' char'.s.' > '   | echohl None

    let C = []
    while n
        let c = nr2char(getchar())
        if c == "\<esc>" | echohl WarningMsg | echon ' ...Aborted' | return
        else             | call add(C, c) | let n -= 1 | echon c
        endif
    endwhile

    let s:v.silence = 1
    let s = 'czp'    "search method: accept at cursor position

    while !empty(C)
        let c = remove(C, 0)

        "remove region if a match isn't found, otherwise it will be aligned
        for r in s:RS()
            call cursor(r.l, r.a)
            if !search(c, s, r.l) | call r.remove() | continue | endif
            call r.update_cursor([r.l, getpos('.')[2]])
        endfor

        "TODO: strip white spaces preceding the shortest columns
        call s:V.Edit.align()
        let s = 'zp'    "change search method: don't accept at cursor position
    endwhile
    let s:v.silence = 0
    call s:F.Scroll.force(winline)
    call s:F.count_msg(0)
    return
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#align_regex()
    if s:X() | call s:G.change_mode() | endif
    let s:v.restore_index = s:v.index
    let winline      = winline()

    echohl Label | let rx = input('Align with regex > ')   | echohl None
    if empty(rx) | echohl WarningMsg | echon ' ...Aborted' | return  | endif

    set nohlsearch
    for r in s:RS()
        call cursor(r.l, r.a)
        if !search(rx, 'czp', r.l) | call r.remove() | continue | endif
        call r.update_cursor([r.l, getpos('.')[2]])
    endfor
    call s:V.Edit.align()
    call s:F.Scroll.force(winline)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#commands#undo()
    call s:G.remove_highlight()
    echom b:VM_backup == b:VM_Selection
    let b:VM_Selection = copy(b:VM_backup)
    call s:G.update_highlight()
    call s:G.select_region(s:v.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

