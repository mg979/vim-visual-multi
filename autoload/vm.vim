""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" b:VM_Selection (= s:V) contains Regions, Matches, Vars (= s:v = plugin variables)

" s:Global holds the Global class methods
" s:Regions contains the regions with their contents
" s:Matches contains the matches as they are registered with matchaddpos()
" s:v.matches contains the current matches as read with getmatches()

fun! vm#init_buffer(empty, ...)
    """If already initialized, return current instance."""

    if !empty(b:VM_Selection) | return s:V | endif

    let b:VM_Selection = {'Vars': {}, 'Regions': [], 'Matches': [], 'Funcs': {}}

    if a:0  "restoring buffer
        exe 'let b:VM_Selection = g:VM_Global.'.bufwinid("%")

    else    "initialize
        exe 'let g:VM_Global.'.bufwinid("%").' = b:VM_Selection'
    endif

    let g:VM_Global.is_active = 1

    let s:V        = b:VM_Selection
    let s:V.Global = s:Global

    let s:v        = s:V.Vars
    let s:Regions  = s:V.Regions
    let s:Matches  = s:V.Matches

    let s:Funcs    = vm#funcs#init(a:empty)
    let s:Search   = s:V.Search

    let s:byte = funcref('s:Funcs.byte')

    call s:Funcs.msg('Visual-Multi started. Press <esc> to exit.')
    call vm#region#init()

    return s:V
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Global = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.get_region() dict
    """Get the region under cursor, or create a new one if there is none."""

    let R = self.is_region_at_pos('.')
    if empty(R) | let R = vm#region#new(0) | endif

    let s:v.matches = getmatches()
    call self.select_region(R.index)
    call s:Search.check_pattern()
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.new_cursor() dict
    """Create a new cursor if there is't already a region."""

    let R = self.is_region_at_pos('.')
    if !empty(R) | call self.select_region(R.index) | return R | endif

    let R = vm#region#new(1)

    let s:v.matches = getmatches()
    call self.select_region(R.index)
    call s:Funcs.count_msg(0)
    return R
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_highlight(...) dict
    """Update highlight for all regions."""

    for r in s:Regions
        call r.update_highlight()
    endfor

    call setmatches(s:v.matches)
    call self.update_cursor_highlight()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_cursor_highlight(...) dict
    """Set cursor highlight, depending on extending mode."""

    highlight clear MultiCursor
    if self.all_empty() && !g:VM_Global.extend_mode
        exe "highlight link MultiCursor ".g:VM_Mono_Cursor_hl
    else
        exe "highlight link MultiCursor ".g:VM_Normal_Cursor_hl
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.all_empty() dict
    """If not all regions are empty, turn on extend mode."""

    for r in s:Regions
        if r.a != r.b
            if !g:VM_Global.extend_mode | call vm#commands#change_mode() | endif
            return 0 | endif
    endfor
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_regions() dict
    """Force regions update."""

    for r in s:Regions | call r.update(r.l, r.a, r.b) | endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.collapse_regions() dict
    """Collapse regions to cursors and turn off extend mode."""

    for r in s:Regions
        if r.a != r.b | call r.update(r.l, r.a, r.a) | endif
    endfor
    let g:VM_Global.extend_mode = 0
    call self.update_regions()
    call self.update_highlight()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region(i) dict
    """Adjust cursor position of the region at index, then return the region."""

    if a:i >= len(s:Regions) | let i = 0
    elseif a:i<0 | let i = len(s:Regions) - 1
    else | let i = a:i | endif

    let R = s:Regions[i]
    let pos = s:v.direction ? R.b : R.a
    call cursor([R.l, pos])
    let s:v.index = i
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region_at_pos(pos) dict
    """Try to select a region at the given position."""

    let r = self.is_region_at_pos(a:pos)
    if !empty(r)
        return self.select_region(r.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.is_region_at_pos(pos) dict
    """Find if the cursor is on a highlighted region.
    "Return an empty dict otherwise."""

    "pos can be a string (like '.') or a list
    if type(a:pos) == v:t_string
        let pos = getpos(a:pos)[1:2]
        let pos = s:byte([pos[0], pos[1]])
    else
        let pos = s:byte([a:pos[0], a:pos[1]])
    endif

    for r in s:Regions
        let a = s:byte([r.l, r.a])
        let b = s:byte([r.l, r.b])
        if pos >= a && pos <= b
            return r | endif | endfor
    return {}
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_indices() dict
    """Adjust region indices."""

    let i = 0
    for r in s:Regions
        let r.index = i
        let i += 1
    endfor
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Merging regions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.merge_cursors()
    """Merge overlapping cursors."""

    let cursors_pos = map(s:Regions, 'v:val.A')
    echom string(cursors_pos)
    while 1
        let i = 0
        for c in cursors_pos
            if count(cursors_pos, c) > 1
                call s:Regions[i].remove() | break | endif
            let i += 1
        endfor
        break
    endwhile
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.merge_regions(...) dict
    """Merge overlapping regions."""

    let lines = {}
    let storepos = getpos('.')

    "find lines with regions
    for r in s:Regions
        "called a merge for a specific line
        if a:0 && r.l != a:1 | continue | endif
        "add region index to indices for that line
        let lines[r.l] = get(lines, r.l, [])
        call add(lines[r.l], r.index)
    endfor

    "remove lines and indices without multiple regions
    let lines = filter(lines, 'len(v:val) > 1')
    let to_remove = []

    "find overlapping regions for each line with multiple regions
    for indices in values(lines)
        let n = 0 | let max = len(indices) - 1

        for i in indices
            while (n < max)
                let i1 = indices[n] | let i2 = indices[n+1] | let n += 1
                let this = s:Regions[i1] | let next = s:Regions[i2]

                let overlap = ( this.B >= next.A ) && ( this.A <= next.A ) ||
                            \ ( next.B >= this.A ) && ( next.A <= this.A )

                "merge regions if there is overlap with next one
                if overlap
                    call next.update(this.l, min([this.a, next.a]), max([this.b, next.b]))
                    call add(to_remove, this)
                endif | endwhile | endfor | endfor

    " remove old regions and update highlight
    for r in to_remove | call r.remove() | endfor
    call self.update_highlight()

    "restore cursor position
    call self.select_region_at_pos(storepos)
    call s:Funcs.count_msg(0)
endfun

