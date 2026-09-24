extends Node
## รอบ 179 — หออิกดราซิล ชั้น 51-100
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
const Loot = preload("res://scripts/world/chapter8_loot.gd")
const Pattern = preload("res://scripts/entities/chapter8_pattern.gd")
const Checkpoint = preload("res://scripts/world/chapter8_checkpoint.gd")
var checks := 0
var fails := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		print("FAIL: ", message)

func snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func _ready() -> void:
	SaveManager.end_session()
	PlayerState.new_game()
	Tower.gm_test = false
	check(Tower.FLOOR_COUNT == 100, "100 floors")
	check(Tower.THEMES.size() == 20 and Tower.NEW_IDS.size() == 20 and Tower.NEW_NAMES.size() == 20 and Tower.SKILL_NAMES.size() == 20, "20 themes/guardians")
	check(Tower.UPPER_PACKS.size() == 16, "upper packs 16")
	check(Loot.GEAR.size() == 20 and Loot.GUARDIANS.size() == 20, "loot tables 20")
	PlayerState.set_flag(&"chapter7_done")
	var old_hp := 0
	for n in range(1, 101):
		check(Game.MAPS.has(Tower.floor_id(n)) and ResourceLoader.exists(Game.MAPS[Tower.floor_id(n)]), "floor scene %d" % n)
		check(MapAtlas.MAPS.has(Tower.floor_id(n)), "atlas %d" % n)
		if n > 50:
			var scene = load(Game.MAPS[Tower.floor_id(n)]).instantiate()
			check(scene.floor_number == n and scene.map_id == Tower.floor_id(n), "scene fields %d" % n)
			check(Game.map_display_name(Tower.floor_id(n)) == "อิกดราซิล ชั้น %d" % n, "map name %d" % n)
			scene.free()
		for w in range(Tower.wave_sizes(n).size()):
			for id in Tower.wave_roster(n, w):
				check(ResourceLoader.exists("res://data/monsters/%s.tres" % id), "wave monster %s @%d" % [id, n])
		var bosses := Tower.boss_roster(n)
		for id in bosses: check(ResourceLoader.exists("res://data/monsters/%s.tres" % id), "boss %s @%d" % [id, n])
		if n % 5 == 0: check(Tower.NEW_IDS[Tower.theme(n)] in bosses, "guardian on %d" % n)
		var src := MonsterData.new(); src.id = &"poring"; src.max_hp = 100
		var e := Tower.make_enemy(src, n, false)
		check(e.max_hp > old_hp, "HP monotonic %d" % n)
		old_hp = e.max_hp
		check(e.level == 110 + n, "level %d" % n)
		PlayerState.set_flag(Tower.clear_flag(n))
		if n < 100: check(Tower.can_enter(n + 1), "unlock %d" % (n + 1))
	# ผู้คุมใหม่
	for i in range(10, 20):
		var id: String = Tower.NEW_IDS[i]
		var floor := (i + 1) * 5
		var boss := GameData.get_monster(StringName(id))
		check(boss != null and boss.sprite_frames != null and boss.sprite_frames.get_frame_texture(&"Idle", 0) != null, "guardian art " + id)
		var gear := GameData.get_item(StringName(Loot.GEAR[i]))
		check(gear != null and gear.is_equipment() and gear.icon != null and gear.card_slots == 2, "gear " + Loot.GEAR[i])
		var card := GameData.get_item(StringName("card_" + id)) as CardData
		check(card != null and card.illustration != null and card.icon != null and card.rarity == 5, "card " + id)
		check(CardAlbum.BONUS.has(StringName("card_" + id)), "album bonus " + id)
		var e := Tower.make_enemy(boss, floor, true, true)
		check(e.skill_cooldown == 11.0 and e.skill_damage_mult >= 3.0, "guardian skill tuning " + id)
		var found := false
		for d in Loot.table(boss, floor, true):
			check(Loot.allowed(d.item_id), "allowed drop %s" % d.item_id)
			if d.item_id == gear.id: found = is_equal_approx(d.chance, 8.0)
		check(found, "gear 8% " + id)
		for rage in [false, true]:
			for x in [200.0, 2100.0, 4000.0]:
				var zones := Pattern.layout(i, x, 2600, 1, rage)
				var second := 0
				for z in zones:
					check(z.at >= 1.35 and z.at < 12.0, "pattern timing %s %.2f" % [id, z.at])
					if z.has("show"):
						second += 1
						check(z.at - z.show >= 1.3, "second-part warning ≥1.3s " + id)
				check(zones.size() >= 5 and second >= 2, "combo zones " + id)
		GameData.release_monsters_except([])
	check(Loot.WEAPONS.has(&"c8_spear_valkyrie") and Loot.WEAPONS.has(&"c8_hammer_shadow"), "weapons 75/100")
	for w in ["c8_valkyrie_spearblade", "c8_hammerfall_blade"]:
		var it := GameData.get_item(StringName(w))
		check(it != null and it.equip_texture != null and it.atk >= 740, "weapon " + w)
	# เควส
	var prev := "c8_10_dawn"
	for q in ["c8_11_thunder", "c8_12_clouds", "c8_13_bridge", "c8_14_prison", "c8_15_valkyrie", "c8_16_hour", "c8_17_chronicle", "c8_18_roots", "c8_19_lies", "c8_20_gate"]:
		var qd = load("res://data/quests/%s.tres" % q)
		check(qd != null and qd.required_quests.has(StringName(prev)) and qd.dialog_offer.length() > 40 and not qd.dialog_offer.contains("\\n"), "quest " + q)
		prev = q
	check(load("res://data/quests/c8_20_gate.tres").set_flag_on_complete == &"chapter8_done", "chapter ends at 100")
	check(load("res://data/quests/c8_10_dawn.tres").set_flag_on_complete != &"chapter8_done", "50 is midpoint")
	var root = load("res://scenes/maps/yggdrasil_root.tscn").instantiate()
	var svala = root.get_node("Svala")
	check(svala.quest_ids.size() == 20 and svala.quest_ids.has(&"c8_20_gate"), "svala quests 20")
	root.free()
	check(Checkpoint.destinations().size() == 40, "checkpoints 1 + x1/x5 → %d" % Checkpoint.destinations().size())
	check(CardAlbum.CHAPTER_SETS.size() == 9 and ((CardAlbum.CHAPTER_SETS as Array)[8]["cards"] as Array).size() == 10, "card set 51-100")
	# ── เล่นจริง: ชั้น 51 55 75 100 (GM ไม่บันทึก แล้วทดสอบจบชั้นจริง) ──
	PlayerState.new_game()
	PlayerState.set_flag(&"chapter7_done")
	PlayerState.stats.job_id = &"ninth_edge"
	PlayerState.stats.level = 190
	PlayerState.stats.base_vit = 250
	PlayerState.refresh()
	for n in range(1, 100): PlayerState.set_flag(Tower.clear_flag(n))
	Tower.gm_test = true
	for number in [51, 65, 100]:
		var map = load(Game.MAPS[Tower.floor_id(number)]).instantiate()
		add_child(map)
		await get_tree().process_frame
		map.player.set_physics_process(false)
		var stages := Tower.wave_sizes(number).size() + 1
		for wave in range(stages):
			for child in map.get_children():
				if child is Timer and child != map.transition_timer:
					child.stop(); child.timeout.emit()
			await get_tree().process_frame
			var alive := 0
			for actor in map.enemy_container.get_children():
				if actor.is_in_group("enemy") and not actor.is_dead():
					alive += 1
					if wave == stages - 1 and number == 100 and actor.data.get_meta("tower_guardian", false):
						# ให้ผู้คุมร่ายท่าผสม 1 ครั้งแล้วถ่ายภาพ
						actor.global_position.x = map.player.global_position.x + 700
						actor._skill_cd = 0
						actor._tower_cast(Tower.NEW_IDS.find(String(actor.data.get_meta("tower_source"))))
						await get_tree().create_timer(0.6).timeout
						await snap("/tmp/r179_f100_warn1.png")
						await get_tree().create_timer(2.3).timeout
						await snap("/tmp/r179_f100_hit1.png")
						await get_tree().create_timer(1.4).timeout
						await snap("/tmp/r179_f100_warn2.png")
					actor.set_physics_process(false)
					actor.take_damage(actor.hp + 1)
			var roster: Array = Tower.wave_roster(number, wave) if wave < stages - 1 else Tower.boss_roster(number)
			var loadable := 0
			for id in roster:
				if GameData.get_monster(StringName(id)) != null: loadable += 1   # คลาวด์ไม่มีภาพมอนบางตัว (สภาพแวดล้อม)
			check(alive == loadable and loadable > 0, "alive count %d w%d (%d/%d)" % [number, wave, alive, loadable])
			if alive == 0 and map.living > 0:
				map.living = 1
				map._enemy_died(null, null)
			if wave == 0 and number == 65: await snap("/tmp/r179_f65.png")
			map._advance_encounter()
			await get_tree().process_frame
		check(map.cleared, "cleared %d" % number)
		Tower.gm_test = false
		map.cleared = false
		map._complete_floor()
		check(PlayerState.has_flag(Tower.clear_flag(number)), "clear flag %d" % number)
		if number == 100:
			check(PlayerState.has_flag(&"c8_ascent100_done"), "summit flag")
			check(map.next_portal.target_map == &"yggdrasil_root", "summit portal to root")
			await snap("/tmp/r179_f100_clear.png")
		Tower.gm_test = true
		map.queue_free()
		await get_tree().process_frame
		GameData.release_monsters_except([])
	Tower.gm_test = false
	print("R179 %d checks · fails %d" % [checks, fails])
	print("R179 DONE")
	get_tree().quit()
