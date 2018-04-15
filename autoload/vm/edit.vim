""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#edit#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches

    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:X       = { -> g:VM.extend_mode }

    let s:v.running_macro = 0

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro() dict

    "forbid count
    if v:count > 1
        if !g:VM.is_active | return | endif
        call s:Funcs.msg('Count not allowed.')
        call vm#reset()
        return | endif

    call s:Funcs.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:Funcs.msg('Macro aborted.')
        return | endif

    let s:v.silence = 1 | let s:v.running_macro = 1
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
    let s:v.silence = 0 | let s:v.running_macro = 0
    call s:Global.update_regions()
    redraw!
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


