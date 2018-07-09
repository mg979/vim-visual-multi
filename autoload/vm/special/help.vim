"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings help
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:select    = {}
let s:cursors   = {}
let s:special   = {}
let s:operators = {}
let s:settings  = {}
let s:commands  = {}
let s:zeta      = {}
let s:menus     = {}

let s:settings.maps  = ["Ctrl+c", "Ctrl+w"]
let s:settings.desc  = ["Case", "Word boundaries"]
let s:settings.note  = ["cycle case settings (smart, ignore, noignore)", "toggle word boundaries for most recent "]

let s:select.maps    = ["Ctrl+d",                                 "[",
                       \"Ctrl+s",                                 "]",
                       \"Alt+Shift+a",                            "}",
                       \"g/",                                     "{",
                       \"*",                                      "q",
                       \"#",                                      "Q",
                       \]

let s:select.desc    = ["Select inner word",                      "Find next",
                       \"Skip current match",                     "Find previous",
                       \"Find all",                               "Goto next",
                       \"Start regex search",                     "Goto previous",
                       \"Select inner word",                      "Skip current match",
                       \"Select around word",                     "Remove region",
                       \]

let s:select.note    = ["with word boundaries",                   "always downwards",
                       \"and find next in the current direction", "always upwards",
                       \"also from visual mode",                  "",
                       \"and select first occurrence",            "",
                       \"without word boundaries",                "alternate for Ctrl+s",
                       \",, ,,",                                  "and go back to previous",
                       \]

let s:cursors.maps   = ["Alt+j", "Alt+Ctrl+Down", "Alt+k", "Alt+Ctrl+Up"]
let s:cursors.desc   = ["Create new downwards", "Create new downwards", ",,         upwards", ",,         upwards"]
let s:cursors.note   = ["start in cursor mode", "start in extend mode", ",,", ",,"]

let s:operators.maps = ["gs[..]", "m[..]", "s[..]", "Alt+j"]
let s:operators.desc = ["Select Operator", "Find Operator", ",,     ,,", ",,     ,,"]
let s:operators.note = ["create a new region", "match all in text object", "affects all cursors", "from visual mode"]

let s:commands.maps  = ["Alt+a", "Ctrl+t", "Alt+d", "S"]
let s:commands.desc  = ["Align cursors", "Transposition", "Duplicate", "Surround"]
let s:commands.note  = ["to the bigger column number", "rotate regions", "extend mode only", ",,"]

let s:zeta.maps      = [
                       \"zz",                                   "zn",
                       \"zv",                                   "z0n",
                       \"zx",                                   "zN",
                       \"z@",                                   "z0N",
                       \"z.",                                   "Z",
                       \"z<",                                   "Ctrl+z",
                       \"z>",                                   "Alt+z",
                       \]

let s:zeta.desc      = [
                       \"Run Normal",                           "Numbers",
                       \"Run Visual",                           ",,",
                       \"Run Ex",                               ",,",
                       \"Run Macro",                            ",,",
                       \"Run Dot",                              "Run Last Normal",
                       \"Align by Char(s)",                     "Run Last Ex",
                       \"Align by Regex",                       "Run Last Visual",
                       \]

let s:zeta.note      = [
                       \"run normal command at cursors",        "insert before region",
                       \"run visual command ,,",                ",, (start from 0)",
                       \"run ex command ,,",                    "append after region",
                       \"run macro ,,",                         ",, (start from 0)",
                       \"run dot command ,,",                   "",
                       \"align by [count] specific characters", "",
                       \"align by regex",                       "",
                       \]

let s:menus.maps     = ["<leader>x", "<leader>s", "<leader>c"]
let s:menus.desc     = ["Tools", "Search", "Case Conversion"]
let s:menus.note     = ["", "", ""]

let s:special.maps   = ["Space", "Enter", "Tab", "Backspace"]
let s:special.desc   = ["Toggle Mappings", "Toggle Only", "Toggle Mode", "Block mode"]
let s:special.note   = ["(except space itself and escape)", "to modify a single region", "between extend and cursor mode", "(toggle)"]

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#help#show()

  let _ = "----------"

  let groups = [
        \["\n"._._._._._._._._." Select -------"._._._._._._._._."\n\n", "select"],
        \["\n"._._._._._._._._." Cursors ------"._._._._._._._._."\n\n", "cursors"],
        \["\n"._._._._._._._._." Special ------"._._._._._._._._."\n\n", "special"],
        \["\n"._._._._._._._._." Operators ----"._._._._._._._._."\n\n", "operators"],
        \["\n"._._._._._._._._." Settings -----"._._._._._._._._."\n\n", "settings"],
        \["\n"._._._._._._._._." Commands -----"._._._._._._._._."\n\n", "commands"],
        \["\n"._._._._._._._._." Zeta ---------"._._._._._._._._."\n\n", "zeta"],
        \["\n"._._._._._._._._." Menus --------"._._._._._._._._."\n\n", "menus"],
        \]

  let l:Pad = { t, n -> b:VM_Selection.Funcs.pad(t, n) }
  let l:Txt = { i, m -> (i%2? 'echon "' : 'echo "').l:Pad(m[i], 15).'"' }

  for g in groups
    echohl WarningMsg | echo g[0] | echohl None
    let M = eval("s:".g[1]).maps
    let D = eval("s:".g[1]).desc
    let N = eval("s:".g[1]).note
    let i = 0
    for m in M
      echohl Special | exe l:Txt(i, M)
      echohl Type    | echon l:Pad(D[i], 25)
      echohl None    | echon l:Pad(N[i], 50)
      let i += 1
    endfor
  endfor
endfun

