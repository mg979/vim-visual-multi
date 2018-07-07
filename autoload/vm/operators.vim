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
    let s:R            = { -> s:V.Regions      }
    let s:X            = { -> g:VM.extend_mode }
endfun

fun! s:init()
    let g:VM.extend_mode = 1
    if !g:VM.is_active       | call vm#init_buffer(0) | endif
endfun

fun! vm#operators#select(all, count, ...)
    """Perform a yank, the autocmd will create the region.
    call s:init()

    if !a:all
        let g:VM.selecting = 1
        if g:VM.oldupdate      | let &updatetime = 10   | endif
        silent! nunmap <buffer> y
        return
    endif

    let s:v.storepos = getpos('.')[1:2]
    call s:F.Scroll.get()

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
    let s:v.silence = 0

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

        "ensure there is an active search
        if empty(s:v.search)
            if !len(s:R()) | call s:Search.get_slash_reg()
            else           | call s:Search.get() | endif
        endif

        if g:VM.oldupdate      | let &updatetime = 10   | endif
        let s:v.finding = 1    | let g:VM.selecting = 1
        silent! nunmap <buffer> y
        return 'y'
    endif

    "set the cursor to the start of the yanked region, then find occurrences until end mark is met
    keepjumps normal! `]
    let endline = getpos('.')[1]
    keepjumps normal! `[

    while 1
        if !search(join(s:v.search, '\|'), 'znp', endline) | break | endif
        let R = vm#commands#find_next(0, 0, 1)
        if empty(R)
            if s:v.index >= 0 | let s:v.index -= 1 | endif
            break | endif
    endwhile

    call s:G.update_map_and_select_region()
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Operations at cursors (yank, delete, change)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:back = { c -> index(split('FTlb0^', '\zs'), c) >= 0      }
let s:ia   = { c -> index(['i', 'a'], c) >= 0                  }
let s:all  = { c -> index(split('hlwebWEB$^0', '\zs'), c) >= 0 }
let s:find = { c -> index(split('fFtT', '\zs'), c) >= 0        }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:total_count(n, S)
    let S = a:S | let n = a:n

    let x = match(S, '\d') >= 0? substitute(S, '\D', '', 'g') : 0
    if x | let S = substitute(S, x, '', '') | endif

    "final count
    let N = x? n*x : n>1? n : 1 | let N = N>1? N : ''

    return [S, N]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#operators#cursors(op, n)
    if s:X() | call s:G.change_mode(1) | endif
    call s:F.Scroll.get()

    let reg = v:register | let r = "\"".reg | let hl1 = 'WarningMsg' | let hl2 = 'Label'

    let s =       a:op==#'d'? [['Delete ', hl1], ['([n] d/w/e/b/$...) ?  ',   hl2]] :
                \ a:op==#'c'? [['Change ', hl1], ['([n] s/w/e/b/$...) ?  ',   hl2]] :
                \ a:op==#'y'? [['Yank   ', hl1], ['([n] y/w/e/b/$...) ?  ',   hl2]] : 'Aborted.'

    call s:F.msg(s, 1)

    "starting string
    let M = (a:n>1? a:n : '').( reg == s:v.def_reg? '' : '"'.reg ).a:op

    "preceding count
    let n = a:n>1? a:n : 1

    echon M
    while 1
        let c = nr2char(getchar())
        if str2nr(c) > 0                     | echon c | let M .= c
        elseif s:find(c)                     | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c | break

        elseif s:ia(c)                       | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c | break

        elseif a:op ==# 'c' && c==#'s'       | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c
            let c = nr2char(getchar())       | echon c | let M .= c | break

        elseif s:all(c)                      | echon c | let M .= c | break
        elseif a:op ==# 'd' && c==#'d'       | echon c | let M .= c | break
        elseif a:op ==# 'c' && c==#'c'       | echon c | let M .= c | break
        elseif a:op ==# 'y' && c==#'y'       | echon c | let M .= c | break

        else | echon ' ...Aborted'           | return  | endif
    endwhile

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "delete
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    if a:op ==# 'd'
        "what comes after 'd'; check for 'dd'
        let S = substitute(M, r, '', '')
        let S = substitute(S, '^\d*d\(.*\)$', '\1', '')
        let [S, N] = s:total_count(n, S)
        let D = S[0]==#'d' | let back = s:back(S)

        "for D, d$, dd: ensure there is only one region per line
        if (S == '$' || S == 'd') | call s:G.one_region_per_line() | endif

        if D | call s:V.Edit.run_normal('dd', 0, 1, 0)
        else
            call vm#operators#select(1, 1, N.S)
            if back | exe "normal h" | endif
            exe "normal ".r."d"
        endif
        call s:G.merge_regions()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "yank
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif a:op ==# 'y'
        call s:G.change_mode(1)

        "what comes after 'y'; check for 'yy'
        let S = substitute(M, r, '', '')
        let S = substitute(S, '^\d*y\(.*\)$', '\1', '')
        let [S, N] = s:total_count(n, S)
        let Y = S[0]==#'y' | let back = s:back(S)

        "for Y, y$, yy, ensure there is only one region per line
        if (S == '$' || S == 'y') | call s:G.one_region_per_line() | endif

        "NOTE: yy doesn't accept count.
        if Y
            call vm#commands#motion('0', 1, 0, 0)
            call vm#commands#motion('$', 1, 0, 0)
            let s:v.multiline = 1
            call vm#commands#motion('l', 1, 0, 0)
            call feedkeys('y')
        else
            call vm#operators#select(1, 1, N.S.r)
            if back | exe "normal h" | endif | normal y
        endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "change
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif a:op ==# 'c'

        "cs surround
        if M[:1] ==# 'cs' | call s:V.Edit.run_normal(M, 1, 1, 0) | return | endif

        "what comes after 'c'; check for 'cc'
        let S = substitute(M, r, '', '')
        let S = substitute(S, '^\d*c\(.*\)$', '\1', '')
        let [S, N] = s:total_count(n, S)
        let C = S[0]==#'c' | let back = s:back(S)

        "for c$, cc, ensure there is only one region per line
        if (S == '$' || S == 'c') | call s:G.one_region_per_line() | endif

        let S = substitute(S, '^c', 'd', '')
        let reg = reg != s:v.def_reg? reg : "_"

        if C
            normal s$
            call vm#commands#motion('^', 1, 0, 0)
            call s:V.Edit.delete(1, reg, 1)
            call s:V.Insert.key('a')

        elseif S=='$'
            call vm#operators#select(1, 1, 's$')
            call s:V.Edit.delete(1, reg, 1)
            call s:V.Insert.key('a')

        else
            call vm#operators#select(1, 1, N.S)
            if back | exe "normal h" | endif
            call feedkeys("\"".reg.'c')
        endif
    endif
endfun

