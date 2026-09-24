# Prontera field art rebuild — 2026-09-23

Reference: user's `ChatGPT Image 26 ส.ค. 2569 19_43_24.png`.

Replaced the 724px-high repeated foreground enlarged 1.65x with four different native 1536x1024 painted forest sections. Alpha-normalized and joined with minimum-error seams into 5760x1024; shipped as three 1920x1024 chunks. Uniform world scale 8/7 avoids the previous nonuniform road stretching. PRONTERA noticeboard, banner, roots, rocks and shrubs belong to the same grounded artwork. No separate decorative obstacles in the walking lane.

Replaced the far mountain/village image with an ivory city and green valley matching the reference. Map-specific parallax covers the viewport plus camera travel without mirrored city repetition. Only the distant layer receives a symmetric pixel-based nine-tap DoF blur. Terrain and actors remain sharp. The shader assigns the filtered texture directly, avoiding accidental multiplication by the already textured fragment COLOR.

Floor remains y=504; map horizontal bounds, monster roster, spawner, portal destinations and quest behavior are preserved. Camera height is 1160, fitting the new artwork without an exposed bottom edge. Removed irrelevant skew/scale on the default spawn marker.

Sunlight follow-up: seven world-anchored, soft additive shafts descend diagonally from canopy openings. Narrow ribbons sway and brighten slowly; the lower ends fade before the walking surface. Rendered behind actors, with no full-screen blur or additional image textures. Shader: `prontera_sunshafts.gdshader`; placement is local to this map script.

Reproduction: `output/prontera_rebuild/compose.py`; pre-edit scene backup in the same folder. Runtime test: `prontera_field_review.tscn` (SaveManager inactive, in-memory new character). Captures five positions and a wider window; checks floor ray hits and actual rightward movement with grounded player. Runtime images/logs in `output/prontera_rebuild/`. Environment warnings about shader cache/root certificates/editor settings are unrelated to map rendering.
