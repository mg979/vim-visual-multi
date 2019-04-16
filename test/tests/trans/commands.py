# transpositions and region splitting
L = '\\\\\\\\'

keys(':let @/ = \\"\\"\<CR>')
keys('\<C-Down>\<C-Down>\<C-Down>')
keys('\<C-Right>')
keys('\<C-Up>\<C-Up>\<C-Up>')
keys('\<C-n>')
keys(L + 't')
keys('\<Esc>}j0')

keys('V3j')
keys(L + 'a')
keys(L + 's')
keys('\<Space>\<CR>')
keys(L + 't')
keys('\<Esc>')

keys('/cat\\\\|bat\<CR>')
keys('ggV3j')
keys(L + 'f')
keys(L + 't')
keys('\<Esc>')

