" needed by vimrunner
function! VimrunnerPyEvaluateCommandOutput(command)
  redir => output
    silent exe a:command
  redir END
  return output
endfunction

set runtimepath=$VIMRUNTIME
set packpath=
set nocompatible
set runtimepath^=..
source ../plugin/visual-multi.vim

filetype plugin indent on
syntax enable
set et ts=2 sts=2 sw=2
