" needed by vimrunner
function! VimrunnerPyEvaluateCommandOutput(command)
  return execute(a:command)
endfunction

let g:loaded_remote_plugins = 1

set runtimepath=$VIMRUNTIME
set packpath=
set nocompatible
set runtimepath^=..
set ignorecase smartcase
set noswapfile
source ../plugin/visual-multi.vim
