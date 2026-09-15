# HUD icon and interaction cleanup — 2026-09-15

**Visual direction superseded:** the user rejected the gold/blue vectors. Current runtime icons use the ivory reference-matched Imagegen atlas and the user-supplied crossed swords in `Sprites/ui/ivory/`. See `docs/ivory_ui_revision_2026-09-15.md`. Functional changes below remain.

- Replaced six menu SVGs with a matching gold/blue set. SVG sources are 256 px at import scale 1, sufficient for 42 px menu display without excessive texture memory.
- Attack button now uses the new high-resolution attack SVG instead of the old swords bitmap. Skill-bank switch uses a circular-arrow rune icon, tinted by active bank; its tooltip explains switching.
- Removed the down touch zone. Talk label is now คุย, diameter reduced from 84 to 56 logical pixels. Ground auto-pickup and keyboard movement remain unchanged.
- Removed the floating minimap instance and its HUD dependencies. The existing M action now opens the full WorldMapPage; the top-right map icon already opens that page. Removed the old MapPage minimap toggle. The shared Minimap drawing class remains for the legacy embedded MapPage, but no floating minimap runs in the HUD.
- Map title 17→24 px; region/chapter 11→19 px, with brighter text.
- LoreObject, StoryPoint and RunebladePoint labels use 26 px type, a dark gold-bordered backing, and a ◆ จุดสำรวจ marker. Parent scaling is compensated when building the label. Empty hidden story labels stay hidden. Story triggers and quest requirements were not changed.
- Native SVG authoring was used for the existing vector icon system; no raster image generation was needed.

Validation: mobile_ui_test.tscn checks legacy save/skill banks, touch bounds and non-overlapping hit regions, no down button/floating minimap, and legacy M input opening the world map. OpenGL previews are in output/mobile_ui/. Test saves are isolated under output/mobile_ui/isolated_saves and autosave is disabled. The Steam Godot environment reports shader-cache/certificate access warnings separately from functional test assertions.

Local changes only; not deployed to GitHub Pages. Visual checks are desktop-rendered touch/desktop layouts, not an on-device Samsung test.
