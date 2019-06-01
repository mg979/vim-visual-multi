""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize global variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:VM_live_editing                     = get(g:, 'VM_live_editing', 1)

let g:VM_custom_commands                  = get(g:, 'VM_custom_commands', {})
let g:VM_commands_aliases                 = get(g:, 'VM_commands_aliases', {})
let g:VM_debug                            = get(g:, 'VM_debug', 0)
let g:VM_reselect_first_insert            = get(g:, 'VM_reselect_first_insert', 0)
let g:VM_reselect_first_always            = get(g:, 'VM_reselect_first_always', 0)
let g:VM_case_setting                     = get(g:, 'VM_case_setting', 'smart')
let g:VM_use_first_cursor_in_line         = get(g:, 'VM_use_first_cursor_in_line', 0)
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


fun! vm#init_buffer(empty, ...) abort
    """If already initialized, return current instance."""
    try
        if exists('b:VM_Selection') && !empty(b:VM_Selection) | return s:V | endif

        let b:VM_Selection = {'Vars': {}, 'Regions': [], 'Groups': {}}

        let b:VM_mappings_loaded = get(b:, 'VM_mappings_loaded', 0)
        let b:VM_Debug           = get(b:, 'VM_Debug', {'lines': []})
        let b:VM_Backup          = {'ticks': [], 'last': 0, 'first': undotree().seq_cur}

        " funcs script must be sourced first
        let s:V            = b:VM_Selection
        let s:v            = s:V.Vars
        let s:V.Funcs      = vm#funcs#init()

        " init plugin variables
        call vm#variables#init()
        let @/ = a:empty ? '' : @/

        " call hook before applying mappings
        if exists('*VM_Start') | call VM_Start() | endif

        " init classes
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

        " set vim variables
        call vm#variables#set()

        if !empty(g:VM_highlight_matches)
            if !has_key(g:Vm, 'Search')
                call vm#themes#init()
            endif
            hi clear Search
            exe g:Vm.Search
        endif

        if !v:hlsearch && !a:empty
            let s:v.oldhls = 1
            call feedkeys("\<Plug>(VM-Toggle-Hls)")
        else
            let s:v.oldhls = 0
        endif

        if empty(b:VM_Debug.lines) && !g:VM_manual_infoline
            call s:V.Funcs.msg("Visual-Multi started. Press <esc> to exit.", 0)
        endif

        " backup sync settings for the buffer
        if !exists('b:VM_sync_minlines')
            let b:VM_sync_minlines = s:V.Funcs.sync_minlines()
        endif

        command! -bang -nargs=1 VMSmartChange
                    \ if <bang>0 | let s:v.smart_case_change = 0 |
                    \ else | let s:v.smart_case_change = function(<q-args>) | endif

        let g:Vm.is_active = 1
        return s:V
    catch
        let b:VM_Backup = {}
        let b:VM_Selection = {}
        let g:Vm.is_active = 0
        let g:Vm.extend_mode = 0
        let g:Vm.selecting = 0
    endtry
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#reset(...)
    call vm#variables#reset()

    if s:v.oldhls
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
    delcommand VMSmartChange
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#augroup(end) abort
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

fun! vm#au_cursor(end) abort
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

fun! s:cursor_moved() abort
    if s:v.block_mode
        if !s:v.block[3]
            call s:V.Block.stop()
            call s:V.Funcs.count_msg(1)
        else
            let s:v.block[3] = 0
        endif

    elseif !s:v.eco
        " if currently on a region, set the index to this region
        " so that it's possible to select next/previous from it
        let r = s:V.Global.is_region_at_pos('.')
        if !empty(r) | let s:v.index = r.index | endif
    endif
endfun

fun! s:buffer_leave() abort
    if !empty(get(b:, 'VM_Selection', {})) && !b:VM_Selection.Vars.insert
        call vm#reset(1)
    endif
endfun

fun! s:buffer_enter() abort
    if empty(get(b:, 'VM_Selection', {}))
        let b:VM_Selection = {}
    endif
endfun

fun! s:set_reg() abort
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

fun! s:vm_regs() abort
    if !g:VM_persistent_registers | return | endif

    let is_win = has('win32') || has('win64') || has('win16')
    let sep    = is_win ? '\' : '/'
    let vmfile = is_win ? '_VM_registers' : '.VM_registers'
    let home   = !empty(get(g:, 'VM_vimhome', '')) ? g:VM_vimhome :
                \ exists('$VIMHOME')               ? $VIMHOME :
                \ is_win                           ? '~/vimfiles' : "~/.vim"

    let g:Vm.regs_file = home.sep.vmfile
    if isdirectory(home) && !filereadable(g:Vm.regs_file)
        call writefile(['{}'], g:Vm.regs_file)
    endif
endfun

fun! s:vm_regs_from_json() abort
    if !g:VM_persistent_registers || !filereadable(g:Vm.regs_file)
        return {'"': []}
    endif
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
" vim: et ts=4 sw=4 sts=4 :
