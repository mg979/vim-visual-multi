""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim 7.4 compatibilty functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#v74#regions() abort
    return b:VM_Selection.Regions
endfun

fun! vm#v74#extend_mode() abort
    return g:Vm.extend_mode
endfun

fun! vm#v74#block_mode() abort
    return g:Vm.is_active && b:VM_Selection.Vars.block_mode && g:Vm.extend_mode
endfun

fun! vm#v74#group() abort
    return b:VM_Selection.Groups[b:VM_Selection.Vars.active_group]
endfun

fun! vm#v74#only_this() abort
    return b:VM_Selection.Vars.only_this || b:VM_Selection.Vars.only_this_always
endfun

fun! vm#v74#is_r() abort
    return g:Vm.is_active && !empty(b:VM_Selection.Global.is_region_at_pos('.'))
endfun

fun! vm#v74#first_line() abort
    return line('.') == 1
endfun

fun! vm#v74#last_line() abort
    return line('.') == line('$')
endfun

fun! vm#v74#RS() abort
    return b:VM_Selection.Global.regions()
endfun

fun! vm#v74#can_from_back() abort
    return vm#v74#extend_mode() && b:VM_Selection.Vars.motion == '$' && !b:VM_Selection.Vars.direction
endfun

fun! vm#v74#always_from_back() abort
    return vm#v74#extend_mode() && index(['^', '0', 'F', 'T'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#symbol() abort
    return index(['^', '0', '%', '$'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#horizontal() abort
    return index(['h', 'l'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#vertical() abort
    return index(['j', 'k'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#simple(m) abort
    return index(split('hlwebWEB', '\zs'), a:m) >= 0
endfun

fun! vm#v74#forw(c) abort
  return index(split('weWE%', '\zs'), a:c) >= 0
endfun

fun! vm#v74#back(c) abort
  return index(split('FThbB0N^{(', '\zs'), a:c[0]) >= 0
endfun

fun! vm#v74#ia(c) abort
  return index(['i', 'a'], a:c) >= 0
endfun

fun! vm#v74#single(c) abort
  return index(split('hljkwebWEB$^0{}()%nN', '\zs'), a:c) >= 0
endfun

fun! vm#v74#double(c) abort
  return index(split('iafFtTg', '\zs'), a:c) >= 0
endfun


" vim: et ts=4 sw=4 sts=4 :
