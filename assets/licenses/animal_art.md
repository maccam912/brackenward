# Original woodland animal animation

`tools/author_animals.py` is the editable original source for the shared woodland
atlas, its animation layout and contact sheet. Rebuild with Python 3 and Pillow.
These are original project assets, with no blanket CC0 license and no borrowed
animal sprites. The colors match the project woodland palette and adult figures.

Hare, deer, boar, marsh goose, hen, pack goat and merchant pack goat each have four
facings, two idle frames, four walking frames, two eating frames and one downed
frame. Boar adds four charge frames per facing. Side poses mirror. All frames use
a 24x24 source canvas with a bottom-center anchor and remain cosmetic: logical
collision, health, feeding, attacks and work come from the simulation grid/state.
Goats share their body/horn artwork; merchant packs are a cosmetic overlay with no
independent inventory, capacity or collision. Juvenile scale changes no world rule.

The 0.7.96 pass adds subtle original translucent contact shadows inside the
existing 24x24 pose bounds. All previous opaque pixels, species/pose regions and
foot anchors remain intact, with no extra runtime node or texture.
