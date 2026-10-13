#!/usr/bin/env python3
"""Fail closed on GDScript parse/runtime errors, hangs, and zero-test suites."""
import argparse, os, re, subprocess, sys
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument('suite', choices=['unit','integration','colony','survival','persistence','seasons','people','production','care','generation','nature','wildlife','domestic','construction','equipment','maintenance','population','trade','region','fire','defense','director','opportunity','charter','chronicle','scheduler','tutorial','tutorial_flow','ui'])
parser.add_argument('--headless', action='store_true')
parser.add_argument('--site', choices=['meadow_reach','pine_shelf','reed_bend'])
parser.add_argument('--seed', type=int)
args = parser.parse_args()
if args.suite != 'tutorial_flow' and (args.site is not None or args.seed is not None):
    parser.error('--site and --seed apply only to tutorial_flow')
if args.seed is not None and not 0 <= args.seed <= 4294967295:
    parser.error('--seed must be an unsigned 32-bit integer')
root = Path(__file__).resolve().parents[1]
command = [str(root/'tools/godot.sh')]
if args.headless or args.suite != 'ui': command += ['--headless']
if os.environ.get('CI') == 'true': command += ['--audio-driver','Dummy']
if args.suite == 'tutorial_flow':
    command += ['--script','tools/tutorial_flow.gd','--','--site',args.site or 'meadow_reach','--seed',str(104729 if args.seed is None else args.seed)]
else:
    command += ['--script','tools/run_suite.gd','--','--suite',args.suite]
try:
    result = subprocess.run(command, cwd=root, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
except subprocess.TimeoutExpired as error:
    print(error.stdout.decode() if isinstance(error.stdout,bytes) else error.stdout)
    sys.exit('Suite timed out; no passing result.')
print(result.stdout, end='')
clean_output = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', result.stdout)
summary = re.search(r'Discovered/run: ([1-9]\d*); failures: 0;',clean_output)
if result.returncode or not summary or re.search(r'(?m)^(SCRIPT ERROR:|ERROR:|FAIL )',clean_output):
    sys.exit(1)
