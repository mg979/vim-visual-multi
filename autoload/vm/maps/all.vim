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

let s:base = {
      \"Reselect Last":           ['', 'n'],
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
      \"Select E":                ['', 'n'],
      \"Select BBW":              ['', 'n'],
      \"Mouse Cursor":            ['', 'n'],
      \"Mouse Word":              ['', 'n'],
      \"Mouse Column":            ['', 'n'],
      \}

fun! vm#maps#all#permanent() abort
  """Default permanent mappings dictionary."""
  let maps = s:base
  let leader = g:Vm.leader.default
  let visual = g:Vm.leader.visual

  " map <c-n> in any case
  let maps["Find Under"][0]              = '<C-n>'
  let maps["Find Subword Under"][0]      = '<C-n>'

  if g:VM_default_mappings
    let maps["Reselect Last"][0]         = leader.'gS'
    let maps["Add Cursor At Pos"][0]     = leader.'\'
    let maps["Start Regex Search"][0]    = leader.'/'
    let maps["Select All"][0]            = leader.'A'
    let maps["Add Cursor Down"][0]       = '<C-Down>'
    let maps["Add Cursor Up"][0]         = '<C-Up>'
    let maps["Select l"][0]              = '<S-Right>'
    let maps["Select h"][0]              = '<S-Left>'
    let maps["Visual Regex"][0]          = visual.'/'
    let maps["Visual All"][0]            = visual.'A'
    let maps["Visual Add"][0]            = visual.'a'
    let maps["Visual Find"][0]           = visual.'f'
    let maps["Visual Cursors"][0]        = visual.'c'
  endif

  if g:VM_mouse_mappings
    let maps["Mouse Cursor"][0]          = '<C-LeftMouse>'
    let maps["Mouse Word"][0]            = '<C-RightMouse>'
    let maps["Mouse Column"][0]          = '<M-C-RightMouse>'
  endif

  return maps
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#all#buffer() abort
  """Default buffer mappings dictionary."""

  let maps = {}
  let leader = g:Vm.leader.buffer
  let visual = g:Vm.leader.visual

  "basic
  call extend(maps, {
        \"Switch Mode":             ['<Tab>',       'n'],
        \"Toggle Single Region":    [leader.'<CR>', 'n'],
        \})

  "select
  call extend(maps, {
        \"Find Next":               ['n',         'n'],
        \"Find Prev":               ['N',         'n'],
        \"Goto Next":               [']',         'n'],
        \"Goto Prev":               ['[',         'n'],
        \"Seek Up":                 ['<C-b>',     'n'],
        \"Seek Down":               ['<C-f>',     'n'],
        \"Skip Region":             ['q',         'n'],
        \"Remove Region":           ['Q',         'n'],
        \"Remove Last Region":      [leader.'q',  'n'],
        \"Remove Every n Regions":  [leader.'R',  'n'],
        \"Select Operator":         ['s',         'n'],
        \"Find Operator":           ['m',         'n'],
        \})

  "utility
  call extend(maps, {
        \"Tools Menu":              [leader.'`',      'n'],
        \"Show Registers":          [leader.'"',      'n'],
        \"Case Setting":            [leader.'c',      'n'],
        \"Toggle Whole Word":       [leader.'w',      'n'],
        \"Case Conversion Menu":    [leader.'C',      'n'],
        \"Search Menu":             [leader.'S',      'n'],
        \"Rewrite Last Search":     [leader.'r',      'n'],
        \"Show Infoline":           [leader.'l',      'n'],
        \"One Per Line":            [leader.'L',      'n'],
        \"Filter Regions":          [leader.'f',      'n'],
        \"Toggle Multiline":        ['M',             'n'],
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
        \"Visual Subtract":         [visual.'s',  'x'],
        \"Visual Reduce":           [visual.'r',  'x'],
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
        \"Numbers":                 [leader.'N',  'n'],
        \"Numbers Append":          [leader.'n',  'n'],
        \"Zero Numbers":            [leader.'0N', 'n'],
        \"Zero Numbers Append":     [leader.'0n', 'n'],
        \"Shrink":                  [leader.'-',  'n'],
        \"Enlarge":                 [leader.'+',  'n'],
        \"Goto Regex":              [leader.'g',  'n'],
        \"Goto Regex!":             [leader.'G',  'n'],
        \"Slash Search":            ['g/',        'n'],
        \})

  "arrows
  call extend(maps, {
        \"Select Cursor Down":      ['<M-C-Down>',  'n'],
        \"Select Cursor Up":        ['<M-C-Up>',    'n'],
        \"Add Cursor Down":         ['<C-Down>',    'n'],
        \"Add Cursor Up":           ['<C-Up>',      'n'],
        \"Select j":                ['<S-Down>',    'n'],
        \"Select k":                ['<S-Up>',      'n'],
        \"Select l":                ['<S-Right>',   'n'],
        \"Select h":                ['<S-Left>',    'n'],
        \"Single Select l":         ['<M-Right>',   'n'],
        \"Single Select h":         ['<M-Left>',    'n'],
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
        \"I CtrlW":                 ['<C-w>',       'i'],
        \"I CtrlU":                 ['<C-u>',       'i'],
        \"I CtrlD":                 ['<C-d>',       'i'],
        \"I Ctrl^":                 ['<C-^>',       'i'],
        \"I Del":                   ['<Del>',       'i'],
        \"I Home":                  ['<Home>',      'i'],
        \"I End":                   ['<End>',       'i'],
        \"I CtrlB":                 ['<C-b>',       'i'],
        \"I CtrlF":                 ['<C-f>',       'i'],
        \"I CtrlC":                 ['<C-c>',       'i'],
        \"I CtrlO":                 ['<C-o>',       'i'],
        \"I Replace":               ['<Insert>',    'i'],
        \})

  let insert_keys = get(g:, 'VM_insert_special_keys', ['c-v'])
  if index(insert_keys, 'c-a') >= 0
    let maps["I CtrlA"] = ['<C-a>', 'i']
  endif
  if index(insert_keys, 'c-e') >= 0
    let maps["I CtrlE"] = ['<C-e>', 'i']
  endif
  if index(insert_keys, 'c-v') >= 0
    let maps["I Paste"] = ['<C-v>', 'i']
  endif

  "edit
  call extend(maps, {
        \"D":                       ['D',           'n'],
        \"Y":                       ['Y',           'n'],
        \"x":                       ['x',           'n'],
        \"X":                       ['X',           'n'],
        \"J":                       ['J',           'n'],
        \"~":                       ['~',           'n'],
        \"&":                       ['&',           'n'],
        \"Del":                     ['<del>',       'n'],
        \"Dot":                     ['.',           'n'],
        \"Increase":                ['<C-a>',       'n'],
        \"Decrease":                ['<C-x>',       'n'],
        \"gIncrease":               ['g<C-a>',      'n'],
        \"gDecrease":               ['g<C-x>',      'n'],
        \"Alpha Increase":          [leader.'<C-a>','n'],
        \"Alpha Decrease":          [leader.'<C-x>','n'],
        \"a":                       ['a',           'n'],
        \"A":                       ['A',           'n'],
        \"i":                       ['i',           'n'],
        \"I":                       ['I',           'n'],
        \"o":                       ['o',           'n'],
        \"O":                       ['O',           'n'],
        \"c":                       ['c',           'n'],
        \"gc":                      ['gc',          'n'],
        \"gu":                      ['gu',          'n'],
        \"gU":                      ['gU',          'n'],
        \"C":                       ['C',           'n'],
        \"Delete":                  ['d',           'n'],
        \"Replace Characters":      ['r',           'n'],
        \"Replace":                 ['R',           'n'],
        \"Transform Regions":       [leader.'e',    'n'],
        \"p Paste":                 ['p',           'n'],
        \"P Paste":                 ['P',           'n'],
        \"Yank":                    ['y',           'n'],
        \})

  return maps
endfun

" vim: et ts=2 sw=2 sts=2 :
