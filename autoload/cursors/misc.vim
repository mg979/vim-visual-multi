""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#misc#default_reg()
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

fun! cursors#misc#get_reg()
    let r = cursors#misc#default_reg()
    return [r, getreg(r), getregtype(r)]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:restore_regs()
    call setreg(s:r[0], s:r[1], s:r[2])
    call setreg("/", s:sreg[0], s:sreg[1])
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
        unmap <buffer> w
        unmap <buffer> <c-w>
    else
        nmap <nowait> <buffer> <esc> :call cursors#clear()<cr>
        nmap <nowait> <buffer> s :call cursors#skip()<cr>
        nmap <nowait> <buffer> ] :call cursors#find_next()<cr>
        nmap <nowait> <buffer> [ :call cursors#find_prev()<cr>
        nmap <nowait> <buffer> } :call cursors#find_under(0, 0)<cr>
        nmap <nowait> <buffer> { :call cursors#find_prev(0, 1)<cr>
        nmap <nowait> <buffer> <c-w> :call cursors#toggle_whole_word()
        nmap <nowait> <buffer> <expr> w cursors#motion('w')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#misc#init(whole)
    let s:whole_word = a:whole
    call s:init_maps(0)
    let s:r = cursors#misc#get_reg()
    let s:sreg = [getreg("/"), getregtype("/")]
    call s:augroup_start()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#misc#set_search()
    let @/ = s:pattern()
    set hlsearch
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#misc#reset()
    for m in g:VisualMatches
        call matchdelete(m)
    endfor
    let g:VisualMatches = []
    let g:Regions = []
    call s:restore_regs()
    call s:init_maps(1)
    call s:augroup_end()
    set nohlsearch
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pattern()
    let t = eval('@'.s:r[0])
    let t = substitute(escape(t, '\'), '\n', '\\n', 'g')
    if s:whole_word | let t = '\<'.t.'\>' | endif
    return t
endfun

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

