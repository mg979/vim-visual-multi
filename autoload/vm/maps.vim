""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Initialize

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Maps = {}
let s:maps = {}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#init()
    let s:V = b:VM_Selection
    return s:Maps
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Global mappings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#default()
    """This function is run at vim start, or when mappings must be re-enabled.
    """Permanent mappings are loaded if they haven't been already.
    let s:maps = s:load_maps()
    if g:VM_s_mappings          | call s:assign(s:maps.permanent.s, 0) | endif
    if !g:VM_permanent_mappings | call vm#maps#permanent()             | endif
endfun


fun! vm#maps#permanent()
    """This function is run at vim start.
    if g:VM_sublime_mappings | call s:assign(s:maps.permanent.sublime, 0) | endif
    if g:VM_default_mappings | call s:assign(s:maps.permanent.default, 0) | endif
    if g:VM_mouse_mappings   | call s:assign(s:maps.permanent.mouse, 0)   | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Buffer maps init

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.mappings(activate, ...) dict
    let s:noremaps = g:VM_custom_noremaps
    let s:remaps   = g:VM_custom_remaps

    if a:activate && !g:VM.mappings_enabled
        let g:VM.mappings_enabled = 1
        call self.start()
        call vm#maps#default()
        for m in (g:VM.motions + g:VM.find_motions)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".m.")"
        endfor
        for m in keys(s:noremaps)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".s:noremaps[m].")"
        endfor
        for m in keys(s:remaps)
            exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Remap-Motion-".s:remaps[m].")"
        endfor

    elseif !a:activate && g:VM.mappings_enabled
        call self.end()
        call self.default_stop()
        let g:VM.mappings_enabled = 0
        for m in (g:VM.motions + g:VM.find_motions)
            exe "nunmap <buffer> ".m
        endfor
        for m in ( keys(s:noremaps) + keys(s:remaps) )
            exe "silent! nunmap <buffer> ".m
        endfor
    endif
endfun

fun! s:Maps.mappings_toggle() dict
    let activate = !g:VM.mappings_enabled
    call self.mappings(activate)
    call s:V.Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.start() dict

    if g:VM_sublime_mappings | call s:assign(s:maps.buffer.sublime, 1) | endif
    if g:VM_s_mappings       | call s:assign(s:maps.buffer.s, 1)       | endif

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)
    nnoremap <silent> <nowait> <buffer> n          n
    nnoremap <silent> <nowait> <buffer> N          N

    call s:assign(s:maps.buffer.basic, 1)
    call s:assign(s:maps.buffer.select, 1)
    call s:assign(s:maps.buffer.utility, 1)
    call s:assign(s:maps.buffer.commands, 1)
    call s:assign(s:maps.buffer.zeta, 1)
    call s:assign(s:maps.buffer.arrows, 1)
    call s:assign(s:maps.buffer.insert, 1, 'Insert-')
    call s:assign(s:maps.buffer.edit, 1, 'Edit-')

    "custom commands
    let cm = g:VM_custom_commands
    for m in keys(cm)
        exe "nmap <silent> <nowait> <buffer> ".cm[m][0]." <Plug>(VM-".m.")"
    endfor

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Buffer maps remove

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.end() dict
    if g:VM_sublime_mappings | call s:unmap(s:maps.buffer.sublime, 1) | endif
    if g:VM_s_mappings       | call s:unmap(s:maps.buffer.s, 1)       | endif
    call s:unmap(s:maps.buffer.basic, 1)
    call s:unmap(s:maps.buffer.select, 1)
    call s:unmap(s:maps.buffer.utility, 1)
    call s:unmap(s:maps.buffer.commands, 1)
    call s:unmap(s:maps.buffer.zeta, 1)
    call s:unmap(s:maps.buffer.arrows, 1)
    call s:unmap(s:maps.buffer.insert, 1)
    call s:unmap(s:maps.buffer.edit, 1)

    let cm = g:VM_custom_commands
    for m in keys(cm)
        exe "silent! nunmap <buffer>".cm[m][0]
    endfor

    nunmap <buffer> :
    nunmap <buffer> /
    nunmap <buffer> ?
    nunmap <buffer> n
    nunmap <buffer> N
    silent! cunmap <buffer> <cr>
    silent! cunmap <buffer> <esc>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.default_stop() dict

    if g:VM_s_mappings         | call s:unmap(s:maps.permanent.s, 0) | endif

    if g:VM_permanent_mappings | return | endif

    if g:VM_sublime_mappings | call s:unmap(s:maps.permanent.sublime, 0) | endif
    if g:VM_default_mappings | call s:unmap(s:maps.permanent.default, 0) | endif
    if g:VM_mouse_mappings   | call s:unmap(s:maps.permanent.mouse, 0)   | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Map dicts functions

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:load_maps()
    """Load the mappings dictionary and integrate custom mappings."""
    if g:VM.mappings_loaded | return s:maps | endif
    let g:VM.mappings_loaded = 1

    let g:VM_maps             = {
                \"utility"  : {},
                \"commands" : {},
                \"zeta"     : {},
                \"arrows"   : {},
                \"insert"   : {},
                \"edit"     : {},
                \"s"        : {},
                \"mouse"    : {},
                \"default"  : {},
                \"sublime"  : {},
                \"basic"    : {},
                \"select"   : {},
                \}

    if exists('*VM_init_maps') | call VM_init_maps() | endif
    let maps = {}

    let maps.permanent = vm#maps#all#permanent()
    for section in keys(g:VM_maps)
        for key in keys(g:VM_maps[section])
            silent! let maps.permanent[section][key][0] = g:VM_maps[section][key]
        endfor
    endfor

    let maps.buffer = vm#maps#all#buffer()
    for section in keys(g:VM_maps)
        for key in keys(g:VM_maps[section])
            silent! let maps.buffer[section][key][0] = g:VM_maps[section][key]
        endfor
    endfor

    return maps
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:assign(dict, buffer, ...)
    """Assign mappings from dictionary."""
    let M = a:dict
    for key in keys(M)
        let k = M[key][0]
        if empty(k) | continue | endif
        let p = (a:0? a:1 : '') . substitute(key, ' ', '-', 'g')
        let m = M[key][1]
        let _ = a:buffer? '<buffer>' : ''
        let _ .= M[key][2]? '<silent>' : ''
        let _ .= M[key][3]? '<nowait> ' : ' '
        exe m."map "._.k.' <Plug>(VM-'.p.")"
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:unmap(dict, buffer)
    """Unmap mappings from dictionary."""
    let M = a:dict
    for key in keys(M)
        let k = M[key][0]
        if empty(k) | continue | endif
        let m = M[key][1]
        let b = a:buffer? ' <buffer> ' : ' '
        exe "silent! "m."unmap".b.k
    endfor
endfun


