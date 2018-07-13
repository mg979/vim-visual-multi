""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Initialize variables

let g:loaded_visual_multi = 1
let b:VM_Selection        = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! <SID>VM_Init()

    let g:VM = {}

    let g:VM.is_active        = 0
    let g:VM.extend_mode      = 0
    let g:VM.selecting        = 0
    let g:VM.mappings_enabled = 0
    let g:VM.last_ex          = ''
    let g:VM.last_normal      = ''
    let g:VM.last_visual      = ''
    let g:VM.oldupdate        = has('nvim')? 0 : &updatetime
    let g:VM.registers        = {'"': []}

    let g:VM_live_editing                     = get(g:, 'VM_live_editing', 1)
    let g:VM_default_mappings                 = get(g:, 'VM_default_mappings', 1)
    let g:VM_sublime_mappings                 = get(g:, 'VM_sublime_mappings', 1)
    let g:VM_mouse_mappings                   = get(g:, 'VM_mouse_mappings', 0)
    let g:VM_permanent_mappings               = get(g:, 'VM_permanent_mappings', 1)
    let g:VM_s_mappings                       = get(g:, 'VM_s_mappings', 0)
    let g:VM_custom_mappings                  = get(g:, 'VM_custom_mappings', 0)

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
    let g:VM_dynamic_synmaxcol                = get(g:, 'VM_dynamic_synmaxcol', 20)

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Reindentation after insert mode

    let g:VM_reindent_all_filetypes           = get(g:, 'VM_reindent_all_filetypes', 0)
    let g:VM_reindent_filetype                = get(g:, 'VM_reindent_filetype', [])
    let g:VM_no_reindent_filetype             = get(g:, 'VM_no_reindent_filetype', ['text', 'markdown'])

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Set up highlighting

    let g:VM_Selection_hl                     = get(g:, 'VM_Selection_hl',     'Visual')
    let g:VM_Mono_Cursor_hl                   = get(g:, 'VM_Mono_Cursor_hl',   'DiffChange')
    let g:VM_Ins_Mode_hl                      = get(g:, 'VM_Ins_Mode_hl',      'Pmenu')
    let g:VM_Normal_Cursor_hl                 = get(g:, 'VM_Normal_Cursor_hl', 'DiffAdd')
    let g:VM_Message_hl                       = get(g:, 'VM_Message_hl',       'WarningMsg')

    exe "highlight link MultiCursor ".g:VM_Normal_Cursor_hl

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    "Global mappings

    call vm#plugs#init()
    call vm#maps#default()
    if g:VM_permanent_mappings
        call vm#maps#permanent()
    endif
endfun

augroup plugin-visual-multi-start
    au!
    au VimEnter     * call <SID>VM_Init()
    au BufEnter     * let b:VM_Selection = {}
    if has('nvim')
        au TextYankPost * call vm#operators#after_yank()
    else
        au CursorMoved  * call vm#operators#after_yank()
        au CursorHold   * call vm#operators#after_yank()
    endif
augroup END

if !has('python3') | finish | endif

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
