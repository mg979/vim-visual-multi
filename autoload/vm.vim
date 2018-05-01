""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global holds the Global class methods
" s:Regions contains the regions with their contents
" s:v.matches contains the current matches as read with getmatches()

fun! vm#init_buffer(empty, ...)
    """If already initialized, return current instance."""

    if !empty(b:VM_Selection) | return s:V | endif

    let b:VM_Selection = {'Vars': {}, 'Regions': [], 'Funcs':  {}, 'Block': {}, 'Bytes': '',
                        \ 'Edit': {}, 'Global':  {}, 'Search': {}, 'Maps':  {},
                        \}

    let s:V            = b:VM_Selection

    "init classes
    let s:v            = s:V.Vars
    let s:Regions      = s:V.Regions

    let s:V.Maps       = vm#maps#init()
    let s:V.Funcs      = vm#funcs#init()

    "init search
    let s:v.def_reg          = s:V.Funcs.default_reg()
    let s:v.oldreg           = s:V.Funcs.get_reg()
    let s:v.oldsearch        = [getreg("/"), getregtype("/")]
    let @/                   = a:empty? '' : @/

    "store old vars
    let s:v.oldvirtual       = &virtualedit
    let s:v.oldwhichwrap     = &whichwrap
    let s:v.oldlz            = &lz
    let s:v.oldch            = &ch
    let s:v.oldcase          = [&smartcase, &ignorecase]

    "init new vars

    "block: [ left edge, right edge, min edge for all regions, au var ]

    let s:v.block            = [0,0,0,0]
    let s:v.search           = []
    let s:v.IDs_list         = []
    let s:v.ID               = 0
    let s:v.index            = -1
    let s:v.direction        = 1
    let s:v.auto             = 0
    let s:v.silence          = 0
    let s:v.eco              = 0
    let s:v.moving           = 0
    let s:v.only_this        = 0
    let s:v.only_this_always = 0
    let s:v.using_regex      = 0
    let s:v.multiline        = 0
    let s:v.block_mode       = 0
    let s:v.vertical_col     = 0
    let s:v.yanked           = 0
    let s:v.merge            = 0

    let s:V.Search     = vm#search#init()
    let s:V.Global     = vm#global#init()
    let s:V.Edit       = vm#edit#init()
    let s:V.Insert     = vm#insert#init()
    let s:V.Live       = vm#live#init()
    let s:V.Block      = vm#block#init()

    call s:V.Maps.mappings(1)
    call vm#region#init()

    call vm#augroup(0)
    call vm#au_cursor(0)

    set virtualedit=onemore
    set ww=h,l,<,>
    set lz
    if !has('nvim')
        set ch=3
    endif

    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Space>    <Plug>(VM-Toggle-Mappings)

    call s:V.Funcs.msg("Visual-Multi started. Press <esc> to exit.\n", 0)

    let g:VM.is_active = 1
    return s:V
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#reset(...)
    let &virtualedit = s:v.oldvirtual
    let &whichwrap   = s:v.oldwhichwrap
    let &smartcase   = s:v.oldcase[0]
    let &ignorecase  = s:v.oldcase[1]
    let &lz          = s:v.oldlz
    let &ch          = s:v.oldch
    call s:V.Funcs.restore_regs()
    call s:V.Maps.mappings(0, 1)
    call vm#maps#default()
    call vm#augroup(1)
    call vm#au_cursor(1)
    let b:VM_Selection = {}
    let g:VM.is_active = 0
    let g:VM.extend_mode = 0
    let s:v.silence = 0

    nunmap <buffer> <Space>
    nunmap <buffer> <esc>

    "exiting manually
    if !a:0 | call s:V.Funcs.msg('Exited Visual-Multi.', 1) | endif

    call clearmatches()
    set nohlsearch
    call garbagecollect()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#augroup(end)
    if a:end
        augroup plugin-visual-multi-global
            au!
        augroup END
        return
    endif

    augroup plugin-visual-multi-global
        au!
        au BufLeave     * call s:buffer_leave()
        au BufEnter     * call s:buffer_enter()

        if has('nvim')
            au TextYankPost * if s:v.yanked     | call <SID>set_reg()                   | endif
        else
            au CursorMoved  * if s:v.yanked     | call <SID>set_reg()                   | endif
        endif
    augroup END
endfun

fun! vm#au_cursor(end)
    if a:end
        augroup plugin-vm-cursormoved
            au!
        augroup END
        return
    endif

    augroup plugin-vm-cursormoved
        au!
        au CursorMoved * call <SID>VM_cursor_moved()
    augroup END
endfun

fun! <SID>VM_cursor_moved()
    if s:v.block_mode
        if !s:v.block[3]
            call s:V.Block.stop()
            call s:V.Funcs.count_msg(1)
        else
            let s:v.block[3] = 0
        endif
    endif
endfun

fun! s:buffer_leave()
    if !empty(get(b:, 'VM_Selection', {}))
        call vm#reset(1)
    endif
endfun

fun! s:buffer_enter()
    let b:VM_Selection = {}
endfun

fun! <SID>set_reg()
    "Replace old default register if yanking in VM outside a region or cursor
    let s:v.yanked = 0
    let g:VM.registers['"'] = []
    let s:v.oldreg = s:V.Funcs.get_reg(v:register)
endfun
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

