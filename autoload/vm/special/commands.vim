" Special commands that can be selected through the Tools Menu (<leader>x)

fun! vm#special#commands#init()
    let s:V = b:VM_Selection
    let s:F = s:V.Funcs
    let s:G = s:V.Global
endfun

if v:version >= 800
    let s:R    = { -> s:V.Regions }
    let s:X    = { -> g:Vm.extend_mode }
else
    let s:R    = function('vm#v74#regions')
    let s:X    = function('vm#v74#extend_mode')
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#menu()
    let opts = [
                \["\"    - ", "Show VM registers"],
                \["i    - ", "Show regions info"],
                \["\n", ""],
                \["f    - ", "Filter regions by pattern or expression"],
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
        call vm#special#commands#filter_regions(0, '')
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

"------------------------------------------------------------------------------

fun! s:temp_buffer()
    setlocal buftype=acwrite
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nomodified
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
        call add(txt, getline(l))
    endfor
    call vm#reset(1)
    let s:buf = bufnr("%")
    noautocmd keepalt botright new! VM\ Filtered\ Lines
    setlocal stl=VM\ Filtered\ Lines
    let b:VM_lines = lines
    for t in txt
        if a:strip
            if match(t, '^\s') == 0 | let t = t[match(t, '\S'):] | endif
        endif
        put = t
    endfor
    normal! ggdd
    call s:temp_buffer()
    autocmd BufWriteCmd <buffer> call s:save_lines(s:buf)
endfun

"------------------------------------------------------------------------------

fun! s:save_lines(buf)
    setlocal nomodified
    if len(b:VM_lines) != line("$")
        return s:F.msg("Number of lines doesn't match, aborting")
    endif
    let lnums = copy(b:VM_lines)
    let lines = map(range(line("$")), 'getline(v:key + 1)')
    quit
    exe a:buf."b"
    let i = 0
    for l in lnums
        call setline(l, lines[i])
        let i += 1
    endfor
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
        call add(txt, r.txt)
    endfor
    call vm#reset(1)
    let s:buf = bufnr("%")
    noautocmd keepalt botright new! VM\ Filtered\ Regions
    setlocal stl=VM\ Filtered\ Regions
    let b:VM_regions = copy(s:R())
    for t in txt
        put = t
    endfor
    normal! ggdd
    call s:temp_buffer()
    autocmd BufWriteCmd <buffer> call s:save_regions(s:buf)
endfun

"------------------------------------------------------------------------------

fun! s:save_regions(buf)
    setlocal nomodified
    if len(b:VM_regions) != line("$")
        return s:F.msg("Number of lines doesn't match number of regions")
    endif
    let R = copy(b:VM_regions)
    let lines = map(range(line("$")), 'getline(v:key + 1)')
    quit
    exe a:buf."b"
    for r in R
        call vm#region#new(0, r.l, r.L, r.a, r.b)
    endfor
    call s:V.Edit.replace_regions_with_text(lines)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter by expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_regions(type, fill, ...)
    """Filter regions based on pattern or expression."""
    if s:not_active() | return | endif
    if a:type == 0 || a:type > 2
      let s:filter_type = 0
    endif
    let type = ['pattern', '!pattern', 'expression'][s:filter_type]
    if !a:0
        cnoremap <buffer><nowait><silent><expr> <C-x> <sid>filter_regions(getcmdline())
        echohl Label
        let exp = input('Enter a filter (^X '.type.') > ', a:fill, 'command')
        echohl None
        cunmap <buffer> <C-x>
    else
        let exp = a:1
    endif
    if empty(exp)
        call s:F.msg('Canceled.', 1)
    else
        call s:G.filter_by_expression(exp, type)
        call s:G.update_and_select_region()
    endif
endfun

fun! s:filter_regions(fill)
  let s:filter_type += 1
  let args = s:filter_type . ", '" . a:fill . "'"
  return "\<C-U>\<Esc>:call vm#special#commands#filter_regions(".args.")\<cr>"
endfun

"------------------------------------------------------------------------------

fun! s:not_active()
    if !g:Vm.is_active
        echohl ErrorMsg | echo "VM is not enabled" | echohl None | return 1
    endif
endfun

