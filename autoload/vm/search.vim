""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#search#init() abort
    let s:V        = b:VM_Selection
    let s:v        = s:V.Vars
    let s:F        = s:V.Funcs
    let s:G        = s:V.Global
    return s:Search
endfun

let s:R = { -> s:V.Regions }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Search = {}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:update_search(p) abort
    " Update search patterns, unless s:v.no_search is set.
    if s:v.no_search | return | endif

    if !empty(a:p) && index(s:v.search, a:p) < 0   "not in list
        call insert(s:v.search, a:p)
    endif

    if s:v.eco | let @/ = s:v.search[0]
    else       | call s:Search.join()
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Search.get_pattern(register) abort
    let t = getreg(a:register)
    let t = self.escape_pattern(t)
    let p = s:v.whole_word ? '\<'.t.'\>' : t
    "if whole word, ensure pattern can be found
    let p = search(p, 'nc')? p : t
    return p
endfun


fun! s:Search.add(...) abort
    " Add a new search pattern.
    let pat = a:0? a:1 : self.get_pattern(s:v.def_reg)
    call s:update_search(pat)
endfun


fun! s:Search.add_if_empty(...) abort
    " Add a new search pattern, only if no pattern is set.
    if empty(s:v.search)
        if a:0 | call self.add(a:1)
        else   | call self.add(s:R()[s:v.index].pat)
        endif
    endif
endfun


fun! s:Search.ensure_is_set(...) abort
    " Ensure there is an active search.
    if empty(s:v.search)
        if !len(s:R()) || empty(s:R()[0].txt)
            call self.get_slash_reg()
        else
            call self.add(self.escape_pattern(s:R()[0].txt))
        endif
    endif
endfun


fun! s:Search.get_from_region() abort
    " Get a new search pattern from the selected region, with a fallback.
    let r = s:G.region_at_pos()
    if !empty(r)
        let pat = self.escape_pattern(r.txt)
        call s:update_search(pat) | return
    endif

    "fallback to first region.txt or @/, if no active search
    if empty(s:v.search) | call self.ensure_is_set() | endif
endfun


fun! s:Search.get_slash_reg(...) abort
    " Get pattern from current "/" register. Use backup register if empty.
    if a:0 | let @/ = a:1 | endif
    call s:update_search(getreg('/'))
    if empty(s:v.search) | call s:update_search(s:v.oldsearch[0]) | endif
endfun


fun! s:Search.validate() abort
    " Check whether the current search is valid, if not, clear the search.
    if s:v.eco || empty(s:v.search) | return | endif

    call self.join()

    "pattern found, ok
    if search(@/, 'cnw') | return | endif

    while 1
        let i = 0
        for p in s:v.search
            if !search(@/, 'cnw') | call remove(s:v.search, i) | break | endif
            let i += 1
        endfor
        break
    endwhile
    call self.join()
endfun


fun! s:Search.update_patterns(...) abort
    " Update the search patterns if the active search isn't listed.
    let current = a:0? [a:1] : split(@/, '\\|')
    for p in current
        if index(s:v.search, p) >= 0 | return | endif
    endfor
    if a:0 | call self.get_from_region()
    else   | call self.get_slash_reg()
    endif
endfun


fun! s:Search.escape_pattern(t) abort
    return substitute(escape(a:t, '\/.*$^~[]'), "\n", '\\n', "g")
endfun


fun! s:Search.join(...) abort
    " Join current patterns, optionally replacing them.
    if a:0 | let s:v.search = a:1 | endif
    let @/ = join(s:v.search, '\|')
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search menu and options
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:pattern_rewritten(t, i) abort
    " Return true if a pattern has been rewritten.
    if @/ == '' | return | endif

    let p = s:v.search[a:i]
    if a:t =~ p || p =~ a:t
        let old = s:v.search[a:i]
        let s:v.search[a:i] = a:t
        call s:G.update_region_patterns(a:t)
        call s:Search.join()
        let [ wm, L ] = [ 'WarningMsg', 'Label' ]
        call s:F.msg([['Pattern updated:   [', wm ], [old, L],
                    \     [']  ->  [', wm],          [a:t, L],
                    \     ["]\n", wm]])
        return 1
    endif
endfun


fun! s:Search.rewrite(last) abort
    " Rewrite patterns, if substrings of the selected text.
    let r = s:G.region_at_pos() | if empty(r) | return | endif

    let t = self.escape_pattern(r.txt)

    if a:last
        "add a new pattern if not found
        if !s:pattern_rewritten(t, 0)
            call self.add(t)
        endif
    else
        "rewrite if found among any pattern, else do nothing
        for i in range ( len(s:v.search) )
            if s:pattern_rewritten(t, i) | break | endif
        endfor
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:update_current(...) abort
    " Update current search pattern to index 0 or <arg>.

    if empty(s:v.search)          | let @/ = ''
    elseif !a:0                   | let @/ = s:v.search[0]
    elseif a:1 < 0                | let @/ = s:v.search[0]
    elseif a:1 >= len(s:v.search) | let @/ = s:v.search[a:1-1]
    else                          | let @/ = s:v.search[a:1]
    endif
endfun


fun! s:Search.remove(also_regions) abort
    " Remove a search pattern, and optionally its associated regions.
    let pats = s:v.search

    if !empty(pats)
        let s1 = ['Which index? ', 'WarningMsg']
        let s2 = [string(s:v.search), 'Type']
        call s:F.msg([s1,s2])
        let i = nr2char(getchar())
        if ( i == "\<esc>" ) | return s:F.msg("\tCanceled.\n")             | endif
        if ( i < 0 || i >= len(pats) ) | return s:F.msg("\tWrong index\n") | endif
        call s:F.msg("\n")
        let pat = pats[i]
        call remove(pats, i)
        call s:update_current()
    else
        return s:F.msg('No search patters yet.')
    endif

    if a:also_regions
        let i = len(s:R()) - 1 | let removed = 0
        while i>=0
            if s:R()[i].pat ==# pat
                call s:R()[i].remove()
                let removed += 1
            endif
            let i -= 1
        endwhile

        if removed | call s:G.update_and_select_region() | endif
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Search.case() abort
    " Cycle case settings.
    if &smartcase              "smartcase        ->  case sensitive
        set nosmartcase
        set noignorecase
        call s:F.msg([['Search -> ', 'WarningMsg'], ['  case sensitive', 'Label']])

    elseif !&ignorecase        "case sensitive   ->  ignorecase
        set ignorecase
        call s:F.msg([['Search -> ', 'WarningMsg'], ['  ignore case', 'Label']])

    else                       "ignore case      ->  smartcase
        set smartcase
        set ignorecase
        call s:F.msg([['Search -> ', 'WarningMsg'], ['  smartcase', 'Label']])
    endif
endfun


fun! s:Search.menu() abort
    echohl WarningMsg | echo "1 - " | echohl Type | echon "Rewrite Last Search"   | echohl None
    echohl WarningMsg | echo "2 - " | echohl Type | echon "Rewrite All Search"    | echohl None
    echohl WarningMsg | echo "3 - " | echohl Type | echon "Read From Search"      | echohl None
    echohl WarningMsg | echo "4 - " | echohl Type | echon "Add To Search"         | echohl None
    echohl WarningMsg | echo "5 - " | echohl Type | echon "Remove Search"         | echohl None
    echohl WarningMsg | echo "6 - " | echohl Type | echon "Remove Search Regions" | echohl None
    echohl Directory | echo "Enter an option: " | echohl None
    let c = nr2char(getchar())
    echon c "\t"
    if c == 1
        call self.rewrite(1)
    elseif c == 2
        call self.rewrite(0)
    elseif c == 3
        call self.get_slash_reg()
    elseif c == 4
        call self.get_from_region()
    elseif c == 5
        call self.remove(0)
    elseif c == 6
        call self.remove(1)
    endif
    call feedkeys("\<cr>", 'n')
endfun


" vim: et sw=4 ts=4 sts=4 fdm=indent fdn=1
