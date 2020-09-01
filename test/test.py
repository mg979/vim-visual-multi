#!/usr/bin/env python3

import argparse
from pathlib import Path, PurePath
import os
import sys
import json
import shutil
import filecmp
import vimrunner
import time
import multiprocessing
import subprocess
from pynvim import attach


# -------------------------------------------------------------
# global varialbes
# -------------------------------------------------------------

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


SUCCESS_STR = "{}SUCCESS{}".format(bcolors.OKGREEN, bcolors.ENDC)
FAIL_STR = "{}FAIL{}".format(bcolors.FAIL, bcolors.ENDC)
CLIENT = None


# -------------------------------------------------------------
# functions
# -------------------------------------------------------------
def log(string, f=None):
    """Log to terminal and to file."""
    print(string)
    if f is not None:
        f.write(string + "\n")


def print_banner(string, f=None):
    """Print a banner with the result of the test."""
    log("\n╒═" + 77*"═" + "\n│ %s" % string + "\n╘═" + 77*"═" + "\n", f)


def get_vimrc(test, f):
    """Check if test-specific vimrc is present, or use default one."""
    try:
        return Path('tests/', test, 'vimrc.vim').resolve(strict=True)
    except FileNotFoundError:
        return DEFAULT_VIMRC


def get_test_description(test):
    """Get test description if present."""
    commands = Path('tests/', test, 'commands.py').resolve(strict=True)
    with open(commands) as file:
        desc = file.readline()
    if desc[0] == '#':
        return (desc[2:-1])
    else:
        return ('')


def get_test_info(test, nvim, vimrc):
    """Generate line for test logging."""
    desc = get_test_description(test)
    return test.ljust(20) + desc.ljust(40)


def print_tests_list(tests, f):
    """Print the list of available tests, with their descriptions."""
    log("\n" + '-' * 60)
    for t in tests:
        desc = get_test_description(t)
        log(t.ljust(20) + "\t" + desc)
    log('-' * 60)


def get_paths(test, f):
    """Create the dictionary with the relevant file paths."""
    paths = {}
    paths["vimrc"] = get_vimrc(test, f)
    paths["command"] = Path('tests/', test, 'commands.py').resolve(strict=True)
    paths["in_file"] = Path('tests/', test, 'input_file.txt').resolve(strict=True)
    paths["config"] = Path('tests/', test, 'config.json').resolve()
    paths["exp_out_file"] = Path('tests/', test, 'expected_output_file.txt').resolve(strict=True)
    paths["gen_out_file"] = Path('tests/', test, 'generated_output_file.txt').resolve()
    paths["socket"] = Path('socket_' + test).resolve()
    return paths


def keys_nvim(key_str):
    """nvim implementation of keys()"""
    key_str = key_str.replace(r'\<', '<')
    key_str = key_str.replace(r'\"', r'"')
    key_str = key_str.replace('\\\\', '\\')
    CLIENT.input(key_str)
    time.sleep(KEY_PRESS_INTERVAL)


def keys_vim(key_str):
    """vim implementation of keys()"""
    CLIENT.feedkeys(key_str)
    time.sleep(KEY_PRESS_INTERVAL)


def run_core(paths, nvim=False):
    """Start the test and return commands_cpu_time."""
    global CLIENT
    if nvim:
        # client/server connection
        server = multiprocessing.Process(
            target=subprocess.call,
            args=(VIM + " -u " + str(paths["vimrc"]) + ' --listen ' + str(paths["socket"]),),
            kwargs={'shell': True}
        )
        server.start()
        time.sleep(1)
        CLIENT = attach('socket', path=str(paths["socket"]))
        # run test
        CLIENT.command('e %s' % paths["in_file"])
        keys = keys_nvim
        start_time = time.process_time()
        commands = open(paths["command"]).read()
        if not LIVE_EDITING:
            commands = r'keys(r":let g:VM_live_editing = 0\<CR>")\n' + commands
        exec(commands)
        end_time = time.process_time()
        CLIENT.command(':w! %s' % paths["gen_out_file"])
        CLIENT.quit()
    else:
        vim = vimrunner.Server(noplugin=False, vimrc=paths["vimrc"], executable=VIM)
        CLIENT = vim.start()
        CLIENT.edit(paths["in_file"])
        keys = keys_vim
        start_time = time.process_time()
        exec(open(paths["command"]).read())
        end_time = time.process_time()
        CLIENT.feedkeys(r'\<Esc>')
        CLIENT.feedkeys(r':wq! %s\<CR>' % paths["gen_out_file"])
    return end_time - start_time


def run_one_test(test, f=None, nvim=False):
    """Run a single test."""
    # input/output files
    paths = get_paths(test, f)
    info = get_test_info(test, nvim, paths['vimrc'])
    config = {}
    if os.path.exists(paths["config"]):
        config = json.load(open(paths["config"]))
    # remove previously generated file
    if os.path.exists(paths["gen_out_file"]):
        os.remove(paths["gen_out_file"])
    # run test
    time.sleep(.5)
    commands_cpu_time = run_core(paths, nvim)
    time.sleep(.5)
    # check results
    time_str = "(took {:.3f} sec)".format(commands_cpu_time)
    if filecmp.cmp(paths["exp_out_file"], paths["gen_out_file"]):
        if "max_cpu_time" in config and config["max_cpu_time"] < commands_cpu_time:
            log("{} {} {}[slow]{} {}".format(info, FAIL_STR,
                                             bcolors.WARNING, bcolors.ENDC, time_str), f)
            return False
        log("{} {} {}".format(info, SUCCESS_STR, time_str), f)
        return True
    else:
        log("{} {} {}[mismatch]{} {}".format(info, FAIL_STR,
                                             bcolors.WARNING, bcolors.ENDC, time_str), f)
        return False


def main():
    """Main function."""
    # arg parsing
    parser = argparse.ArgumentParser(description='Run test suite. See README.')
    parser.add_argument('test', nargs='?', help='run <test> only instead of running all tests')
    parser.add_argument('-t', '--time', nargs=1, type=float, default=[0.1], help='set key delay in seconds (default 0.1)')
    parser.add_argument('-n', '--nvim', action='store_true', help='run in neovim instead of vim')
    parser.add_argument('-l', '--list', action='store_true', help='list all tests')
    parser.add_argument('-L', '--nolive', action='store_false', help='disable live editing')
    parser.add_argument('-d', '--diff', action='store_true', help='diff falied tests')
    args = parser.parse_args()

    # vim version and default vimrc
    global VIM, DEFAULT_VIMRC, KEY_PRESS_INTERVAL, LIVE_EDITING, DIFF_FAILED
    VIM = shutil.which('vim' if not args.nvim else 'nvim')
    DEFAULT_VIMRC = Path('default/', 'vimrc.vim').resolve(strict=True)
    KEY_PRESS_INTERVAL = args.time[0]
    LIVE_EDITING = args.nolive
    DIFF_FAILED = args.diff

    # execution
    failing_tests = []
    f = open('test.log', 'w')
    tests = sorted([PurePath(str(p)).name for p in Path('tests').glob('*')])
    if args.list:
        print_tests_list(tests, f)
    else:
        print_banner("Starting vim-visual-multi tests", f)
        tests = tests if args.test is None else [args.test]
        for t in tests:
            if run_one_test(t, f, args.nvim) is not True:
                failing_tests.append(t)
        if failing_tests == []:
            print_banner("summary: " + SUCCESS_STR, f)
        else:
            print_banner("summary: " + FAIL_STR, f)
            log("the following tests failed:", f)
            log("\n".join(failing_tests), f)
            if DIFF_FAILED:
                for t in failing_tests:
                    print_banner(t)
                    exp = 'tests/' + t + '/expected_output_file.txt'
                    gen = 'tests/' + t + '/generated_output_file.txt'
                    subprocess.run('diff --color=always ' + exp + ' ' + gen, shell=True)
    f.close()
    if failing_tests != []:
        sys.exit(1)


# -------------------------------------------------------------
# execution
# -------------------------------------------------------------
if __name__ == '__main__':
    main()
