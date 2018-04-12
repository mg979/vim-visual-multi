""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#search#init()
    let s:V        = b:VM_Selection
    let s:v        = s:V.Vars
    let s:Global   = s:V.Global
    let s:Regions  = s:V.Regions
    let s:Funcs    = s:V.Funcs
    let s:V.Search = s:Search

    return s:Search
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Search = {}

fun! s:Search.case() dict
    if &smartcase              "smartcase        ->  case sensitive
        set nosmartcase
        set noignorecase
        call s:Funcs.msg('Search ->  case sensitive')

    elseif !&ignorecase        "case sensitive   ->  ignorecase
        set ignorecase
        call s:Funcs.msg('Search ->  ignore case')

    else                       "ignore case      ->  smartcase
        set smartcase
        set ignorecase
        call s:Funcs.msg('Search ->  smartcase')
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.rewrite() dict
    let r = s:Global.is_region_at_pos('.')
    if empty(r) | return | endif
    call s:update_search(escape(r.txt, '\|'), 1)
    call s:Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.set() dict
    call s:update_search(s:pattern(s:v.def_reg, 0), 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.get_slash_reg() dict
    call s:update_search(s:pattern('/', 1), 0)
    call s:Funcs.count_msg(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Search.update(...) dict
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
        if ( i < 0 || i >= len(pats) ) | call s:Funcs.msg('      Wrong index') | return | endif
        let pat = pats[i]
        call remove(pats, i)
        call self.update()
    else
        call s:Funcs.msg('No search patters yet.') | return | endif

    if a:also_regions
        let i = len(s:Regions) - 1 | let removed = 0
        while i>=0
            if s:Regions[i].pat ==# pat
                call s:Regions[i].remove()
                let removed += 1 | endif
            let i -= 1 | endwhile

        if removed | call s:Global.update_regions() | endif
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

fun! s:pattern(register, regex)
    let t = eval('@'.a:register)
    if !a:regex
        let t = escape(t, '.\|')
        let t = substitute(t, '\n', '\\n', 'g')
        if s:v.whole_word | let t = '\<'.t.'\>' | endif | endif
    return t
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:update_search(p, update)

    if empty(s:v.search)
        call insert(s:v.search, a:p)    "just started

    elseif a:update                     "updating a match

        "if there's a match that is a substring of
        "the selected text, replace it with the new one
        let i = 0
        for p in s:v.search
            if a:p =~ p || p =~ a:p
                let old = s:v.search[i]
                let s:v.search[i] = a:p
                call s:Global.update_patterns(a:p)
                break | endif
            let i += 1
        endfor

        call s:Funcs.msg('Pattern updated:           '.old.'  ->  '.a:p)

    elseif index(s:v.search, a:p) < 0   "not in list

        call insert(s:v.search, a:p)
    endif

    let @/ = join(s:v.search, '\|')
    set hlsearch
endfun


