
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#all#permanent()
    """Default permanent mappings dictionary."""
    let maps = {}

    let maps.sublime = {
                \"Select Cursor Down":      ['<M-C-Down>',  'n', 1, 1],
                \"Select Cursor Up":        ['<M-C-Up>',    'n', 1, 1],
                \"Select j":                ['<S-Down>',    'n', 1, 1],
                \"Select k":                ['<S-Up>',      'n', 1, 1],
                \"Select l":                ['<S-Right>',   'n', 1, 1],
                \"Select h":                ['<S-Left>',    'n', 1, 1],
                \"Select w":                ['<C-S-Right>', 'n', 1, 1],
                \"Select b":                ['<C-S-Left>',  'n', 1, 1],
                \"Select Line Down":        ['<C-S-Down>',  'n', 1, 1],
                \"Select Line Up":          ['<C-S-Up>',    'n', 1, 1],
                \"Select E":                ['<M-C-Right>', 'n', 1, 1],
                \"Select BBW":              ['<M-C-Left>',  'n', 1, 1],
                \"Find Under":              ['<C-d>',       'n', 1, 1],
                \"Find Subword Under":      ['<C-d>',       'x', 1, 1],
                \}

    let maps.s = {
                \"Find I Word":             ['s]',        'n', 1, 1],
                \"Find A Word":             ['s[',        'n', 1, 1],
                \"Find I Whole Word":       ['s}',        'n', 1, 1],
                \"Find A Subword":          ['s]',        'x', 1, 1],
                \"Find A Whole Subword":    ['s[',        'x', 1, 1],
                \}

    let maps.mouse = {
                \"Mouse Cursor":            ['<C-LeftMouse>',    'n', 1, 1],
                \"Mouse Word":              ['<C-RightMouse>',   'n', 1, 1],
                \"Mouse Column":            ['<M-C-RightMouse>', 'n', 1, 1],
                \}

    let maps.default = {
                \"Select Operator":         ['gs',        'n', 1, 1],
                \"Erase Regions":           ['gr',        'n', 1, 1],
                \"Add Cursor At Pos":       ['g<space>',  'n', 1, 1],
                \"Add Cursor At Word":      ['g<cr>',     'n', 1, 1],
                \"Start Regex Search":      ['g/',        'n', 1, 1],
                \"Select All":              ['<M-A>',     'n', 1, 1],
                \"Add Cursor Down":         ['<M-j>',     'n', 1, 1],
                \"Add Cursor Up":           ['<M-k>',     'n', 1, 1],
                \"Visual Regex":            ['g/',        'x', 1, 1],
                \"Visual All":              ['<M-A>',     'x', 1, 1],
                \"Visual Add":              ['<M-a>',     'x', 1, 1],
                \"Visual Find":             ['<C-f>',     'x', 1, 1],
                \"Visual Cursors":          ['<C-c>',     'x', 1, 1],
                \}

    if g:VM_no_meta_mappings
        let maps.default['Select All'][0]      = '<leader>A'
        let maps.default['Visual All'][0]      = '<leader>A'
        let maps.default['Add Cursor Down'][0] = '<C-Down>'
        let maps.default['Add Cursor Up'][0]   = '<C-Up>'
        let maps.default['Visual Add'][0]      = '<C-a>'
    endif

    if !g:VM_sublime_mappings
        let maps.default['Find Under']         = ['<C-n>',       'n', 1, 1],
        let maps.default['Find Subword Under'] = ['<C-n>',       'x', 1, 1],
    endif
    return maps
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#maps#all#buffer()
    """Default buffer mappings dictionary."""

    let maps = {}

    let maps.s = {
                \"Find I Word":             ['s]',        'n', 1, 1],
                \"Find A Word":             ['s[',        'n', 1, 1],
                \"Find I Whole Word":       ['s}',        'n', 1, 1],
                \"Find A Subword":          ['s]',        'x', 1, 1],
                \"Find A Whole Subword":    ['s[',        'x', 1, 1],
                \}

    let maps.sublime = {
                \"Skip Region":             ['<C-s>',      'n', 1, 1],
                \"Goto Next":               ['<F2>',       'n', 1, 1],
                \"Goto Prev":               ['<S-F2>',     'n', 1, 1],
                \}

    let maps.basic = {
                \"Switch Mode":             ['<Tab>',     'n', 1, 1],
                \"Toggle Block":            ['<BS>',      'n', 1, 1],
                \"Toggle Only This Region": ['<CR>',      'n', 1, 1],
                \}

    let maps.select = {
                \"Find Next":               [']',         'n', 1, 1],
                \"Find Prev":               ['[',         'n', 1, 1],
                \"Goto Next":               ['}',         'n', 1, 1],
                \"Goto Prev":               ['{',         'n', 1, 1],
                \"Invert Direction":        ['o',         'n', 1, 1],
                \"Skip Region":             ['q',         'n', 1, 1],
                \"Remove Region":           ['Q',         'n', 1, 1],
                \"Remove Last Region":      ['<M-q>',     'n', 1, 1],
                \"Star":                    ['*',         'n', 1, 1],
                \"Hash":                    ['#',         'n', 1, 1],
                \"Visual Star":             ['*',         'x', 1, 1],
                \"Visual Hash":             ['#',         'x', 1, 1],
                \"Merge To Eol":            ['<S-End>',   'n', 1, 1],
                \"Merge To Bol":            ['<S-Home>',  'n', 1, 1],
                \"Select All Operator":     ['s',         "n", 1, 0],
                \"Find Operator":           ["m",         'n', 1, 1],
                \"This Motion h":           ['<C-h>',     'n', 1, 1],
                \"This Motion l":           ['<C-l>',     'n', 1, 1],
                \"Add Cursor Down":         ['<M-j>',     'n', 1, 1],
                \"Add Cursor Up":           ['<M-k>',     'n', 1, 1],
                \}

    let maps.utility = {
                \"Tools Menu":              ['<leader>x', 'n', 1, 1],
                \"Show Help":               ['<F1>',      'n', 1, 1],
                \"Show Registers":          ['<leader>"', 'n', 0, 1],
                \"Toggle Debug":            ['<C-x><F12>','n', 1, 1],
                \"Case Setting":            ['<c-c>',     'n', 1, 1],
                \"Toggle Whole Word":       ['<c-w>',     'n', 1, 1],
                \"Case Conversion Menu":    ['<leader>c', 'n', 1, 1],
                \"Search Menu":             ['<leader>S', 'n', 1, 1],
                \"Rewrite Last Search":     ['<leader>r', 'n', 1, 1],
                \"Toggle Multiline":        ['M',         'n', 1, 1],
                \}

    let maps.commands = {
                \"Surround":                ['S',         'n', 1, 1],
                \"Merge Regions":           ['<leader>m', 'n', 1, 1],
                \"Transpose":               ['<leader>t', 'n', 1, 1],
                \"Duplicate":               ['<leader>d', 'n', 1, 1],
                \"Align":                   ['<leader>a', 'n', 1, 1],
                \"Split Regions":           ['<leader>s', 'n', 1, 1],
                \"Visual Subtract":         ['<M-s>',     'x', 1, 1],
                \}

    let maps.zeta = {
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
                \}

    let maps.arrows = {
                \"Select Cursor Down":      ['<M-C-Down>',  'n', 1, 1],
                \"Select Cursor Up":        ['<M-C-Up>',    'n', 1, 1],
                \"Select Line Down":        ['<C-S-Down>',  'n', 1, 1],
                \"Select Line Up":          ['<C-S-Up>',    'n', 1, 1],
                \"Add Cursor Down":         ['',            'n', 1, 1],
                \"Add Cursor Up":           ['',            'n', 1, 1],
                \"Select j":                ['<S-Down>',    'n', 1, 1],
                \"Select k":                ['<S-Up>',      'n', 1, 1],
                \"Select l":                ['<S-Right>',   'n', 1, 1],
                \"Select h":                ['<S-Left>',    'n', 1, 1],
                \"This Select l":           ['<M-Right>',   'n', 1, 1],
                \"This Select h":           ['<M-Left>',    'n', 1, 1],
                \"Select e":                ['<C-Right>',   'n', 1, 1],
                \"Select ge":               ['<C-Left>',    'n', 1, 1],
                \"Select w":                ['<C-S-Right>', 'n', 1, 1],
                \"Select b":                ['<C-S-Left>',  'n', 1, 1],
                \"Select E":                ['<M-C-Right>', 'n', 1, 1],
                \"Select BBW":              ['<M-C-Left>',  'n', 1, 1],
                \"Shift Right":             ['<M-S-Right>', 'n', 1, 1],
                \"Shift Left":              ['<M-S-Left>',  'n', 1, 1],
                \}

    let maps.insert = {
                \"Arrow w":                 ['<C-Right>',   'i', 1, 1],
                \"Arrow b":                 ['<C-Left>',    'i', 1, 1],
                \"Arrow W":                 ['<C-S-Right>', 'i', 1, 1],
                \"Arrow B":                 ['<C-S-Left>',  'i', 1, 1],
                \"Arrow ge":                ['<C-Up>',      'i', 1, 1],
                \"Arrow e":                 ['<C-Down>',    'i', 1, 1],
                \"Arrow gE":                ['<C-S-Up>',    'i', 1, 1],
                \"Arrow E":                 ['<C-S-Down>',  'i', 1, 1],
                \"Left Arrow":              ['<Left>',      'i', 1, 1],
                \"Right Arrow":             ['<Right>',     'i', 1, 1],
                \"Up Arrow":                ['<Up>',        'i', 1, 1],
                \"Down Arrow":              ['<Down>',      'i', 1, 1],
                \"Return":                  ['<CR>',        'i', 1, 1],
                \"BS":                      ['<BS>',        'i', 1, 1],
                \"Paste":                   ['<C-v>',       'i', 1, 1],
                \"CtrlW":                   ['<C-w>',       'i', 1, 1],
                \"CtrlD":                   ['<C-d>',       'i', 1, 1],
                \"Del":                     ['<Del>',       'i', 1, 1],
                \"CtrlA":                   ['<C-a>',       'i', 1, 1],
                \"CtrlE":                   ['<C-e>',       'i', 1, 1],
                \"CtrlB":                   ['<C-b>',       'i', 1, 1],
                \"CtrlF":                   ['<C-f>',       'i', 1, 1],
                \}

    let maps.edit = {
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
                \"p Paste Regions":         ['p',           'n', 1, 1],
                \"P Paste Regions":         ['P',           'n', 1, 1],
                \"p Paste Normal":          ['<leader>p',   'n', 1, 1],
                \"P Paste Normal":          ['<leader>P',   'n', 1, 1],
                \"Yank":                    ['y',           'n', 1, 1],
                \}

    if g:VM_no_meta_mappings
        let maps.select['Remove Last Region'][0]   = '<C-q>'
        let maps.select['Add Cursor Down'][0]      = '<C-Down>'
        let maps.select['Add Cursor Up'][0]        = '<C-Up>'
        let maps.commands['Visual Subtract'][0]    = '<C-s>'
        let maps.zeta['Run Last Visual'][0]        = 'zV'
        let maps.arrows['Add Cursor Down'][0]      = '<C-Down>'
        let maps.arrows['Add Cursor Up'][0]        = '<C-Up>'
    endif

    return maps
endfun

