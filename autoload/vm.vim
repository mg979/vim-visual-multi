""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" g:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global holds the Global class methods
" s:Regions contains the regions with their contents
" s:Matches contains the matches as they are registered with matchaddpos()
" s:v.matches contains the current matches as read with getmatches()

fun! vm#init(whole)
    "if already initialized, return current instance
    if !empty(g:VM_Selection)
        let s:v.whole_word = a:whole
        return s:V
    endif

    let g:VM_Selection = {'Vars': {}, 'Regions': [], 'Matches': []}

    let s:V = g:VM_Selection
    let s:v = s:V.Vars
    let s:v.whole_word = a:whole

    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:V.Global = s:Global

    call vm#funcs#init()
    call vm#region#init()

    return s:V
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Global = {}

fun! s:Global.all_empty() dict
    for r in s:Regions
        if !r.empty() | return 0 | endif
    endfor
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.new_region(down, ...) dict

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

