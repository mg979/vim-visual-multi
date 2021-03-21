" needed by vimrunner
function! VimrunnerPyEvaluateCommandOutput(command)
  return execute(a:command)
endfunction

set runtimepath=$VIMRUNTIME
set packpath=
set nocompatible
set runtimepath^=..
set ignorecase smartcase
source ../plugin/visual-multi.vim
