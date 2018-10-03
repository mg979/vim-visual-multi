" Special commands that can be selected through the Tools Menu (<leader>x)

fun! vm#special#commands#init()
    let s:V = b:VM_Selection
    let s:F = s:V.Funcs
    let s:G = s:V.Global
    let s:R = { -> s:V.Regions }
    let s:X = { -> g:VM.extend_mode }
endfun

fun! vm#special#commands#menu()
    let opts = [
                \["\"    - ", "Show VM registers"],
                \["i    - ", "Show regions info"],
                \["\n", ""],
                \["f    - ", "Filter regions by expression"],
                \["l(L) - ", "Filter lines with regions (strip indent)"],
                \["p    - ", "Paste regions contents in a new buffer"],
                \]
    for o in opts
        echohl WarningMsg | echo o[0] | echohl Type | echon o[1]
    endfor
    echohl Directory  | echo "Enter an option: " | echohl None
    let c = nr2char(getchar())
    if c ==# '"'
        redraw!
        call s:F.show_registers()
    elseif c ==# 'i'
        redraw!
        call s:F.regions_contents()
    elseif c ==# 'p'
        call feedkeys("\<cr>", 'n')
        call vm#special#commands#regions_to_buffer()
    elseif c ==# 'f'
        redraw!
        call vm#special#commands#filter_regions()
    elseif c ==# 'l'
        call feedkeys("\<cr>", 'n')
        call vm#special#commands#filter_lines(0)
    elseif c == 'L'
        call feedkeys("\<cr>", 'n')
        call vm#special#commands#filter_lines(1)
    else
        call feedkeys("\<cr>", 'n')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter lines
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_lines(strip)
    """Filter lines containing regions, and paste them in a new buffer.
    if !len(s:R()) | return | endif

    let lines = sort(keys(s:G.lines_with_regions(0)))
    let txt = []
    for l in lines
        exe "normal! ".l."ggyy"
        call add(txt, getreg(s:F.default_reg()))
    endfor
    call vm#reset(1)
    new
    set buftype=nofile
    for t in txt
        if a:strip
            if match(t, '^\s') == 0 | let t = t[match(t, '\S'):] | endif
        endif
        put = t
    endfor
    normal! ggdd
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions to buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#regions_to_buffer()
    """Paste selected regions in a new buffer.
    if !s:X() || !len(s:R()) | return | endif

    let txt = []
    for r in s:R()
        let t = r.txt
        if t[-1:-1] != "\n" | let t .= "\n" | endif
        call add(txt, r.txt) | endfor
    call vm#reset(1)
    new
    set buftype=nofile
    for t in txt
        put = t
    endfor
    normal! ggdd
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter by expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_regions(...)
    """Remove regions that don't match an expression."""
    if s:not_active() | return | endif
    if !a:0
        echohl Label
        let exp = input('Enter a filter (expression) > ', '', 'command')
        echohl None
    else
        let exp = a:1
    endif
    if empty(exp)
        call s:F.msg('Canceled.', 1)
    else
        call s:G.filter_by_expression(exp)
        call s:G.select_region(0)
    endif
endfun

fun! s:not_active()
    if !g:VM.is_active
        echohl ErrorMsg | echo "VM is not enabled" | echohl None | return 1
    endif
endfun

