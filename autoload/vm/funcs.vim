"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Store registers, initialize script vars and temporary buffer mappings.
"Some functions are registered in s:Funcs, that is returned to the global
"script, and then included in the global variable, so that they can be
"accessed from anywhere.

fun! vm#funcs#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars

    let s:R       = { -> s:V.Regions }

    return s:Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Backup/restore buffer state on buffer change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.pos2byte(...) dict
    "pos can be a string, a list [line, col], or the offset itself

    if type(a:1) == v:t_number          "an offset
        return a:1

    elseif type(a:1) == v:t_string      "a string (like '.')
        let pos = getpos(a:1)[1:2]
        return (line2byte(pos[0]) + pos[1])

    else                                "a list [line, col]
        return (line2byte(a:1[0]) + a:1[1])
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.byte2pos(byte) dict
    """Return the (line, col) position of a byte offset.

    let line   = byte2line(a:byte)
    let col    = a:byte - line2byte(line)
    return [line, col]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.Cursor(A) dict
    let ln = byte2line(a:A) | let cl = a:A - line2byte(ln)
    call cursor(ln, cl)
    return [ln, cl]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.no_regions() dict
    if s:v.index == -1 | call self.msg('No selected regions.', 0) | return 1 | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.char_under_cursor() dict
    return matchstr(getline('.'), '\%' . col('.') . 'c.')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.default_reg() dict
    let clipboard_flags = split(&clipboard, ',')
    if index(clipboard_flags, 'unnamedplus') >= 0
        return "+"
    elseif index(clipboard_flags, 'unnamed') >= 0
        return "*"
    else
        return "\""
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.get_reg(...) dict
    let r = a:0? a:1 : s:v.def_reg
    return [r, getreg(r), getregtype(r)]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:Funcs.set_reg(text) dict
    let r = s:v.def_reg
    call setreg(r, a:text, 'v')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.restore_reg() dict
    let r = s:v.oldreg
    call setreg(r[0], r[1], r[2])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.restore_regs() dict
    let s = s:v.oldsearch
    call self.restore_reg()
    call setreg("/", s[0], s[1])
    let g:VM.registers['"'] = []
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.region_with_id(id) dict
    for r in s:R()
        if r.id == a:id | return r | endif
    endfor
    return {}
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Messages
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(text, force) dict
    if s:v.eco                     | return
    elseif s:v.silence && !a:force | return | endif

    if type(a:text) == v:t_string
        exe "echohl" g:VM_Message_hl
        echon a:text
        echohl None | return | endif

    for txt in a:text
        exe "echohl ".txt[1]
        echon txt[0]
        echohl None
    endfor
endfun

fun! s:Funcs.count_msg(force, ...) dict
    if s:v.eco                     | return
    elseif s:v.silence && !a:force | return
    elseif s:v.index < 0           | call self.msg("No selected regions.", 1) | return | endif
    let r = s:R()[s:v.index]

    let hl = 'Directory' | let H1 = 'Type' | let H2 = 'WarningMsg'

    if g:VM_debug | let ix = ' '.r.index.' '.r.a.' '.r.b | else | let ix = '' | endif
    let ix = ['  ['.s:v['index'].ix.']  ', hl]

    let i1 = [' '  , hl] | let m1 = g:VM.mappings_enabled? ["M\+", H1] : ["m\-", H2]
    let i2 = [' / ', hl] | let m2 = s:v.multiline?         ["V\+", H1] : ["v\-", H2]
    let i3 = [' / ', hl] | let m3 = s:v.block_mode?        ["B\+", H1] : ["b\-", H2]
    let i4 = [' / ', hl] | let m4 = s:v.only_this_always?  ["O\+", H1] : ["o\-", H2]

    let s = len(s:R())>1 ? 's.' : '.'
    let t = g:VM.extend_mode? ' region' : ' cursor'
    let R = [len(s:R()).t.s, hl]
    let s1 = ['   Current patterns: ', hl]
    let s2 = [self.pad(string(s:v.search), 120), H1]
    let msg = [i1, m1, i2, m2, i3, m3, i4, m4, ix, R, s1, s2]
    if a:0 | call insert(msg, a:1, 9) | endif | call self.msg(msg, a:force)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Utility functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.show_registers() dict
    echohl Label | echo " Register\tLine\t--- Register contents ---" | echohl None
    for r in keys(g:VM.registers)
        echohl Directory  | echo "\n    ".r
        let l = 1
        for s in g:VM.registers[r]
            echohl WarningMsg | echo "\t\t".l."\t"
            echohl None  | echon s
            let l += 1
        endfor
    endfor
endfun

function! s:Funcs.pad(t, n)
    if len(a:t) > a:n
        return a:t[:(a:n-1)]."…"
    else
        let spaces = a:n - len(a:t)
        let spaces = printf("%".spaces."s", "")
        return a:t.spaces
    endif
endfunction

fun! s:Funcs.regions_contents() dict
    echohl WarningMsg | echo "Index\tID\tA\tB\tw\tl / L\t\ta / b\t\t"
                \ "--- Pattern ---\t"
                \ "--- Regions contents ---" | echohl None
    for r in s:R() | call self.region_txt(r) | endfor
endfun

fun! s:Funcs.region_txt(r) dict
    let r = a:r
    let index = printf("%-4d", r.index)
    let line = substitute(r.txt, '\V\n', '^M', 'g')
    if len(line) > 80 | let line = line[:80] . '…' | endif

    echohl Directory  | echo  index."\t".r.id."\t".r.A."\t".r.B."\t".r.w."\t"
                \.self.pad(r.l." / ".r.L, 14).self.pad("\t".r.a." / ".r.b, 14)."\t"

    echohl Type       | echon self.pad(r.pat, 18)
    echohl None       | echon "\t".line
    echohl None
endfun

fun! s:Funcs.external_funcs(maps, restore)
    if a:restore
        if exists('*VM_after_auto')       | call VM_after_auto()     | endif
        call s:V.Maps.mappings(1)
        if a:maps
            if exists('*VM_after_macro') | call VM_after_macro()     | endif
        endif
        return
    endif

    if exists('*VM_before_auto')      | call VM_before_auto()        | endif
    if a:maps
        if g:VM.mappings_enabled      | call s:V.Maps.mappings(0, 1) | endif
        if exists('*VM_before_macro') | call VM_before_macro()       | endif
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle options
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.toggle_option(option, ...) dict
    if s:v.eco | return | endif

    let s = "s:v.".a:option
    exe "let" s "= !".s

    if a:option == 'multiline'
        if s:v.multiline
            call s:V.Block.stop()
        else
            call s:V.Global.split_lines()
            call s:V.Global.select_region_at_pos('.')   | endif

    elseif a:option == 'block_mode'
        if s:v.block_mode
            if s:v.multiline
                let s:v.multiline = 0
                call s:V.Global.split_lines()
                call s:V.Global.select_region_at_pos('.')   | endif
            call s:V.Block.start()
        else
            call s:V.Block.stop() | endif

    elseif a:option == 'whole_word'
        if empty(s:v.search) | call self.msg('No search patterns.', 1) | return | endif
        let s = s:v.search[0]
        let wm = 'WarningMsg' | let L = 'Label'

        if s:v.whole_word
            if s[:1] != '\<' | let s:v.search[0] = '\<'.s.'\>' | endif
            let pats = self.pad(string(s:v.search), 120)
            call self.msg([
                        \['Search ->'               , wm], ['    whole word  ', L],
                        \['  ->  Current patterns: ', wm], [pats              , L]], 1)
        else
            if s[:1] == '\<' | let s:v.search[0] = s[2:-3] | endif
            let pats = self.pad(string(s:v.search), 120)
            call self.msg([
                        \['Search ->'              , wm], ['  not whole word ', L],
                        \[' ->  Current patterns: ', wm], [pats               , L]], 1)
        endif
        return
    endif

    if a:0 | redraw! | call self.count_msg(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

