"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set vim variable to VM compatible values

fun! vm#variables#set() abort
  let F = b:VM_Selection.Funcs
  let v = b:VM_Selection.Vars

  " disable folding, but keep winline
  if &foldenable
    call F.Scroll.get(1)
    let v.oldfold = 1
    set nofoldenable
    call F.Scroll.restore()
  endif

  if g:VM_case_setting ==? 'smart'
    set smartcase
    set ignorecase
  elseif g:VM_case_setting ==? 'sensitive'
    set nosmartcase
    set noignorecase
  elseif g:VM_case_setting ==? 'ignore'
    set nosmartcase
    set ignorecase
  endif

  "force default register
  set clipboard=

  "disable conceal
  let &l:conceallevel = vm#comp#conceallevel()
  set concealcursor=

  set virtualedit=onemore
  set ww=h,l,<,>
  set lz

  if get(g:, 'VM_cmdheight', 1) > 1
    let &ch = g:VM_cmdheight
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init VM variables

fun! vm#variables#init() abort
  let F = b:VM_Selection.Funcs
  let v = b:VM_Selection.Vars

  "init search
  let v.def_reg          = F.default_reg()
  let v.oldreg           = F.get_reg()
  let v.oldregs_1_9      = F.get_regs_1_9()
  let v.oldsearch        = [getreg("/"), getregtype("/")]
  let v.noh              = !v:hlsearch ? 'noh|' : ''

  "store old vars
  let v.oldhls           = &hlsearch
  let v.oldvirtual       = &virtualedit
  let v.oldwhichwrap     = &whichwrap
  let v.oldlz            = &lz
  let v.oldch            = &ch
  let v.oldcase          = [&smartcase, &ignorecase]
  let v.indentkeys       = &indentkeys
  let v.cinkeys          = &cinkeys
  let v.synmaxcol        = &synmaxcol
  let v.oldmatches       = getmatches()
  let v.clipboard        = &clipboard
  let v.textwidth        = &textwidth
  let v.conceallevel     = &conceallevel
  let v.concealcursor    = &concealcursor
  let v.softtabstop      = &softtabstop
  let v.statusline       = &statusline

  "init new vars

  let v.search           = []
  let v.IDs_list         = []
  let v.ID               = 0
  let v.index            = -1
  let v.direction        = 1
  let v.nav_direction    = 1
  let v.auto             = 0
  let v.silence          = 0
  let v.eco              = 0
  let v.single_region    = 0
  let v.using_regex      = 0
  let v.multiline        = 0
  let v.yanked           = 0
  let v.merge            = 0
  let v.insert           = 0
  let v.whole_word       = 0
  let v.winline          = 0
  let v.restore_scroll   = 0
  let v.find_all_overlap = 0
  let v.dot              = ''
  let v.no_search        = 0
  let v.visual_regex     = 0
  let v.use_register     = v.def_reg
  let v.deleting         = 0
  let v.vmarks           = [getpos("'<"), getpos("'>")]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset vim variables to previous values

fun! vm#variables#reset() abort
  let v = b:VM_Selection.Vars

  if !v.oldhls
    set nohlsearch
  endif

  let &virtualedit = v.oldvirtual
  let &whichwrap   = v.oldwhichwrap
  let &smartcase   = v.oldcase[0]
  let &ignorecase  = v.oldcase[1]
  let &lz          = v.oldlz
  let &cmdheight   = v.oldch
  let &clipboard   = v.clipboard

  let &l:indentkeys    = v.indentkeys
  let &l:cinkeys       = v.cinkeys
  let &l:synmaxcol     = v.synmaxcol
  let &l:textwidth     = v.textwidth
  let &l:softtabstop   = v.softtabstop
  let &l:conceallevel  = v.conceallevel
  let &l:concealcursor = v.concealcursor

  if get(g:, 'VM_set_statusline', 2)
    let &l:statusline  = v.statusline
  endif

  silent! unlet b:VM_skip_reset_once_on_bufleave
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset VM global variables

fun! vm#variables#reset_globals()
  let b:VM_Backup = {}
  let b:VM_Selection = {}
  let g:Vm.buffer = 0
  let g:Vm.extend_mode = 0
  let g:Vm.finding = 0
endfun

" vim: et ts=2 sw=2 sts=2 tw=79 :
