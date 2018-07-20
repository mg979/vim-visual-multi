
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#config#start()
  """Call VM configurator."""

  redraw!
  let opt = [
            \['Default mappings',              "VM_default_mappings"],
            \['Sublime mappings',              "VM_sublime_mappings"],
            \['Mouse mappings',                "VM_mouse_mappings"],
            \['"s" mappings',                  "VM_s_mappings"],
            \['Reselect first insert',         "VM_reselect_first_insert"],
            \['Reselect first always',         "VM_reselect_first_always"],
            \['Case setting',                  "VM_case_setting"],
            \['Pick first after n cursors',    "VM_pick_first_after_n_cursors"],
            \['Dynamic synmaxcol',             "VM_dynamic_synmaxcol"],
            \['Disable syntax in insert-mode', "VM_disable_syntax_in_imode"],
            \['No meta mappings',              "VM_no_meta_mappings"],
            \['Auto-exit with 1 cursor left',  "VM_exit_on_1_cursor_left"],
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
  elseif o == 6
    if g:VM_case_setting == 'smart'         | let g:VM_case_setting = 'sensitive'
    elseif g:VM_case_setting == 'sensitive' | let g:VM_case_setting = 'ignore'
    else                                    | let g:VM_case_setting = 'smart' | endif
  elseif o == 7
    let new = input("\nEnter a new value for g:VM_pick_first_after_n_cursors (0 disables it) > ")
    if !empty(new) | let g:VM_pick_first_after_n_cursors = new | endif
  elseif o == 8
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
        \'let g:VM_sublime_mappings           = '.g:VM_sublime_mappings,
        \'let g:VM_mouse_mappings             = '.g:VM_mouse_mappings,
        \'let g:VM_s_mappings                 = '.g:VM_s_mappings,
        \'let g:VM_no_meta_mappings           = '.g:VM_no_meta_mappings,
        \'let g:VM_reselect_first_insert      = '.g:VM_reselect_first_insert,
        \'let g:VM_reselect_first_always      = '.g:VM_reselect_first_always,
        \'let g:VM_case_setting               = "'.g:VM_case_setting.'"',
        \'let g:VM_pick_first_after_n_cursors = '.g:VM_pick_first_after_n_cursors,
        \'let g:VM_dynamic_synmaxcol          = '.g:VM_dynamic_synmaxcol,
        \'let g:VM_disable_syntax_in_imode    = '.g:VM_disable_syntax_in_imode,
        \'let g:VM_exit_on_1_cursor_left      = '.g:VM_exit_on_1_cursor_left,
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
  let _ = "-------------------------------------"
  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special
  echo "g:VM_default_mappings"
  echo "g:VM_sublime_mappings"
  echo "g:VM_mouse_mappings"
  echo "g:VM_s_mappings"
  echohl None
  echo "\nThese settings enable/disable the relative mappings sets.\n\n"

  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special
  echo "g:VM_no_meta_mappings"
  echohl None
  echo "\nThis setting enables/disables meta(Alt) mappings. If disabled, some mappings are replaced with others that don't use the Alt key.\n\n"

  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special
  echo "g:VM_reselect_first_insert"
  echo "g:VM_reselect_first_always"
  echohl None
  echo "\nThese settings control which region/cursor is reselected, after performing an operation. If both are disabled, the last selected cursor is reselected.\n\n"

  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special
  echo "g:VM_case_setting"
  echohl None
  echo "\nThis setting controls case matching: 'smart' -> 'sensitive' -> 'ignore'\n\n"

  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special | echo "g:VM_pick_first_after_n_cursors"
  echohl None | echon ": can improve performance when there are lots of cursors, but you may not like to be brought to the first cursor and back."
  echohl Special | echo "g:VM_dynamic_synmaxcol"
  echohl None | echon ": when this number of cursors is reached, when entering insert mode, syntax highlightin max column will be gradually decreased."
  echohl Special | echo "g:VM_disable_syntax_in_imode"
  echohl None | echon ": drops synmaxcol to 1, while in insert mode. The most radical solution.\n"
  echohl None
  echo "\nPerformance-related settings for insert mode. Type :help 'synmaxcol' if you need to know what it is.\n\n"

  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special
  echo "g:VM_exit_on_1_cursor_left"
  echohl None
  echo "\nIf enabled, VM automatically exits when there is one cursor left. Also useful to use VM selection methods as a replacement for regular visual mode, if you feel like it.\n\n"

  echohl WarningMsg | echo "\nPress a key to go back\n" | echohl None
  call getchar()
  call vm#special#config#start()
endfun

