# September 22 monster animation integration

Update Sept 23: Ash Knight's pending Idle/Walk is now installed; see `spriteflow_sep23_monsters.md`. Run the Sept 23 importer after this historical importer to retain the completed Ash Knight clips.

Downloaded original PNGs from the owner's SpriteFlow gallery. `output/sep22_sprites/sources.json` records source UUIDs. The installed PNG hashes and clip ranges are in `source_hashes.json` and `manifest.json` alongside backups. The importer is `_tools/import_spriteflow_sep22.py`.

| Monster | New source sets | Result |
|---|---|---|
| drowned | Sep 16 walk-cycle-loop-1027 and unnamed 10:20 set | Walk/Run, Attack, Hit, Die/Death now use real frames; keeps Sep 21 idle-loop-0844. No legacy still remains. |
| cinder_hound | idle-walk-1010, attack-sprite-animation-1019, hit-and-die-1031 | Complete idle, movement, bite, reaction and death |
| slag_mantis | idle-walk-loop-1446, triple-attack-1441, hit-and-die-1351 | Complete animations; three contacts at source frames 10,17,23 |
| chainbound_ogre | idle-walk-loop-1556, attack-slash-hit-1608, hit-and-die-1619 | Complete animations; two contacts at 15,22. Death ends at 31 because frame 32 returns to standing. |
| kiln_sentinel | idle-walk-1550, attack-slash-hit-1556, hit-and-die-1608 | Complete animations; normal contacts at 12,20; existing ground-slam skill impacts at source 20 |
| ash_knight | attack-slash-three-1619, hit-and-die-1612 | Attack, Hit, Die/Death installed. Three contacts at 9,14,22. Idle/Walk generation 16:24 was still processing at last successful gallery inspection; old idle/movement remain pending that source. |

The Sep 16 `idle-stance-loop-1100` is a Pitman sprite, downloaded while identifying Drowned. It is kept as a reference only; Pitman already has separate animation sheets and is outside the new Sept 22 set.

Hel Hound and Ferryman were already connected to their full Sept 21 PNG clips. `gjoll_sprite_check.tscn` verifies the exact MonsterData resources referenced by `scenes/maps/gjoll_river.tscn`, rather than a separate copy of the enemy data. Restart an already-running game to load changed resources.

Registration uses fixed AtlasTexture margins and per-source neutral-pose scales. PNG dimensions vary (1112×834 and 1024×1024); the registered canvas is always 1600×1400 with feet at (800,1100). No PNG pixels are changed. Existing heights, HP, ATK, rewards and cooldowns are preserved. Two/three-contact attacks split one normal attack's damage budget rather than doubling/tripling it. Attack timing follows the authored 12 FPS motion. The kiln skill retains its existing 1.35-second anticipation and 2-second recovery, with the slam origin aligned to the hammer head.

Open `sep22_monster_review.tscn` and run with F6 for the review selector. Automated mode uses `-- --audit-sep22`. The probe observes calls to the real combat method; it verifies hit counts and visible contact frames in both directions, constant sprite scale, canvas registration and kiln ground-slam timing. It initializes an in-memory game without activating saving.

Rendered verification: Godot 4.7.2, OpenGL Compatibility, 3,970 assertions passed. All 544 installed PNG hashes verified. The run encountered unrelated newly added boss-card textures awaiting Godot import; the follow-up editor import resolved those without changing card resources. A fresh Gjoll scene-binding review then passed 272 checks, including multiple distinct source textures and no Chapter 6 mockup paths in all five poses of all three monsters. Only sandbox log/cache/certificate startup warnings remain. The focused tests do not constitute a complete chapter playthrough.
