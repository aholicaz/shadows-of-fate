# Boss card and item artwork refresh — 2026-09-22

All 18 cards whose source MonsterData has `is_boss = true` now use gold/bronze frames and ruby details. Full illustrations are 640×960 RGBA under `Sprites/card/boss_gold/`; inventory icons are 256×256 RGBA under `Sprites/items/boss_gold/`. Normal cards retain their existing artwork. IDs, stats, rarity values, sockets, prices and drops were not changed.

Six cards previously had only 256×256 inventory images with a small portrait inside: Chained Garm, False Judge, Light Forsaken, Radiant Alfr, Stone Hrungnir and Wall Shieldbearer. New high-resolution illustrations were generated from their existing identities and scenes rather than enlarging their pixels. Other boss artwork was retained and composited with the generated gold frame.

## Mockup audit

Reviewed all 273 non-card item resources and 68 card resources. The `placeholder` directory name does not indicate unfinished artwork: most images there are finished paintings. One remaining letter tile (`book_seven_half_2`) and six simple socket crystal SVG icons were replaced with painted transparent 256×256 PNGs in `Sprites/items/final/`:

- book_seven_half_2: torn chronicle pages, covenant sun/hammer seal and an erased name, matching its description.
- socket_shard_1 / socket_stone_1: amber fire mineral fragments and complete socket stone.
- socket_shard_2 / socket_stone_2: cyan fragments and complete socket stone.
- socket_shard_3 / socket_stone_3: violet fragments and complete socket stone.

Original assets remain available; only resource texture references changed. Before-resource copies and generation sources are under `output/art_refresh/`. `compose.py` records frame extraction/compositing and icon resizing, using the user's existing permission for frame composition, background removal and resizing.

## Generation instructions

Built-in imagegen was used. Shared frame prompt: portrait 2:3 narrow angular polished gold border, bronze recesses, ruby top/bottom diamond jewels, transparent center and outside corners, no text. The generated center needed deterministic removal using its measured contour.

Card reconstruction prompt: preserve the existing creature identity, equipment, pose and scene; reconstruct sharp painted fantasy detail at 1024×1536; gold frame, ruby jewels, exact English monster title; no stats or extra text. Existing small card images were references.

Item prompt: single centered painted fantasy RPG inventory object, strong silhouette, crystalline material detail or weathered parchment/leather, genuine alpha, no background/UI/text; then contain-resize to 236px inside a 256px canvas. Shards use a broken three-crystal cluster; whole stones use a pointed hexagonal crystal with dwarven socket rune.

Generated image IDs are recorded in `output/art_refresh/generated.json`. Frame source ID: `76d07b9f-0019-41a9-9a54-fbbc429501fa`.

## Verification

- Resource comparison confirmed gameplay properties unchanged across 25 edited resources.
- All 44 new PNGs, including the reusable frame, have genuine alpha and expected dimensions (`output/art_refresh/final_audit.json`).
- Godot render review loaded all 341 item/card icons, verified all 18 gold card illustrations and 7 replacement icons, and produced `output/art_refresh/godot_review.png`.
- Final runtime review passed without script/resource errors. Sandbox warnings about shader cache and root certificates remain. No player save was loaded or written.
