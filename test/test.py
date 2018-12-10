#!/bin/env python3

import argparse
from pathlib import Path, PurePath
import os
import sys
import shutil
import filecmp
import vimrunner
import time
import multiprocessing
import subprocess
from pynvim import attach


def my_print(string, f=None):
    print(string)
    if f is not None:
        f.write(string + "\n")


def print_banner(string, f=None):
    my_print("""
++--------------------------------------------------------------
++ %s
++--------------------------------------------------------------""" % string, f)


def run_core(paths, nvim=False):
    if nvim:
        # client/server connection
        server = multiprocessing.Process(
            target=subprocess.call,
            args=(shutil.which('nvim') + " -u " + str(paths["vimrc"]) + ' --listen ' + str(paths["socket"]),),
            kwargs={'shell': True}
        )
        server.start()
        time.sleep(1)
        client = attach('socket', path=str(paths["socket"]))
        # run test
        client.command('e %s' % paths["in_file"])
        keys = client.input
        for line in open(paths["command"]):
            exec(line)
            time.sleep(0.5)
        client.command(':w! %s' % paths["gen_out_file"])
        client.quit()
    else:
        vim = vimrunner.Server(noplugin=False, vimrc=paths["vimrc"], executable=shutil.which('vim'))
        client = vim.start()
        client.edit(paths["in_file"])
        keys = client.feedkeys
        exec(open(paths["command"]).read())
        client.feedkeys('\<Esc>')
        client.feedkeys(':wq! %s\<CR>' % paths["gen_out_file"])


def run_one_test(test, f=None, nvim=False):
    my_print("++ " + test, f)
    my_print("reproduce: ./test.py " + ("", "-n ")[nvim] + test, f)
    # input/output files
    paths = dict()
    try:
        paths["vimrc"] = Path('tests/', test, 'vimrc.vim').resolve(strict=True)
    except FileNotFoundError:
        paths["vimrc"] = Path('default/', 'vimrc.vim').resolve(strict=True)
        my_print("using default vimrc", f)
    paths["command"] = Path('tests/', test, 'commands.py').resolve(strict=True)
    paths["in_file"] = Path('tests/', test, 'input_file.txt').resolve(strict=True)
    paths["exp_out_file"] = Path('tests/', test, 'expected_output_file.txt').resolve(strict=True)
    paths["gen_out_file"] = Path('tests/', test, 'generated_output_file.txt').resolve()
    paths["socket"] = Path('socket_' + test).resolve()
    if os.path.exists(paths["gen_out_file"]):
        os.remove(paths["gen_out_file"])
    # run test
    run_core(paths, nvim)
    # check results
    if filecmp.cmp(paths["exp_out_file"], paths["gen_out_file"]):
        my_print("++ SUCCESS\n", f)
        return True
    else:
        my_print("++ FAIL\n", f)
        return False


def main():
    # arg parsing
    parser = argparse.ArgumentParser(description='Run test suite. See README.')
    parser.add_argument('test', nargs='?', help='run <test> only instead of running all tests')
    parser.add_argument('-n', '--nvim', action='store_true', help='run in neovim instead of vim')
    parser.add_argument('-l', '--list', action='store_true', help='list all tests')
    args = parser.parse_args()
    # execution
    failing_tests = []
    f = open('test.log', 'w')
    tests = [PurePath(str(p)).name for p in Path('tests').glob('*')]
    if args.list:
        my_print("\n".join(tests), f)
    else:
        if args.test is not None:
            run_one_test(args.test, f, args.nvim)
        else:
            for test in tests:
                if run_one_test(test, f, args.nvim) is not True:
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
