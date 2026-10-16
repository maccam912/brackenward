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

The 0.7.85 terrain pass remaps grass tuft colors to quieter intermediate greens,
reduces poor/rich soil contrast and bakes original translucent contact shadows
inside natural-resource sprite bounds. Source component bytes stay unchanged.
River-bank geometry is original presentation code in `ColonyEnvironment`; it
follows existing water boundaries and adds no media dependencies.

The 0.7.87 pass replaces the narrow evergreen composition with original tiered
branches and shades the retained round-canopy silhouette with original leaf
clusters. The approved conifer source tiles remain retained for provenance.
The stone hearth ring and folded/striped blankets are original project drawing
code. Atlas layout, source dimensions and foot anchors remain unchanged.

The 0.7.93 pass adds original open-cart timber, wheels and bundled canvas; distinct
masonry kiln/smelter/forge bodies; a slatted bench; and separate bell, memorial
and beacon silhouettes. Ground contact shadows stay inside existing sprite bounds.
The beacon basket is static brass-colored metal, not an additional fire effect.
All source components, 284 regions, dimensions and gameplay anchors are retained.

The 0.7.94 pass adds four original seasonal broadleaf views (gold/copper autumn
crowns and forked bare winter branches), plus nine dormant-grass variants. Autumn
retains the approved crown silhouette and changes its original project shading.
Winter branches are entirely original drawing code. The resulting atlas has 297
regions at 1024x418; all earlier rectangle positions/dimensions remain intact.
