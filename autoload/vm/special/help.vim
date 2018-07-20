"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings help
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:dict()

  let regions   = ['Find Under',                        'Find Prev',
                  \'Select All',                        'Find Next',
                  \'Start Regex Search',                'Goto Prev',
                  \'Star',                              'Goto Next',
                  \'Hash',                              'q Skip',
                  \'Remove Last Region',                'Remove Region',
                  \'Select Line Down',                  'Skip Region',
                  \'Select Line Up',                    'Find I Word',
                  \'Find A Word',                       'Find I Whole Word',
                  \'Find A Subword',                    'Find A Whole Subword',
                  \]

  let cursors   = ['Add Cursor At Pos',                 'Select Cursor Down',
                  \'Add Cursor At Word',                'Select Cursor Up',
                  \'Merge To Eol',                      '',
                  \'Merge To Bol',                      '',
                  \]

  let visual    = ['Visual Regex',                      'Visual Select All',
                  \'Visual Add',                        'Visual Find',
                  \'Visual Cursors',                    'Visual Star',
                  \'Visual Hash',                       'Visual Subtract',
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
                  \]

  let tools     = ['Change Case Setting',               'Toggle Whole Word',
                  \'Show Registers',                    'Search Menu',
                  \'Show Help',                         'Tools Menu',
                  \'Case Conversion Menu',              'Toggle Debug',
                  \'Rewrite Last Search',               '',
                  \]

  let special   = ['Toggle Mappings',                   'Toggle Block Mode',
                  \'Switch Mode',                       'Toggle Only This Region',
                  \'Case Setting',                      'Toggle Whole Word',
                  \'Invert Direction',                  'Toggle Multiline',
                  \]

  let others    = []

  for p in sort(keys(g:VM.help))
    if index(regions, p) >= 0
    elseif index(cursors, p) >= 0
    elseif index(visual, p) >= 0
    elseif index(operators, p) >= 0
    elseif index(commands, p) >= 0
    elseif index(tools, p) >= 0
    elseif index(special, p) >= 0
    else
      call add(others, p)
    endif
  endfor

  return {'regions': regions, 'cursors': cursors, 'visual': visual, 'operators': operators, 'commands': commands, 'tools': tools, 'special': special, 'others': others}
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Pad = { t, n -> b:VM_Selection.Funcs.pad(t, n) }

fun! s:Txt(i, m)
  let p = match(a:m, '"') >= 0? 21 : 20
  let p = match(a:m, '\') >= 0? p+1 : p
  return (a:i%2? 'echon "' : 'echo "').s:Pad(escape(a:m, '"\'), p).'"'
endfun


fun! vm#special#help#show()

  let _  = "=========="
  let __ = _._._._._._._._._._._._._._._._._._
  let sp = '                                                                                 '

  let groups = [
        \["\n".__."\n"."   Regions        ".sp."\n\n", "regions"],
        \["\n".__."\n"."   Cursors        ".sp."\n\n", "cursors"],
        \["\n".__."\n"."   Operators      ".sp."\n\n", "operators"],
        \["\n".__."\n"."   Visual         ".sp."\n\n", "visual"],
        \["\n".__."\n"."   Special        ".sp."\n\n", "special"],
        \["\n".__."\n"."   Commands       ".sp."\n\n", "commands"],
        \["\n".__."\n"."   Tools          ".sp."\n\n", "tools"],
        \["\n".__."\n"."   All Others     ".sp."\n\n", "others"],
        \]

  echohl Special    | echo "1. "          | echohl Type | echon "Regions, Operators, Visual"
  echohl Special    | echo "2. "          | echohl Type | echon "Special, Commands, Menus"
  echohl Special    | echo "3. "          | echohl Type | echon "All others"
  echohl WarningMsg | echo "\nEnter an option > "       | let ask = nr2char(getchar())      | echohl None

  if ask == '1'     | redraw! | let show_groups = groups[:3]
  elseif ask == '2' | redraw! | let show_groups = groups[4:-2]
  elseif ask == '3' | redraw! | let show_groups = groups[-1:-1]
  else              | return  | endif

  let D = s:dict()

  for g in show_groups
    echohl WarningMsg | echo g[0] | echohl None
    let dict_key = g[1]
    let i = 0
    "iterate s:dict chosen groups and print keys / desctiptions / notes
    for plug in D[dict_key]
      if !has_key(g:VM.help, plug) | continue | endif
      let Map  = g:VM.help[plug]
      let Desc = s:plugs[plug][0]
      let Note = s:plugs[plug][1]
      echohl Special | exe s:Txt(i, Map)
      echohl Type    | echon s:Pad(Desc, 25)
      echohl None    | echon s:Pad(Note, 50)
      let i += 1
    endfor
    echo "\n"
  endfor
endfun

let s:plugs = {
      \"Erase Regions":           ["Erase Regions",              ""],
      \"Add Cursor At Pos":       ["Add Cursor At Position",     "create a cursor at current position"],
      \"Add Cursor At Word":      ["Add Cursor At Word",         "create a cursor at current word, adding a pattern"],
      \"Start Regex Search":      ["Start Regex Search",         "add regions with a regex pattern"],
      \"Select All":              ["Select All",                 ""],
      \"Add Cursor Down":         ["Add Cursor Down",            "in cursor mode"],
      \"Add Cursor Up":           ["Add Cursor Up",              "in cursor mode"],
      \"Visual Regex":            ["Visual Regex",               "add regions with regex in visual selection"],
      \"Visual All":              ["Visual Select All",          "subwords accepted"],
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
      \"Select Line Down":        ["Select Line Down",           "like Visual Line"],
      \"Select Line Up":          ["Select Line Up",             "like Visual Line"],
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
      \"Find I Whole Word":       ["Select Inner Whole Word",    ""],
      \"Find A Subword":          ["Select A Subword",           ""],
      \"Find A Whole Subword":    ["Select A Whole Subword",     ""],
      \"Mouse Cursor":            ["Mouse Cursor",               "create a cursor at position"],
      \"Mouse Word":              ["Mouse Word",                 "select word"],
      \"Mouse Column":            ["Mouse Column",               "create a column of cursors"],
      \"Find Next":               ["Find next",                  "always downwards"],
      \"Find Prev":               ["Find previous",              "always upwards"],
      \"Goto Next":               ["Goto Next",                  ""],
      \"Goto Prev":               ["Goto Prev",                  ""],
      \"Toggle Mappings":         ["Toggle Mappings",            "disable VM mappings, except Space and Escape"],
      \"Exit VM":                 ["Exit VM",                    ""],
      \"Switch Mode":             ["Switch Mode",                "toggle cursor/extend mode"],
      \"Toggle Block":            ["Toggle Block Mode",          ""],
      \"Toggle Only This Region": ["Toggle Only This Region",    "lets you modify a region at a time"],
      \"Skip Region":             ["Skip Region",                "and find next in the current direction"],
      \"q Skip":                  ["Skip Region",                "and find next in the current direction"],
      \"Invert Direction":        ["Invert Direction",           "as 'o' in visual mode"],
      \"Remove Region":           ["Remove Region",              "and go back to previous"],
      \"Remove Last Region":      ["Remove Last Region",         "removes the bottom-most region"],
      \"Star":                    ["Star",                       "select inner word, case sensitive"],
      \"Hash":                    ["Hash",                       "select around word, case sensitive"],
      \"Visual Star":             ["Visual Star",                "select inner (sub)word, case sensitive"],
      \"Visual Hash":             ["Visual Hash",                "select around (sub)word, case sensitive"],
      \"Merge To Eol":            ["Merge to EOL",               "collapse cursors to end of line"],
      \"Merge To Bol":            ["Merge to BOL",               "collapse cursors to indent level"],
      \"Select Operator":         ["Select Operator",            "accepts motions and text objects"],
      \"Select All Operator":     ["Select All Operator",        "applies the select operator to all cursors"],
      \"Find Operator":           ["Find Operator",              "matches patterns in motion/text object"],
      \"This Motion h":           ["Extend Left This Region",    ""],
      \"This Motion l":           ["Extend Right This Region",   ""],
      \"This Select h":           ["Extend Left This Region",    "will create a new region if there is none"],
      \"This Select l":           ["Extend Right This Region",   "will create a new region if there is none"],
      \"Tools Menu":              ["Tools Menu",                 ""],
      \"Show Help":               ["Show Help",                  ""],
      \"Show Registers":          ["Show Registers",             ""],
      \"Toggle Debug":            ["Toggle Debug",               ""],
      \"Case Setting":            ["Change Case Setting",        "cycle case settings (smart, ignore, noignore)"],
      \"Toggle Whole Word":       ["Toggle Whole Word",          "toggle word boundaries for most recent pattern"],
      \"Case Conversion Menu":    ["Case Conversion Menu",       ""],
      \"Search Menu":             ["Search Menu",                ""],
      \"Rewrite Last Search":     ["Rewrite Last Search",        "update last search pattern to match current region"],
      \"Toggle Multiline":        ["Toggle Multiline",           "will force one region per line, when disabling"],
      \"Surround":                ["Surround",                   ""],
      \"Merge Regions":           ["Merge Regions",              ""],
      \"Transpose":               ["Transpose",                  ""],
      \"Duplicate":               ["Duplicate",                  ""],
      \"Align":                   ["Align at Column",            "simple alignment at highest cursors column"],
      \"Split Regions":           ["Split Regions",              ""],
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
      \"Shrink":                  ["Shrink",                     "reduce selection(s) width by 1 from the sides"],
      \"Enlarge":                 ["Enlarge",                    "increase selection(s) width by 1 from the sides"],
      \"I-Arrow w":               ["(Insert Mode) w",            ""],
      \"I-Arrow b":               ["(Insert Mode) b",            ""],
      \"I-Arrow W":               ["(Insert Mode) W",            ""],
      \"I-Arrow B":               ["(Insert Mode) B",            ""],
      \"I-Arrow ge":              ["(Insert Mode) ge",           ""],
      \"I-Arrow e":               ["(Insert Mode) e",            ""],
      \"I-Arrow gE":              ["(Insert Mode) gE",           ""],
      \"I-Arrow E":               ["(Insert Mode) E",            ""],
      \"I-Left Arrow":            ["(Insert Mode) Left",         ""],
      \"I-Right Arrow":           ["(Insert Mode) Right",        ""],
      \"I-Up Arrow":              ["(Insert Mode) Up",           "currently moves left"],
      \"I-Down Arrow":            ["(Insert Mode) Down",         "currently moves right"],
      \"I-Return":                ["(Insert Mode) Return",       ""],
      \"I-BS":                    ["(Insert Mode) Backspace",    ""],
      \"I-Paste":                 ["(Insert Mode) Paste",        "using VM unnamed register"],
      \"I-CtrlW":                 ["(Insert Mode) CtrlW",        "as ctrl-w"],
      \"I-CtrlD":                 ["(Insert Mode) CtrlD",        "same as delete"],
      \"I-Del":                   ["(Insert Mode) Del",          ""],
      \"I-CtrlA":                 ["(Insert Mode) CtrlA",        "moves to the beginning of the line"],
      \"I-CtrlE":                 ["(Insert Mode) CtrlE",        "moves to the end of the line"],
      \"I-CtrlB":                 ["(Insert Mode) CtrlB",        "like left arrow"],
      \"I-CtrlF":                 ["(Insert Mode) CtrlF",        "like right arrow"],
      \"D":                       ["D",                          ""],
      \"Y":                       ["Y",                          ""],
      \"x":                       ["x",                          ""],
      \"X":                       ["X",                          ""],
      \"J":                       ["J",                          ""],
      \"~":                       ["~",                          ""],
      \"Del":                     ["Del",                        ""],
      \"Dot":                     ["Dot command",                "cursor mode only"],
      \"Increase":                ["Increase Numbers",           "like ctrl-a at cursors"],
      \"Decrease":                ["Decrease Numbers",           "like ctrl-x at cursors"],
      \"a":                       ["a",                          ""],
      \"A":                       ["A",                          ""],
      \"i":                       ["i",                          ""],
      \"I":                       ["I",                          ""],
      \"o":                       ["o",                          ""],
      \"O":                       ["O",                          ""],
      \"c":                       ["c",                          ""],
      \"C":                       ["C",                          ""],
      \"Delete":                  ["Delete Selection",           ""],
      \"Replace":                 ["Replace",                    "just as 'r'"],
      \"Replace Pattern":         ["Replace Pattern",            "regex substitution in all regions"],
      \"p Paste Regions":         ["p Paste",                    "accepts both vim and VM registers"],
      \"P Paste Regions":         ["P Paste",                    "accepts both vim and VM registers"],
      \"p Paste Normal":          ["p Paste [vim]",              "force pasting from vim register"],
      \"P Paste Normal":          ["P Paste [vim]",              "force pasting from vim register"],
      \"Yank":                    ["Yank",                       "accepts both vim and VM registers"],
      \}

