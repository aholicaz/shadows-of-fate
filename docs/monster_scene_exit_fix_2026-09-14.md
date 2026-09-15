# Monster projectile coroutine scene-exit fix

The debugger stopped at `await get_tree().process_frame` inside `_run_hand_projectiles`. The monster had left the SceneTree while its attack coroutine was suspended. Its ATTACK state and sprite frame still satisfied the loop condition, but `get_tree()` was null. This can occur during map removal/replacement; the screenshot alone does not identify which action removed the node.

The hand-projectile coroutine now captures the current SceneTree once, validates node/tree/sprite state before release and completion, and cancels permanently on `tree_exiting`. A one-shot cancellation listener is cleaned up on normal completion. Reattaching the same node cannot revive its old attack. Skill projectiles and basic projectiles share this lifecycle protection.

Regression coverage in `scripts/tools/gullveig_fireball_test.gd` includes leaving the tree before the first projectile, leaving during the animation tail, reattachment, queued deletion, ordinary three-shot releases, interruption and collision. Aim assertions honor the current `projectile_aim_at_player` setting; no monster resource values were changed for this fix.

Results: `output/boss_skills/scene_exit_verified.log`. Tests use an isolated dummy target and do not write the player's saves. The user's paused editor session must be stopped and started again to discard the old suspended coroutine.
