""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Plugs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#plugs#permanent() abort
  " Plugs and mappings for non <buffer> keys.
  xmap <expr><silent>     <Plug>(VM-Visual-Find)             vm#operators#find(1, 1)

  nnoremap <silent>       <Plug>(VM-Add-Cursor-At-Pos)       :call vm#commands#add_cursor_at_pos(0)<cr>
  nnoremap <silent>       <Plug>(VM-Add-Cursor-At-Word)      :call vm#commands#add_cursor_at_word(1, 1)<cr>
  nnoremap <silent>       <Plug>(VM-Add-Cursor-Down)         :<C-u>call vm#commands#add_cursor_down(0, v:count1)<cr>
  nnoremap <silent>       <Plug>(VM-Add-Cursor-Up)           :<C-u>call vm#commands#add_cursor_up(0, v:count1)<cr>
  nnoremap <silent>       <Plug>(VM-Select-Cursor-Down)      :<C-u>call vm#commands#add_cursor_down(1, v:count1)<cr>
  nnoremap <silent>       <Plug>(VM-Select-Cursor-Up)        :<C-u>call vm#commands#add_cursor_up(1, v:count1)<cr>

  nnoremap <silent>       <Plug>(VM-Reselect-Last)           :call vm#commands#reselect_last()<cr>
  nnoremap <silent>       <Plug>(VM-Select-All)              :call vm#commands#find_all(0, 1)<cr>
  xnoremap <silent><expr> <Plug>(VM-Visual-All)              <sid>Visual('all')
  xnoremap <silent>       <Plug>(VM-Visual-Cursors)          <Esc>:call vm#commands#visual_cursors()<cr>
  xnoremap <silent>       <Plug>(VM-Visual-Add)              <Esc>:call vm#commands#visual_add()<cr>
  xnoremap <silent>       <Plug>(VM-Visual-Reduce)           :<c-u>call vm#visual#reduce()<cr>

  nnoremap <silent>       <Plug>(VM-Find-Under)              :<c-u>call vm#commands#ctrln(v:count1)<cr>
  xnoremap <silent><expr> <Plug>(VM-Find-Subword-Under)      <sid>Visual('under')

  nnoremap <silent>       <Plug>(VM-Start-Regex-Search)      @=vm#commands#find_by_regex(1)<cr>
  xnoremap <silent>       <Plug>(VM-Visual-Regex)            :call vm#commands#find_by_regex(2)<cr>:call feedkeys('/', 'n')<cr>

  nnoremap <silent>       <Plug>(VM-Left-Mouse)              <LeftMouse>
  nmap     <silent>       <Plug>(VM-Mouse-Cursor)            <Plug>(VM-Left-Mouse)<Plug>(VM-Add-Cursor-At-Pos)
  nmap     <silent>       <Plug>(VM-Mouse-Word)              <Plug>(VM-Left-Mouse)<Plug>(VM-Find-Under)
  nnoremap <silent>       <Plug>(VM-Mouse-Column)            :call vm#commands#mouse_column()<cr>

  let g:Vm.select_motions = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E', 'ge', 'gE', 'BBW']
  for m in g:Vm.select_motions
    exe "nnoremap <silent> <Plug>(VM-Select-".m.") :\<C-u>call vm#commands#motion('".m."', v:count1, 1, 0)\<cr>"
  endfor
endfun


fun! vm#plugs#buffer() abort
  " Plugs and mappings for <buffer> keys.
  let g:Vm.motions        = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E', ',', ';', '$', '0', '^', '%', 'ge', 'gE', '\|']
  let g:Vm.find_motions   = ['f', 'F', 't', 'T']
  let g:Vm.tobj_motions   = { '{': '{', '}': '}', '(': '(', ')': ')', 'g{': '[{', 'g}': ']}', 'g)': '])', 'g(': '[(' }

  nnoremap <silent>       <Plug>(VM-Select-Operator)         :<c-u>call vm#operators#select(v:count)<cr>
  nmap <expr><silent>     <Plug>(VM-Find-Operator)           vm#operators#find(1, 0)

  xnoremap <silent>       <Plug>(VM-Visual-Subtract)         :<c-u>call vm#visual#subtract(visualmode())<cr>
  nnoremap                <Plug>(VM-Split-Regions)           :<c-u>call vm#visual#split()<cr>
  nnoremap <silent>       <Plug>(VM-Remove-Empty-Lines)      :<c-u>call vm#commands#remove_empty_lines()<cr>
  nnoremap <silent>       <Plug>(VM-Goto-Regex)              :<c-u>call vm#commands#regex_motion('', v:count1, 0)<cr>
  nnoremap <silent>       <Plug>(VM-Goto-Regex!)             :<c-u>call vm#commands#regex_motion('', v:count1, 1)<cr>

  nnoremap <silent>       <Plug>(VM-Toggle-Mappings)         :call b:VM_Selection.Maps.mappings_toggle()<cr>
  nnoremap <silent>       <Plug>(VM-Toggle-Multiline)        :call b:VM_Selection.Funcs.toggle_option('multiline')<cr>
  nnoremap <silent>       <Plug>(VM-Toggle-Whole-Word)       :call b:VM_Selection.Funcs.toggle_option('whole_word')<cr>
  nnoremap <silent>       <Plug>(VM-Toggle-Single-Region)    :call b:VM_Selection.Funcs.toggle_option('single_region')<cr>
  nnoremap <silent>       <Plug>(VM-Case-Setting)            :call b:VM_Selection.Search.case()<cr>
  nnoremap <silent>       <Plug>(VM-Rewrite-Last-Search)     :call b:VM_Selection.Search.rewrite(1)<cr>
  nnoremap <silent>       <Plug>(VM-Rewrite-All-Search)      :call b:VM_Selection.Search.rewrite(0)<cr>
  nnoremap <silent>       <Plug>(VM-Read-From-Search)        :call b:VM_Selection.Search.get_slash_reg()<cr>
  nnoremap <silent>       <Plug>(VM-Add-Search)              :call b:VM_Selection.Search.get_from_region()<cr>
  nnoremap <silent>       <Plug>(VM-Remove-Search)           :call b:VM_Selection.Search.remove(0)<cr>
  nnoremap <silent>       <Plug>(VM-Remove-Search-Regions)   :call b:VM_Selection.Search.remove(1)<cr>
  nnoremap <silent>       <Plug>(VM-Search-Menu)             :call b:VM_Selection.Search.menu()<cr>
  nnoremap <silent>       <Plug>(VM-Case-Conversion-Menu)    :call b:VM_Selection.Case.menu()<cr>

  nnoremap <silent>       <Plug>(VM-Show-Regions-Info)       :call b:VM_Selection.Funcs.regions_contents()<cr>
  nnoremap <silent>       <Plug>(VM-Show-Registers)          :VMRegisters<cr>
  nnoremap <silent>       <Plug>(VM-Tools-Menu)              :call vm#special#commands#menu()<cr>
  nnoremap <silent>       <Plug>(VM-Filter-Regions)          :call vm#special#commands#filter_regions(0, '', 1)<cr>
  nnoremap <silent>       <Plug>(VM-Regions-To-Buffer)       :call vm#special#commands#regions_to_buffer()<cr>
  nnoremap <silent>       <Plug>(VM-Filter-Lines)            :call vm#special#commands#filter_lines(0)<cr>
  nnoremap <silent>       <Plug>(VM-Filter-Lines-Strip)      :call vm#special#commands#filter_lines(1)<cr>
  nnoremap <silent>       <Plug>(VM-Merge-Regions)           :call b:VM_Selection.Global.merge_regions()<cr>
  nnoremap <silent>       <Plug>(VM-Switch-Mode)             :call b:VM_Selection.Global.change_mode(1)<cr>
  nnoremap <silent>       <Plug>(VM-Exit)                    :<c-u><C-r>=b:VM_Selection.Vars.noh<CR>call vm#reset()<cr>
  nnoremap <silent>       <Plug>(VM-Undo)                    :call vm#commands#undo()<cr>
  nnoremap <silent>       <Plug>(VM-Redo)                    :call vm#commands#redo()<cr>

  nnoremap <silent>       <Plug>(VM-Invert-Direction)        :call vm#commands#invert_direction(1)<cr>
  nnoremap <silent>       <Plug>(VM-Goto-Next)               :call vm#commands#find_next(0, 1)<cr>
  nnoremap <silent>       <Plug>(VM-Goto-Prev)               :call vm#commands#find_prev(0, 1)<cr>
  nnoremap <silent>       <Plug>(VM-Find-Next)               :call vm#commands#find_next(0, 0)<cr>
  nnoremap <silent>       <Plug>(VM-Find-Prev)               :call vm#commands#find_prev(0, 0)<cr>
  nnoremap <silent>       <Plug>(VM-Seek-Up)                 :call vm#commands#seek_up()<cr>
  nnoremap <silent>       <Plug>(VM-Seek-Down)               :call vm#commands#seek_down()<cr>
  nnoremap <silent>       <Plug>(VM-Skip-Region)             :call vm#commands#skip(0)<cr>
  nnoremap <silent>       <Plug>(VM-Remove-Region)           :call vm#commands#skip(1)<cr>
  nnoremap <silent>       <Plug>(VM-Remove-Last-Region)      :call b:VM_Selection.Global.remove_last_region()<cr>
  nnoremap <silent>       <Plug>(VM-Remove-Every-n-Regions)  :<c-u>call vm#commands#remove_every_n_regions(v:count)<cr>
  nnoremap <silent>       <Plug>(VM-Show-Infoline)           :call b:VM_Selection.Funcs.infoline()<cr>
  nnoremap <silent>       <Plug>(VM-One-Per-Line)            :call b:VM_Selection.Global.one_region_per_line()<bar>call b:VM_Selection.Global.update_and_select_region()<cr>

  nnoremap <silent>       <Plug>(VM-Hls)                     :set hls<cr>

  for m in g:Vm.motions
    exe "nnoremap <silent> <Plug>(VM-Motion-".m.") :\<C-u>call vm#commands#motion('".m."', v:count1, 0, 0)\<cr>"
    exe "nnoremap <silent> <Plug>(VM-Single-Motion-".m.") :\<C-u>call vm#commands#motion('".m."',v:count1, 0, 1)\<cr>"
  endfor

  for m in g:Vm.find_motions
    exe "nnoremap <silent> <Plug>(VM-Motion-".m.") :call vm#commands#find_motion('".m."', '')\<cr>"
  endfor

  let tobj = g:Vm.tobj_motions
  for m in keys(tobj)
    exe "nnoremap <silent> <Plug>(VM-Motion-".m.") :\<C-u>call vm#commands#motion('".tobj[m]."', v:count1, 0, 0)\<cr>"
  endfor

  for m in g:Vm.select_motions
    exe "nnoremap <silent> <Plug>(VM-Single-Select-".m.") :\<C-u>call vm#commands#motion('".m."', v:count1, 1, 1)\<cr>"
  endfor

  "make a dict with custom user operators, if they have been defined
  "the key holds the operator, the value is the expected characters of the
  "text object, 0 means any kind of text object
  let g:Vm.user_ops = {}
  for op in get(g:, 'VM_user_operators', [])
    if type(op) == v:t_dict
      let key = keys(op)[0]
      let g:Vm.user_ops[key] = op[key]
    else
      let key = op
      let g:Vm.user_ops[key] = 0
    endif
    exe "nnoremap <silent> <Plug>(VM-User-Operator-".key.") :\<C-u>call <sid>Operator('".key."', v:count1, v:register)\<cr>"
  endfor

  let remaps = g:VM_custom_remaps
  for m in keys(remaps)
    exe "nmap <silent> <Plug>(VM-Remap-".remaps[m].") ".remaps[m]
  endfor

  let noremaps = g:VM_custom_noremaps
  for m in values(noremaps)
    exe "nnoremap <silent> <Plug>(VM-Normal!-".m.") :\<C-u>call b:VM_Selection.Edit.run_normal('".m."', {'count': v:count1, 'recursive': 0})\<cr>"
  endfor

  let cm = g:VM_custom_commands
  for m in keys(cm)
    exe "nnoremap <silent> <Plug>(VM-".m.") ".cm[m]
  endfor

  nnoremap <silent>        <Plug>(VM-Shrink)                  :call vm#commands#shrink_or_enlarge(1)<cr>
  nnoremap <silent>        <Plug>(VM-Enlarge)                 :call vm#commands#shrink_or_enlarge(0)<cr>
  nnoremap <silent>        <Plug>(VM-Merge-To-Eol)            :call vm#commands#merge_to_beol(1, 0)<cr>
  nnoremap <silent>        <Plug>(VM-Merge-To-Bol)            :call vm#commands#merge_to_beol(0, 0)<cr>

  "Edit commands
  nnoremap <silent>        <Plug>(VM-D)                       :<C-u>call vm#cursors#operation('d', 0, v:register, 'd$')<cr>
  nnoremap <silent>        <Plug>(VM-Y)                       :<C-u>call vm#cursors#operation('y', 0, v:register, 'y$')<cr>
  nnoremap <silent>        <Plug>(VM-x)                       :<C-u>call b:VM_Selection.Edit.xdelete('x', v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-X)                       :<C-u>call b:VM_Selection.Edit.xdelete('X', v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-J)                       :<C-u>call b:VM_Selection.Edit.run_normal('J', {'count': v:count1, 'recursive': 0})<cr>
  nnoremap <silent>        <Plug>(VM-~)                       :<C-u>call b:VM_Selection.Edit.run_normal('~', {'recursive': 0})<cr>
  nnoremap <silent>        <Plug>(VM-&)                       :<C-u>call b:VM_Selection.Edit.run_normal('&', {'recursive': 0, 'silent': 1})<cr>
  nnoremap <silent>        <Plug>(VM-Del)                     :<C-u>call b:VM_Selection.Edit.run_normal('x', {'count': v:count1, 'recursive': 0})<cr>
  nnoremap <silent>        <Plug>(VM-Dot)                     :<C-u>call b:VM_Selection.Edit.dot()<cr>
  nnoremap <silent>        <Plug>(VM-Increase)                :<C-u>call vm#commands#increase_or_decrease(1, 0, v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-Decrease)                :<C-u>call vm#commands#increase_or_decrease(0, 0, v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-Alpha-Increase)          :<C-u>call vm#commands#increase_or_decrease(1, 1, v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-Alpha-Decrease)          :<C-u>call vm#commands#increase_or_decrease(0, 1, v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-a)                       :<C-u>call b:VM_Selection.Insert.key('a')<cr>
  nnoremap <silent>        <Plug>(VM-A)                       :<C-u>call b:VM_Selection.Insert.key('A')<cr>
  nnoremap <silent>        <Plug>(VM-i)                       :<C-u>call b:VM_Selection.Insert.key('i')<cr>
  nnoremap <silent>        <Plug>(VM-I)                       :<C-u>call b:VM_Selection.Insert.key('I')<cr>
  nnoremap <silent>        <Plug>(VM-o)                       :<C-u>call b:VM_Selection.Insert.key('o')<cr>
  nnoremap <silent>        <Plug>(VM-O)                       :<C-u>call b:VM_Selection.Insert.key('O')<cr>
  nnoremap <silent>        <Plug>(VM-c)                       :<C-u>call b:VM_Selection.Edit.change(g:Vm.extend_mode, v:count1, v:register, 0)<cr>
  nnoremap <silent>        <Plug>(VM-gc)                      :<C-u>call b:VM_Selection.Edit.change(g:Vm.extend_mode, v:count1, v:register, 1)<cr>
  nnoremap <silent>        <Plug>(VM-gu)                      :<C-u>call <sid>Operator('gu', v:count1, v:register)<cr>
  nnoremap <silent>        <Plug>(VM-gU)                      :<C-u>call <sid>Operator('gU', v:count1, v:register)<cr>
  nnoremap <silent>        <Plug>(VM-C)                       :<C-u>call vm#cursors#operation('c', 0, v:register, 'c$')<cr>
  nnoremap <silent>        <Plug>(VM-Delete)                  :<C-u>call b:VM_Selection.Edit.delete(g:Vm.extend_mode, v:register, v:count1, 1)<cr>
  nnoremap <silent>        <Plug>(VM-Delete-Exit)             :<C-u>call b:VM_Selection.Edit.delete(g:Vm.extend_mode, v:register, v:count1, 1)<cr>:call vm#reset()<cr>
  nnoremap <silent>        <Plug>(VM-Replace-Characters)      :<C-u>call b:VM_Selection.Edit.replace_chars()<cr>
  nnoremap <silent>        <Plug>(VM-Replace)                 :<C-u>call b:VM_Selection.Edit.replace()<cr>
  nnoremap <silent>        <Plug>(VM-Transform-Regions)       :<C-u>call b:VM_Selection.Edit.replace_expression()<cr>
  nnoremap <silent>        <Plug>(VM-p-Paste)                 :call b:VM_Selection.Edit.paste(g:Vm.extend_mode, 0, g:Vm.extend_mode, v:register)<cr>
  nnoremap <silent>        <Plug>(VM-P-Paste)                 :call b:VM_Selection.Edit.paste(               1, 0, g:Vm.extend_mode, v:register)<cr>
  nnoremap <silent>        <Plug>(VM-p-Paste-Vimreg)          :call b:VM_Selection.Edit.paste(g:Vm.extend_mode, 1, g:Vm.extend_mode, v:register)<cr>
  nnoremap <silent>        <Plug>(VM-P-Paste-Vimreg)          :call b:VM_Selection.Edit.paste(               1, 1, g:Vm.extend_mode, v:register)<cr>
  nnoremap <silent> <expr> <Plug>(VM-Yank)                    <SID>Yank()

  nnoremap <silent>        <Plug>(VM-Move-Right)              :call b:VM_Selection.Edit.shift(1)<cr>
  nnoremap <silent>        <Plug>(VM-Move-Left)               :call b:VM_Selection.Edit.shift(0)<cr>
  nnoremap <silent>        <Plug>(VM-Transpose)               :call b:VM_Selection.Edit.transpose()<cr>
  nnoremap <silent>        <Plug>(VM-Rotate)                  :call b:VM_Selection.Edit.rotate()<cr>
  nnoremap <silent>        <Plug>(VM-Duplicate)               :call b:VM_Selection.Edit.duplicate()<cr>

  nnoremap <silent>        <Plug>(VM-Align)                   :<C-u>call vm#commands#align()<cr>
  nnoremap <silent>        <Plug>(VM-Align-Char)              :<C-u>call vm#commands#align_char(v:count1)<cr>
  nnoremap <silent>        <Plug>(VM-Align-Regex)             :<C-u>call vm#commands#align_regex()<cr>
  nnoremap <silent>        <Plug>(VM-Numbers)                 :<C-u>call b:VM_Selection.Edit.numbers(v:count1, 0)<cr>
  nnoremap <silent>        <Plug>(VM-Numbers-Append)          :<C-u>call b:VM_Selection.Edit.numbers(v:count1, 1)<cr>
  nnoremap <silent>        <Plug>(VM-Zero-Numbers)            :<C-u>call b:VM_Selection.Edit.numbers(v:count, 0)<cr>
  nnoremap <silent>        <Plug>(VM-Zero-Numbers-Append)     :<C-u>call b:VM_Selection.Edit.numbers(v:count, 1)<cr>
  nnoremap <silent>        <Plug>(VM-Run-Dot)                 :<C-u>call b:VM_Selection.Edit.run_normal('.', {'count': v:count1, 'recursive': 0})<cr>
  nnoremap <silent>        <Plug>(VM-Surround)                :<c-u>call b:VM_Selection.Edit.surround()<cr>
  nnoremap <silent>        <Plug>(VM-Run-Macro)               :<c-u>call b:VM_Selection.Edit.run_macro()<cr>
  nnoremap <silent>        <Plug>(VM-Run-Ex)                  @=b:VM_Selection.Edit.ex()<CR>
  nnoremap <silent>        <Plug>(VM-Run-Last-Ex)             :<C-u>call b:VM_Selection.Edit.run_ex(g:Vm.last_ex)<cr>
  nnoremap <silent>        <Plug>(VM-Run-Normal)              :<C-u>call b:VM_Selection.Edit.run_normal(-1, {'count': v:count1})<cr>
  nnoremap <silent>        <Plug>(VM-Run-Last-Normal)         :<C-u>call b:VM_Selection.Edit.run_normal(g:Vm.last_normal[0], {'count': v:count1, 'recursive': g:Vm.last_normal[1]})<cr>
  nnoremap <silent>        <Plug>(VM-Run-Visual)              :call b:VM_Selection.Edit.run_visual(-1, 1)<cr>
  nnoremap <silent>        <Plug>(VM-Run-Last-Visual)         :call b:VM_Selection.Edit.run_visual(g:Vm.last_visual[0], g:Vm.last_visual[1])<cr>

  inoremap <silent><expr> <Plug>(VM-I-Arrow-w)          <sid>Insert('w')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-b)          <sid>Insert('b')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-W)          <sid>Insert('W')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-B)          <sid>Insert('B')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-e)          <sid>Insert('e')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-ge)         <sid>Insert('ge')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-E)          <sid>Insert('E')
  inoremap <silent><expr> <Plug>(VM-I-Arrow-gE)         <sid>Insert('gE')
  inoremap <silent><expr> <Plug>(VM-I-Left-Arrow)       <sid>Insert('h')
  inoremap <silent><expr> <Plug>(VM-I-Right-Arrow)      <sid>Insert('l')
  inoremap <silent><expr> <Plug>(VM-I-Up-Arrow)         <sid>Insert('k')
  inoremap <silent><expr> <Plug>(VM-I-Down-Arrow)       <sid>Insert('j')
  inoremap <silent><expr> <Plug>(VM-I-Return)           <sid>Insert('cr')
  inoremap <silent><expr> <Plug>(VM-I-BS)               <sid>Insert('X')
  inoremap <silent><expr> <Plug>(VM-I-Paste)            <sid>Insert('c-v')
  inoremap <silent><expr> <Plug>(VM-I-CtrlW)            <sid>Insert('c-w')
  inoremap <silent><expr> <Plug>(VM-I-CtrlU)            <sid>Insert('c-u')
  inoremap <silent><expr> <Plug>(VM-I-CtrlD)            <sid>Insert('x')
  inoremap <silent><expr> <Plug>(VM-I-Del)              <sid>Insert('x')
  inoremap <silent><expr> <Plug>(VM-I-Home)             <sid>Insert('0')
  inoremap <silent><expr> <Plug>(VM-I-End)              <sid>Insert('A')
  inoremap <silent><expr> <Plug>(VM-I-CtrlE)            <sid>Insert('A')
  inoremap <silent><expr> <Plug>(VM-I-Ctrl^)            <sid>Insert('I')
  inoremap <silent><expr> <Plug>(VM-I-CtrlA)            <sid>Insert('I')
  inoremap <silent><expr> <Plug>(VM-I-CtrlB)            <sid>Insert('h')
  inoremap <silent><expr> <Plug>(VM-I-CtrlF)            <sid>Insert('l')
  inoremap <silent><expr> <Plug>(VM-I-Next)             vm#icmds#goto(1)
  inoremap <silent><expr> <Plug>(VM-I-Prev)             vm#icmds#goto(0)
  inoremap <silent><expr> <Plug>(VM-I-Replace)          <sid>Insert('ins')

  "Cmdline
  nnoremap         <expr> <Plug>(VM-:)                  vm#commands#regex_reset(':')
  nnoremap         <expr> <Plug>(VM-/)                  vm#commands#regex_reset('/')
  nnoremap         <expr> <Plug>(VM-?)                  vm#commands#regex_reset('?')
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert(key) abort
  " Handle keys in insert mode.
  let VM = b:VM_Selection
  let i  = ":call b:VM_Selection.Insert.key('i')\<cr>"
  let a  = ":call b:VM_Selection.Insert.key('a')\<cr>"

  if pumvisible()
    if a:key == 'j'       | return "\<C-n>"
    elseif a:key == 'k'   | return "\<C-p>"
    elseif a:key == 'c-e' | return "\<C-e>"
    endif
  endif

  if a:key == 'ins'
    let VM.Insert.replace = !VM.Insert.replace
  endif

  if VM.Insert.replace | return s:Replace(a:key) | endif

  " in single region mode, some keys must be handled differently, or the
  " function must return prematurely
  if VM.Vars.single_region
    if a:key == 'c-v'
      return "\<C-r>0"
    elseif index(['cr', 'c-w', 'c-u', 'ins'], a:key) >= 0
      call VM.Funcs.msg("[visual-multi] not possible in single region mode")
      let &ro = &ro          " brings the cursor back from commmand line
      return ""
    endif
  else
    let VM.Vars.restart_insert = 1
  endif

  if index(split('hjklwbWB0', '\zs'), a:key) >= 0
    return "\<esc>:call vm#commands#motion('".a:key."', 1, 0, 0)\<cr>".i
  endif

  return {
        \ 'cr': "\<esc>:call vm#icmds#return()\<cr>".i,
        \ 'x': "\<esc>:call vm#icmds#x('".a:key."')\<cr>".i,
        \ 'ge': "\<esc>:call vm#commands#motion('h".a:key."l', 1, 0, 0)\<cr>".i,
        \ 'e': "\<esc>:call vm#commands#motion('".a:key."l', 1, 0, 0)\<cr>".i,
        \ 'a': "\<esc>:call b:VM_Selection.Insert.key('A')\<cr>",
        \ 'i': "\<esc>:call b:VM_Selection.Insert.key('I')\<cr>",
        \ 'c-v': "\<esc>:call vm#icmds#paste()\<cr>".a,
        \ 'c-w': "\<esc>:call vm#icmds#cw(0)\<cr>",
        \ 'c-u': "\<esc>:call vm#icmds#cw(1)\<cr>",
        \ 'ins': "\<esc>".i,
        \}[tolower(a:key)]
endfun


fun! s:Replace(key) abort
  " Handle keys in replace mode.
  let b:VM_Selection.Vars.restart_insert = 1
  let i  = ":call b:VM_Selection.Insert.key('i')\<cr>"

  if index(split('hl', '\zs'), a:key) >= 0
    return "\<esc>:call vm#commands#motion('".a:key."', 1, 0, 0)\<cr>".i
  endif

  let keys = {
        \ 'X': "\<esc>:call vm#icmds#x('".a:key."')\<cr>".i,
        \ 'ins': "\<esc>".i,
        \}
  return has_key(keys, a:key) ? keys[a:key] : ''
endfun


fun! s:Yank() abort
  " Wrapper for yank key.
  try
    if empty(b:VM_Selection.Global.region_at_pos())
      let b:VM_Selection.Vars.yanked = 1
      return 'y'
    endif
    return ":\<C-u>call b:VM_Selection.Edit.yank(v:register, 1, 1)\<cr>"
  catch
    VMClear
    return 'y'
  endtry
endfun


fun! s:Visual(cmd) abort
  " Restore register after a visual yank.
  if !g:Vm.buffer
    let g:Vm.visual_reg = ['"', getreg('"'), getregtype('"')]
    let r = "g:Vm.visual_reg[0], g:Vm.visual_reg[1], g:Vm.visual_reg[2]"
    let r = ":let b:VM_Selection.Vars.oldreg = g:Vm.visual_reg\<cr>:call setreg(".r.")\<cr>"
  else
    let r = ''
  endif
  return a:cmd == 'all'
        \ ? "y:call vm#commands#find_all(1, 0)\<cr>".r."`]"
        \ : "y:call vm#commands#find_under(1, 0)\<cr>".r."`]"
endfun


fun! s:Operator(op, n, reg) abort
  " User operator wrapper that checks extend mode.
  if !g:Vm.extend_mode
    call vm#cursors#operation(a:op, a:n, a:reg)
  elseif a:op ==? 'gu'
    call b:VM_Selection.Edit.run_visual(a:op[1:1], 0)
  else
    echo '[visual-multi] only in cursor mode'
  endif
endfun


" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
