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
    """At VM start, buffer mappings are generated (only once) and applied.
    let s:V = b:VM_Selection
    if !g:Vm.mappings_loaded | call s:build_buffer_maps() | endif

    if !has('nvim') && !has('gui_running')
        nnoremap <silent> <nowait> <buffer> <esc><esc> <esc><esc>
    endif
    nmap     <silent><nowait><buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent><nowait><buffer> <Space>    <Plug>(VM-Toggle-Mappings)

    return s:Maps
endfun

fun! vm#maps#reset()
    """At VM reset, last buffer mappings are reset, and permanent maps are restored.
    silent! nunmap <buffer> <Space>
    silent! nunmap <buffer> <esc>
    if !has('nvim') && !has('gui_running')
        silent! nunmap <buffer> <esc><esc>
    endif

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

" Map dicts functions

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_permanent_maps()
    """Run at vim start. Generate permanent mappings and integrate custom ones.

    "prevent <Space> to be used as leader inside VM
    let g:Vm.leader = get(g:, 'VM_leader', '')
    if !empty(g:Vm.leader) && g:Vm.leader !=? "\<Space>"
        let g:Vm.leader = escape(g:Vm.leader, '\')
    elseif !exists('g:mapleader') || g:mapleader ==? "\<Space>" || g:Vm.leader ==? "\<Space>"
        let g:Vm.leader = '\'
    else
        let g:Vm.leader = g:mapleader
    endif

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
        call add(g:Vm.maps.permanent, s:assign(key, maps[key], 0))
    endfor

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(g:Vm.unmaps, s:unmap(maps[key], 0))
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_buffer_maps()
    """Run at first VM start. Generate buffer mappings and integrate custom ones.
    let g:Vm.mappings_loaded = 1

    "generate base buffer maps dict
    let maps = vm#maps#all#buffer()

    "integrate custom maps
    for key in keys(g:VM_maps)
        silent! let maps[key][0] = g:VM_maps[key]
    endfor

    "generate list of 'exe' commands for map assignment
    for key in keys(maps)
        call add(g:Vm.maps.buffer, s:assign(key, maps[key], 1))
    endfor

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(g:Vm.unmaps, s:unmap(maps[key], 1))
    endfor

    "extra help plugs
    let g:Vm.help['Toggle Mappings'] = '<Space>'
    let g:Vm.help['Exit Vm'] = '<Esc>'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:assign(plug, key, buffer, ...)
    """Create a map command that will be executed."""
    let k = a:key[0]
    if empty(k) | return '' | endif

    if !empty(g:Vm.leader)
        let k = substitute(k, '<leader>', g:Vm.leader, '')
    endif

    let g:Vm.help[a:plug] = k
    let p = substitute(a:plug, ' ', '-', 'g')
    let m = a:key[1]
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


