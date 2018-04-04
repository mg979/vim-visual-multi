"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"store registers, initialize script vars and temporary buffer mappings

fun! vm#funcs#init()
    let s:V = g:VM_Selection | let s:v = s:V.Vars

    call s:init_maps(0)

    let s:v.def_reg = s:default_reg()
    let s:v.oldreg = s:get_reg()
    let s:v.oldsearch = [getreg("/"), getregtype("/")]
    let s:v.search = []
    let s:v.move_from_back = 0
    let s:v.case_ignore = 0

    call s:augroup_start()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#reset()
    call s:restore_regs()
    call s:init_maps(1)
    let g:VM_Selection = {}
    call s:augroup_end()
    call clearmatches()
    set nohlsearch
    "call garbagecollect()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
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

fun! s:get_reg()
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
        unmap <buffer> <esc>
        unmap <buffer> s
        unmap <buffer> q
        unmap <buffer> Q
        unmap <buffer> [
        unmap <buffer> ]
        unmap <buffer> {
        unmap <buffer> }
        unmap <buffer> <c-w>
        unmap <buffer> x
        unmap <buffer> h
        unmap <buffer> l
        unmap <buffer> k
        unmap <buffer> j
    else
        nmap <nowait> <buffer> <esc> :call vm#funcs#reset()<cr>
        nmap <nowait> <buffer> s :call vm#commands#skip()<cr>
        nmap <nowait> <buffer> ] :call vm#commands#find_next()<cr>
        nmap <nowait> <buffer> [ :call vm#commands#find_prev()<cr>
        nmap <nowait> <buffer> } :call vm#commands#find_under(0, 0)<cr>
        nmap <nowait> <buffer> { :call vm#commands#find_under(0, 1)<cr>
        nmap <nowait> <buffer> <c-w> :call vm#commands#toggle_whole_word()<cr>
    endif

    "motions
    let motions = ['w', 'W', 'b', 'B', 'e', 'E', '$', '0', '^']
    let find = ['f', 'F', 't', 'T']

    if a:end
        for m in (motions + find)
            exe "unmap <buffer> ".m
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
        nmap <nowait> <buffer> <expr> x vm#commands#motion('x')
        nmap <nowait> <buffer> <expr> h vm#commands#motion('h')
        nmap <nowait> <buffer> <expr> l vm#commands#motion('l')
        nmap <nowait> <buffer> <expr> k vm#commands#motion('k')
        nmap <nowait> <buffer> <expr> j vm#commands#motion('j')
    endif

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:msg(text)
    echohl WarningMsg
    echo a:text
    echohl None
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#set_search()
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

