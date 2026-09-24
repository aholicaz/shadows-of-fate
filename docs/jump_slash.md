# Jump Slash integration

- Skill ID: jump_slash; Runeblade / Ninth Edge, level 50, rune_lunge 3, maximum 10 levels. Uses Runeblade points, compatible with existing saves and eight hotkeys.
- 600 px grounded collision sweep; airborne motion is authored in the sprite. Stops at scene collision, cancels at unsupported ledges. No invulnerability.
- 32 original PNGs, unmodified. 40 fps / 0.8 s. Frame 18 releases the effect and damage wave.
- Forward wave: 1260 x 450 px, eight targets maximum, one hit per target, 408–1272% ATK; 7 s cooldown, 20–29 SP. One rune gain per cast under existing Runeblade rules.
- Uses existing rune_lunge icon provisionally and existing wave sound. Source art has a baked sword; equipped sword overlay hidden only for this animation. Later swordless replacement must also provide/calibrate hand sockets and remove JumpSlash_Runeblade from rb_baked_weapon.
- Source ZIP: C:/Users/peeco/Downloads/sword-jump-slash-1036.zip. Effect from output/jump_slash_spritegen/run; runtime copies under Sprites, no runtime output/ dependencies.
- Focused runtime test: jump_slash_test.tscn. Checks movement, control recovery, 32 frames, baked weapon, single-hit multiplier, wall blocking both movement and damage, death cancellation. No saves activated.
- Render: jump_slash_preview.tscn captures both directions at frames 6/12/18/24/32. Output under output/jump_slash_import. Rendered sampled frames checked, live mobile feel not yet tested.

Height pass: extra visual lift of 1.2 standing body heights at apex, returning to zero at release; collision stays grounded. Wave art width x1.8 and height x2, lifetime 0.67 s. Damage is 1.2 times rune_lunge at every level (Lv1 408%, Lv10 1272%).
