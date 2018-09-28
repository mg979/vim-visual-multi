""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:         visual-multi.vim
" Description:  multiple selections in vim
" Mantainer:    Gianmaria Bajo <mg1979.git@gmail.com>
" Url:          https://github.com/mg979/vim-visual-multi
" Licence:      The MIT License (MIT)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Initialize variables

let g:loaded_visual_multi = 1
let b:VM_Selection        = {}

com!                                                  VMConfig call vm#special#config#start()
com! -nargs=? -complete=customlist,vm#themes#complete VMTheme  call vm#themes#load(<q-args>)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! <SID>VM_Init()

    let g:VM = { 'hi': {} }

    let g:VM.is_active        = 0
    let g:VM.extend_mode      = 0
    let g:VM.selecting        = 0
    let g:VM.mappings_enabled = 0
    let g:VM.mappings_loaded  = 0
    let g:VM.last_ex          = ''
    let g:VM.last_normal      = ''
    let g:VM.last_visual      = ''
    let g:VM.oldupdate        = has('nvim')? 0 : &updatetime

    let g:VM_live_editing                     = get(g:, 'VM_live_editing', 1)
    let g:VM_default_mappings                 = get(g:, 'VM_default_mappings', 1)
    let g:VM_sublime_mappings                 = get(g:, 'VM_sublime_mappings', 0)
    let g:VM_mouse_mappings                   = get(g:, 'VM_mouse_mappings', 0)
    let g:VM_permanent_mappings               = get(g:, 'VM_permanent_mappings', 1)
    let g:VM_extended_mappings                = get(g:, 'VM_extended_mappings', 0)

    let g:VM_custom_noremaps                  = get(g:, 'VM_custom_noremaps', {})
    let g:VM_custom_remaps                    = get(g:, 'VM_custom_remaps', {})
    let g:VM_extend_by_default                = get(g:, 'VM_extend_by_default', 0)
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
    let g:VM_dynamic_synmaxcol                = get(g:, 'VM_dynamic_synmaxcol', 20)
    let g:VM_no_meta_mappings                 = get(g:, 'VM_no_meta_mappings', has('nvim') || has('gui_running') ? 0 : 1)
    let g:VM_leader_mappings                  = get(g:, 'VM_leader_mappings', 1)
    let g:VM_exit_on_1_cursor_left            = get(g:, 'VM_exit_on_1_cursor_left', 0)
    let g:VM_manual_infoline                  = get(g:, 'VM_manual_infoline', 0)
    let g:VM_persistent_registers             = get(g:, 'VM_persistent_registers', 0)
    let g:VM_overwrite_vim_registers          = get(g:, 'VM_overwrite_vim_registers', 0)
    let g:VM_highlight_matches                = get(g:, 'VM_highlight_matches', '')

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Reindentation after insert mode

    let g:VM_reindent_all_filetypes           = get(g:, 'VM_reindent_all_filetypes', 0)
    let g:VM_reindent_filetype                = get(g:, 'VM_reindent_filetype', [])
    let g:VM_no_reindent_filetype             = get(g:, 'VM_no_reindent_filetype', ['text', 'markdown'])

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Set up highlighting

    let g:VM.hi.extend                        = get(g:, 'VM_Selection_hl',     'Visual')
    let g:VM.hi.mono                          = get(g:, 'VM_Mono_Cursor_hl',   'DiffChange')
    let g:VM.hi.insert                        = get(g:, 'VM_Ins_Mode_hl',      'Pmenu')
    let g:VM.hi.cursor                        = get(g:, 'VM_Normal_Cursor_hl', 'ToolbarLine')
    let g:VM.hi.message                       = get(g:, 'VM_Message_hl',       'WarningMsg')

    exe "highlight link MultiCursor ".g:VM.hi.cursor

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Global mappings

    call vm#themes#init()
    call vm#plugs#init()
    call vm#maps#default()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Registers

    call s:vm_regs()
    let g:VM.registers = s:vm_regs_from_json()
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands

augroup plugin-visual-multi-start
    au!
    au VimEnter     * call <SID>VM_Init()
    au ColorScheme  * call vm#themes#init()
    if has('nvim')
        au TextYankPost * call vm#operators#after_yank()
    else
        au CursorMoved  * call vm#operators#after_yank()
        au CursorHold   * call vm#operators#after_yank()
    endif
augroup END


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"VM registers

fun! s:vm_regs()
    if !g:VM_persistent_registers | return | endif

    let is_win = has('win32') || has ('win64')
    let sep    = is_win ? '\' : '/'
    let vmfile = is_win ? '_VM_registers' : '.VM_registers'
    let home   = !empty(get(g:, 'VM_vimhome', '')) ? g:VM_vimhome :
               \ exists('$VIMHOME')                ? $VIMHOME :
               \ is_win                            ? '~/vimfiles' : "~/vim"

    let g:VM.regs_file = home.sep.vmfile
    if isdirectory(home) && !filereadable(g:VM.regs_file)
        call writefile(['{}'], g:VM.regs_file)
    endif
endfun

fun! s:vm_regs_from_json()
    if !g:VM_persistent_registers || !filereadable(g:VM.regs_file)
        return {'"': []} | endif
    let regs = json_decode(readfile(g:VM.regs_file)[0])
    let regs['"'] = []
    return regs
endfun

