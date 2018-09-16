""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Initialize

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Maps = {}

fun! vm#maps#default()
    """At vim start, permanent mappings are generated and applied.
    let s:noremaps = g:VM_custom_noremaps
    let s:remaps   = g:VM_custom_remaps
    call s:build_permanent_maps()
    for m in g:VM.maps.permanent | exe m | endfor
endfun

fun! vm#maps#init()
    """At VM start, buffer mappings are generated (only once) and applied.
    let s:V = b:VM_Selection
    if !g:VM.mappings_loaded | call s:build_buffer_maps() | endif

    if !has('nvim') && !has('gui_running')
        nnoremap <silent> <nowait> <buffer> <esc><esc> <esc><esc>
    endif
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Space>    <Plug>(VM-Toggle-Mappings)

    return s:Maps
endfun

fun! vm#maps#reset()
    """At VM reset, last buffer mappings are reset, and permanent maps are restored.
    silent! nunmap <buffer> <Space>
    silent! nunmap <buffer> <esc>
    if !has('nvim') && !has('gui_running')
        silent! nunmap <buffer> <esc><esc>
    endif

    for m in g:VM.maps.permanent | exe m | endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Mappings activation/deactivation

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.mappings(activate, ...) dict
    """Extra arg is to reactivate permanent mappings, when disabling.
    if a:activate && !g:VM.mappings_enabled
        let g:VM.mappings_enabled = 1
        call self.start()

    elseif !a:activate && g:VM.mappings_enabled
        let g:VM.mappings_enabled = 0
        call self.end(a:0)
    endif
endfun

fun! s:Maps.mappings_toggle() dict
    let activate = !g:VM.mappings_enabled
    call self.mappings(activate, 1)
    call s:V.Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Apply mappings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.start() dict

    for m in g:VM.maps.permanent | exe m | endfor
    for m in g:VM.maps.buffer    | exe m | endfor

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)
    nnoremap <silent> <nowait> <buffer> n          n
    nnoremap <silent> <nowait> <buffer> N          N

    for m in (g:VM.motions + g:VM.find_motions)
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
    for m in g:VM.unmaps | exe m | endfor

    for m in (g:VM.motions + g:VM.find_motions)
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

    if a:keep_permanent
        for m in g:VM.maps.permanent | exe m | endfor
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Map dicts functions

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_permanent_maps()
    """Run at vim start. Generate permanent mappings and integrate custom ones.

    "init vars and generate base permanent maps dict
    let g:VM_maps   = get(g:, 'VM_maps', {})
    let g:VM.maps   = {'permanent': [], 'buffer': []}
    let g:VM.unmaps = []
    let g:VM.help   = {}
    let maps        = vm#maps#all#permanent()

    "prevent <Space> to be used as leader inside VM
    let g:VM.leader = get(g:, 'VM_leader', '')
    if !empty(g:VM.leader) && g:VM.leader !=? "\<Space>"
        let g:VM.leader = escape(g:VM.leader, '\')
    elseif !exists('g:mapleader') || g:mapleader ==? "\<Space>" || g:VM.leader ==? "\<Space>"
        let g:VM.leader = '\'
    else
        let g:VM.leader = g:mapleader
    endif

    "integrate custom maps
    for key in keys(g:VM_maps)
        silent! let maps[key][0] = g:VM_maps[key]
    endfor

    "generate list of 'exe' commands for map assignment
    for key in keys(maps)
        call add(g:VM.maps.permanent, s:assign(key, maps[key], 0))
    endfor

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(g:VM.unmaps, s:unmap(maps[key], 0))
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_buffer_maps()
    """Run at first VM start. Generate buffer mappings and integrate custom ones.
    let g:VM.mappings_loaded = 1

    "generate base buffer maps dict
    let maps = vm#maps#all#buffer()

    "integrate custom maps
    for key in keys(g:VM_maps)
        silent! let maps[key][0] = g:VM_maps[key]
    endfor

    "generate list of 'exe' commands for map assignment
    for key in keys(maps)
        call add(g:VM.maps.buffer, s:assign(key, maps[key], 1))
    endfor

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(g:VM.unmaps, s:unmap(maps[key], 1))
    endfor

    "extra help plugs
    let g:VM.help['Toggle Mappings'] = '<Space>'
    let g:VM.help['Exit VM'] = '<Esc>'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:assign(plug, key, buffer, ...)
    """Create a map command that will be executed."""
    let k = a:key[0]
    if empty(k) | return '' | endif

    if !empty(g:VM.leader)
        let k = substitute(k, '<leader>', g:VM.leader, '')
    endif

    let g:VM.help[a:plug] = k
    let p = substitute(a:plug, ' ', '-', 'g')
    let m = a:key[1]
    let _ = a:buffer? '<buffer>' : ''
    let _ .= a:key[2]? '<silent>' : ''
    let _ .= a:key[3]? '<nowait> ' : ' '
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


