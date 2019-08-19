"script to handle compatibility issues with other plugins

let s:plugins = extend({
                \'ctrlsf':    {
                                \'ft': ['ctrlsf'],
                                \'maps': 'call ctrlsf#buf#ToggleMap(1)',
                                \'var': 'g:ctrlsf_loaded'},
                \'AutoPairs': {
                                \'maps': 'call AutoPairsInit()',
                                \'enable': 'let b:autopairs_enabled = 1',
                                \'disable': 'let b:autopairs_enabled = 0',
                                \'var': 'b:autopairs_enabled'}
                \}, get(g:, 'VM_plugins_compatibilty', {}))

let s:disabled_deoplete = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#init() abort
    """Set variables according to plugin needs."""
    let s:V = b:VM_Selection
    let s:v = s:V.Vars

    if exists('g:loaded_youcompleteme')
        let g:VM_use_first_cursor_in_line = 1
    endif

    for plugin in keys(s:plugins)
        let p = s:plugins[plugin]

        if !exists(p.var)
            continue

        elseif has_key(p, 'disable')
            if s:ftype(p)       | exe p.disable
            elseif s:noftype(p) | exe p.disable
            endif
        endif
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#TextChangedI() abort
    if exists('g:loaded_deoplete') && s:disabled_deoplete
        call deoplete#enable()
        let s:disabled_deoplete = 0
    elseif exists('b:ncm2_enable')
        let b:ncm2_enable = 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#icmds() abort
    if exists('g:loaded_deoplete') && g:deoplete#is_enabled()
        call deoplete#disable()
        let s:disabled_deoplete = 1
    elseif exists('b:ncm2_enable')
        let b:ncm2_enable = 0
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#conceallevel() abort
    return exists('b:indentLine_ConcealOptionSet') && b:indentLine_ConcealOptionSet
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#reset() abort
    if exists('g:loaded_deoplete') && s:disabled_deoplete
        call deoplete#enable()
        let s:disabled_deoplete = 0
    elseif exists('b:ncm2_enable')
        let b:ncm2_enable = 1
    endif

    "restore plugins functionality if necessary
    for plugin in keys(s:plugins)
        let p = s:plugins[plugin]

        if !exists(p.var)
            continue

        elseif has_key(p, 'maps')
            if s:ftype(p) || s:noftype(p) | exe p.maps | endif
        endif

        if has_key(p, 'enable')
            if s:ftype(p) || s:noftype(p) | exe p.enable | endif
        endif
    endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#exit() abort
    """Called last on VM exit."""
    if exists('*VM_Exit') | call VM_Exit() | endif
    silent doautocmd <nomodeline> User visual_multi_exit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#add_line() abort
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

fun! vm#comp#no_reindents() abort
    return g:VM_no_reindent_filetype + ['ctrlsf']
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:ftype(p) abort
    return has_key(a:p, 'ft') && index(a:p.ft, &ft) >= 0
endfun

fun! s:noftype(p) abort
    return !has_key(a:p, 'ft') || empty(a:p.ft)
endfun


" vim: et ts=4 sw=4 sts=4 :
