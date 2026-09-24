extends Node
## รอบ 164 — First Aid เป็นพาสซีฟ ยาแรงขึ้น 5%/เลเวล (สูงสุด 10)
var fails := 0
var passes := 0
func ok(c: bool, m: String) -> void:
	if c: passes += 1; print("  PASS ", m)
	else: fails += 1; print("  FAIL ", m)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	await get_tree().process_frame
	SaveManager.end_session()
	PlayerState.new_game()
	UI.set_in_game(true)
	var s := GameData.get_skill(&"first_aid")
	ok(s.type == SkillData.SkillType.PASSIVE and s.max_level == 10, "First Aid = พาสซีฟ · เลเวลสูงสุด 10")
	ok(is_equal_approx(float(s.passive_values(1)["potion_heal_percent"]), 5.0) and is_equal_approx(float(s.passive_values(10)["potion_heal_percent"]), 50.0), "Lv1 +5% · Lv10 +50%")
	var red := GameData.get_item(&"red_potion")
	var blue := GameData.get_item(&"blue_potion")
	ok(int(PlayerState.potion_heal_amounts(red).hp) == red.heal_hp, "ยังไม่เรียน = ยาแดงฟื้น %d" % red.heal_hp)
	var cd0 := PlayerState.potion_cooldown_of(red)
	PlayerState.skills.learned[&"first_aid"] = 10
	PlayerState.refresh()
	ok(is_equal_approx(PlayerState.potion_heal_bonus_percent(), 50.0), "โบนัส 50%")
	var want := int(round(red.heal_hp * 1.5))
	ok(int(PlayerState.potion_heal_amounts(red).hp) == want, "ยาแดงฟื้น %d (%d×1.5)" % [want, red.heal_hp])
	ok(int(PlayerState.potion_heal_amounts(blue).sp) == int(round(blue.heal_sp * 1.5)), "ยาน้ำเงิน SP ×1.5 = %d" % int(PlayerState.potion_heal_amounts(blue).sp))
	ok(is_equal_approx(PlayerState.potion_cooldown_of(red), cd0), "คูลดาวน์ยาเท่าเดิม %.1f" % cd0)
	# กินจริง
	PlayerState.stats.hp = 1
	PlayerState.inventory.add_id(&"red_potion", 1)
	var idx := -1
	for i in PlayerState.inventory.size:
		var it := PlayerState.inventory.get_slot(i)
		if it != null and it.item_id == &"red_potion": idx = i
	var hp0: int = PlayerState.stats.hp
	PlayerState.use_item(idx)
	ok(PlayerState.stats.hp - hp0 == mini(want, PlayerState.stats.max_hp - hp0), "กินยาแดงจริง +%d" % (PlayerState.stats.hp - hp0))
	ok(PlayerState.potion_cooldown_left(&"hp") <= cd0 + 0.01, "คูลดาวน์หลังกิน %.2f ≤ %.2f" % [PlayerState.potion_cooldown_left(&"hp"), cd0])
	# เลเวล 5 (เซฟเก่า) = +25% · อัปต่อได้
	PlayerState.skills.learned[&"first_aid"] = 5
	PlayerState.refresh()
	ok(is_equal_approx(PlayerState.potion_heal_bonus_percent(), 25.0), "เซฟเก่า Lv5 = +25%")
	# ปุ่มลัดเซฟเก่า
	var d: Dictionary = PlayerState.skills.to_dict()
	d["hotkeys"] = ["first_aid", "bash", "", "", "", "", "", ""]
	PlayerState.skills.from_dict(d)
	ok(PlayerState.skills.hotkeys[0] == &"" and PlayerState.skills.hotkeys[1] == &"bash", "ถอด First Aid ออกจากปุ่มลัด (bash อยู่)")
	# ข้อความหน้าสกิล/ไอเทม
	var txt := SkillWindow.describe(s, 5)
	ok(txt.contains("แรงขึ้น +25%") and not txt.contains("ใช้ SP"), "หน้าสกิล: %s" % txt.get_slice("\n", 3))
	var pop := ""
	if UI.item_popup.has_method("describe"):
		pop = UI.item_popup.describe(red, null)
	ok(pop == "" or pop.contains("ปฐมพยาบาล +25%"), "กล่องไอเทมบอกฟื้นจริง")
	print("R164 RESULT: %d pass · %d fail" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)
