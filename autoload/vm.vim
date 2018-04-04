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

    let g:VM_Selection = {'Vars': {}, 'Regions': [], 'Matches': [], 'Funcs': {}}
    let s:V = g:VM_Selection
    let s:V.Global = s:Global

    let s:v = s:V.Vars
    let s:v.whole_word = a:whole

    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches

    let s:Funcs = vm#funcs#init()
    call vm#region#init()

    return s:V
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Global = {}

fun! s:Global.all_empty() dict
    for r in s:Regions
        if r.a != r.b | return 0 | endif
    endfor
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.new_region(down) dict

    let existing = s:Global.is_region_existant()
    let R = existing[0]

    let region = [R.l, R.a, R.w]
    let w      = R.a==R.b ? 1 : -1
    let cursor = [R.l, R.b, w]

    if !existing[1]
        let match  = matchaddpos('Selection',   [region], 30)
        let cursor = matchaddpos('MultiCursor', [cursor], 40)
        call add(s:Matches, [match, cursor])
        call add(s:Regions, R)
    endif

    let s:v.index = R.index
    let s:v.going_down = a:down
    let s:v.matches = getmatches()

    call self.select_region(R.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region(i) dict
    "move cursor to the end of the region at index, then return the region
    let R = s:Regions[a:i]
    call cursor([R.l, R.b])
    return R
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.is_region_existant() dict
    let pos = getpos('.')[1:2]
    for r in s:Regions
        if pos[0] == r.l && pos[1] >= r.a && pos[1] <= r.b
            return [r, 1]
        endif
    endfor
    return [vm#region#new(), 0]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_indices() dict
    "adjust region indices
    let i = 0
    for r in s:Regions
        let r.index = i
        let i += 1
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

