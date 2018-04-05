fun! vm#region#init()
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:Regions = s:V.Regions
    let s:Matches = s:V.Matches
    let s:Global = s:V.Global
    let s:Funcs = s:V.Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existant

" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global holds the Global class methods
" s:Regions contains the regions with their contents
" s:Matches contains the matches as they are registered with matchaddpos()
" s:v.matches contains the current matches as read with getmatches()


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#region#new(empty)
    return s:Region.new(a:empty)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Region = {}

fun! s:Region.new(empty)
    let R       = copy(self)
    let R.index = len(s:Regions)

    if !a:empty
        let R.l     = getpos("'[")[1]       " line
        let R.a     = getpos("'[")[2]       " begin
        let R.b     = getpos("']")[2]       " end
        let R.w     = R.b - R.a + 1         " width
        let R.txt   = getreg(s:v.def_reg)   " text content
    else
        let R.l     = getpos(".")[1]        " line
        let R.a     = getpos(".")[2]        " begin
        let R.b     = R.a                   " end
        let R.w     = 1                     " width
        let R.txt   = ''                    " text content
    endif

    "highlight entry
    let region  = [R.l, R.a, R.w]
    let cursor  = [R.l, R.b, 1]
    call s:cursor_hl(R.a==R.b)

    let match   = matchaddpos(g:VM_Selection_hl, [region], 30)
    let cursor  = matchaddpos('MultiCursor',     [cursor], 40)
    call add(s:Matches, [match, cursor])
    call add(s:Regions, R)

    return R
endfun

fun! s:Region.empty() dict
    return self.a == self.b
endfun

fun! s:Region.remove() dict
    let i = self.index
    call remove(s:Regions, i)
    let m = s:Matches[i][0]
    let c = s:Matches[i][1]
    call remove(s:Matches, i)
    call matchdelete(m)
    call matchdelete(c)

    let s:v.matches = getmatches()
    call s:Global.update_indices()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region resizing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:forward   = {m -> index(['w', 'W', 'e', 'E', 'l', 'j', 'f', 't', '$'], m)  >= 0}
let s:backwards = {m -> index(['b', 'B', 'F', 'T', 'h', 'k', '0', '^'], m)       >= 0}
let s:simple    = {m -> index(['h', 'j', 'k', 'l'], m)                           >= 0}
let s:extreme   = {m -> index(['$', '0', '^'], m)                                >= 0}

fun! s:Region.move(motion) dict
    if s:v.move_from_back
        call self.move_from_back(a:motion)

    elseif s:backwards(a:motion[0])
        call self.move_back(a:motion)

    else
        call self.move_forward(a:motion)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.move_forward(motion) dict
    let r = self | let all_empty = s:Global.all_empty()

    "move to the beginning of the region and set a mark
    call cursor(r.l, r.a)
    normal! m[

    "move to the end of the region and perform the motion
    call cursor(r.l, r.b)
    exe "normal! ".a:motion

    "ensure line boundaries aren't crossed
    "if !s:simple(a:motion[0]) && getpos('.')[1] > r.l
    if getpos('.')[1] > r.l
        let r.b = col([r.l, '$'])-1
    else
        let r.b = col('.')
    endif

    "keep single width while moving if all cursors are empty
    if a:motion ==# 'l' && all_empty
        let r.a += 1
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
    "if !s:simple(a:motion[0]) && getpos('.')[1] < r.l
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
    "if !s:simple(a:motion[0]) && getpos('.')[1] < r.l
    if getpos('.')[1] < r.l
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
" Update functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update(l, a, b) dict
    let self.l   = a:l                   " line
    let self.a   = a:a                   " begin
    let self.b   = a:b                   " end

    "yank new content
    call cursor(a:l, a:a)
    normal! m[
    call cursor(a:l, a:b+1)
    normal! m]`[y`]

    call self.update_vars()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Region.update_vars() dict
    "update the rest of the region vars
    let r = self
    let s:v.index = r.index

    let r.w = r.b - r.a + 1
    let r.txt = getreg(s:v.def_reg)
    call r.update_highlight()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:cursor_hl(mono)
    highlight clear MultiCursor
    if a:mono
        exe "highlight link MultiCursor ".g:VM_Mono_Cursor_hl
    else
        exe "highlight MultiCursor ".g:VM_Normal_Cursor_hl
    endif
endfun

fun! s:Region.update_highlight() dict
    "update the highlight match
    let r = self | let i = r.index

    let s:v.matches[i].pos1 = [r.l, r.a, r.w]
    let cursor = len(s:Matches) + i
    let s:v.matches[cursor].pos1 = [r.l, r.b, 1]
    call s:cursor_hl(r.a==r.b)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

