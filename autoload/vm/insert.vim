""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Insert = {'index': -1, 'cursors': [], 'begin': 0, 'is_active': 0, 'mode': ''}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#insert#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars
    let s:G       = s:V.Global

    let s:R       = {      -> s:V.Regions               }
    let s:X       = {      -> g:VM.extend_mode          }
    let s:Byte    = { pos  -> s:V.Funcs.pos2byte(pos)   }
    let s:append  = { m    -> index(['a', 'A'], m) >= 0 }

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

    return C
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.key(type) dict

    if a:type ==# 'I'
        call vm#commands#merge_to_beol(0, 0)
        call self.start('i')

    elseif a:type ==# 'A'
        call vm#commands#merge_to_beol(1, 0)
        call self.start('a')

    elseif a:type ==# 'o'
        call vm#commands#merge_to_beol(1, 0)
        call self.start('o')

    elseif a:type ==# 'O'
        call vm#commands#merge_to_beol(0, 0)
        call self.start('O')

    elseif a:type ==# 'a'
        if s:X()
            if s:v.direction | call vm#commands#invert_direction() | endif
            call s:G.change_mode(1) | endif
        call self.start('a')

    else
        if s:X()
            if !s:v.direction | call vm#commands#invert_direction() | endif
            call s:G.change_mode(1) | endif
        call self.start('i')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.start(mode) dict
    if g:VM_live_editing | call s:V.Live.start(a:mode) | return | endif
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'begin' is the initial offset, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------

    let r              = s:G.select_region(-1)
    let self.index     = r.index
    let self.begin     = s:Byte('.')
    let self.is_active = 1
    let self.mode      = a:mode

    for r in s:R()
        "remove the regular cursor highlight, add new cursor
        let A = s:append(a:mode)? r.A+1 : r.A
        call add(self.cursors, s:Cursor.new(A))
        if r.index == self.index | call r.remove_highlight() | endif
    endfor

    "start tracking text changes
    call self.auto_start()

    inoremap <silent> <buffer> <esc>   <esc>:call b:VM_Selection.Insert.stop(-1)<cr>
    call s:G.update_cursor_highlight()

    "start insert mode and break the undo point
    let keys = (a:mode=='c'? 'i': a:mode)."\<c-g>u"
    call feedkeys(keys, 'n')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.stop(mode) dict
    iunmap <buffer> <esc>
    "iunmap <buffer> <space>
    call self.auto_end() | let s:v.eco = 1

    let dot = @.
    let n = 0

    "replace backspaces
    while 1
        if match(dot, "\<BS>") > 0
            let dot = substitute(dot, "\<BS>", '', '')
            let n += 1
        else | break | endif | endwhile

    let Len = len(dot) - n

    let i = 0
    for r in s:R()
        let s = s:append(self.mode)? 0 : 1
        if r.A == self.begin
            call r.bytes([len(s:R())*Len - s, 0])
        else
            call r.bytes([Len - s, 0])
        endif
        let i += 1
    endfor

    let self.mode = ''

    let self.is_active = 0
    let s:v.storepos = getpos('.')
    call s:V.Edit.post_process(0,0)
    if a:mode != -1 | call self.start(a:mode, 1) | return | endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Insert.auto_start() dict
    augroup plugin-vm-insert
        au!
        au InsertLeave * silent call b:VM_Selection.Edit.apply_change()
    augroup END
endfun

fun! s:Insert.auto_end() dict
    augroup plugin-vm-insert
        au!
    augroup END
endfun


