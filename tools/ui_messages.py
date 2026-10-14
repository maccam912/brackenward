"""Validate English UI keys, plural branches and named format parameters."""
import json
import re

TOKEN = re.compile(r"\{([a-z][a-z0-9_]*)\}")
KEY = re.compile(r"ui\.[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+")


def parameters(text):
    if not isinstance(text, str) or not text:
        raise ValueError("A UI message must be nonempty text")
    stripped = TOKEN.sub("", text)
    if "{" in stripped or "}" in stripped:
        raise ValueError("Malformed UI message parameter")
    return set(TOKEN.findall(text))


def validate_catalog(catalog):
    if not isinstance(catalog, dict) or not catalog:
        raise ValueError("A UI catalog must be a nonempty object")
    for key, entry in catalog.items():
        if not KEY.fullmatch(key):
            raise ValueError(f"Invalid UI key: {key}")
        if isinstance(entry, str):
            parameters(entry)
        elif isinstance(entry, dict) and set(entry) == {"one", "other"}:
            if parameters(entry["one"]) != parameters(entry["other"]):
                raise ValueError(f"Plural parameters differ: {key}")
        else:
            raise ValueError(f"Invalid message/plural forms: {key}")
    return catalog


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate UI key: {key}")
        result[key] = value
    return result


def load_catalog(path):
    return validate_catalog(json.loads(path.read_text(), object_pairs_hook=unique_object))
