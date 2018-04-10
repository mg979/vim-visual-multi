"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Store registers, initialize script vars and temporary buffer mappings.
"Some functions are registered in s:Funcs, that is returned to the global
"script, and then included in the global variable, so that they can be
"accessed from anywhere.

fun! vm#funcs#init(empty)
    let s:V       = b:VM_Selection
    let s:V.Funcs = s:Funcs

    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global  = s:V.Global
    let s:Search  = vm#search#init()

    call vm#maps#start()

    let s:v.def_reg = s:default_reg()
    let s:v.oldreg = s:Funcs.get_reg()
    let s:v.oldsearch = [getreg("/"), getregtype("/")]
    if a:empty | let @/ = '' | endif

    let s:v.oldvirtual = &virtualedit
    set virtualedit=onemore
    let s:v.oldwhichwrap = &whichwrap
    set ww=<,>,h,l

    let s:v.search = []
    let s:v.move_from_back = 0

    let s:v.oldcase = [&smartcase, &ignorecase]
    let s:v.index = -1
    let s:v.direction = 1
    let s:v.silence = 0
    let s:v.extending = 0
    let s:v.only_this = 0
    let s:v.only_this_always = 0
    let s:v.merge_to_beol = 0

    call s:augroup_start()
    return s:Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Backup/restore buffer state on buffer change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#reset(...)
    let &virtualedit = s:v.oldvirtual
    let &whichwrap = s:v.oldwhichwrap
    let &smartcase = s:v.oldcase[0]
    let &ignorecase = s:v.oldcase[1]
    call s:restore_regs()
    call vm#maps#end()
    let b:VM_Selection = {}
    let g:VM_Global.is_active = 0
    let g:VM_Global.extend_mode = 0

    "exiting manually
    if !a:0 | call s:Funcs.msg('Exited Visual-Multi.') | endif

    call s:augroup_end()
    call clearmatches()
    set nohlsearch
    call garbagecollect()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs = {}

let s:Funcs.byte_pos = { pos -> eval(line2byte(line(pos)) + col(pos)) }
let s:Funcs.byte     = { pos -> eval(line2byte(pos[0]) + pos[1] ) }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:default_reg()
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

fun! s:restore_regs()
    let r = s:v.oldreg | let s = s:v.oldsearch
    call setreg(r[0], r[1], r[2])
    call setreg("/", s[0], s[1])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(text) dict
    if !s:v.silence
        exe "echohl" g:VM_Message_hl
        echo a:text
        echohl None
    endif
endfun

fun! s:Funcs.count_msg(force) dict
    let i = '['.s:v['index'].']  '
    if a:force | let s:v.silence = 0 | endif
    let s = len(s:Regions)>1 ? 's.' : '.'
    let t = g:VM_Global.extend_mode? ' region' : ' cursor'
    call self.msg(i.len(s:Regions).t.s.'   Current patterns: '.string(s:v.search))
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:augroup_start()
    augroup plugin-visual-multi
        au!
        au CursorMoved * call vm#commands#move(0, 0)
    augroup END
endfun

fun! s:augroup_end()
    augroup plugin-visual-multi
        au!
    augroup END
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Utility functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.regions_contents() dict
    echohl WarningMsg | echo "Index, A, B, width    --- Regions contents ---" | echohl None
    for r in s:Regions | call self.region_txt(r) | endfor
endfun

fun! s:Funcs.region_txt(r) dict
    let index = printf("%-4d", a:r.index)
    let line = substitute(a:r.txt, '\V\n', '^M', 'g')
    if len(line) > 80 | let line = line[:80] . '…' | endif

    echohl Directory | echo  index a:r.A a:r.B a:r.w
    echohl None      | echon "      " line
    echohl None
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

