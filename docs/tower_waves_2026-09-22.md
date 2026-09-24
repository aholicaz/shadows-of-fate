# Tower waves — 22 September 2026

Implemented for all 20 existing floors. Story gates, checkpoint entitlements and one-time clear rewards are unchanged. GM testing does not award progress or rewards.

- Floors 1–5: 20 regular enemies (6/7/7); 6–10: 24 (8/8/8); 11–15: 26 (6/6/7/7); 16–20: 30 (7/7/8/8).
- 5–6 source species per floor; rotating themed pools; up to eight regular enemies alive together. Cache entries for other waves are released, while living actors retain their resources.
- Two-second intermission, optional skip button; one-second spawn warning. Paired boss arrives six seconds after the first. Pending boss counts toward completion.
- Boss pairs start at floor 11. Milestone guardians replace a boss rather than append another fight.
- Boss heavy casts share a 7.5-second reservation, covering Meteor ground fire. Basic attacks remain independent. No new boss skill announcement panel.
- Regular HP/ATK multipliers against prior tower base: swarm .30/.60, mobile/ranged .40/.72, heavy .65/.85. Paired boss .65/.85 each. Chapter monster resources are not edited. Defense, accuracy and reward formulas retained.
- Tower boss bars: two compact rows; campaign boss UI retains its previous placement.

Validation: tower_gm_test checks all floor roster counts and resource paths, species diversity, bosses, pending partner completion guard, delayed spawning, scene-exit timer cleanup, source immutability, stats, shared cast reservation, GM reward isolation, and both boss bars including one boss dying. OpenGL UI preview inspected. This is not a full combat or mobile performance benchmark; user playtest still needed for time-to-clear and potion demand.

Try floors 1, 11 and 20 with both attack/crit and skill builds. Record level, equipment/refinement, clear time and potion use. Restart the running game before testing changed scripts. No web export/deployment performed.
