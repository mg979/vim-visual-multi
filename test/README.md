# How to Run:
## run all tests:
    ./test.py

## run 1 test:
    ./test.py [test]

## list all tests
    ./test.py -l

# Add a Test
## create a directory in tests/ then add the following files:
    input_file.txt
    commands.py
    expected_output_file.txt

## (optional) if you don't want to use default/vimrc.vim, add:
    vimrc.vim

# Reminders

When creating tests, some characters need special escaping:

* a literal backslash is written `\\\\`
* a literal double quote is written `\\"`
