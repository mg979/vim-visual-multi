"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Key -> plug:
"       'Select Operator' ->    <Plug>(VM-Select-Operator)

"Contents of lists:
"       [0]: mapping
"       [1]: mode
"
" When adding a new mapping, the following is required:
"       1. add a <Plug> with a command
"       2. add the reformatted plug name in this file (permanent or buffer section)
"       3. update the help file: an entry in s:plugs is necessary
"       4. in the help file, add an entry in a section of s:dict to assign a category

let s:base = {
      \"Select Operator":         ['', 'n'],
      \"Erase Regions":           ['', 'n'],
      \"Add Cursor At Pos":       ['', 'n'],
      \"Add Cursor At Word":      ['', 'n'],
      \"Start Regex Search":      ['', 'n'],
      \"Select All":              ['', 'n'],
      \"Add Cursor Down":         ['', 'n'],
      \"Add Cursor Up":           ['', 'n'],
      \"Visual Regex":            ['', 'x'],
      \"Visual All":              ['', 'x'],
      \"Visual Add":              ['', 'x'],
      \"Visual Find":             ['', 'x'],
      \"Visual Cursors":          ['', 'x'],
      \"Find Under":              ['', 'n'],
      \"Find Subword Under":      ['', 'x'],
      \"Select Cursor Down":      ['', 'n'],
      \"Select Cursor Up":        ['', 'n'],
      \"Select j":                ['', 'n'],
      \"Select k":                ['', 'n'],
      \"Select l":                ['', 'n'],
      \"Select h":                ['', 'n'],
      \"Select w":                ['', 'n'],
      \"Select b":                ['', 'n'],
      \"Select Line Down":        ['', 'n'],
      \"Select Line Up":          ['', 'n'],
      \"Select E":                ['', 'n'],
      \"Select BBW":              ['', 'n'],
      \"Find I Word":             ['', 'n'],
      \"Find A Word":             ['', 'n'],
      \"Find A Subword":          ['', 'x'],
      \"Find A Whole Subword":    ['', 'x'],
      \"Mouse Cursor":            ['', 'n'],
      \"Mouse Word":              ['', 'n'],
      \"Mouse Column":            ['', 'n'],
      \}

fun! vm#maps#all#permanent()
  """Default permanent mappings dictionary."""
  let maps = s:base
  let leader = g:Vm.leader

  " map <c-n> in any case
  let maps["Find Under"][0]              = '<C-n>'
  let maps["Find Subword Under"][0]      = '<C-n>'

  if g:VM_default_mappings
    let maps["Select Operator"][0]       = leader.'gs'
    let maps["Add Cursor At Pos"][0]     = leader.'\'
    let maps["Start Regex Search"][0]    = leader.'/'
    let maps["Select All"][0]            = leader.'A'
    let maps["Add Cursor Down"][0]       = '<C-Down>'
    let maps["Add Cursor Up"][0]         = '<C-Up>'
    let maps["Visual Regex"][0]          = leader.'/'
    let maps["Visual All"][0]            = leader.'A'
    let maps["Visual Add"][0]            = leader.'a'
    let maps["Visual Find"][0]           = leader.'f'
    let maps["Visual Cursors"][0]        = leader.'c'
  endif

  if g:VM_mouse_mappings
    let maps["Mouse Cursor"][0]          = '<C-LeftMouse>'
    let maps["Mouse Word"][0]            = '<C-RightMouse>'
    let maps["Mouse Column"][0]          = '<M-C-RightMouse>'
  endif

  return maps
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#all#buffer()
  """Default buffer mappings dictionary."""

  let maps = {}
  let leader = g:Vm.leader

  "basic
  call extend(maps, {
        \"Switch Mode":             ['<Tab>',       'n'],
        \"Toggle Block":            [leader.'<BS>', 'n'],
        \"Toggle Only This Region": [leader.'<CR>', 'n'],
        \})

  "select
  call extend(maps, {
        \"Find Next":               [']',         'n'],
        \"Find Prev":               ['[',         'n'],
        \"Goto Next":               ['}',         'n'],
        \"Goto Prev":               ['{',         'n'],
        \"Alt Next":                ['',          'n'],
        \"Alt Prev":                ['',          'n'],
        \"Seek Up":                 ['<C-b>',     'n'],
        \"Seek Down":               ['<C-f>',     'n'],
        \"Invert Direction":        ['o',         'n'],
        \"Skip Region":             ['<C-s>',     'n'],
        \"Alt Skip":                ['q',         'n'],
        \"Remove Region":           ['Q',         'n'],
        \"Remove Last Region":      [leader.'q',  'n'],
        \"Remove Every n Regions":  [leader.'R',  'n'],
        \"Star":                    ['',          'n'],
        \"Hash":                    ['',          'n'],
        \"Visual Star":             ['',          'x'],
        \"Visual Hash":             ['',          'x'],
        \"Select All Operator":     ['s',         'n'],
        \"Find Operator":           ['m',         'n'],
        \"Add Cursor Down":         ['<C-Down>',  'n'],
        \"Add Cursor Up":           ['<C-Up>',    'n'],
        \"Find I Word":             ['',          'n'],
        \"Find A Word":             ['',          'n'],
        \"Find A Subword":          ['',          'x'],
        \"Find A Whole Subword":    ['',          'x'],
        \})

  "utility
  call extend(maps, {
        \"Tools Menu":              [leader.'`',      'n'],
        \"Show Help":               [leader.'<F1>',   'n'],
        \"Show Registers":          [leader.'"',      'n'],
        \"Toggle Debug":            [leader.'<F12>',  'n'],
        \"Case Setting":            [leader.'c',      'n'],
        \"Toggle Whole Word":       [leader.'w',      'n'],
        \"Case Conversion Menu":    [leader.'C',      'n'],
        \"Search Menu":             [leader.'S',      'n'],
        \"Rewrite Last Search":     [leader.'r',      'n'],
        \"Show Infoline":           [leader.'l',      'n'],
        \"Filter Regions":          [leader.'f',      'n'],
        \"Toggle Multiline":        [leader.'M',      'n'],
        \})

  "commands
  call extend(maps, {
        \"Undo":                    ['',          'n'],
        \"Redo":                    ['',          'n'],
        \"Surround":                ['S',         'n'],
        \"Merge Regions":           [leader.'m',  'n'],
        \"Transpose":               [leader.'t',  'n'],
        \"Rotate":                  ['',          'n'],
        \"Duplicate":               [leader.'d',  'n'],
        \"Align":                   [leader.'a',  'n'],
        \"Split Regions":           [leader.'s',  'n'],
        \"Visual Subtract":         [leader.'s',  'x'],
        \"Run Normal":              [leader.'z',  'n'],
        \"Run Last Normal":         [leader.'Z',  'n'],
        \"Run Visual":              [leader.'v',  'n'],
        \"Run Last Visual":         [leader.'V',  'n'],
        \"Run Ex":                  [leader.'x',  'n'],
        \"Run Last Ex":             [leader.'X',  'n'],
        \"Run Macro":               [leader.'@',  'n'],
        \"Run Dot":                 [leader.'.',  'n'],
        \"Align Char":              [leader.'<',  'n'],
        \"Align Regex":             [leader.'>',  'n'],
        \"Numbers":                 [leader.'n',  'n'],
        \"Numbers Append":          [leader.'N',  'n'],
        \"Zero Numbers":            [leader.'0n', 'n'],
        \"Zero Numbers Append":     [leader.'0N', 'n'],
        \"Shrink":                  [leader.'-',  'n'],
        \"Enlarge":                 [leader.'+',  'n'],
        \})

  "arrows
  call extend(maps, {
        \"Select Cursor Down":      ['<M-C-Down>',  'n'],
        \"Select Cursor Up":        ['<M-C-Up>',    'n'],
        \"Select Line Down":        ['',            'n'],
        \"Select Line Up":          ['',            'n'],
        \"Add Cursor Down":         ['',            'n'],
        \"Add Cursor Up":           ['',            'n'],
        \"Select j":                ['<S-Down>',    'n'],
        \"Select k":                ['<S-Up>',      'n'],
        \"Select l":                ['<S-Right>',   'n'],
        \"Select h":                ['<S-Left>',    'n'],
        \"This Select l":           ['<M-Right>',   'n'],
        \"This Select h":           ['<M-Left>',    'n'],
        \"Select e":                ['',            'n'],
        \"Select ge":               ['',            'n'],
        \"Select w":                ['',            'n'],
        \"Select b":                ['',            'n'],
        \"Select E":                ['',            'n'],
        \"Select BBW":              ['',            'n'],
        \"Move Right":              ['<M-S-Right>', 'n'],
        \"Move Left":               ['<M-S-Left>',  'n'],
        \})

  "insert
  call extend(maps, {
        \"I Arrow w":               ['<C-Right>',   'i'],
        \"I Arrow b":               ['<C-Left>',    'i'],
        \"I Arrow W":               ['<C-S-Right>', 'i'],
        \"I Arrow B":               ['<C-S-Left>',  'i'],
        \"I Arrow ge":              ['<C-Up>',      'i'],
        \"I Arrow e":               ['<C-Down>',    'i'],
        \"I Arrow gE":              ['<C-S-Up>',    'i'],
        \"I Arrow E":               ['<C-S-Down>',  'i'],
        \"I Left Arrow":            ['<Left>',      'i'],
        \"I Right Arrow":           ['<Right>',     'i'],
        \"I Up Arrow":              ['<Up>',        'i'],
        \"I Down Arrow":            ['<Down>',      'i'],
        \"I Return":                ['<CR>',        'i'],
        \"I BS":                    ['<BS>',        'i'],
        \"I Paste":                 ['<C-v>',       'i'],
        \"I CtrlW":                 ['<C-w>',       'i'],
        \"I CtrlD":                 ['<C-d>',       'i'],
        \"I Del":                   ['<Del>',       'i'],
        \"I Home":                  ['<Home>',      'i'],
        \"I End":                   ['<End>',       'i'],
        \"I CtrlA":                 ['<C-a>',       'i'],
        \"I CtrlE":                 ['<C-e>',       'i'],
        \"I CtrlB":                 ['<C-b>',       'i'],
        \"I CtrlF":                 ['<C-f>',       'i'],
        \})

  "edit
  call extend(maps, {
        \"D":                       ['D',           'n'],
        \"Y":                       ['Y',           'n'],
        \"x":                       ['x',           'n'],
        \"X":                       ['X',           'n'],
        \"J":                       ['J',           'n'],
        \"~":                       ['~',           'n'],
        \"Del":                     ['<del>',       'n'],
        \"Dot":                     ['.',           'n'],
        \"Increase":                ['<C-a>',       'n'],
        \"Decrease":                ['<C-x>',       'n'],
        \"a":                       ['a',           'n'],
        \"A":                       ['A',           'n'],
        \"i":                       ['i',           'n'],
        \"I":                       ['I',           'n'],
        \"o":                       [leader.'o',    'n'],
        \"O":                       [leader.'O',    'n'],
        \"c":                       ['c',           'n'],
        \"C":                       ['C',           'n'],
        \"Delete":                  ['d',           'n'],
        \"Replace":                 ['r',           'n'],
        \"Replace Pattern":         ['R',           'n'],
        \"Transform Regions":       [leader.'e',    'n'],
        \"p Paste Regions":         ['p',           'n'],
        \"P Paste Regions":         ['P',           'n'],
        \"p Paste Vimreg":          [leader.'p',    'n'],
        \"P Paste Vimreg":          [leader.'P',    'n'],
        \"Yank":                    ['y',           'n'],
        \"Yank Hard":               [leader.'y',    'n'],
        \})

  return maps
endfun

