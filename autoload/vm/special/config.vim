
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#config#start()
  """Call VM configurator."""

  redraw!
  let opt = [
            \['Default mappings',               "VM_default_mappings"],
            \['Mouse mappings',                 "VM_mouse_mappings"],
            \['Reselect first insert',          "VM_reselect_first_insert"],
            \['Reselect first always',          "VM_reselect_first_always"],
            \['Case setting',                   "VM_case_setting"],
            \['Pick first after n cursors',     "VM_pick_first_after_n_cursors"],
            \['Dynamic synmaxcol',              "VM_dynamic_synmaxcol"],
            \['Disable syntax in insert-mode',  "VM_disable_syntax_in_imode"],
            \['Auto-exit with 1 cursor left',   "VM_exit_on_1_cursor_left"],
            \['Manual infoline',                "VM_manual_infoline"],
            \]

  echohl Special    | echo "\nvim-visual-multi configuration. Select an option you want to change, or '?' for help.\n\n"
  for i in range(len(opt))
    let st = i.". ".opt[i][0] | let lst = len(st) | let tabs = ''
    for n in range(5-lst/8)
      let tabs .= "\t"
    endfor

    echohl WarningMsg | echo i.". "
    echohl Type       | echon opt[i][0].tabs
    echohl Number     | echon eval("g:".opt[i][1])
  endfor
  echohl None

  let o = input("\nEnter an option to change, or nothing to generate configuration > ")
  if empty(o) | call vm#special#config#generate() | return | endif

  if o == '?'
    call vm#special#config#help() | return
  elseif o == 4
    if g:VM_case_setting == 'smart'         | let g:VM_case_setting = 'sensitive'
    elseif g:VM_case_setting == 'sensitive' | let g:VM_case_setting = 'ignore'
    else                                    | let g:VM_case_setting = 'smart' | endif
  elseif o == 5
    let new = input("\nEnter a new value for g:VM_pick_first_after_n_cursors (0 disables it) > ")
    if !empty(new) | let g:VM_pick_first_after_n_cursors = new | endif
  elseif o == 6
    let new = input("\nEnter a new value for g:VM_dynamic_synmaxcol (0 disables it) > ")
    if !empty(new) | let g:VM_dynamic_synmaxcol = new | endif
  else
    exe "let g:".opt[o][1]." = ".!eval("g:".opt[o][1])
  endif
  redraw!
  call vm#special#config#start()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#config#generate()
  """Copy the current config to registers."""
  echohl WarningMsg | echo "\n\nYour configuration has been copied to the \" and + registers.\n"

  let config = [
        \'"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""',
        \'" vim-visual-multi configuration',
        \'',
        \'let g:VM_default_mappings           = '.g:VM_default_mappings,
        \'let g:VM_mouse_mappings             = '.g:VM_mouse_mappings,
        \'let g:VM_reselect_first_insert      = '.g:VM_reselect_first_insert,
        \'let g:VM_reselect_first_always      = '.g:VM_reselect_first_always,
        \'let g:VM_case_setting               = "'.g:VM_case_setting.'"',
        \'let g:VM_pick_first_after_n_cursors = '.g:VM_pick_first_after_n_cursors,
        \'let g:VM_dynamic_synmaxcol          = '.g:VM_dynamic_synmaxcol,
        \'let g:VM_disable_syntax_in_imode    = '.g:VM_disable_syntax_in_imode,
        \'let g:VM_exit_on_1_cursor_left      = '.g:VM_exit_on_1_cursor_left,
        \'let g:VM_manual_infoline            = '.g:VM_manual_infoline,
        \'',
        \'"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""',
        \'',
        \]

  let @" = join(config, "\n")
  let @+ = @"
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#config#help()
  """Options help."""

  redraw!
  let _ = repeat('-', &columns-1)."\n"
  echohl WarningMsg | echo _ | echohl None

  echohl Special | echo "g:VM_default_mappings\t\t\t"  | echohl None | echon "if disabled, only <C-N> will be mapped"
  echohl Special | echo "g:VM_mouse_mappings\t\t\t"    | echohl None | echon "default mouse mappings\n\n"

  echohl WarningMsg | echo _ | echohl None

  echohl Special
  echohl Special | echo "g:VM_reselect_first_insert\t\t" | echohl None | echon "reselect first cursor after exiting insert mode"
  echohl Special | echo "g:VM_reselect_first_always\t\t" | echohl None | echon "reselect first cursor after most commands\n\n"

  echohl WarningMsg | echo _ | echohl None

  echohl Special | echo "g:VM_case_setting"
  echohl None | echon "\t\t\tthis setting controls case matching:\n\t\t\t\t\t'smart' -> 'sensitive' -> 'ignore'\n\n"

  echohl WarningMsg | echo _ | echohl None

  echo "Performance-related settings for insert mode. Type :help 'synmaxcol' for more info.\n\n"
  echohl Special | echo "g:VM_pick_first_after_n_cursors"
  echohl None | echon "\t\tcan improve performance when there are lots of cursors"
  echohl Special | echo "g:VM_dynamic_synmaxcol"
  echohl None | echon "\t\t\tsyntax highlighting max column will be gradually decreased"
  echohl Special | echo "g:VM_disable_syntax_in_imode"
  echohl None | echon "\t\tdrops synmaxcol to 1, while in insert mode\n\n"
  echohl None

  echohl WarningMsg | echo _ | echohl None

  echohl Special | echo "g:VM_exit_on_1_cursor_left" | echohl None | echon "\t\tautomatically exit when there is one cursor left"
  echohl Special | echo "g:VM_manual_infoline"       | echohl None | echon "\t\t\tshow the infoline only manually (default \\\\l)"

  echohl Special
  echohl None

  echohl WarningMsg | echo "\nPress a key to go back\n" | echohl None
  call getchar()
  call vm#special#config#start()
endfun

