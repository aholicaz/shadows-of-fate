# Map artwork workflow established in Chapters 3–4

Use this sequence for later chapters. Read the current map scenes, NPC dialogue,
story variants and monster resources before generating anything.

1. Inventory map IDs, collision floor, bounds, portals, NPCs, lore and light/dim groups. Preserve saved IDs and quest flags.
2. Generate each distant parallax painting first, showing the complete upper composition. Give each location its own materials, lighting and mood.
3. Use that painting plus the approved sharp painted road as references for a unified road, rear bank, roots/rocks/buildings and lower foundation. No detached curb with floating props. Keep a broad straight walk band with readable large shapes.
4. Inspect source images before resizing. Reject grainy narrow road strips, baked checkerboards, cropped roofs and mismatched materials. Preserve opaque pale surfaces when removing the outside matte.
5. Register the painted walk plane to the actual collision surface. Keep scenery and NPC soles behind the active movement lane. Compose adjacent textures with matching material seams; no broad blurry crossfades or repeated mirrored architecture.
6. Make city buildings distinct by NPC role. Door size must fit the inhabitants. Keep portals visually separated and preserve their destinations.
7. Bake static scenery and unique lore landmarks into the same foreground. Retain NPCs and story-dependent objects as dynamic nodes. Never bake a character that must disappear with a flag.
8. NPCs face the camera; monsters face left. Use real alpha, consistent body size and registered animation feet. A breathing transform is procedural idle, not a claim of frame animation.
9. Integrate final assets under Sprites, with references in project scenes/resources. Keep prompts, sources, candidate comparisons and test outputs under output. Prefer compressed map textures and bounded particle counts.
10. Render all map regions at normal and wide aspect ratios; inspect actual-size feet, road detail, roots, roof silhouettes, shadows and seams. Test full traversal, NPC reachability, story variants and existing portal mappings. Fix poor results before delivery.

Built-in imagegen is the generation path. Deterministic matte cleanup, resizing
and compositing use the user's explicit continuing authorization for this workflow.
Do not change combat balance or save IDs merely to replace art.

Reference implementation: output/chapter4_organic/README.md and its preparation,
integration, movement, visual and variant checks.

## Chapters 5–6 refinements

- Monster delivery is now **one standalone left-facing idle illustration per species**, not an animation sheet. Preserve native detail above 1000 pixels and place the subject on a 1792-square transparent canvas with at least 15% margin on every side (about 30% combined). Do not upscale a 512px source. Keep a separate runtime copy; a repeated standing texture is not frame animation.
- For an open bridge, retain alpha in the lower arches and extend the distant parallax to the bottom of the viewport. Do not cover it with an opaque repeated foundation.
- Check generated alpha numerically and inspect on a contrasting solid background. Reject baked checkerboards; remove chroma spill around roots, fine fur and enclosed holes before integration.
- Chapter 6 keeps dynamic story interactions under their original nodes. Hide only the point's own placeholder drawing with `self_modulate`, preserving its label, action and children. Baked walls/throne remain scenery; chains and the freed hound respond to existing flags.
- Latest implementation and evidence: `output/chapter6_organic/README.md`.
