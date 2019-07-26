fun! vm#block#init() abort
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    return s:Block
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X         = { -> g:Vm.extend_mode }
let s:R         = { -> s:V.Regions      }
let s:B         = { -> s:v.block_mode && g:Vm.extend_mode }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Block = {}

" s:v.block:
"   [0]  virtcol() for left edge
"   [1]  virtcol() for right edge
"   [2]  minimum edge for all regions
"   [3]  state boolean: checked by CursorMoved autocommand

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.vertical() abort
    if !s:B() | return self.stop() | endif
    let vcol = virtcol('.')

    let s:v.block[3] = 1
    if s:v.direction
        if s:v.block[1] <= vcol | let s:v.block[1] = vcol | endif

    elseif s:v.block[1] >= vcol | let s:v.block[1] = vcol
    endif

    call s:G.new_cursor()
    call s:G.merge_regions()
    call s:G.select_region_at_pos('.')
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.horizontal(before) abort
    if !s:B() | return self.stop() | endif
    let vcol = virtcol('.')

    "-----------------------------------------------------------------------
    "before motion

    if a:before
        let s:v.block[3] = 1
        let is_region = !empty(s:G.is_region_at_pos('.'))

        if !is_region         | call self.stop()
        elseif !s:v.block[0]  | let s:v.block[0] = vcol
        endif

        "-----------------------------------------------------------------------
        "after motion

    else
        let [ b0, b1 ] = [ s:v.block[0], s:v.block[1] ]

        if vcol < b0      | let s:v.block[0] = vcol
        elseif vcol < b1  | let s:v.block[1] = vcol
        endif

        "set minimum edge
        let bs = map(copy(s:R()), 'v:val.b')
        if count(bs, bs[0]) == len(bs) | let s:v.block[2] = s:v.block[0]
        else                           | let s:v.block[2] = min(bs)
        endif
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.positions(r, new, back, forth) abort
    let r = a:r | let new = a:new

    if !r.dir && a:back
        let r.a = new
        let r.b = r.k
        let s:v.block[0] = r.a

    elseif a:back
        let r.a = s:v.block[0]
        let r.b = r.a

    elseif a:forth
        let r.b = new
        let r.a = r.k

    elseif r.dir
        let r.b = new>s:v.block[2]? new : s:v.block[2]
    else
        let r.a = new
    endif
    call r.update_region()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.start() abort
    if s:v.eco | return | endif
    call s:G.extend_mode()

    let s:v.block_mode = 1
    if s:v.only_this_always | call s:V.Funcs.toggle_option('only_this_always') | endif
    if s:v.index != -1
        let r = s:G.is_region_at_pos('.')
        if empty(r) | let r = s:R()[-1] | endif
        let s:v.block[0] = r.a
        let s:v.block[1] = r.b
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.stop() abort
    if s:v.eco | return | endif

    let s:v.block_mode = 0
    let s:v.block = [0,0,0,0]
endfun

" vim: et ts=4 sw=4 sts=4 :
