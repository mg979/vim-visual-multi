""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Initialize variables

let s:NVIM                = has('gui_running') || has('nvim')

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
    let g:VM_case_setting                     = get(g:, 'VM_case_setting', 'smart')

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

fun! s:Select()
    if g:VM.selecting
        let g:VM.selecting = 0

        "find operator
        if b:VM_Selection.Vars.finding
            let b:VM_Selection.Vars.finding = 0
            call vm#commands#find_operator(0, 1)
        else
            "select operator
            call b:VM_Selection.Global.get_region()
            let R = b:VM_Selection.Global.select_region_at_pos('.')

            if R.h && !b:VM_Selection.Vars.multiline
                call b:VM_Selection.Funcs.toggle_option('multiline') | endif
        endif

        if g:VM.oldupdate | let &updatetime = g:VM.oldupdate | endif
        nmap <silent> <nowait> <buffer> y <Plug>(VM-Edit-Yank)
    endif
endfun

augroup plugin-visual-multi-start
    au!
    au VimEnter     * call <SID>VM_Init()
    au BufEnter     * let b:VM_Selection = {}
    if has('nvim')
        au TextYankPost * call <sid>Select()
    else
        au CursorMoved  * call <sid>Select()
        au CursorHold   * call <sid>Select()
    endif
augroup END
