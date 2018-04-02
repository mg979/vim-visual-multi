""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" A new region will only been created if not already existant

" g:Regions contains the regions with their contents
" g:VisualMatches contains the matches as they are registered with matchaddpos()

fun! cursors#regions#new()

    let obj = {}
    let obj.l = getpos("'[")[1]       " line
    let obj.a = getpos("'[")[2]       " begin
    let obj.b = getpos("']")[2]       " end
    let obj.w = obj.b - obj.a + 1     " width
    let obj.txt = getreg(cursors#misc#default_reg())

    let region = [obj.l, obj.a, obj.w]

    let index = index(g:Regions, obj)
    if index == -1
        let match = matchaddpos('Selection', [region], 30)
        call add(g:VisualMatches, match)
        call add(g:Regions, obj)
    endif
    return index
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
