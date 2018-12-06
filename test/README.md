# How to Run:
run all tests:
    ./test.py

run 1 test:
    ./test.py <test>

list all <test>
    ./test.py -l

# Add a Test
To add a test, add the following files:
    input/file/<test>.txt
    input/command/<test>.py
    output/file/expected/<test>.txt

(optional) If you don't want to use the default input/vimrc/default.vim, add:
    input/vimrc/<test>.vim
