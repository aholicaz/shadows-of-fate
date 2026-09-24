# Chapter 6 SpriteFlow integration — 22 September 2026

Source: the owner's SpriteFlow gallery, generation date 21 September. Downloaded 29 sets (928 original PNGs). Installed 28 sets (896 PNGs); `idle-walk-2353` supersedes the older Nidhogg `idle-walk-2109` set. PNG bytes are unchanged. Source URLs, SHA-256 hashes, backups and frame mappings are in `output/chapter6_sprites/`.

## Runtime mapping

| Actor | Idle / movement | Attack | Hit / death |
|---|---|---|---|
| hel_hound | idle-walk-0856 | attack-hit-swing-0903 | hit-and-die-0927 |
| mist_ghost | idle-fly-1039 | mist-ball-attack-1100 | hit-and-die-1011 |
| ferryman | idle-walk-cycle-1121 | attack-action-1109 | hit-die-1515 |
| name_warden | idle-walk-loop-1135 | attack-slash-hit-1152 | hit-and-die-1202 |
| erased_voice | idle-fly-1616 | attack-strike-1702 | attack-death-animation-1555 |
| false_judge | idle-walk-set-2042 | spell-attack-2047 | hit-and-die-2051 |
| chained_garm | hero-idle-walk-2102 | attack-sprite-animation-2106 | hit-and-die-2057 |
| nidhogg_spawn | idle-walk-2353 | attack-strike-2112 | attack-hit-die-2105 |
| drowned | idle-loop-0844 + Sep 16 walk-cycle-loop-1027 | Sep 16 unnamed 10:20 set | Sep 16 unnamed 10:20 set |
| garm_freed (story form) | idle-walk-cycle-2041 | attack-hit-strike-2049 | hit-and-die-2056 |

The freed Garm's Walk is used when the player releases it, before the existing quest cleanup. Its remaining animations are available in `data/sprites/monsters/garm_freed_frames.tres`. The sleeping portrait beside Odin's throne remains unchanged to match its dialogue.

Each clip uses a fixed foot anchor (800,1100) in a 1600×1400 AtlasTexture canvas. Per-source neutral-pose scale calibration avoids shrinking during weapon swings, lunges and collapse. No per-frame bounding-box centering is applied. Existing display heights, stats, hitboxes, rewards and boss spell behavior are retained. Attack clips run at 12 FPS and finish their recovery; contacts are assigned to the visible forward strike. Name Warden's first backward sweep is windup, with damage on its forward sweep.

Erased Voice's death stops at source frame 24: frames 25–32 respawn the figure and must not play after death. Drowned's missing movement, attack, reaction and death were subsequently found in the Sep 16 gallery and integrated; see `spriteflow_sep22_monsters.md` for the correction.

## Ranged attacks

| Actor | Release source frame | Attack frame (zero-based) | Appearance | Count |
|---|---:|---:|---|---:|
| mist_ghost | 19 | 15 | gray-blue mist orb from hands | 1 |
| erased_voice | 12 | 8 | blue soul/voice orb from mouth | 1 |
| false_judge | 13 | 10 | pale green-gold orb from staff tip | 1 |

The existing procedural orb, trail and impact renderer supplies these effects. Each projectile travels at 1000 px/s along the initial facing, horizontally, with a 1200 px lifetime range. No aim-at-player or homing. Damage occurs on impact; swept collision prevents tunneling and terrain blocks the shot. The mist animation's original charge and trailing mist are retained. The judge's existing three ground judgment bolts remain its separate skill.

## Review

Open `chapter6_monster_review.tscn` in Godot and run the scene to select an actor, animation and facing. Automated rendered audit:

```powershell
& $godotExe --path . --rendering-method gl_compatibility res://chapter6_monster_review.tscn -- --audit-chapter6
```

The audit uses an in-memory new game with saving inactive. It checks animation resources, both facing directions, constant per-clip scale, actual release events and shot counts, straight trajectories, player/terrain collision, and the freed-Garm departure. Screenshots and results are under `output/chapter6_sprites/runtime/`.

Verified with Godot 4.7.2, OpenGL Compatibility on the RTX 3050 Ti: 4,194 checks, zero failures. Reviewed the rendered idle, attack, death, projectile and departure screenshots. Sandbox startup warnings prevented writing the engine's user log/shader cache and reading the OS certificate store; the test itself completed, and its redirected logs and screenshots were written to the project output folder. This is a focused animation/combat review, not a complete chapter quest playthrough.
