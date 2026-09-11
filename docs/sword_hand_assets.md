# Sword hand assets

All 17 sword items use the existing bare-hand Idle and the shared three-hit Blade combo. Each item stores its own texture, grip in texture pixels, scale, and rotation. Skill-specific animation selection remains unchanged.

- Item settings: `data/items/*.tres` (`equip_follow_idle_hand`, `equip_texture`, `equip_grip`, `equip_hand_scale`, `equip_hand_rotation_degrees`, `equip_attack_body_frames`).
- Shared hand samples: `scripts/entities/blade_hand_track.gd`.
- Body registration and timing still use the original player animation resources. `CharacterVisual` substitutes only the rendered attack body and overlays the equipped sword and fingers.
- Full-resolution copies live in `Sprites/equip/*_hand.png`; no runtime reference points into `_to_delete` or a user-specific generated-images folder.
- Calibration setup for the 16 additional swords: `_tools/configure_sword_hands.ps1`. Rerunning it reapplies the recorded defaults; edit the item resource directly for subsequent manual calibration.
- Validation scene: `all_swords_review.tscn`. It checks all 17 swords across 9 Idle and 22 attack frames in both directions and writes screenshots plus `output/all_swords_review.txt` before exiting.

## Claymore artwork

Created with the built-in imagegen tool because the Claymore item had no image. Saved as `Sprites/equip/claymore_hand.png`; genuine alpha transparency was verified. Existing sword artwork was copied without raster edits.

Generation prompt:

> Create a single isolated Scottish-inspired fantasy claymore greatsword game equipment sprite, detailed hand-painted anime JRPG illustration consistent with polished fantasy inventory weapons. Long straight broad double-edged silver steel blade with a subtle fuller, simple dark iron crossguard with downsloped quillons, long brown leather wrapped two-hand grip, small round steel pommel with modest brass accents. Whole weapon visible with margins. Diagonal orientation: pommel at top right, blade tip at bottom left. Flat side view, minimal perspective, crisp edges, neutral lighting, no ground shadow, no text, no character. Actual transparent alpha background PNG; do not paint a checkerboard or any backdrop. Square canvas.
