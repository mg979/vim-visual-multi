"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Store registers, initialize script vars and temporary buffer mappings.
"Some functions are registered in s:Funcs, that is returned to the global
"script, and then included in the global variable, so that they can be
"accessed from anywhere.

fun! vm#funcs#init()
    let s:V = b:VM_Selection | let s:v = s:V.Vars | let s:Global = s:V.Global
    let s:V.Funcs = s:Funcs

    call vm#maps#start()

    let s:v.def_reg = s:default_reg()
    let s:v.oldreg = s:Funcs.get_reg()
    let s:v.oldsearch = [getreg("/"), getregtype("/")]
    let s:v.oldvirtual = &virtualedit
    set virtualedit=onemore
    let s:v.oldwhichwrap = &whichwrap
    set ww=<,>,h,l

    let s:v.search = []
    let s:v.move_from_back = 0

    let s:v.oldcase = [&smartcase, &ignorecase]
    let s:v.index = -1
    let s:v.direction = 1
    let s:v.silence = 0
    let s:v.only_this = 0
    let s:v.only_this_all = 0

    call s:augroup_start()
    return s:Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Backup/restore buffer state on buffer change
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:key = { -> 'g:VM_Global.'.bufnr("%") }

fun! vm#funcs#buffer_leave()
    if !empty(b:VM_Selection)
        let s:v.pos = getpos('.')
        exe 'let '.s:key().' = copy(b:VM_Selection)'
        call vm#funcs#reset(1)
    endif
endfun

fun! vm#funcs#buffer_enter()
    let b:VM_Selection = {}

    if !empty(get(g:VM_Global, bufnr("%"), {}))
        call vm#init_buffer(1)
        call setmatches(s:v.matches)
        call setpos('.', s:v.pos)
        call vm#commands#add_under(0, s:v.whole_word, 0, 1)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#reset(...)
    let &virtualedit = s:v.oldvirtual
    let &whichwrap = s:v.oldwhichwrap
    let &smartcase = s:v.oldcase[0]
    let &ignorecase = s:v.oldcase[1]
    call s:restore_regs()
    call vm#maps#end()
    let b:VM_Selection = {}
    let g:VM_Global.is_active = 0

    if !a:0    "exiting manually
        call s:Funcs.msg('Exited Visual-Multi.')
        call remove(g:VM_Global, bufnr("%"))
    endif

    call s:augroup_end()
    call clearmatches()
    set nohlsearch
    call garbagecollect()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs = {}

fun! s:default_reg()
    let clipboard_flags = split(&clipboard, ',')
    if index(clipboard_flags, 'unnamedplus') >= 0
        return "+"
    elseif index(clipboard_flags, 'unnamed') >= 0
        return "*"
    else
        return "\""
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.get_reg() dict
    let r = s:v.def_reg
    return [r, getreg(r), getregtype(r)]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:Funcs.set_reg(text) dict
    let r = s:v.def_reg
    call setreg(r, a:text, 'v')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:restore_regs()
    let r = s:v.oldreg | let s = s:v.oldsearch
    call setreg(r[0], r[1], r[2])
    call setreg("/", s[0], s[1])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.msg(text) dict
    if !s:v.silence
        exe "echohl" g:VM_Message_hl
        echo a:text
        echohl None
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.case_search()
    if &smartcase              "smartcase        ->  case sensitive
        set nosmartcase
        set noignorecase
        call self.msg('Search ->  case sensitive')

    elseif !&ignorecase        "case sensitive   ->  ignorecase
        set ignorecase
        call self.msg('Search ->  ignore case')

    else                       "ignore case      ->  smartcase
        set smartcase
        set ignorecase
        call self.msg('Search ->  smartcase')
    endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.update_search()
    let r = s:Global.is_region_at_pos('.')
    if empty(r) | return | endif
    call s:update_search(escape(r.txt, '\|'), 1)
endfun

fun! s:Funcs.set_search() dict
    call s:update_search(s:pattern(s:v.def_reg, 0), 0)
endfun

fun! s:Funcs.read_from_search() dict
    call s:update_search(s:pattern('/', 1), 0)
endfun

fun! s:Funcs.check_pattern() dict
    let current = split(@/, '\\|')
    for p in current
        if index(s:v.search, p) == -1 | call s:Funcs.read_from_search() | endif
        break
    endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pattern(register, regex)
    let t = eval('@'.a:register)
    if !a:regex
        let t = escape(t, '.\|')
        let t = substitute(t, '\n', '\\n', 'g')
        if s:v.whole_word | let t = '\<'.t.'\>' | endif | endif
    return t
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:update_search(p, update)

    if empty(s:v.search)
        call insert(s:v.search, a:p)       "just started

    elseif a:update                     "updating a match

        "if there's a match that is a substring of
        "the selected text, replace it with the new one
        let i = 0
        for p in s:v.search
            if a:p =~ p
                let s:v.search[i] = a:p
                break | endif
            let i += 1
        endfor

    elseif index(s:v.search, a:p) < 0   "not in list

        call insert(s:v.search, a:p)
    endif

    let @/ = join(s:v.search, '\|')
    set hlsearch
    call s:Funcs.msg('Current search: '.string(s:v.search))
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:augroup_start()
    augroup plugin-visual-multi
        au!
        au CursorMoved * call vm#commands#move()
    augroup END
endfun

fun! s:augroup_end()
    augroup plugin-visual-multi
        au!
    augroup END
endfun

