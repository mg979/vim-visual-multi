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
    let s:Global  = s:V.Global
    let s:Search  = s:V.Search
    let s:Edit    = s:V.Edit

    let s:R    = {     -> s:V.Regions           }

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
    "pos can be a string, a list or a (line, col) couple, or the offset itself

    if a:0 > 1                          "a (line, col) couple
        return line2byte(a:1) + a:2

    elseif type(a:1) == v:t_number      "an offset
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
    let lnbyte = line2byte(line)
    let col    = line + ( a:byte - lnbyte )
    return [line, col]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.lastcol(line) dict
    return len(getline(a:line))
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

fun! s:Funcs.get_reg() dict
    let r = s:v.def_reg
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Messages
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(text, force) dict
    if s:v.silence && !a:force | return | endif

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

fun! s:m1()
    let t = g:VM.motions_enabled? "M\+" : "M\-"
    let hl = g:VM.motions_enabled? "Type" : "WarningMsg"
    return [t, hl]
endfun

fun! s:m2()
    let t = !g:VM.multiline? "B\+" : "B\-"
    let hl = !g:VM.multiline? "Type" : "WarningMsg"
    return [t, hl]
endfun

fun! s:m3()
    let t = s:v.only_this_always? "O\+" : "O\-"
    let hl = s:v.only_this_always? "Type" : "WarningMsg"
    return [t, hl]
endfun

fun! s:Funcs.count_msg(force) dict
    if s:v.silence && !a:force | return | endif

    if s:v.index < 0
        call self.msg("No selected regions.", 1)
        return | endif

    let ix = g:VM_debug? " ".s:R()[s:v.index].index : ''
    let hl = 'Directory'
    let i = [' ', hl]
    let m1 = s:m1()
    let i2 = [' / ', hl]
    let m2 = s:m2()
    let i3 = [' / ', hl]
    let m3 = s:m3()
    let i4 = [' ['.s:v['index'].ix.']  ', hl]
    let s = len(s:R())>1 ? 's.' : '.'
    let t = g:VM.extend_mode? ' region' : ' cursor'
    let t1 = [len(s:R()).t.s.'   Current patterns: ', hl]
    let t2 = [string(s:v.search), 'Type']
    call self.msg([i, m1, i2, m2, i3, m3, i4, t1, t2], a:force)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Utility functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.show_registers() dict
    echohl Label | echo " Register\tLine\t--- Register contents ---" | echohl None
    for r in keys(s:v.registers)
        echohl Directory  | echo "\n    ".r
        let l = 1
        for s in s:v.registers[r]
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle options
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.toggle_option(option) dict

    if a:option == 'multiline'
        let g:VM.multiline = !g:VM.multiline
        redraw! | call b:VM_Selection.Funcs.count_msg(0)
        "if !g:VM.multiline | call s:V.Global.split_lines() | endif
        return | endif

    let s = "s:v.".a:option
    exe "let" s "= !".s

    if a:option == 'whole_word'
        redraw!
        let s = s:v.search[0]
        let wm = 'WarningMsg' | let L = 'Label'

        if s:v.whole_word
            if s[:1] != '\<' | let s:v.search[0] = '\<'.s.'\>' | endif
            call s:Funcs.msg([['Search ->', wm], ['    whole word  ', L], ['  ->  Current patterns: ', wm], [string(s:v.search), L]], 0)
        else
            if s[:1] == '\<' | let s:v.search[0] = s[2:-3] | endif
            call s:Funcs.msg([['Search ->', wm], ['  not whole word ', L], [' ->  Current patterns: ', wm], [string(s:v.search), L]], 0)
        endif
        return
    endif

    redraw! | call b:VM_Selection.Funcs.count_msg(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

