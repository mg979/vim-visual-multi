""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit commands #1 (yank, delete, paste, replace)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}

fun! vm#ecmds1#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    let s:R       = { -> s:V.Regions                  }
    let s:X       = { -> g:VM.extend_mode             }
    let s:size    = { -> line2byte(line('$') + 1)     }
    let s:min     = { nr -> s:X() && len(s:R()) >= nr }

    return extend(s:Edit, vm#ecmds2#init())
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Yank
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.yank(hard, def_reg, silent, ...) dict
    let register = (s:v.use_register != s:v.def_reg)? s:v.use_register :
                \  a:def_reg?                         s:v.def_reg : v:register

    if !s:X()    | call vm#operators#cursors('y', v:count, register) | return | endif
    if !s:min(1) | call s:F.msg('No regions selected.', 0)           | return | endif

    "write custom and possibly vim registers.
    let [text, type] = self.fill_register(register, s:G.regions_text(), a:hard)

    "restore default register if a different register was provided
    if register !=# s:v.def_reg | call s:F.restore_reg() | endif

    "reset temp register
    let s:v.use_register = s:v.def_reg

    "overwrite the old saved register if yanked using default register
    if register ==# s:v.def_reg
        let s:v.oldreg = [s:v.def_reg, join(text, "\n"), type]
    endif

    if !a:silent
        call s:F.msg('Yanked the content of '.len(s:R()).' regions.', 1) | endif
    if a:0 | call s:G.change_mode() | endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Delete
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.delete(X, register, count, hard) dict
    """Delete the selected text and change to cursor mode.
    if !s:v.direction | call vm#commands#invert_direction() | endif

    if !a:X     "ask for motion
        call vm#operators#cursors('d', a:count, a:register) | return | endif

    let winline      = winline()
    let size         = s:size()
    let change       = 0
    let ix           = s:G.select_region_at_pos('.').index
    let s:v.old_text = s:G.regions_text()

    for r in s:R()
        call r.bytes([change, change])
        call self.extra_spaces.add(r)
        call cursor(r.l, r.a)
        normal! m[
        call cursor(r.L, r.b>1? r.b+1 : 1)
        normal! m]

        exe "normal! `[d`]"

        "update changed size
        let change = s:size() - size
    endfor

    "write custom and possibly vim registers.
    call self.fill_register(a:register, s:v.old_text, a:hard)

    call s:G.change_mode()
    call s:G.select_region(ix)

    if a:hard            | call self.extra_spaces.remove() | endif
    if a:register == "_" | call s:F.restore_reg()          | endif
    let s:v.old_text = ''
    call s:F.Scroll.force(winline)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Paste
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.paste(before, vim_reg, reselect, register, ...) dict
    let X                = s:X()
    let s:v.use_register = a:register
    let vim_reg          = a:vim_reg || !has_key(g:VM.registers, a:register) ||
                           \empty(g:VM.registers[a:register])

    if empty(s:v.old_text) | let s:v.old_text = s:G.regions_text() | endif

    if a:0         | let s:v.new_text = a:1
    elseif vim_reg | let s:v.new_text = self.convert_vimreg(a:vim_reg)
    else           | let s:v.new_text = s:fix_regions_text(g:VM.registers[a:register]) | endif

    if X | call self.delete(1, "_", 1, 0) | endif

    call self.block_paste(a:before)

    let s:v.W = self.store_widths(s:v.new_text)
    call self.post_process((X? 1 : a:reselect), !a:before)
    let s:v.old_text = ''
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.block_paste(before) dict
    let size = s:size() | let change = 0 | let text = copy(s:v.new_text) | let s:v.eco = 1

    for r in s:R()
        if !empty(text)
            call r.bytes([change, change])
            call cursor(r.l, r.a)
            let s = remove(text, 0)
            call s:F.set_reg(s)

            if a:before | normal! P
            else        | normal! p
            endif

            "update changed size
            let change = s:size() - size
        else | break | endif
    endfor
    call s:F.restore_reg()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Replace
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.replace() dict
    if s:X()
        let char = nr2char(getchar())
        if char ==? "\<esc>" | return | endif

        let s:v.W = self.store_widths() | let s:v.new_text = []

        for i in range(len(s:v.W))
            let r = ''
            while len(r) < s:v.W[i] | let r .= char | endwhile
            let s:v.W[i] -= 1
            call add(s:v.new_text, r)
        endfor

        call self.delete(1, "_", 1, 0)
        call self.block_paste(1)
        call self.post_process(1, 0)
    else
        call s:F.msg('Replace char... ', 1)
        let char = nr2char(getchar())
        if char ==? "\<esc>" | call s:F.msg('Canceled.', 1) | return | endif
        call self.run_normal('r'.char, 0, '', 0)
        call s:F.count_msg(1)
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.replace_pattern() dict
    """Replace a pattern in all regions as with :s command."""
    if !s:X() | return | endif

    let ix = s:v.index | call s:F.Scroll.get()
    echohl Type
    let pat = input('Pattern to replace > ')
    if empty(pat)  | call s:F.msg('Command aborted.', 1) | return | endif
    let repl = input('Replacement > ')
    if empty(repl)
        call s:F.msg('Hit Enter for an empty replacement... ', 1)
        let confirm = nr2char(getchar())
        if confirm != "\<cr>" | call s:F.msg('Command aborted.', 1) | return | endif
    endif
    echohl None
    let text = s:G.regions_text() | let T = []
    for t in text
        call add(T, substitute(t, pat, repl, 'g'))
    endfor
    call self.fill_register('"', T, 0)
    normal p
    call s:G.select_region(ix)
endfun



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.replace_expression() dict
    """Replace all regions with the result of an expression."""
    if !s:X() | return | endif
    let ix = s:v.index | call s:F.Scroll.get()

    echohl Type    | let expr = input('Expression > ', '', 'expression') | echohl None
    if empty(expr) | call s:F.msg('Command aborted.', 1) | return | endif

    let T = [] | let expr = s:F.get_expr(expr)
    for r in s:R()
        call add(T, eval(expr))
    endfor
    call self.fill_register('"', T, 0)
    normal p
    call s:G.select_region(ix)
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:fix_regions_text(replacement)
    """Ensure there are enough elements for all regions.
    let L = a:replacement
    let i = len(s:R()) - len(L)

    while i>0
        call add(L, empty(s:v.old_text)? '' : s:v.old_text[-i])
        let i -= 1
    endwhile
    return L
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.convert_vimreg(as_block) dict
    """Fill the content to paste with the chosen vim register.
    let text = []
    let block = char2nr(getregtype(s:v.use_register)[0]) == 22

    if block
        "default register is of block type, assign a line to each region
        let width   = getregtype(s:v.use_register)[1:]
        let content = split(getreg(s:v.use_register), "\n")

        "ensure all regions have the same width, fill the rest with spaces
        if a:as_block
            for t in range(len(content))
                while len(content[t]) < width | let content[t] .= ' ' | endwhile
            endfor
        endif

        call s:fix_regions_text(content)

        for n in range(len(s:R()))
            call add(text, content[n])
        endfor
    else
        for n in range(len(s:R())) | call add(text, getreg(s:v.use_register)) | endfor
    endif
    return text
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.store_widths(...)
    "Build a list that holds the widths(integers) of each region
    "It will be used for various purposes (reselection, paste as block...)

    let W = [] | let x = s:X()
    let use_text = 0
    let use_list = 0

    if a:0
        if type(a:1) == v:t_string | let text = len(a:1)-1 | let use_text = 1
        else                       | let list = a:1        | let use_list = 1 | endif
    endif

    "mismatching blocks must be corrected
    if use_list | call s:fix_regions_text(list) | endif

    for r in s:R()
        "if using list, w must be len[i]-1, but always >= 0, set it to 0 if empty
        if use_list | let w = len(list[r.index]) | endif
        call add(W, use_text? text :
                \   use_list? (w? w-1 : 0) :
                \   r.w
                \)
    endfor
    return W
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Edit.fill_register(reg, text, hard) dict
    """Write custom and possibly vim registers.
    if a:reg == "_" | return | endif

    let text = a:text
    let maxw = max(map(copy(text), 'len(v:val)'))

    let g:VM.registers[a:reg] = text
    let type = s:v.multiline? 'V' : ( len(s:R())>1? 'b'.maxw : 'v' )

    "vim register is overwritten if unnamed, or if hard yank
    if a:reg ==# s:v.def_reg || a:hard
        call setreg(a:reg, join(text, "\n"), type)
        if a:hard   "also overwrite the old saved register
            let s:v.oldreg = [s:v.def_reg, join(text, "\n"), type]
        endif
    endif
    return [text, type]
endfun

