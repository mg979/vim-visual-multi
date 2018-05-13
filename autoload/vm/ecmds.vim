""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#ecmds#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R         = { -> s:V.Regions              }
    let s:X         = { -> g:VM.extend_mode         }
    let s:size      = { -> line2byte(line('$') + 1) }

    return s:Edit
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
            let eol = r.b == col([r.L, '$'])

            call r.bytes([change, change])
            call self.extra_spaces(r, 0)
            call cursor(r.l, r.a)
            normal! m[
            if eol
                call cursor(r.L+1, 1)
            else
                call cursor(r.L, r.b+1)
            endif
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
        call s:V.Insert.start(0)
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

        let s:v.W = s:store_widths() | let s:v.new_text = []

        for i in range(len(s:v.W))
            let r = ''
            while len(r) < s:v.W[i] | let r .= char | endwhile
            let s:v.W[i] -= 1
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
    let s:v.W = s:store_widths(s:v.new_text)
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
    if s:X() | call s:G.change_mode(1) | endif

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

        "for commands like D, C, d$, dd... ensure there is only one region per line
        if (M == 'd$' || M == 'dd') | call s:G.one_region_per_line() | endif

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

        "for Y, y$, yy, ensure there is only one region per line
        if (M == 'y$' || M == 'yy') | call s:G.one_region_per_line() | endif

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

        "for c$, cc, ensure there is only one region per line
        if (M == 'c$' || M == 'cc') | call s:G.one_region_per_line() | endif

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
" Special commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.surround() dict
    if !s:X() | exe "normal siw" | endif

    let s:v.W = s:store_widths()
    let c = nr2char(getchar())

    "not possible
    if c == '<' || c == '>' | call s:F.msg('Not possible. Use visual command (zv) instead. ', 1)
        return | endif

    nunmap <buffer> S

    call self.run_visual('S'.c, 1)
    if index(['[', '{', '('], c) >= 0
        call map(s:v.W, 'v:val + 3')
    else
        call map(s:v.W, 'v:val + 1')
    endif
    call self.post_process(1, 0)

    nmap <silent> <nowait> <buffer> S <Plug>(VM-Run-Surround)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.del_key() dict
    "if !s:min(1) | return | endif

    call self.before_macro(0)
    call self._process(0, 'del')
    call s:G.merge_cursors()
    call self.after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.select_op(cmd) dict

    if g:VM.oldupdate | let &updatetime = 10 | endif

    call self.before_macro(1)

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
    call self.after_macro(0)

    if empty(s:v.search) | let @/ = ''                      | endif
    if g:VM.oldupdate    | let &updatetime = g:VM.oldupdate | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.transpose() dict
    if !s:min(2)                           | return         | endif
    let rlines = s:G.lines_with_regions(0) | let inline = 1 | let n = 0
    let klines = sort(keys(rlines), 'n')

    "check if there is the same nr of regions in each line
    if len(klines) == 1 | let inline = 0
    else
        for l in klines
            let nr = len(rlines[l])

            if     nr == 1 | let inline = 0 | break     "line with 1 region
            elseif !n      | let n = nr                 "set required n regions x line
            elseif nr != n | let inline = 0 | break     "different number of regions
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
    for l in klines
        let t = remove(g:VM.registers[s:v.def_reg], rlines[l][-1])
        call insert(g:VM.registers[s:v.def_reg], t, rlines[l][0])
    endfor
    call self.delete(1, "_", 0)
    call self.paste(1, 1, 1)
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
    let X = s:X() | if !X | call s:G.change_mode(1) | endif

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

    "if started in cursor mode, return to it
    if !X && a:app | exe "normal o" | call s:G.change_mode(1)
    elseif !X      | call s:G.change_mode(1)
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

