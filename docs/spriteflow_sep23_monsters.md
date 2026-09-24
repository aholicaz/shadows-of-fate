# Chapter 7 SpriteFlow additions — 2026-09-23

Seven completed sources were found above the already installed Sept 22 entries in the logged-in gallery. Downloaded 224 original PNGs; existing Ash Knight attack/hit/death sources remain installed. Runtime PNGs are byte-identical to the downloads. Provenance and registration are recorded in `output/sep23_sprites/sources.json` and `manifest.json`.

Source frame numbers below are one-based. Runtime event indices are zero-based.

| Monster | Idle | Walk / Run | Attack | Hit | Die / Death |
|---|---|---|---|---|---|
| ash_knight | idle-walk-loop-1624, 1–6 | same, 9–24 | existing 4–29 | existing 3–8 | existing 9–32 |
| ember_oracle | idle-walk-cycle-1657, 1–6 | same, 9–24 | spell-cast-attack-1000, 3–30 | hit-and-die-1648, 4–6 | same, 7–32 |
| oath_warden | idle-walk-1648, 1–4 | same, 9–24 | attack-slash-combo-1657, 2–26 | hit-and-die-0959, 3–6 | same, 7–32 |

Idle/walk/death run at 8 FPS; attack/hit at 12 FPS. Death never loops. All frames use a fixed 1600×1400 canvas and (800,1100) anchor through AtlasTexture margins, without changing original pixels or independently recentering each pose. Per-source neutral geometry preserves intentional attack movement.

Ember Oracle releases one orange fire orb from source frame 15 (Attack index 12), at the visible hand/orb center. It uses the existing procedural fire shader and impact effect, travels horizontally at 1000 px/s for up to 1200 px, and does not track the player. Ranged engagement is 650 px. The source shows one casting thrust, not a multi-shot volley.

Oath Warden's normal attack contacts source frames 4 and 16 (indices 2,14), splitting its existing damage budget equally. Its ground-slam skill uses source frames 10–26, with impact at source 16 (Skill index 6). Weighted frame durations preserve the existing 1.35-second windup and 2-second recovery. Slam origin follows the lowered blade. Stats, rewards, display heights, cooldowns, hitboxes and saved IDs are preserved.

## Review

Open `sep23_monster_review.tscn` and press F6 for the three-monster selector, animation buttons, and facing control. The audit mode (`-- --audit-sep23`) exercises the actual attack coroutines, orb release and boss slam, samples both facings, checks stable frame scale, and verifies the real Ash Procession and Oathbreak Crucible spawners reference these resources. Saves remain inactive.

Current results are written to `output/sep23_sprites/runtime/audit.json`, with captured frames in the same directory. Original-file hashes and protected-stat checks are in `output/sep23_sprites/static_audit.json`.

Verified with Godot 4.7.2 / GL Compatibility: 1,494 assertions passed, zero failures; 111 rendered captures. Reviewed animation phases and both projectile directions in `output/sep23_sprites/rendered_review.jpg`. All 288 PNG hashes (224 new + 64 retained Ash Knight frames) match originals; protected stats were unchanged. Sandbox log/cache/certificate warnings occurred, but no script/resource errors occurred in the completed runtime audit.
