""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim 7.4 compatibilty functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#v74#regions()
    return b:VM_Selection.Regions
endfun

fun! vm#v74#extend_mode()
    return g:Vm.extend_mode
endfun

fun! vm#v74#size()
    return line2byte(line('$'))
endfun

fun! vm#v74#block_mode()
    return g:Vm.is_active && b:VM_Selection.Vars.block_mode && g:Vm.extend_mode
endfun

fun! vm#v74#group()
    return b:VM_Selection.Groups[b:VM_Selection.Vars.active_group]
endfun

fun! vm#v74#only_this()
    return b:VM_Selection.Vars.only_this || b:VM_Selection.Vars.only_this_always
endfun

fun! vm#v74#is_r()
    return g:Vm.is_active && !empty(b:VM_Selection.Global.is_region_at_pos('.'))
endfun

fun! vm#v74#first_line()
    return line('.') == 1
endfun

fun! vm#v74#last_line()
    return line('.') == line('$')
endfun

fun! vm#v74#RS()
    return b:VM_Selection.Global.regions()
endfun

fun! vm#v74#can_from_back()
    return vm#v74#extend_mode() && b:VM_Selection.Vars.motion == '$' && !b:VM_Selection.Vars.direction
endfun

fun! vm#v74#always_from_back()
    return vm#v74#extend_mode() && index(['^', '0', 'F', 'T'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#symbol()
    return index(['^', '0', '%', '$'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#horizontal()
    return index(['h', 'l'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#vertical()
    return index(['j', 'k'], b:VM_Selection.Vars.motion) >= 0
endfun

fun! vm#v74#simple(m)
    return index(split('hlwebWEB', '\zs'), a:m) >= 0
endfun

fun! vm#v74#forw(c)
  return index(split('weWE%', '\zs'), a:c) >= 0
endfun

fun! vm#v74#back(c)
  return index(split('FThbB0N^{(', '\zs'), a:c[0]) >= 0
endfun

fun! vm#v74#ia(c)
  return index(['i', 'a'], a:c) >= 0
endfun

fun! vm#v74#single(c)
  return index(split('hljkwebWEB$^0{}()%nN', '\zs'), a:c) >= 0
endfun

fun! vm#v74#double(c)
  return index(split('iafFtTg', '\zs'), a:c) >= 0
endfun


