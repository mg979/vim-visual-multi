#!/bin/env python3

import vimrunner

vim = vimrunner.Server(noplugin=False, vimrc='vimrc/default.vim')
client = vim.start()
client.edit('input/example.txt')

client.feedkeys('\<C-Down>\<C-Down>\<C-Down>')
client.feedkeys('i')
client.feedkeys('Hello')
client.feedkeys('\<Esc>')

client.feedkeys(':wq! output.txt\<CR>')

# TODO: compare expected output and actual output
