""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#search#init()
    let s:V        = b:VM_Selection
    let s:v        = s:V.Vars
    let s:Regions  = s:V.Regions

    let s:Funcs    = s:V.Funcs
    let s:Edit     = s:V.Edit

    let s:V.Search = s:Search

    return s:Search
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Search = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.get_pattern(register, regex) dict
    let t = eval('@'.a:register)
    if !a:regex
        let t = self.escape_pattern(t)
        if s:v.whole_word | let t = '\<'.t.'\>' | endif | endif
    return t
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:update_search(p)

    if empty(s:v.search)
        call insert(s:v.search, a:p)    "just started

    elseif index(s:v.search, a:p) < 0   "not in list
        call insert(s:v.search, a:p)
    endif

    let @/ = join(s:v.search, '\|')
    set hlsearch
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.add(...) dict
    """Add a new search pattern."
    let pat = a:0? a:1 : self.get_pattern(s:v.def_reg, 0)
    call s:update_search(pat)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.get_slash_reg() dict
    """Get pattern from current "/" register."
    call s:update_search(self.get_pattern('/', 1))
    call s:Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.update_current(...) dict
    """Update current search pattern to index 0 or <arg>."""

    if empty(s:v.search)          | let @/ = ''
    elseif !a:0                   | let @/ = s:v.search[0]
    elseif a:1 < 0                | let @/ = s:v.search[0]
    elseif a:1 >= len(s:v.search) | let @/ = s:v.search[a:1-1]
    else                          | let @/ = s:v.search[a:1]
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.remove(also_regions) dict
    """Remove a search pattern, and optionally its associated regions."""
    let pats = s:v.search

    if !empty(pats)
        call s:Funcs.count_msg(1)
        let i = input('Which index? ') | let i = str2nr(i)
        if ( i < 0 || i >= len(pats) ) | call s:Funcs.msg('      Wrong index', 0) | return | endif
        let pat = pats[i]
        call remove(pats, i)
        call self.update_current()
    else
        call s:Funcs.msg('No search patters yet.', 0) | return | endif

    if a:also_regions
        let i = len(s:Regions) - 1 | let removed = 0
        while i>=0
            if s:Regions[i].pat ==# pat
                call s:Regions[i].remove()
                let removed += 1 | endif
            let i -= 1 | endwhile

        if removed | call s:V.Global.update_regions() | endif
    endif
    call s:Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.validate() dict
    """Check whether the current search is valid, if not, clear the search."""
    let @/ = join(s:v.search, '\|')
    if empty(@/) | return | endif

    "pattern found, ok
    if search(@/, 'cnw') | return | endif

    while 1
        let i = 0
        for p in s:v.search
            if !search(@/, 'cnw') | call remove(s:v.search, i) | break | endif
        endfor | break
    endwhile
    let @/ = join(s:v.search, '\|')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.check_pattern() dict
    """Update the search patterns if the active search isn't listed."""
    let current = split(@/, '\\|')
    for p in current
        if index(s:v.search, p) == -1 | call self.get_slash_reg() | break | endif
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.escape_pattern(t) dict
    return substitute(escape(a:t, '\/.*$^~[]'), "\n", '\\n', "g")
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Search.case() dict
    if &smartcase              "smartcase        ->  case sensitive
        set nosmartcase
        set noignorecase
        call s:Funcs.msg([['Search -> ', 'WarningMsg'], ['  case sensitive', 'Label']], 0)

    elseif !&ignorecase        "case sensitive   ->  ignorecase
        set ignorecase
        call s:Funcs.msg([['Search -> ', 'WarningMsg'], ['  ignore case', 'Label']], 0)

    else                       "ignore case      ->  smartcase
        set smartcase
        set ignorecase
        call s:Funcs.msg([['Search -> ', 'WarningMsg'], ['  smartcase', 'Label']], 0)
    endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search rewrite
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Try to rewrite last or all patterns, if one of the matches is a substring of
"the selected text.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pattern_found(t, i)
    if @/ == '' | return | endif

    let p = s:v.search[a:i]
    if a:t =~ p || p =~ a:t
        let old = s:v.search[a:i]
        let s:v.search[a:i] = a:t
        call s:V.Global.update_region_patterns(a:t)
        let wm = 'WarningMsg' | let L = 'Label'
        call s:Funcs.msg([['Pattern updated:   [', wm ], [old, L],
                    \     [']  ->  [', wm],              [a:t, L],
                    \     ["]\n", wm]], 1)
        return 1
    endif
endfun

fun! s:Search.rewrite(last) dict
    let r = s:V.Global.is_region_at_pos('.') | if empty(r) | return | endif

    let t = self.escape_pattern(r.txt)

    if a:last
        "add a new pattern if not found
        if !s:pattern_found(t, 0) | call self.add(t) | endif
    else
        "rewrite if found among any pattern, else do nothing
        for i in range ( len(s:v.search) )
            if s:pattern_found(t, i) | break | endif
        endfor
    endif
    call s:Funcs.count_msg(1)
endfun

