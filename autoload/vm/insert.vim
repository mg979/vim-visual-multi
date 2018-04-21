""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Insert = {'index': -1, 'cursors': [], 'begin': 0, 'is_active': 0, 'mode': ''}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#insert#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars

    let s:Global  = s:V.Global
    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search

    let s:R       = {      -> s:V.Regions              }
    let s:X       = {      -> g:VM.extend_mode         }
    let s:size    = {      -> line2byte(line('$') + 1) }
    let s:Byte    = { pos  -> s:Funcs.pos2byte(pos)    }
    let s:Pos     = { byte -> s:Funcs.byte2pos(byte)   }
    let s:append  = { m    -> index(['a', 'A'], m) >= 0  }
    let s:newline = { m    -> index(['o', 'O'], m) >= 0  }

    return s:Insert
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Cursor = {}

"--------------------------------------------------------------------------

"in Insert Mode we will forget about the regions, and work with cursors at
"byte offsets; from the final offset, we'll update the real regions later

"--------------------------------------------------------------------------


fun! s:Cursor.new(byte) dict
    "Create new cursor.
    let C       = copy(self)
    let C.index = len(s:Insert.cursors)
    let C.A     = a:byte
    let C.txt   = ''

    if g:VM_live_editing
        let C.hl    = matchaddpos('MultiCursor', [s:Pos(a:byte)], 40)
    endif

    return C
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Cursor.update(byte, txt) dict
    "Update cursors positions and highlight.
    call matchdelete(self.hl)

    let self.A   = a:byte
    let self.txt = a:txt

    if g:VM_live_editing
        let self.hl  = matchaddpos('MultiCursor', [s:Pos(a:byte)], 40)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Live insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.start(mode, ...) dict
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'begin' is the initial offset, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------

    let self.index     = s:v.index
    let self.begin     = s:Byte('.')
    let self.is_active = 1
    let self.mode      = a:mode

    for r in s:R()
        "remove the regular cursor highlight, add new cursor
        let A = s:append(a:mode)? r.A+1 : r.A
        call add(self.cursors, s:Cursor.new(A))
        if g:VM_live_editing || r.index == self.index
            call r.remove_highlight() | endif | endfor

    "start tracking text changes
    call self.auto_start()

    inoremap <silent> <buffer> <esc>   <esc>:call b:VM_Selection.Insert.stop(-1)<cr>
    "inoremap <buffer> <space> <esc>:call b:VM_Selection.Insert.stop(b:VM_Selection.Insert.mode)<cr>
    call s:Global.update_cursor_highlight()

    "start insert mode and break the undo point
    let keys = (a:mode=='c'? 'i': a:mode)."\<c-g>u"
    if a:0 | let keys .= "\<space>" | endif
    call feedkeys(keys, 'n')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_inserted_text(a, b)
    "Yank between the offsets and return the yanked text

    let pos = s:Pos(a:a)
    call cursor(pos[0], pos[1])
    normal! `[
    let pos = s:Pos(a:b)
    call cursor(pos[0], pos[1]+1)
    normal! `]`[y`]`]
    return getreg(s:v.def_reg)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.live_insert() dict
    "TextChangedI
    call feedkeys("\<esc>", 'n')
    let current = s:Byte('.') + 1
    let begin = self.begin

    "if current < s:Insert.begin | let s:Insert.begin = current | endif

    let size = s:size()
    let change = current - begin
    let text = s:get_inserted_text(begin, current)

    "update cursors
    for c in self.cursors
        call c.update(c.A + change, text)
    endfor

    "update main cursor
    let self.begin = current

    call s:Global.update_cursor_highlight()
    let pos = s:Pos(current)
    call cursor(pos[0], pos[1]+1)
    call feedkeys("i", 'n')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.stop(mode) dict
    iunmap <buffer> <esc>
    "iunmap <buffer> <space>
    call self.auto_end()

    let self.mode = ''

    let dot = @.
    let dot = substitute(dot, ".\<BS>", '', 'g')

    let i = 0
    for r in s:R()
        if g:VM_live_editing
            let r.A = self.cursors[i].A | let r.B = r.A | call r.shift(0,0)
        elseif r.A == self.begin
            let r.A += len(s:R())*len(dot) | let r.B = r.A | call r.shift(0,0)
        else
            let r.A += len(dot) | let r.B = r.A | call r.shift(0,0)
        endif
        let i += 1
    endfor


    let self.is_active = 0
    call s:V.Edit.post_process(0,0)
    call s:Global.update_regions()
    call s:Funcs.count_msg(1)
    if a:mode != -1 | call self.start(a:mode, 1) | return | endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.auto_start() dict
    augroup plugin-vm-insert
        au!
        if g:VM_live_editing
            au TextChangedI * silent call b:VM_Selection.Insert.live_insert()
        else
            au InsertLeave * silent call b:VM_Selection.Edit.apply_change()
        endif
    augroup END
endfun

fun! s:Insert.auto_end() dict
    augroup plugin-vm-insert
        au!
    augroup END
endfun


