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
