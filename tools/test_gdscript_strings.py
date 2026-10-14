import unittest
from gdscript_strings import extract_strings


class StringInventoryTests(unittest.TestCase):
    def test_quotes_in_comments_are_excluded(self):
        self.assertEqual(list(extract_strings('# worker\'s "quoted" comment\nvar text = "Actual" # \'ignored\'')), ["Actual"])

    def test_both_quote_styles_and_unicode_escapes(self):
        self.assertEqual(list(extract_strings(r'''var a = "Caf\u00e9"; var b = '18:00\u201320:00' ''')), ["Café", "18:00–20:00"])

    def test_hash_and_escaped_quotes_inside_text_are_kept(self):
        self.assertEqual(list(extract_strings(r'''var text = "#1 \"quoted\""''')), ['#1 "quoted"'])

    def test_multiline_string_contains_its_hash(self):
        self.assertEqual(list(extract_strings('var text = """First\n# still text\nLast"""')), ["First\n# still text\nLast"])

    def test_gdscript_ordinary_multiline_string(self):
        self.assertEqual(list(extract_strings('var text = "%s · %s\nSecond"')), ["%s · %s\nSecond"])

    def test_raw_pattern_keeps_escapes(self):
        self.assertEqual(list(extract_strings(r'''var text = r"\u4e00\n"''')), [r"\u4e00\n"])

    def test_unterminated_input_fails_closed(self):
        with self.assertRaises(ValueError):
            list(extract_strings('var text = "Missing end'))


if __name__ == "__main__":
    unittest.main()
