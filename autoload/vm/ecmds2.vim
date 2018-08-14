""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit commands #2 (special commands)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#ecmds2#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R       = { -> s:V.Regions                  }
    let s:X       = { -> g:VM.extend_mode             }
    let s:size    = { -> line2byte(line('$') + 1)     }
    let s:min     = { nr -> s:X() && len(s:R()) >= nr }

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Duplicate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.duplicate() dict
    if !s:X() | return | endif

    call self.yank(0, 1, 1)
    call s:G.change_mode()
    call self.paste(1, 1, 1, '"')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.change(X, count, reg) dict
    if !s:v.direction | call vm#commands#invert_direction() | endif
    if a:X
        "delete existing region contents and leave the cursors
        call self.delete(1, a:reg != s:v.def_reg? a:reg : "_", 1, 0)
        call s:V.Insert.start(0)
    else
        call vm#operators#cursors('c', a:count, a:reg)
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
" Special commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.surround() dict
    if !s:X() | call vm#operators#select(1, 1, 'iw') | endif

    let s:v.W = self.store_widths()
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

    nmap <silent> <nowait> <buffer> S <Plug>(VM-Surround)
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
        call self.paste(1, 0, 1, '"')
        return | endif

    "inline transpositions
    for l in klines
        let t = remove(g:VM.registers[s:v.def_reg], rlines[l][-1])
        call insert(g:VM.registers[s:v.def_reg], t, rlines[l][0])
    endfor
    call self.delete(1, "_", 0, 0)
    call self.paste(1, 0, 1, '"')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.align() dict
    if s:v.multiline | return                  | endif
    if s:X()         | call s:G.change_mode()  | endif

    normal D
    let s:v.silence = 1
    let max = max(map(copy(s:R()), 'virtcol([v:val.l, v:val.a])'))
    let reg = g:VM.registers[s:v.def_reg]
    for r in s:R()
        let s = ''
        while len(s) < (max - virtcol([r.l, r.a])) | let s .= ' ' | endwhile
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
        call self.paste(0, 0, 1, '"')
    else
        call self.delete(1, "_", 0, 0)
        call vm#commands#motion('h', 1, 0, 0)
        call self.paste(1, 0, 1, '"')
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
        call self.fill_register('"', map(copy(s:R()), '(v:val.txt).text[v:key]'), 0)
    elseif s:X()
        call self.fill_register('"', map(copy(s:R()), 'text[v:key].(v:val.txt)'), 0)
    else
        call self.fill_register('"', text, 0)
    endif
    normal p
endfun

fun! s:Edit.numbers(start, app) dict
    let X = s:X() | if !X | call s:G.change_mode() | endif

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
      \( n == 4 && (!l:N(x[1])  || !l:N(x[2])) ) ||
      \( n >  4 )
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
    if !X && a:app | exe "normal o" | call s:G.change_mode()
    elseif !X      | call s:G.change_mode()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
