""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {'skip_index': -1}

fun! vm#edit#init() abort
    " Initialize script variables
    let s:V = b:VM_Selection
    let s:v = s:V.Vars
    let s:G = s:V.Global
    let s:F = s:V.Funcs

    let s:v.new_text     = []
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
" Commands at cursors
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_normal(cmd, ...) abort
    " Run normal command over regions.
    " optional arg is a dictionary with options
    "-----------------------------------------------------------------------

    if a:cmd == -1
        call s:F.special_statusline('NORMAL')
        let bang = a:0 && !get(a:1, 'recursive', 1) ? '!' : ''
        let cmd = input(':normal'.bang.' ')
        unlet s:v.statusline_mode
        if empty(cmd) | return s:F.msg('Normal command aborted.') | endif

    elseif a:cmd == '~' && s:X()
        return self.run_visual('~', 0)

    elseif empty(a:cmd)
        return s:F.msg('No last command.')

    else
        let cmd = a:cmd
    endif

    "-----------------------------------------------------------------------

    " defaults: commands are recursive, count=1, vim registers untouched
    let args = {
                \'recursive': 1, 'count': 1, 'vimreg': 0, 'gcount': 0,
                \'silent': get(g:, 'VM_silent_ex_commands', 0)
                \}

    if a:0 | call extend(args, a:1) | endif

    " if it's a VM internal operation, never use recursive mappings
    if has_key(args, 'store') && args.store == '§'
        let args.recursive = 0
    endif

    let n = args.count > 1 ? args.count : ''
    let c = args.recursive ? ("normal ".n.cmd) : ("normal! ".n.cmd)
    let c = args.silent    ? ("silent! ".c) : c

    call s:G.cursor_mode()
    call self.before_commands()
    let errors = ''

    try
        if a:cmd ==? 'x'   | call s:bs_del(n . a:cmd)
        elseif args.gcount | call self.process(a:cmd, args)
        else               | call self.process(c, args)
        endif
    catch
        let errors = v:errmsg
    endtry

    let g:Vm.last_normal = [cmd, args.recursive]
    let s:v.dot = [cmd, args.recursive]
    let s:v.merge = 1
    call self.after_commands(0)

    if !empty(errors)
        call s:F.msg('[visual-multi] errors while executing '.c)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_visual(cmd, recursive, ...) abort
    " Run visual command over selections.
    "-----------------------------------------------------------------------

    if !s:X()
        return s:F.msg('Not possible in cursor mode.')

    elseif !a:0 && a:cmd == -1
        call s:F.special_statusline('VISUAL')
        let bang = !a:recursive ? '!' : ''
        let cmd = input(':visual'.bang.' ')
        unlet s:v.statusline_mode
        if empty(cmd) | return s:F.msg('Visual command aborted.') | endif

    elseif empty(a:cmd)
        return s:F.msg('Command not found.')

    elseif !a:0
        let cmd = a:cmd
    endif

    "-----------------------------------------------------------------------

    call self.before_commands()
    let errors = ''

    try
        call self.process_visual(cmd, a:recursive)
    catch
        let errors = v:errmsg
    endtry

    let g:Vm.last_visual = [cmd, a:recursive]
    call self.after_commands(0)
    if !s:visual_reselect(cmd) | call s:G.change_mode() | endif

    if !empty(errors)
        call s:F.msg('[visual-multi] errors while executing '.cmd)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex(...) abort
    " Run Ex command over regions.
    "-----------------------------------------------------------------------

    if !empty(a:1)
        let cmd = a:1
    else
        return s:F.msg('Invalid command')
    endif

    "-----------------------------------------------------------------------

    if has_key(g:VM_commands_aliases, cmd)
        let cmd = g:VM_commands_aliases[cmd]
    endif

    let g:Vm.last_ex = cmd
    call s:G.cursor_mode()
    let errors = ''

    call self.before_commands()

    try
        call self.process(cmd)
    catch
        let errors = v:errmsg
    endtry

    let s:v.merge = 1
    call self.after_commands(0)

    if !empty(errors)
        call s:F.msg('[visual-multi] errors while executing '.cmd)
    endif
endfun


fun! s:Edit.ex_done() abort
    " Remove command mode mappings.
    silent! cunmap <buffer> <cr>
    silent! cunmap <buffer> <esc><esc>
    silent! cunmap <buffer> <esc>
    call histdel(':', -1)
    unlet s:v.statusline_mode
    if empty(@") | return s:F.msg('Ex command aborted.') | endif
    call s:V.Edit.run_ex(@")
endfun


fun! s:Edit.ex_get() abort
    " Get command line as entered by user.
    let @" = getcmdline()
    if !empty(@") | call histadd(':', @") | endif
    return ''
endfun


fun! s:Edit.ex() abort
    " Set command mode mappings.
    cnoremap <silent><nowait><buffer> <cr>  <c-r>=b:VM_Selection.Edit.ex_get()<cr><c-u>call b:VM_Selection.Edit.ex_done()<cr>
    cnoremap <silent><nowait><buffer> <esc><esc> <c-u>let @" = ''<cr>:call b:VM_Selection.Edit.ex_done()<cr>
    cnoremap <silent><nowait><buffer> <esc> <c-u>let @" = ''<cr>:call b:VM_Selection.Edit.ex_done()<cr>
    call s:F.special_statusline('EX')
    return ':'
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro() abort
    " Run macro over regions. Change to cursor mode if necessary.
    call s:F.msg('Register? ')
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        return s:F.msg('Macro aborted.')
    endif

    call self.before_commands()
    call s:G.cursor_mode()

    call self.process('normal! @'.reg)
    let s:v.merge = 1
    call self.after_commands(0)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Dot
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.dot() abort
    " Run dot command over regions.
    let dot = s:v.dot
    if !s:X() && !empty(dot)
        if type(dot) == v:t_list                    " a VM normal command
            call self.run_normal(dot[0], {'recursive': dot[1]})
        elseif dot[0] ==? 'c' && dot[1] !=? 's'     "repeat last change operator
            call vm#operators#select(1, dot[1:])
            normal ".p
            call s:G.cursor_mode()
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
    " Execute command at cursors.
    let s:v.eco = 1             " turn on eco mode
    let change  = 0             " each cursor will update this value
    let txt     = []            " if text is deleted, it will be stored here
    let size    = s:F.size()    " initial buffer size

    if empty(s:v.storepos) | let s:v.storepos = getpos('.')[1:2] | endif

    let backup_txt      = a:0 && has_key(a:1, 'store')      " deleting regions, store their text
    let write_reg       = backup_txt && a:1.store != '_'    " also write vim register unless _
    let stay_put        = a:0 && has_key(a:1, 'stay_put')   " don't move the cursors after command
    let do_cursor_moved = !exists("##TextYankPost")         " we want CursorMoved, even if cursor doesn't move

    " used by g<C-A>, g<C-X>
    let gcount = a:0 && get(a:1, 'gcount', 0) ? a:1.count ? a:1.count : 1 : 0

    " if we are planning to store regions text, it's because commands can delete them
    " but not all commands will alter vim registers, even if text changes
    "
    " then there's a bug: if user has mappings that redirect to _ register,
    " they will be falsely interpreted as using " register
    " if we just assume that " register contains deleted text and we store it,
    " we'd concatenate instead the old unchanged register, that will become
    " exponentially bigger in the process, because we write it back too
    "
    " so what we do is:
    "
    " - store the old " register
    " - clear it
    " - if commands change the register
    "       regions text must be stored
    "       the old " register will not be restored
    " - if after command " register is still empty
    "       don't store anything
    "       the old " register will be restored

    if backup_txt
        let oldreg = [@", getregtype('"')]
        let @" = ''
    endif
    let must_restore_register = v:false

    call s:G.backup_regions()

    for r in s:R()
        " used in non-live edit, currently disabled
        if !s:v.auto && r.index == self.skip_index | continue | endif

        " update cursor position on the base of previous text changes
        call r.shift(change, change)

        " execute command at cursor
        call cursor(r.l, r.a)

        if gcount
            let tick = b:changedtick
            exe 'normal! ' . gcount . a:cmd
            if b:changedtick > tick
                let gcount += a:1.count
            endif
        else
            exe a:cmd
        endif

        " store deleted text during deletions/changes at cursors
        if backup_txt
            if @" == ''
                let backup_txt = v:false
                let write_reg = v:false
                let must_restore_register = v:true
            else
                call add(txt, getreg(s:v.def_reg))
            endif
        endif

        " update new cursor position after the command, unless specified
        let diff = s:F.curs2byte() - r.A
        if !stay_put
            call r.shift(diff, diff)
        endif

        " update changed size
        let change = s:F.size() - size

        " let's force CursorMoved in case some yank command needs it
        if !diff && do_cursor_moved
            silent! doautocmd <nomodeline> CursorMoved
        endif
    endfor

    if must_restore_register
        call setreg('"', oldreg[0], oldreg[1])

    elseif write_reg
        " fill VM register after deletions/changes at cursors
        " overwrite vim register if requested
        call self.fill_register(a:1.store, txt, a:1.vimreg)
    endif

    " the original regions text could used by commands
    if backup_txt
        let s:v.changed_text = txt
    endif
endfun


fun! s:Edit.process_visual(cmd, recursive) abort
    " Process a 'visual' command over selections.
    let s:v.eco = 1             " turn on eco mode
    let change  = 0             " each cursor will update this value
    let size    = s:F.size()    " initial buffer size
    let s:v.storepos = getpos('.')[1:2]

    let cmd = a:recursive ? 'normal '.a:cmd : 'normal! '.a:cmd

    call s:G.backup_regions()

    for r in s:R()
        call r.shift(change, change)
        call cursor(r.L, r.b) | normal! m`
        call cursor(r.l, r.a) | normal! v``
        exe cmd

        "update changed size
        let change = s:F.size() - size
    endfor
endfun


fun! s:Edit.post_process(reselect, ...) abort
    " Operations to be performed after the command has been executed.
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
    " Extra spaces at EOL may have been added and must be removed.
    " remove the extra space only if it comes after r.b, and it's just before \n
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


fun! s:Edit.extra_spaces.add(r, ...) abort
    " It may be necessary to add spaces over empty lines, or if at EOL.
    " add space if empty line(>) or eol(=)
    " optional arg is when called in insert mode (cursors are different)
    let [end, line] = a:0? [a:r._a, a:r.l] : [a:r.b, a:r.L]
    let L = getline(line)
    " use strwidth because multibyte chars cause problems at EOL
    " this will result in more extra spaces than necessary but no big deal
    if end >= strwidth(L)
        call setline(line, L.' ')
        call add(s:v.extra_spaces, a:r.index)
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Before/after processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.before_commands() abort
    " Disable mappings and run user autocommand before running commands.
    let s:v.auto = 1 | let s:v.eco = 1

    let s:old_multiline = s:v.multiline
    let s:v.multiline = s:can_multiline
    let s:can_multiline = 0

    silent doautocmd <nomodeline> User visual_multi_before_cmd
    call s:V.Maps.disable(0)
    call s:V.Maps.unmap_esc_and_toggle()
endfun


fun! s:Edit.after_commands(reselect, ...) abort
    " Trigger post processing and reenable mappings.
    let s:v.multiline = s:old_multiline
    if a:reselect
        call s:V.Edit.post_process(1, a:1)
    else
        call s:V.Edit.post_process(0)
    endif

    call s:V.Maps.enable()
    call s:V.Maps.map_esc_and_toggle()
    silent doautocmd <nomodeline> User visual_multi_after_cmd
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bs_del(cmd) abort
    " Special handler for x/X normal commands, and <BS>/<Del> insert commands.
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


fun! s:visual_reselect(cmd) abort
    " Ensure selections are reselected after some commands.
    let reselect = a:cmd == '~' || a:cmd =~? 'u'
    return s:X() && reselect
endfun

" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
