"""Keep captured native logs printable when Windows redirects a legacy console."""
import sys


def configure_output():
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="backslashreplace", newline="\n")
