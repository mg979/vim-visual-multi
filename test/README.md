# How to Run:
## run all tests:
    ./test.py

## run 1 test:
    ./test.py [test]

## list all tests
    ./test.py -l

## use a different key interval (default 0.1s)
    ./test.py -t 0.3

## show a diff for failed tests
    ./test.py -d

## run with `g:VM_live_editing` disabled
    ./test.py -L

# Add a Test
## create a directory in tests/ then add the following files:
  - input_file.txt
  - commands.py
    - a literal backslash is written `r'\\'`
    - a literal double quote is written `r'\"'`
    - key notation have to be escaped `r'\<CR>'`
  - expected_output_file.txt

You can call the following function to create a template:

    :call vm#special#commands#new_test()

## (optional) if you don't want to use default/vimrc.vim, add:
  - vimrc.vim

## (optional) if you want to add extra constraints, add:
  - config.json
```json
{
  "max_cpu_time": 2.7
}
```
