""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {'skip_index': -1}

fun! vm#edit#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R         = {      -> s:V.Regions                       }
    let s:X         = {      -> g:VM.extend_mode                  }
    let s:size      = {      -> line2byte(line('$') + 1)          }
    let s:Byte      = { pos  -> s:F.pos2byte(pos)                 }
    let s:Pos       = { byte -> s:F.byte2pos(byte)                }

    let s:v.use_register = s:v.def_reg
    let s:v.new_text     = ''
    let s:v.old_text     = ''
    let s:v.W            = []
    let s:v.storepos     = []
    let s:v.insert_marks = {}
    let s:v.extra_spaces = []
    let s:change         = 0
    let s:can_multiline  = 0

    call vm#icmds#init()
    return extend(s:Edit, vm#ecmds1#init())
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_normal(cmd, recursive, count, maps, ...) dict

    "-----------------------------------------------------------------------

    if a:cmd == -1
        let cmd = input('Normal command? ')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif a:cmd == '~' && s:X()
        call self.run_visual('~', 0)        | return

    elseif empty(a:cmd)
        call s:F.msg('No last command.', 1) | return

    else | let cmd = a:cmd | endif

    "-----------------------------------------------------------------------

    let c = a:count>1? a:count : ''
    let s:cmd = a:recursive? ("normal ".c.cmd) : ("normal! ".c.cmd)
    if s:X() | call s:G.change_mode() | endif

    call self.before_macro(a:maps)

    if a:cmd ==? 'x' | call s:bs_del(a:cmd)
    elseif a:0       | call self._process(0, a:1)
    else             | call self._process(s:cmd) | endif

    let g:VM.last_normal = [cmd, a:recursive]
    call self.after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_visual(cmd, recursive, ...) dict

    "-----------------------------------------------------------------------

    if !a:0 && a:cmd == -1
        let cmd = input('Visual command? ')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif empty(a:cmd)
        call s:F.msg('Command not found.', 1) | return

    elseif !a:0
        let cmd = a:cmd | endif

    "-----------------------------------------------------------------------

    call self.before_macro(!a:recursive)
    call self.process_visual(cmd)

    let g:VM.last_visual = [cmd, a:recursive]
    call self.after_macro(0)
    if s:X() | call s:G.change_mode() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex(count, ...) dict

    "-----------------------------------------------------------------------

    if !a:0
        let cmd = input('Ex command? ', '', 'command')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif !empty(a:1)
        let cmd = a:1
    else
        call s:F.msg('Command not found.', 1) | return | endif

    "-----------------------------------------------------------------------

    if has_key(g:VM_commands_aliases, cmd)
        let cmd = g:VM_commands_aliases[cmd]
    endif

    let g:VM.last_ex = cmd
    if s:X() | call s:G.change_mode() | endif

    call self.before_macro(1)
    for n in range(a:count)
        call self._process(cmd)
    endfor
    call self.after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro(replace) dict
    if s:count(v:count) | return | endif

    call s:F.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:F.msg('Macro aborted.', 0)
        return | endif

    let s:cmd = "@".reg
    call self.before_macro(1)

    if s:X() | call s:G.change_mode() | endif

    call self.process()
    call self.after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Dot
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.dot() dict
    let dot = s:v.dot
    if !s:X() && !empty(dot)

        if dot[0] ==? 'c' && dot[1] !=? 's'     "change -> delete + z.
            let dot = 'd'.dot[1:]
            exe "normal ".dot."z."

        elseif dot[1] ==? 's'                   "surround needs run_normal()
            call self.run_normal(dot, 1, 1, 0)

        else
            exe "normal ".dot
        endif
    else
        normal z.
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit._process(cmd, ...) dict
    let size = s:size()    | let s:change = 0 | let cmd = a:cmd  | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    for r in s:R()
        if !s:v.auto && r.index == self.skip_index | continue | endif

        "execute command, but also take special cases into account
        if a:0 && s:special(cmd, r, a:000)
        else
            call r.bytes([s:change, s:change])
            call cursor(r.l, r.a)
            exe cmd
        endif

        "update changed size
        let s:change = s:size() - size
        if !has('nvim')
            doautocmd CursorMoved
        endif
    endfor

    "reset index to skip
    let self.skip_index = -1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process_visual(cmd) dict
    let size = s:size()                 | let change = 0
    let s:v.storepos = getpos('.')[1:2] | let s:v.eco = 1

    for r in s:R()
        call r.bytes([change, change])
        call cursor(r.L, r.b) | normal! m`
        call cursor(r.l, r.a) | normal! v``
        exe "normal ".a:cmd

        "update changed size
        let change = s:size() - size
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process(...) dict
    "arg1: prefix for normal command
    "arg2: 0 for recursive command

    let cmd = a:0? (a:1."normal".(a:2? "! ":" ").s:cmd)
            \    : ("normal! ".s:cmd)

    call self._process(cmd)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.post_process(reselect, ...) dict

    if a:reselect
        if !s:X() | call s:G.change_mode() | endif
        for r in s:R()
            call r.bytes([a:1, a:1 + s:v.W[r.index]])
        endfor
    endif

    "remove extra spaces that may have been added
    call self.extra_spaces.remove()

    "update, restore position and clear vars
    let pos = empty(s:v.storepos)? '.' : s:v.storepos
    call s:G.update_and_select_region(pos) | let s:v.storepos = []
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.special(cmd, ...) dict
    if a:0 | let s:v.merge = 1 | endif
    call self.before_macro(0)
    call self._process(0, a:cmd)
    call s:G.merge_regions()
    call self.after_macro(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:special(cmd, r, args)
    "Some commands need special adjustments while being processed.

    if a:args[0] ==# 'del'
        "<del> key deletes \n if executed at eol
        call a:r.bytes([s:change, s:change])
        call cursor(a:r.l, a:r.a)
        if a:r.a == col([a:r.l, '$']) - 1 | normal! Jx
        else                              | normal! x
        endif
        return 1

    elseif a:args[0] ==# 'd'
        "PROBABLY UNUSED: store deleted text so that it can all be put in the register
        call a:r.bytes([s:change, s:change])
        call cursor(a:r.l, a:r.a)
        exe a:cmd
        if s:v.use_register != "_"
            call add(s:v.deleted_text, getreg(s:v.use_register))
        endif
        return 1

    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extra spaces
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit.extra_spaces = {}

fun! s:Edit.extra_spaces.remove(...) dict
    "remove the extra space only if it comes after r.b, and it's just before \n
    for i in s:v.extra_spaces

        "some region has been removed for some reason(merge, ...)
        if i >= len(s:R()) | break | endif

        let l = s:R()[i].L + (a:0? a:1 : 0)
        if getline(l)[-1:-1] ==# ' '
            call cursor(l, 1)
            silent! undojoin
            normal! $x
        endif
    endfor
    let s:v.extra_spaces = []
endfun

fun! s:Edit.extra_spaces.add(r, ...) dict
    "add space if empty line(>) or eol(=)
    "a:0 is called by insert c-w, that requires an additional extra space
    let L = getline(a:r.L)
    if a:r.b > len(L) || (a:r.b == len(L) && (L[-1:-1] != ' ' || a:0))
        call setline(a:r.L, a:0? L.'  ' : L.' ')
        call add(s:v.extra_spaces, a:r.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Edit.before_macro(maps) dict
    let s:v.silence = 1 | let s:v.auto = 1 | let s:v.eco = 1
    let s:old_multiline = s:v.multiline    | let s:v.multiline = s:can_multiline
    let s:can_multiline = 0

    "disable mappings and run custom functions
    let s:maps = a:maps
    nunmap <buffer> <Space>
    nunmap <buffer> <esc>
    call s:F.external_funcs(a:maps, 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.after_macro(reselect, ...) dict
    let s:v.multiline = s:old_multiline
    if a:reselect
        call s:V.Edit.post_process(1, a:1)
    else
        call s:V.Edit.post_process(0)
    endif

    "reenable mappings and run custom functions
    nmap     <silent> <nowait> <buffer> <esc>      <Plug>(VM-Reset)
    nmap     <silent> <nowait> <buffer> <Space>    <Plug>(VM-Toggle-Mappings)
    call s:F.external_funcs(s:maps, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:count(c)
    "forbid count
    if a:c > 1
        if !g:VM.is_active | return 1 | endif
        call s:F.msg('Count not allowed.', 0)
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs_del(cmd)
    if s:v.insert | call vm#icmds#x(a:cmd)        | return
    else          | call s:V.Edit._process(s:cmd) | endif

    if a:cmd ==# 'X'
        for r in s:R() | call r.bytes([-1,-1]) | endfor

    elseif a:cmd ==# 'x'
        for r in s:R()
            if r.a == col([r.L, '$'])
                call r.bytes([-1,-1])
            endif
        endfor
    endif

    call s:G.merge_regions()
endfun

