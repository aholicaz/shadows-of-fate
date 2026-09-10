# Chapter 2 map artwork — Shadows of Fate

Finished backgrounds are installed in the existing map scenes:

| Map | Runtime texture | Dimensions | Art origin | Collision floor |
| --- | --- | --- | --- | --- |
| Ember Mine | `Sprites/map/generated/ember_mine_bg_final.png` | 5200 × 1400 | (-100, -200) | world Y=900 / image Y=1100 |
| Hall of Silence | `Sprites/map/generated/hall_of_silence_bg_final.png` | 4800 × 1400 | (-100, -200) | world Y=900 / image Y=1100 |

## Art direction and sources

- [Game story supplied by the user](https://docs.google.com/document/d/1BBeC8v8oM_42ooAELRWQgy9YcO_fDk97ooeszOxrMv0/edit): Chapter 2, Svartalfheim, dwarven craftsmanship, suppressed history, and uncertainty about the weapons made for the gods. The environments hint at erased history without depicting the late-game revelations.
- Existing local `nidavellir_town_bg.png` and `iron_road_bg.png`: black basalt, bronze geometric carving, iron reinforcement, amber lights, side-on stone walkway with a substantial foundation.
- `data/quests/c2_3_forbidden_name.tres` and `c2_4_nameless_grave.tres`: silence surrounding Sindri and deliberately removed names.
- `data/quests/c2_5_hall_of_silence.tres`: the largest ancestral foundry beneath the mountain, inherited tools, silent wraiths and the Rune Watcher in the deepest area.
- `data/quests/c2_6_to_cold_forge.tres`: the abandoned forge beyond the hall and machinery still following old commands.

Ember Mine progresses from a supported mine entrance through ember-ore galleries and lifting machinery to the architectural entrance of the old foundry. Hall of Silence contains cold monumental foundry pillars, hanging ironwork, inherited tools, a defaced smiths' relief and an old forge seal near the far-end encounter area. Characters, enemies, UI and magical portal effects are drawn by the game, not baked into the artwork.

## Generation and assembly

All new artwork was generated/refined with the **built-in image_gen tool**. Exact prompts are in `prompts.json`. No external image API or CLI was used.

The tool returned smaller images than the requested large panorama sizes. Two composition halves per map established a continuous layout, then four overlapping detail tiles per map restored surface detail at a higher effective resolution. The final PNG sizes are the actual scene dimensions; they are assembled assets, not a claim that a single generation produced a native 5200-pixel image.

`sources/` retains the four composition halves and eight detail results. `*_guide_*.png` contains registered layout guides. `assemble_maps.ps1` performs deterministic resizing, floor registration and smooth overlap compositing with System.Drawing. The image generation tool performs the creative drawing; the assembly script handles geometry and joins.

- Ember detail tiles: 1504 × 1400 assembly size, starts at X=0, 1232, 2464, 3696; 272 px overlap.
- Hall detail tiles: 1408 × 1400 assembly size, starts at X=0, 1131, 2262, 3392; 277–278 px overlap.
- Each tile's horizontal floor lip is registered to image Y=1100 before joining.
- UVs cover each finished image 1:1. The textures use high-quality VRAM compression and mipmaps; the background Polygon2D uses linear mipmap filtering.

Rebuild from this project root with PowerShell:

```powershell
& ./output/map_art/assemble_maps.ps1
& ./output/map_art/assemble_maps.ps1 -Refined
```

The original mockup PNGs are preserved. Only the two map scenes' texture references, UV coordinates and background filtering were updated. Ground shapes, map bounds, spawn markers, portals, monsters and quest logic were preserved. Pre-existing uncommitted player/FX work was not edited by this map-art task. `.gdignore` keeps this source/review folder out of Godot resource imports.

## Verification

Tested with Godot 4.7.2 using the OpenGL compatibility renderer:

```text
MAP_ART_TEST: 2 maps, 6 standing samples, 480 walking frames, 0 failures
```

`map_art_test.tscn` checks texture dimensions, UVs, unchanged floor/spawn/portal heights, player floor contact, and walking across the central artwork join. It removes enemies only from its temporary test instances. Six `*_ingame_*.png` captures were visually reviewed for ground alignment, seams, readability, camera coverage and endpoint composition.

`godot_runtime.log` contains no runtime script errors. Editor import still reports the pre-existing malformed translation import from `_to_delete/npc_lines.csv`; that unrelated source was left unchanged.
