# Mobile UI and web stability review — 2026-09-15

## Evidence and limits
- User device: Samsung S23 Ultra; browser tab reloads itself during play. Exact browser/version and device crash logs are unavailable.
- Live https://aholicaz.github.io/shadows-of-fate/ responded HTTP 200. Its HTML declares index.pck=479,884,364 bytes (457.7 MiB), index.wasm=39,509,339 bytes (37.7 MiB). The live build is much larger than the old local build/web/index.pck (106,626,668 bytes). Do not confuse the local build with deployment.
- Live desktop browser reached the canvas without warning/error logs at the sampled time. This does not reproduce or rule out mobile memory exhaustion.
- Source scene texture estimates are in output/mobile_ui/map_texture_estimates.json. Giant Steppe references ~1,456 MiB of RGBA texture pixels; Broken Wall ~1,416 MiB; Frozen Hall ~1,210 MiB. These estimates count unique statically referenced source textures per scene, not actual measured RAM/VRAM, and exclude dynamically loaded assets, mipmaps and engine overhead. Desktop BC7 and web Lossy have different memory costs.
- Hosting affects download speed; the current evidence points toward client memory/rendering pressure as a significant risk. No claim that the mobile reload is conclusively fixed.

## Changes
- NPC name font 21 → 28; quest title 18 → 24; objectives/completion 14 → 20 with wrapping.
- Menu captions 11 → 18, icons 28 → 36, button area 72×62 → 84×82; dependent map placement follows menu height.
- Eight persistent skill slots in two banks of four. T or the on-screen bank button switches banks. Keys 1–4 and configured right-click slot use the active bank; icons and cooldowns read the same mapping. Switching releases held touch actions and does not reset cooldowns. Old four-slot saves populate the first bank; second bank starts empty.
- Skill window shows two rows of four assignable slots, labeled by bank. Secret profession remains ??? until unlocked.
- Potion buttons moved above skill 1, enlarged 48 → 56 logical pixels, retaining the touch scale. Minimap moves left if it intersects the potion row. Clock moved to lower center.
- Circular buttons use circular hit regions to avoid rectangular corner overlap.
- Ground item art is doubled in linear size; labels lifted and enlarged. Cards use their illustration, falling back to icon/generic card art, with a lightweight animated golden halo. Pickup distance is unchanged.
- Release GameData monster cache after unloading the old scene and BEFORE loading the next map. Existing post-load cleanup remains.
- On web/mobile, SpriteFit warm-up releases CPU image copies after each animation rather than retaining every animation sheet until the end of the actor warm-up. Measurement results remain cached; source art and frame coordinates are unchanged.
- Exclude build/ and shadows-of-fate-planner-site/ from Web export. The separate planner site's files (~51 MiB on disk, not all necessarily export resources) remain intact; its .gdignore prevents Godot importing its duplicate art. Actual PCK reduction must be measured after re-export.

## Validation
Focused test: mobile_ui_test.tscn / scripts/tools/mobile_ui_test.gd.
Checks legacy save migration, eight-slot round trip, cross-bank uniqueness, bank touch switching, drop size/card classification, button bounds and hit-shape overlaps, and potion/minimap separation at 1280×720 in desktop and touch modes. Renders desktop, touch and skill-window previews.
Outputs: output/mobile_ui/{desktop,mobile,skill_window}.png and output/mobile_ui_render.log.
The local Godot Steam test environment reports certificate-store/shader-cache access errors; these are separate from test assertions and are not evidence about the user's mobile browser. No on-device mobile profiling was performed.

## Recommended next steps
1. Export and publish these changes, measure new PCK size and reproduce on S23 Ultra with browser name/version and map/action recorded.
2. Compare a native Android build on the same device. Godot documents that native Android/iOS builds significantly outperform web exports: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
3. Add an optional mobile effects preset (ambient layers, particles, shadows) and compare frame times during combat. Keep combat telegraphs visible.
4. Audit unused export resources and consider texture compression variants only with visual/device verification. Do not blanket-resize sheets: atlas frame coordinates must remain correct.

Changes are local. No commit, push, export replacement or deployment was performed in this task.
