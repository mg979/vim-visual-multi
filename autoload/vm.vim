""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" b:VM_Selection (= s:V) contains Regions, Vars (= s:v = plugin variables),
" function classes (Global, Funcs, Edit, Search, Insert, etc)

fun! vm#init_buffer(empty, ...)
    """If already initialized, return current instance."""

    if exists('b:VM_Selection') && !empty(b:VM_Selection) | return s:V | endif

    let b:VM_Selection = {'Vars': {}, 'Regions': [], 'Funcs':  {}, 'Block': {}, 'Bytes': '',
                \ 'Edit': {}, 'Global':  {}, 'Search': {}, 'Maps':  {}, 'Groups': {}
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
    let s:v.oldregs_1_9      = s:V.Funcs.get_regs_1_9()
    let s:v.oldsearch        = [getreg("/"), getregtype("/")]
    let @/                   = a:empty? '' : @/

    "store old vars
    let s:v.oldvirtual       = &virtualedit
    let s:v.oldwhichwrap     = &whichwrap
    let s:v.oldlz            = &lz
    let s:v.oldch            = &ch
    let s:v.oldhls           = &hls
    let s:v.oldcase          = [&smartcase, &ignorecase]
    let s:v.indentkeys       = &indentkeys
    let s:v.synmaxcol        = &synmaxcol
    let s:v.oldmatches       = getmatches()
    let s:v.clipboard        = &clipboard

    "init new vars

    "block: [ left edge, right edge, min edge for all regions, au var ]

    let s:v.block            = [0,0,0,0]
    let s:v.search           = []
    let s:v.IDs_list         = []
    let s:v.ID               = 0
    let s:v.active_group     = 0
    let s:v.index            = -1
    let s:v.direction        = 1
    let s:v.nav_direction    = 1
    let s:v.auto             = 0
    let s:v.silence          = 0
    let s:v.eco              = 0
    let s:v.only_this        = 0
    let s:v.only_this_always = 0
    let s:v.using_regex      = 0
    let s:v.multiline        = 0
    let s:v.block_mode       = 0
    let s:v.vertical_col     = 0
    let s:v.yanked           = 0
    let s:v.merge            = 0
    let s:v.insert           = 0
    let s:v.whole_word       = 0
    let s:v.winline          = 0
    let s:v.restore_scroll   = 0
    let s:v.find_all_overlap = 0
    let s:v.multi_find       = 0
    let s:v.dot              = ''
    let s:v.no_search        = 0
    let s:v.no_msg           = g:VM_manual_infoline
    let s:v.visual_regex     = 0

    let s:V.Global     = vm#global#init()
    let s:V.Search     = vm#search#init()
    let s:V.Edit       = vm#edit#init()
    let s:V.Insert     = vm#insert#init()
    let s:V.Block      = vm#block#init()
    let s:V.Case       = vm#special#case#init()

    call s:V.Maps.mappings(1)
    call vm#region#init()
    call vm#commands#init()
    call vm#operators#init()
    call vm#comp#init()
    call vm#special#commands#init()

    call vm#augroup(0)
    call vm#au_cursor(0)

    " disable folding, but keep winline
    if &foldenable
        call s:V.Funcs.Scroll.get(1)
        let s:v.oldfold = 1
        set nofoldenable
        call s:V.Funcs.Scroll.restore()
    endif

    if g:VM_case_setting ==? 'smart'
        set smartcase
        set ignorecase
    elseif g:VM_case_setting ==? 'sensitive'
        set nosmartcase
        set noignorecase
    else
        set nosmartcase
        set ignorecase
    endif

    "force use of unnamed register
    set clipboard=

    set virtualedit=onemore
    set ww=h,l,<,>
    set lz
    set nofoldenable
    let &ch = get(g:, 'VM_cmdheight', 2)

    if !empty(g:VM_highlight_matches)
        if !has_key(g:VM, 'Search')
            call vm#themes#init()
        endif
        hi clear Search
        exe g:VM.Search
    endif
    if !g:VM_manual_infoline
        call s:V.Funcs.msg("Visual-Multi started. Press <esc> to exit.", 0)
    endif

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
    let &hls         = s:v.oldhls
    let &synmaxcol   = s:v.synmaxcol
    let &indentkeys  = s:v.indentkeys
    let &clipboard   = s:v.clipboard
    call vm#commands#regex_reset()
    call s:V.Global.remove_highlight()
    call s:V.Funcs.save_vm_regs()
    call s:V.Funcs.restore_regs()
    call s:V.Maps.mappings(0)
    call vm#maps#reset()
    let matches = vm#comp#reset()
    call vm#augroup(1)
    call vm#au_cursor(1)

    " reenable folding, but keep winline and open current fold
    if exists('s:v.oldfold')
        call s:V.Funcs.Scroll.get(1)
        normal! zizv
        call s:V.Funcs.Scroll.restore()
    endif

    let b:VM_Selection = {}
    let g:VM.is_active = 0
    let g:VM.extend_mode = 0
    let g:VM.selecting = 0

    "exiting manually
    if !a:0 | call s:V.Funcs.msg('Exited Visual-Multi.', 1) | endif

    if !empty(g:VM_highlight_matches)
        hi clear Search
        exe "hi! Search ".g:VM.search_hi
    endif

    if !empty(matches)
        call setmatches(matches)
    endif
    call garbagecollect()
    call vm#comp#exit()
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

        if has('nvim') || has('patch-8.0.1394')
            au TextYankPost * if s:v.yanked | call <SID>set_reg() | endif
        else
            au CursorMoved  * if s:v.yanked | call <SID>set_reg() | endif
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

fun! s:VM_cursor_moved()
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
    if !empty(get(b:, 'VM_Selection', {})) && !b:VM_Selection.Vars.insert
        call vm#reset(1)
    endif
endfun

fun! s:buffer_enter()
    if empty(get(b:, 'VM_Selection', {}))
        let b:VM_Selection = {}
    endif
endfun

fun! s:set_reg()
    "Replace old default register if yanking in VM outside a region or cursor
    let s:v.yanked = 0
    let g:VM.registers['"'] = []
    let s:v.oldreg = s:V.Funcs.get_reg(v:register)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"python section

if !has('python3')
    let g:VM_use_python = 0
    finish
endif

let g:VM_use_python = get(g:, 'VM_use_python', !has('nvim'))
if !g:VM_use_python | finish | endif

let s:root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

python3 << EOF
import sys
from os.path import normpath, join
import vim
root_dir = vim.eval('s:root_dir')
python_root_dir = normpath(join(root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)
import vm
EOF
