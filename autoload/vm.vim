""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global holds the Global class methods
" s:Regions contains the regions with their contents
" s:Matches contains the matches as they are registered with matchaddpos()
" s:v.matches contains the current matches as read with getmatches()

fun! vm#init(whole)
    "if already initialized, return current instance
    if !empty(b:VM_Selection)
        let s:v.whole_word = a:whole
        return s:V
    endif

    let b:VM_Selection = {'Vars': {}, 'Regions': [], 'Matches': [], 'Funcs': {}}
    let s:V = b:VM_Selection
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.new_region(down) dict

    let R = s:Global.is_region_at_pos('.')
    if empty(R) | let R = vm#region#new() | endif

    let s:v.direction = a:down
    let s:v.matches = getmatches()
    call self.select_region(R.index)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_highlight(...) dict

    for r in s:Regions
        call r.update_highlight()
    endfor

    call setmatches(s:v.matches)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.all_empty() dict
    for r in s:Regions
        if r.a != r.b | return 0 | endif | endfor
        return 1
    endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region(i) dict
    "adjust cursor position of the region at index, then return the region
    if a:i >= len(s:Regions) | let i = 0 | else | let i = a:i | endif
    let R = s:Regions[i]
    let pos = s:v.direction ? R.b : R.a
    call cursor([R.l, pos])
    let s:v.index = i
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region_at_pos(pos) dict
    let r = self.is_region_at_pos(a:pos)
    if !empty(r)
        call self.select_region(r.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.is_region_at_pos(pos) dict
    "find if the cursor is on an highlighted region
    let pos = getpos(a:pos)[1:2]
    for r in s:Regions
        if pos[0] == r.l && pos[1] >= r.a && pos[1] <= r.b
            return r | endif | endfor
    return {}
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
" Merging regions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#merge_regions()
    if !empty(b:VM_Selection) | call s:Global.merge_regions() | endif
endfun

fun! s:Global.merge_regions() dict
    "merge overlapping regions
    let lines = {}
    let storepos = getpos('.')

    "find lines with regions
    for r in s:Regions
        "add region index to indices for that line
        let lines[r.l] = get(lines, r.l, [])
        call add(lines[r.l], r.index)
    endfor

    "remove lines and indices without multiple regions
    let lines = filter(lines, 'len(v:val) > 1')
    let to_remove = []

    "find overlapping regions for each line with multiple regions
    for indices in values(lines)
        let n = 0 | let max = len(indices) - 1

        for i in indices
            while (n < max)
                let this = indices[n] | let next = indices[n+1] | let n += 1
                let r = s:Regions[this] | let next = s:Regions[next]

                "merge regions if there is overlap with next one
                if ( r.b >= next.a )
                    call next.update(r.l, r.a, next.b)
                    call add(to_remove, r)
                endif | endwhile | endfor | endfor

    " remove old regions and update highlight
    for r in to_remove | call r.remove() | endfor
    call s:Global.update_highlight()

    "restore cursor position
    call setpos('.', storepos)
    call self.select_region_at_pos('.')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

