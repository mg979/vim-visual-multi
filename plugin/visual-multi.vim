""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:         visual-multi.vim
" Description:  multiple selections in vim
" Mantainer:    Gianmaria Bajo <mg1979.git@gmail.com>
" Url:          https://github.com/mg979/vim-visual-multi
" Licence:      The MIT License (MIT)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if v:version < 704 || v:version == 704 && !has("patch330")
  echomsg '[vim-visual-multi] Vim version 7.4.330 is required'
  finish
endif

"Initialize variables

if exists("g:loaded_visual_multi")
  finish
endif
let g:loaded_visual_multi = 1

let s:save_cpo = &cpo
set cpo&vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

com! -nargs=? -complete=customlist,vm#themes#complete
      \ VMTheme  call vm#themes#load(<q-args>)
com!    VMConfig call vm#special#config#start()
com!    VMDebug  call vm#special#help#debug()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:Vm = { 'hi'          : {},
      \ 'is_active'        : 0,
      \ 'extend_mode'      : 0,
      \ 'selecting'        : 0,
      \ 'mappings_enabled' : 0,
      \ 'last_ex'          : '',
      \ 'last_normal'      : '',
      \ 'last_visual'      : '',
      \ 'oldupdate'        : exists("##TextYankPost") ? 0 : &updatetime,
      \}

let g:VM_highlight_matches = get(g:, 'VM_highlight_matches', 'underline')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Global mappings

call vm#plugs#permanent()
call vm#maps#default()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands

augroup VM_start
    au!
    au ColorScheme  * call vm#themes#init()
augroup END

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &cpo = s:save_cpo
unlet s:save_cpo
