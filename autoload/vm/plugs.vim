let g:VM.select_motions = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E', 'ge', 'gE', 'BBW']
let g:VM.motions        = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E', ',', ';', '$', '0', '^', '%', 'ge', 'gE']
let g:VM.find_motions   = ['f', 'F', 't', 'T']

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Plugs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#plugs#init()
    nmap  <silent>  <Plug>(VM-Select-Operator)         :<c-u>call vm#operators#select(0, 0)<cr>y
    nnoremap        <Plug>(VM-Select-All-Operator)     :<c-u>call vm#operators#select(1, v:count)<cr>

    nmap <expr> <silent>  <Plug>(VM-Find-Operator)     vm#operators#find(1, 0)
    xmap <expr> <silent>  <Plug>(VM-Visual Find)       vm#operators#find(1, 1)

    nnoremap        <Plug>(VM-Add-Cursor-At-Pos)       :call vm#commands#add_cursor_at_pos(0)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-At-Word)      :call vm#commands#add_cursor_at_word(1, 1)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-Down)         :<C-u>call vm#commands#add_cursor_down(0, v:count1)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-Up)           :<C-u>call vm#commands#add_cursor_up(0, v:count1)<cr>
    nnoremap        <Plug>(VM-Select-Cursor-Down)      :<C-u>call vm#commands#add_cursor_down(1, v:count1)<cr>
    nnoremap        <Plug>(VM-Select-Cursor-Up)        :<C-u>call vm#commands#add_cursor_up(1, v:count1)<cr>
    nnoremap        <Plug>(VM-Select-Line-Down)        :call vm#commands#expand_line(1)<cr>
    nnoremap        <Plug>(VM-Select-Line-Up)          :call vm#commands#expand_line(0)<cr>

    nnoremap        <Plug>(VM-Select-All)              :call vm#commands#find_all(0, 1, 0)<cr>
    xnoremap        <Plug>(VM-Visual-All)              y:call vm#commands#find_all(1, 0, 0)<cr>`]
    xnoremap        <Plug>(VM-Visual-Cursors)          :<c-u>call vm#commands#from_visual('cursors')<cr>
    xnoremap        <Plug>(VM-Visual-Add)              :<c-u>call vm#commands#from_visual('add')<cr>
    xnoremap        <Plug>(VM-Visual-Subtract)         :<c-u>call vm#commands#from_visual('subtract')<cr>
    nnoremap        <Plug>(VM-Split-Regions)           :<c-u>call vm#visual#split()<cr>
    nnoremap        <Plug>(VM-Remove-Empty-Lines)      :<c-u>call vm#commands#remove_empty_lines()<cr>

    nnoremap        <Plug>(VM-Find-Under)              :<c-u>call vm#commands#ctrld(v:count1)<cr>
    xnoremap        <Plug>(VM-Find-Subword-Under)      y:call vm#commands#find_under(1, 0, 0, 1)<cr>`]
    nnoremap        <Plug>(VM-Find-I-Word)             :<c-u>call vm#commands#find_under(0, 0, 0)<cr>
    nnoremap        <Plug>(VM-Find-A-Word)             :<c-u>call vm#commands#find_under(0, 0, 1)<cr>
    nnoremap        <Plug>(VM-Find-I-Whole-Word)       :<c-u>call vm#commands#find_under(0, 1, 0)<cr>
    nnoremap        <Plug>(VM-Find-A-Whole-Word)       :<c-u>call vm#commands#find_under(0, 1, 1)<cr>
    xnoremap        <Plug>(VM-Find-A-Subword)          y:call vm#commands#find_under(1, 0, 0)<cr>`]
    xnoremap        <Plug>(VM-Find-A-Whole-Subword)    y:call vm#commands#find_under(1, 1, 0)<cr>`]

    nnoremap        <Plug>(VM-Star)                    :<c-u>call <sid>Star(1)<cr>
    nnoremap        <Plug>(VM-Hash)                    :<c-u>call <sid>Star(2)<cr>
    xnoremap        <Plug>(VM-Visual-Star)             y:call <sid>Star(3)<cr>`]
    xnoremap        <Plug>(VM-Visual-Hash)             y:call <sid>Star(4)<cr>`]

    nnoremap        <Plug>(VM-Toggle-Mappings)         :call b:VM_Selection.Maps.mappings_toggle()<cr>
    nnoremap        <Plug>(VM-Toggle-Multiline)        :call b:VM_Selection.Funcs.toggle_option('multiline', 1)<cr>
    nnoremap        <Plug>(VM-Toggle-Block)            :call b:VM_Selection.Funcs.toggle_option('block_mode', 1)<cr>
    nnoremap        <Plug>(VM-Toggle-Debug)            :let g:VM_debug = !g:VM_debug<cr>
    nnoremap        <Plug>(VM-Toggle-Whole-Word)       :call b:VM_Selection.Funcs.toggle_option('whole_word', 1)<cr>
    nnoremap        <Plug>(VM-Toggle-Only-This-Region) :call b:VM_Selection.Funcs.toggle_option('only_this_always', 1)<cr>
    nnoremap        <Plug>(VM-Show-Help)               :call vm#special#help#show()<cr>
    nnoremap        <Plug>(VM-Case-Setting)            :call b:VM_Selection.Search.case()<cr>
    nnoremap        <Plug>(VM-Rewrite-Last-Search)     :call b:VM_Selection.Search.rewrite(1)<cr>
    nnoremap        <Plug>(VM-Rewrite-All-Search)      :call b:VM_Selection.Search.rewrite(0)<cr>
    nnoremap        <Plug>(VM-Read-From-Search)        :call b:VM_Selection.Search.get_slash_reg()<cr>
    nnoremap        <Plug>(VM-Add-Search)              :call b:VM_Selection.Search.get()<cr>
    nnoremap        <Plug>(VM-Remove-Search)           :call b:VM_Selection.Search.remove(0)<cr>
    nnoremap        <Plug>(VM-Remove-Search-Regions)   :call b:VM_Selection.Search.remove(1)<cr>
    nnoremap        <Plug>(VM-Search-Menu)             :call b:VM_Selection.Search.menu()<cr>
    nnoremap        <Plug>(VM-Case-Conversion-Menu)    :call b:VM_Selection.Case.menu()<cr>

    nnoremap        <Plug>(VM-Start-Regex-Search)      :call vm#commands#find_by_regex(1)<cr>:call <SID>Mode()<cr>/
    xnoremap        <Plug>(VM-Start-Visual-Search)     :call vm#commands#find_by_regex(2)<cr>:call <SID>Mode()<cr>/
    nnoremap        <Plug>(VM-Show-Regions-Info)       :call b:VM_Selection.Funcs.regions_contents()<cr>
    nnoremap        <Plug>(VM-Show-Registers)          :call b:VM_Selection.Funcs.show_registers()<cr>
    nnoremap        <Plug>(VM-Tools-Menu)              :call b:VM_Selection.Funcs.tools_menu()<cr>
    nnoremap        <Plug>(VM-Erase-Regions)           :call vm#commands#erase_regions(1)<cr>
    nnoremap        <Plug>(VM-Filter-Regions)          :call vm#special#commands#filter_regions()<cr>
    nnoremap        <Plug>(VM-Filter-Lines)            :call vm#special#commands#filter_lines(0)<cr>
    nnoremap        <Plug>(VM-Filter-Lines-Strip)      :call vm#special#commands#filter_lines(1)<cr>
    nnoremap        <Plug>(VM-Merge-Regions)           :call b:VM_Selection.Global.merge_regions()<cr>
    nnoremap        <Plug>(VM-Switch-Mode)             :call b:VM_Selection.Global.change_mode(1)<cr>
    nnoremap        <Plug>(VM-Reset)                   :call vm#reset()<cr><esc>
    nnoremap        <Plug>(VM-Undo)                    u:call b:VM_Selection.Global.update_regions()<cr>

    nnoremap        <Plug>(VM-Invert-Direction)        :call vm#commands#invert_direction(1)<cr>
    nnoremap        <Plug>(VM-Goto-Next)               :call vm#commands#find_next(0, 1)<cr>
    nnoremap        <Plug>(VM-Goto-Prev)               :call vm#commands#find_prev(0, 1)<cr>
    nnoremap        <Plug>(VM-Find-Next)               :call vm#commands#find_next(0, 0)<cr>
    nnoremap        <Plug>(VM-Find-Prev)               :call vm#commands#find_prev(0, 0)<cr>
    nnoremap        <Plug>(VM-Skip-Region)             :call vm#commands#skip(0)<cr>
    nnoremap        <Plug>(VM-Remove-Region)           :call vm#commands#skip(1)<cr>
    nnoremap        <Plug>(VM-Remove-Last-Region)      :call b:VM_Selection.Global.remove_last_region()<cr>
    nnoremap        <Plug>(VM-Undo-Visual)             :call vm#commands#undo()<cr>

    for m in g:VM.motions
        exe "nnoremap <Plug>(VM-Motion-".m.") :\<C-u>call vm#commands#motion('".m."', v:count1, 0, 0)\<cr>"
        exe "nnoremap <Plug>(VM-This-Motion-".m.") :\<C-u>call vm#commands#motion('".m."',v:count1, 0, 1)\<cr>"
    endfor

    for m in g:VM.find_motions
        exe "nnoremap <Plug>(VM-Motion-".m.") :call vm#commands#find_motion('".m."', '', 0)\<cr>"
    endfor

    for m in g:VM.select_motions
        exe "nnoremap <Plug>(VM-Select-".m.") :\<C-u>call vm#commands#motion('".m."', v:count1, 1, 0)\<cr>"
        exe "nnoremap <Plug>(VM-This-Select-".m.") :\<C-u>call vm#commands#motion('".m."', v:count1, 1, 1)\<cr>"
    endfor

    let remaps = g:VM_custom_remaps
    for m in keys(remaps)
        exe "nnoremap <Plug>(VM-Remap-Motion-".remaps[m].") :call vm#commands#remap_motion('".remaps[m]."', 0)\<cr>"
    endfor

    let noremaps = g:VM_custom_noremaps
    for m in keys(noremaps)
        exe "nnoremap <Plug>(VM-Motion-".noremaps[m].") :\<C-u>call vm#commands#motion('".noremaps[m]."', 1, 0, 0)\<cr>"
    endfor

    let cm = g:VM_custom_commands
    for m in keys(cm)
        exe "nnoremap <Plug>(VM-".m.") ".cm[m][1]
    endfor

    nnoremap        <Plug>(VM-Shrink)                  :call vm#commands#shrink_or_enlarge(1, 0)<cr>
    nnoremap        <Plug>(VM-Enlarge)                 :call vm#commands#shrink_or_enlarge(0, 0)<cr>
    nnoremap        <Plug>(VM-Merge-To-Eol)            :call vm#commands#merge_to_beol(1, 0)<cr>
    nnoremap        <Plug>(VM-Merge-To-Bol)            :call vm#commands#merge_to_beol(0, 0)<cr>

    "Edit commands
    nnoremap        <Plug>(VM-Edit-D)                  :<C-u>call vm#operators#cursors('d', 0, v:register)<cr>$
    nnoremap        <Plug>(VM-Edit-Y)                  :<C-u>call vm#operators#cursors('y', 0, v:register)<cr>$
    nnoremap        <Plug>(VM-Edit-x)                  :<C-u>call b:VM_Selection.Edit.run_normal('x', 0, v:count1, 0)<cr>:silent! undojoin<cr>
    nnoremap        <Plug>(VM-Edit-X)                  :<C-u>call b:VM_Selection.Edit.run_normal('X', 0, v:count1, 0)<cr>:silent! undojoin<cr>
    nnoremap        <Plug>(VM-Edit-J)                  :<C-u>call b:VM_Selection.Edit.run_normal('J', 0, v:count1, 0)<cr>:silent! undojoin<cr>
    nnoremap        <Plug>(VM-Edit-~)                  :<C-u>call b:VM_Selection.Edit.run_normal('~', 0, 1, 0)<cr>:silent! undojoin<cr>
    nnoremap        <Plug>(VM-Edit-Del)                :call b:VM_Selection.Edit.del_key()<cr>
    nnoremap        <Plug>(VM-Edit-Dot)                :call b:VM_Selection.Edit.dot()<cr>
    nnoremap        <Plug>(VM-Edit-Increase)           :<C-u>call b:VM_Selection.Edit.run_normal('<c-a>', 0, v:count1, 0)<cr>
    nnoremap        <Plug>(VM-Edit-Decrease)           :<C-u>call b:VM_Selection.Edit.run_normal('<c-x>', 0, v:count1, 0)<cr>
    nnoremap        <Plug>(VM-Edit-a)                  :<C-u>call b:VM_Selection.Insert.key('a')<cr>
    nnoremap        <Plug>(VM-Edit-A)                  :<C-u>call b:VM_Selection.Insert.key('A')<cr>
    nnoremap        <Plug>(VM-Edit-i)                  :<C-u>call b:VM_Selection.Insert.key('i')<cr>
    nnoremap        <Plug>(VM-Edit-I)                  :<C-u>call b:VM_Selection.Insert.key('I')<cr>
    nnoremap        <Plug>(VM-Edit-o)                  :<C-u>call b:VM_Selection.Insert.key('o')<cr>
    nnoremap        <Plug>(VM-Edit-O)                  :<C-u>call b:VM_Selection.Insert.key('O')<cr>
    nnoremap        <Plug>(VM-Edit-c)                  :<C-u>call b:VM_Selection.Edit.change(g:VM.extend_mode, v:count1, v:register)<cr>
    nnoremap        <Plug>(VM-Edit-C)                  :<C-u>call vm#operators#cursors('c', 0, v:register)<cr>$
    nnoremap        <Plug>(VM-Edit-Delete)             :<C-u>call b:VM_Selection.Edit.delete(g:VM.extend_mode, v:register, v:count1, 1)<cr>
    nnoremap        <Plug>(VM-Edit-Delete-Exit)        :<C-u>call b:VM_Selection.Edit.delete(g:VM.extend_mode, v:register, v:count1, 1)<cr>:call vm#reset()<cr>
    nnoremap        <Plug>(VM-Edit-Replace)            :<C-u>call b:VM_Selection.Edit.replace()<cr>
    nnoremap        <Plug>(VM-Edit-Replace-Pattern)    :<C-u>call b:VM_Selection.Edit.replace_pattern()<cr>
    nnoremap        <Plug>(VM-Edit-p-Paste-Regions)    :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 0), 1, g:VM.extend_mode, v:register)<cr>
    nnoremap        <Plug>(VM-Edit-P-Paste-Regions)    :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 1), 1, g:VM.extend_mode, v:register)<cr>
    nnoremap        <Plug>(VM-Edit-p-Paste-Normal)     :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 0), 0, g:VM.extend_mode, v:register)<cr>
    nnoremap        <Plug>(VM-Edit-P-Paste-Normal)     :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 1), 0, g:VM.extend_mode, v:register)<cr>
    nnoremap <expr> <Plug>(VM-Edit-Yank)               <SID>Yank(1)

    nnoremap        <Plug>(VM-Shift-Right)             :call b:VM_Selection.Edit.shift(1)<cr>
    nnoremap        <Plug>(VM-Shift-Left)              :call b:VM_Selection.Edit.shift(0)<cr>
    nnoremap        <Plug>(VM-Transpose)               :call b:VM_Selection.Edit.transpose()<cr>
    nnoremap        <Plug>(VM-Duplicate)               :call b:VM_Selection.Edit.duplicate()<cr>

    nnoremap        <Plug>(VM-Align)                   :<C-u>call b:VM_Selection.Edit.align()<cr>
    nnoremap        <Plug>(VM-Align-Char)              :<C-u>call vm#commands#align_char(v:count1)<cr>
    nnoremap        <Plug>(VM-Align-Regex)             :<C-u>call vm#commands#align_regex()<cr>
    nnoremap        <Plug>(VM-Numbers)                 :<C-u>call b:VM_Selection.Edit.numbers(v:count1, 0)<cr>
    nnoremap        <Plug>(VM-Numbers-Append)          :<C-u>call b:VM_Selection.Edit.numbers(v:count1, 1)<cr>
    nnoremap        <Plug>(VM-Zero-Numbers)            :<C-u>call b:VM_Selection.Edit.numbers(v:count, 0)<cr>
    nnoremap        <Plug>(VM-Zero-Numbers-Append)     :<C-u>call b:VM_Selection.Edit.numbers(v:count, 1)<cr>
    nnoremap        <Plug>(VM-Run-Dot)                 :<C-u>call b:VM_Selection.Edit.run_normal('.', 0, v:count1, 0)<cr>
    nnoremap        <Plug>(VM-Surround)                :call b:VM_Selection.Edit.surround()<cr>
    nnoremap        <Plug>(VM-Run-Macro)               :call b:VM_Selection.Edit.run_macro(0)<cr>
    nnoremap        <Plug>(VM-Run-Ex)                  :<C-u>call b:VM_Selection.Edit.run_ex(v:count1)<cr>
    nnoremap        <Plug>(VM-Run-Last-Ex)             :<C-u>call b:VM_Selection.Edit.run_ex(v:count1, g:VM.last_ex)<cr>
    nnoremap        <Plug>(VM-Run-Normal)              :<C-u>call b:VM_Selection.Edit.run_normal(-1, 1,  v:count1,1)<cr>
    nnoremap        <Plug>(VM-Run-Last-Normal)         :<C-u>call b:VM_Selection.Edit.run_normal(g:VM.last_normal[0] ,g:VM.last_normal[1], v:count1, 1)<cr>
    nnoremap        <Plug>(VM-Run-Visual)              :call b:VM_Selection.Edit.run_visual(-1, 0)<cr>
    nnoremap        <Plug>(VM-Run-Last-Visual)         :call b:VM_Selection.Edit.run_visual(g:VM.last_visual[0], g:VM.last_visual[1])<cr>

    inoremap <expr> <Plug>(VM-Insert-Arrow-w)          <sid>Insert('w')
    inoremap <expr> <Plug>(VM-Insert-Arrow-b)          <sid>Insert('b')
    inoremap <expr> <Plug>(VM-Insert-Arrow-W)          <sid>Insert('W')
    inoremap <expr> <Plug>(VM-Insert-Arrow-B)          <sid>Insert('B')
    inoremap <expr> <Plug>(VM-Insert-Arrow-e)          <sid>Insert('e')
    inoremap <expr> <Plug>(VM-Insert-Arrow-ge)         <sid>Insert('ge')
    inoremap <expr> <Plug>(VM-Insert-Arrow-E)          <sid>Insert('E')
    inoremap <expr> <Plug>(VM-Insert-Arrow-gE)         <sid>Insert('gE')
    inoremap <expr> <Plug>(VM-Insert-Left-Arrow)       <sid>Insert('h')
    inoremap <expr> <Plug>(VM-Insert-Right-Arrow)      <sid>Insert('l')
    inoremap <expr> <Plug>(VM-Insert-Up-Arrow)         <sid>Insert('h')
    inoremap <expr> <Plug>(VM-Insert-Down-Arrow)       <sid>Insert('l')
    inoremap <expr> <Plug>(VM-Insert-Return)           <sid>Insert('cr')
    inoremap <expr> <Plug>(VM-Insert-BS)               <sid>Insert('X')
    inoremap <expr> <Plug>(VM-Insert-Paste)            <sid>Insert('p')
    inoremap <expr> <Plug>(VM-Insert-CtrlW)            <sid>Insert('cw')
    inoremap <expr> <Plug>(VM-Insert-CtrlD)            <sid>Insert('x')
    inoremap <expr> <Plug>(VM-Insert-Del)              <sid>Insert('x')
    inoremap <expr> <Plug>(VM-Insert-CtrlA)            <sid>Insert('^')
    inoremap <expr> <Plug>(VM-Insert-CtrlE)            <sid>Insert('$')
    inoremap <expr> <Plug>(VM-Insert-CtrlB)            <sid>Insert('h')
    inoremap <expr> <Plug>(VM-Insert-CtrlF)            <sid>Insert('l')

    "Cmdline
    nnoremap <expr> <Plug>(VM-:)                       vm#commands#regex_reset(':')
    nnoremap <expr> <Plug>(VM-/)                       vm#commands#regex_reset('/')
    nnoremap <expr> <Plug>(VM-?)                       vm#commands#regex_reset('?')

    "mouse
    nmap            <Plug>(VM-Mouse-Cursor)            <LeftMouse>g<Space>
    nmap            <Plug>(VM-Mouse-Word)              <LeftMouse><C-d>
    nmap            <Plug>(VM-Mouse-Column)            :call vm#commands#mouse_column()<cr>
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Star(type)
    set nosmartcase
    set noignorecase

    if a:type == 1
        call vm#commands#find_under(0, 1, 0)
    elseif a:type == 2
        call vm#commands#find_under(0, 1, 1)
    elseif a:type == 3
        call vm#commands#find_under(1, 0, 0)
    elseif a:type == 4
        call vm#commands#find_under(1, 1, 0)
    endif
endfun

fun! s:Insert(key)
    call vm#comp#icmds()  "compatibility tweaks

    let b:VM_Selection.Vars.restart_insert = 1
    let b:VM_Selection.Vars.restore_scroll = 1
    let i = ":call b:VM_Selection.Insert.key('i')\<cr>"
    let a = ":call b:VM_Selection.Insert.key('a')\<cr>"
    let u = b:VM_Selection.Insert.change? ":silent! undojoin\<cr>" : ""

    if a:key == 'cr'            "return
        return "\<esc>:call vm#icmds#return()\<cr>".i
    elseif a:key ==? 'x'        "x/X
        "only join undo if there's been a change
        return "\<esc>".u.":call vm#icmds#x('".a:key."')\<cr>".i
    elseif index(split('hlwbWBeE', '\zs'), a:key) >= 0
        return "\<esc>:call vm#commands#motion('".a:key."', 1, 0, 0)\<cr>".i
    elseif a:key ==? 'ge'
        return "\<esc>:call vm#commands#motion('".a:key."', 1, 0, 0)\<cr>".i
    elseif a:key == '$'
        return "\<esc>".u.":call b:VM_Selection.Insert.key('A')\<cr>"
    elseif a:key == '^'
        return "\<esc>".u.":call b:VM_Selection.Insert.key('I')\<cr>"
    elseif a:key == 'p'         "c-v
        return "\<esc>".u.":call vm#icmds#paste()\<cr>".i
    elseif a:key == 'cw'        "c-w
        return "\<esc>".u.":call vm#icmds#cw()\<cr>".i
    endif
endfun

fun! s:Yank(hard)
    if empty(b:VM_Selection.Global.is_region_at_pos('.'))
        let b:VM_Selection.Vars.yanked = 1 | return 'y'
    endif
    return ":\<C-u>call b:VM_Selection.Edit.yank(".a:hard.", 0, 0, 1)\<cr>"
endfun

fun! s:Mode()
    let mode = g:VM.extend_mode? ' (extend mode)' : ' (cursor mode)'
    call b:VM_Selection.Funcs.msg([["Enter regex".mode.":", 'WarningMsg'], ["\n/", 'None']], 1)
endfun

