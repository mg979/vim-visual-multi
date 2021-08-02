""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:         visual-multi.vim
" Description:  multiple selections in vim
" Mantainer:    Gianmaria Bajo <mg1979.git@gmail.com>
" Url:          https://github.com/mg979/vim-visual-multi
" Licence:      The MIT License (MIT)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Guard {{{
if v:version < 800
  echomsg '[vim-visual-multi] Vim version 8 is required'
  finish
endif

if exists("g:loaded_visual_multi")
  finish
endif
let g:loaded_visual_multi = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

com! -nargs=? -complete=customlist,vm#themes#complete VMTheme call vm#themes#load(<q-args>)

com! -bar VMDebug  call vm#special#commands#debug()
com! -bar VMClear  call vm#hard_reset()
com! -bar VMLive   call vm#special#commands#live()

com! -bang  -nargs=?       VMRegisters call vm#special#commands#show_registers(<bang>0, <q-args>)
com! -range -bang -nargs=? VMSearch    call vm#special#commands#search(<bang>0, <line1>, <line2>, <q-args>)

" Deprecated commands {{{1
com! -bang VMFromSearch call vm#special#commands#deprecated('VMFromSearch')
"}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:Vm = { 'hi'          : {},
      \ 'buffer'           : 0,
      \ 'extend_mode'      : 0,
      \ 'finding'          : 0,
      \ 'mappings_enabled' : 0,
      \ 'last_ex'          : '',
      \ 'last_normal'      : '',
      \ 'last_visual'      : '',
      \ 'registers'        : {'"': [], '-': []},
      \ 'oldupdate'        : exists("##TextYankPost") ? 0 : &updatetime,
      \}

let g:VM_highlight_matches = get(g:, 'VM_highlight_matches', 'underline')


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Global mappings

call vm#plugs#permanent()
call vm#maps#default()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Registers

let g:VM_persistent_registers = get(g:, 'VM_persistent_registers', 0)

fun! s:vm_registers()
  if exists('g:VM_PERSIST') && !g:VM_persistent_registers
    unlet g:VM_PERSIST
  elseif exists('g:VM_PERSIST')
    let g:Vm.registers = deepcopy(g:VM_PERSIST)
  endif
endfun

fun! s:vm_persist()
  if exists('g:VM_PERSIST') && !g:VM_persistent_registers
    unlet g:VM_PERSIST
  elseif g:VM_persistent_registers
    let g:VM_PERSIST = deepcopy(g:Vm.registers)
  endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands

augroup VM_start
  au!
  au VimEnter     * call s:vm_registers()
  au VimLeavePre  * call s:vm_persist()
augroup END


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! VMInfos() abort
    if !exists('b:VM_Selection') || empty(b:VM_Selection)
        return {}
    endif

    let infos = {}
    let VM = b:VM_Selection

    let m = g:Vm.mappings_enabled ?    'M' : 'm'
    let s = VM.Vars.single_region ?    'S' : 's'
    let l = VM.Vars.multiline ?        'V' : 'v'

    let infos.current = VM.Vars.index + 1
    let infos.total = len(VM.Regions)
    let infos.ratio = infos.current . ' / ' . infos.total
    let infos.patterns = VM.Vars.search
    let infos.status = m.s.l
    return infos
endfun

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: ft=vim et sw=2 ts=2 sts=2 fdm=marker
