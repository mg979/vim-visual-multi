"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Maps = {}

let g:VM_custom_noremaps   = get(g:, 'VM_custom_noremaps', {})
let g:VM_custom_remaps     = get(g:, 'VM_custom_remaps', {})
let g:VM_custom_motions    = get(g:, 'VM_custom_motions', {})
let g:VM_check_mappings    = get(g:, 'VM_check_mappings', 1)
let g:VM_default_mappings  = get(g:, 'VM_default_mappings', 1)
let g:VM_mouse_mappings    = get(g:, 'VM_mouse_mappings', 0)


fun! vm#maps#default() abort
    " At vim start, permanent mappings are generated and applied.
    call s:build_permanent_maps()
    for m in g:Vm.maps.permanent | exe m | endfor
endfun


fun! vm#maps#init() abort
    " At VM start, buffer mappings are generated (once per buffer) and applied.
    let s:V = b:VM_Selection
    if !exists('b:VM_maps') | call s:build_buffer_maps() | endif

    call s:Maps.map_esc_and_toggle()
    call s:check_warnings()
    return s:Maps
endfun


fun! vm#maps#reset() abort
    " At VM reset, last buffer mappings are reset, and permanent maps are restored.
    call s:Maps.unmap_esc_and_toggle()
    for m in g:Vm.maps.permanent | exe m | endfor
endfun




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings activation/deactivation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.enable() abort
    " Enable mappings in current buffer.
    if !g:Vm.mappings_enabled
        let g:Vm.mappings_enabled = 1
        call self.start()
    endif
endfun


fun! s:Maps.disable(keep_permanent) abort
    " Disable mappings in current buffer.
    if g:Vm.mappings_enabled
        let g:Vm.mappings_enabled = 0
        call self.end(a:keep_permanent)
    endif
endfun


fun! s:Maps.mappings_toggle() abort
    " Toggle mappings in current buffer.
    if g:Vm.mappings_enabled
        call self.disable(1)
    else
        call self.enable()
    endif
endfun




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Apply mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.start() abort
    " Apply mappings in current buffer.
    for m in g:Vm.maps.permanent | exe m | endfor
    for m in b:VM_maps           | exe m | endfor

    nmap              <nowait> <buffer> :          <Plug>(VM-:)
    nmap              <nowait> <buffer> /          <Plug>(VM-/)
    nmap              <nowait> <buffer> ?          <Plug>(VM-?)

    " user autocommand after mappings have been set
    silent doautocmd <nomodeline> User visual_multi_mappings
endfun


fun! s:Maps.map_esc_and_toggle() abort
    " Esc and 'toggle' keys are handled separately.
    if !has('nvim') && !has('gui_running')
        nnoremap <nowait><buffer> <esc><esc> <esc><esc>
    endif
    exe 'nmap <nowait><buffer>' g:Vm.maps.exit '<Plug>(VM-Exit)'
    exe 'nmap <nowait><buffer>' g:Vm.maps.toggle '<Plug>(VM-Toggle-Mappings)'
endfun




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remove mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Maps.end(keep_permanent) abort
    " Remove mappings in current buffer.
    for m in g:Vm.unmaps | exe m | endfor
    for m in b:VM_unmaps | exe m | endfor

    nunmap <buffer> :
    nunmap <buffer> /
    nunmap <buffer> ?
    silent! cunmap <buffer> <cr>
    silent! cunmap <buffer> <esc>

    " restore permanent mappings
    if a:keep_permanent
        for m in g:Vm.maps.permanent | exe m | endfor
    endif
endfun


fun! s:Maps.unmap_esc_and_toggle() abort
    " Esc and 'toggle' keys are handled separately.
    silent! exe 'nunmap <buffer>' g:Vm.maps.toggle
    silent! exe 'nunmap <buffer>' g:Vm.maps.exit
    if !has('nvim') && !has('gui_running')
        silent! nunmap <buffer> <esc><esc>
    endif
endfun




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:build_permanent_maps() abort
    " Run at vim start. Generate permanent mappings and integrate custom ones.

    "set default VM leader
    let ldr = get(g:, 'VM_leader', '\\')
    let g:Vm.leader = type(ldr) == v:t_string
                \ ? {'default': ldr, 'visual': ldr, 'buffer': ldr}
                \ : extend({'default':'\\', 'visual':'\\', 'buffer':'\\'}, ldr)

    "init vars and generate base permanent maps
    let g:VM_maps   = get(g:, 'VM_maps', {})
    let g:Vm.maps   = {'permanent': []}
    let g:Vm.unmaps = []
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


fun! s:build_buffer_maps() abort
    " Run once per buffer. Generate buffer mappings and integrate custom ones.
    let b:VM_maps   = []
    let b:VM_unmaps = []
    let check_maps  = get(b:, 'VM_check_mappings', g:VM_check_mappings)
    let force_maps  = get(b:, 'VM_force_maps', get(g:, 'VM_force_maps', []))

    "generate base buffer maps
    let maps = vm#maps#all#buffer()

    "integrate motions
    for m in (g:Vm.motions + g:Vm.find_motions)
        let maps['Motion ' . m] = [m, 'n']
    endfor
    for m in keys(g:Vm.tobj_motions)
        let maps['Motion ' . g:Vm.tobj_motions[m]] = [m, 'n']
    endfor
    for op in keys(g:Vm.user_ops)
        " don't map the operator if it starts with a key that would interfere
        " with VM operations in extend mode, eg. if 'cx' gets mapped, then 'c'
        " will not work as it should (it would have a delay in extend mode)
        if index(['y', 'c', 'd'], op[:0]) == -1
            let maps['User Operator ' . op] = [op, 'n']
        endif
    endfor

    "integrate custom motions and commands
    for m in keys(g:VM_custom_motions)
        let maps['Motion ' . g:VM_custom_motions[m]] = [m, 'n']
    endfor
    for m in keys(g:VM_custom_noremaps)
        let maps['Normal! ' . g:VM_custom_noremaps[m]] = [m, 'n']
    endfor
    for m in keys(g:VM_custom_remaps)
        let maps['Remap ' . g:VM_custom_remaps[m]] = [m, 'n']
    endfor
    for m in keys(g:VM_custom_commands)
        let maps[m] = [m, 'n']
    endfor

    "integrate custom remappings
    for key in keys(g:VM_maps)
        silent! let maps[key][0] = g:VM_maps[key]
    endfor

    "generate list of 'exe' commands for map assignment
    for key in keys(maps)
        let mapping = s:assign(key, maps[key], 1, check_maps, force_maps)
        if !empty(mapping)
            call add(b:VM_maps, mapping)
        else
            " remove the mapping, so that it won't be unmapped either
            unlet maps[key]
        endif
    endfor

    "store the key used to toggle mappings
    let g:Vm.maps.toggle = has_key(g:VM_maps, 'Toggle Mappings') ?
                \ g:VM_maps['Toggle Mappings'] : g:Vm.leader.buffer . '<Space>'
    let g:Vm.maps.exit   = has_key(g:VM_maps, 'Exit') ?
                \ g:VM_maps['Exit'] : '<Esc>'

    "generate list of 'exe' commands for unmappings
    for key in keys(maps)
        call add(b:VM_unmaps, s:unmap(maps[key], 1))
    endfor
endfun


fun! s:assign(plug, key, buffer, ...) abort
    " Create a map command that will be executed.
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
            " Handle Neovim mappings with Lua functions as rhs
            let rhs = has_key(K, 'rhs') ? K.rhs : '<Lua callback>'
            if m != 'i'
                let s = b.'Could not map: '.k.' ('.a:plug.')  ->  ' . rhs
                call add(b:VM_Debug.lines, s)
                return ''
            else
                let s = b.'Overwritten imap: '.k.' ('.a:plug.')  ->  ' . rhs
                call add(b:VM_Debug.lines, s)
            endif
        endif
    endif

    let p = substitute(a:plug, ' ', '-', 'g')
    let _ = a:buffer? '<buffer><nowait> ' : '<nowait> '
    return m."map "._.k.' <Plug>(VM-'.p.")"
endfun


fun! s:unmap(key, buffer) abort
    " Create an unmap command that will be executed.
    let k = a:key[0]
    if empty(k) | return '' | endif
    let m = a:key[1]
    let b = a:buffer? ' <buffer> ' : ' '
    return "silent! ".m."unmap".b.k
endfun


fun! s:check_warnings() abort
    " Notify once per buffer if errors have happened.
    if get(g:, 'VM_show_warnings', 1) && !empty(b:VM_Debug.lines)
                \ && !has_key(b:VM_Debug, 'maps_warning')
        let b:VM_Debug.maps_warning = 1
        call s:V.Funcs.msg('VM has started with warnings. :VMDebug for more info')
    endif
endfun

" vim: et ts=4 sw=4 sts=4 fdm=indent fdn=1 :
