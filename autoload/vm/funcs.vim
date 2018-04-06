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
    let s:v.oldvirtual = &virtualedit
    set virtualedit=onemore
    let s:v.oldwhichwrap = &whichwrap
    set ww=<,>,h,l

    let s:v.search = []
    let s:v.move_from_back = 0

    let s:v.oldcase = [&smartcase, &ignorecase]
    let s:v.index = -1
    let s:v.matches = get(s:v, matches, [])
    let s:v.direction = 1
    let s:v.silence = 0
    let s:v.only_this = 0
    let s:v.only_this_all = 0

    call s:augroup_start()
    return s:Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Backup/restore buffer state on buffer change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:key = { -> 'g:VM_Global.'.bufnr("%") }

fun! vm#funcs#buffer_leave()
    if !empty(b:VM_Selection)
        let s:v.pos = getpos('.')
        exe 'let '.s:key().' = copy(b:VM_Selection)'
        call vm#funcs#reset(1)
    endif
endfun

fun! vm#funcs#buffer_enter()
    let b:VM_Selection = {}

    if !empty(get(g:VM_Global, bufnr("%"), {}))
        call vm#init_buffer(1)
        call setmatches(s:v.matches)
        call setpos('.', s:v.pos)
        call vm#commands#add_under(0, s:v.whole_word, 0, 1)
    endif
endfun

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

    if !a:0    "exiting manually
        call s:Funcs.msg('Exited Visual-Multi.')
        call remove(g:VM_Global, bufnr("%"))
    endif

    call s:augroup_end()
    call clearmatches()
    set nohlsearch
    call garbagecollect()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs = {}

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

function! s:Funcs.msg(text) dict
    if !s:v.silence
        exe "echohl" g:VM_Message_hl
        echo a:text
        echohl None
    endif
endfunction

fun! s:Funcs.count_msg() dict
    let s = len(s:Regions)>1 ? 's.' : '.'
    call self.msg(len(s:Regions).' region'.s.'   Current patterns: '.string(s:v.search))
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:augroup_start()
    augroup plugin-visual-multi
        au!
        au CursorMoved * call vm#commands#move()
    augroup END
endfun

fun! s:augroup_end()
    augroup plugin-visual-multi
        au!
    augroup END
endfun

