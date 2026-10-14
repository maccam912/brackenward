"""Read quoted GDScript text without treating comments as localization strings."""
import ast


def extract_strings(source):
    index = 0
    while index < len(source):
        if source[index] == "#":
            newline = source.find("\n", index)
            index = len(source) if newline < 0 else newline + 1
            continue
        if source[index] not in "\"'":
            index += 1
            continue
        quote = source[index]
        if source.startswith(quote * 3, index):
            quote *= 3
        start = index
        if index and source[index - 1] in "rR" and (index < 2 or not (source[index - 2].isalnum() or source[index - 2] == "_")):
            start -= 1
        index += len(quote)
        while index < len(source):
            if source[index] == "\\":
                index += 2
            elif source.startswith(quote, index):
                index += len(quote)
                token = source[start:index]
                # GDScript permits physical newlines in ordinary quoted text.
                if len(quote) == 1:
                    token = token.replace("\r", "\\r").replace("\n", "\\n")
                value = ast.literal_eval(token)
                if not isinstance(value, str):
                    raise ValueError("Expected a text literal")
                yield value
                break
            else:
                index += 1
        else:
            raise ValueError("Unterminated GDScript text literal")
