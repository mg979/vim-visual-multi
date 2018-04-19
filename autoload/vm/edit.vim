""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {'skip_index': -1}

fun! vm#edit#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars

    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:R       = {      -> s:V.Regions              }
    let s:X       = {      -> g:VM.extend_mode         }
    let s:size    = {      -> line2byte(line('$') + 1) }
    let s:Byte    = { pos  -> s:Funcs.pos2byte(pos)    }
    let s:Pos     = { byte -> s:Funcs.byte2pos(byte)   }

    let s:v.registers   = {}
    let s:extra_spaces  = []

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process(...) dict
    "Optional args:
    "arg1: prefix for normal command
    "arg2: 0 for recursive command

    let size = s:size() | let change = 0

    let cmd = a:0? (a:1."normal".(a:2? "! ":" ").s:cmd)
            \    : ("normal! ".s:cmd)

    for r in s:R()
        if r.index == self.skip_index | continue | endif
        let test = r.shift(change, change)
        call cursor(r.l, r.a)
        exe cmd

        "update changed size
        let change = s:size() - size
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.post_process(reselect, shift) dict
    if a:reselect
        if !s:X()      | call vm#commands#change_mode(1) |  endif
        for r in s:R()
            if a:shift
                call r._b(s:W[r.index])
                call r.shift(a:shift, a:shift)
            else
                call r._b(s:W[r.index])
            endif
        endfor
    endif

    "remove extra spaces that may have been added
    for line in s:extra_spaces
        let l = getline(line)
        if l[-1:] ==# ' ' | call setline(line, l[:-2]) | endif
    endfor

    call s:Global.update_regions()
    call s:Global.select_region_at_pos('.')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Delete
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.delete(X, keep, count) dict
    """Delete the selected text and change to cursor mode.
    """Remember the lines that have been added an extra space, for later removal

    if a:X
        let size = s:size() | let change = 0 | let s:extra_spaces = []
        for r in s:R()
            call r.shift(change, change)
            call cursor(r.l, r.a)
            let L = getline(r.L)
            if s:v.auto || r.b == len(L)
                call setline(r.L, L.' ')
                call add(s:extra_spaces, r.L)
            endif
            if a:keep
                call self.yank(1, 1, 1, 1)
            endif
            let reg = a:keep? '' : "\"_"
            exe "normal! ".reg."d".r.w."l"

            "update changed size
            let change = s:size() - size
        endfor
        call vm#commands#change_mode(1)

    else
        "ask for motion
        call self.get_motion('d', a:count)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.change(X, count) dict
    if a:X
        "delete existing region contents and leave the cursors
        call self.delete(1, 0, 1)
        call s:V.Insert.start('c')
    else
        call self.get_motion('c', a:count)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Non-live edit mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.apply_change() dict
    call vm#augroup_end()
    let s:cmd = '.'
    let self.skip_index = s:v.index
    call self.process()
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Get motion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:delchars = { c -> index(['d', 'w', 'e', 'b','W', 'E', 'B', '$', '^', '0'], c) >= 0 }
let s:chgchars = { c -> index(['c', 'w', 'e', 'b','W', 'E', 'B', '$', '^', '0', 's'], c) >= 0 }
let s:rplchars = { c -> index(['r', 'w', 'e', 'b','W', 'E', 'B', '$', '^', '0'], c) >= 0 }

fun! s:Edit.get_motion(op, n) dict

    let hl1 = 'WarningMsg' | let hl2 = 'Label'
    let s =       a:op==#'d'? [['Delete ', hl1], ['([n] d/w/e/b/$...) ?  '  , hl2]] :
                \ a:op==#'c'? [['Change ', hl1], ['([n] c/s/w/e/b/$...) ?  ', hl2]] :
                \ a:op==#'r'? [['Replace', hl1], ['([n] r/w/e/b/$...) ?  '  , hl2]] : 'Aborted.'

    call s:Funcs.msg(s, 1)

    let m = (a:n>1? a:n : '').a:op
    let M = (a:n>1? a:n : '').( a:op==#'c'? 'd' : a:op )
    echon m

    while 1
        let c = nr2char(getchar())
        if str2nr(c) > 0                     | echon c | let M .= c | let m .= c
        elseif a:op ==# 'd' && s:delchars(c) | echon c | let M .= c | let m .= c | break
        elseif a:op ==# 'c' && s:chgchars(c) | echon c | let M .= c | let m .= c | break
        elseif a:op ==# 'r' && s:rplchars(c) | echon c | let M .= c | let m .= c | break

        else | let M = '' | break | endif
    endwhile

    if empty(M) | echon ' ...Aborted'

    elseif a:op == 'd'
        let s:cmd = M
        call self.process()
    elseif a:op == 'c'
        let s:cmd = M
        call self.process()
        call s:V.Insert.start('c')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.paste(before, block) dict
    let reg = v:register | let X = s:X()

    "force paste before in extend mode, as it works in visual mode
    let before = X? 1 : a:before
    if X | call self.delete(1, 0, 1) | endif

    if !a:block || !has_key(s:v.registers, reg)
        let text = s:default_text()
    else
        let text = s:v.registers[reg]
    endif

    call self.block_paste(before, text)
    let s:W = s:store_widths(text)
    call self.post_process(X, !before)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.block_paste(before, text) dict
    let size = s:size() | let change = 0 | let text = copy(a:text)

    for r in s:R()
        if !empty(text)
            call r.shift(change, change)
            call cursor(r.l, r.a)
            let s = remove(text, 0)
            call s:Funcs.set_reg(s)

            if a:before | normal! P
            else        | normal! p
            endif

            "update changed size
            let change = s:size() - size
        else | break | endif
    endfor
    call s:Funcs.restore_reg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.yank(hard, def_reg, silent, ...) dict
    if !s:X()    | call s:Funcs.msg('Not in cursor mode.', 0)  | return | endif
    if !s:min(1) | call s:Funcs.msg('No regions selected.', 0) | return | endif

    let register = a:def_reg? s:v.def_reg : v:register
    let text = []  | let maxw = 0

    for r in s:R()
        if len(r.txt) > maxw | let maxw = len(r.txt) | endif
        call add(text, r.txt)
    endfor

    let s:v.registers[register] = text
    call setreg(register, join(text, "\n"), "b".maxw)

    "overwrite the old saved register
    if a:hard
        let s:v.oldreg = [s:v.def_reg, join(text, "\n"), "b".maxw] | endif
    if !a:silent
        call s:Funcs.msg('Yanked the content of '.len(s:R()).' regions.', 1) | endif
    if !a:0 | call vm#commands#change_mode(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex() dict
    if s:count(v:count) | return | endif

    let cmd = input('Ex command? ')
    if cmd == "\<esc>"
        call s:Funcs.msg('Command aborted.', 0)
        return | endif

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_macro()
    let s:v.silence = 1 | let s:v.auto = 1
    let s:old_multiline = g:VM.multiline
    let g:VM.multiline
    call vm#maps#end()
    if g:VM.motions_enabled | call vm#maps#motions(0, 1) | return 1 | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_macro(motions)
    let s:v.silence = 0 | let s:v.auto = 0
    let g:VM.multiline = s:old_multiline

    call vm#maps#start()
    if a:motions | call vm#maps#motions(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro(replace) dict
    if s:count(v:count) | return | endif

    call s:Funcs.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:Funcs.msg('Macro aborted.', 0)
        return | endif

    let s:cmd = "@".reg
    let motions = s:before_macro()

    if a:replace | call self.delete(0, 0, 1)
    elseif s:X() | call vm#commands#change_mode(1) | endif

    call self.process()
    call self.post_process(0, 0)
    call s:after_macro(motions)
    redraw!
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.surround(type) dict
    if s:X()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.transpose() dict
    if !s:min(2)                                 | return         | endif
    let rlines = s:Global.lines_with_regions(0)  | let inline = 1 | let l = 0

    "check if there is the same nr of regions in each line
    if len(keys(rlines)) == 1 | let inline = 0
    else
        for rl in keys(rlines)
            let nr = len(rlines[rl])

            if nr == 1     | let inline = 0 | break
            elseif !l      | let l = nr
            elseif nr != l | let inline = 0 | break
            endif
        endfor
    endif

    call self.yank(0, 1, 1)

    "non-inline transposition
    if !inline
        let t = remove(s:v.registers[s:v.def_reg], 0)
        call add(s:v.registers[s:v.def_reg], t)
        call self.paste(1, 1)
        return | endif

    "inline transpositions
    for rl in keys(rlines)
        let t = remove(s:v.registers[s:v.def_reg], rlines[rl][-1])
        call insert(s:v.registers[s:v.def_reg], t, rlines[rl][0])
        call self.paste(1, 1)
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.shift(dir) dict
    if !s:min(1) | return | endif

    call self.yank(0, 1, 1)
    if a:dir
        call self.paste(0, 1)
    else
        call self.delete(0, 0, 1)
        call vm#commands#motion('h', 0)
        call self.paste(1, 1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:count(c)
    "forbid count
    if a:c > 1
        if !g:VM.is_active | return 1 | endif
        call s:Funcs.msg('Count not allowed.', 0)
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:min(nr)
    "check for a minimum of available regions
    return ( s:X() && len(s:R()) >= a:nr )
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:default_text()
    "fill the content to past with the default register
    let text = []
    let block = char2nr(getregtype(s:v.def_reg)[0]) == 22

    if block
        "default register is of block type, assign a line to each region
        let width = getregtype(s:v.def_reg)[1:]
        let reg = split(getreg(s:v.def_reg), "\n")
        for t in range(len(reg))
            while len(reg[t]) < width | let reg[t] .= ' ' | endwhile
        endfor

        "ensure there are enough lines for all regions
        while len(reg) < len(s:R()) | call add(reg, '') | endwhile

        for n in range(len(s:R()))
            call add(text, reg[n])
        endfor
    else
        for n in range(len(s:R())) | call add(text, getreg(s:v.def_reg)) | endfor
    endif
    return text
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:store_widths(...)
    "store regions widths in a list
    let W = [] | let x = s:X()
    let use_text = 0
    let use_list = 0

    if a:0
        if type(a:1) == v:t_string | let text = len(a:1)-1 | let use_text = 1
        else                       | let list = a:1        | let use_list = 1 | endif
    endif

    "mismatching blocks must be corrected
    if use_list | while len(list) < len(s:R()) | call add(list, 0) | endwhile | endif

    for r in s:R()
        call add(W, use_text? text : use_list? len(list[r.index])-1 : r.w) | endfor
    return W
endfun
