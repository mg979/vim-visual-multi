""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {'skip_index': -1}

fun! vm#edit#init() abort
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs

    let s:v.use_register = s:v.def_reg
    let s:v.new_text     = []
    let s:v.old_text     = []
    let s:v.W            = []
    let s:v.storepos     = []
    let s:v.extra_spaces = []
    let s:can_multiline  = 0

    call vm#icmds#init()
    return extend(s:Edit, vm#ecmds1#init())
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:R = { -> s:V.Regions }
let s:X = { -> g:Vm.extend_mode }


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

    else
        let cmd = a:cmd
    endif

    "-----------------------------------------------------------------------

    " defaults: commands are recursive, count 1, disable buffer mappings
    let args = { 'recursive': 1, 'count': 1, 'vimreg': 0, 'disable_maps': 1,
                \'silent': get(g:, 'VM_silent_ex_commands', 0) }
    if a:0 | call extend(args, a:1) | endif

    let n = args.count > 1 ? args.count : ''
    let c = args.recursive ? ("normal ".n.cmd) : ("normal! ".n.cmd)
    let c = args.silent    ? ("silent! ".c) : c

    call s:G.cursor_mode()
    call self.before_commands(args.disable_maps)
    let errors = ''

    try
        if a:cmd ==? 'x' | call s:bs_del(n.a:cmd)
        else             | call self.process(c, args)
        endif
    catch
        let errors = v:errmsg
    endtry

    let g:Vm.last_normal = [cmd, args.recursive]
    call self.after_commands(0)

    if !empty(errors)
        call s:F.msg('[visual-multi] errors while executing '.c, 1)
    endif
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
        let cmd = a:cmd
    endif

    "-----------------------------------------------------------------------

    call self.before_commands(!a:recursive)
    let errors = ''

    try
        call self.process_visual(cmd)
    catch
        let errors = v:errmsg
    endtry

    let g:Vm.last_visual = [cmd, a:recursive]
    call self.after_commands(0)
    if !s:visual_reselect(cmd) | call s:G.change_mode() | endif

    if !empty(errors)
        call s:F.msg('[visual-multi] errors while executing '.cmd, 1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex(...) abort

    "-----------------------------------------------------------------------

    if !a:0
        let cmd = input('Ex command? ', '', 'command')
        if empty(cmd) | call s:F.msg('Command aborted.', 1) | return | endif

    elseif !empty(a:1)
        let cmd = a:1
    else
        call s:F.msg('Command not found.', 1) | return
    endif

    "-----------------------------------------------------------------------

    if has_key(g:VM_commands_aliases, cmd)
        let cmd = g:VM_commands_aliases[cmd]
    endif

    let g:Vm.last_ex = cmd
    call s:G.cursor_mode()
    let errors = ''

    call self.before_commands(1)

    try
        call self.process(cmd)
    catch
        let errors = v:errmsg
    endtry

    call self.after_commands(0)

    if !empty(errors)
        call s:F.msg('[visual-multi] errors while executing '.cmd, 1)
    endif
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
            call vm#operators#select(1, dot[1:])
            normal ".p
            call s:G.cursor_mode()

        elseif dot[1] ==? 's'                   "surround (ys, ds, cs)
            call self.run_normal(dot, {'disable_maps': 0})

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
    let s:v.eco = 1             " turn on eco mode
    let change  = 0             " each cursor will update this value
    let txt     = []            " if text is deleted, it will be stored here
    let size    = s:F.size()    " initial buffer size

    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    let store           = a:0 && exists('a:1.store') && a:1.store != "_"
    let backup_txt      = a:0 && exists('a:1.store')
    let stay_put        = a:0 && exists('a:1.stay_put')
    let do_cursor_moved = !exists("##TextYankPost")

    call s:G.backup_regions()

    for r in s:R()
        " used in non-live edit, currently disabled
        if !s:v.auto && r.index == self.skip_index | continue | endif

        " update cursor position on the base of previous text changes
        call r.shift(change, change)

        " execute command at cursor
        call cursor(r.l, r.a)
        exe a:cmd

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
        let change = s:F.size() - size

        " let's force CursorMoved in case some yank command needs it
        if !diff && do_cursor_moved
            doautocmd CursorMoved
        endif
    endfor

    " fill VM register after deletions/changes at cursors
    if store
        let hard = g:VM_overwrite_vim_registers
                    \ || ( a:1.store == s:v.def_reg ) || a:1.vimreg
        call self.fill_register(a:1.store, txt, hard)
    endif
    " backup original regions text since it could used
    if backup_txt
        let s:v.changed_text = txt
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process_visual(cmd) abort
    let s:v.eco = 1             " turn on eco mode
    let change  = 0             " each cursor will update this value
    let size    = s:F.size()    " initial buffer size
    let s:v.storepos = getpos('.')[1:2]

    call s:G.backup_regions()

    for r in s:R()
        call r.shift(change, change)
        call cursor(r.L, r.b) | normal! m`
        call cursor(r.l, r.a) | normal! v``
        exe "normal ".a:cmd

        "update changed size
        let change = s:F.size() - size
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
        let Line = getline(l)
        if Line[-1:-1] ==# ' '
            call setline(l, Line[:-2])
        endif
    endfor
    let s:v.extra_spaces = []
endfun

fun! s:Edit.extra_spaces.add(r) abort
    "add space if empty line(>) or eol(=)
    let L = getline(a:r.L)
    if a:r.b >= strwidth(L)
        call setline(a:r.L, L.' ')
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

fun! s:count(c) abort
    "forbid count
    if a:c > 1
        if !g:Vm.is_active | return 1 | endif
        call s:F.msg('Count not allowed.', 0)
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs_del(cmd) abort
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

fun! s:visual_reselect(cmd) abort
    """Ensure selections are reselected after some commands.
    let reselect = a:cmd == '~' || a:cmd =~? 'gu'
    return s:X() && reselect
endfun

" vim: et ts=4 sw=4 sts=4 :
