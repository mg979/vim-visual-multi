#!/usr/bin/env python3

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


def log(string, f=None):
    """Log to terminal and to file."""
    print(string)
    if f is not None:
        f.write(string + "\n")


def print_banner(string, f=None):
    """Print a banner with the result of the test."""
    log("""
++--------------------------------------------------------------
++ %s
++--------------------------------------------------------------""" % string, f)

def vimrc_info(vimrc, type):
    """Log the description if present inside the vimrc."""
    with open(vimrc) as file:
        v = file.readline()
        if v[:14] == '" DESCRIPTION:':
            return v[15:]
        else:
            return "using " + type + " vimrc"

def get_vimrc(test, f):
    """Check if test-specific vimrc is present, or use default one."""
    try:
        vimrc = Path('tests/', test, 'vimrc.vim').resolve(strict=True)
        output = vimrc_info(vimrc, 'test')
    except FileNotFoundError:
        vimrc, output = VIMRC, INFO
    log(output, f)
    return vimrc

def get_paths(test, f):
    """Create the dictionary with the relevant file paths."""
    paths = {}
    paths["vimrc"] = get_vimrc(test, f)
    paths["command"] = Path('tests/', test, 'commands.py').resolve(strict=True)
    paths["in_file"] = Path('tests/', test, 'input_file.txt').resolve(strict=True)
    paths["exp_out_file"] = Path('tests/', test, 'expected_output_file.txt').resolve(strict=True)
    paths["gen_out_file"] = Path('tests/', test, 'generated_output_file.txt').resolve()
    paths["socket"] = Path('socket_' + test).resolve()
    return paths

def run_core(paths, nvim=False):
    """Start the test."""
    if nvim:
        # client/server connection
        server = multiprocessing.Process(
            target=subprocess.call,
            args=(VIM + " -u " + str(paths["vimrc"]) + ' --listen ' + str(paths["socket"]),),
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
        vim = vimrunner.Server(noplugin=False, vimrc=paths["vimrc"], executable=VIM)
        client = vim.start()
        client.edit(paths["in_file"])
        keys = client.feedkeys
        exec(open(paths["command"]).read())
        client.feedkeys('\<Esc>')
        client.feedkeys(':wq! %s\<CR>' % paths["gen_out_file"])


def run_one_test(test, f=None, nvim=False):
    """Run a single test."""
    log("++ " + test, f)
    log("reproduce: ./test.py " + ("", "-n ")[nvim] + test, f)
    # input/output files
    paths = get_paths(test, f)
    # run test
    run_core(paths, nvim)
    time.sleep(0.5)
    # check results
    if filecmp.cmp(paths["exp_out_file"], paths["gen_out_file"]):
        log("++ SUCCESS\n", f)
        result = True
    else:
        log("++ FAIL\n", f)
        result = False
    # remove generated file when done
    if os.path.exists(paths["gen_out_file"]):
        os.remove(paths["gen_out_file"])
    return result


def main():
    """Main function."""
    # arg parsing
    parser = argparse.ArgumentParser(description='Run test suite. See README.')
    parser.add_argument('test', nargs='?', help='run <test> only instead of running all tests')
    parser.add_argument('-n', '--nvim', action='store_true', help='run in neovim instead of vim')
    parser.add_argument('-l', '--list', action='store_true', help='list all tests')
    parser.add_argument('-v', nargs=1, help='use specific vimrc as default')
    args = parser.parse_args()

    # vim version and default vimrc/info
    global VIM, VIMRC, INFO
    VIM = shutil.which('vim' if not args.nvim else 'nvim')
    VIMRC = Path('default/', 'vimrc.vim' if not args.v else args.v[0] + '.vim').resolve(strict=True)
    INFO = vimrc_info(VIMRC, 'default' if not args.v else args.v[0])

    # execution
    failing_tests = []
    f = open('test.log', 'w')
    tests = [PurePath(str(p)).name for p in Path('tests').glob('*')]
    if args.list:
        log("\n".join(tests), f)
    else:
        if args.test is not None:
            run_one_test(args.test, f, args.nvim)
        else:
            for t in tests:
                if run_one_test(t, f, args.nvim) is not True:
                    failing_tests.append(t)
        if failing_tests == []:
            print_banner("summary: SUCCESS", f)
        else:
            print_banner("summary: FAIL", f)
            log("the following tests failed:", f)
            log("\n".join(failing_tests), f)
    f.close()
    if failing_tests != []:
        sys.exit(1)


if __name__ == '__main__':
    main()
