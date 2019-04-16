""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit commands #2 (special commands)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#ecmds2#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs
    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:R    = { -> s:V.Regions }
    let s:X    = { -> g:Vm.extend_mode }
    let s:size = { -> line2byte(line('$')) }
else
    let s:R    = function('vm#v74#regions')
    let s:X    = function('vm#v74#extend_mode')
    let s:size = function('vm#v74#size')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Duplicate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.duplicate() abort
    if !s:min(1) | return | endif

    call self.yank(0, 1, 1)
    call s:G.change_mode()
    call self.paste(1, 1, 1, '"')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.change(X, count, reg) abort
    if !len(s:R()) | return | endif
    if !s:v.direction | call vm#commands#invert_direction() | endif
    if a:X
        "delete existing region contents and leave the cursors
        call self.delete(1, a:reg != s:v.def_reg? a:reg : "_", 1, 0)
        call s:V.Insert.start()
    else
        call vm#cursors#operation('c', a:count, a:reg)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Non-live edit mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.apply_change() abort
    call s:V.Insert.auto_end()
    let self.skip_index = s:v.index
    call self.process('normal! .')
    "reset index to skip
    let self.skip_index = -1
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.surround() abort
    if !len(s:R()) | return | endif
    if !s:X() | call vm#operators#select(1, 1, 'iw') | endif

    let s:v.W = self.store_widths()
    let c = nr2char(getchar())

    "not possible
    if c == '<' || c == '>'
        return s:F.msg('Not possible. Use visual command (zv) instead. ', 1)
    endif

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

fun! s:Edit.rotate() abort
    """Non-inline transposition.
    if !s:min(2) | return | endif

    call self.yank(0, 1, 1)

    let t = remove(g:Vm.registers[s:v.def_reg], 0)
    call add(g:Vm.registers[s:v.def_reg], t)
    call self.paste(1, 0, 1, '"')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.transpose() abort
    if !s:min(2) | return | endif
    let rlines = s:G.lines_with_regions(0)
    let klines = sort(keys(rlines), 'n')

    "check if there is the same nr of regions in each line
    let inline = len(klines) > 1
    if inline
        let n = 0
        for l in klines
            let nr = len(rlines[l])

            if     nr == 1 | let inline = 0 | break     "line with 1 region
            elseif !n      | let n = nr                 "set required n regions x line
            elseif nr != n | let inline = 0 | break     "different number of regions
            endif
        endfor
    endif

    "non-inline transposition
    if !inline
        return self.rotate()
    endif

    call self.yank(0, 1, 1)

    "inline transpositions
    for l in klines
        let t = remove(g:Vm.registers[s:v.def_reg], rlines[l][-1])
        call insert(g:Vm.registers[s:v.def_reg], t, rlines[l][0])
    endfor
    call self.delete(1, "_", 0, 0)
    call self.paste(1, 0, 1, '"')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.align() abort
    if s:v.multiline
        return s:F.msg('Not possible, multiline is enabled.') | endif
    call s:G.cursor_mode()

    call self.run_normal('D', {'store': '§'})
    let s:v.silence = 1
    let max = max(map(copy(s:R()), 'virtcol([v:val.l, v:val.a])'))
    let reg = g:Vm.registers['§']
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

fun! s:Edit.shift(dir) abort
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

fun! s:Edit._numbers(start, step, sep, app) abort
    let start = str2nr(a:start)
    let step = str2nr(a:step)

    let text = []
    for n in range(len(s:R()))
      if a:app
          let t = a:sep . string(start + step * n)
      else
          let t = string(start + step * n) . a:sep
      endif
      call add(text, t)
    endfor

    if s:X()
        call self.fill_register('"', map(copy(s:R()),
              \ a:app ? '(v:val.txt).text[v:key]' : 'text[v:key].(v:val.txt)'), 0)
        normal p
    else
        call self.fill_register('"', text, 0)
        if a:app | normal p
        else     | normal P
        endif
    endif
endfun

fun! s:Edit.numbers(start, app) abort
    if !len(s:R()) | return | endif
    let X = s:X() | if !X | call s:G.change_mode() | endif

    " fill the command line with [count]/default_step
    let x = input('Expression > ', a:start . '/1/')

    if empty(x) | return s:F.msg('Canceled', 1) | endif

    "first char must be a digit or a negative sign
    if match(x, '^\d') < 0 && match(x, '^\-') < 0
        return s:F.msg('Invalid expression', 1)
    endif

    "evaluate terms of the expression
    "/ is the separator, it must be escaped \/ to be used
    let x = split(x, '/', 1)
    let i = 0
    while i < len(x)-1
        if x[i][-1:-1] == '\'
            let x[i] = x[i][:-2].'/'.remove(x, i+1)
        else
            let i += 1
        endif
    endwhile
    call filter(x, '!empty(v:val)')
    let n = len(x)

    " true for a number, not for a separator
    let l:Num = { x -> match(x, '^\d') >= 0 || match(x, '^\-\d') >= 0 }

    "------------------------------------------- start  step   separ.   append?
    if     n == 1        | call self._numbers (  x[0],   1,     '',     a:app  )

    elseif n == 2

        if l:Num(x[1])   | call self._numbers (  x[0],   x[1],  '',     a:app  )
        else             | call self._numbers (  x[0],   1,     x[1],   a:app  ) | endif

    elseif n == 3        | call self._numbers (  x[0],   x[1],  x[2],   a:app  ) | endif

    "if started in cursor mode, return to it
    if !X && a:app | exe "normal o" | call s:G.change_mode()
    elseif !X      | call s:G.change_mode()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:min(n)
    return s:X() && len(s:R()) >= a:n
endfun

