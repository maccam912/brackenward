# Schema 22 working-colony fixture

Created from exact source `0a4712485e7b443dea847cbfb6f4358513240130`, before the
work-budget/content-v3 implementation. This is an original exported schema-22,
content-v2 envelope, not a new save with its version number changed.

Starting from `ColonyTests.world()` with session `schema22-budget-upgrade`, queue
these public commands and advance 240 ticks:

- Build a bed at (74,63), rotation 0.
- Gather trees at (55,54), (53,54) and (51,54).
- Paint turnips over x=74..77, y=74..77.

The save passes original-code invariants, decode and canonical round trip. It has
23 job records at tick 2040. Its snapshot name is `Schema 22 before work budget`.
The fixture contains no grants, direct needs edits or fabricated job fields.

Original file: 48,103 bytes, SHA-256
`eac9462f2633de6d5f9c805ce755876876dbf262e7032cb57a688830b6414b36`.
Acknowledged canonical payload:
`437b533de5a1e1a4d5b9348d0ee9b9171bc4f60d2a16c1da628c3e3a721e7d33`.

Upgrade tests compare every original gameplay field after removing only declared
empty queue metadata and restoring the original content/schema header. They also
verify exact original bytes and a separate valid reversed-filter-order variant.
