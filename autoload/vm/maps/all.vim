
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Key -> plug:
"       'Select Operator' ->    <Plug>(VM-Select-Operator)

"Contents of lists:
"       [0]: mapping
"       [1]: mode
"       [2]: silent
"       [3]: nowait
"
" When adding a new mapping, the following is required:
"       1. add a <Plug> with a command
"       2. add the reformatted plug name in this file (permanent or buffer section)
"       3. update the help file: an entry in s:plugs is necessary
"       4. in the help file, add an entry in a section of s:dict to assign a category

let s:base = {
            \"Select Operator":         ['', 'n', 1, 1],
            \"Erase Regions":           ['', 'n', 1, 1],
            \"Add Cursor At Pos":       ['', 'n', 1, 1],
            \"Add Cursor At Word":      ['', 'n', 1, 1],
            \"Start Regex Search":      ['', 'n', 1, 1],
            \"Select All":              ['', 'n', 1, 1],
            \"Add Cursor Down":         ['', 'n', 1, 1],
            \"Add Cursor Up":           ['', 'n', 1, 1],
            \"Visual Regex":            ['', 'x', 1, 1],
            \"Visual All":              ['', 'x', 1, 1],
            \"Visual Add":              ['', 'x', 1, 1],
            \"Visual Find":             ['', 'x', 1, 1],
            \"Visual Cursors":          ['', 'x', 1, 1],
            \"Find Under":              ['', 'n', 1, 1],
            \"Find Subword Under":      ['', 'x', 1, 1],
            \"Select Cursor Down":      ['', 'n', 1, 1],
            \"Select Cursor Up":        ['', 'n', 1, 1],
            \"Select j":                ['', 'n', 1, 1],
            \"Select k":                ['', 'n', 1, 1],
            \"Select l":                ['', 'n', 1, 1],
            \"Select h":                ['', 'n', 1, 1],
            \"Select w":                ['', 'n', 1, 1],
            \"Select b":                ['', 'n', 1, 1],
            \"Select Line Down":        ['', 'n', 1, 1],
            \"Select Line Up":          ['', 'n', 1, 1],
            \"Select E":                ['', 'n', 1, 1],
            \"Select BBW":              ['', 'n', 1, 1],
            \"Find I Word":             ['', 'n', 1, 1],
            \"Find A Word":             ['', 'n', 1, 1],
            \"Find A Subword":          ['', 'x', 1, 1],
            \"Find A Whole Subword":    ['', 'x', 1, 1],
            \"Mouse Cursor":            ['', 'n', 1, 1],
            \"Mouse Word":              ['', 'n', 1, 1],
            \"Mouse Column":            ['', 'n', 1, 1],
            \}

fun! vm#maps#all#permanent()
    """Default permanent mappings dictionary."""
    let maps = s:base

    if g:VM_default_mappings
        let maps["Select Operator"][0]          = 'gs'
        let maps["Add Cursor At Pos"][0]        = 'g<space>'
        let maps["Start Regex Search"][0]       = 'g/'
        let maps["Select All"][0]               = '<M-A>'
        let maps["Add Cursor Down"][0]          = '<M-j>'
        let maps["Add Cursor Up"][0]            = '<M-k>'
        let maps["Visual Regex"][0]             = 'g/'
        let maps["Visual All"][0]               = '<M-A>'
        let maps["Visual Add"][0]               = '<M-a>'
        let maps["Visual Find"][0]              = '<C-f>'
        let maps["Visual Cursors"][0]           = '<C-c>'
        let maps["Find Under"][0]               = '<C-n>'
        let maps["Find Subword Under"][0]       = '<C-n>'
    endif

    if g:VM_sublime_mappings
        let maps["Select Cursor Down"][0]       = '<M-C-Down>'
        let maps["Select Cursor Up"][0]         = '<M-C-Up>'
        let maps["Select j"][0]                 = '<S-Down>'
        let maps["Select k"][0]                 = '<S-Up>'
        let maps["Select l"][0]                 = '<S-Right>'
        let maps["Select h"][0]                 = '<S-Left>'
        let maps["Select w"][0]                 = '<C-S-Right>'
        let maps["Select b"][0]                 = '<C-S-Left>'
        let maps["Select Line Down"][0]         = '<C-S-Down>'
        let maps["Select Line Up"][0]           = '<C-S-Up>'
        let maps["Select E"][0]                 = '<M-C-Right>'
        let maps["Select BBW"][0]               = '<M-C-Left>'
        let maps["Find Under"][0]               = '<C-d>'
        let maps["Find Subword Under"][0]       = '<C-d>'
    endif

    if g:VM_extended_mappings
        let maps["Find I Word"][0]              = 'gw'
        let maps["Find A Word"][0]              = 'gW'
        let maps["Find A Subword"][0]           = 'gw'
        let maps["Find A Whole Subword"][0]     = 'gW'
    endif

    if g:VM_mouse_mappings
        let maps["Mouse Cursor"][0]             = '<C-LeftMouse>'
        let maps["Mouse Word"][0]               = '<C-RightMouse>'
        let maps["Mouse Column"][0]             = '<M-C-RightMouse>'
    endif

    if g:VM_no_meta_mappings
        let maps['Select All'][0]               = '<leader>A'
        let maps['Visual All'][0]               = '<leader>A'
        let maps['Add Cursor Down'][0]          = '<C-Down>'
        let maps['Add Cursor Up'][0]            = '<C-Up>'
        let maps['Visual Add'][0]               = '<C-a>'
    endif

    return maps
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#all#buffer()
    """Default buffer mappings dictionary."""

    let maps = {}

    "s
    call extend(maps, {
                \"Find I Word":             ['gw',        'n', 1, 1],
                \"Find A Word":             ['gW',        'n', 1, 1],
                \"Find A Subword":          ['gw',        'x', 1, 1],
                \"Find A Whole Subword":    ['gW',        'x', 1, 1],
                \})

    "sublime
    call extend(maps, {
                \"Skip Region":             ['<C-s>',      'n', 1, 1],
                \"F3 Next":                 ['<F3>',       'n', 1, 1],
                \"F2 Prev":                 ['<F2>',       'n', 1, 1],
                \})

    "basic
    call extend(maps, {
                \"Switch Mode":             ['<Tab>',     'n', 1, 1],
                \"Toggle Block":            ['<BS>',      'n', 1, 1],
                \"Toggle Only This Region": ['<CR>',      'n', 1, 1],
                \})

    "select
    call extend(maps, {
                \"Find Next":               [']',         'n', 1, 1],
                \"Find Prev":               ['[',         'n', 1, 1],
                \"Goto Next":               ['}',         'n', 1, 1],
                \"Goto Prev":               ['{',         'n', 1, 1],
                \"Seek Up":                 ['<C-b>',     'n', 1, 1],
                \"Seek Down":               ['<C-f>',     'n', 1, 1],
                \"Invert Direction":        ['o',         'n', 1, 1],
                \"q Skip":                  ['q',         'n', 1, 1],
                \"Remove Region":           ['Q',         'n', 1, 1],
                \"Remove Last Region":      ['<M-q>',     'n', 1, 1],
                \"Remove Every n Regions":  ['<leader>R', 'n', 1, 1],
                \"Star":                    ['*',         'n', 1, 1],
                \"Hash":                    ['#',         'n', 1, 1],
                \"Visual Star":             ['*',         'x', 1, 1],
                \"Visual Hash":             ['#',         'x', 1, 1],
                \"Merge To Eol":            ['<S-End>',   'n', 1, 1],
                \"Merge To Bol":            ['<S-Home>',  'n', 1, 1],
                \"Select All Operator":     ['s',         "n", 1, 0],
                \"Find Operator":           ["m",         'n', 1, 1],
                \"Add Cursor Down":         ['<M-j>',     'n', 1, 1],
                \"Add Cursor Up":           ['<M-k>',     'n', 1, 1],
                \})

    "utility
    call extend(maps, {
                \"Tools Menu":              ['<leader>x', 'n', 1, 1],
                \"Show Help":               ['<F1>',      'n', 1, 1],
                \"Show Registers":          ['<leader>"', 'n', 0, 1],
                \"Toggle Debug":            ['<C-x><F12>','n', 1, 1],
                \"Case Setting":            ['<c-c>',     'n', 1, 1],
                \"Toggle Whole Word":       ['<c-w>',     'n', 1, 1],
                \"Case Conversion Menu":    ['<leader>c', 'n', 1, 1],
                \"Search Menu":             ['<leader>S', 'n', 1, 1],
                \"Rewrite Last Search":     ['<leader>r', 'n', 1, 1],
                \"Show Infoline":           ['<leader>l', 'n', 0, 1],
                \"Toggle Multiline":        ['M',         'n', 1, 1],
                \})

    "commands
    call extend(maps, {
                \"Surround":                ['S',         'n', 1, 1],
                \"Merge Regions":           ['<leader>m', 'n', 1, 1],
                \"Transpose":               ['<leader>t', 'n', 1, 1],
                \"Duplicate":               ['<leader>d', 'n', 1, 1],
                \"Align":                   ['<leader>a', 'n', 1, 1],
                \"Split Regions":           ['<leader>s', 'n', 1, 1],
                \"Visual Subtract":         ['<M-s>',     'x', 1, 1],
                \})

    "zeta
    call extend(maps, {
                \"Run Normal":              ['zz',        'n', 0, 1],
                \"Run Last Normal":         ['Z',         'n', 1, 1],
                \"Run Visual":              ['zv',        'n', 0, 1],
                \"Run Last Visual":         ['<M-z>',     'n', 1, 1],
                \"Run Ex":                  ['zx',        'n', 0, 1],
                \"Run Last Ex":             ['<C-z>',     'n', 1, 1],
                \"Run Macro":               ['z@',        'n', 1, 1],
                \"Run Dot":                 ['z.',        'n', 1, 1],
                \"Align Char":              ['z<',        'n', 1, 1],
                \"Align Regex":             ['z>',        'n', 1, 1],
                \"Numbers":                 ['zn',        'n', 0, 1],
                \"Numbers Append":          ['zN',        'n', 1, 1],
                \"Zero Numbers":            ['z0n',       'n', 0, 1],
                \"Zero Numbers Append":     ['z0N',       'n', 1, 1],
                \"Shrink":                  ["z-",        'n', 1, 1],
                \"Enlarge":                 ["z+",        'n', 1, 1],
                \})

    "arrows
    call extend(maps, {
                \"Select Cursor Down":      ['<M-C-Down>',  'n', 1, 1],
                \"Select Cursor Up":        ['<M-C-Up>',    'n', 1, 1],
                \"Select Line Down":        ['',            'n', 1, 1],
                \"Select Line Up":          ['',            'n', 1, 1],
                \"Add Cursor Down":         ['',            'n', 1, 1],
                \"Add Cursor Up":           ['',            'n', 1, 1],
                \"Select j":                ['<S-Down>',    'n', 1, 1],
                \"Select k":                ['<S-Up>',      'n', 1, 1],
                \"Select l":                ['<S-Right>',   'n', 1, 1],
                \"Select h":                ['<S-Left>',    'n', 1, 1],
                \"This Select l":           ['<M-Right>',   'n', 1, 1],
                \"This Select h":           ['<M-Left>',    'n', 1, 1],
                \"Select e":                ['',            'n', 1, 1],
                \"Select ge":               ['',            'n', 1, 1],
                \"Select w":                ['',            'n', 1, 1],
                \"Select b":                ['',            'n', 1, 1],
                \"Select E":                ['',            'n', 1, 1],
                \"Select BBW":              ['',            'n', 1, 1],
                \"Move Right":              ['<M-S-Right>', 'n', 1, 1],
                \"Move Left":               ['<M-S-Left>',  'n', 1, 1],
                \})

    "insert
    call extend(maps, {
                \"I Arrow w":               ['<C-Right>',   'i', 1, 1],
                \"I Arrow b":               ['<C-Left>',    'i', 1, 1],
                \"I Arrow W":               ['<C-S-Right>', 'i', 1, 1],
                \"I Arrow B":               ['<C-S-Left>',  'i', 1, 1],
                \"I Arrow ge":              ['<C-Up>',      'i', 1, 1],
                \"I Arrow e":               ['<C-Down>',    'i', 1, 1],
                \"I Arrow gE":              ['<C-S-Up>',    'i', 1, 1],
                \"I Arrow E":               ['<C-S-Down>',  'i', 1, 1],
                \"I Left Arrow":            ['<Left>',      'i', 1, 1],
                \"I Right Arrow":           ['<Right>',     'i', 1, 1],
                \"I Up Arrow":              ['<Up>',        'i', 1, 1],
                \"I Down Arrow":            ['<Down>',      'i', 1, 1],
                \"I Return":                ['<CR>',        'i', 1, 1],
                \"I BS":                    ['<BS>',        'i', 1, 1],
                \"I Paste":                 ['<C-v>',       'i', 1, 1],
                \"I CtrlW":                 ['<C-w>',       'i', 1, 1],
                \"I CtrlD":                 ['<C-d>',       'i', 1, 1],
                \"I Del":                   ['<Del>',       'i', 1, 1],
                \"I CtrlA":                 ['<C-a>',       'i', 1, 1],
                \"I CtrlE":                 ['<C-e>',       'i', 1, 1],
                \"I CtrlB":                 ['<C-b>',       'i', 1, 1],
                \"I CtrlF":                 ['<C-f>',       'i', 1, 1],
                \})

    "edit
    call extend(maps, {
                \"D":                       ['D',           'n', 1, 1],
                \"Y":                       ['Y',           'n', 1, 1],
                \"x":                       ['x',           'n', 1, 1],
                \"X":                       ['X',           'n', 1, 1],
                \"J":                       ['J',           'n', 1, 1],
                \"~":                       ['~',           'n', 1, 1],
                \"Del":                     ['<del>',       'n', 1, 1],
                \"Dot":                     ['.',           'n', 1, 1],
                \"Increase":                ['+',           'n', 1, 1],
                \"Decrease":                ['-',           'n', 1, 1],
                \"a":                       ['a',           'n', 1, 1],
                \"A":                       ['A',           'n', 1, 1],
                \"i":                       ['i',           'n', 1, 1],
                \"I":                       ['I',           'n', 1, 1],
                \"o":                       ['<leader>o',   'n', 1, 1],
                \"O":                       ['<leader>O',   'n', 1, 1],
                \"c":                       ['c',           'n', 1, 1],
                \"C":                       ['C',           'n', 1, 1],
                \"Delete":                  ['d',           'n', 1, 1],
                \"Replace":                 ['r',           'n', 1, 1],
                \"Replace Pattern":         ['R',           'n', 1, 1],
                \"Transform Regions":       ['<leader>e',   'n', 1, 1],
                \"p Paste Regions":         ['p',           'n', 1, 1],
                \"P Paste Regions":         ['P',           'n', 1, 1],
                \"p Paste Normal":          ['<leader>p',   'n', 1, 1],
                \"P Paste Normal":          ['<leader>P',   'n', 1, 1],
                \"Yank":                    ['y',           'n', 1, 1],
                \"Yank Hard":               ['<leader>y',   'n', 1, 1],
                \})

    if g:VM_sublime_mappings
        let maps["Select e"][0]                 = '<C-Right>'
        let maps["Select ge"][0]                = '<C-Left>'
        let maps["Select w"][0]                 = '<C-S-Right>'
        let maps["Select b"][0]                 = '<C-S-Left>'
        let maps["Select Line Down"][0]         = '<C-S-Down>'
        let maps["Select Line Up"][0]           = '<C-S-Up>'
        let maps["Select E"][0]                 = '<M-C-Right>'
        let maps["Select BBW"][0]               = '<M-C-Left>'
    endif

    if g:VM_no_meta_mappings
        let maps['Remove Last Region'][0] = '<C-q>'
        let maps['Add Cursor Down'][0]    = '<C-Down>'
        let maps['Add Cursor Up'][0]      = '<C-Up>'
        let maps['Visual Subtract'][0]    = '<C-s>'
        let maps['Run Last Visual'][0]    = 'zV'
        let maps['Add Cursor Down'][0]    = '<C-Down>'
        let maps['Add Cursor Up'][0]      = '<C-Up>'
        let maps['Move Right'][0]         = '<C-l>'
        let maps['Move Left'][0]          = '<C-h>'
    endif

    return maps
endfun

