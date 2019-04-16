""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {'skip_index': -1}

fun! vm#edit#init()
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs

    let s:v.use_register = s:v.def_reg
    let s:v.new_text     = []
    let s:v.old_text     = []
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
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version >= 800
    let s:R    = { -> s:V.Regions }
    let s:X    = { -> g:Vm.extend_mode }
    let s:size = { -> line2byte(line('$')) }
else
    let s:R    = function('vm#v74#regions')
    let s:X    = function('vm#v74#extend_mode')
    let s:size = function('vm#v74#size')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_normal(cmd, ...) abort
    " optional arg is a dictionary with options
    "-----------------------------------------------------------------------

    if a:cmd == -1
        let cmd = input('Normal command? ')
        if empty(cmd) | return s:F.msg('Command aborted.', 1) | endif

    elseif a:cmd == '~' && s:X()
        call self.run_visual('~', 0)        | return

    elseif empty(a:cmd)
        call s:F.msg('No last command.', 1) | return

    else | let cmd = a:cmd | endif

    "-----------------------------------------------------------------------

    " defaults: commands are recursive, count 1, disable buffer mappings
    let args = { 'recursive': 1, 'count': 1 }
    if a:0 | call extend(args, a:1) | endif
    let args.maps = get(args, 'maps', args.recursive)

    let n = args.count > 1 ? args.count : ''
    let c = args.recursive ? ("normal ".n.cmd) : ("normal! ".n.cmd)

    call s:G.cursor_mode()
    call self.before_commands(args.maps)

    if a:cmd ==? 'x' | call s:bs_del(n.a:cmd)
    else             | call self.process(c, args)
    endif

    let g:Vm.last_normal = [cmd, args.recursive]
    call self.after_commands(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_visual(cmd, recursive, ...) abort

    "-----------------------------------------------------------------------

    if !a:0 && a:cmd == -1
        let cmd = input('Visual command? ')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif empty(a:cmd)
        call s:F.msg('Command not found.', 1) | return

    elseif !a:0
        let cmd = a:cmd | endif

    "-----------------------------------------------------------------------

    call self.before_commands(!a:recursive)
    call self.process_visual(cmd)

    let g:Vm.last_visual = [cmd, a:recursive]
    call self.after_commands(0)
    if !s:visual_reselect(cmd) | call s:G.change_mode() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex(count, ...) abort

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

    let g:Vm.last_ex = cmd
    call s:G.cursor_mode()

    call self.before_commands(1)
    for n in range(a:count)
        call self.process(cmd)
    endfor
    call self.after_commands(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro(replace) abort
    if s:count(v:count) | return | endif

    call s:F.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        return s:F.msg('Macro aborted.', 0)
    endif

    call self.before_commands(1)
    call s:G.cursor_mode()

    call self.process('normal! @'.reg)
    call self.after_commands(0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Dot
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.dot() abort
    let dot = s:v.dot
    if !s:X() && !empty(dot)

        if dot[0] ==? 'c' && dot[1] !=? 's'     "repeat last change operator
            call vm#operators#select(1, 1, dot[1:])
            normal ".p
            call s:G.cursor_mode()

        elseif dot[1] ==? 's'                   "surround (ys, ds, cs)
            call self.run_normal(dot, {'maps': 0})

        else
            call self.run_normal(dot)
        endif
    else
        call self.run_normal('.', {'count': v:count1, 'recursive': 0})
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process(cmd, ...) abort
    let size = s:size()    | let s:change = 0 | let cmd = a:cmd  | let s:v.eco = 1
    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    let store           = a:0 && exists('a:1.store') && a:1.store != "_"
    let stay_put        = a:0 && exists('a:1.stay_put')
    let do_cursor_moved = !exists("##TextYankPost")
    let txt = []

    call s:G.backup_regions()

    for r in s:R()
        " used in non-live edit, currently disabled
        if !s:v.auto && r.index == self.skip_index | continue | endif

        " update cursor position on the base of previous text changes
        call r.shift(s:change, s:change)

        " execute command at cursor
        call cursor(r.l, r.a)
        exe cmd

        " store deleted text during deletions/changes at cursors
        if store
            call add(txt, getreg(s:v.def_reg))
        endif

        " update new cursor position after the command, unless specified
        let diff = s:F.pos2byte('.') - r.A
        if !stay_put
            call r.shift(diff, diff)
        endif

        " update changed size
        let s:change = s:size() - size

        " let's force CursorMoved in case some yank command needs it
        if !diff && do_cursor_moved
            doautocmd CursorMoved
        endif
    endfor

    " fill VM register after deletions/changes at cursors
    if store
        let hard = g:VM_overwrite_vim_registers || ( a:1.store == s:v.def_reg )
        call self.fill_register(a:1.store, txt, hard)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process_visual(cmd) abort
    let size = s:size()                 | let change = 0
    let s:v.storepos = getpos('.')[1:2] | let s:v.eco = 1

    for r in s:R()
        call r.shift(change, change)
        call cursor(r.L, r.b) | normal! m`
        call cursor(r.l, r.a) | normal! v``
        exe "normal ".a:cmd

        "update changed size
        let change = s:size() - size
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.post_process(reselect, ...) abort

    if a:reselect
        call s:G.extend_mode()
        for r in s:R()
            call r.shift(a:1, a:1 + s:v.W[r.index])
        endfor
    endif

    "remove extra spaces that may have been added
    call self.extra_spaces.remove()

    "update, restore position and clear vars
    let pos = empty(s:v.storepos)? '.' : s:v.storepos
    call s:G.update_and_select_region(pos) | let s:v.storepos = []
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Extra spaces
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit.extra_spaces = {}

fun! s:Edit.extra_spaces.remove(...) abort
    "remove the extra space only if it comes after r.b, and it's just before \n
    for i in s:v.extra_spaces

        "some region has been removed for some reason(merge, ...)
        if i >= len(s:R()) | break | endif

        let l = s:R()[i].L + (a:0? a:1 : 0)
        if getline(l)[-1:-1] ==# ' '
            call cursor(l, 1)
            silent! undojoin | normal! $x
        endif
    endfor
    let s:v.extra_spaces = []
endfun

fun! s:Edit.extra_spaces.add(r, ...) abort
    "add space if empty line(>) or eol(=)
    "a:0 is called by insert c-w, that requires an additional extra space
    let L = getline(a:r.L)
    if a:r.b > len(L) || (a:r.b == len(L) && (L[-1:-1] != ' ' || a:0))
        call setline(a:r.L, a:0? L.'  ' : L.' ')
        call add(s:v.extra_spaces, a:r.index)
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Before/after processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.before_commands(disable_maps) abort
    let s:v.silence = 1 | let s:v.auto = 1 | let s:v.eco = 1

    let s:old_multiline = s:v.multiline
    let s:v.multiline = s:can_multiline
    let s:can_multiline = 0

    exe 'nunmap <buffer>' g:Vm.maps.toggle
    nunmap <buffer> <esc>

    let s:maps_disabled = 0
    call s:F.external_before_auto()

    if a:disable_maps
        let s:maps_disabled = 1
        call s:V.Maps.disable(0)
        call s:F.external_before_macro()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.after_commands(reselect, ...) abort
    let s:v.multiline = s:old_multiline
    if a:reselect
        call s:V.Edit.post_process(1, a:1)
    else
        call s:V.Edit.post_process(0)
    endif

    call s:F.external_after_auto()

    nmap <nowait><buffer>       <esc>             <Plug>(VM-Reset)
    exe 'nmap <nowait><buffer>' g:Vm.maps.toggle '<Plug>(VM-Toggle-Mappings)'

    if s:maps_disabled
        let s:maps_disabled = 0
        call s:V.Maps.enable()
        call s:F.external_after_macro()
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:count(c)
    "forbid count
    if a:c > 1
        if !g:Vm.is_active | return 1 | endif
        call s:F.msg('Count not allowed.', 0)
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs_del(cmd)
    if s:v.insert
        return vm#icmds#x(a:cmd)
    else
        call s:V.Edit.process('normal! '.a:cmd)
    endif

    if a:cmd ==# 'x'
        for r in s:R()
            if r.a == col([r.L, '$'])
                call r.shift(-1,-1)
            endif
        endfor
    endif

    call s:G.merge_regions()
endfun

"------------------------------------------------------------------------------

fun! s:visual_reselect(cmd)
    """Ensure selections are reselected after some commands.
    let reselect = a:cmd == '~' || a:cmd =~? 'gu'
    return s:X() && reselect
endfun

