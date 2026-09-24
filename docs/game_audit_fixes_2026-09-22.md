# Audit fixes — 22 September 2026

All eight findings from game_audit_2026-09-22.md addressed. No existing saves migrated, no level rollback, no deployment.

## Gameplay and UI

- Quest rewards: pure whole-reward capacity check, including slots freed by consumed objectives. Validate aggregate consumption; complete quest before granting reward. Repeated failed hand-ins cannot yield partial rewards.
- Map and GM lists now use get_monster_info, leaving actual monster loading until spawning.
- Release builds do not create/open GM windows or bind F10; god mode and one-hit logic require a debug binary. Editor/debug testing retains GM.
- Skill tile names use fixed-width clipped ellipsis; full name remains in the detail pane and tooltip. OpenGL screenshot reviewed.
- Hans quest progress now says 50, matching kill_count.

## Export

- Exclude output, tool scripts, explicit root test/preview/review files and the monster preview scene directory. Production equipment_character_preview remains included. No active production references into excluded developer paths found by _tools/check_export_boundaries.py. Optional Web videos retain their existing exclusion.
- addons/export_metadata builds data/monster_quest_export.json from current source during each editor export. GameData reads it for packaged builds.
- GitHub build regenerates fallback catalog and validates export boundaries before building. No workflow dispatched.
- Isolated minimal Web PCK export ran the real plugin; packaged runtime read generated JSON successfully. Full production Web export/real-device performance not benchmarked. Restart the editor to load the new plugin if already open.

## Progression

Existing level curve, monster combat stats, gold and drops unchanged. Monster Base EXP capped to .6% ordinary / 8% boss at its own level for the seven chapter 7 monsters; Job EXP follows 70% of new Base.
Ninth awakening: 60,000 Job EXP gives Job1→4 (three earned levels), replacing 280,000 (Job1→13). Later chapter 7–8 Job rewards reduced as below.
Tower first-clear Base EXP = floor(20% × exp_needed_at(110+floor)); Job EXP = 8,000 + 400×floor (8,400–16,000). Once-only reward and GM isolation retained. Battle difficulty still needs user playtest.

| Type | ID | Old Base | New Base | Old Job | New Job |
|---|---|---:|---:|---:|---:|
| monster | cinder_hound | 4500 | 2432 | 3150 | 1702 |
| monster | slag_mantis | 5000 | 2524 | 3500 | 1767 |
| monster | chainbound_ogre | 5500 | 2716 | 3850 | 1901 |
| monster | ash_knight | 6500 | 3126 | 4550 | 2188 |
| monster | ember_oracle | 7000 | 3345 | 4900 | 2342 |
| monster | kiln_sentinel | 70000 | 34925 | 49000 | 24448 |
| monster | oath_warden | 70000 | 50817 | 49000 | 35572 |
| quest | c7_1_refuge | — | — | 122500 | 40000 |
| quest | c7_2_warmth | — | — | 157500 | 50000 |
| quest | c7_3_chains | — | — | 192500 | 60000 |
| quest | c7_4_ninth_edge | — | — | 280000 | 60000 |
| quest | c7_5_chosen_cut | — | — | 332500 | 20000 |
| quest | c7_6_procession | — | — | 367500 | 22000 |
| quest | c7_7_warden | — | — | 437500 | 35000 |
| quest | c7_8_hundred | — | — | 490000 | 25000 |
| quest | c8_1_roots | — | — | 115000 | 10000 |
| quest | c8_2_storm | — | — | 130000 | 12000 |
| quest | c8_3_reflections | — | — | 145000 | 14000 |
| quest | c8_4_register | — | — | 160000 | 16000 |

## Validation

AUDIT_FIXES_PASS, STORY_EXP_PASS, TOWER_GM_PASS, MOBILE_UI_TEST failures=0, EXPORT_BOUNDARIES_PASS and PACKAGED_METADATA_PASS. Tests end the save session and use memory-only game state. Existing certificate warnings are environment-related.
