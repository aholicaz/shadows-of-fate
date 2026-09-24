# Quest and bounty window loading

Cause: ObjectiveData.describe(), QuestData.target_name(), and BountyBoard candidate/boss selection and labels called GameData.get_monster(). This synchronous resource load recursively loaded SpriteFrames and large textures even though these callers only needed scalar metadata/drop entries. Bounty selection scans multiple maps, amplifying the stall.

Fix: get_monster_info() has its own lightweight metadata cache. In a source checkout it reads current .tres text and selects only id/name/level/boss/zeny/drop fields without loading resource dependencies. Exported builds use scripts/core/monster_quest_catalog.gd (68 entries). Combat resource loading is unchanged. Existing bounty specifications and rewards are retained.

When monster metadata/drops are edited, refresh the export catalog before export:
`python _tools/build_monster_quest_catalog.py`
The quest_metadata_test.tscn test checks source/catalog parity for every monster, all quest labels, bounty generation, default drop amounts, and that the full monster cache did not grow. This catches stale exported metadata. Source checkout edits are read on next game start.

Validation: focused headless test passed, initial full metadata/quest/bounty pass 68.7 ms on this host, no full monster loads. This is not a device or complete UI latency benchmark. Existing environment certificate warnings do not indicate quest failure. No player save or web deployment performed.

Update: addons/export_metadata now builds packaged metadata automatically on every editor export. GitHub also regenerates the fallback catalog and validates export boundaries. See game_audit_fixes_2026-09-22.md.
