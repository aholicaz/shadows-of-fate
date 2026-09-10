# Slash and ambient lighting

The three Attack_Blade entries in `data/sprites/player_fx.tres` enable a white crescent shader through the existing SlashSheetFX and PlayerFXBook. The shader follows the authored blade positions and angles after sprite flip and auto-fit, and uses animation frame progress for streaks, sparks, and final fade. Canvas sizes are 360/350/320 px; the existing finisher multiplier remains 1.25. Visible crescent height is approximately the 240 px character height.

In PlayerFXBook, select an Attack entry and adjust crescent span, width, direction or size. Disable crescent_enabled to return to the existing SpriteFrames / directory / sheet sources. Skill entries are preserved.

Both map scenes have an AmbientFX node using scripts/world/map_ambient_fx.gd. Positions are in map coordinates and match the baked lanterns, braziers and ceiling openings. Ember Mine has 7 foreground lanterns and 2 faint warm shafts; Hall of Silence has 2 braziers and 4 cool shafts. Independent smooth flicker animates the flame, glow and local PointLight2D. Local lights affect character layers, excluding the baked background. Ground, bounds, spawns and portals are preserved.

Validation scenes:
- slash_combo_test.tscn: 132 authored frame/direction/speed cases, real animation clocks, cancellation, subframe shader phase and final fade.
- fx_playtest.tscn: real Player.start_attack integration, all three combos in both directions, with rendered screenshots.
- map_art_test.tscn: light flicker, 6 standing samples and 480 walking frames across the two maps.

Renderer: Godot 4.7.2, OpenGL compatibility. Existing editor import errors in _to_delete/npc_lines.csv and duplicate UIDs in archived assets are unrelated; game runtime tests are clean.
