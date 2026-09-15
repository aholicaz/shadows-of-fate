# Boss skills and animated effects — 2026-09-14

## Cause and combat change

Several skill callers multiplied `Combat.monster_hits_player().damage`, then forced a minimum of 1 even when the original result was a FLEE miss. Large visual attacks could therefore deal 1 damage. Forge Guardian additionally used 0.7 ATK per skill hit.

`Combat.monster_skill_hits_player()` now resolves boss skills after their caller checks collision/area. Boss skills use ATK × skill multiplier × 100/(100+DEF), with the existing ±12% variation. They do not roll FLEE a second time or randomly bypass DEF through critical hits. Movement, jumping where height permits, dash invulnerability and player damage defenses still apply. Ordinary monster skills preserve misses as zero; ordinary attacks retain their original FLEE/critical rules. A normal critical can still exceed a mitigated skill hit against high DEF.

The shared resolver covers direct area attacks, dark waves, lightning, skill projectiles/explosions and ground slams. Straight ordinary fireballs remain ordinary attacks. An explicit `skill_cast` flag marks hand-fired skill projectiles.

## Multipliers

| Boss | Before | After | Note |
|---|---:|---:|---|
| Forge Guardian | 0.70 | 1.15 | Per hit, five authored skill hits; total 5.75 ATK |
| Stormscar | 1.60 | 2.00 | Existing bolt override already 2.00 |
| Chained Garm, Wall Shieldbearer | 1.90 | 2.20 | Per hit |
| Stone Hrungnir | 1.70 | 2.20 | Per hit |
| Thorn Matriarch, Radiant Alfr, Light Forsaken, False Judge, Kiln Sentinel, Oath Warden | 1.80 | 2.20 | Per hit |
| King Poring | 2.40 | 2.40 | Shared resolution fix only |
| Baphomet, Gullveig Ember | 2.00 | 2.00 | Existing/default multiplier; signature attacks below |

## New encounter attacks

- **Gullveig Meteor:** three warned impact locations, 240 px apart, locked when casting. Impacts at 1.65/1.85/2.05 seconds. Each danger area has a 120 px horizontal radius. One impact maximum per player per cast, 2.6 ATK. Each patch burns for five seconds and can tick once per second for 0.35 ATK; adjacent patches cannot stack rapid burn ticks. Standing through one complete impact and burn deals 4.35 ATK before defense. Ground is raycast, so casting at a jumping target does not suspend fire in midair.
- **Gullveig frontal flame jet:** alternates with Meteor. One-second warning; three hits at 1.0/1.5/2.0 seconds, 1.2 ATK each. Flame is emitted from the authored hand socket toward the ground ahead. Skill cooldown 8 → 10 seconds. The existing three-fireball ordinary attack stays available.
- **Baphomet triple scythe:** three separate animated slashes at 0.90/1.32/1.84 seconds, 1.15/1.25/1.50 ATK; total 3.90 ATK. Final hit has stronger knockback. Alternates with the existing dark-wave skill. Each slash animation starts 0.12 seconds before its impact. The sheet is mirrored relative to the attack direction so the convex cutting edge leads outward toward the player; both left and right casts are rendered in `scythe_direction.log`.

These effects terminate safely if the caster dies. Meteor releases the caster after 2.25 seconds while ground fire continues; jet/scythe release after 2.5 seconds.

## Sprite assets

Final runtime assets: `Sprites/effects/boss_skills/{meteor,flame_jet,scythe,burning_ground}_sheet.png`, with matching `_frames.tres` SpriteFrames resources. Each has eight genuinely distinct frames in a 4×2 grid; 444×444 px cells, 1776×888 px sheets. No existing character sprite sheet was resized.

Meteor and flame jet run at 16 fps; burning ground loops at 12 fps; scythe is an eight-frame one-shot at 20 fps. `boss_signature_skill.gd` draws changing AtlasTexture frames from these SpriteFrames resources against the combat timeline. This is actual frame animation, with additional placement/rotation for the cast. Ground-frame baseline metadata compensates for row-to-row registration differences so the fixed lava floor does not bob; flame shapes keep their authored motion. Four final PNG sheets total about 5.6 MB. Unused single-image concepts are outside runtime assets under `output/boss_skills/concepts/`.

Artwork was created with built-in Imagegen. The first checkerboard-backed candidates were discarded because background extraction damaged thin luminous details. Final meteor, scythe and ground candidates were generated on solid black, then extracted to RGBA with the user's explicit permission for code background removal. The jet already had native alpha. Black matting preserves enclosed dark rock and unpremultiplies soft glow. Original generated images are retained.

Reproduction and prompts: `_tools/prepare_boss_skill_sheets.py`, `output/boss_skills/source_manifest.json`, `output/boss_skills/final_sources.json`. Read-only alpha/frame validation is saved to `output/boss_skills/sheet_validation.json`.

## Verification

`boss_skill_test.tscn` tests all 14 boss resources, armor mitigation, nonboss misses, eight-frame playback, left/right hit areas, three-hit sequences, five burn ticks, warning safety, moving away, dash protection, caster-death cleanup and actual MonsterBase skill alternation. Tests use a dummy target and in-memory PlayerState, without saving or loading the player's progress.

The functional run passed **1,564 assertions** with no failures. The same scene provides real OpenGL rendered sequences for Meteor, flame jet and scythe in both directions; `gullveig_fireball_test.tscn` separately passed **45 assertions** for the existing three ordinary projectiles. Current reports and rendered previews are under `output/boss_skills/` (`test_verified.log`, `basic_regression.log`, `render_final.log`, `ground_alignment.log`).

These are focused combat and rendering tests, not a full campaign difficulty playthrough. Engine root-certificate/editor-settings/shader-cache permission messages are recorded separately from script/test failures.
