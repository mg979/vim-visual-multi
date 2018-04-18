""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#edit#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars

    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:R       = { -> s:V.Regions }
    let s:X       = { -> g:VM.extend_mode }
    let s:size    = { -> line2byte(line('$') + 1) }

    let s:v.insert     = 0
    let s:v.registers  = {}
    let s:extra_spaces = []

    return s:Edit
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Region processing
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.process(...) dict
    "Optional args:
    "arg1: prefix for normal command
    "arg2: 0 for recursive command

    redir @t
    silent nmap <buffer>
    redir END
    let size = s:size() | let change = 0

    let cmd = a:0? (a:1."normal".(a:2? "! ":" ").s:cmd)
            \    : ("normal! ".s:cmd)

    for r in s:R()
        call r.shift(change, change)
        call cursor(r.l, r.a)
        exe cmd

        "update changed size
        let change = s:size() - size
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.post_process(reselect, shift) dict
    if a:reselect
        if !s:X()      | call vm#commands#change_mode(1) |  endif
        for r in s:R()
            if a:shift
                call r._b(s:W[r.index])
                call r.shift(a:shift, a:shift)
            else
                call r._b(s:W[r.index])
            endif
        endfor
    endif

    "remove extra spaces that may have been added
    for line in s:extra_spaces
        let l = getline(line)
        if l[-1:] ==# ' ' | call setline(line, l[:-2]) | endif
    endfor

    call s:Global.update_regions()
    call s:Global.select_region_at_pos('.')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.delete() dict
    """Delete the selected text and change to cursor mode.
    """Remember the lines that have been added an extra space, for later removal

    if s:X()
        let size = s:size() | let change = 0 | let s:extra_spaces = []
        for r in s:R()
            call r.shift(change, change)
            call cursor(r.l, r.a)
            let L = getline(r.L)
            if s:v.auto || r.b == len(L)
                call setline(r.L, L.' ')
                call add(s:extra_spaces, r.L)
            endif
            exe "normal! \"_d".r.w."l"

            "update changed size
            let change = s:size() - size
        endfor
        call vm#commands#change_mode(1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.block_paste(before, text) dict
    let size = s:size() | let change = 0 | let text = copy(a:text)

    for r in s:R()
        if !empty(text)
            call r.shift(change, change)
            call cursor(r.l, r.a)
            let s = remove(text, 0)
            call s:Funcs.set_reg(s)

            if a:before | normal! P
            else        | normal! p
            endif

            "update changed size
            let change = s:size() - size
        else | break | endif
    endfor
    call s:Funcs.restore_reg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.paste(before, block) dict
    let reg = v:register
    call self.delete()

    if !a:block || !has_key(s:v.registers, reg)
        let text = s:default_text()
    else
        let text = s:v.registers[reg]
    endif

    call self.block_paste(a:before, text)
    let s:W = s:store_widths(text)
    call self.post_process(1, !a:before)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.yank(hard) dict
    if !s:X() | call s:Funcs.msg('Not in cursor mode.', 0) | return | endif

    let text = []  | let maxw = 0
    for r in s:R()
        if len(r.txt) > maxw | let maxw = len(r.txt) | endif
        call add(text, r.txt)
    endfor

    let s:v.registers[v:register] = text
    call setreg(v:register, join(text, "\n"), "b".maxw)

    "overwrite the old saved register
    if a:hard
        let s:v.oldreg = [s:v.def_reg, join(text, "\n"), "b".maxw]
    endif
    call s:Funcs.msg('Yanked the content of '.len(s:R()).' regions.', 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_ex() dict
    if s:count(v:count) | return | endif

    let cmd = input('Ex command? ')
    if cmd == "\<esc>"
        call s:Funcs.msg('Command aborted.', 0)
        return | endif

endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Macros
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:before_macro()
    let s:v.silence = 1 | let s:v.auto = 1
    let s:old_multiline = g:VM.multiline
    let g:VM.multiline
    call vm#maps#end()
    if g:VM.motions_enabled | call vm#maps#motions(0, 1) | return 1 | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:after_macro(motions)
    let s:v.silence = 0 | let s:v.auto = 0
    let g:VM.multiline = s:old_multiline

    call vm#maps#start()
    if a:motions | call vm#maps#motions(1) | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.run_macro(replace) dict
    if s:count(v:count) | return | endif

    call s:Funcs.msg('Macro register? ', 1)
    let reg = nr2char(getchar())
    if reg == "\<esc>"
        call s:Funcs.msg('Macro aborted.', 0)
        return | endif

    let s:cmd = "@".reg
    let motions = s:before_macro()

    if a:replace | call self.delete()
    elseif s:X() | call vm#commands#change_mode(1) | endif

    call self.process()
    call self.post_process(0, 0)
    call s:after_macro(motions)
    redraw!
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.surround(type)
    if s:X()
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:count(c)
    "forbid count
    if a:c > 1
        if !g:VM.is_active | return 1 | endif
        call s:Funcs.msg('Count not allowed.', 0)
        call vm#reset()
        return 1
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:default_text()
    "fill the content to past with the default register
    let text = []
    for n in range(len(s:R())) | call add(text, getreg(s:v.def_reg)) | endfor
    return text
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:store_widths(...)
    "store regions widths in a list
    let W = [] | let x = s:X()
    let use_text = 0
    let use_list = 0

    if a:0
        if type(a:1) == v:t_string | let text = len(a:1)-1 | let use_text = 1
        else                       | let list = a:1        | let use_list = 1 | endif
    endif

    for r in s:R()
        call add(W, use_text? text : use_list? len(list[r.index])-1 : r.w) | endfor
    return W
endfun
