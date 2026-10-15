# Independent generation evidence

## 0.7.45 revision transition

The independent exported-map observer found that Pine Shelf seed 1, generator
revision 1, placed extra stone node 130 at (56,33). Its nearest legal adjacent
work position is 41 steps from the cart footprint. Only 1,400 stone units are
within 40 steps; the promised eight full nodes require 1,600. The original
generator checked final reachability but did not enforce the final distance.
All four cart cells and all adjacent work positions were checked with the
unchanged public A* implementation. Raw old map SHA-256 is
`14592c9fdb960f62a637b0ddc78d0908d9e650cdbd3a34b1f4ec775afbc18a0b`.
The working-tree diagnostic lives in `generation-v45-boundary-pine_shelf.log`
and `generation-pine1-distance-cause.json`; it is not a frozen release sweep.

Revision 2 measures routes from the four actual cart cells, checks each new
guaranteed resource within its 24/40-step limit, and keeps the route clear of
later deposits and trees. Final validation recomputes actual distances. Route
reservations exist only during generation. New colonies use revision 2 and
its dedicated starting streams. Existing maps are loaded, never regenerated;
revision 1 remains explicit in the immutable replay and older geometry cases.
Content remains colony-v6, schema 23, envelope 5, settings 6; catalog SHA-256 is
`eb5fd60496e154184057859aad76683ffdd91acd839cf9335fa48293e3f6a9b5`.

`generation_v1_reference.gd` retains the full old generator. Eighteen complete
world comparisons and three fallback comparisons match revision 1 exactly.
Other new checks cover Pine 1's original failure, unchanged old-save loading,
new snapshot round trip, future-version rejection without mutation, all three
new fallbacks, exact legal route limits and protection against later solids.
The generation suite passes 148 checks. Original replay inputs, acknowledgments,
foreign saves and expected hashes were not rewritten.

Initial revision-2 implementation failures are retained rather than hidden:
one deposits stream initially missed the explicit revision argument; navigation
and room fixtures initially used the new default despite asserting old hashes;
and fallback clay could be blocked by later guaranteed deposits. The final
route protection addresses that clay failure. Those two frozen fixture groups
now explicitly request revision 1 with their original expectations unchanged.
An early independent observer also incorrectly used the maximum future flood
mask as starting weather. It now checks actual starting weather separately from
protected future-flood ground; those observer failures were not product defects.

## Reproducible checks and current boundary

`export_map_batch.gd` streams raw geometry and actual resource quantities.
`validate_raw_map.py` uses independent Python footprint/flood/BFS logic, checks
water/soil/transforms, protected field/home, usable starting structures,
resource amounts and routes, wildlife and the regional graph. It does not call
the generator validator or trust a success flag. Nine synthetic observer tests
and thirteen sweep-contract tests pass; these tests are not generated-map
certificates.

`map_sweep.py` requires its own exact clean frozen source checkout. It records
source/tool/catalog identities, every case's metrics/hash, all raw boundary or
failed maps, completion and a separate audit. The six boundary seeds are fixed;
subsequent seeds derive from SHA-256 of `brackenward-map-sweep-v1|INDEX`.
All 10,000 indices are unique. A subset cannot pass the release gate, and each
site must have fewer than ten fallbacks across the full 10,000-case release run.
CI adds a separate 256-hashed-seed-per-site job, required before APK publication.

The final working-tree boundary diagnostic passes all eighteen revision-2 maps,
with raw maps and metrics in `generation-v2-diagnostic-boundary/`. It is not
yet a frozen sweep or inspected golden certificate. The old campaign balance
evidence remains revision 1; new revision-2 campaigns require their own runs.
The full 30,000-map release sweep and inspected revision-2 golden hashes are
pending at this checkpoint.

All 28 maintained GDScript suites pass 2,622 checks, including 663 graphical UI
checks. The original survival run's three old-map hash mismatches are retained
in `generation-v2-final-survival.log`; the explicit revision-1 rerun passes all
83 in `generation-v2-survival-legacy-fixtures.log`. Other suite logs remain
`generation-v2-final-*`. Three actual tutorial flows pass 22 checks each.
The frozen historical replay passes all 234 checks and 62 commands, keeping
7,200/72,000-tick hashes
`50bb80a8c127473adf03f8882bef3f0ac6b09844c42c14bc0cce3816cf7b920e`
and `b996c5f4e4d953d234b3d967fc931582dbd426fc527e410e6dc92af5bee707d6`.
Native source launch, catalog/media validation and Android debug export pass;
aapt reports 0.7.45-m7 / local code 84. These do not certify physical Android.
