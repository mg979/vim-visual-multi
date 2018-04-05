"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Store registers, initialize script vars and temporary buffer mappings.
"Some functions are registered in s:Funcs, that is returned to the global
"script, and then included in the global variable, so that they can be
"accessed from anywhere.

fun! vm#funcs#init()
    let s:V = b:VM_Selection | let s:v = s:V.Vars | let s:Global = s:V.Global
    let s:V.Funcs = s:Funcs

    call s:init_maps(0)

    let s:v.def_reg = s:default_reg()
    let s:v.oldreg = s:Funcs.get_reg()
    let s:v.oldsearch = [getreg("/"), getregtype("/")]
    let s:v.oldvirtual = &virtualedit
    set virtualedit=onemore
    let s:v.oldwhichwrap = &whichwrap
    set ww=<,>,h,l

    let s:v.search = []
    let s:v.move_from_back = 0
    let s:v.case_ignore = 0
    let s:v.index = -1

    call s:augroup_start()
    return s:Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#reset()
    let &virtualedit = s:v.oldvirtual
    let &whichwrap = s:v.oldwhichwrap
    call s:restore_regs()
    call s:init_maps(1)
    let b:VM_Selection = {}
    call s:augroup_end()
    call clearmatches()
    set nohlsearch
    "call garbagecollect()
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

fun! s:restore_regs()
    let r = s:v.oldreg | let s = s:v.oldsearch
    call setreg(r[0], r[1], r[2])
    call setreg("/", s[0], s[1])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:init_maps(end)
    if a:end
        nunmap <buffer> <esc>
        nunmap <buffer> <c-w>
        nunmap <buffer> <c-m>
        nunmap <buffer> <c-]>
        nunmap <buffer> +
        nunmap <buffer> -
        nunmap <buffer> s
        nunmap <buffer> q
        nunmap <buffer> Q
        nunmap <buffer> [
        nunmap <buffer> ]
        nunmap <buffer> {
        nunmap <buffer> }
        nunmap <buffer> h
        nunmap <buffer> l
        nunmap <buffer> k
        nunmap <buffer> j
        xunmap <buffer> [
        xunmap <buffer> ]
        xunmap <buffer> {
        xunmap <buffer> }
    else
        nmap <nowait> <buffer> <esc> :call vm#funcs#reset()<cr>
        nmap <nowait> <buffer> <c-w> :call vm#commands#toggle_whole_word()<cr>
        nmap <nowait> <buffer> <c-m> :call vm#merge_regions()<cr>
        nmap <nowait> <buffer> <c-]> :call vm#funcs#update_search()<cr>
        nmap <nowait> <buffer> s :call vm#commands#skip()<cr>
        nmap <nowait> <buffer> + :call vm#commands#find_next(0, 1)<cr>
        nmap <nowait> <buffer> - :call vm#commands#find_prev(0, 1)<cr>
        nmap <nowait> <buffer> ] :call vm#commands#find_next(0, 0)<cr>
        nmap <nowait> <buffer> [ :call vm#commands#find_prev(0, 0)<cr>
        nmap <nowait> <buffer> } :call vm#commands#find_under(0, 0, 0)<cr>
        nmap <nowait> <buffer> { :call vm#commands#find_under(0, 1, 0)<cr>
        xmap <nowait> <buffer> ] y:call vm#commands#find_under(1, 0, 0)<cr>`]
        xmap <nowait> <buffer> [ boey:call vm#commands#find_under(1, 1, 0)<cr>`]
        xmap <nowait> <buffer> } BoEy:call vm#commands#find_under(1, 0, 1)<cr>`]
        xmap <nowait> <buffer> { BoEy:call vm#commands#find_under(1, 1, 1)<cr>`]
    endif

    "motions
    let motions = ['w', 'W', 'b', 'B', 'e', 'E', '$', '0', '^']
    let find = ['f', 'F', 't', 'T']

    if a:end
        for m in (motions + find)
            exe "nunmap <buffer> ".m
        endfor
    else
        for m in motions
            exe "nmap <nowait> <buffer> <expr> ".m." vm#commands#motion('".m."')"
        endfor
        for m in find
            exe "nmap <nowait> <buffer> <expr> ".m." vm#commands#find_motion('".m."')"
        endfor

        "select
        nmap <nowait> <buffer> q :call vm#commands#select_motion(0)<cr>
        nmap <nowait> <buffer> Q :call vm#commands#select_motion(1)<cr>
        "move from back
        nmap <nowait> <buffer> <expr> h vm#commands#motion('h')
        nmap <nowait> <buffer> <expr> l vm#commands#motion('l')
        nmap <nowait> <buffer> <expr> k vm#commands#motion('k')
        nmap <nowait> <buffer> <expr> j vm#commands#motion('j')
    endif

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.msg(text) dict
    echohl WarningMsg
    echo a:text
    echohl None
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#update_search()
    let r = s:Global.is_region_at_pos('.')
    if empty(r) | return | endif
    let s = escape(r.txt, '\|')
    if index(s:v.search, s) == -1
        let s:v.search[-1] = s
    endif
    let @/ = join(s:v.search, '\|')
    set hlsearch
endfun

fun! s:Funcs.set_search() dict
    let s = s:pattern()
    if index(s:v.search, s) == -1
        call add(s:v.search, s)
    endif
    let @/ = join(s:v.search, '\|')
    set hlsearch
endfun

fun! s:pattern()
    let t = eval('@'.s:v.def_reg)
    let t = escape(t, '\|')
    let t = substitute(t, '\n', '\\n', 'g')
    if s:v.whole_word | let t = '\<'.t.'\>' | endif
    return t
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

