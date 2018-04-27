let g:VM.select_motions = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E']
let g:VM.motions        = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E', ',', ';', '~']
let g:VM.find_motions   = ['f', 'F', 't', 'T', '$', '0', '^', '%']

fun! vm#plugs#init()
    if has('nvim')
        nmap            <Plug>(VM-Select-Operator)     :let g:VM.selecting = 1<cr>:silent! nunmap <buffer> y<cr>y
    else
        nmap            <Plug>(VM-Select-Operator)     :set updatetime=10<cr>:let g:VM.selecting = 1<cr>:silent! nunmap <buffer> y<cr>y
    endif
    nnoremap        <Plug>(VM-Select-All-Operator)     :call vm#commands#select_operator()<cr>
    nnoremap        <Plug>(VM-Add-Cursor-At-Pos)       :call vm#commands#add_cursor_at_pos(0, 0)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-At-Word)      :call vm#commands#add_cursor_at_word(1, 1)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-Down)         :call vm#commands#add_cursor_at_pos(1, 0)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-Up)           :call vm#commands#add_cursor_at_pos(2, 0)<cr>
    nnoremap        <Plug>(VM-Select-Cursor-Down)      :call vm#commands#add_cursor_at_pos(1, 1)<cr>
    nnoremap        <Plug>(VM-Select-Cursor-Up)        :call vm#commands#add_cursor_at_pos(2, 1)<cr>
    nnoremap        <Plug>(VM-Select-Line-Down)        :call vm#commands#expand_line(1)<cr>
    nnoremap        <Plug>(VM-Select-Line-Up)          :call vm#commands#expand_line(0)<cr>

    nnoremap        <Plug>(VM-Select-All)              :call vm#commands#find_all(0, 1, 0)<cr>
    xnoremap        <Plug>(VM-Select-All)              y:call vm#commands#find_all(1, 0, 0)<cr>`]
    nnoremap        <Plug>(VM-Find-I-Word)             :call vm#commands#find_under(0, 0, 0)<cr>
    nnoremap        <Plug>(VM-Find-A-Word)             :call vm#commands#find_under(0, 0, 1)<cr>
    nnoremap        <Plug>(VM-Find-I-Whole-Word)       :call vm#commands#find_under(0, 1, 0)<cr>
    nnoremap        <Plug>(VM-Find-A-Whole-Word)       :call vm#commands#find_under(0, 1, 1)<cr>
    xnoremap        <Plug>(VM-Find-A-Subword)          y:call vm#commands#find_under(1, 0, 0)<cr>`]
    xnoremap        <Plug>(VM-Find-A-Whole-Subword)    y:call vm#commands#find_under(1, 1, 0)<cr>`]

    nnoremap        <Plug>(VM-Star)                    :call vm#commands#find_under(0, 1, 0)<cr>
    nnoremap        <Plug>(VM-Hash)                    :call vm#commands#find_under(0, 1, 1)<cr>
    xnoremap        <Plug>(VM-Star)                    y:call vm#commands#find_under(1, 0, 0)<cr>`]
    xnoremap        <Plug>(VM-Hash)                    y:call vm#commands#find_under(1, 1, 0)<cr>`]

    nnoremap        <Plug>(VM-Toggle-Mappings)         :call b:VM_Selection.Maps.mappings_toggle()<cr>
    nnoremap        <Plug>(VM-Toggle-Multiline)        :call b:VM_Selection.Funcs.toggle_option('multiline')<cr>
    nnoremap        <Plug>(VM-Toggle-Block)            :call b:VM_Selection.Funcs.toggle_option('block_mode')<cr>
    nnoremap        <Plug>(VM-Toggle-Debug)            :let g:VM_debug = !g:VM_debug<cr>
    nnoremap        <Plug>(VM-Toggle-Whole-Word)       :call b:VM_Selection.Funcs.toggle_option('whole_word')<cr>
    nnoremap        <Plug>(VM-Toggle-Only-This-Region) :call b:VM_Selection.Funcs.toggle_option('only_this_always')<cr>
    nnoremap        <Plug>(VM-Toggle-Edit)             :call b:VM_Selection.Funcs.toggle_option('edit_enabled')<cr>
    nnoremap        <Plug>(VM-Case-Setting)            :call b:VM_Selection.Search.case()<cr>
    nnoremap        <Plug>(VM-Case-Setting)            :call b:VM_Selection.Search.case()<cr>
    nnoremap        <Plug>(VM-Rewrite-Last-Search)     :call b:VM_Selection.Search.rewrite(1)<cr>
    nnoremap        <Plug>(VM-Rewrite-All-Search)      :call b:VM_Selection.Search.rewrite(0)<cr>
    nnoremap        <Plug>(VM-Read-From-Search)        :call b:VM_Selection.Search.get_slash_reg()<cr>
    nnoremap        <Plug>(VM-Add-Search)              :call b:VM_Selection.Search.add()<cr>
    nnoremap        <Plug>(VM-Remove-Search)           :call b:VM_Selection.Search.remove(0)<cr>
    nnoremap        <Plug>(VM-Remove-Search-Regions)   :call b:VM_Selection.Search.remove(1)<cr>

    nnoremap        <Plug>(VM-Start-Regex-Search)      :call vm#commands#find_by_regex()<cr>:call <SID>Mode()<cr>/
    nnoremap        <Plug>(VM-Show-Regions-Text)       :call b:VM_Selection.Funcs.regions_contents()<cr>
    nnoremap        <Plug>(VM-Show-Registers)          :call b:VM_Selection.Funcs.show_registers()<cr>
    nnoremap        <Plug>(VM-Erase-Regions)           :call b:VM_Selection.Global.erase_regions()<cr>
    nnoremap        <Plug>(VM-Merge-Regions)           :call b:VM_Selection.Global.merge_regions()<cr>
    nnoremap        <Plug>(VM-Switch-Mode)             :call b:VM_Selection.Global.change_mode(0)<cr>
    nnoremap        <Plug>(VM-Reset)                   :call vm#reset()<cr>
    nnoremap        <Plug>(VM-Undo)                    u:call b:VM_Selection.Global.update_regions()<cr>

    nnoremap        <Plug>(VM-Invert-Direction)        :call vm#commands#invert_direction()<cr>
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

    nnoremap        <Plug>(VM-Fast-Back)               :call vm#commands#end_back(1, 0, 1)<cr>
    nnoremap        <Plug>(VM-End-Back)                :call vm#commands#end_back(0, 0, 1)<cr>

    nnoremap        <Plug>(VM-Motion-Shrink)           :call vm#commands#shrink_or_enlarge(1, 0)<cr>
    nnoremap        <Plug>(VM-Motion-Enlarge)          :call vm#commands#shrink_or_enlarge(0, 0)<cr>
    nnoremap        <Plug>(VM-Merge-To-Eol)            :call vm#commands#merge_to_beol(1, 0)<cr>
    nnoremap        <Plug>(VM-Merge-To-Bol)            :call vm#commands#merge_to_beol(0, 0)<cr>

    "Edit commands
    nnoremap        <Plug>(VM-Edit-x)                  :call b:VM_Selection.Edit.run_normal('x', 0, 0)<cr>
    nnoremap        <Plug>(VM-Edit-X)                  :call b:VM_Selection.Edit.run_normal('X', 0, 0)<cr>
    nnoremap        <Plug>(VM-Edit-J)                  :call b:VM_Selection.Edit.run_normal('J', 0, 0)<cr>
    nnoremap        <Plug>(VM-Edit-Del)                :call b:VM_Selection.Edit.del_key()<cr>
    nnoremap        <Plug>(VM-Edit-a-Append)           :<C-u>call b:VM_Selection.Insert.key('a')<cr>
    nnoremap        <Plug>(VM-Edit-A-Append)           :<C-u>call b:VM_Selection.Insert.key('A')<cr>
    nnoremap        <Plug>(VM-Edit-i-Insert)           :<C-u>call b:VM_Selection.Insert.key('i')<cr>
    nnoremap        <Plug>(VM-Edit-I-Insert)           :<C-u>call b:VM_Selection.Insert.key('I')<cr>
    nnoremap        <Plug>(VM-Edit-o-New-Line)         :<C-u>call b:VM_Selection.Insert.key('o')<cr>
    nnoremap        <Plug>(VM-Edit-O-New-Line)         :<C-u>call b:VM_Selection.Insert.key('O')<cr>
    nnoremap        <Plug>(VM-Edit-Delete)             :<C-u>call b:VM_Selection.Edit.delete(g:VM.extend_mode, v:register, v:count1)<cr>
    nnoremap        <Plug>(VM-Edit-Change)             :<C-u>call b:VM_Selection.Edit.change(g:VM.extend_mode, v:count1)<cr>
    nnoremap        <Plug>(VM-Edit-Replace)            :<C-u>call b:VM_Selection.Edit.replace()<cr>
    nnoremap        <Plug>(VM-Edit-p-Paste)            :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 0), 1, g:VM.extend_mode)<cr>
    nnoremap        <Plug>(VM-Edit-P-Paste)            :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 1), 1, g:VM.extend_mode)<cr>
    nnoremap        <Plug>(VM-Edit-p-Paste-Block)      :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 0), 0, g:VM.extend_mode)<cr>
    nnoremap        <Plug>(VM-Edit-P-Paste-Block)      :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 1), 0, g:VM.extend_mode)<cr>
    nnoremap <expr> <Plug>(VM-Edit-Yank)               <SID>Yank(1)
    nnoremap <expr> <Plug>(VM-Edit-Soft-Yank)          <SID>Yank(0)
    nnoremap        <Plug>(VM-Edit-Shift-Right)        :call b:VM_Selection.Edit.shift(1)<cr>
    nnoremap        <Plug>(VM-Edit-Shift-Left)         :call b:VM_Selection.Edit.shift(0)<cr>
    nnoremap        <Plug>(VM-Edit-Transpose)          :call b:VM_Selection.Edit.transpose()<cr>

    nnoremap        <Plug>(VM-Numbers)                 :<C-u>call b:VM_Selection.Edit.numbers(v:count1, 0)<cr>
    nnoremap        <Plug>(VM-Numbers-Append)          :<C-u>call b:VM_Selection.Edit.numbers(v:count1, 1)<cr>
    nnoremap        <Plug>(VM-Zero-Numbers)            :<C-u>call b:VM_Selection.Edit.numbers(v:count, 0)<cr>
    nnoremap        <Plug>(VM-Zero-Numbers-Append)     :<C-u>call b:VM_Selection.Edit.numbers(v:count, 1)<cr>
    nnoremap        <Plug>(VM-Run-Dot)                 :call b:VM_Selection.Edit.run_normal('.', 0, 0)<cr>
    nnoremap        <Plug>(VM-Run-Surround)            :call b:VM_Selection.Edit.surround()<cr>
    nnoremap        <Plug>(VM-Run-Macro)               :call b:VM_Selection.Edit.run_macro(0)<cr>
    nnoremap        <Plug>(VM-Run-Ex)                  :call b:VM_Selection.Edit.run_ex()<cr>
    nnoremap        <Plug>(VM-Run-Last-Ex)             :call b:VM_Selection.Edit.run_ex(g:VM.last_ex)<cr>
    nnoremap        <Plug>(VM-Run-Normal)              :call b:VM_Selection.Edit.run_normal(-1, 1, 1)<cr>
    nnoremap        <Plug>(VM-Run-Last-Normal)         :call b:VM_Selection.Edit.run_normal(g:VM.last_normal[0] ,g:VM.last_normal[1], 1)<cr>
    nnoremap        <Plug>(VM-Run-Visual)              :call b:VM_Selection.Edit.run_visual(-1)<cr>
    nnoremap        <Plug>(VM-Run-Last-Visual)         :call b:VM_Selection.Edit.run_visual(g:VM.last_visual)<cr>

    fun! <SID>Yank(hard)
        if empty(b:VM_Selection.Global.is_region_at_pos('.')) | let b:VM_Selection.Vars.yanked = 1 | return 'y' | endif
        return ":\<C-u>call b:VM_Selection.Edit.yank(".a:hard.", 0, 0, 1)\<cr>"
    endfun

    fun! <SID>Mode()
        let mode = g:VM.extend_mode? ' (extend mode)' : ' (cursor mode)'
        call b:VM_Selection.Funcs.msg([["Enter regex".mode.":", 'WarningMsg'], ["\n/", 'None']], 1)
    endfun

    nnoremap <expr> <Plug>(VM-:)                       vm#commands#regex_reset(':')
    nnoremap <expr> <Plug>(VM-/)                       vm#commands#regex_reset('/')
    nnoremap <expr> <Plug>(VM-?)                       vm#commands#regex_reset('?')
endfun
