# Chapter 3 map artwork — 2026-09-10

สร้างและใส่ภาพลงฉาก Godot โดยตรง อิงข้อมูลเนื้อเรื่อง เควส ตำแหน่ง NPC และทรัพยากรในโปรเจกต์ รักษางานเดิมที่ยังไม่ได้ commit

| Map | Final PNG pixels | Collision floor Y |
|---|---:|---:|
| root_road | 5200 × 1300 | 880 |
| vanir_town | 4000 × 1200 | 880 |
| silver_marsh | 5400 × 1400 | 900 |
| withered_grove | 5200 × 1400 | 900 |
| forgotten_battlefield | 5600 × 1400 | 900 |
| spring_of_life | 3400 × 1300 | 880 |
| dark_forest_2 | 4400 × 1021 | 659.5 |
| nidavellir_town | 5600 × 1200 | 943 |

Runtime images: `Sprites/map/generated/<map>_bg_final.png`. Scene references: `scenes/maps/<map>.tscn`.

## Floor and movement

Painted walking band is 110 world pixels deep, from 86 pixels behind the collision line to 24 pixels in front. Player and monster visible feet are checked against this band using their real sprite frame alpha bounds. Wide monster capsules can put their sprite feet a few pixels above the physical collision bottom; the test checks the visible walking band rather than assuming identical collision and sprite origins.

Nidavellir extends from 3600 to 5600 pixels. NPCs are spaced 650–850 pixels apart, with portals, return spawn and Sindri grave placed to fit the expanded district.

Latest user direction: **no platforms in any map; player does not jump; monsters retain their existing jumping behavior.** All remaining Plat nodes and descendants were removed from root_road, forgotten_battlefield and thunder_scar. Other map scenes have no Plat nodes. Player scene explicitly sets `can_jump = false`; existing horizontal dodge remains. Monster resources and AI are not changed by this movement adjustment. Root ledge source art remains as an unused production asset, with no runtime scene references.

## Quest landmarks

- Vanir: dry well and war mural; mural interaction separated from Eskil.
- Silver Marsh: submerged hammer helmets, abandoned weapons and medicinal plants.
- Withered Grove: dry spring basin, water stains and converging roots.
- Forgotten Battlefield: thrice-burned stake, erased inscription, buried hammer banner and thorn boss clearing.
- Spring of Life: drained sacred well and siphon rune. Rune glow brightens only after the existing Gullveig boss flag unlocks it.
- Dark Forest 2: horned altar and mine passage.
- Nidavellir: distinct shop districts, forge, warp shrine, apothecary and unnamed grave.

Existing quest IDs, dialogue, flags, rewards and portal conditions are retained.

## Effects and tuning

Select `AmbientFX` in each map's Scene tree. Inspector exports control `Lantern Positions`, `Light Energy`, `Light Radius`, `Shaft Color`, `Mist Color`, `Mote Color`, `Glow Energy`, `Water Regions`, `Wind Regions` and `Heat Regions`. Spring also has `QuestRuneFX`.

Existing MapAmbientFX architecture is extended with drifting particles, smoothly breathing fungus/mineral lights and locally masked water, cloth and heat motion. Decorative FX carry `ignore_map_bounds` metadata so mist and shafts cannot expand camera limits beyond actual map art. Existing lantern/Cold Forge lighting defaults are retained.

## Production files

Tool mode: built-in ImageGen generation and reference-image editing. Complete submitted prompts are recorded in `prompts_final.json`. Separate overlapping sections were generated, floor-registered and assembled at the game's required dimensions with minimum-difference seams and feathered joins using PowerShell/System.Drawing. No Python image editing was used. Background images are opaque; isolated ledge art has real alpha transparency.

`sources/` contains source sections. `specs.json`, `registration.json`, `marks.json` and `layout.json` record dimensions and effect/landmark coordinates. `assemble.ps1` can rebuild artwork. `integrate.cjs` is a historical one-time integration script, not an idempotent command: do not rerun it on integrated scenes. `remove_platforms.cjs` records the later platform removal. `before/` and `before_no_platforms/` preserve scene snapshots, including then-current uncommitted work.

## Verification

`chapter3_map_test.tscn` instantiates the actual eight map scenes, checks dimensions, ground registration, seam traversal, disabled player jump with retained dodge, real monster sprite feet, NPC proximity, actual lore quest progression, boss-gated rune and destination spawns. It also loads every map scene to check for remaining platforms. It uses fresh in-memory quests and does not load or save user progress. Captures and logs are in this directory.

Editor import also reports pre-existing duplicate UIDs and invalid translation paths under `_to_delete`; those archived files were not modified as part of this work.

Final results: Godot 4.7.2 rendered all eight maps with OpenGL Compatibility and captured real player/monster/boss feet. After repairing Thunder Scar resource references during platform removal, the complete headless integration rerun passed with **0 failures** (`runtime_verified.log`), including loading all 18 maps. Cold Forge real-renderer lighting regression also passed with **0 failures** (`cold_forge_regression.log`). Four stale monster UID warnings in Silver Marsh/Withered Grove resolve correctly through their existing resource paths; no runtime script errors remained in the final verification log.
