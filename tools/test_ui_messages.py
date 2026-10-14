import json
import unittest
from ui_messages import parameters, validate_catalog, unique_object


class UIMessageContractTests(unittest.TestCase):
    def test_named_fields_can_reorder_across_plural_forms(self):
        value = {"ui.test.count": {"one": "{name}: {count} tile", "other": "{count} tiles for {name}"}}
        self.assertIs(validate_catalog(value), value)
        self.assertEqual(parameters("{name} / {name} / {count}"), {"name", "count"})

    def test_duplicate_keys_are_rejected_before_json_can_hide_them(self):
        for value in ['{"ui.test.a":"a","ui.test.a":"b"}', '{"ui.test.a":{"one":"a","other":"b","one":"c"}}']:
            with self.assertRaises(ValueError):
                json.loads(value, object_pairs_hook=unique_object)

    def test_plural_branches_are_complete_and_have_matching_fields(self):
        for value in [{"one": "one"}, {"other": "many"}, {"one": "{name}", "other": "{count}"}, {"one": "one", "other": "many", "few": "few"}]:
            with self.assertRaises(ValueError):
                validate_catalog({"ui.test.count": value})

    def test_malformed_fields_and_empty_messages_are_rejected(self):
        for value in ["", "{name", "name}", "{bad-name}", "{}", "{{name}}", 1, None]:
            with self.assertRaises(ValueError):
                parameters(value)

    def test_message_keys_use_the_declared_namespace(self):
        for key in ["ui", "ui..name", "ui.Name.text", "other.action.name", "ui.action.bad-key"]:
            with self.assertRaises(ValueError):
                validate_catalog({key: "Message"})


if __name__ == "__main__":
    unittest.main()
