"special commands

fun! vm#special#commands#init()
    let s:V = b:VM_Selection
    let s:R = { -> s:V.Regions }
    let s:X = { -> g:VM.extend_mode }
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter lines
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_lines(strip)
    """Filter lines containing regions, and paste them in a new buffer.
    if !len(s:R()) | return | endif

    let lines = sort(keys(s:V.Global.lines_with_regions(0)))
    let txt = []
    for l in lines
        exe "normal! ".l."ggyy"
        call add(txt, getreg(s:V.Funcs.default_reg()))
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
    normal! gg
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter regions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_regions()
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
    normal! gg
endfun
