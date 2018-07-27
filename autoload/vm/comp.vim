"script to handle compatibility issues with other plugins

let s:plugins = {
                \'ctrlsf':    {
                                \'ft': 'ctrlsf',
                                \'func': 'call ctrlsf#buf#ToggleMap(1)',
                                \'var': 'g:ctrlsf_loaded'},
                \'AutoPairs': {
                                \'func': 'call AutoPairsInit()',
                                \'var': 'b:autopairs_enabled'},
                \}

fun! vm#comp#init()
    """Set variables according to plugin needs."""
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    if exists('g:loaded_youcompleteme')
        let g:VM_use_first_cursor_in_line = 1
    endif
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

    "restore plugins mappings if necessary
    for plugin in keys(s:plugins)
        let p = s:plugins[plugin]

        if !exists(p.var)
            continue

        elseif has_key(p, 'ft') && &ft == p.ft  "specific for plugin filetype
            exe p.func
            let oldmatches = s:v.oldmatches

        elseif !has_key(p, 'ft')
            exe p.func
        endif
    endfor
    return oldmatches
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
