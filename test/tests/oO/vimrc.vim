" needed by vimrunner
function! VimrunnerPyEvaluateCommandOutput(command)
  return execute(a:command)
endfunction

let g:loaded_remote_plugins = 1

set runtimepath=$VIMRUNTIME
set packpath=
set nocompatible
set runtimepath^=..
source ../plugin/visual-multi.vim

filetype plugin indent on
syntax enable
set et ts=2 sts=2 sw=2
