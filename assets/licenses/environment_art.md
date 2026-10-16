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

The 0.7.97 pass replaces generic pile shapes for wood, grain, fiber, cloth and
leather with original logs, tied sheaves, coils, folded cloth and hide silhouettes;
brick piles gain a visible joint. Only these eighteen existing item regions change.
All three quantity tiers, rectangles, atlas dimensions and other art are retained.

The 0.7.105 pass adds original utility construction details for racks, granaries,
barns, cellars, wells, fishing piers and watchposts. Only their twenty-eight
rotation regions change. Shelves and bins represent fixtures, not stored goods.
All source components, atlas rectangles, dimensions and foot anchors are retained.

The 0.7.111 pass appends sixty original baked poor/rich soil borders, covering
fifteen grass-neighbor masks in summer and winter. These use project ground
colors and the existing winter transform. All 300 previous rectangles and pixels
are retained; the atlas now has 360 regions at 1024x436.

The 0.7.114 pass replaces eighteen food-item regions with original bowls, parcels,
fruit baskets, rooted vegetables, tied herbs and meat cuts. All 360 atlas bounds
and every other region remain unchanged. Source drawing code is retained.

The 0.7.116 pass adds original timber fixtures, loom threads/weave, herbal mortar
and leaf bundles, and open pages/quill. Sixteen craft-station regions change,
retaining the inspected hammer/fork components and every atlas rectangle.

The 0.7.119 pass replaces the sapling and stump regions with original open leaf
clusters, visible stems, cut rings and roots. Every atlas rectangle and all other
pixels are preserved; retained source components remain untouched.

The 0.7.120 pass replaces twelve stone, clay, iron-ore and charcoal pile regions
with original facets, folds, mineral inclusions and angular charred pieces. All
360 bounds and unrelated pixels remain identical.

The 0.7.121 pass replaces cloak, vest, milk and medicine regions with original
folds, padding, trim, jugs and bottles. Twelve regions change, preserving all
360 bounds and other pixels. Clothing materials follow the existing recipes.

The 0.7.122 pass appends two original 32x16 two-frame ripple strips. All 360
previous rectangles and pixels remain identical; the atlas now has 362 regions
at the same 1024x436 dimensions. Existing GPU layers select the new variants.
