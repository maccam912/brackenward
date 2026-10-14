# Woodland environment artwork and retained components

`tools/author_environment.py` is the editable source for the original missing
structures, crops, deposits and supplies, composed with inspected Tiny Town 1.1
components. `tools/import_tiny_town.py` retains only nineteen reviewed source tiles
and their exact bytes. `data/environment_sources.json` records every original
filename, packed-atlas rectangle, SHA-256, author and license evidence. The original
Kenney license is copied byte-for-byte to `kenney_tiny_town.txt`; its digest is
`c483c167cc3bdfe17c15f957ff847d409f64d81b410b28783636cf3b2b7814c5`.

Kenney's underlying components remain CC0. The new original artwork and composition
are original project assets; no blanket copied CC0 license is applied to the
project. The export manifest credits both authors, declares editing and links this
evidence. Source components are excluded from game exports. The game uses only the
shared exported atlas and semantic rectangles in `data/environment_art.json`.

Rebuild with Python 3 and Pillow after importing the reviewed components. Ground
variants, crop stages, item-pile heights and four building rotations are visual
only. Grid footprints, fertility, quantities, growth, collision and roof status
still come exclusively from the catalog and saved simulation. The single barn
roof layer is separate so inspection can reveal its interior without changing
room, warmth or storage rules.

`warm_glow.png` is an original 64x64 additive radial gradient authored by the same
script. It is a bounded presentation effect over actual heat sources and adds no
light, fuel, collision or simulation rules.
