# Effect artwork direction

User preference: create future effect artwork with the built-in imagegen tool, including sword light and sparks. Use code for placement, sprite animation, facing and timing. Preserve real PNG alpha.

## Current Dash and Rune Lunge direction (September 13, 2026)

Reference: user's frame_02cc.png. This supersedes the blue lightning / white starburst design, which the user rejected.

- Dash: compact horizontal white / pale blue speed ribbons behind the character; scale (0.32,0.48), 36% smaller in each dimension than the previous version. Play four frames once at 20 fps (0.2 seconds), then disappear without looping or an extra fade.
- Rune Lunge: same rearward ribbons plus an animated sharp gold-orange thrust plume starting at the equipped blade tip and extending rearward / upward.
- Both effects are animated sprite sheets, four frames each, at 20 fps (ribbons) and 18 fps (gold). Both draw behind the character and equipment with relative z=-5.
- No lightning branches, rings, orbiting bolts, or radial starburst.

Production assets: Sprites/effects/dash_silver_speed_sheet.png and Sprites/effects/dash_gold_thrust_sheet.png. Each is1536x1024, 2x2 frames. Runtime uses inset764x508 atlas cells, preserving source alpha. No raster postprocessing.

Prompts: output/dash_imagegen/v2_prompts.md. Runtime: scripts/entities/rune_dash_fx.gd. Original combat and movement timing remain unchanged.
