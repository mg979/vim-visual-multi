"script to handle compatibility issues with other plugins

let s:plugins = extend({
            \'ctrlsf':    {
            \   'test': { -> &ft == 'ctrlsf' },
            \   'enable': 'call ctrlsf#buf#ToggleMap(1)',
            \   'disable': 'call ctrlsf#buf#ToggleMap(0)',
            \},
            \'AutoPairs': {
            \   'test': { -> exists('b:autopairs_enabled') && b:autopairs_enabled },
            \   'enable': 'unlet b:autopairs_loaded | call AutoPairsTryInit() | let b:autopairs_enabled = 1',
            \   'disable': 'let b:autopairs_enabled = 0',
            \},
            \'smartinput': {
            \   'test': { -> exists('g:loaded_smartinput') && g:loaded_smartinput == 1 },
            \   'enable': 'unlet! b:smartinput_disabled',
            \   'disable': 'let b:smartinput_disabled = 1',
            \},
            \'tagalong': {
            \   'test': { -> exists('b:tagalong_initialized') },
            \   'enable': 'TagalongInit',
            \   'disable': 'TagalongDeinit'
            \},
            \}, get(g:, 'VM_plugins_compatibilty', {}))

let s:disabled_deoplete = 0
let s:disabled_ncm2     = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#comp#init() abort
    " Set variables according to plugin needs. "{{{1
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:v.disabled_plugins = []

    silent! call VM_Start()
    silent doautocmd <nomodeline> User visual_multi_start

    if exists('g:loaded_youcompleteme')
        let g:VM_use_first_cursor_in_line = 1
    endif

    if exists('b:doge_interactive')
        call doge#deactivate()
    endif

    for plugin in keys(s:plugins)
        let p = s:plugins[plugin]

        if p.test()
            exe p.disable
            call add(s:v.disabled_plugins, plugin)
        endif
    endfor
endfun "}}}


fun! vm#comp#icmds() abort
    " Insert mode starts: temporarily disable autocompletion engines. {{{1
    if exists('g:loaded_deoplete') && g:deoplete#is_enabled()
        call deoplete#disable()
        let s:disabled_deoplete = 1
    elseif exists('b:ncm2_enable') && b:ncm2_enable
        let b:ncm2_enable = 0
        let s:disabled_ncm2 = 1
    endif
endfun "}}}


fun! vm#comp#TextChangedI() abort
    " Insert mode change: re-enable autocompletion engines. {{{1
    if exists('g:loaded_deoplete') && s:disabled_deoplete
        call deoplete#enable()
        let s:disabled_deoplete = 0
    elseif s:disabled_ncm2
        let b:ncm2_enable = 1
        let s:disabled_ncm2 = 0
    endif
endfun "}}}


fun! vm#comp#conceallevel() abort
    " indentLine compatibility. {{{1
    return exists('b:indentLine_ConcealOptionSet') && b:indentLine_ConcealOptionSet
endfun "}}}


fun! vm#comp#iobj() abort
    " Inner text objects that should avoid using the select operator. {{{1
    return exists('g:loaded_targets') ? ['q'] : []
endfun "}}}


fun! vm#comp#reset() abort
    " Called during VM exit. "{{{1
    if exists('g:loaded_deoplete') && s:disabled_deoplete
        call deoplete#enable()
        let s:disabled_deoplete = 0
    elseif s:disabled_ncm2
        let b:ncm2_enable = 1
        let s:disabled_ncm2 = 0
    endif

    "restore plugins functionality if necessary
    for plugin in keys(s:plugins)
        if index(s:v.disabled_plugins, plugin) >= 0
            exe s:plugins[plugin].enable
        endif
    endfor
endfun "}}}


fun! vm#comp#exit() abort
    " Called last on VM exit. "{{{1
    silent! call VM_Exit()
    silent doautocmd <nomodeline> User visual_multi_exit
endfun "}}}


fun! vm#comp#add_line() abort
    " Ensure a line is added with these text objects, while changing in cursor mode. "{{{1

    let l = []
    if exists('g:loaded_textobj_indent')
        let l += ['ii', 'ai', 'iI', 'aI']
    endif
    if exists('g:loaded_textobj_function')
        let l += ['if', 'af', 'iF', 'aF']
    endif
    return l
endfun "}}}


fun! vm#comp#no_reindents() abort
    " Don't reindent for filetypes. "{{{1
    return ['ctrlsf']
endfun "}}}

" vim: et sw=4 ts=4 sts=4 fdm=marker
