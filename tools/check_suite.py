#!/usr/bin/env python3
"""Fail closed on GDScript parse/runtime errors, hangs, and zero-test suites."""
import argparse, os, re, subprocess, sys
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument('suite', choices=['unit','integration','colony','survival','persistence','seasons','people','production','care','generation','nature','wildlife','domestic','ui'])
parser.add_argument('--headless', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
command = [str(root/'tools/godot.sh')]
if args.headless or args.suite != 'ui': command += ['--headless']
if os.environ.get('CI') == 'true': command += ['--audio-driver','Dummy']
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
