# How to Run:
## run all tests:
    ./test.py

## run 1 test:
    ./test.py [test]

## list all tests
    ./test.py -l

## if you want to use an alternative default vimrc, for example to run all test with a specific vimrc default/alt.vim
    ./test.py -v alt

# Add a Test
## create a directory in tests/ then add the following files:
    input_file.txt
    commands.py
    expected_output_file.txt

## (optional) if you don't want to use default/vimrc.vim, add in the test's directory:
    vimrc.vim

## (optional) if you want to show some info about a test, add as first line of the test (or default) vimrc
    " DESCRIPTION: { test description }
