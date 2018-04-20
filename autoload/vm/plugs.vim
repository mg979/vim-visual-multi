let s:motions  = ['h', 'j', 'k', 'l', 'w', 'W', 'b', 'B', 'e', 'E']

fun! vm#plugs#init()
    nnoremap        <Plug>(VM-Add-Cursor-At-Pos)       :call vm#commands#add_cursor_at_pos(0, 0)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-At-Word)      :call vm#commands#add_cursor_at_word(1, 1)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-Down)         :call vm#commands#add_cursor_at_pos(1, 0)<cr>
    nnoremap        <Plug>(VM-Add-Cursor-Up)           :call vm#commands#add_cursor_at_pos(2, 0)<cr>
    nnoremap        <Plug>(VM-Select-Down)             :call vm#commands#add_cursor_at_pos(1, 1)<cr>
    nnoremap        <Plug>(VM-Select-Up)               :call vm#commands#add_cursor_at_pos(2, 1)<cr>

    nnoremap        <Plug>(VM-Select-All)              :call vm#commands#find_all(0, 1, 0)<cr>
    xnoremap        <Plug>(VM-Select-All)              y:call vm#commands#find_all(1, 0, 0)<cr>`]
    nnoremap        <Plug>(VM-Find-I-Word)             :call vm#commands#find_under(0, 0, 0)<cr>
    nnoremap        <Plug>(VM-Find-A-Word)             :call vm#commands#find_under(0, 0, 1)<cr>
    nnoremap        <Plug>(VM-Find-I-Whole-Word)       :call vm#commands#find_under(0, 1, 0)<cr>
    nnoremap        <Plug>(VM-Find-A-Whole-Word)       :call vm#commands#find_under(0, 1, 1)<cr>
    xnoremap        <Plug>(VM-Find-A-Subword)          y:call vm#commands#find_under(1, 0, 0)<cr>`]
    xnoremap        <Plug>(VM-Find-A-Whole-Subword)    y:call vm#commands#find_under(1, 1, 0)<cr>`]

    nnoremap        <Plug>(VM-Star)                    :call vm#commands#add_under(0, 1, 0, 1)<cr>
    nnoremap        <Plug>(VM-Hash)                    :call vm#commands#add_under(0, 1, 1, 1)<cr>
    nnoremap        <Plug>(VM-Add-I-Word)              :call vm#commands#add_under(0, 0, 0)<cr>
    nnoremap        <Plug>(VM-Add-A-Word)              :call vm#commands#add_under(0, 0, 1)<cr>
    nnoremap        <Plug>(VM-Add-I-Whole-Word)        :call vm#commands#add_under(0, 1, 0)<cr>
    nnoremap        <Plug>(VM-Add-A-Whole-Word)        :call vm#commands#add_under(0, 1, 1)<cr>
    xnoremap        <Plug>(VM-Star)                    y:call vm#commands#add_under(1, 0, 0, 1)<cr>`]
    xnoremap        <Plug>(VM-Hash)                    y:call vm#commands#add_under(1, 1, 0, 1)<cr>`]

    nnoremap        <Plug>(VM-Toggle-Motions)          :call vm#maps#motions_toggle()<cr>
    nnoremap        <Plug>(VM-Toggle-Multiline)        :call b:VM_Selection.Funcs.toggle_option('multiline')<cr>
    nnoremap        <Plug>(VM-Toggle-Debug)            :let g:VM_debug = !g:VM_debug<cr>
    nnoremap        <Plug>(VM-Toggle-Whole-Word)       :call b:VM_Selection.Funcs.toggle_option('whole_word')<cr>
    nnoremap        <Plug>(VM-Toggle-Only-This-Region) :call b:VM_Selection.Funcs.toggle_option('only_this_always')<cr>
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
    nnoremap        <Plug>(VM-Switch-Mode)             :call vm#commands#change_mode(0)<cr>
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

    nnoremap        <Plug>(VM-Select-One-Inside)       :call vm#commands#select_motion(0, 1)<cr>
    nnoremap        <Plug>(VM-Select-One-Around)       :call vm#commands#select_motion(1, 1)<cr>
    nnoremap        <Plug>(VM-Select-All-Inside)       :call vm#commands#select_motion(0, 0)<cr>
    nnoremap        <Plug>(VM-Select-All-Around)       :call vm#commands#select_motion(1, 0)<cr>

    nnoremap        <Plug>(VM-This-Motion-h)           :call vm#commands#motion('h', 1)<cr>
    nnoremap        <Plug>(VM-This-Motion-l)           :call vm#commands#motion('l', 1)<cr>

    for m in s:motions
        exe "nnoremap <Plug>(VM-Motion-".m.") :call vm#commands#motion('".m."', 0)\<cr>"
        exe "nnoremap <Plug>(VM-Select-".m.") :call vm#commands#motion('".m."', 0, 1)\<cr>"
        exe "nnoremap <Plug>(VM-This-Motion-".m.") :call vm#commands#motion('".m."', 0)\<cr>"
    endfor

    nnoremap        <Plug>(VM-Fast-Back)               :call vm#commands#end_back(1, 0, 1)<cr>
    nnoremap        <Plug>(VM-End-Back)                :call vm#commands#end_back(0, 0, 1)<cr>

    nnoremap        <Plug>(VM-Motion-f)                :call vm#commands#find_motion('f', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-F)                :call vm#commands#find_motion('F', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-t)                :call vm#commands#find_motion('t', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-T)                :call vm#commands#find_motion('T', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-$)                :call vm#commands#find_motion('$', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-0)                :call vm#commands#find_motion('0', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-^)                :call vm#commands#find_motion('^', '', 0)<cr>
    nnoremap        <Plug>(VM-Motion-%)                :call vm#commands#find_motion('%', '', 0)<cr>

    nnoremap        <Plug>(VM-Motion-Shrink)           :call vm#commands#shrink_or_enlarge(1, 0)<cr>
    nnoremap        <Plug>(VM-Motion-Enlarge)          :call vm#commands#shrink_or_enlarge(0, 0)<cr>
    nnoremap        <Plug>(VM-Merge-To-Eol)            :call vm#commands#merge_to_beol(1, 0)<cr>
    nnoremap        <Plug>(VM-Merge-To-Bol)            :call vm#commands#merge_to_beol(0, 0)<cr>

    "Edit commands
    nnoremap        <Plug>(VM-Edit-Delete)             :<C-u>call b:VM_Selection.Edit.delete(g:VM.extend_mode, 1, v:count1)<cr>
    nnoremap        <Plug>(VM-Edit-Change)             :<C-u>call b:VM_Selection.Edit.change(g:VM.extend_mode, v:count1)<cr>
    nnoremap        <Plug>(VM-Edit-Replace)            :<C-u>call b:VM_Selection.Edit.replace()<cr>
    nnoremap        <Plug>(VM-Edit-p-Paste)            :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 0), 1, g:VM.extend_mode)<cr>
    nnoremap        <Plug>(VM-Edit-P-Paste)            :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 1), 1, g:VM.extend_mode)<cr>
    nnoremap        <Plug>(VM-Edit-p-Paste-Block)      :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 0), 0, g:VM.extend_mode)<cr>
    nnoremap        <Plug>(VM-Edit-P-Paste-Block)      :call b:VM_Selection.Edit.paste((g:VM.extend_mode? 1 : 1), 0, g:VM.extend_mode)<cr>
    nnoremap <expr> <Plug>(VM-Edit-Yank)               <SID>Yank(1)
    nnoremap <expr> <Plug>(VM-Edit-Soft-Yank)          <SID>Yank(0)
    nnoremap        <Plug>(VM-Run-Macro)               :call b:VM_Selection.Edit.run_macro(0)<cr>
    nnoremap        <Plug>(VM-Run-Macro-Replace)       :call b:VM_Selection.Edit.run_macro(1)<cr>
    nnoremap        <Plug>(VM-Edit-Shift-Right)        :call b:VM_Selection.Edit.shift(1)<cr>
    nnoremap        <Plug>(VM-Edit-Shift-Left)         :call b:VM_Selection.Edit.shift(0)<cr>
    nnoremap        <Plug>(VM-Edit-Transpose)          :call b:VM_Selection.Edit.transpose()<cr>
    nnoremap        <Plug>(VM-Run-Ex)                  :call b:VM_Selection.Edit.run_ex(1)<cr>
    nnoremap        <Plug>(VM-Run-Last-Ex)             :call b:VM_Selection.Edit.run_ex(0, b:VM_Selection.Vars.last_ex)<cr>
    nnoremap        <Plug>(VM-Edit-x)                  :call b:VM_Selection.Edit.run_normal('x', 0)<cr>
    nnoremap        <Plug>(VM-Edit-X)                  :call b:VM_Selection.Edit.run_normal('X', 0)<cr>
    nnoremap        <Plug>(VM-Run-Normal)              :call b:VM_Selection.Edit.run_normal(-1, 1)<cr>

    fun! <SID>Yank(hard)
        if empty(b:VM_Selection.Global.is_region_at_pos('.')) | return 'y' | endif
        return ":\<C-u>call b:VM_Selection.Edit.yank(".a:hard.", 0, 0, 1)\<cr>"
    endfun

    fun! <SID>Mode()
        let mode = g:VM.extend_mode? ' (extend mode)' : ' (cursor mode)'
        call b:VM_Selection.Funcs.msg([["Enter regex".mode.":", 'WarningMsg'], ["\n/", 'None']], 1)
    endfun

    let remaps = g:VM_custom_remaps
    for m in keys(remaps)
        exe "nnoremap <Plug>(VM-Remap-Motion-".remaps[m].") :call vm#commands#remap_motion('".remaps[m]."')\<cr>"
    endfor

    nnoremap <expr> <Plug>(VM-:)                       vm#commands#regex_reset(':')
    nnoremap <expr> <Plug>(VM-/)                       vm#commands#regex_reset('/')
    nnoremap <expr> <Plug>(VM-?)                       vm#commands#regex_reset('?')
endfun
