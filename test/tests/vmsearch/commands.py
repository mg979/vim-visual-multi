# VMSearch test

keys(r':VMSearch magna\<CR>')
keys(r'c')
keys(r'MAGNA')
keys(r'\<Esc>')
keys(r'\<Esc>')

# BUGGER... this took me a hour, and it still fails in vim
keys(r':%VMSearch \\')
keys(r'<LT>dolor\>\<CR>')
keys(r'c')
keys(r'DOLOR')
keys(r'\<Esc>')
keys(r'\<Esc>')

keys(r'ggVj')
keys(r':VMSearch dolor\<CR>')
keys(r'a')
keys(r'---')
keys(r'\<Esc>')

keys(r':%VMSearch lab\<CR>')
keys(r'a')
keys(r'LAB')
keys(r'\<Esc>')
keys(r'\<Esc>')

