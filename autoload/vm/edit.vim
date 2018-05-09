""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {'skip_index': -1}

fun! vm#edit#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R         = {      -> s:V.Regions                       }
    let s:X         = {      -> g:VM.extend_mode                  }
    let s:size      = {      -> line2byte(line('$') + 1)          }
    let s:Byte      = { pos  -> s:F.pos2byte(pos)                 }
    let s:Pos       = { byte -> s:F.byte2pos(byte)                }
    let s:Is_Region = {      -> !empty(s:G.is_region_at_pos('.')) }

    let s:v.use_register = s:v.def_reg
    let s:v.new_text     = ''
    let s:W              = []
    let s:v.storepos     = []
    let s:v.insert_marks = {}
    let s:v.extra_spaces = []
    let s:change         = 0
    let s:can_multiline  = 0

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit._process(cmd, ...) dict
    let size = s:size()    | let s:change = 0 | let cmd = a:cmd  | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    "cursors on empty lines still give problems, remove them
    let fix = (a:0 && a:1=='cr')? [] : map(copy(s:R()), '[len(getline(v:val.l)), v:val.id]')
    for r in fix
        if !r[0]
            call s:F.region_with_id(r[1]).remove()
        endif
    endfor

    for r in s:R()
        if !s:v.auto && r.index == self.skip_index | continue | endif

        "execute command, but also take special cases into account
        if a:0 && s:special(cmd, r, a:000)
        else
            call r.bytes([s:change, s:change])
            call cursor(r.l, r.a)
            exe cmd
        endif

        "update changed size
        let s:change = s:size() - size
        if !has('nvim')
            doautocmd CursorMoved
        endif
    endfor

    "reset index to skip
    let self.skip_index = -1
endfun

fun! s:Edit.process_visual(cmd) dict
    let size = s:size()                 | let change = 0
    let s:v.storepos = getpos('.')[1:2] | let s:v.eco = 1

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
        if !s:X()      | call s:G.change_mode(1) |  endif
        for r in s:R()
            call r.bytes([a:1, a:1 + s:W[r.index]])
        endfor
    endif

    "remove extra spaces that may have been added
    call self.extra_spaces(0, 1)

    "clear highlight now to prevent weirdinesses, then update regions
    call clearmatches()    | call s:G.eco_off()

    "byte map must be reset after all editing has been done, and before final update
    call s:G.reset_byte_map(0)

    "update, restore position and clear var
    let pos = empty(s:v.storepos)? '.' : s:v.storepos
    call s:G.update_and_select_region(pos) | let s:v.storepos = []
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Delete
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.delete(X, register, count) dict
    """Delete the selected text and change to cursor mode.
    """Remember the lines that have been added an extra space, for later removal
    if !s:v.direction                     | call vm#commands#invert_direction() | endif
    let ix = s:G.select_region_at_pos('.').index

    if a:X
        let size = s:size() | let change = 0 | let s:v.deleted_text = []
        for r in s:R()
            call r.bytes([change, change])
            call self.extra_spaces(r, 0)
            call cursor(r.l, r.a)
            normal! m[
            call cursor(r.L, r.b>1? r.b+1 : 1)
            normal! m]

            if a:register != "_"
                let s:v.use_register = a:register
                call self.yank(1, 1, 1)
            endif
            call add(s:v.deleted_text, r.txt)
            exe "normal! `[d`]"

            "update changed size
            let change = s:size() - size
        endfor

        call s:G.change_mode(1)
        call s:G.select_region(ix)

        if a:register != "_" | call self.post_process(0)
        else                 | call s:F.restore_reg()     | endif

    elseif a:count
        "ask for motion
        call self.get_motion('d', a:count)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Duplicate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.duplicate() dict
    if !s:X() | return | endif

    call self.yank(0, 1, 1)
    call s:G.change_mode(1)
    call self.paste(1, 1, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.change(X, count) dict
    if !s:v.direction | call vm#commands#invert_direction() | endif
    if a:X
        "delete existing region contents and leave the cursors
        call self.delete(1, "_", 1)
        call s:V.Insert.start('c')
    else
        call self.get_motion('c', a:count)
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

        for i in range(len(s:W))
            let r = ''
            while len(r) < s:W[i] | let r .= char | endwhile
            let s:W[i] -= 1
            call add(s:v.new_text, r)
        endfor

        call self.delete(1, "_", 1)
        call self.block_paste(1)
        call self.post_process(1, 0)
    else
        call s:F.msg('Replace char... ', 1)
        let char = nr2char(getchar())
        if char ==? "\<esc>" | call s:F.msg('Canceled.', 1) | return | endif
        call self.run_normal('r'.char, 0, '', 0)
        call s:F.count_msg(1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Paste
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.paste(before, regions, reselect, ...) dict
    let reg = a:0? a:1 : v:register | let X = s:X()

    if X | call self.delete(1, "_", 1) | endif

    if !a:regions || !has_key(g:VM.registers, reg) || empty(g:VM.registers[reg])
        let s:v.new_text = s:default_text(a:regions)
    else
        let s:v.new_text = s:fill_text(g:VM.registers[reg])
    endif

    if s:v.restart_insert
        call self.insert_paste()
    else
        call self.block_paste(a:before)
    endif
    let s:W = s:store_widths(s:v.new_text)
    call self.post_process((X? 1 : a:reselect), !a:before)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.insert_paste() dict
    let size = s:size() | let change = 0 | let text = copy(s:v.new_text) | let s:v.eco = 1

    for r in s:R()
        if !empty(text)
            call r.bytes([change, change])
            call cursor(r.l, r.a)
            let s = remove(text, 0)
            call s:F.set_reg(s)

            let before = r.a!=col([r.L, '$'])-1? 1 : 0

            if before | normal! P
            else      | normal! p
            endif

            if !before
                call r.update_cursor([r.l, col([r.l, '$'])])
                call setline(r.l, getline(r.l).' ')
                call r.bytes([1,1])
            else
                let s = len(s)
                call r.bytes([s, s])
            endif

            let change = s:size() - size
        else | break | endif
    endfor
    call s:F.restore_reg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.block_paste(before) dict
    let size = s:size() | let change = 0 | let text = copy(s:v.new_text) | let s:v.eco = 1

    for r in s:R()
        if !empty(text)
            call r.bytes([change, change])
            call cursor(r.l, r.a)
            let s = remove(text, 0)
            call s:F.set_reg(s)

            if a:before | normal! P
            else        | normal! p
            endif

            "update changed size
            let change = s:size() - size
        else | break | endif
    endfor
    call s:F.restore_reg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Yank
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.yank(hard, def_reg, silent, ...) dict
    if !s:X()         | call self.get_motion('y', v:count)      | return | endif
    if !s:min(1)      | call s:F.msg('No regions selected.', 0) | return | endif

    let register = (s:v.use_register != s:v.def_reg)? s:v.use_register :
                \  a:def_reg?                         s:v.def_reg : v:register

    let text = []  | let maxw = 0

    for r in s:R()
        if len(r.txt) > maxw | let maxw = len(r.txt) | endif
        call add(text, r.txt)
    endfor

    "write custom and vim registers
    if register != "_"
        let g:VM.registers[register] = text
        let type = s:v.multiline? 'V' : ( len(s:R())>1? 'b'.maxw : 'v' )
        call setreg(register, join(text, "\n"), type)
    endif

    "restore default register if a different register was provided
    if register !=# s:v.def_reg | call s:F.restore_reg() | endif

    "reset temp register
    let s:v.use_register = s:v.def_reg

    "overwrite the old saved register if yanked using default register
    if a:hard && register ==# s:v.def_reg
        let s:v.oldreg = [s:v.def_reg, join(text, "\n"), type]
    elseif a:hard
        call setreg(register, join(text, "\n"), type) | endif

    if !a:silent
        call s:F.msg('Yanked the content of '.len(s:R()).' regions.', 1) | endif
    if a:0 | call s:G.change_mode(1) | endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Get motion
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:forw = { c -> index(['f', 't'], c) >= 0                }
let s:back = { c -> index(['F', 'T', '0', '^'], c) >= 0      }
let s:ia   = { c -> index(['i', 'a'], c) >= 0                }
let s:all  = { c -> index(split('webWEB$^0', '\zs'), c) >= 0 }
let s:find = { c -> index(split('fFtT', '\zs'), c) >= 0      }

fun! s:Edit.get_motion(op, n) dict

    let reg = v:register | let hl1 = 'WarningMsg' | let hl2 = 'Label'

    let s =       a:op==#'d'? [['Delete ', hl1], ['([n] d/w/e/b/$...) ?  ',   hl2]] :
                \ a:op==#'c'? [['Change ', hl1], ['([n] s/w/e/b/$...) ?  ',   hl2]] :
                \ a:op==#'y'? [['Yank   ', hl1], ['([n] y/w/e/b/$...) ?  ',   hl2]] : 'Aborted.'

    call s:F.msg(s, 1)

    "starting string
    let M = (a:n>1? a:n : '').( reg == s:v.def_reg? '' : '"'.reg ).a:op

    "preceding count
    let n = a:n>1? a:n : 1

    echon M
    while 1
        let c = nr2char(getchar())
        if str2nr(c) > 0                     | echon c | let M .= c
        elseif s:find(c)                     | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c | break

        elseif s:ia(c)                       | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c | break

        elseif a:op ==# 'c' && c==#'s'       | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c | break

        elseif s:all(c)                      | echon c | let M .= c | break
        elseif a:op ==# 'd' && c==#'d'       | echon c | let M .= c | break
        elseif a:op ==# 'c' && c==#'c'       | echon c | let M .= c | break
        elseif a:op ==# 'y' && c==#'y'       | echon c | let M .= c | break

        else | echon ' ...Aborted'           | return  | endif
    endwhile

    if a:op ==# 'd'
        let s:v.deleted_text = [] | let s:v.merge = 1
        nunmap <buffer> d
        call s:F.external_funcs(0, 0)
        call self._process("normal ".M, 'd')
        nmap <silent> <nowait> <buffer> d <Plug>(VM-Edit-Delete)
        call self.post_process(0)
        call s:F.external_funcs(0, 1)
        if reg != "_"
            let maxw = max(map(copy(s:v.deleted_text), 'len(v:val)'))
            let type = s:v.multiline? 'V' : 'b'.maxw
            call setreg(reg, join(s:v.deleted_text, "\n"), type)
            let g:VM.registers[reg] = s:v.deleted_text
        endif

    elseif a:op ==# 'y'
        call s:G.change_mode(1)

        "what comes after 'y'; check for 'yy'
        let S = substitute(M, '^\d*y\(.*\)$', '\1', '') | let m = S[0] | let Y = m==#'y'

        let x = match(S, '\d') >= 0? substitute(S, '\D', '', 'g') : 0
        if x | let S = substitute(S, x, '', '') | endif

        "final count
        let N = x? n*x : n>1? n : 1 | let N = N>1? N : ''

        "NOTE: yy doesn't accept count.
        if Y
            call vm#commands#motion('0', 1, 0, 0)
            call vm#commands#motion('$', 1, 0, 0)
            let s:v.multiline = 1
            call vm#commands#motion('l', 1, 0, 0)
            call feedkeys('y')
        else
            call feedkeys("s".N.S."\"".reg."y") | endif

    elseif a:op ==# 'c'
        "cs surround
        if M[:1] ==# 'cs' | call self.run_normal(M, 1, 1, 0) | return | endif

        "what comes after 'c'; check for 'cc'
        let S = substitute(M, '^\d*c\(.*\)$', '\1', '') | let m = S[0] | let C = m==#'c'

        "'cc' motion -> ^d$
        if !C | let S = substitute(S, '^c', 'd', '')     | endif

        "backwards and i/a motions use select operator, forward motions use delete
        if s:back(m) || s:ia(m) | call feedkeys(n."s".S."c")
        elseif C                | call feedkeys('^d$a')
        else                    | call feedkeys(n."\"_d".S."i") | endif
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_normal(cmd, recursive, count, maps) dict

    "-----------------------------------------------------------------------

    if a:cmd == -1
        let cmd = input('Normal command? ')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif empty(a:cmd)
        call s:F.msg('No last command.', 1) | return

    else | let cmd = a:cmd | endif

    "-----------------------------------------------------------------------

    let c = a:count>1? a:count : ''
    let s:cmd = a:recursive? ("normal ".c.cmd) : ("normal! ".c.cmd)
    if s:X() | call s:G.change_mode(1) | endif

    call s:before_macro(a:maps)

    if a:cmd ==? 'x' | call s:bs_del(a:cmd)
    else             | call self._process(s:cmd) | endif

    let g:VM.last_normal = [cmd, a:recursive]
    call s:after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_visual(cmd, maps, ...) dict

    "-----------------------------------------------------------------------

    if !a:0 && a:cmd == -1
        let cmd = input('Visual command? ')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif empty(a:cmd)
        call s:F.msg('Command not found.', 1) | return

    elseif !a:0
        let cmd = a:cmd | endif

    "-----------------------------------------------------------------------

    call s:before_macro(a:maps)
    call self.process_visual(cmd)

    let g:VM.last_visual = cmd
    call s:after_macro(0)
    if s:X() | call s:G.change_mode(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex(...) dict

    "-----------------------------------------------------------------------

    if !a:0
        let cmd = input('Ex command? ', '', 'command')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif !empty(a:1)
        let cmd = a:1
    else
        call s:F.msg('Command not found.', 1) | return | endif

    "-----------------------------------------------------------------------

    if has_key(g:VM_commands_aliases, cmd)
        let cmd = g:VM_commands_aliases[cmd]
    endif

    let g:VM.last_ex = cmd
    if s:X() | call s:G.change_mode(1) | endif

    call s:before_macro(1)
    call self._process(cmd)
    call s:after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro(replace) dict
    if s:count(v:count) | return | endif

    call s:F.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:F.msg('Macro aborted.', 0)
        return | endif

    let s:cmd = "@".reg
    call s:before_macro(1)

    if s:X() | call s:G.change_mode(1) | endif

    call self.process()
    call s:after_macro(0)
    "redraw!
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert numbers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit._numbers(start, stop, step, sep, app) dict
    let a = str2nr(a:start) | let b = str2nr(a:stop) | let s = str2nr(a:step) | let x = a:sep | let text = []

    "reverse order if start>stop
    if b >= a
        let r = range(b-a+1)
        if a:app  | let text = map(r , '( x.string(a + v:key * s) )')
        else      | let text = map(r , '( string(a + v:key * s).x )') | endif
    else
        let r = range(a-b+1)
        if a:app  | let text = map(r , '( x.string(a - v:key * s) )')
        else      | let text = map(r , '( string(a - v:key * s).x )') | endif
    endif

    "ensure there is enough text
    if len(text) < len(s:R()) | let text += map(range(len(s:R()) - len(text)), '""') | endif

    if s:X() && a:app
        let g:VM.registers['"'] = map(copy(s:R()), '(v:val.txt).text[v:key]')
        call self.paste(1, 1, 1)
    elseif s:X()
        let g:VM.registers['"'] = map(copy(s:R()), 'text[v:key].(v:val.txt)')
        call self.paste(1, 1, 1)
    else
        let g:VM.registers['"'] = text
        call self.paste(1, 1, 0)
    endif
endfun

fun! s:Edit.numbers(start, app) dict
    let text = []

    let l:Invalid = { -> s:F.msg('Invalid expression', 1) }
    let l:N =       { x -> match(x, '\D')<0? 1 : 0 }

    let S = a:start
    let x = S.'/'.( S-1+len(s:R()) ).'/1/'
    let x = input('Expression > ', x)

    "first char must be a digit
    if match(x, '^\d') < 0 | call l:Invalid() | return | endif

    "match an expression separator
    let char = match(x, '\D')
    if char < 0  | let x = [x]
    else         | let x = split(x, x[char]) | endif

    let n = len(x)

    "invalid expressions
    if ( n == 3 && !l:N(x[1]) ) ||
      \( n == 4 && (!l:N(x[1]) || !l:N(x[2])) ) ||
      \( n > 4 )
        call l:Invalid() | return | endif

    "                                         start    stop     step   separ.   append?
    if     n == 1        | call self._numbers(S,     S-1+x[0],   1,     '',     a:app)

    elseif n == 2

        if l:N(x[1])     | call self._numbers(S,     S-1+x[0],   x[1],  '',     a:app)
        else             | call self._numbers(S,     S-1+x[0],   1,     x[1],   a:app) | endif

    elseif n == 3

        if l:N(x[2])     | call self._numbers(x[0],  x[1],       x[2],  '',     a:app)
        else             | call self._numbers(S,     S-1+x[0],   x[1],  x[2],   a:app) | endif

    elseif n == 4        | call self._numbers(x[0],  x[1],       x[2],  x[3],   a:app) | endif

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.surround() dict
    if !s:X() | exe "normal siw" | endif

    let s:W = s:store_widths()
    let c = nr2char(getchar())

    "not possible
    if c == '<' || c == '>' | call s:F.msg('Not possible. Use visual command (zv) instead. ', 1)
        return | endif

    nunmap <buffer> S

    call self.run_visual('S'.c, 0)
    if index(['[', '{', '('], c) >= 0
        call map(s:W, 'v:val + 3')
    else
        call map(s:W, 'v:val + 1')
    endif
    call self.post_process(1, 0)

    nmap <silent> <nowait> <buffer> S <Plug>(VM-Run-Surround)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.del_key() dict
    "if !s:min(1) | return | endif

    call s:before_macro(0)
    call self._process(0, 'del')
    call s:G.merge_cursors()
    call s:after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.select_op(cmd) dict

    if !has('nvim')        | let &updatetime = 10   | endif

    call s:before_macro(1)

    "if not using permanent mappings, this will be unmapped but it's needed
    nmap <silent> gs         <Plug>(VM-Select-Operator)

    for r in s:R()
        call cursor(r.l, r.a)
        call r.remove()
        let g:VM.selecting = 1
        exe "normal ".a:cmd
        if !has('nvim')
            doautocmd CursorMoved
        endif
    endfor
    call s:after_macro(0)

    if empty(s:v.search) | let @/ = ''                      | endif
    if !has('nvim')      | let &updatetime = g:VM.oldupdate | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.transpose() dict
    if !s:min(2)                           | return         | endif
    let rlines = s:G.lines_with_regions(0) | let inline = 1 | let l = 0

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

fun! s:Edit.align() dict
    if s:v.multiline | return                  | endif
    if s:X()         | call s:G.change_mode(1) | endif

    normal D
    let max = max(map(copy(s:R()), 'v:val.a'))
    let reg = g:VM.registers[s:v.def_reg]
    for r in s:R()
        let s = ''
        while len(s) < max-r.a | let s .= ' ' | endwhile
        let L = getline(r.l)
        call setline(r.l, L[:r.a-1].s.L[r.a:].reg[r.index])
        call r.update_cursor([r.l, r.a+len(s)])
    endfor
    call s:G.update_and_select_region()
    call vm#commands#motion('l', 1, 0, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.shift(dir) dict
    if !s:min(1) | return | endif

    call self.yank(0, 1, 1)
    if a:dir
        call self.paste(0, 1, 1)
    else
        call self.delete(1, "_", 0)
        call vm#commands#motion('h', 1, 0, 0)
        call self.paste(1, 1, 1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.extra_spaces(r, remove) dict

    if a:remove
        "remove the extra space only if it comes after r.b, and it's just before \n
        for i in s:v.extra_spaces
            let r = s:R()[i]
            call cursor(r.L, r.b<col([r.L, '$'])-1? r.b+1 : r.b)
            normal! x
        endfor
        let s:v.extra_spaces = [] | return | endif

    "add space if empty line(>) or eol(=)
    let L = getline(a:r.L)
    if a:r.b >= len(L)
        call setline(a:r.L, L.' ')
        call add(s:v.extra_spaces, a:r.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_macro(maps)
    let s:v.silence = 1 | let s:v.auto = 1 | let s:v.eco = 1
    let s:old_multiline = s:v.multiline    | let s:v.multiline = s:can_multiline
    let s:can_multiline = 0

    "disable mappings and run custom functions
    let s:maps = a:maps
    nunmap <buffer> <Space>
    nunmap <buffer> <esc>
    call s:F.external_funcs(a:maps, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_macro(reselect, ...)
    let s:v.multiline = s:old_multiline
    if a:reselect
        call s:V.Edit.post_process(1, a:1)
    else
        call s:V.Edit.post_process(0)
    endif

    "reenable mappings and run custom functions
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Space>    <Plug>(VM-Toggle-Mappings)
    call s:F.external_funcs(s:maps, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:count(c)
    "forbid count
    if a:c > 1
        if !g:VM.is_active | return 1 | endif
        call s:F.msg('Count not allowed.', 0)
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:min(nr)
    "Check for a minimum of available regions
    return ( s:X() && len(s:R()) >= a:nr )
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:fill_text(list)
    "Ensure there are enough lines for all regions
    let L = a:list
    let i = len(s:R()) - len(a:list)

    if !has_key(s:v, 'deleted_text') || empty(s:v.deleted_text)
        while i>0
            call add(L, '')
            let i -= 1
        endwhile
    else
        while i>0
            call add(L, s:v.deleted_text[-i])
            let i -= 1
        endwhile
    endif
    return L
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:default_text(regions)
    "fill the content to past with the default register
    let text = []
    let block = char2nr(getregtype(s:v.def_reg)[0]) == 22

    if block && a:regions
        "default register is of block type, assign a line to each region
        let width = getregtype(s:v.def_reg)[1:]
        let reg = split(getreg(s:v.def_reg), "\n")
        for t in range(len(reg))
            while len(reg[t]) < width | let reg[t] .= ' ' | endwhile
        endfor

        call s:fill_text(reg)

        for n in range(len(s:R()))
            call add(text, reg[n])
        endfor
    else
        for n in range(len(s:R())) | call add(text, getreg(s:v.def_reg)) | endfor
    endif
    return text
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs_del(cmd)
    if s:V.Insert.is_active | call s:V.Edit._process(s:cmd, 'ix')
    else                    | call s:V.Edit._process(s:cmd)         | endif

    if a:cmd ==# 'X'
        for r in s:R() | call r.bytes([-1,-1]) | endfor
        call s:G.merge_cursors()
    elseif a:cmd ==# 'x'
        let eol = s:V.Insert.is_active? s:V.Live.append : 0
        for r in s:R() | if r.a == col([r.L, '$'])-eol | call r.bytes([-1,-1]) | endif  | endfor
        call s:G.merge_cursors()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:special(cmd, r, args)
    "Some commands need special adjustments while being processed.

    if a:args[0] ==#'del'
        "<del> key deletes \n if executed at eol
        call a:r.bytes([s:change, s:change])
        call cursor(a:r.l, a:r.a)
        if a:r.a == col([a:r.l, '$']) - 1 | normal! Jx
        else                              | normal! x
        endif
        return 1

    elseif a:args[0] ==# 'ix'
        "insert BS/C-D is quite messy when at eol
        let eol = a:r.a == col([a:r.l, '$']) - 1
        let app = s:V.Live.mode == 'a'

        "no adjustments
        if !eol && !app | return | endif

        let s = app? 1 : 0
        call a:r.bytes([s:change+s, s:change+s])

        call cursor(a:r.l, a:r.a)

        if a:cmd ==# 'normal! x'
            normal! x
            if s | call a:r.bytes([-1, -1]) | endif
        else
            if eol
                call s:V.Edit.extra_spaces(a:r, 0)
                normal! x
            else
                normal! X
            endif
            if s | call a:r.bytes([-1, -1]) | endif
        endif
        return 1

    elseif a:args[0] ==# 'cr'
        let r = a:r           | let r.l += r.index       | let eol = col([r.l, '$'])
        let ind = indent(r.l) | let end = (r.a == eol-1) | let ok = ind && !end

        call cursor(r.l, r.a)

        let s = ok? '' : '_'
        call append(line('.'), s)

        if ok               | exe a:cmd    | normal! d$jp==
        elseif end && ind   | normal! j==
        endif

        "remember which lines have been marked
        let s:v.insert_marks[r.l+1] = indent(r.l+1)
        return 1

    elseif a:args[0] ==# 'd'
        "store deleted text so that it can all be put in the register
        call a:r.bytes([s:change, s:change])
        call cursor(a:r.l, a:r.a)
        exe a:cmd
        if s:v.use_register != "_"
            call add(s:v.deleted_text, getreg(s:v.use_register))
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
    if use_list | call s:fill_text(list) | endif

    for r in s:R()
        "if using list, w must be len[i]-1, but always >= 0, set it to 0 if empty
        if use_list | let w = len(list[r.index]) | endif
        call add(W, use_text? text :
                \   use_list? (w? w-1 : 0) :
                \   r.w
                \) | endfor
    return W
endfun
