# Hall of Silence / Cold Forge

Final user preference: keep the original shallow walkway. Hall uses its original 4800 × 1400 final background unchanged. Its latest authored collision shape (42px high, local Y=-113) and portal positions are preserved. The widened-floor study is retained only in this ignored output folder.

Cold Forge now uses `Sprites/map/generated/cold_forge_bg_final.png`, 3200 × 1300 with 1:1 UVs. Back of walkway is image Y=980; front lip is Y=1080 (world Y=880), matching the existing collision floor. Original spawns, bounds and portals remain intact.

Artwork was made with built-in image_gen, then registered and assembled from three overlapping detail tiles (1280 × 1300, starts 0/960/1920). A minimum-difference seam with 32px feathering joins tiles. `build_maps.ps1 -Final` rebuilds the selected final asset. `prompts.json` contains the exact prompt set, including the discarded wide-floor study. `sources/` retains generated originals and pre-edit scene snapshots.

Quest support:
- Hall: an optional readable FamilyTools point at the existing inherited-tool rack, consistent with Dvalin's C2-5 dialogue; existing objectives and rewards remain unchanged.
- Cold Forge: five forge golems now spawn through the existing MapSpawner, fulfilling C2-6's previously missing roster.
- Guardian remains at X=2500; HammerBlueprint moves from X=1500 to X=2650, at the actual engraved wall beyond the boss. Existing `hammer_blueprint` ID, boss flag gate and C2-8 READ objective remain unchanged.
- Engraved hammer rune circuits and a root-filled fissure visually support C2-8 and the chapter 3 exit. The exit still requires `chapter2_done`.

MapAmbientFX adds optional moving mist, drifting embers and animated rune glow masked from the actual background texture. Cold Forge now has a map-local CanvasModulate (0.14, 0.155, 0.20) and stronger 430px-radius lantern lights (energy 2.2) affecting background, player, enemies and boss. Ceiling shafts and rune self-glow are disabled there so lanterns remain the light sources; the blueprint text is still gated by LoreObject. Hall and Ember retain their existing ambient light.

`cold_forge_darkness_test.tscn` renders the actual player, golem and guardian with lantern lighting on/off, checks brightness changes when entering a lantern area, and verifies that exiting to Hall removes the darkness. The CanvasModulate belongs to the Cold Forge scene, not an autoload, and is released with that scene. Adjust Darkness.color for the ambient level and AmbientFX.light_radius/light_energy for lantern reach/strength.

Validation: `chapter2_map_test.tscn` runs both real maps, six standing samples, 480 walking frames, actual golem/boss spawn and death events, locked/unlocked lore dialogue, READ quest progress and chapter exit flag. Test instances freeze and hide monster combat during screenshots and never save player state. Runtime screenshots and logs are in this folder.

Godot editor still reports the pre-existing malformed `_to_delete/npc_lines.csv` translation import; it is unrelated to these runtime assets.
