#!/bin/env python3

import argparse
from pathlib import Path, PurePath
import os
import sys
import shutil
import filecmp
import vimrunner

# arg parsing
parser = argparse.ArgumentParser(description='Run test suite. See README.')
parser.add_argument('test', nargs='?', help='run <test> only instead of running all tests')
parser.add_argument('-l', '--list', action='store_true', help='list all tests')
args = parser.parse_args()


def my_print(string, f=None):
    print(string)
    if f is not None:
        f.write(string + "\n")


def print_banner(string, f=None):
    my_print("""
#--------------------------------------------------------------
# %s
#--------------------------------------------------------------""" % string, f)


def run_one_test(test, f=None):
    print_banner(test, f)
    my_print("reproduce: ./test.py " + test, f)
    # input/output files
    try:
        vimrc_path = Path('tests/', test, 'vimrc.vim').resolve(strict=True)
    except FileNotFoundError:
        vimrc_path = Path('default/', 'vimrc.vim').resolve(strict=True)
        my_print("using default vimrc", f)
    command_path = Path('tests/', test, 'commands.py').resolve(strict=True)
    in_file_path = Path('tests/', test, 'input_file.txt').resolve(strict=True)
    exp_out_file_path = Path('tests/', test, 'expected_output_file.txt').resolve(strict=True)
    gen_out_file_path = Path('tests/', test, 'generated_output_file.txt').resolve()
    if os.path.exists(gen_out_file_path):
        os.remove(gen_out_file_path)
    # run test
    # TODO: remove shutil.which once vimrunner is fixed
    vim = vimrunner.Server(noplugin=False, vimrc=vimrc_path, executable=shutil.which('vim'))
    client = vim.start()
    client.edit(in_file_path)
    exec(open(command_path).read())
    client.feedkeys('\<Esc>')
    client.feedkeys(':wq! %s\<CR>' % gen_out_file_path)
    # check results
    if filecmp.cmp(exp_out_file_path, gen_out_file_path):
        my_print("SUCCESS", f)
        return True
    else:
        my_print("FAIL", f)
        return False


# execution
def main():
    failing_tests = []
    f = open('test.log', 'w')
    tests = [PurePath(str(p)).name for p in Path('tests').glob('*')]
    if args.list:
        my_print("\n".join(tests), f)
    else:
        if args.test is not None:
            run_one_test(args.test, f)
        else:
            for test in tests:
                if run_one_test(test, f) is not True:
                    failing_tests.append(test)
        if failing_tests == []:
            print_banner("summary: SUCCESS", f)
        else:
            print_banner("summary: FAIL", f)
            my_print("the following tests failed:", f)
            my_print("\n".join(failing_tests), f)
    f.close()
    if failing_tests != []:
        sys.exit(1)


if __name__ == '__main__':
    main()
