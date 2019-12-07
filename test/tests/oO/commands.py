# insert CR, insert line above
L = '\\\\\\\\'

keys(':setf vim\<CR>jw')
keys('4\<C-Down>')
keys('Ea')
keys('\<CR>')
keys('CARRYING OVER ')
keys('\<Esc>A')
keys('\<CR>')
keys('CR at EOL')
keys('\<Esc>k')
keys(L + 'O')
keys('above CR')
keys('\<Esc>\<Esc>')
