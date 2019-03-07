""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Initialize

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Maps = {}

fun! vm#maps#default()
    """At vim start, permanent mappings are generated and applied.
    let s:noremaps = g:VM_custom_noremaps
    let s:remaps   = g:VM_custom_remaps
    call s:build_permanent_maps()
    for m in g:Vm.maps.permanent | exe m | endfor
endfun

fun! vm#maps#init()
    """At VM start, buffer mappings are generated (once per buffer) and applied.
    let s:V = b:VM_Selection
    if !b:VM_mappings_loaded | call s:build_buffer_maps() | endif

    call s:map_esc_and_toggle()
    call s:check_warnings()
    return s:Maps
endfun

fun! vm#maps#reset()
    """At VM reset, last buffer mappings are reset, and permanent maps are restored.
    call s:unmap_esc_and_toggle()
    for m in g:Vm.maps.permanent | exe m | endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Mappings activation/deactivation

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.enable() dict
    if !g:Vm.mappings_enabled
        let g:Vm.mappings_enabled = 1
        call self.start()
    endif
endfun

fun! s:Maps.disable(keep_permanent) dict
    if g:Vm.mappings_enabled
        let g:Vm.mappings_enabled = 0
        call self.end(a:keep_permanent)
    endif
endfun

fun! s:Maps.mappings_toggle() dict
    if g:Vm.mappings_enabled
        call self.disable(1)
    else
        call self.enable()
    endif
    call s:V.Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Apply mappings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.start() dict

    for m in g:Vm.maps.permanent | exe m | endfor
    for m in g:Vm.maps.buffer    | exe m | endfor

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)
    nnoremap <silent> <nowait> <buffer> n          n
    nnoremap <silent> <nowait> <buffer> N          N

    for m in (g:Vm.motions + g:Vm.find_motions)
        exe "nmap <silent> <buffer> ".m." <Plug>(VM-Motion-".m.")"
    endfor
    for m in keys(s:noremaps)
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Motion-".s:noremaps[m].")"
    endfor
    for m in keys(s:remaps)
        exe "nmap <silent> <nowait> <buffer> ".m." <Plug>(VM-Remap-Motion-".s:remaps[m].")"
    endfor

    "custom commands
    let cm = g:VM_custom_commands
    for m in keys(cm)
        exe "nmap <silent> <nowait> <buffer> ".cm[m][0]." <Plug>(VM-".m.")"
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Remove mappings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.end(keep_permanent) dict
    for m in g:Vm.unmaps | exe m | endfor

    for m in (g:Vm.motions + g:Vm.find_motions)
        exe "nunmap <buffer> ".m
    endfor

    for m in ( keys(s:noremaps) + keys(s:remaps) )
        exe "silent! nunmap <buffer> ".m
    endfor

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

    " restore permanent mappings
    if a:keep_permanent
        for m in g:Vm.maps.permanent | exe m | endfor
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Map helper functions

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_permanent_maps()
    """Run at vim start. Generate permanent mappings and integrate custom ones.

    "set default VM leader
    let leader = get(g:, 'mapleader', '\')
    let g:Vm.leader = get(g:, 'VM_leader', leader.leader)

    "init vars and generate base permanent maps dict
    let g:VM_maps   = get(g:, 'VM_maps', {})
    let g:Vm.maps   = {'permanent': [], 'buffer': []}
    let g:Vm.unmaps = []
    let g:Vm.help   = {}
    let maps        = vm#maps#all#permanent()

    "integrate custom maps
    for key in keys(g:VM_maps)
        silent! let maps[key][0] = g:VM_maps[key]
    endfor

    "generate list of 'exe' commands for map assignment
    for key in keys(maps)
        let mapping = s:assign(key, maps[key], 0)
        if !empty(mapping)
            call add(g:Vm.maps.permanent, mapping)
        endif
    endfor

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(g:Vm.unmaps, s:unmap(maps[key], 0))
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_buffer_maps()
    """Run once per buffer. Generate buffer mappings and integrate custom ones.
    let b:VM_mappings_loaded = 1
    let check_maps = get(b:, 'VM_check_mappings', g:VM_check_mappings)
    let force_maps = get(b:, 'VM_force_maps', get(g:, 'VM_force_maps', []))

    "generate base buffer maps dict
    let maps = vm#maps#all#buffer()

    "integrate custom maps
    for key in keys(g:VM_maps)
        silent! let maps[key][0] = g:VM_maps[key]
    endfor

    "generate list of 'exe' commands for map assignment
    for key in keys(maps)
        let mapping = s:assign(key, maps[key], 1, check_maps, force_maps)
        if !empty(mapping)
            call add(g:Vm.maps.buffer, mapping)
        endif
    endfor

    "store the key used to toggle mappings
    let g:Vm.maps.toggle = has_key(g:VM_maps, 'Toggle Mappings') ?
          \ g:VM_maps['Toggle Mappings'] : g:Vm.leader.'<Space>'

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(g:Vm.unmaps, s:unmap(maps[key], 1))
    endfor

    "extra help plugs
    let g:Vm.help['Toggle Mappings'] = g:Vm.maps.toggle
    let g:Vm.help['Exit Vm'] = '<Esc>'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:assign(plug, key, buffer, ...)
    """Create a map command that will be executed."""
    let k = a:key[0] | if empty(k) | return '' | endif
    let m = a:key[1]

    "check if the mapping can be applied: this only runs for buffer mappings
    "a:1 is a bool that is true if mappings must be checked
    "a:2 can contain a list of mappings that will be applied anyway (forced)
    "otherwise, if a buffer mapping already exists, the remapping fails, and
    "a debug line is added
    if a:0 && a:1 && index(a:2, k) < 0
        let K = maparg(k, m, 0, 1)
        if !empty(K) && K.buffer
            let b = 'b'.bufnr('%').': '
            let s = b.'Could not map: '.k.' ('.a:plug.')  ->  ' . K.rhs
            call add(b:VM_Debug.lines, s)
            return ''
        endif
    endif

    let g:Vm.help[a:plug] = k
    let p = substitute(a:plug, ' ', '-', 'g')
    let _ = a:buffer? '<buffer><nowait> ' : '<nowait> '
    return m."map "._.k.' <Plug>(VM-'.p.")"
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:unmap(key, buffer)
    """Create an unmap command that will be executed."""
    let k = a:key[0]
    if empty(k) | return '' | endif
    let m = a:key[1]
    let b = a:buffer? ' <buffer> ' : ' '
    return "silent! ".m."unmap".b.k
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:map_esc_and_toggle() abort
    if !has('nvim') && !has('gui_running')
        nnoremap <nowait><buffer> <esc><esc> <esc><esc>
    endif
    nmap <nowait><buffer> <esc> <Plug>(VM-Reset)
    exe 'nmap <nowait><buffer>' g:Vm.maps.toggle '<Plug>(VM-Toggle-Mappings)'
endfun

fun! s:unmap_esc_and_toggle() abort
    silent! exe 'nunmap <buffer>' g:Vm.maps.toggle
    silent! nunmap <buffer> <esc>
    if !has('nvim') && !has('gui_running')
        silent! nunmap <buffer> <esc><esc>
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:check_warnings() abort
    """Notify once per buffer if errors have happened.
    if !empty(b:VM_Debug.lines) && !has_key(b:VM_Debug, 'maps_warning')
        let b:VM_Debug.maps_warning = 1
        call s:V.Funcs.msg('VM has started with warnings. :VM_Debug for more info', 1)
    endif
endfun

