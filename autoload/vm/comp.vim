"script to handle compatibility issues with other plugins

let s:plugins = extend({
                \'ctrlsf':    {
                                \'ft': ['ctrlsf'],
                                \'maps': 'call ctrlsf#buf#ToggleMap(1)',
                                \'matches': 1,
                                \'var': 'g:ctrlsf_loaded'},
                \'AutoPairs': {
                                \'maps': 'call AutoPairsInit()',
                                \'enable': 'let b:autopairs_enabled = 1',
                                \'disable': 'let b:autopairs_enabled = 0',
                                \'var': 'b:autopairs_enabled'}
                \}, get(g:, 'VM_plugins_compatibilty', {}))

"specific for plugin filetype
let s:ftype           = { p -> has_key(p, 'ft') && index(p.ft, &ft) >= 0 }
let s:noftype         = { p -> !has_key(p, 'ft') || empty(p.ft) }
let s:restore_matches = { p -> s:v.clearmatches && has_key(p, 'matches') && p.matches }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#init()
    """Set variables according to plugin needs."""
    let s:V = b:VM_Selection
    let s:v = s:V.Vars

    if exists('g:loaded_youcompleteme')
        let g:VM_use_first_cursor_in_line = 1
    endif

    call s:check_clearmatches()

    for plugin in keys(s:plugins)
        let p = s:plugins[plugin]

        if !exists(p.var)
            continue

        elseif has_key(p, 'disable')
            if s:ftype(p)       | exe p.disable
            elseif s:noftype(p) | exe p.disable | endif
        endif
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#TextChangedI()
    if exists('g:loaded_deoplete')
        call deoplete#custom#buffer_option('auto_complete', v:true)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#icmds()
    if exists('g:loaded_deoplete')
        call deoplete#custom#buffer_option('auto_complete', v:false)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#reset()
    let oldmatches = []
    if exists('g:loaded_deoplete')
        call deoplete#custom#buffer_option('auto_complete', v:true)
    endif

    "restore plugins functionality if necessary
    for plugin in keys(s:plugins)
        let p = s:plugins[plugin]

        if !exists(p.var)
            continue

        elseif has_key(p, 'maps')
            if s:ftype(p) || s:noftype(p) | exe p.maps | endif
        endif

        if s:restore_matches(p)
            if s:ftype(p) || s:noftype(p) | let oldmatches = s:v.oldmatches | endif
        endif

        if has_key(p, 'enable')
            if s:ftype(p) || s:noftype(p) | exe p.enable | endif
        endif
    endfor
    return oldmatches
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#exit()
    """Called last on VM exit."""
    call s:restore_indentLine()
    if exists('*VM_Exit') | call VM_Exit() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#add_line()
    """Ensure a line is added with these text objects, while changing in cursor mode.

    let l = []
    if exists('g:loaded_textobj_indent')
        let l += ['ii', 'ai', 'iI', 'aI']
    endif
    if exists('g:loaded_textobj_function')
        let l += ['if', 'af', 'iF', 'aF']
    endif
    return l
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" don't reindent for filetypes

fun! vm#comp#no_reindents()
    return g:VM_no_reindent_filetype + ['ctrlsf']
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" indentLine plugin

fun! s:check_clearmatches()
    let il = exists('g:indentLine_loaded') &&
                \ exists('b:indentLine_ConcealOptionSet') &&
                \ b:indentLine_ConcealOptionSet
    let s:v.clearmatches = get(g:, 'VM_clear_buffer_hl', !il)
    if il && s:v.clearmatches
        let b:VM_indentLine = 1
    endif
endfun

fun! s:restore_indentLine()
    if exists('b:VM_indentLine')
        IndentLinesEnable
        unlet b:VM_indentLine
    endif
endfun
