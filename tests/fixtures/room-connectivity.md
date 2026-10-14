# Frozen room geometry

`room-connectivity-golden.json` was recorded from commit `7089f14` before
replacing the original Vector2i/Dictionary flood fill with packed cells.
Each digest includes every roofed tile, its room ID and dictionary insertion
order. These are geometry fixtures, separate from ordinary-play certificates.

Forty cases cover authored geography and all three generated sites (seed
104729), empty space, enclosed rooms, exactly 64 and 65 interior tiles,
door-separated rooms, removed boundaries, map edges, water, bridges and
overlapping built-in roofs. Tests use unchanged definitions and create the
same fixture records; they do not regenerate the expected values. Native
replay and campaign continuation additionally check authoritative outcomes.

Run `python3 tools/check_suite.py survival`. For uncached CPU timing on a
preserved snapshot, use `tools/godot.sh --headless --script
tools/profile_rooms.gd -- SNAPSHOT ITERATIONS` (1–100 iterations). The profiler
also checks stable ordered geometry and an unchanged authoritative hash.
