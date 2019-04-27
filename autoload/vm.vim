""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize global variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:VM_live_editing                     = get(g:, 'VM_live_editing', 1)

let g:VM_skip_empty_lines                 = get(g:, 'VM_skip_empty_lines', 0)
let g:VM_custom_commands                  = get(g:, 'VM_custom_commands', {})
let g:VM_commands_aliases                 = get(g:, 'VM_commands_aliases', {})
let g:VM_debug                            = get(g:, 'VM_debug', 0)
let g:VM_reselect_first_insert            = get(g:, 'VM_reselect_first_insert', 0)
let g:VM_reselect_first_always            = get(g:, 'VM_reselect_first_always', 0)
let g:VM_case_setting                     = get(g:, 'VM_case_setting', 'smart')
let g:VM_use_first_cursor_in_line         = get(g:, 'VM_use_first_cursor_in_line', 0)
let g:VM_autoremove_empty_lines           = get(g:, 'VM_autoremove_empty_lines', 0)
let g:VM_pick_first_after_n_cursors       = get(g:, 'VM_pick_first_after_n_cursors', 0)
let g:VM_disable_syntax_in_imode          = get(g:, 'VM_disable_syntax_in_imode', 0)
let g:VM_dynamic_synmaxcol                = get(g:, 'VM_dynamic_synmaxcol', 0)
let g:VM_exit_on_1_cursor_left            = get(g:, 'VM_exit_on_1_cursor_left', 0)
let g:VM_manual_infoline                  = get(g:, 'VM_manual_infoline', 1)
let g:VM_overwrite_vim_registers          = get(g:, 'VM_overwrite_vim_registers', 0)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Reindentation after insert mode

let g:VM_reindent_all_filetypes           = get(g:, 'VM_reindent_all_filetypes', 0)
let g:VM_reindent_filetype                = get(g:, 'VM_reindent_filetype', [])
let g:VM_no_reindent_filetype             = get(g:, 'VM_no_reindent_filetype', ['text', 'markdown'])

call vm#themes#init()
call vm#plugs#buffer()




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" b:VM_Selection (= s:V) contains Regions, Vars (= s:v = plugin variables),
" function classes (Global, Funcs, Edit, Search, Insert, etc)


fun! vm#init_buffer(empty, ...)
    """If already initialized, return current instance."""

    if exists('b:VM_Selection') && !empty(b:VM_Selection) | return s:V | endif

    let b:VM_Selection = {'Vars': {}, 'Regions': [], 'Funcs':  {}, 'Block': {}, 'Bytes': '',
                \ 'Edit': {}, 'Global':  {}, 'Search': {}, 'Maps':  {}, 'Groups': {}
                        \}

    let b:VM_mappings_loaded = get(b:, 'VM_mappings_loaded', 0)
    let b:VM_Debug           = get(b:, 'VM_Debug', {'lines': []})
    let b:VM_Backup          = {'ticks': [], 'last': 0, 'first': undotree().seq_cur}

    "init classes
    let s:V            = b:VM_Selection
    let s:v            = s:V.Vars
    let s:Regions      = s:V.Regions

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
    let s:v.oldhls           = v:hlsearch
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
    let s:v.dot              = ''
    let s:v.no_search        = 0
    let s:v.no_msg           = g:VM_manual_infoline
    let s:v.visual_regex     = 0

    " call hook before applying mappings
    if exists('*VM_Start') | call VM_Start() | endif

    let s:V.Maps       = vm#maps#init()
    let s:V.Global     = vm#global#init()
    let s:V.Search     = vm#search#init()
    let s:V.Edit       = vm#edit#init()
    let s:V.Insert     = vm#insert#init()
    let s:V.Block      = vm#block#init()
    let s:V.Case       = vm#special#case#init()

    call s:V.Maps.enable()
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
    if !g:VM_manual_infoline
      let &ch = get(g:, 'VM_cmdheight', 2)
    endif

    if !empty(g:VM_highlight_matches)
        if !has_key(g:Vm, 'Search')
            call vm#themes#init()
        endif
        hi clear Search
        exe g:Vm.Search
    endif

    if !v:hlsearch && !a:empty
      call feedkeys("\<Plug>(VM-Toggle-Hls)")
    endif

    if empty(b:VM_Debug.lines) && !g:VM_manual_infoline
        call s:V.Funcs.msg("Visual-Multi started. Press <esc> to exit.", 0)
    endif

    let g:Vm.is_active = 1
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
    let &synmaxcol   = s:v.synmaxcol
    let &indentkeys  = s:v.indentkeys
    let &clipboard   = s:v.clipboard

    if !s:v.oldhls
      call feedkeys("\<Plug>(VM-Toggle-Hls)")
    endif

    call vm#commands#regex_reset()
    call s:V.Global.remove_highlight()
    call s:V.Funcs.save_vm_regs()
    call s:V.Funcs.restore_regs()
    call s:V.Maps.disable(1)
    silent! call s:V.Insert.auto_end()

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

    let b:VM_Backup = {}
    let b:VM_Selection = {}
    let g:Vm.is_active = 0
    let g:Vm.extend_mode = 0
    let g:Vm.selecting = 0

    "exiting manually
    if !a:0 | call s:V.Funcs.msg('Exited Visual-Multi.', 1) | endif

    if !empty(g:VM_highlight_matches)
        hi clear Search
        exe g:Vm.search_hi
    endif

    if g:Vm.oldupdate && &updatetime != g:Vm.oldupdate
      let &updatetime = g:Vm.oldupdate
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
        autocmd! VM_global
        augroup! VM_global
        return
    endif

    augroup VM_global
        au!
        au BufLeave     * call s:buffer_leave()
        au BufEnter     * call s:buffer_enter()

        if exists("##TextYankPost")
            au TextYankPost * call s:set_reg()
            au TextYankPost * call vm#operators#after_yank()
        else
            au CursorMoved  * call s:set_reg()
            au CursorMoved  * call vm#operators#after_yank()
            au CursorHold   * call vm#operators#after_yank()
        endif
    augroup END
endfun

fun! vm#au_cursor(end)
    if a:end
        autocmd! VM_cursormoved
        augroup! VM_cursormoved
        return
    endif

    augroup VM_cursormoved
        au!
        au CursorMoved * call s:cursor_moved()
    augroup END
endfun

fun! s:cursor_moved()
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
    if s:v.yanked
      let s:v.yanked = 0
      let g:Vm.registers['"'] = []
      let s:v.oldreg = s:V.Funcs.get_reg(v:register)
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"VM registers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:VM_persistent_registers = get(g:, 'VM_persistent_registers', 0)

fun! s:vm_regs()
    if !g:VM_persistent_registers | return | endif

    let is_win = has('win32') || has('win64') || has('win16')
    let sep    = is_win ? '\' : '/'
    let vmfile = is_win ? '_VM_registers' : '.VM_registers'
    let home   = !empty(get(g:, 'VM_vimhome', '')) ? g:VM_vimhome :
               \ exists('$VIMHOME')                ? $VIMHOME :
               \ is_win                            ? '~/vimfiles' : "~/.vim"

    let g:Vm.regs_file = home.sep.vmfile
    if isdirectory(home) && !filereadable(g:Vm.regs_file)
        call writefile(['{}'], g:Vm.regs_file)
    endif
endfun

fun! s:vm_regs_from_json()
    if !g:VM_persistent_registers || !filereadable(g:Vm.regs_file)
        return {'"': []} | endif
    let regs = json_decode(readfile(g:Vm.regs_file)[0])
    let regs['"'] = []
    return regs
endfun

call s:vm_regs()
let g:Vm.registers = s:vm_regs_from_json()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"python section
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
