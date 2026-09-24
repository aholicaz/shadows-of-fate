# September 18 local monster sprites

Integrated on September 21, 2026 from the artist's existing local PNGs, without
downloading or overwriting artwork. The six monsters are crystal_stag,
reflection, garden_keeper, light_eater_bloom, light_moth and hollow_moth.

All six now use the supplied Idle, Walk/Run, Attack, Hit and Die clips. Skill uses
the attack motion where no separate skill sheet exists; Crystal Stag uses the
rear-up/crystal phase of its attack sheet. Attack/skill frame durations follow
the existing windup and recovery values. Combat parameters, release/hit logic,
monster display heights, IDs and drops are unchanged.

## Registration

`_tools/import_spriteflow_sep18.py` constructs AtlasTexture margins around the
original 1112×834 PNGs on a common 1600×1400 canvas. No image pixels are rewritten.
Each source's neutral poses establish a fixed baseline. The animation scale
compensates for faint export alpha included in SpriteFit's used rectangle.

Walking uses reviewed torso patches to track horizontal source translation.
The tracking region excludes weapons, legs, wing tips and tails. Only horizontal
translation is corrected; authored vertical gait and wing motion remain.
Walk/Run share the same registered frames. Light Moth needed no X correction.
Reflection's tracked horizontal range was 80 source pixels; Hollow Moth's was
132. The smoothed registration residual is at most 3 source pixels across the
six clips (a tracking diagnostic, not a guarantee about all painted details).

## Review and validation

Open `sep18_monster_review.tscn` and press F6. Select a monster, animation or Flip.
The scene shows the actual player for size comparison and initializes only an
in-memory game. It does not activate saving or load a save slot.

The focused `--audit-sep18` run completed with Godot 4.7.2, OpenGL Compatibility
on the NVIDIA renderer: 2,972 checks, zero failures. It verifies animation
availability/looping, registered textures and constant scale across every frame
in both directions. The 310 rendered captures include every walking frame;
walking sequences and both-facing attack/death poses were visually inspected.
The review's Die button plays artwork only; actual flying-monster corpse descent
continues to be controlled by the existing gameplay death state.

576 original PNG SHA-256 hashes were checked unchanged. All six monster data
files were compared with pre-edit backups: only fit/registration fields changed.
The engine reported sandbox-related certificate/shader-cache errors, and the
editor could not save settings under Program Files; imports and the real
renderer audit nevertheless completed with no script/resource errors.

Evidence and backups: `output/sep18_integration/` (manifest, hashes, before,
static_validation.json, runtime/audit.json, runtime.log, walking strips).
