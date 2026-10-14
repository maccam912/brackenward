# Original adult citizen art

`tools/author_citizens.py` is the editable source for `adults.png`, `portraits.png`,
the animation layout and the inspected contact sheet. These are original project
assets, with no blanket CC0 license. No downloaded character artwork is included.
Rebuild with Python 3 and Pillow (`python3 tools/author_citizens.py`).

The eight clothing silhouettes and eight independent hair shapes each have 99
poses: idle 8, walk 16, carry 16, work 12, plant 12, eat 2, talk 2, sleep 2,
melee 12, shoot 12, hurt 1, downed 1 and cheer 3. Columns 11, rows 9 form one
body/hair block; body selects the block column and hair selects the block row.
Side poses mirror because handedness is cosmetic. Portraits use the same mask,
clothing seams and hair, at 64 by 64. All characters represent adults.

The eight opaque RGB cube corners encode ink, coat, hair, linen, skin, trousers,
scarf and trim. `citizen_palette.gdshader` supplies independent colors without
allocating a separate atlas for each combination. Transparency is preserved.
Tools and job hats are drawn separately from the actual current task/equipment.
Animation never determines work completion, movement, collision or damage.

The eight 64-pixel trait SVGs are also original vector artwork in the same
source file: heart (Kind), house (Homebody), anchor (Steady), people (Sociable),
leaf (Outdoorsy), turning arrows (Restless), magnifier (Curious), and a closed
book (Private). Each appears alongside its text label. The original M0 SVG
travelers remain for frozen prototype tests, rather than serving colony play.

The palette shader preserves the vertex tint separately because fragment
`COLOR` already includes the indexed texture. See the official
[CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html#color-and-texture).
