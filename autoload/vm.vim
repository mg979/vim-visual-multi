""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#init(whole)
    "already initialized, return current instance
    if !empty(g:VM_Selection) | return s:V | endif

    let g:VM_Selection = {'Vars': {}, 'Regions': [], 'Matches': []}

    let s:V = g:VM_Selection
    let s:v = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches

    call vm#funcs#init(a:whole)
    call vm#region#init()

    return s:V
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:V = g:VM_Selection

fun! vm#new_region(down, ...)

    let R = vm#region#new()

    let region = [R.l, R.a, R.w]
    let w      = R.a==R.b ? 1 : -1
    let cursor = [R.l, R.b, w]

    let index = index(s:Regions, R)
    if index == -1
        let match  = matchaddpos('Selection',   [region], 30)
        let cursor = matchaddpos('MultiCursor', [cursor], 40)
        if a:0
            call insert(s:Matches, [match, cursor],  a:1)
            call insert(s:Regions, R,                a:1)
        else
            call add(s:Matches, [match, cursor])
            call add(s:Regions, R)
        endif
    endif

    let s:v.going_down = a:down
    let s:v.index = index
    let s:v.matches = getmatches()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

