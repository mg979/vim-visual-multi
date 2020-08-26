"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Edit commands #1 (yank, delete, paste, replace)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Edit = {}
let s:old_text = []

fun! vm#ecmds1#init() abort
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs

    return extend(s:Edit, vm#ecmds2#init())
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Lambdas
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


let s:R   = { -> s:V.Regions }
let s:X   = { -> g:Vm.extend_mode }
let s:min = { n -> s:X() && len(s:R()) >= n }


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Yank
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Edit.yank(reg, silent, ...) abort
    " Yank the regions contents in a VM register. {{{1
    let register = (s:v.use_register != s:v.def_reg) ? s:v.use_register : a:reg

    if !s:X()    | return vm#cursors#operation('y', v:count, register) | endif
    if !s:min(1) | return s:F.msg('No regions selected.')              | endif

    "write custom and possibly vim registers.
    let [text, type] = self.fill_register(register, s:G.regions_text(), 0)

    "restore default register if a different register was provided
    if register !=# s:v.def_reg | call s:F.restore_reg() | endif

    "reset temp register
    let s:v.use_register = s:v.def_reg

    if !a:silent
        call s:F.msg('Yanked the content of '.len(s:R()).' regions.')
    endif
    if a:0 | call s:G.change_mode() | endif
endfun " }}}



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Delete
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Edit.delete(X, register, count, manual) abort
    " Delete the selected text and change to cursor mode.
    " Return the deleted text.
    " {{{1
    if s:F.no_regions() | return | endif
    if !s:v.direction | call vm#commands#invert_direction() | endif

    if !a:X     "ask for motion
        return vm#cursors#operation('d', a:count, a:register)
    endif

    let winline      = winline()
    let size         = s:F.size()
    let change       = 0
    let ix           = s:G.select_region_at_pos('.').index
    let s:old_text   = s:G.regions_text()
    let retVal       = copy(s:old_text)
    let s:v.deleting = 1

    " manual deletion: backup current regions
    if a:manual | call s:G.backup_regions() | endif

    for r in s:R()
        call r.shift(change, change)
        call self.extra_spaces.add(r)
        call cursor(r.l, r.a)
        if r.w == 1
          normal! "_dl
        else
          normal! m[
          call cursor(r.L, r.b>1? r.b+1 : 1)
          normal! m]`["_d`]
        endif

        "update changed size
        let change = s:F.size() - size
    endfor

    "write custom and possibly vim registers.
    call self.fill_register(a:register, s:old_text, a:manual)

    call s:G.change_mode()
    call s:G.select_region(ix)

    if a:manual
        call self.extra_spaces.remove()
        call s:G.update_and_select_region()
    endif
    if a:register == "_" | call s:F.restore_reg() | endif
    call s:F.Scroll.force(winline)
    let s:old_text = []
    return retVal
endfun " }}}


fun! s:Edit.xdelete(key, cnt) abort
    " Delete with 'x' or 'X' key, use black hole register in extend mode {{{1
    if s:X()
        call self.delete(1, '_', a:cnt, 1)
    else
        call self.run_normal(a:key, {'count': a:cnt, 'recursive': 0})
    endif
endfun "}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Paste
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Edit.paste(before, vim_reg, reselect, register, ...) abort
    " Perform a paste of the appropriate type. {{{1
    " @param before: 'P' or 'p' behaviour
    " @param vim_reg: if forcing regular vim registers
    " @param reselect: trigger reselection if run from extend mode
    " @param register: the register being used
    " @param ...: optional list with replacement text for regions
    let X                = s:X()
    let s:v.use_register = a:register
    let vim_reg          = a:vim_reg || !has_key(g:Vm.registers, a:register) ||
                \          empty(g:Vm.registers[a:register])
    let vim_V            = vim_reg && getregtype(a:register) ==# 'V'

    if empty(s:old_text) | let s:old_text = s:G.regions_text() | endif

    if vim_V
        return self.run_normal('"' . a:register . 'p', {'recursive': 0})

    elseif a:0     | let s:v.new_text = a:1
    elseif vim_reg | let s:v.new_text = self.convert_vimreg(a:vim_reg)
    else           | let s:v.new_text = s:fix_regions_text(g:Vm.registers[a:register])
    endif

    call s:G.backup_regions()

    if X | call self.delete(1, "_", 1, 0) | endif

    call self.block_paste(a:before)

    let s:v.W = self.store_widths(s:v.new_text)
    call self.post_process((X? 1 : a:reselect), !a:before)
    let s:old_text = []
endfun " }}}


fun! s:Edit.block_paste(before) abort
    " Paste the new text (list-type) at cursors. {{{1
    let size = s:F.size()
    let text = copy(s:v.new_text)
    let change = 0
    let s:v.eco = 1

    for r in s:R()
        if !empty(text)
            call r.shift(change, change)
            call cursor(r.l, r.a)
            let s = remove(text, 0)
            call s:F.set_reg(s)

            if a:before
                normal! P
            else
                normal! p
                if !exists('s:v.dont_move_cursors')
                    call r.update_cursor_pos()
                endif
            endif

            "update changed size
            let change = s:F.size() - size
        else
            break
        endif
    endfor
    silent! unlet s:v.dont_move_cursors
    call s:F.restore_reg()
endfun " }}}



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Replace
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Edit.replace_chars() abort
    " Replace single characters or selections with character. {{{1
    if s:X()
        let char = nr2char(getchar())
        if char ==? "\<esc>" | return | endif

        if s:v.multiline
            call s:F.toggle_option('multiline')
            call s:G.remove_empty_lines()
        endif

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
        call s:F.msg('Replace char... ')
        let char = nr2char(getchar())
        if char ==? "\<esc>" | return s:F.msg('Canceled.') | endif
        call self.run_normal('r'.char, {'recursive': 0, 'stay_put': 1})
    endif
endfun " }}}


fun! s:Edit.replace() abort
    " Replace a pattern in all regions, or start replace mode. {{{1
    if !s:X()
        let s:V.Insert.replace = 1
        return s:V.Insert.key('i')
    endif

    let ix = s:v.index
    call s:F.Scroll.get()

    echohl Type
    let pat = input('Pattern to replace > ')
    if empty(pat)
        return s:F.msg('Command aborted.')
    endif
    let repl = input('Replacement > ')
    if empty(repl)
        call s:F.msg('Hit Enter for an empty replacement... ')
        if getchar() != 13
            return s:F.msg('Command aborted.')
        endif
    endif
    echohl None

    let text = s:G.regions_text()
    let T = []
    for t in text
        call add(T, substitute(t, '\C' . pat, repl, 'g'))
    endfor
    call self.replace_regions_with_text(T)
    call s:G.select_region(ix)
endfun " }}}


fun! s:Edit.replace_expression() abort
    " Replace all regions with the result of an expression. {{{1
    if !s:X() | return | endif
    let ix = s:v.index | call s:F.Scroll.get()

    echohl Type    | let expr = input('Expression > ', '', 'expression') | echohl None
    if empty(expr) | return s:F.msg('Command aborted.') | endif

    let T = [] | let expr = s:F.get_expr(expr)
    for r in s:R()
        call add(T, eval(expr))
    endfor
    call map(T, 'type(v:val) != v:t_string ? string(v:val) : v:val')
    call self.replace_regions_with_text(T)
    call s:G.select_region(ix)
endfun " }}}



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:fix_regions_text(replacement) abort
    " Ensure there are enough elements for all regions. {{{1
    let L = a:replacement
    let i = len(s:R()) - len(L)

    while i>0
        call add(L, empty(s:old_text)? '' : s:old_text[-i])
        let i -= 1
    endwhile
    return L
endfun " }}}


fun! s:Edit.convert_vimreg(as_block) abort
    " Fill the content to paste with the chosen vim register. {{{1
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
endfun " }}}


fun! s:Edit.store_widths(...) abort
    " Build a list that holds the widths(integers) of each region {{{1
    " It will be used for various purposes (reselection, paste as block...)

    let W = [] | let x = s:X()
    let use_text = 0
    let use_list = 0

    if a:0
        if type(a:1) == type("") | let text = len(a:1)-1 | let use_text = 1
        else                     | let list = a:1        | let use_list = 1
        endif
    endif

    "mismatching blocks must be corrected
    if use_list | call s:fix_regions_text(list) | endif

    for r in s:R()
        "if using list, w must be len[i]-1, but always >= 0, set it to 0 if empty
        if use_list | let w = len(list[r.index]) | endif
        call add( W, use_text? text : use_list? (w? w-1 : 0) : r.w )
    endfor
    return W
endfun " }}}


fun! s:Edit.fill_register(reg, text, force_ow) abort
    " Write custom and possibly vim registers. {{{1

    "if doing a change/deletion, write the VM - register
    if s:v.deleting
        let g:Vm.registers['-'] = a:text
        let s:v.deleting = 0
    endif

    if a:reg == "_" | return | endif

    let text      = a:text
    let reg       = empty(a:reg) ? '"' : a:reg
    let temp_reg  = reg == '§'
    let overwrite = reg ==# s:v.def_reg || ( a:force_ow && !temp_reg )
    let maxw      = max(map(copy(text), 'len(v:val)'))
    let type      = s:v.multiline? 'V' : ( len(s:R())>1? 'b'.maxw : 'v' )

    " set VM register, overwrite backup register unless temporary
    if !temp_reg
        let g:Vm.registers[s:v.def_reg] = text
        let s:v.oldreg = [s:v.def_reg, join(text, "\n"), type]
    endif
    let g:Vm.registers[reg] = text

    "vim register is overwritten if unnamed, or if forced
    if overwrite
        call setreg(reg, join(text, "\n"), type)
    endif

    return [text, type]
endfun " }}}


fun! s:Edit.replace_regions_with_text(text, ...) abort
    " Paste a custom list of strings into current regions. {{{1
    call self.fill_register('"', a:text, 0)
    let before = !a:0 || !a:1
    call self.paste(before, 0, s:X(), '"')
endfun " }}}


" vim: et sw=4 ts=4 sts=4 fdm=marker
