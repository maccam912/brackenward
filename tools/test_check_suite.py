#!/usr/bin/env python3
"""Native suite invocation and fail-closed output tests; no engine install needed."""
import argparse
import contextlib
import io
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

import check_suite

GOOD = 'Discovered/run: 167; failures: 0; elapsed: 234 ms; engine: 4.7.2\n'


class SuiteChecks(unittest.TestCase):
    def args(self, **changes):
        values = dict(suite='generation', headless=False, site=None, seed=None)
        values.update(changes)
        return argparse.Namespace(**values)

    def test_direct_native_path_handles_spaces_without_a_posix_shell(self):
        binary = r'C:\Users\Test User\Godot_v4.7.2-stable_win64_console.exe'
        with patch.dict('os.environ', {'CI': 'false'}):
            result = check_suite.command(self.args(), binary)
        self.assertEqual(result[:3], [binary, '--path', str(check_suite.ROOT)])
        self.assertNotIn('godot.sh', ' '.join(result))
        self.assertIn('--headless', result)
        self.assertEqual(result[-4:], ['tools/run_suite.gd', '--', '--suite', 'generation'])

    def test_graphical_ui_and_ci_audio_keep_their_options(self):
        with patch.dict('os.environ', {'CI': 'true'}):
            result = check_suite.command(self.args(suite='ui'), '/native/editor')
        self.assertNotIn('--headless', result)
        self.assertIn('--audio-driver', result)
        self.assertIn('Dummy', result)

    def test_tutorial_boundary_seed_zero_is_not_replaced_with_default(self):
        result = check_suite.command(self.args(suite='tutorial_flow', site='reed_bend', seed=0), '/native/editor')
        self.assertEqual(result[-4:], ['--site', 'reed_bend', '--seed', '0'])

    def test_complete_positive_summary_passes(self):
        self.assertTrue(check_suite.passed(GOOD, 0))

    def test_missing_zero_or_multiple_summaries_fail(self):
        for text in ['', GOOD.replace('167', '0'), GOOD+GOOD, GOOD.replace('failures: 0', 'failures: 1')]:
            with self.subTest(text=text): self.assertFalse(check_suite.passed(text, 0))

    def test_nonzero_exit_cannot_be_hidden_by_a_pass_summary(self):
        self.assertFalse(check_suite.passed(GOOD, 1))

    def test_colored_indented_engine_script_and_case_errors_fail(self):
        for error in ['SCRIPT ERROR: fixture', 'ERROR: fixture', 'FATAL ERROR: fixture', 'FAIL fixture']:
            with self.subTest(error=error): self.assertFalse(check_suite.passed(GOOD+'  \x1b[31m'+error+'\x1b[0m\n', 0))

    def invoke(self, arguments, result=None, error=None):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()), patch('check_suite.bootstrap.verify_engine') as verify, patch('check_suite.subprocess.run', return_value=result, side_effect=error) as run, patch.dict('os.environ', {'BRACKENWARD_GODOT': '/test/native/editor'}):
            code = check_suite.main(arguments)
        return code, verify, run

    def test_explicit_timeout_uses_one_direct_child_and_verifies_engine(self):
        code, verify, run = self.invoke(['generation', '--timeout', '600'], subprocess.CompletedProcess([], 0, GOOD))
        self.assertEqual(code, 0)
        verify.assert_called_once_with(Path('/test/native/editor'))
        self.assertEqual(run.call_args.kwargs['timeout'], 600)
        self.assertEqual(run.call_args.args[0][0], str(Path('/test/native/editor')))
        self.assertEqual(run.call_args.kwargs['encoding'], 'utf-8')

    def test_timeout_and_missing_executable_fail_without_a_result(self):
        for error in [subprocess.TimeoutExpired(['editor'], 120, output=b'partial\xff'), FileNotFoundError('editor')]:
            with self.subTest(error=type(error).__name__): self.assertEqual(self.invoke(['generation'], error=error)[0], 1)

    def test_invalid_suite_constraints_never_start_the_editor(self):
        for arguments in [['unit', '--seed', '1'], ['tutorial_flow', '--seed', '-1'], ['generation', '--timeout', '0'], ['generation', '--timeout', '601']]:
            with self.subTest(arguments=arguments), contextlib.redirect_stderr(io.StringIO()), patch('check_suite.bootstrap.verify_engine') as verify:
                with self.assertRaises(SystemExit) as error: check_suite.main(arguments)
                self.assertEqual(error.exception.code, 2)
                verify.assert_not_called()

    def test_redirected_cp1252_output_preserves_unicode_without_hiding_errors(self):
        for code, suffix in [(0, 'WARNING: Unicode \ufffd ☀\n'), (1, 'SCRIPT ERROR: Unicode \ufffd ☀\n')]:
            with self.subTest(code=code):
                data = io.BytesIO()
                errors = io.BytesIO()
                output = io.TextIOWrapper(data, encoding='cp1252')
                diagnostic = io.TextIOWrapper(errors, encoding='cp1252')
                result = subprocess.CompletedProcess([], 0, GOOD + suffix)
                with patch('check_suite.sys.stdout', output), patch('check_suite.sys.stderr', diagnostic), patch('check_suite.bootstrap.verify_engine'), patch('check_suite.subprocess.run', return_value=result), patch.dict('os.environ', {'BRACKENWARD_GODOT': '/test/editor'}):
                    self.assertEqual(check_suite.main(['persistence']), code)
                output.flush()
                diagnostic.flush()
                self.assertEqual(data.getvalue().decode('utf-8'), GOOD + suffix)
                self.assertEqual(output.encoding, 'utf-8')
                self.assertEqual(diagnostic.encoding, 'utf-8')


if __name__ == '__main__': unittest.main()
