""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Live Insert
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Live = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#live#init()
    let s:V       = b:VM_Selection
    let s:v       = s:V.Vars
    let s:G       = s:V.Global
    let s:F       = s:V.Funcs
    let s:Search  = s:V.Search

    let s:R       = {      -> s:V.Regions               }
    let s:X       = {      -> g:VM.extend_mode          }
    let s:size    = {      -> line2byte(line('$') + 1)  }
    let s:Byte    = { pos  -> s:F.pos2byte(pos)         }
    let s:Pos     = { byte -> s:F.byte2pos(byte)        }
    let s:Cur     = { byte -> s:F.Cursor(byte)          }
    let s:append  = { m    -> index(['a', 'A'], m) >= 0 }
    let s:newline = { m    -> index(['o', 'O'], m) >= 0 }

    return s:Live
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.start(mode) dict
    "--------------------------------------------------------------------------

    "Initialize Insert Mode dict. 'Begin' is the initial offset, and will be
    "used to track all changes from that point, to apply them on all cursors

    "--------------------------------------------------------------------------
    let I = self
    let s:V.Insert.is_active = 1

    let R           = s:G.select_region_at_pos('.')
    let I.index     = R.index
    let I.Begin     = s:append(a:mode)? R.A+1 : R.A
    let I.begin     = [R.l, s:append(a:mode)? R.a+1 : R.a]
    let I.size      = s:size()
    let I.mode      = a:mode
    let I.cursors   = []
    let I.lines     = {}
    let I.change    = 0

    call clearmatches()

    for r in s:R()
        let A = s:append(a:mode)? r.A+1 : r.A
        let C = s:Cursor.new(A, r.l, s:append(a:mode)? r.a+1 : r.a)
        call add(I.cursors, C)

        call s:V.Edit.extra_spaces(r, 0)

        if !has_key(I.lines, r.l)
            let I.lines[r.l] = s:Line.new(r.l, C)
            let first_a = r.a | let nth = 0 | let C.nth = 0
        else
            let nth += 1
            let C.nth = nth
            "not the first cursor in its line? change main cursor and restart
            if r == R
                let A = I.lines[r.l].cursors[0].a
                call cursor(r.l, first_a)
                call s:G.select_region_at_pos('.')
                call self.start(a:mode)
                return
            else
                call add(I.lines[r.l].cursors, C)
            endif
        endif
    endfor

    "start tracking text changes
    call I.auto_start()

    inoremap <silent> <expr> <buffer> <esc>   pumvisible()?
                \ "\<esc>:call b:VM_Selection.Live.insert(1)\<cr>:call b:VM_Selection.Live.stop()\<cr>" :
                \ "\<esc>:call b:VM_Selection.Live.stop()\<cr>"

    call s:G.update_cursor_highlight()

    "start insert mode and break the undo point
    let keys = (a:mode=='c'? 'i': a:mode)."\<c-g>u"
    call feedkeys(keys, 'n')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Live insert mode
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.insert(...) dict
    "TextChangedI

    let I  = self
    let L  = I.lines
    let ln = getpos('.')[1]

    "line change
    if ln != I.begin[0]
        for l in keys(I.lines)
            let I.lines[l].l = I.lines[l].l + ln - I.begin[0]
        endfor
        let I.begin = getpos('.')[1:2]
    endif

    let pos      = I.begin[1]
    "popup eats one char on esc, give one more space
    let cur      = a:0? getpos('.')[2]+1 : getpos('.')[2]
    let I.change = cur - pos
    let text     = getline(ln)[(pos-1):(cur-2)]

    for l in keys(L)
        call L[l].update(I.change, text)
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.paste() dict
    call s:G.select_region(-1)
    call s:V.Edit.paste(1, 1, 1)
    call s:G.select_region(self.index)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.return() dict

    call s:V.Edit.run_normal('s$d', 1, 1, 0)
    call s:V.Edit.run_ex("call append(line('.'), '')")
    let old = s:v.multiline
    let s:v.multiline = 1
    normal lp
    call s:V.Edit.run_normal('==', 0, 1, 0)
    call s:V.Edit.run_normal('^', 1, 1, 0)
    let s:v.multiline = old
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.stop() dict
    iunmap <buffer> <esc>
    call self.auto_end() | let s:v.eco = 1

    let i = 0
    for r in s:R()
        let c = self.cursors[i]
        let a = s:append(self.mode)? c.a-1 : c.a 
        call r.update_cursor([c.l, a + self.change + self.change*c.nth])
        if r.index == self.index | let s:v.storepos = [r.l, r.a] | endif
        let i += 1
    endfor

    let self.mode = ''
    let s:V.Insert.is_active = 0

    call s:V.Edit.post_process(0,0)
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Cursor = {}

"--------------------------------------------------------------------------

"in Insert Mode we will forget about the regions, and work with cursors at
"byte offsets; from the final offset, we'll update the real regions later

"--------------------------------------------------------------------------


fun! s:Cursor.new(byte, ln, col) dict
    "Create new cursor.
    let C        = copy(self)
    let C.index  = len(s:Live.cursors)
    let C.A      = a:byte
    let C.txt    = ''
    let C.l      = a:ln
    let C.a      = a:col
    let C.active = ( C.index == s:Live.index )
    let C.hl  = matchaddpos('MultiCursor', [[C.l, C.a]], 40)

    return C
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Cursor.update(l, c) dict
    "Update cursors positions and highlight.
    let C = self
    if C.l != a:l
        let C.l = a:l
        let C.a = a:c
    endif
    let C.A = s:Byte([C.l, a:c])

    call matchdelete(C.hl)
    let C.hl  = matchaddpos('MultiCursor', [[C.l, a:c]], 40)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Line class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Line = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Line.new(line, cursor) dict
    let L         = copy(self)
    let L.l       = a:line
    let L.txt     = getline(a:line)
    let L.cursors = [a:cursor]

    return L
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Line.update(change, text) dict
    let change = 0
    let text = self.txt
    for c in self.cursors
        let a = c.a>1? c.a-2 : c.a-1
        let b = c.a-1
        let t1   = text[:a+change]
        let t2   = text[b+change:]
        let text = t1 . a:text . t2
        if c.a==1 | let text = text[1:] | endif
        "echom t1 "|||" t2 "///" text
        let change += a:change
        call c.update(self.l, c.a+change)
    endfor
    call setline(self.l, text)
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Live.auto_start() dict
    augroup plugin-vm-insert
        au!
        au TextChangedI * call b:VM_Selection.Live.insert()
    augroup END
endfun

fun! s:Live.auto_end() dict
    augroup plugin-vm-insert
        au!
    augroup END
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


