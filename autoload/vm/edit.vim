""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#edit#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions

    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:X       = { -> g:VM.extend_mode }

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex() dict
    if s:count(v:count) | return | endif

    let cmd = input('Ex command? ')
    if cmd == "\<esc>"
        call s:Funcs.msg('Command aborted.')
        return | endif

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_macro()
    let s:v.silence = 1 | let s:v.auto = 1
    let s:old_multiline = g:VM.multiline
    let g:VM.multiline
    call vm#maps#end()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_macro()
    let s:v.silence = 0 | let s:v.auto = 0
    let g:VM.multiline = s:old_multiline

    call vm#maps#start()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:count(c)
    "forbid count
    if a:c > 1
        if !g:VM.is_active | return 1 | endif
        call s:Funcs.msg('Count not allowed.')
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro() dict
    if s:count(v:count) | return | endif

    call s:Funcs.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:Funcs.msg('Macro aborted.')
        return | endif

    call s:before_macro()

    let W = [] | let X = s:X() | let change_for_ln = 0 | let replace_width = 0

    "store selections widths before they are collapsed
    for r in s:Regions | call add(W, X? r.w : 0) | endfor

    "change to cursor mode
    if X | call vm#commands#change_mode(1) | endif

    "run macro
    for r in s:Regions

        "first edit: run actual macro and store length of entered text
        if r.index == 0
            call cursor(r.l, r.a)
            exe "normal! @".reg
            let replace_width = len(@.)
        else
            "subsequent cursors: adjust position if necessary, then run macro
            let prev = s:Regions[r.index-1]

            "if there are more regions in the same line, store the width changes,
            "and adjust every cursor with the cumulative change for that line

            if r.l == prev.l

                let changed_width   = replace_width - W[prev.index]
                let r.a            += changed_width + change_for_ln
                let change_for_ln  += changed_width

                call r.update_cursor(r.l, r.a)
            else
                let change_for_ln = 0
            endif

            call cursor(r.l, r.a)
            normal! @@
        endif
    endfor
    call s:after_macro()
    call s:Global.update_regions()
    redraw!
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


