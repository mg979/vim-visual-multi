""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs
    let s:Search  = s:V.Search

    let s:v.finding    = 0
    let s:R            = { -> s:V.Regions }
endfun

fun! s:init()
    let g:VM.extend_mode = 1 | let g:VM.selecting = 1
    if !g:VM.is_active       | call vm#init_buffer(0) | endif
endfun

fun! vm#operators#select(all, count, ...)
    """Perform a yank, the autocmd will create the region.
    call s:init()

    if !a:all
        if g:VM.oldupdate      | let &updatetime = 10   | endif
        silent! nunmap <buffer> y
        return
    endif

    let s:v.storepos = getpos('.')[1:2]

    if a:0 | call s:select('y'.a:1) | return | endif

    let abort = 0
    let s = ''                     | let n = ''
    let x = a:count>1? a:count : 1 | echo "Selecting: ".(x>1? x : '')

    let l:Single = { c -> index(split('webWEB$0^hjkl', '\zs'), c) >= 0 }
    let l:Double = { c -> index(split('iaftFT', '\zs'), c) >= 0    }

    while 1
        let c = nr2char(getchar())
        if c == "\<esc>"                 | let abort = 1 | break

        elseif str2nr(c) > 0             | let n .= c    | echon c

        elseif l:Single(c)               | let s .= c    | echon c
            break

        elseif l:Double(c) || len(s)
            let s .= c                   | echon c
            if len(s) > 1                | break          | endif

        else                             | let abort = 1  | break    | endif
    endwhile

    if abort | return | endif

    let n = n<1? 1 : n
    let n = n*x>1? n*x : ''
    call s:select('y'.n.s)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:select(cmd)

    if g:VM.oldupdate | let &updatetime = 10 | endif

    call s:V.Edit.before_macro(1)

    silent! nunmap <buffer> y

    let Rs = map(copy(s:R()), '[v:val.l, v:val.a]')
    call vm#commands#erase_regions()

    for r in Rs
        call cursor(r[0], r[1])
        exe "normal ".a:cmd
        call s:G.get_region()
    endfor
    call s:V.Edit.after_macro(0)

    if !s:v.multiline
        for r in s:R()
            if r.h | call s:F.toggle_option('multiline') | break | endif
        endfor | endif

    nmap <silent> <nowait> <buffer> y               <Plug>(VM-Edit-Yank)

    if empty(s:v.search) | let @/ = ''                      | endif
    if g:VM.oldupdate    | let &updatetime = g:VM.oldupdate | endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Find operator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#find(start, visual, ...)

    if a:start
        if !g:VM.is_active
            call s:init()
            if a:visual
                "use search register if just starting from visual mode
                let @/ = s:v.oldsearch[0]
                call s:Search.get_slash_reg()
            endif
        else
            call s:init()
        endif

        if g:VM.oldupdate      | let &updatetime = 10   | endif
        let s:v.finding = 1
        silent! nunmap <buffer> y
        return 'y'
    endif

    "set the cursor to the start of the yanked region, then find occurrences until end mark is met
    keepjumps normal! `]
    let endline = getpos('.')[1]
    keepjumps normal! `[

    while 1
        if !search(join(s:v.search, '\|'), 'czpn', endline) | break | endif
        let R = vm#commands#find_next(0, 0)
        if empty(R)
            if s:v.index >= 0 | let s:v.index -= 1 | endif
            break | endif
    endwhile

    call s:G.update_and_select_region()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#after_yank()
    if g:VM.selecting
        let g:VM.selecting = 0

        "find operator
        if s:v.finding
            let s:v.finding = 0
            call vm#operators#find(0, 0)
        else
            "select operator
            call s:G.get_region()
            let R = s:G.select_region_at_pos('.')

            if R.h && !s:v.multiline
                call s:F.toggle_option('multiline') | endif
        endif

        if g:VM.oldupdate | let &updatetime = g:VM.oldupdate | endif
        nmap <silent> <nowait> <buffer> y <Plug>(VM-Edit-Yank)
    endif
endfun

