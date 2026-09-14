# SpriteFlow monster integration — September 14, 2026

Eighteen completed gallery records supply six monsters. Runtime frames are unchanged PNGs under `Sprites/monsters/spriteflow/<monster>/sep14_*/`. The import configuration is `_tools/import_spriteflow_sep14.py`; reviewed source URLs and contact sheets live under `output/spriteflow/`. Existing artist edits are never overwritten by the importer.

| Monster | Idle / walk | Attack | Hit / death |
|---|---|---|---|
| Echo Wraith | sep14_15 | sep14_14 | sep14_12 |
| Snow Hawk | sep14_13 | sep14_11 | sep14_08 |
| Hollow Elf | sep14_03 | sep14_01 | sep14_17 |
| Water Nymph | sep14_02 | sep14_00 | sep14_16 |
| Light Forsaken | sep14_09 | sep14_05 | sep14_04 |
| Radiant Alfr | sep14_10 | sep14_07 | sep14_06 |

Death clips omit later standing resets. Registration is constant within each source; animation-specific scale compensates for differently sized source artwork. The imported resources reference 559 unique original frames. Atlas regions exclude detached, baked projectiles in Water Nymph frames 13–15 and Light Forsaken frame 10, without editing the PNG files.

## Straight projectiles

| Monster | Releases (one-based source frames) | Effect |
|---|---|---|
| Echo Wraith | 9, 18 | Blue spirit orbs |
| Light Forsaken | 10, 19 | Purple shadow orbs |
| Radiant Alfr | 11 | Pearl / pale pink light orb |
| Water Nymph | 13 | Pale blue water orb |
| Gullveig Ember | Existing three release events retained | Orange fireballs |

Each discharge creates one projectile at its authored hand socket. Each travels at 1,000 pixels/second with a fixed direction and no player tracking. The taller new casters have a fixed downward angle so a shot from an elevated hand crosses the player-height lane. This angle does not depend on the player's location. Facing remains fixed throughout each volley. Shaders and native canvas bursts provide matching colors, trails, muzzle flashes, and impacts. Swept collision prevents a fast ball from skipping over the player or a wall.

Light Forsaken and Radiant Alfr use the same authored hand-release sequence for their skill casts, with their existing skill damage multiplier. Their old ground-wave path is bypassed for these casts. Interruption cancels pending releases. Damage stats, drops, quests, saves, and IDs are preserved.

## Chapter 4–5 scale

The player reference is 288 pixels. All 18 monster types in chapters 4–5 now range from 310 to 850 pixels, chosen by creature shape: wolves 330, humanoids 380–460, large guardians 600, mammoth 680, and bosses 650–850. HP labels are raised with their bodies. Chapter 3 sizes are not modified.

Open `sep14_monster_review.tscn` and press F6 for the size/animation viewer. The viewer offers monster selection, facing, animation replay, and a real projectile attack button. Audit mode is `--audit-sep14`; reports and rendered captures are written to `output/spriteflow/sep14/runtime/`. It starts fresh in-memory state and does not save a slot.

Validation: the Godot 4.7.2 GL Compatibility audit completed 3,261 checks with no failures, covering all six integrations, 18 sizes, both facing directions, authored one/two/three-ball volleys, interruption, skill casts, and swept player/wall collision. Static validation confirms all 559 runtime PNG hashes match their originals and 234 combat/reward stat fields remain unchanged. Six ending ghost frames are intentionally translucent in their source artwork. `output/spriteflow/sep14/size_comparison.jpg` shows each monster beside the actual player sprite.

After setting Gullveig's fixed downward angle to 22.7 degrees, its dedicated real-renderer test passed 45 additional checks, including all three balls hitting a stationary target in either direction, cancellation, and low-FPS wall collision. The report is `output/spriteflow/fire_update/runtime/audit.json`.
