" Special commands that can be selected through the Tools Menu (<leader>x)

fun! vm#special#commands#init() abort
  let s:V = b:VM_Selection
  let s:F = s:V.Funcs
  let s:G = s:V.Global
  call s:set_commands()
endfun

let s:R = { -> s:V.Regions }
let s:X = { -> g:Vm.extend_mode }


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tools menu                                                               {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#menu() abort
  let opts = [
        \['"    - ', "Show VM registers"],
        \['i    - ', "Show regions info"],
        \["\n", ""],
        \['f    - ', "Filter regions by pattern or expression"],
        \['l    - ', "Filter lines with regions"],
        \['r    - ', "Regions contents to buffer"],
        \['q    - ', "Fill quickfix with regions lines"],
        \['Q    - ', "Fill quickfix with regions positions and contents"],
        \]
  for o in opts
    echohl WarningMsg | echo o[0] | echohl Type | echon o[1]
  endfor
  echohl Directory  | echo "Enter an option: " | echohl None
  let c = nr2char(getchar())
  if c ==# '"'
    redraw!
    call vm#special#commands#show_registers(0, '')
  elseif c ==# 'i'
    redraw!
    call s:F.regions_contents()
  elseif c ==# 'r'
    call feedkeys("\<cr>", 'n')
    call vm#special#commands#regions_to_buffer()
  elseif c ==# 'f'
    redraw!
    call vm#special#commands#filter_regions(0, '', 1)
  elseif c ==# 'l'
    call feedkeys("\<cr>", 'n')
    call vm#special#commands#filter_lines()
  elseif c ==# 'q'
    call feedkeys("\<cr>", 'n')
    call vm#special#commands#qfix(1)
  elseif c ==# 'Q'
    call feedkeys("\<cr>", 'n')
    call vm#special#commands#qfix(0)
  else
    call feedkeys("\<cr>", 'n')
  endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter lines                                                             {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_lines() abort
  """Filter lines containing regions, and paste them in a new buffer.
  if !len(s:R()) | return | endif

  let lines = sort(keys(s:G.lines_with_regions(0)))
  let txt = []
  for l in lines
    call add(txt, getline(l))
  endfor
  call vm#reset(1)
  let s:buf = bufnr("%")
  noautocmd keepalt botright new! VM\ Filtered\ Lines
  let &l:statusline = '%#WarningMsg#VM Filtered Lines (:w updates lines!)'
  let b:VM_lines = lines
  for t in txt
    put = t
  endfor
  1d _
  call s:temp_buffer()
  autocmd BufWriteCmd <buffer> call s:save_lines()
endfun

"------------------------------------------------------------------------------

fun! s:save_lines() abort
  setlocal nomodified
  if len(b:VM_lines) != line("$")
    return s:F.msg("Number of lines doesn't match, aborting")
  endif
  let lnums = copy(b:VM_lines)
  let lines = map(range(line("$")), 'getline(v:key + 1)')
  let buf = b:VM_buf
  quit
  exe buf."b"
  let i = 0
  for l in lnums
    call setline(l, lines[i])
    let i += 1
  endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions to buffer                                                        {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#regions_to_buffer() abort
  """Paste selected regions in a new buffer.
  if !s:X() || !len(s:R()) | return | endif

  let txt = []
  for r in s:R()
    let t = r.txt
    if t[-1:-1] != "\n" | let t .= "\n" | endif
    call add(txt, r.txt)
  endfor
  call vm#reset(1)
  let s:buf = bufnr("%")
  noautocmd keepalt botright new! VM\ Filtered\ Regions
  let &l:statusline = '%#WarningMsg#VM Filtered Regions (:w updates regions!)'
  let b:VM_regions = copy(s:R())
  for t in txt
    put = t
  endfor
  1d _
  call s:temp_buffer()
  autocmd BufWriteCmd <buffer> call s:save_regions()
endfun

"------------------------------------------------------------------------------

fun! s:save_regions() abort
  setlocal nomodified
  if len(b:VM_regions) != line("$")
    return s:F.msg("Number of lines doesn't match number of regions")
  endif
  let R = copy(b:VM_regions)
  let lines = map(range(line("$")), 'getline(v:key + 1)')
  let buf = b:VM_buf
  quit
  exe buf."b"
  for r in R
    call vm#region#new(0, r.l, r.L, r.a, r.b)
  endfor
  call s:G.extend_mode()
  call s:V.Edit.replace_regions_with_text(lines)
endfun



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter by expression                                                     {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#filter_regions(type, exp, prompt) abort
  """Filter regions based on pattern or expression."""
  if s:not_active() | return | endif
  if a:type == 0 || a:type > 2
    let s:filter_type = 0
  else
    let s:filter_type = a:type
  endif
  let type = ['pattern', '!pattern', 'expression'][s:filter_type]
  if a:prompt
    cnoremap <buffer><nowait><silent><expr> <C-x> <sid>filter_regions(getcmdline())
    echohl Label
    let exp = input('Enter a filter (^X '.type.') > ', a:exp, 'command')
    echohl None
    cunmap <buffer> <C-x>
  else
    let exp = a:exp
  endif
  if empty(exp)
    call s:F.msg('Canceled.')
  else
    call s:G.filter_by_expression(exp, type)
    call s:G.update_and_select_region()
  endif
endfun

"------------------------------------------------------------------------------

fun! s:filter_regions(fill) abort
  let s:filter_type += 1
  let args = s:filter_type . ", '" . a:fill . "', 1"
  return "\<C-U>\<Esc>:call vm#special#commands#filter_regions(".args.")\<cr>"
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mass transpose                                                           {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#mass_transpose()
  if s:not_active() | return | endif

  let VM = b:VM_Selection
  if len(VM.Regions) == 1 || !g:Vm.extend_mode
    echo "Not possible"
    return
  endif

  let txt = VM.Global.regions_text()

  " create a list of the unique regions contents
  let unique = uniq(copy(txt))

  if len(unique) == 1
    echo "Regions have the same content"
    return
  endif

  " move first unique text to the bottom of the stack, but make a copy first
  let old = copy(unique)
  call add(unique, remove(unique, 0))

  " create new text
  let new_text = []
  for t in txt
    call add(new_text, old[index(unique, t)])
  endfor

  " fill register and paste new text
  call VM.Edit.fill_register('"', new_text, 0)
  call VM.Edit.paste(1, 0, 1, '"')
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Debug                                                                    {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#debug() abort
  if !exists('b:VM_Debug')
    return
  elseif empty(b:VM_Debug.lines)
    echomsg '[visual-multi] No errors'
    return
  endif

  for line in b:VM_Debug.lines
    if !empty(line)
      echom line
    endif
  endfor
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Qfix                                                                     {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#qfix(full_line)
  call vm#reset()
  let qfix = []
  if a:full_line
    for line in sort(keys(s:G.lines_with_regions(0)))
      call add(qfix, { "bufnr": bufnr(''), "lnum": line, "col": 1, "text": getline(line), "valid":1 })
    endfor
  else
    for r in s:R()
      call add(qfix, { "bufnr": bufnr(''), "lnum": r.l, "col": r.a, "text": r.txt, "valid":1 })
    endfor
  endif
  call setqflist(qfix)
  copen
  cc
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Show registers                                                           {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#show_registers(delete, args) abort
  if a:delete
    if a:args != ''
      " don't delete " or - registers, they are reset anyway at VM restart
      if a:args != '"' && a:args != '-'
        silent! unlet g:Vm.registers[a:args]
      endif
    else
      let g:Vm.registers = {'"': [], '-': []}
    endif
    return
  elseif a:args != ''
    if !has_key(g:Vm.registers, a:args)
      echo '[visual-multi] invalid register'
      return
    else
      let registers = [a:args]
    endif
  else
    let registers = keys(g:Vm.registers)
  endif

  echohl Label | echo " Register\tLine\t--- Register contents ---" | echohl None

  for r in registers
    "skip temporary register
    if r == '§' | continue | endif

    echohl Directory  | echo "\n    ".r
    let l = 1
    for s in g:Vm.registers[r]
      echohl WarningMsg | echo "\t\t".l."\t"
      echohl None  | echon s
      let l += 1
    endfor
  endfor
  echohl None
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Get all from current search                                              {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#from_search(bang) abort
  if exists('b:visual_multi')
    return
  endif
  let search = @/
  try
    call vm#init_buffer(1)
    let g:Vm.extend_mode = 1
    call s:V.Search.get_slash_reg(search)
    call vm#commands#find_next(0, 0)
    if a:bang
      call vm#commands#find_all(0, 0)
    endif
  catch
    call vm#reset(1)
    echo '[visual multi] pattern not found'
  endtry
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sort regions                                                             {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#commands#sort(...) abort
  if s:not_active() | return | endif
  if a:0
    call s:V.Edit.replace_regions_with_text(sort(s:G.regions_text(), a:1))
  else
    call s:V.Edit.replace_regions_with_text(sort(s:G.regions_text()))
  endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ex Commands and helpers                                                  {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_commands() abort
  command! -bang -nargs=? VMFilterRegions call vm#special#commands#filter_regions(<bang>0, <q-args>, empty(<q-args>))
  command! VMFilterLines                  call vm#special#commands#filter_lines()
  command! VMRegionsToBuffer              call vm#special#commands#regions_to_buffer()
  command! VMMassTranspose                call vm#special#commands#mass_transpose()
  command! -bang VMQfix                   call vm#special#commands#qfix(!<bang>0)
  command! -nargs=? VMSort                call vm#special#commands#sort(<args>)
endfun

fun! vm#special#commands#unset()
  delcommand VMFilterRegions
  delcommand VMFilterLines
  delcommand VMRegionsToBuffer
  delcommand VMMassTranspose
  delcommand VMQfix
  delcommand VMSort
endfun

"------------------------------------------------------------------------------

fun! s:not_active() abort
  if !g:Vm.buffer
    echohl ErrorMsg | echo "VM is not enabled" | echohl None | return 1
  endif
endfun

"------------------------------------------------------------------------------

fun! s:temp_buffer() abort
  setlocal buftype=acwrite
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nomodified
  let b:VM_buf = s:buf
endfun

" vim: et ts=2 sw=2 sts=2 :
