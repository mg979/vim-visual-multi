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
