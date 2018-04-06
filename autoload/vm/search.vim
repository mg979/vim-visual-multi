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

fun! s:Search.update() dict
    let r = s:Global.is_region_at_pos('.')
    if empty(r) | return | endif
    call s:update_search(escape(r.txt, '\|'), 1)
endfun

fun! s:Search.set() dict
    call s:update_search(s:pattern(s:v.def_reg, 0), 0)
endfun

fun! s:Search.read() dict
    call s:update_search(s:pattern('/', 1), 0)
endfun

fun! s:Search.check_pattern() dict
    let current = split(@/, '\\|')
    for p in current
        if index(s:v.search, p) == -1 | call self.read() | endif
        break
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


