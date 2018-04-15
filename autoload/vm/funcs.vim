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
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Search  = s:V.Search
    let s:Edit    = s:V.Edit
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
    "pos can be a string, a list or a (line, col) couple

    if a:0 > 1                          "a (line, col) couple
        return line2byte(a:1) + a:2

    elseif type(a:1) == v:t_string      "a string (like '.')
        let pos = getpos(a:1)[1:2]
        return line2byte(pos[0]) + pos[1]

    else                                "a list [line, col]
        return line2byte(a:1[0]) + a:1[1]
    endif
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

fun! s:Funcs.restore_regs() dict
    let r = s:v.oldreg | let s = s:v.oldsearch
    call setreg(r[0], r[1], r[2])
    call setreg("/", s[0], s[1])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(text, ...) dict
    if !s:v.silence || a:0
        exe "echohl" g:VM_Message_hl
        echo a:text
        echohl None
    endif
endfun

fun! s:Funcs.count_msg(force) dict
    if a:force         | let s:v.silence = 0
    elseif s:v.silence | return
    endif

    let i = g:VM.motions_enabled? '[M+ ' : '[m- '
    let i .= s:v['index'].']  '
    let s = len(s:Regions)>1 ? 's.' : '.'
    let t = g:VM.extend_mode? ' region' : ' cursor'
    call self.msg(i.len(s:Regions).t.s.'   Current patterns: '.string(s:v.search))
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Utility functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
    echohl WarningMsg | echo "Index\tA\tB\tw\tl / L\t\ta / b\t\t"
                \ "--- Pattern ---\t"
                \ "--- Regions contents ---" | echohl None
    for r in s:Regions | call self.region_txt(r) | endfor
endfun

fun! s:Funcs.region_txt(r) dict
    let r = a:r
    let index = printf("%-4d", r.index)
    let line = substitute(r.txt, '\V\n', '^M', 'g')
    if len(line) > 80 | let line = line[:80] . '…' | endif

    echohl Directory  | echo  index."\t".r.A."\t".r.B."\t".r.w."\t"
                \.self.pad(r.l." / ".r.L, 14).self.pad("\t".r.a." / ".r.b, 14)."\t"

    echohl SpecialKey | echon self.pad(r.pat, 18)
    echohl None       | echon "\t".line
    echohl None
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

