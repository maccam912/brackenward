#!/usr/bin/env python3
"""Run a pinned native editor suite; fail on errors, hangs or incomplete results."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

import bootstrap

ROOT = Path(__file__).resolve().parents[1]
SUITES = ['unit','integration','colony','survival','persistence','seasons','people','production','care','generation','nature','wildlife','domestic','construction','equipment','maintenance','population','trade','region','fire','defense','director','opportunity','charter','chronicle','scheduler','tutorial','tutorial_flow','ui']


def command(args, binary):
    result = [str(binary), '--path', str(ROOT)]
    if args.headless or args.suite != 'ui': result += ['--headless']
    if os.environ.get('CI') == 'true': result += ['--audio-driver', 'Dummy']
    if args.suite == 'tutorial_flow':
        result += ['--script', 'tools/tutorial_flow.gd', '--', '--site', args.site or 'meadow_reach', '--seed', str(104729 if args.seed is None else args.seed)]
    else:
        result += ['--script', 'tools/run_suite.gd', '--', '--suite', args.suite]
    return result


def passed(output, returncode):
    clean = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', output)
    summaries = re.findall(r'Discovered/run: (\d+); failures: (\d+);', clean)
    return (returncode == 0 and len(summaries) == 1 and int(summaries[0][0]) > 0
            and int(summaries[0][1]) == 0
            and not re.search(r'(?m)^\s*(SCRIPT ERROR:|ERROR:|FATAL ERROR:|FAIL )', clean))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('suite', choices=SUITES)
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--site', choices=['meadow_reach','pine_shelf','reed_bend'])
    parser.add_argument('--seed', type=int)
    parser.add_argument('--timeout', type=int, default=120, help='Bounded suite time in seconds (1..600)')
    args = parser.parse_args(argv)
    if args.suite != 'tutorial_flow' and (args.site is not None or args.seed is not None): parser.error('--site and --seed apply only to tutorial_flow')
    if args.seed is not None and not 0 <= args.seed <= 4294967295: parser.error('--seed must be an unsigned 32-bit integer')
    if not 1 <= args.timeout <= 600: parser.error('--timeout must be 1..600 seconds')
    binary = Path(os.environ.get('BRACKENWARD_GODOT', bootstrap.engine_binary()))
    try:
        bootstrap.verify_engine(binary)
        result = subprocess.run(command(args, binary), cwd=ROOT, text=True, encoding='utf-8', errors='replace', stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=args.timeout)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        print(output.decode('utf-8', 'replace') if isinstance(output, bytes) else output, end='')
        print('Suite timed out; no passing result.', file=sys.stderr)
        return 1
    except (OSError, subprocess.SubprocessError) as error:
        print('Could not run the pinned native suite: '+str(error), file=sys.stderr)
        return 1
    print(result.stdout, end='')
    return 0 if passed(result.stdout, result.returncode) else 1


if __name__ == '__main__': raise SystemExit(main())
