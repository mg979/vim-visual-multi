""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#funcs#init(whole)
    if !empty(g:VM_Selection) | return s:V | endif

    call cursors#regions#init()
    let s:V = g:VM_Selection | let s:v = s:V.Vars

    call s:init_maps(0)

    let s:v.def_reg = s:default_reg()
    let s:v.whole_word = a:whole
    let s:v.oldreg = s:get_reg()
    let s:v.oldsearch = [getreg("/"), getregtype("/")]
    let s:v.search = []

    call s:augroup_start()
    return s:V
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#funcs#reset()
    for m in s:V.Matches
        call matchdelete(m)
    endfor
    call s:restore_regs()
    call s:init_maps(1)
    let g:VM_Selection = {}
    call s:augroup_end()
    set nohlsearch
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
        unmap <buffer> [
        unmap <buffer> ]
        unmap <buffer> {
        unmap <buffer> }
        unmap <buffer> <c-w>
    else
        nmap <nowait> <buffer> <esc> :call cursors#funcs#reset()<cr>
        nmap <nowait> <buffer> s :call cursors#skip()<cr>
        nmap <nowait> <buffer> ] :call cursors#find_next()<cr>
        nmap <nowait> <buffer> [ :call cursors#find_prev()<cr>
        nmap <nowait> <buffer> } :call cursors#find_under(0, 0)<cr>
        nmap <nowait> <buffer> { :call cursors#find_under(0, 1)<cr>
        nmap <nowait> <buffer> <c-w> :call cursors#toggle_whole_word()
    endif

    "motions
    let motions = ['w', 'W', 'b', 'B', 'e', 'E']
    let find = ['f', 'F', 't', 'T']

    if a:end
        for m in (motions + find)
            exe "unmap <buffer> ".m
        endfor
    else
        for m in motions
            exe "nmap <nowait> <buffer> <expr> ".m." cursors#motion('".m."')"
        endfor
        for m in find
            exe "nmap <nowait> <buffer> <expr> ".m." cursors#find_motion('".m."')"
        endfor
    endif

    "select
    "TODO select inside/around brackets/quotes/etc.
    nmap <nowait> <buffer> q :call cursors#select_motion(0)<cr>
    nmap <nowait> <buffer> Q :call cursors#select_motion(1)<cr>
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

fun! cursors#funcs#set_search()
    let s = s:pattern()
    if index(s:v.search, s) == -1
        call add(s:v.search, s)
    endif
    let @/ = join(s:v.search, '\|')
    set hlsearch
endfun

fun! s:pattern()
    let t = eval('@'.s:v.def_reg)
    let t = substitute(escape(t, '\'), '\n', '\\n', 'g')
    if s:v.whole_word | let t = '\<'.t.'\>' | endif
    return t
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:augroup_start()
    augroup plugin-visual-multi
        au!
        au CursorMoved * call cursors#move()
    augroup END
endfun

fun! s:augroup_end()
    augroup plugin-visual-multi
        au!
    augroup END
endfun

