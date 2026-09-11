# Chapter 2 NPC Idle

Created from the user's five supplied character images using built-in ImageGen. Installed in `scenes/maps/nidavellir_town.tscn` with autoplay.

| Asset | NPC |
|---|---|
| helga | นายหน้าเฮลกา |
| brokk | บรอกก์ |
| hedin | หมอคนแคระเฮดิน |
| dvalin | ช่างเอกดวาลิน |
| thor_warp | เสาวาปแห่งธอร์ |

Each new animation has 16 distinct frames, 8 FPS, a 2-second loop. Sheets are 2048×2048, 4×4 cells of 512×512. The source generated sheets were 1254×1254 and have been cut, background-cleaned, aligned and resampled; the larger sheet size does not add source detail. PNGs have real alpha transparency. Frame origin for the soles/base is (256,472), equivalent to (0,216) from centered sprite origin. Includes standing PNGs, separate frame PNGs, and Godot SpriteFrames .tres.

Hans uses the established chapter 1 artwork and its original four selected Idle frames to preserve his identity. NPC interactions, quests, shops and dialogue remain as authored.

Prompts and exact reference paths: `output/npc_chapter2/prompts.json`. Source images: `output/npc_chapter2/originals`. Map backup: `output/npc_chapter2/nidavellir_town.before.tscn`. Animated preview: `output/npc_chapter2/idle_preview.webp`.
