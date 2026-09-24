# Story character art audit — 23 September 2026

## Canon and visual identity
Read docs/คัมภีร์บท4-6.md (secret quest section S5–S10), current ch456_campaign.gd, chapter7_implementation.md and chapter6 Stranger NPC resources. Author-side identity is Loki, erased from names/history, Thor's younger brother in this game's canon. The chapters intentionally retain the label คนแปลกหน้า and do not reveal his name. No dialogue, identity revelation, quest ID or reward was rewritten.

Visual anchors: angular pale face, charcoal shoulder-length hair with silver front streak, forest-green scarf, round silver shoulder clasp, worn leather travelling coat. Reference images stranger.png and stranger_seated.png stay intact. New stranger_winter.png uses the same face and clothing with a snowy hood and offered parchment for S5. Prompt: full-body single same man, front facing, guarded melancholy, worn winter hood, same silver streak/scarf/clasp, parchment in hand, transparent, no horns/crown/superhero costume/background/text. Original generated path ends exec-8fd636a7-85bb-416d-afa7-3a04d1fc4e36.png. Source 1024×1536, genuine alpha 0–254, 1,047,040 fully transparent pixels. Viewed on a solid green background to confirm no baked black backdrop.

## Findings and fixes

| Location/event | Before | After |
|---|---|---|
| Broken Wall S5 | Polygon person and no dialogue portrait | Same-character winter sprite and upper-body AtlasTexture portrait |
| Mirror Lake S7 | Rescue text without character portrait/world figure | Existing canonical standing figure appears for event and matching portrait; removed after dialogue |
| Ljosalf S8 | Stranger text without portrait/world figure; Nott raw page | Existing standing figure appears beside Nott; speaker-specific portraits; removed after event |
| Eljudnir S9 | Ordinary NPC had portrait, scripted follow-up omitted it | Scripted pages use canonical standing portrait |
| Odin Seat S10 | Ordinary NPC had portrait, scripted follow-up omitted it | Scripted pages use existing seated portrait |
| Dimming Wood Sol_exile | Portrait assigned but Sprite2D texture absent | Existing sol_exile.png attached; existing flag and translucent appearance preserved |
| Ljosalf large shade crystal | Procedural polygon although finished asset exists | Existing shade_crystal.png attached, placeholder hidden; interaction unchanged |

S6 intentionally remains an unseen voice behind the player: its text explicitly says not to turn around. Narration and disembodied voices get explicit null portraits so the previous speaker does not carry over. Chapter6 chains, throne, ninth wall and freed Garm already have dedicated art or painted scenery through chapter6_story_art.gd. Campfire already has its own rendered child. Runeblade clue markers explicitly disable their fallback polygon and use scene art. These are not missing NPC portraits.

## Audit scope

Engine instantiated all 96 registered map scenes, inspecting 60 NPC instances and 364 item icons. All 60 NPCs have dialogue portrait assignments, all 364 items have icons. The only NPC without a texture was Sol_exile, now fixed. Baseline machine output: output/story_art_audit/npcs.json; completed scan log: npc_scan.log. NPC scanning alone does not execute dynamic event setup; ch456_campaign and runeblade_campaign were also inspected. Enumerated 37 explicitly named lore points in lore_points.json and code-authored speakers in script_speakers.json. Lore inscriptions, graves, cracks and ambient triggers often use baked map scenery rather than character portraits; this inventory is not a claim that each scenic detail was visually audited at runtime.

New art lives in Sprites/npc/story/stranger_winter.png and Sprites/portraits/npcs/stranger_winter.tres. Character portraits use AtlasTexture cropping, preserving original image. No changes to save data, quest gates, combat or reward chances.

## Focused validation

story_art_test.tscn loads actual maps with combat spawners removed only inside harness. SaveManager disabled. Checks real S5 dialogue portrait and world sprite, invisible placeholder, unseen voice suppression, original page immutability, one-time reward and repeat dialogue; checks Sol visible sprite and portrait, chapter5 temporary visitor and crystal, chapter6 seated portrait. Screenshots/logs in output/story_art_audit. No claim of a full chapter playthrough or new frame animation.


Final evidence: broken_wall.log 8 checks, dimming_wood_verified.log 4, events_final.log 11, odin_seat_verified.log 3 (26 total across these completed runs). Inspected all four map screenshots and s8_dialogue.png. S8 test executed the real event, checked portrait swap to Nott, reward, flag and temporary actor removal; the rescue dialogue/actor lifecycle was invoked in that same fixture, not a full lethal-hit lake playthrough. Initial failed test logs retained for transparency; use the named completed logs. Broken Wall rendering logged three native Rect2i negative-size warnings while still passing and producing correctly placed art; other verified maps had no such warnings. Sandbox shader-cache/certificate warnings remain. No full-game visual audit or motion-animation claim.
