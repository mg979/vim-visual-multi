"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Store registers, initialize script vars and temporary buffer mappings.
"Some functions are registered in s:Funcs, that is returned to the global
"script, and then included in the global variable, so that they can be
"accessed from anywhere.

fun! vm#funcs#init() abort
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    return s:Funcs
endfun

let s:R = { -> s:V.Regions }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.pos2byte(...) abort
    "pos can be a mark, a list [line, col], or the offset itself

    if type(a:1) == 0                   "an offset
        return a:1

    elseif type(a:1) == v:t_list        "a list [line, col]
        return (line2byte(a:1[0]) + a:1[1] - 1)

    else                                "a mark like '[
        let pos = getpos(a:1)[1:2]
        return (line2byte(pos[0]) + min([pos[1], col([pos[0], '$'])]) - 1)
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.curs2byte() abort
    " Return the offset of the current cursor position.
    let pos = getcurpos()[1:2]
    return (line2byte(pos[0]) + pos[1] - 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.byte2pos(byte) abort
    " Return the (line, col) position of a byte offset.

    let line = byte2line(a:byte)
    let col  = a:byte - line2byte(line) + 1
    return [line, col]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.Cursor(A) abort
    let ln = byte2line(a:A)
    let cl = a:A - line2byte(ln) + 1
    call cursor(ln, cl)
    return [ln, cl]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.get_vertcol() abort
    " getcurpos() is unreliable at $ (https://github.com/vim/vim/issues/4464)
    " if > eol, reposition the cursor, so that curswant is reset
    let curswant = getcurpos()[4]
    if curswant > col('$')
        call cursor(getpos('.')[1:2])
        let curswant = getcurpos()[4]
    endif
    return curswant
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.no_regions() abort
    if !len(s:R())
        let s:v.index = -1
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.char_under_cursor() abort
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
endfun

fun! s:Funcs.char_at_pos(l, c) abort
    return matchstr(getline(a:l), '\%' . a:c . 'c.')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.default_reg() abort
    return "\""
endfun

fun! s:Funcs.size() abort
    return line2byte(line('$') + 1) - 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.get_reg(...) abort
    let r = a:0? a:1 : s:v.def_reg
    return [r, getreg(r), getregtype(r)]
endfun

fun! s:Funcs.get_regs_1_9() abort
    let regs = []
    for r in range(1, 9)
        call add(regs, [r, getreg(r), getregtype(r)])
    endfor
    return regs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.set_reg(text) abort
    let r = s:v.def_reg
    call setreg(r, a:text, 'v')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.restore_reg() abort
    let r = s:v.oldreg
    call setreg(r[0], r[1], r[2])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.restore_regs() abort
    "default reg
    call self.restore_reg()

    "regs 0-9
    for r in s:v.oldregs_1_9 | call setreg(r[0], r[1], r[2]) | endfor

    "search reg
    let s = s:v.oldsearch
    call setreg("/", s[0], s[1])
    let g:Vm.registers['"'] = []
    let g:Vm.registers['-'] = []
    silent! unlet g:Vm.registers['§']
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.region_with_id(id) abort
    for r in s:R()
        if r.id == a:id | return r | endif
    endfor
    return {}
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.should_quit() abort
    " VM should quit if there are no regions, or 1 left if option is set.
    let nR = len(s:V.Global.active_regions())
    return !nR || nR == 1 &&
                \ g:VM_exit_on_1_cursor_left && !s:v.single_region
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.syntax(pos) abort
    " Find syntax element at position.
    if type(a:pos) == type([])    "list [line, col]
        let line = a:pos[0]
        let col = a:pos[1]
    else                          "position ('.', ...)
        let line = line(a:pos)
        let col = col(a:pos)
    endif
    return synIDattr(synID(line, col, 1),"name")
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.get_expr(x) abort
    let l:Has = { x, c -> match(x, '%'.c ) >= 0 }
    let l:Sub = { x, a, b -> substitute(x, a, b, 'g') }
    let N = len(s:R()) | let x = a:x

    if l:Has(x, 't')   | let x = l:Sub(x, '%t', 'r.txt')                    | endif
    if l:Has(x, 'i')   | let x = l:Sub(x, '%i', 'r.index')                  | endif
    if l:Has(x, 'n')   | let x = l:Sub(x, '%n', N)                          | endif
    if l:Has(x, 'syn') | let x = l:Sub(x, '%syn', 's:F.syntax([r.l, r.a])') | endif
    return x
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.sync_minlines() abort
    " Get the current sync minlines setting for the buffer.
    let sync = split(execute('syn sync'), '\n')
    let sync = len(sync) > 1 ? sync[1] : sync[0]
    return matchstr(sync, '\d\+')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.set_statusline(auto) abort
    let setting = get(g:, 'VM_set_statusline', 2)
    if ( setting - a:auto ) >= 1
        silent! noautocmd setlocal statusline=%!vm#themes#statusline()
    endif
endfun

fun! s:Funcs.special_statusline(msg) abort
    let s:v.statusline_mode = a:msg
    call self.set_statusline(1)
    redraw
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:add_char(c)
  let s:chars .= nr2char(a:c)
  echon nr2char(a:c)
endfun

fun! s:ask_char()
  let c = getchar()
  if c == 27                        " escape
    return
  elseif s:char_escape              " escaped character
  elseif c == 92                    " backslash
    call s:add_char(c)
    let s:char_escape = 1
    return s:ask_char()
  endif
  call s:add_char(c)
  let s:chars2go -= 1
  let s:char_escape = 0
  return 1
endfun

fun! s:Funcs.search_chars(n) abort
  " Ask for [count] or 1 regex-interpretable character(s).
  let [ s:chars, s:chars2go, s:char_escape ] = [ '', a:n, 0 ]
  let ns = a:n > 1 ? 's' : ''
  let pre = printf('Find regex [%d char'.ns.'] ', a:n)
  echohl Label  | echo pre
  echohl None   | echon '> '
  while s:chars2go
    if !s:ask_char() | return '' | endif
  endwhile
  return s:chars
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keep viewport position
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs.Scroll = {}

fun! s:Funcs.Scroll.can_see_eof() abort
    return ( winheight(0) - winline() + line('.') ) >= line('$')
endfun

fun! s:Funcs.Scroll.can_see_bof() abort
    return line('.') <= winline()
endfun

fun! s:Funcs.Scroll.get(...) abort
    " Store winline().
    if a:0 | let s:v.restore_scroll = 1 | endif
    let s:v.winline = winline()
endfun

fun! s:Funcs.Scroll.force(line) abort
    " Restore arbitrary winline().
    let s:v.restore_scroll = 1
    let s:v.winline = a:line
    call self.restore()
endfun

fun! s:Funcs.Scroll.restore(...) abort
    " Restore viewport position when done.
    if s:v.restore_scroll | let s:v.restore_scroll = 0 | else | return | endif

    " restoring should be avoided if it's possible to see EOF or BOF
    if ( self.can_see_bof() || self.can_see_eof() ) | return | endif

    let lines = winline() - s:v.winline
    if lines > 0
        silent! exe "normal! ".lines."\<C-e>"
    elseif lines < 0
        let lines = lines * -1
        silent! exe "normal! ".lines."\<C-y>"
    endif
    if a:0 | let s:v.winline = winline() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Messages
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(text) abort
    if s:v.eco | return | endif

    echo "\r"
    redraw
    if type(a:text) == type("")
        exe "echohl" g:Vm.hi.message
        echon a:text
        echohl None | return
    endif

    for txt in a:text
        exe "echohl ".txt[1]
        echon txt[0]
        echohl None
    endfor
endfun

fun! s:Funcs.infoline() abort
    if s:v.index < 0
        return self.msg("No regions.")
    endif
    let r = s:R()[s:v.index]

    let hl = 'Directory' | let H1 = 'Type' | let H2 = 'WarningMsg'

    if g:VM_debug | let ix = ' '.r.index.' '.r.a.' '.r.b | else | let ix = '' | endif
    let ix = ['  ['.s:v['index'].ix.']  ', hl]

    let i1 = [' '  , hl] | let m1 = g:Vm.mappings_enabled? ["M\+", H1] : ["m\-", H2]
    let i2 = [' / ', hl] | let m2 = s:v.multiline?         ["V\+", H1] : ["v\-", H2]
    let i3 = [' / ', hl] | let m3 = s:v.single_region?     ["S\+", H1] : ["s\-", H2]

    let s = len(s:R())>1 ? 's.' : '.'
    let t = g:Vm.extend_mode? ' region' : ' cursor'
    let R = [len(s:R()).t.s, hl]
    let s1 = ['   Current patterns: ', hl]
    let s2 = [self.pad(string(s:v.search), &columns - 1), H1]
    let msg = [i1, m1, i2, m2, i3, m3, ix, R, s1, s2]
    call self.msg(msg)
endfun

fun! s:Funcs.exit(msg) abort
    call self.msg(a:msg)
    call vm#reset(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle options
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.toggle_option(option) abort
    if s:v.eco | return | endif

    let s = "s:v.".a:option
    exe "let" s "= !".s

    if a:option == 'multiline'
        if !s:v.multiline
            call vm#commands#split_lines()
        endif

    elseif a:option == 'single_region'
        let a = ['Single region mode: ', 'None']
        if !get(g:, 'VM_set_statusline', 2)
            if s:v.single_region
                call self.msg([a, ['activated', 'Label']])
            else
                call self.msg([a, ['deactivated', 'WarningMsg']])
            endif
        endif

    elseif a:option == 'whole_word'
        if empty(s:v.search) | return self.msg('No search patterns.') | endif
        let s = s:v.search[0]
        let wm = 'WarningMsg' | let L = 'Label'

        if s:v.whole_word
            if s[:1] != '\<' | let s:v.search[0] = '\<'.s.'\>' | endif
            let pats = self.pad(string(s:v.search), &columns - 1)
            call self.msg([
                        \['Search ->'               , wm], ['    whole word  ', L],
                        \['  ->  Current patterns: ', wm], [pats              , L]])
        else
            if s[:1] == '\<' | let s:v.search[0] = s[2:-3] | endif
            let pats = self.pad(string(s:v.search), &columns - 1)
            call self.msg([
                        \['Search ->'              , wm], ['  not whole word ', L],
                        \[' ->  Current patterns: ', wm], [pats               , L]])
        endif
        call s:V.Search.join()
        return
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Utility functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.pad(t, n, ...)
    if len(a:t) > a:n
        return a:t[:(a:n-3)]."… "
    elseif a:0
        let spaces = a:n - len(a:t)
        let spaces = printf("%".spaces."s", "")
        return a:t.spaces
    else
        return a:t
    endif
endfunction

fun! s:Funcs.repeat_char(c) abort
    let s = ''
    for i in range(&columns - 20)
        let s .= a:c
    endfor
    return s
endfun

fun! s:Funcs.redraw() abort
    if !has('gui_running') | redraw!
    endif
endfun

fun! s:Funcs.regions_contents() abort
    echohl WarningMsg | echo "Index\tID\tA\tB\tw\tl / L\t\ta / b\t\t"
                \ "--- Pattern ---\t"
                \ "--- Regions contents ---" | echohl None
    for r in s:R() | call self.region_txt(r) | endfor
endfun

fun! s:Funcs.region_txt(r) abort
    let r = a:r
    let index = printf("%-4d", r.index)
    let line = substitute(r.txt, '\V\n', '^M', 'g')
    if len(line) > 80 | let line = line[:80] . '…' | endif

    echohl Directory
    echo index."\t".r.id."\t".r.A."\t".r.B."\t".r.w."\t"
                \.self.pad(r.l." / ".r.L, 14, 1)
                \.self.pad("\t".r.a." / ".r.b, 14, 1)."\t"

    echohl Type       | echon self.pad(r.pat, 18, 1)
    echohl None       | echon "\t".line
    echohl None
endfun

fun! s:Funcs.not_VM() abort
    return !exists('b:visual_multi')
endfun

" vim: et ts=4 sw=4 sts=4 tw=85 :
