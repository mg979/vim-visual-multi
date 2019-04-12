fun! vm#block#init()
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    return s:Block
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:X         = { -> g:Vm.extend_mode }
    let s:R         = { -> s:V.Regions      }
    let s:B         = { -> s:v.block_mode && g:Vm.extend_mode }
else
    let s:R         = function('vm#v74#regions')
    let s:X         = function('vm#v74#extend_mode')
    let s:B         = function('vm#v74#block_mode')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Block = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.vertical() abort
    if !s:B() | call self.stop() | return | endif

    let s:v.block[3] = 1
    if s:v.direction
        if s:v.block[1] <= col('.') | let s:v.block[1] = col('.') | endif

    elseif s:v.block[1] >= col('.') | let s:v.block[1] = col('.') | endif

    call s:G.new_cursor()
    call s:G.update_and_select_region()
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Block.horizontal(before) abort
    if !s:B() | call self.stop() | return | endif

    "before motion
    if a:before
        let s:v.block[3] = 1
        let is_region = g:Vm.is_active && !empty(s:G.is_region_at_pos('.'))

        if !is_region         | call self.stop()
        elseif !s:v.block[0]  | let s:v.block[0] = col('.') | endif

    "-----------------------------------------------------------------------
    "after motion

    else
        let b0 = s:v.block[0] | let b1 = s:v.block[1]

        if col('.') < b0 | let s:v.block[0] = col('.')
        elseif col('.') < b1 | let s:v.block[1] = col('.') | endif

        "set minimum edge
        let bs = map(copy(s:R()), 'v:val.b')
        if count(bs, bs[0]) == len(bs) | let s:v.block[2] = s:v.block[0]
        else                           | let s:v.block[2] = min(bs) | endif
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

