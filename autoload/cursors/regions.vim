fun! cursors#regions#init()
    let g:VM_Selection = {'Vars': {}, 'Regions': [], 'Matches': []}
    let s:V = g:VM_Selection
    let s:v = s:V.Vars
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existant

" g:Regions contains the regions with their contents
" g:VisualMatches contains the matches as they are registered with matchaddpos()

fun! cursors#regions#new(...)

    let obj = {}
    let obj.l = getpos("'[")[1]       " line
    let obj.a = getpos("'[")[2]       " begin
    let obj.b = getpos("']")[2]       " end
    let obj.w = obj.b - obj.a + 1     " width
    let obj.txt = getreg(s:v.def_reg)

    let region = [obj.l, obj.a, obj.w]

    let index = index(s:V.Regions, obj)
    if index == -1
        let match = matchaddpos('Selection', [region], 30)
        if a:0
            call insert(s:V.Matches, match, a:1)
            call insert(s:V.Regions, obj, a:1)
        else
            call add(s:V.Matches, match)
            call add(s:V.Regions, obj)
        endif
    endif
    let s:v.index = index
    let s:v.matches = getmatches()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! cursors#regions#move(i, motion)
    if index(['b', 'B', 'F', 'T'], a:motion[0]) >= 0
        call s:move_back(a:i, a:motion) | else | call s:move_forward(a:i, a:motion)
    endif
endfun

fun! s:move_forward(i, motion)
    let r = s:V.Regions[a:i]

    "move to the beginning of the region and set a mark
    call cursor(r.l, r.a)
    normal! m[

    "move to the end of the region and perform the motion
    call cursor(r.l, r.b)
    exe "normal! ".a:motion

    "ensure line boundaries aren't crossed
    if getpos('.')[1] > r.l
        let r.b = col([r.l, '$'])-1
    else
        let r.b = col('.')
    endif

    "set end mark and yank between marks
    call cursor(r.l, r.b)
    normal! m]`[y`]

    "update the rest of the region vars, and the highlight match
    let r.w = r.b - r.a + 1
    let r.txt = getreg(s:v.def_reg)
    let s:v.matches[a:i].pos1 = [r.l, r.a, r.w]
endfun

fun! s:move_back(i, motion)
    let r = s:V.Regions[a:i]

    "move to the beginning of the region, set a mark and perform the motion
    call cursor(r.l, r.b)
    normal! m]
    call cursor(r.l, r.a)
    exe "normal! ".a:motion

    "ensure line boundaries aren't crossed
    if getpos('.')[1] < r.l
        let r.a = col([r.l, 1])
    else
        let r.a = col('.')
    endif

    "set begin mark and yank between marks
    normal! m[`[y`]

    "update the rest of the region vars, and the highlight match
    let r.w = r.b - r.a + 1
    let r.txt = getreg(s:v.def_reg)
    let s:v.matches[a:i].pos1 = [r.l, r.a, r.w]
endfun
