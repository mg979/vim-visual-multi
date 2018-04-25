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

    let s:R         = {      -> s:V.Regions                            }
    let s:X         = {      -> g:VM.extend_mode                       }
    let s:size      = {      -> line2byte(line('$') + 1)               }
    let s:Byte      = { pos  -> s:Funcs.pos2byte(pos)                  }
    let s:Pos       = { byte -> s:Funcs.byte2pos(byte)                 }
    let s:Is_Region = {      -> !empty(s:Global.is_region_at_pos('.')) }

    let s:v.use_register = s:v.def_reg
    let s:v.new_text     = ''
    let s:extra_spaces   = []
    let s:W              = []

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit._process(cmd, ...)
    let size = s:size() | let change = 0 | let cmd = a:cmd

    for r in s:R()
        if !s:v.auto && r.index == self.skip_index | continue | endif

        call r.bytes([change, change])
        "cursors on empty lines still give problems, remove them
        if !r.a && !len(getline(r.l)) | call r.remove() | continue | endif
        call cursor(r.l, r.a)

        "execute command, but also take special cases into account
        if a:0 && s:special(cmd, r, a:000) | else | exe cmd | endif

        "update changed size
        let change = s:size() - size
        doautocmd CursorMoved
    endfor

    "reset index to skip
    let self.skip_index = -1
endfun

fun! s:Edit.process_visual(cmd)
    let size = s:size() | let change = 0

    for r in s:R()
        call r.bytes([change, change])
        call cursor(r.L, r.b) | normal! m`
        call cursor(r.l, r.a) | normal! v``
        exe "normal ".a:cmd

        "update changed size
        let change = s:size() - size
    endfor
endfun

fun! s:Edit.process(...) dict
    "arg1: prefix for normal command
    "arg2: 0 for recursive command

    let cmd = a:0? (a:1."normal".(a:2? "! ":" ").s:cmd)
            \    : ("normal! ".s:cmd)

    call self._process(cmd)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.post_process(reselect, ...) dict
    if a:reselect
        if !s:X()      | call s:Global.change_mode(1) |  endif
        for r in s:R()
            call r.bytes([a:1, a:1 + s:W[r.index]])
        endfor
    endif

    "remove extra spaces that may have been added
    for line in s:extra_spaces
        let l = getline(line)
        if l[-1:] ==# ' ' | call setline(line, l[:-2]) | endif
    endfor

    let s:v.auto = 0
    let s:extra_spaces = []

    "clear highlight now to prevent weirdinesses, then update regions
    call clearmatches()
    call s:Global.update_regions()
    call s:Global.select_region(-1)
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
            call r.bytes([change, change])
            call cursor(r.l, r.a)
            let L = getline(r.L)
            if s:v.auto || r.b == len(L)
                call setline(r.L, L.' ')
                call add(s:extra_spaces, r.L)
            endif
            if a:keep && v:register != "_"
                let s:v.use_register = v:register
                call self.yank(1, 1, 1)
            endif
            let reg = a:keep? '' : "\"_"
            exe "normal! ".reg."d".r.w."l"

            "update changed size
            let change = s:size() - size
        endfor
        call s:Global.change_mode(1)
        if a:keep | call self.post_process(0) | endif

    elseif a:count
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
" Insert
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.insert(type) dict

    if a:type ==# 'I'
        call vm#commands#merge_to_beol(0, 0)
        call s:V.Insert.start('i')

    elseif a:type ==# 'A'
        call vm#commands#merge_to_beol(1, 0)
        call s:V.Insert.start('a')

    elseif a:type ==# 'o'
        call vm#commands#merge_to_beol(1, 0)
        call s:V.Insert.start('o')

    elseif a:type ==# 'O'
        call vm#commands#merge_to_beol(0, 0)
        call s:V.Insert.start('O')

    elseif a:type ==# 'a'
        if s:X()
            if s:v.direction | call vm#commands#invert_direction() | endif
            call s:Global.change_mode(1)
        endif
        call s:V.Insert.start('a')

    else
        if s:X()
            if !s:v.direction | call vm#commands#invert_direction() | endif
            call s:Global.change_mode(1)
        endif
        call s:V.Insert.start('i')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Non-live edit mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.apply_change() dict
    call s:V.Insert.auto_end()
    let s:cmd = '.'
    let self.skip_index = s:v.index
    call self.process()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Replace
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.replace() dict
    if s:X()
        let char = nr2char(getchar())
        if char ==? "\<esc>" | return | endif

        let s:W = s:store_widths() | let s:v.new_text = []

        for i in s:W
            let r = ''
            while len(r) < i | let r .= char | endwhile
            call add(s:v.new_text, r)
        endfor

        call self.delete(1, 0, 1)
        call self.block_paste(1)
        for r in s:R() | call r.bytes([0,-1]) | endfor
        call self.post_process(1, 0)
    else
        call s:Funcs.msg('Replace char... ', 1)
        let char = nr2char(getchar())
        if char ==? "\<esc>" | call s:Funcs.msg('Canceled.', 1) | return | endif
        call self.run_normal('r'.char, 0)
        call s:Funcs.count_msg(1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Paste
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.paste(before, block, reselect) dict
    let reg = v:register | let X = s:X()

    if X | call self.delete(1, 0, 1) | endif

    if !a:block || !has_key(g:VM.registers, reg)
        let s:v.new_text = s:default_text()
    else
        let s:v.new_text = g:VM.registers[reg]
    endif

    call self.block_paste(a:before)
    let s:W = s:store_widths(s:v.new_text)
    call self.post_process((X? 1 : a:reselect), !a:before)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.block_paste(before) dict
    let size = s:size() | let change = 0 | let text = copy(s:v.new_text)

    for r in s:R()
        if !empty(text)
            call r.bytes([change, change])
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
" Yank
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.yank(hard, def_reg, silent, ...) dict
    if !s:X()         | call self.get_motion('y', v:count)          | return | endif
    if !s:min(1)      | call s:Funcs.msg('No regions selected.', 0) | return | endif

    let register = (s:v.use_register != s:v.def_reg)? s:v.use_register :
                \  a:def_reg?                         s:v.def_reg : v:register

    let text = []  | let maxw = 0

    for r in s:R()
        if len(r.txt) > maxw | let maxw = len(r.txt) | endif
        call add(text, r.txt)
    endfor

    "write custom and vim registers
    let g:VM.registers[register] = text
    let type = s:v.multiline? 'V' : 'b'.maxw
    call setreg(register, join(text, "\n"), type)

    "restore default register if a different register was provided
    if register !=# s:v.def_reg | call s:Funcs.restore_reg() | endif

    "reset temp register
    let s:v.use_register = s:v.def_reg

    "overwrite the old saved register if yanked using default register
    if a:hard && register ==# s:v.def_reg
        let s:v.oldreg = [s:v.def_reg, join(text, "\n"), type]
    elseif a:hard
        call setreg(register, join(text, "\n"), type) | endif

    if !a:silent
        call s:Funcs.msg('Yanked the content of '.len(s:R()).' regions.', 1) | endif
    if a:0 | call s:Global.change_mode(1) | endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Get motion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:delchars = { c -> index(split('dwlebWEB$^0', '\zs'), c) >= 0 }
let s:chgchars = { c -> index(split('cwlebWEB$^0s', '\zs'), c) >= 0 }
let s:ynkchars = { c -> index(split('welbWEB$^0', '\zs'), c) >= 0 }

fun! s:Edit.get_motion(op, n) dict

    let reg = v:register
    let hl1 = 'WarningMsg' | let hl2 = 'Label'

    let s =       a:op==#'d'? [['Delete ', hl1], ['([n] d/w/e/b/$...) ?  ',   hl2]] :
                \ a:op==#'c'? [['Change ', hl1], ['([n] c/s/w/e/b/$...) ?  ', hl2]] :
                \ a:op==#'y'? [['Yank   ', hl1], ['([n] w/e/b/$...) ?  ',   hl2]] : 'Aborted.'

    call s:Funcs.msg(s, 1)

    if index(['y', 'd'], a:op) >= 0
        let m = (a:n>1? a:n : '').( reg == s:v.def_reg? '' : '"'.reg ).a:op
        let M = (a:n>1? a:n : '').( reg == s:v.def_reg? '' : '"'.reg ).a:op
        let s:v.use_register = reg
    else
        let m = (a:n>1? a:n : '').a:op
        let M = (a:n>1? a:n : '').( a:op==#'c'? 'd' : a:op )
        endif
    echon m

    while 1
        let c = nr2char(getchar())
        if str2nr(c) > 0                     | echon c | let M .= c | let m .= c
        elseif a:op ==# 'd' && s:delchars(c) | echon c | let M .= c | let m .= c | break
        elseif a:op ==# 'c' && s:chgchars(c) | echon c | let M .= c | let m .= c | break
        elseif a:op ==# 'y' && s:ynkchars(c) | echon c | let M .= c | let m .= c | break

        else | let M = '' | break | endif
    endwhile

    if empty(M) | echon ' ...Aborted'

    elseif a:op ==# 'd'
        let s:deleted_text = []
        call self._process("normal! ".M, 'd')
        call self.post_process(0)
        let maxw = max(map(copy(s:deleted_text), 'len(v:val)'))
        let type = s:v.multiline? 'V' : 'b'.maxw
        call setreg(reg, join(s:deleted_text, "\n"), type)
        let g:VM.registers[reg] = s:deleted_text

    elseif a:op ==# 'y'
        call s:Global.change_mode(1)
        let cmd = substitute(M, "^.*y", "", "")."\"".reg.'y'
        call feedkeys(cmd)

    elseif a:op ==# 'c'
        let s:cmd = M
        call self.process()
        call s:V.Insert.start('c')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_normal(cmd, recursive, ...) dict

    "-----------------------------------------------------------------------

    if !a:0 && a:cmd == -1
        let cmd = input('Normal command? ')
        if empty(cmd) | call s:Funcs.msg('Command aborted.', 1) | return | endif

    elseif empty(a:cmd)
        call s:Funcs.msg('Command not found.', 1) | return

    elseif !a:0
        let cmd = a:cmd

    elseif !empty(a:1)
        call self.run_normal(a:1[0], a:1[1]) | return | endif

    "-----------------------------------------------------------------------

    let s:cmd = a:recursive? ("normal ".cmd) : ("normal! ".cmd)
    if s:X() | call s:Global.change_mode(1) | endif

    call s:before_macro()
    call self._process(s:cmd)

    if a:cmd ==# 'X'
        for r in s:R() | call r.bytes([-1,-1]) | endfor
    elseif a:cmd ==# 'x'
        for r in s:R() | if r.a == col([r.L, '$']) | call r.bytes([-1,-1]) | endif  | endfor
    endif


    let g:VM.last_normal = [cmd, a:recursive]
    call self.post_process(0)
    call s:after_macro()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_visual(cmd, ...) dict

    "-----------------------------------------------------------------------

    if !a:0 && a:cmd == -1
        let cmd = input('Visual command? ')
        if empty(cmd) | call s:Funcs.msg('Command aborted.', 1) | return | endif

    elseif empty(a:cmd)
        call s:Funcs.msg('Command not found.', 1) | return

    elseif !a:0
        let cmd = a:cmd

    elseif !empty(a:1)
        call self.run_visual(a:1[0], a:1[1]) | return | endif

    "-----------------------------------------------------------------------

    call s:before_macro()
    call self.process_visual(cmd)

    let g:VM.last_visual = cmd
    call self.post_process(0)
    call s:after_macro()
    if s:X() | call s:Global.change_mode(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex(...) dict

    "-----------------------------------------------------------------------

    if !a:0
        let cmd = input('Ex command? ', '', 'command')
        if empty(cmd) | call s:Funcs.msg('Command aborted.', 1) | return | endif

    elseif !empty(a:1)
        let cmd = a:1
    else
        call s:Funcs.msg('Command not found.', 1) | return | endif

    "-----------------------------------------------------------------------

    let g:VM.last_ex = cmd
    if s:X() | call s:Global.change_mode(1) | endif

    call s:before_macro()
    call self._process(cmd)
    call self.post_process(0)
    call s:after_macro()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro(replace) dict
    if s:count(v:count) | return | endif

    call s:Funcs.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:Funcs.msg('Macro aborted.', 0)
        return | endif

    let s:cmd = "@".reg
    call s:before_macro()

    if s:X() | call s:Global.change_mode(1) | endif

    call self.process()
    call self.post_process(0)
    call s:after_macro()
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

fun! s:Edit.del_key() dict
    "if !s:min(1) | return | endif

    call s:before_macro()
    call self._process(0, 'del')
    call self.post_process(0)
    call s:after_macro()
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
        let t = remove(g:VM.registers[s:v.def_reg], 0)
        call add(g:VM.registers[s:v.def_reg], t)
        call self.paste(1, 1, 1)
        return | endif

    "inline transpositions
    for rl in keys(rlines)
        let t = remove(g:VM.registers[s:v.def_reg], rlines[rl][-1])
        call insert(g:VM.registers[s:v.def_reg], t, rlines[rl][0])
        call self.paste(1, 1, 1)
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.shift(dir) dict
    if !s:min(1) | return | endif

    call self.yank(0, 1, 1)
    if a:dir
        call self.paste(0, 1, 1)
    else
        call self.delete(1, 0, 0)
        call vm#commands#motion('h', 1, 0, 0)
        call self.paste(1, 1, 1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_macro()
    let s:v.silence = 1 | let s:v.auto = 1
    let s:old_multiline = s:v.multiline
    let s:old_motions = g:VM.motions_enabled
    let s:v.multiline = 1
    call vm#maps#end()
    if g:VM.motions_enabled | call vm#maps#motions(0, 1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_macro()
    let s:v.silence = 0
    let s:v.multiline = s:old_multiline

    call vm#maps#start()
    if s:old_motions | call vm#maps#motions(1) | endif
endfun

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

fun! s:special(cmd, r, args)
    "Some commands need special adjustments while being processed.

    if a:args[0] ==#'del'
        "<del> key deletes \n if executed at eol
        if a:r.a == col([a:r.l, '$']) - 1 | normal! Jx
        else                              | normal! x
        endif
        return 1

    elseif a:args[0] ==# 'd'
        "store deleted text so that it can all be put in the register
        exe a:cmd
        if s:v.use_register != "_"
            call add(s:deleted_text, getreg(s:v.use_register))
        endif
        return 1

    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:store_widths(...)
    "Build a list that holds the widths(integers) of each region
    "It will be used for various purposes (reselection, paste as block...)

    let W = [] | let x = s:X()
    let use_text = 0
    let use_list = 0

    if a:0
        if type(a:1) == v:t_string | let text = len(a:1)-1 | let use_text = 1
        else                       | let list = a:1        | let use_list = 1 | endif
    endif

    "mismatching blocks must be corrected
    if use_list | while len(list) < len(s:R()) | call add(list, '') | endwhile | endif

    for r in s:R()
        "if using list, w must be len[i]-1, but always >= 0, set it to 0 if empty
        if use_list | let w = len(list[r.index]) | endif
        call add(W, use_text? text :
                \   use_list? (w? w-1 : 0) :
                \   r.w
                \) | endfor
    return W
endfun
