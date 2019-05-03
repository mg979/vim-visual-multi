# insert CR, insert line above
L = '\\\\\\\\'

keys(':setf vim\<CR>jw')
keys('4\<C-Down>Ea')
keys('\<CR>')
keys('test ')
keys('\<Esc>')
keys(L + 'O')
keys('above CR')
keys('\<Esc>\<Esc>')
