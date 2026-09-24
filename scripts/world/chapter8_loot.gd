extends RefCounted
## Deliberate allowlist: never inherit campaign junk, potions or quest materials.
const GEAR := ["c8_root_cuirass", "c8_storm_boots", "c8_mirror_mantle", "c8_name_ring", "c8_hour_crown", "c8_tide_pendant", "c8_sun_plate", "c8_astral_circlet", "c8_void_cloak", "c8_crown_aegis",
	"c8_thunder_mail", "c8_cloud_striders", "c8_prism_mantle", "c8_chain_signet", "c8_valkyrie_helm", "c8_eon_pendant", "c8_chronicle_plate", "c8_rotroot_circlet", "c8_liar_veil", "c8_gate_aegis"]   # ★ รอบ 179 ★ ชั้น 55-100
const GUARDIANS := ["c8_root_jailer", "c8_storm_cantor", "c8_mirror_hunter", "c8_name_eater", "c8_hour_warden", "c8_tide_oracle", "c8_sunforged_lion", "c8_astral_archivist", "c8_void_weaver", "c8_crown_seraph",
	"c8_thunder_herald", "c8_cloud_shepherd", "c8_bifrost_warden", "c8_forgotten_jailer", "c8_spear_valkyrie", "c8_last_hour", "c8_ash_scribe", "c8_rot_gnawer", "c8_lie_weaver", "c8_hammer_shadow"]
const STONES := [&"phracon", &"emveretarcon"]
const WEAPONS := {&"c8_sunforged_lion": &"c8_solar_fang", &"c8_crown_seraph": &"c8_dawn_crown_blade",
	&"c8_spear_valkyrie": &"c8_valkyrie_spearblade", &"c8_hammer_shadow": &"c8_hammerfall_blade"}

static func allowed(id: StringName) -> bool:
	var item := GameData.get_item(id)
	return item != null and (item.is_equipment() or item.is_card() or id in STONES)

static func entry(id: StringName, chance: float, amount := 1) -> DropEntry:
	var drop := DropEntry.new()
	drop.item_id = id
	drop.chance = chance
	drop.max_count = amount
	return drop

static func table(source: MonsterData, floor_number: int, boss: bool) -> Array[DropEntry]:
	var drops: Array[DropEntry] = []
	var card := StringName("card_" + String(source.id))
	if GameData.get_item(card) != null:
		drops.append(entry(card, 5.0 if boss else 0.5))
	var guardian := GUARDIANS.find(String(source.id))
	if guardian >= 0:
		drops.append(entry(StringName(GEAR[guardian]), 8.0))   # ★ รอบ 153 ★ 18 → 8 (บอสดรอปอุปกรณ์ 5-8%))
		if boss and WEAPONS.has(source.id):
			drops.append(entry(WEAPONS[source.id], 8.0))   # ★ รอบ 153 ★ 10 → 8)
	else:
		# Preserve recognizable equipment only; cap chance so campaign tables cannot flood bags.
		for original in source.drops:
			var item := GameData.get_item(original.item_id)
			if item != null and item.is_equipment():
				drops.append(entry(original.item_id, minf(original.chance, 8.0 if boss else 1.5)))
	drops.append(entry(&"phracon", 65.0 if boss else 5.0, 2 if boss else 1))
	drops.append(entry(&"emveretarcon", (25.0 + floor_number * 0.5) if boss else (1.0 + floor_number * 0.06), 2 if boss and floor_number >= 25 else 1))
	return drops
