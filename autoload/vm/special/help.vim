"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Debug
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#help#debug()
  if !exists('b:VM_Debug')
    return
  elseif empty(b:VM_Debug.lines)
    echomsg '[visual-multi] No errors'
    return
  endif

  for line in b:VM_Debug.lines
    if !empty(line)
      echom line
    endif
  endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings help
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:dict()

  let regions   = ['Find Under',                        'Find Prev',
                  \'Select All',                        'Find Next',
                  \'Start Regex Search',                'Goto Prev',
                  \'Star',                              'Goto Next',
                  \'Hash',                              'Alt Skip',
                  \'Remove Last Region',                'Remove Region',
                  \'Select Line Down',                  'Skip Region',
                  \'Select Line Up',                    'Find I Word',
                  \'Seek Down',                         'Find A Word',
                  \'Seek Up',                           '',
                  \]

  let cursors   = ['Add Cursor At Pos',                 'Select Cursor Down',
                  \'Add Cursor At Word',                'Select Cursor Up',
                  \'Add Cursor Down',                   'Merge To Eol',
                  \'Add Cursor Up',                     'Merge To Bol',
                  \]

  let visual    = ['Find Subword Under',                'Visual All',
                  \'Visual Add',                        'Visual Find',
                  \'Visual Subtract',                   'Visual Star',
                  \'Visual Cursors',                    'Visual Hash',
                  \'Find A Subword',                    'Find A Whole Subword',
                  \'Visual Regex',
                  \]

  let operators = ['Select Operator',                   'Select All Operator',
                  \'Find Operator',                     '',
                  \]

  let commands  = ['Run Normal',                        'Align',
                  \'Run Last Normal',                   'Align Char',
                  \'Run Visual',                        'Align Regex',
                  \'Run Last Visual',                   'Numbers',
                  \'Run Ex',                            'Numbers Append',
                  \'Run Last Ex',                       'Zero Numbers',
                  \'Run Macro',                         'Zero Numbers Append',
                  \'Run Dot',                           'Shrink',
                  \'Surround',                          'Enlarge',
                  \'Transpose',                         'Merge Regions',
                  \'Increase',                          'Duplicate',
                  \'Decrease',                          'Split Regions',
                  \'Rotate',                            'Filter Regions',
                  \]

  let fkeys     = ['Show Help',                         '',
                  \'Alt Prev',                          '',
                  \'Alt Next',                          '',
                  \]

  let mouse     = ['Mouse Cursor',                      '',
                  \'Mouse Word',                        '',
                  \'Mouse Column',                      '',
                  \]

  let tools     = ['Show Registers',                    'Rewrite Last Search',
                  \'Search Menu',                       'Tools Menu',
                  \'Case Conversion Menu',              'Toggle Debug',
                  \'Show Infoline',
                  \]

  let special   = ['Toggle Mappings',                   'Toggle Block',
                  \'Switch Mode',                       'Toggle Only This Region',
                  \'Case Setting',                      'Toggle Whole Word',
                  \'Invert Direction',                  'Toggle Multiline',
                  \]

  let edit      = ['D',                       'Y',
                  \'x',                       'X',
                  \'J',                       '~',
                  \'Del',                     'Dot',
                  \'a',                       'A',
                  \'i',                       'I',
                  \'o',                       'O',
                  \'c',                       'C',
                  \'Transform Regions',       'Delete',
                  \'Yank',                    'Replace',
                  \'Yank Hard',               'Replace Pattern',
                  \'p Paste Regions',         'p Paste Vimreg',
                  \'P Paste Regions',         'P Paste Vimreg',
                  \'Undo',                    'Redo',
                  \]

  let insert    = ['I Arrow w',               'I Arrow b',
                  \'I Arrow W',               'I Arrow B',
                  \'I Arrow ge',              'I Arrow e',
                  \'I Arrow gE',              'I Arrow E',
                  \'I Left Arrow',            'I Right Arrow',
                  \'I Up Arrow',              'I Down Arrow',
                  \'I Return',                'I BS',
                  \'I Home',                  'I End',
                  \'I Paste',                 'I CtrlW',
                  \'I CtrlD',                 'I Del',
                  \'I CtrlA',                 'I CtrlE',
                  \'I CtrlB',                 'I CtrlF',
                  \]

  let arrows    = []
  let leader    = []
  let others    = []

  for p in sort(keys(g:Vm.help))
    let other = 0
    let ins = 0

    if     index(regions,   p) >= 0
    elseif index(cursors,   p) >= 0
    elseif index(visual,    p) >= 0
    elseif index(operators, p) >= 0
    elseif index(commands,  p) >= 0
    elseif index(fkeys,     p) >= 0
    elseif index(mouse,     p) >= 0
    elseif index(tools,     p) >= 0
    elseif index(insert,    p) >= 0
      let ins = 1
    elseif index(edit,      p) >= 0
    elseif index(special,   p) >= 0
    else
      let other = 1
    endif

    if !ins && match(g:Vm.help[p], '\-\<Up\>\|\-\<Down\>\|\-\<Left\>\|\-\<Right\>') >= 0
      let other = 0
      call add(arrows, p)
    elseif !ins && match(g:Vm.help[p], g:Vm.leader) >= 0
      let other = 0
      call add(leader, p)
    endif

    if other
      call add(others, p)
    endif
  endfor

  return {'regions': regions, 'cursors': cursors, 'visual': visual, 'operators': operators, 'commands': commands, 'tools': tools, 'mouse': mouse, 'fkeys': fkeys, 'arrows': arrows, 'insert': insert, 'edit': edit, 'special': special, 'leader': sort(leader), 'others': others}
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Pad(t, n)
  return b:VM_Selection.Funcs.pad(a:t, a:n, 1)
endfun

fun! s:Sep(c)
  return b:VM_Selection.Funcs.repeat_char(a:c)
endfun

fun! s:Txt(i, m)
  let n = &columns > 180 ? 18 : 20
  let p = match(a:m, '"') >= 0? n+1 : n
  let p = match(a:m, '\') >= 0? p+1 : p
  return (a:i%2? 'echon "' : 'echo "').s:Pad(escape(a:m, '"\'), p).'"'
endfun


fun! vm#special#help#show()

  let _  = "\n".b:VM_Selection.Funcs.repeat_char("=")."\n"
  let sp = b:VM_Selection.Funcs.repeat_char(" ")

  let groups = [
        \[ _."   Regions        "."\n\n", "regions"],
        \[ _."   Cursors        "."\n\n", "cursors"],
        \[ _."   Operators      "."\n\n", "operators"],
        \[ _."   Visual         "."\n\n", "visual"],
        \[ _."   F keys         "."\n\n", "fkeys"],
        \[ _."   Mouse          "."\n\n", "mouse"],
        \[ _."   Arrows         "."\n\n", "arrows"],
        \[ _."   Leader         "."\n\n", "leader"],
        \[ _."   Special        "."\n\n", "special"],
        \[ _."   Commands       "."\n\n", "commands"],
        \[ _."   Tools          "."\n\n", "tools"],
        \[ _."   Edit           "."\n\n", "edit"],
        \[ _."   Insert         "."\n\n", "insert"],
        \[ _."   All Others     "."\n\n", "others"],
        \]

  echohl Special    | echo "1. "          | echohl Type | echon "Regions, Cursors, Operators, Visual"
  echohl Special    | echo "2. "          | echohl Type | echon "F keys, Mouse, Arrows, Leader"
  echohl Special    | echo "3. "          | echohl Type | echon "Special, Commands, Menus"
  echohl Special    | echo "4. "          | echohl Type | echon "Edit, Insert, Others"
  echohl WarningMsg | echo "\nEnter an option > "       | let ask = nr2char(getchar())      | echohl None

  if ask == '1'     | redraw! | let show_groups = groups[:3]
  elseif ask == '2' | redraw! | let show_groups = groups[4:7]
  elseif ask == '3' | redraw! | let show_groups = groups[8:10]
  elseif ask == '4' | redraw! | let show_groups = groups[-3:-1]
  else              | return  | endif

  let D = s:dict()

  for g in show_groups
    echohl WarningMsg | echo g[0] | echohl None
    let dict_key = g[1]
    let i = 0
    "iterate s:dict chosen groups and print keys / desctiptions / notes
    for plug in D[dict_key]
      if !has_key(g:Vm.help, plug)   | continue
      elseif !has_key(s:plugs, plug) | let s:plugs[plug] = [plug, ""] | endif
      let Map  = g:Vm.help[plug]
      let Desc = s:plugs[plug][0]
      let Note = s:plugs[plug][1]
      echohl Special | exe s:Txt(i, Map)
      echohl Type    | echon s:Pad(Desc, &columns > 180 ? 25 : 30)
      echohl None    | if &columns > 180 | echon s:Pad(Note, 50) | endif
      let i += 1
    endfor
    echo "\n"
  endfor
endfun

let s:plugs = {
      \"Erase Regions":           ["Erase Regions",              ""],
      \"Add Cursor At Pos":       ["Add Cursor At Position",     "cursor at current position"],
      \"Add Cursor At Word":      ["Add Cursor At Word",         "cursor at current word, adding a pattern"],
      \"Start Regex Search":      ["Start Regex Search",         "add regions with a regex pattern"],
      \"Select All":              ["Select All",                 ""],
      \"Add Cursor Down":         ["Add Cursor Down",            "in cursor mode"],
      \"Add Cursor Up":           ["Add Cursor Up",              "in cursor mode"],
      \"Visual Regex":            ["Find By Regex",              "add regions with regex in visual selection"],
      \"Visual All":              ["Select All",                 "subwords accepted"],
      \"Visual Add":              ["Visual Add",                 "create a region from visual selection"],
      \"Visual Find":             ["Visual Find",                "find current patterns in visual selection"],
      \"Visual Cursors":          ["Visual Cursors",             "create cursors along visual selection"],
      \"Select Cursor Down":      ["Select Cursor Down",         "in extend mode"],
      \"Select Cursor Up":        ["Select Cursor Up",           "in extend mode"],
      \"Select j":                ["Extend Down",                ""],
      \"Select k":                ["Extend Up",                  ""],
      \"Select l":                ["Extend Right",               ""],
      \"Select h":                ["Extend Left",                ""],
      \"Select w":                ["Extend (w)",                 ""],
      \"Select b":                ["Extend (b)",                 ""],
      \"Select Line Down":        ["Select Line Down",           "like Visual Line 'j'"],
      \"Select Line Up":          ["Select Line Up",             "like Visual Line 'k'"],
      \"Select E":                ["Extend (E)",                 ""],
      \"Select BBW":              ["Extend (BBW)",               ""],
      \"Select e":                ["Extend (e)",                 ""],
      \"Select ge":               ["Extend (ge)",                ""],
      \"Move Right":              ["Move Right",                 "shift the selection(s) to the right"],
      \"Move Left":               ["Move Left",                  "shift the selection(s) to the left"],
      \"Find Under":              ["Select Inner Whole Word",    "whole word, or expand word under cursors"],
      \"Find Subword Under":      ["Select Subword",             "without word boundaries"],
      \"Find I Word":             ["Select Inner Word",          "without word boundaries"],
      \"Find A Word":             ["Select Around Word",         ""],
      \"Find A Subword":          ["Select A Subword",           ""],
      \"Find A Whole Subword":    ["Select A Whole Subword",     ""],
      \"Mouse Cursor":            ["Mouse Cursor",               "create a cursor at position"],
      \"Mouse Word":              ["Mouse Word",                 "select word"],
      \"Mouse Column":            ["Mouse Column",               "create a column of cursors"],
      \"Find Next":               ["Find next",                  "always downwards"],
      \"Find Prev":               ["Find previous",              "always upwards"],
      \"Goto Next":               ["Goto Next",                  ""],
      \"Goto Prev":               ["Goto Prev",                  ""],
      \"Alt Next":                ["Goto Next",                  ""],
      \"Alt Prev":                ["Goto Prev",                  ""],
      \"Seek Up":                 ["Seek Up",                    "scroll the page up, and select a region"],
      \"Seek Down":               ["Seek Down",                  "scroll the page down, and select a region"],
      \"Toggle Mappings":         ["Toggle Mappings",            "disable VM mappings, except Space and Esc"],
      \"Exit VM":                 ["Exit VM",                    ""],
      \"Switch Mode":             ["Switch Mode",                "toggle cursor/extend mode"],
      \"Toggle Block":            ["Toggle Block Mode",          ""],
      \"Toggle Only This Region": ["Toggle Only This Region",    "lets you modify a region at a time"],
      \"Skip Region":             ["Skip Region",                "and find next in the current direction"],
      \"Alt Skip":                ["Skip Region",                "and find next in the current direction"],
      \"Invert Direction":        ["Invert Direction",           "as 'o' in visual mode"],
      \"Remove Region":           ["Remove Region",              "and go back to previous"],
      \"Remove Every n Regions":  ["Remove Every n Regions",     "n is [count], min 2 if no count given"],
      \"Remove Last Region":      ["Remove Last Region",         "removes the bottom-most region"],
      \"Star":                    ["Star",                       "select inner word, case sensitive"],
      \"Hash":                    ["Hash",                       "select around word, case sensitive"],
      \"Visual Star":             ["Visual Star",                "select inner (sub)word, case sensitive"],
      \"Visual Hash":             ["Visual Hash",                "select around (sub)word, case sensitive"],
      \"Merge To Eol":            ["Merge to EOL",               "collapse cursors to end of line"],
      \"Merge To Bol":            ["Merge to BOL",               "collapse cursors to indent level"],
      \"Select Operator":         ["Select Operator",            "accepts motions and text objects"],
      \"Select All Operator":     ["Select All Operator",        "applies to all cursors"],
      \"Find Operator":           ["Find Operator",              "matches patterns in motion/text object"],
      \"This Motion h":           ["Extend This Left",           ""],
      \"This Motion l":           ["Extend This Right",          ""],
      \"This Select h":           ["Extend This Left",           "will create a new region if there is none"],
      \"This Select l":           ["Extend This Right",          "will create a new region if there is none"],
      \"Tools Menu":              ["Tools Menu",                 ""],
      \"Show Help":               ["Show Help",                  ""],
      \"Show Registers":          ["Show Registers",             ""],
      \"Toggle Debug":            ["Toggle Debug",               ""],
      \"Case Setting":            ["Change Case Setting",        "cycle case settings"],
      \"Toggle Whole Word":       ["Toggle Whole Word",          "toggle word boundaries"],
      \"Case Conversion Menu":    ["Case Conversion Menu",       ""],
      \"Search Menu":             ["Search Menu",                ""],
      \"Rewrite Last Search":     ["Rewrite Last Search",        "update search pattern to match region"],
      \"Toggle Multiline":        ["Toggle Multiline",           "force one region per line, when disabling"],
      \"Show Infoline":           ["Show Infoline",              ""],
      \"Surround":                ["Surround",                   ""],
      \"Merge Regions":           ["Merge Regions",              ""],
      \"Transpose":               ["Transpose",                  "Transpose regions: can be inline-synched"],
      \"Rotate":                  ["Rotate",                     "Rotate regions: always unsynched"],
      \"Duplicate":               ["Duplicate",                  ""],
      \"Align":                   ["Align at Column",            "simple alignment at highest cursors column"],
      \"Split Regions":           ["Split Regions",              "subtract regex from all regions"],
      \"Filter Regions":          ["Filter Regions",             "Filter regions based on given pattern"],
      \"Visual Subtract":         ["Visual Subtract",            "subtract visual selection from regions"],
      \"Run Normal":              ["Run Normal Command",         ""],
      \"Run Last Normal":         ["Run Last Normal Command",    ""],
      \"Run Visual":              ["Run Visual Command",         ""],
      \"Run Last Visual":         ["Run Last Visual Command",    ""],
      \"Run Ex":                  ["Run Ex Command",             ""],
      \"Run Last Ex":             ["Run Last Ex Command",        ""],
      \"Run Macro":               ["Run Macro at Cursors",       ""],
      \"Run Dot":                 ["Run Dot at Cursors",         ""],
      \"Align Char":              ["Align by Character(s)",      "accepts count for multiple characters"],
      \"Align Regex":             ["Align by Regex",             ""],
      \"Numbers":                 ["Prepend Numbers",            "with optional separator, count from 1"],
      \"Numbers Append":          ["Append Numbers",             "with optional separator, count from 1"],
      \"Zero Numbers":            ["Prepend Numbers from 0",     "with optional separator, count from 0"],
      \"Zero Numbers Append":     ["Append Numbers from 0",      "with optional separator, count from 0"],
      \"Shrink":                  ["Shrink",                     "by 1 from both sides"],
      \"Enlarge":                 ["Enlarge",                    "by 1 from both sides"],
      \"I Arrow w":               ["(I) w",                      "move as by motion"],
      \"I Arrow b":               ["(I) b",                      "move as by motion"],
      \"I Arrow W":               ["(I) W",                      "move as by motion"],
      \"I Arrow B":               ["(I) B",                      "move as by motion"],
      \"I Arrow ge":              ["(I) ge",                     "move as by motion"],
      \"I Arrow e":               ["(I) e",                      "move as by motion"],
      \"I Arrow gE":              ["(I) gE",                     "move as by motion"],
      \"I Arrow E":               ["(I) E",                      "move as by motion"],
      \"I Left Arrow":            ["(I) Left",                   ""],
      \"I Right Arrow":           ["(I) Right",                  ""],
      \"I Up Arrow":              ["(I) Up",                     "currently moves left"],
      \"I Down Arrow":            ["(I) Down",                   "currently moves right"],
      \"I Return":                ["(I) Return",                 ""],
      \"I BS":                    ["(I) Backspace",              ""],
      \"I Paste":                 ["(I) Paste",                  "using VM unnamed register"],
      \"I CtrlW":                 ["(I) CtrlW",                  "as ctrl-w"],
      \"I CtrlD":                 ["(I) CtrlD",                  "same as delete"],
      \"I Del":                   ["(I) Del",                    ""],
      \"I Home":                  ["(I) Home",                   ""],
      \"I End":                   ["(I) End",                    ""],
      \"I CtrlA":                 ["(I) CtrlA",                  "moves to the beginning of the line"],
      \"I CtrlE":                 ["(I) CtrlE",                  "moves to the end of the line"],
      \"I CtrlB":                 ["(I) CtrlB",                  "same as left arrow"],
      \"I CtrlF":                 ["(I) CtrlF",                  "same as right arrow"],
      \"D":                       ["D",                          ""],
      \"Y":                       ["Y",                          ""],
      \"x":                       ["x",                          ""],
      \"X":                       ["X",                          ""],
      \"J":                       ["J",                          ""],
      \"~":                       ["~",                          ""],
      \"Del":                     ["Del",                        ""],
      \"Dot":                     ["Dot command",                "cursor mode only"],
      \"Increase":                ["Increase Numbers",           "same as ctrl-a at cursors"],
      \"Decrease":                ["Decrease Numbers",           "same as ctrl-x at cursors"],
      \"a":                       ["a",                          ""],
      \"A":                       ["A",                          ""],
      \"i":                       ["i",                          ""],
      \"I":                       ["I",                          ""],
      \"o":                       ["o",                          "as 'o' in normal mode"],
      \"O":                       ["O",                          "as 'O' in normal mode"],
      \"c":                       ["c",                          ""],
      \"C":                       ["C",                          ""],
      \"Undo":                    ["Undo",                       "undo last edit and reselect regions"],
      \"Redo":                    ["Redo",                       "redo last edit and reselect regions"],
      \"Delete":                  ["Delete",                     "both vim and VM registers"],
      \"Replace":                 ["Replace",                    "just as 'r'"],
      \"Replace Pattern":         ["Replace Pattern",            "regex substitution in all regions"],
      \"Transform Regions":       ["Transform Regions",          "transform regions with expression"],
      \"p Paste Regions":         ["p Paste",                    "both vim and VM registers"],
      \"P Paste Regions":         ["P Paste",                    "both vim and VM registers"],
      \"p Paste Vimreg":          ["p Paste [vimreg]",           "force pasting from vim register"],
      \"P Paste Vimreg":          ["P Paste [vimreg]",           "force pasting from vim register"],
      \"Yank":                    ["Yank",                       "only write VM registers"],
      \"Yank Hard":               ["Hard Yank",                  "both vim and VM registers"],
      \}

