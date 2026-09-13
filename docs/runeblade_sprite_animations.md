# Runeblade sprites — SpriteFlow September 12–13, 2026

Open `scenes/player/runeblade.tscn` to inspect the dedicated player scene and its AnimatedSprite2D / SpriteFrames. Open `runeblade_sprite_gallery.tscn` and press F6 for playback, frame stepping, speed and facing controls. `Source_*` animations retain complete source sequences for reviewing later replacement art.

Runtime resource: `data/sprites/runeblade_frames.tres`. Original PNGs: `Sprites/player/runeblade/<source>/frame_01.png` etc. Source images are copied without pixel edits; baked skill swords remain. The artist subsequently removed the basic-combo swords; these poses now show the equipped weapon. Equipment overlays are hidden for the remaining baked sword skill poses. Existing class assets are retained.

| SpriteFlow time (Bangkok) | Source folder | Use |
|---|---|---|
| Sep 12 16:26:29 | rb_idle_1626 | All 32 breathing frames, twice per idle cycle |
| Sep 12 16:33 | runeblade_idle | All 32 sigh frames, after breathing |
| Sep 12 20:17:59 | rb_walk_2017 | Walk, source frames 5–24 |
| Sep 12 20:18:40 | rb_run_2018 | Run, source frames 5–32 |
| Sep 13 08:11:15 | rb_dash_0811 | Dash 5–27; airborne fallback 14–20 |
| Sep 12 20:55:59 | rb_hitdie_2055 | Hit 3–11; Death 12–32, non-looping |
| Sep 12 21:02:14 | rb_basic_2102 | Basic combo: 1–7, 8–14, 15–27 |
| Sep 12 21:08:37 | rb_skill_2108 | Anvil Cleave; Rending Wave casting pose |
| Sep 12 20:55:26 | rb_skill_2055 | Faultline casting pose |
| Sep 12 20:44:53 | rb_skill_2044 | Rune Lunge, Erasing Cut, three Flurry segments |
| Sep 12 20:20:11 | rb_skill_2020 | Worldcleaver casting pose |

Basic attacks retain the existing three-step combat system; authored contact frames are 4 / 11 / 18 in the original 21:02 source. Skills keep their saved IDs, costs, hit counts and damage formulas. Rune Flurry selects the three attack segments twice across its six existing strike events. Heavy skill frame weights align visual contact with existing cast windups. Buff skills retain their existing effects.

Idle is a 96-frame, 12-second sequence at 8 FPS. A Godot canvas shader blends adjacent originals in premultiplied alpha space, aligning the two source registrations when crossing between breathing and sigh. This changes rendering, not the source artwork. Body scale is fixed per source sequence; authored root-height corrections keep perspective steps and the prone landing grounded without measuring silhouette bounds each frame. A long sword does not change character size. Slow grounded movement below 75% of normal movement speed selects Walk; full movement selects Run.

`_tools/import_runeblade_full.py` rebuilds the resource from staged source PNGs in `output/spriteflow/downloads`. It records hashes and animation mappings in `output/runeblade_full/manifest.json`. Run `runeblade_sprite_test.tscn` for focused routing, registration, equipment and three-step combo checks, plus rendered motion captures. The test initializes game state only in memory and never saves a slot.

## Validation

Godot 4.7.2 / GL Compatibility: 338 focused sprite, combo, registration and gallery checks passed; 20 actual skill-cast and visual timing checks passed. All 352 runtime PNGs match their staged originals byte-for-byte. See `output/runeblade_full/validation.json`, rendered previews and `idle_preview.webp`. The environment logs shader-cache/root-certificate warnings, but the focused checks complete without sprite or script failures.

## Equipped weapon revision — September 13

The four artist-edited skill sources (`rb_skill_2020`, `rb_skill_2044`, `rb_skill_2055`, `rb_skill_2108`) now use equipped swords across all 128 source frames. Source-pixel hand sockets and blade angles follow each texture through the existing skill routes; fingers render over the grip. The baked-weapon list is empty, including in the importer. `_tools/calibrate_runeblade_skill_weapons.py` regenerates these sockets using current hand pixels and staged sword references without writing image assets. The overhead hold in 2108 includes an explicit angle correction for its foreshortened reference.

Skill attachment validation: 28,704 weapon checks passed across 18 swords and both facings, plus 20 actual skill-cast/timing checks. All 128 edited skill PNG hashes match `output/runeblade_skill_weapons/original_hashes.json`. Rendered skill previews are in `output/runeblade_weapon/skill_*.png`; the overview is `output/runeblade_skill_weapons/rendered.jpg`.

- The artist-edited `rb_basic_2102` PNGs remain unchanged. All three combo steps use equipped swords with source-specific grip positions, rotation and finger occlusion.
- Breathing and sigh use separate measurements from their current PNGs in `data/sprites/runeblade_weapon_tracks.json`. Socket interpolation uses the same smoothstep and cross-source registration transform as the body shader. The old sigh track is no longer reused for breathing.
- Run carries the equipped sword behind the torso, with the hilt above the rear shoulder and blade toward the opposite hip. Both facing directions use the same mirrored attachment. No negative map depth is needed.
- World weapon scale remains constant between idle, combo, and back carry. The previous 1.3 back-carry multiplier was removed to reduce the running sword by approximately 23% at the user's request.
- The sprite gallery has a weapon selector, including no weapon and all supported swords. It does not change inventory or saved equipment.
- The importer now copies only absent PNGs, preserving later artist edits instead of replacing them from old staged downloads.

`runeblade_weapon_review.tscn` passed 10,956 focused checks across 18 equipped swords, all relevant frames and both directions, including source-splice position/scale continuity. Rendered idle motion and comparisons are under `output/runeblade_weapon/`. All 128 inspected current body PNGs retain their pre-change hashes. The earlier 352-file import hash statement describes the initial import, before the artist's sword-removal edits.
