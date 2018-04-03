fun! vm#region#init()
    let s:V = g:VM_Selection
    let s:v = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existant

" g:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Regions contains the regions with their contents
" s:Matches contains the matches as they are registered with matchaddpos()
" s:v.matches contains the current matches as read with getmatches()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#region#new()
    return s:Region.new()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Region = {}

fun! s:Region.new()
    let obj = copy(self)
    let obj.l = getpos("'[")[1]       " line
    let obj.a = getpos("'[")[2]       " begin
    let obj.b = getpos("']")[2]       " end
    let obj.w = obj.b - obj.a + 1     " width
    let obj.txt = getreg(s:v.def_reg) " text content

    return obj
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region resizing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move(motion) dict
    if s:v.move_from_back | call self.move_from_back(a:motion)
    elseif index(['b', 'B', 'F', 'T', 'h', 'k', '0', '^'], a:motion[0]) >= 0
        call self.move_back(a:motion) | else | call self.move_forward(a:motion)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_forward(motion) dict
    let r = self

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
    call cursor(r.l, r.b+1)
    normal! m]`[y`]

    call self.update_vars()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_from_back(motion) dict
    let r = self

    "set a marks and perform the motion
    call cursor(r.l, r.b+1)
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

    call self.update_vars()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_back(motion) dict
    let r = self

    "move to the beginning of the region and set a mark
    call cursor(r.l, r.a)
    normal! m[

    "move to the end of the region and perform the motion
    call cursor(r.l, r.b)
    exe "normal! ".a:motion

    "ensure line boundaries aren't crossed
    if getpos('.')[1] > r.l
        let r.b = col([r.l, '$'])-1
    elseif getpos('.')[1] < r.l
        let r.b = col([r.l, 1])
    else
        let r.b = col('.')
    endif

    "exchange a and b if there's been inversion
    if r.a > r.b
        let r.a = r.b
        call cursor(r.l, r.a)
        normal! m[
    endif

    "set end mark and yank between marks
    call cursor(r.l, r.b+1)
    normal! m]`[y`]

    call self.update_vars()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_vars() dict
    "update the rest of the region vars, and the highlight match
    let r = self

    let r.w = r.b - r.a + 1
    let r.txt = getreg(s:v.def_reg)
    let i = index(s:Regions, self)
    let s:v.matches[i].pos1 = [r.l, r.a, r.w]
    let cursor = len(s:Matches) + i
    let w = r.a==r.b ? 1 : -1
    let s:v.matches[cursor].pos1 = [r.l, r.b, w]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

