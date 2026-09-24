# Effect artwork direction

User preference: create future effect artwork with the built-in imagegen tool, including sword light and sparks. Use code for placement, sprite animation, facing and timing. Preserve real PNG alpha.

## Revised C: equipped weapon with animated slash sprites (September 21, 2026)

Latest Flurry size: multiply the separate flurry cut artwork by 1.5 (normal runtime cap becomes 360 px visually from the previous 240 px). Preserve 0.12 s per cut, six strike events, damage and hitboxes. Backup: `output/flurry_size_revision/runeblade_echo_art_before.gd`.

Latest direction correction: lunge uses a 500 px horizontal streak triggered only at the forward near-horizontal sword pose (axis dot facing > 0.97). Use explicit transform bases for mirroring; do not assign global_rotation after negative scale. Anvil slam source is mirrored opposite to crescents so it cleaves outward. Captures/backups: `output/runeblade_direction_fix/`.

Latest critical preference: use the exact user-selected clipboard sheet `codex-clipboard-d0ac725b-ec76-4e23-8025-b02184a39d07.png`, replacing the thicker redrawn version. Runtime critical size is 210 times monster factor to compensate for wider source coverage. Eight frames / 0.28 seconds remain. Backup and rendered review: `output/critical_selected_revision/`.

Latest impact tuning: normal cuts are 45% larger and drawn in front of the body/equipment. Lunge uses a 360 px sprite (was 200), begins only during dash when the actual sword points forward, and lasts 0.42 s. Dodge remains 0.20 s. Anvil range is now 660 x 400; Faultline radius is 420 with four symmetric animated sweeps/cross-cuts around a larger planted sword. Rain has 20 larger visual swords instead of 45, retaining five damage pulses. Critical hits add the new imagegen `critical_sheet.png` eight-frame silver sparkle to the existing crack overlay, without audio. Backups, prompts, numeric changes and latest review outputs: `output/runeblade_impact_revision/`. These latest settings supersede historical timings below.

User correction: the hand must always show the equipped physical weapon. Spectral swords are separate summoned effects such as Worldcleaver rain and the wave projectile. CharacterVisual no longer replaces the held weapon or creates rigid sword echoes.

Six separate built-in imagegen RGBA sheets under `Sprites/effects/runeblade_echo/`, each with eight distinct painted silhouettes (4 columns, 2 rows): `slash_sheet.png` for combo 1 descending cut, `rise_sheet.png` for combo 2 rising cut, `sweep_sheet.png` for combo 3 wide finisher and Bash, `thrust_sheet.png` for lunge, `slam_sheet.png` for Anvil/faultline ground cuts, and `flurry_sheet.png` for rapid cross-cuts. The 48 drawings grow, sweep, break apart and vanish over 0.20 seconds per animation. AnimatedSprite2D samples different atlas frames; orientation transforms only select the swing plane. Basic attacks release near existing hit timing; Flurry releases its own sheet on each actual strike. Bash retains its damage node and hitbox. Dodge retains short animated speed ribbons; lunge adds an eight-frame thrust anchored to the equipped sword tip. No spectral sword copies in the hand or golden thrust plume.

Runtime: `runeblade_echo_art.gd`, `runeblade_echo_burst.gd`. Review scene: `runeblade_echo_review.tscn`. Prompt, latest captures and pre-revision backup: `output/runeblade_sprite_revision/`. Original pre-C backup remains untouched in `output/runeblade_echo_backup_20260921/`.

## Previous C implementation: spectral echo blade (September 21, 2026)

This supersedes the September 13 visuals for Runeblade. Silver-white edges, translucent lavender interiors, restrained angular diamond runes. A single coherent light blade replaces the equipped blade during attacks; idle restores equipment. Normal combo, lunge, flurry, anvil, faultline, Rending Wave, Worldcleaver and support flashes share this language. Dash echoes remain behind the character and stop after 0.2 seconds. Worldcleaver keeps the 585-pixel starting height and staggered random falls.

Built-in imagegen produced the three original transparent PNGs in `Sprites/effects/runeblade_echo/`: blade, cut and rune. Source artwork is unmodified; Godot animates transforms, opacity, hand attachment and short echoes continuously. Body animation still uses the existing authored frames. This is not a newly generated frame-by-frame character animation.

Prompts: `output/runeblade_echo_review/imagegen_prompts.json`. Focused visual scene: `runeblade_echo_review.tscn`. Review captures and GIFs: `output/runeblade_echo_review/`. Visual checks: 51 passed; legacy visual rollback: 43 passed. Broader combat regression: 52 checks with the same one skill-point-refund failure in both enabled and disabled modes. Damage timings, hit budgets and collision sizes were retained.

Rollback: set `ENABLED` to `false` in `scripts/entities/runeblade_echo_art.gd`, restart the running game. Original branches and assets remain. Original file backup: `output/runeblade_echo_backup_20260921/before.zip` with 295 SHA-256-verified entries. See that directory's README before restoring files.

## Previous Dash and Rune Lunge direction (September 13, 2026)

Reference: user's frame_02cc.png. This supersedes the blue lightning / white starburst design, which the user rejected.

- Dash: compact horizontal white / pale blue speed ribbons behind the character; scale (0.32,0.48), 36% smaller in each dimension than the previous version. Play four frames once at 20 fps (0.2 seconds), then disappear without looping or an extra fade.
- Rune Lunge: same rearward ribbons plus an animated sharp gold-orange thrust plume starting at the equipped blade tip and extending rearward / upward.
- Both effects are animated sprite sheets, four frames each, at 20 fps (ribbons) and 18 fps (gold). Both draw behind the character and equipment with relative z=-5.
- No lightning branches, rings, orbiting bolts, or radial starburst.

Production assets: Sprites/effects/dash_silver_speed_sheet.png and Sprites/effects/dash_gold_thrust_sheet.png. Each is1536x1024, 2x2 frames. Runtime uses inset764x508 atlas cells, preserving source alpha. No raster postprocessing.

Prompts: output/dash_imagegen/v2_prompts.md. Runtime: scripts/entities/rune_dash_fx.gd. Original combat and movement timing remain unchanged.
