## vim-visual-multi

It's called ___vim-visual-multi___ in analogy with _visual-block_, but the plugin works mostly from normal mode.

Basic usage:

- select words with <kbd>Ctrl-N</kbd> (like `Ctrl-d` in Sublime Text/VS Code)
- create cursors vertically with <kbd>Ctrl-Down</kbd>/<kbd>Ctrl-Up</kbd>
- select one character at a time with <kbd>Shift-Arrows</kbd>
- press <kbd>n</kbd>/<kbd>N</kbd> to get next/previous occurrence
- press <kbd>[</kbd>/<kbd>]</kbd> to select next/previous cursor
- press <kbd>q</kbd> to skip current and get next occurrence
- press <kbd>Q</kbd> to remove current cursor/selection
- start insert mode with <kbd>i</kbd>,<kbd>a</kbd>,<kbd>I</kbd>,<kbd>A</kbd>

Two main modes:

- in _cursor mode_ commands work as they would in normal mode
- in _extend mode_ commands work as they would in visual mode
- press <kbd>Tab</kbd> to switch between «cursor» and «extend» mode

Most vim commands work as expected (motions, <kbd>r</kbd> to replace characters, <kbd>~</kbd> to change case, etc). Additionally you can:

- run macros/ex/normal commands at cursors
- align cursors
- transpose selections
- add patterns with regex, or from visual mode

And more... of course, you can enter insert mode and autocomplete will work.


### Installation

With vim-plug:

    Plug 'mg979/vim-visual-multi', {'branch': 'master'}


### Documentation

    :help visual-multi

For some specific topic it's often:

    :help vm-some-topic

### Tutorial

To run the tutorial:

    vim -Nu path/to/visual-multi/tutorialrc


### [Wiki](https://github.com/mg979/vim-visual-multi/wiki)

The wiki was the first documentation for the plugin, but many pictures are
outdated and contain wrong mappings. Still, you can take a look.

You could read at least the [Quick Start](https://github.com/mg979/vim-visual-multi/wiki/Quick-start).

-------
Some (sometimes very old) random pics:

-------
Insert mode with autocomplete, alignment (mappings in pic have changed, don't trust them)

![Imgur](https://i.imgur.com/u5pPY5W.gif)

-------
Undo/Redo edits and selections

![Imgur](https://i.imgur.com/gwFfUxq.gif)

-------
Alternate cursor/extend mode, motions (even %), reverse direction (as in visual mode) and extend from the back. At any time you can switch from extend to cursor mode and viceversa.

![Imgur](https://i.imgur.com/ggQr1Ve.gif)

-------
Select inside/around brackets/quotes/etc:

![Imgur](https://i.imgur.com/GAXQLao.gif)

-------
Select operator, here shown with 'wellle/targets.vim' plugin: sib, sia, saa + selection shift

![Imgur](https://i.imgur.com/yM3Fele.gif)

-------
Synched column transposition

![Imgur](https://i.imgur.com/9JDaLBi.gif)

-------
Unsynched transposition (cycle all regions, also in different lines)

![Imgur](https://i.imgur.com/UQOCxyf.gif)

-------
Shift regions left and right (M-S-\<\>)

![Imgur](https://i.imgur.com/Q7EF8YI.gif)

------
Find words under cursor, add new words (patterns stack), navigate regions, skip them, add regions with regex.

![Imgur](https://i.imgur.com/zWtelNO.gif)

-------
Normal/Visual/Ex commands at cursors

![Imgur](https://i.imgur.com/5aiQscj.gif)

-------
Macros. Shorter lines are skipped when adding cursors vertically.

![Imgur](https://i.imgur.com/3IsZzF3.gif)

-------
Some editing functions: yank, delete, paste from register, paste block from yanked regions

![Imgur](https://i.imgur.com/0jRkVdp.gif)

----------------------------------------

Case conversion

![Imgur](https://i.imgur.com/W6EP0dy.gif)

