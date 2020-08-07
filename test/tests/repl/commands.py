# replace mode

keys(r'3\<C-Down>')
keys('R')
keys('testòlè')
keys(r'\<Esc>')
keys(r'\<Esc>')

# the same, but from second column
keys('6gg0')
keys(r'3\<C-Down>')
keys('rtlR')
keys('estòlè')
keys(r'\<Esc>')
keys(r'\<Esc>')

# from second column, and multibyte in first one
keys('11gg0l')
keys(r'3\<C-Down>')
keys('R')
keys('estòlè')
keys(r'\<Esc>')
keys(r'\<Esc>')

# backspace
keys(r':set list\<CR>')
keys('16gg0')
keys(r'3\<C-Down>')
keys('R')
keys('festòlè')
keys(r'\<BS>')
keys(r'\<BS>')
keys(r'\<BS>')
keys(r'\<BS>')
keys(r'\<BS>')
keys(r'\<BS>')
keys(r'\<Esc>')
keys(r'\<Esc>')
