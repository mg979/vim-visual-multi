"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings help
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:settings = [
      \["Ctrl+c\t\t",      "Case\t\t\t",             "cycle case settings (smart, ignore, noignore)"],
      \["Ctrl+w\t\t",      "Word boundaries\t\t",    "toggle word boundaries for most recent pattern"]
      \]

let s:select = [
      \["Ctrl+d\t\t",      "Select inner word\t",    "with word boundaries"],
      \["Ctrl+s\t\t",      "Skip current match\t",   "and find next in the current direction"],
      \["Alt+Shift+a\t",   "Find all\t\t",           "also from visual mode"],
      \["]\t\t",           "Find next\t\t",          "always downwards"],
      \["[\t\t",           "Find previous\t\t",      "always upwards"],
      \["}\t\t",           "Goto next\t",            ""],
      \["{\t\t",           "Goto previous\t",        ""],
      \["q\t\t",           "Skip current match\t",   "alternate for Ctrl-s"],
      \["Q\t\t",           "Remove region\t\t",      "and go back to previous"]
      \]

let s:cursors = [
      \["Alt+j\t\t",       "Create new downwards\t", "start in cursor mode"],
      \["Alt+k\t\t",       ",,         upwards\t",   ",,"],
      \["Alt+Ctrl+Down\t", "Create new downwards\t", "start in extend mode"],
      \["Alt+Ctrl+Up\t",   ",,         upwards\t",   ",,"],
      \]

let s:operators = [
      \["gs[..]\t\t",        "Select Operator\t\t",    "create a new region"],
      \["s[..]\t\t",         ",,     ,,\t\t",          "affects all cursors"],
      \["m[..]\t\t",         "Find Operator\t\t",      "match all in text object"],
      \["Alt+j\t\t",       ",,     ,,\t\t",          "from visual mode"],
      \]

let s:commands = [
      \["Alt+a\t\t",       "Align cursors\t\t",      "to the bigger column number"],
      \["Ctrl+t\t\t",      "Transposition\t\t",      "rotate regions"],
      \["Alt+d\t\t",       "Duplicate\t\t",          "extend mode only"],
      \["S\t\t",           "Surround\t\t",           ",,"],
      \]

let s:zeta = [
      \["z-\t\t",            "Shrink\t\t",           ""],
      \["z+\t\t",            "Enlarge\t\t",          ""],
      \["zz\t\t",            "Run Normal\t\t",       "run normal command at cursors"],
      \["zv\t\t",            "Run Visual\t\t",       "run visual command at cursors"],
      \["zx\t\t",            "Run Ex\t\t\t",         "run ex command at cursors"],
      \["z@\t\t",            "Run Macro\t\t",        "run macro at cursors"],
      \["z.\t\t",            "Run Dot\t\t",          ""],
      \["z<\t\t",            "Align by Char(s)\t",   "align by [count] specific characters"],
      \["z>\t\t",            "Align by Regex\t\t",   "align by regex"],
      \["zn\t\t",            "Numbers\t\t\t",        "(insert before region)"],
      \["z0n\t\t",           ",,\t\t\t",             ",, (start from 0)"],
      \["zN\t\t",            ",,\t\t\t",             "(append after region)"],
      \["z0N\t\t",           ",,\t\t\t",             ",, (start from 0)"],
      \["Z\t\t",             "Run Last Normal\t\t",  ""],
      \["Alt+z\t\t",         "Run Last Visual\t\t",  ""],
      \["Ctrl+z\t\t",        "Run Last Ex\t\t",      ""],
      \]

let s:menus = [
      \["<leader>x\t",     "Tools\t\t",              ""],
      \["<leader>s\t",     "Search\t\t",             ""],
      \["<leader>c\t",     "Case Conversion\t\t",    ""],
      \]

let s:special = [
      \["Space\t\t",       "Toggle Mappings\t\t",    "(except space itself and escape)"],
      \["Enter\t\t",       "Toggle Only\t\t",        "use to change a single region"],
      \["Tab\t\t",         "Toggle Mode\t\t",        "between extend and cursor mode"],
      \["Backspace\t",     "Block mode\t\t",         "(toggle)"],
      \]

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#special#help#show()

  let groups = [
        \["\n--------- Select -------------------\n\n", s:select],
        \["\n--------- Cursors ------------------\n\n", s:cursors],
        \["\n--------- Special ------------------\n\n", s:special],
        \["\n--------- Operators ----------------\n\n", s:operators],
        \["\n--------- Settings -----------------\n\n", s:settings],
        \["\n--------- Commands -----------------\n\n", s:commands],
        \["\n--------- Zeta ---------------------\n\n", s:zeta],
        \["\n--------- Menus --------------------\n\n", s:menus],
        \]

  for g in groups
    echohl WarningMsg | echo g[0] | echohl None
    for t in g[1]
      echohl Special | echo t[0] | echohl Type | echon t[1] | echohl None | echon t[2]
    endfor
  endfor
  echo "\n"
endfun

