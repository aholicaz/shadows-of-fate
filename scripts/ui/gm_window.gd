## GMWindow — หน้าต่างเครื่องมือทดสอบ (รอบ 80)
##
## ★ เปิดด้วยปุ่ม F10 ได้ทุกที่ในเกม ★ (หรือ Events.toggle_window.emit(&"gm"))
##
## 4 แท็บ:
##   มอน      — ค้นหา/เรียกมอนมาเกิดตรงหน้า · ลบมอนทั้งแมพ · ตั้งเลเวลมอนชั่วคราว
##   ไอเทม    — ค้นหา/ใส่ของลงกระเป๋าทีละกี่ชิ้นก็ได้ · ชุดของที่ใช้บ่อย
##   ตัวละคร  — ตั้งเลเวล/เลเวลอาชีพ · ★ รอบ 106: เปลี่ยนอาชีพ (นักดาบ/Runeblade/Ninth Edge) + ปลดล็อกรูน ★ · เติมเลือด/มานา/แต้ม/ซีนี · อมตะ · ตีทีเดียวตาย
##   ระบบ     — วาปไปแมพไหนก็ได้ (รวมห้อง GM) · ตั้งธงเนื้อเรื่องรายบท · ล้างของตก
##
## ทั้งหมดทำงานผ่าน PlayerState/GameData ปกติ ไม่มีอะไรพิเศษที่เกมจริงไม่ใช้
class_name GMWindow
extends GameWindow

## ชุดของที่กดทีเดียวได้ครบ (id, จำนวน)
const QUICK_KITS := {
	"ยาครบชุด x99": [["red_potion", 99], ["orange_potion", 99], ["white_potion", 99], ["blue_potion", 99]],
	"หินตีบวก x99": [["phracon", 99], ["emveretarcon", 99]],
	"ของเควสบท 1-3": [["glow_shard", 1], ["hunter_journal", 1], ["burnt_bark_piece", 3],
		["vanir_seal", 1], ["spring_vial", 1], ["frida_song", 1], ["eskil_chronicle", 1]],
	"ปีกวาลคีรี x50": [["wing_of_valkyrie", 50]],
	# ★ รอบ 106 ★ ของเควสบท 4-6 (ตราเมือง · ผ้าพันคอเด็กยักษ์ (แมมมอธ/เอลฟ์กลวงสงบ) · สิ่วเกอร์ด (พิธี Ninth Edge) · ผลึกเงา (ร่างมืดบท 5) · สมุดเล่มเจ็ด)
	"ของเควสบท 4-6": [["jotun_seal", 1], ["giant_child_scarf", 1], ["gerd_chisel", 1], ["mural_fragment", 1],
		["light_seal", 1], ["shade_crystal", 1], ["light_crystal", 1], ["hel_seal", 1], ["judge_seal", 1],
		["book_seven_half", 1], ["book_seven_half_2", 1], ["book_seven_complete", 1]],
}
## ★ รอบ 106 ★ ลำดับอาชีพในเมนูเปลี่ยนอาชีพ (อาชีพอื่นที่มีไฟล์ data/jobs/ ต่อท้ายอัตโนมัติ)
const JOB_ORDER: Array[StringName] = [&"novice", &"swordsman", &"runeblade", &"ninth_edge"]
## ธงที่ต้องมีเพื่อให้สกิลรูนทุกท่าเรียนได้ (ดู SkillBook.RUNE_SKILL_FLAGS + rune_points)
const RUNE_UNLOCK_FLAGS: Array[StringName] = [&"rb_rune_4", &"rb_rune_5", &"rb_rune_6", &"rb_rune_7"]
## ธงเนื้อเรื่องที่กดเปิด/ปิดได้ (ป้าย, ธง)
const STORY_FLAGS := [
	["บท 2 เปิด", "chapter2_open"], ["บท 2 จบ", "chapter2_done"],
	["บท 3 เคยไป", "chapter3_visited"], ["บท 3 จบ", "chapter3_done"],
	["ดูพิธี M6", "saw_ceremony"], ["ล้มอสูรสายฟ้า", "killed_stormscar"],
	["ล้มผู้พิทักษ์", "killed_forge_guardian"], ["ล้มราชินีหนาม", "killed_thorn_matriarch"],
	["ล้มกุลล์ไวก์", "killed_gullveig_ember"],
	# ★ รอบ 106 ★ บท 4-6
	["บท 4 เคยไป", "chapter4_visited"], ["บท 4 จบ", "chapter4_done"],
	["บท 5 เคยไป", "chapter5_visited"], ["บท 5 จบ", "chapter5_done"],
	["บท 6 เคยไป", "chapter6_visited"], ["บท 6 จบ", "chapter6_done"],
	["ผลึกเงา (ร่างมืดบท 5)", "has_shade_crystal"], ["ทิ้งชื่อแล้ว (กยอลล์)", "name_left"],
	["ล้มหรุงนีร์", "killed_stone_hrungnir"], ["ล้มดาเกอร์", "killed_radiant_alfr"],
	["การ์มจบแล้ว", "garm_resolved"], ["ปล่อยการ์ม", "freed_garm"],
	["ร่องรอยอาชีพ 3", "rb_next_job_hint"], ["Lv90 พร้อมอาชีพ 3", "rb_next_job_ready"],
]

var _mon_ids: Array[StringName] = []
var _item_ids: Array[StringName] = []
var _mon_list: ItemList
var _item_list: ItemList
var _mon_search: LineEdit
var _item_search: LineEdit
var _mon_count: SpinBox
var _item_count: SpinBox
var _level_box: SpinBox
var _job_box: SpinBox
var _job_option: OptionButton        # ★ รอบ 106 ★
var _job_ids: Array[StringName] = []
var _unlock_check: CheckBox
var _god_check: CheckBox
var _onehit_check: CheckBox
var _map_option: OptionButton
var _info: Label
var _flag_boxes: Dictionary = {}      # ธง -> CheckBox


func _init() -> void:
	window_title = "★ ห้อง GM — เครื่องมือทดสอบ (F10) ★"
	custom_minimum_size = Vector2(520, 520)


func _build_content() -> void:
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(500, 430)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(tabs)

	_build_monster_tab(_tab(tabs, "มอน"))
	_build_item_tab(_tab(tabs, "ไอเทม"))
	_build_player_tab(_tab(tabs, "ตัวละคร"))
	_build_system_tab(_tab(tabs, "ระบบ"))

	_info = UITheme.make_label("", 13, UITheme.TEXT_DIM)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_info)


func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = title
	box.add_theme_constant_override("separation", 6)
	tabs.add_child(box)
	return box


func _row(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	parent.add_child(h)
	return h


func _button(parent: Control, text: String, fn: Callable, width: float = 0.0) -> Button:
	var b := UITheme.make_button(text, width)
	b.pressed.connect(fn)
	parent.add_child(b)
	return b


# =========================================================
# แท็บ "มอน"
# =========================================================
func _build_monster_tab(box: VBoxContainer) -> void:
	box.add_child(UITheme.make_label("เรียกมอนมาเกิดข้างหน้าตัวละคร (ห่าง 320 px)", 13, UITheme.TEXT_DIM))

	_mon_search = LineEdit.new()
	_mon_search.placeholder_text = "ค้นหาชื่อ/ไอดีมอน..."
	_mon_search.text_changed.connect(func(_t): _fill_monsters())
	box.add_child(_mon_search)

	_mon_list = ItemList.new()
	_mon_list.custom_minimum_size = Vector2(0, 230)
	_mon_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mon_list.item_activated.connect(func(_i): _spawn_selected())
	box.add_child(_mon_list)

	var r := _row(box)
	r.add_child(UITheme.make_label("จำนวน", 13))
	_mon_count = SpinBox.new()
	_mon_count.min_value = 1
	_mon_count.max_value = 20
	_mon_count.value = 1
	r.add_child(_mon_count)
	_button(r, "เกิดมอน", _spawn_selected, 110)
	_button(r, "ลบมอนทั้งแมพ", _clear_monsters, 130)


func _fill_monsters() -> void:
	if _mon_list == null:
		return
	var key := _mon_search.text.strip_edges().to_lower()
	_mon_list.clear()
	_mon_ids.clear()
	# ★ รอบ 90 ★ ห้อง GM ต้องเห็นครบทุกตัว จึงบังคับโหลดที่นี่
	# (ตอนเปิดเกมปกติมอนจะโหลดเฉพาะตัวที่แมพใช้ — ดู GameData.get_monster)
	var all: Dictionary = GameData.load_all_monsters()
	var ids: Array = all.keys()
	ids.sort_custom(func(a, b):
		var da: MonsterData = all[a]
		var db: MonsterData = all[b]
		return da.level < db.level)
	for id in ids:
		var d: MonsterData = all[id]
		var label := "Lv%-3d %s   (%s)%s" % [d.level, d.display_name, id, "  ★บอส" if d.is_boss else ""]
		if key != "" and not (key in String(id).to_lower() or key in d.display_name.to_lower()):
			continue
		_mon_list.add_item(label)
		_mon_ids.append(id)


func _selected_monster() -> MonsterData:
	var sel := _mon_list.get_selected_items()
	if sel.is_empty() or sel[0] >= _mon_ids.size():
		return null
	return GameData.get_monster(_mon_ids[sel[0]])


func _spawn_selected() -> void:
	var d := _selected_monster()
	if d == null:
		_say("เลือกมอนก่อน")
		return
	var map := get_tree().get_first_node_in_group("map")
	var player := get_tree().get_first_node_in_group("player")
	if map == null or player == null:
		_say("ต้องอยู่ในแมพก่อน")
		return
	var scene: PackedScene = load("res://scenes/monsters/monster.tscn")
	var n := int(_mon_count.value)
	var face: int = player.facing if "facing" in player else 1
	for i in range(n):
		var mob = scene.instantiate()
		mob.data = d
		mob.global_position = player.global_position + Vector2(face * (320.0 + i * 90.0), -40.0)
		map.add_child(mob)
		mob.set_home(mob.global_position)
	_say("เกิด %s x%d" % [d.display_name, n])


func _clear_monsters() -> void:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
		n += 1
	_say("ลบมอน %d ตัว" % n)


# =========================================================
# แท็บ "ไอเทม"
# =========================================================
func _build_item_tab(box: VBoxContainer) -> void:
	box.add_child(UITheme.make_label("ใส่ของลงกระเป๋าโดยตรง (ของเต็มสแต็กจะล้นทิ้ง)", 13, UITheme.TEXT_DIM))

	_item_search = LineEdit.new()
	_item_search.placeholder_text = "ค้นหาชื่อ/ไอดีไอเทม..."
	_item_search.text_changed.connect(func(_t): _fill_items())
	box.add_child(_item_search)

	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(0, 200)
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.item_activated.connect(func(_i): _give_selected())
	box.add_child(_item_list)

	var r := _row(box)
	r.add_child(UITheme.make_label("จำนวน", 13))
	_item_count = SpinBox.new()
	_item_count.min_value = 1
	_item_count.max_value = 99
	_item_count.value = 1
	r.add_child(_item_count)
	_button(r, "ใส่กระเป๋า", _give_selected, 110)

	box.add_child(UITheme.separator())
	box.add_child(UITheme.make_label("ชุดของที่ใช้บ่อย", 13, UITheme.ACCENT))
	var kits := _row(box)
	for kit_name in QUICK_KITS.keys():
		_button(kits, kit_name, func(): _give_kit(kit_name))


func _fill_items() -> void:
	if _item_list == null:
		return
	var key := _item_search.text.strip_edges().to_lower()
	_item_list.clear()
	_item_ids.clear()
	var ids: Array = GameData.items.keys()
	ids.sort()
	for id in ids:
		var d: ItemData = GameData.items[id]
		if key != "" and not (key in String(id).to_lower() or key in d.display_name.to_lower()):
			continue
		_item_list.add_item("%s   (%s)" % [d.display_name, id])
		_item_ids.append(id)


func _give_selected() -> void:
	var sel := _item_list.get_selected_items()
	if sel.is_empty() or sel[0] >= _item_ids.size():
		_say("เลือกไอเทมก่อน")
		return
	var id: StringName = _item_ids[sel[0]]
	var n := int(_item_count.value)
	var left := PlayerState.inventory.add_id(id, n)
	Events.inventory_changed.emit()
	var d := GameData.get_item(id)
	_say("ได้ %s x%d%s" % [d.display_name if d != null else id, n - left, "  (กระเป๋าเต็ม เหลือ %d)" % left if left > 0 else ""])


func _give_kit(kit_name: String) -> void:
	var got := 0
	for entry in QUICK_KITS[kit_name]:
		var id := StringName(entry[0])
		if GameData.get_item(id) == null:
			continue
		PlayerState.inventory.add_id(id, int(entry[1]))
		got += 1
	Events.inventory_changed.emit()
	_say("ใส่ชุด «%s» %d รายการ" % [kit_name, got])


# =========================================================
# แท็บ "ตัวละคร"
# =========================================================
func _build_player_tab(box: VBoxContainer) -> void:
	var r1 := _row(box)
	r1.add_child(UITheme.make_label("เลเวล", 13))
	_level_box = SpinBox.new()
	_level_box.min_value = 1
	_level_box.max_value = PlayerStats.MAX_LEVEL
	_level_box.value = 1
	r1.add_child(_level_box)
	r1.add_child(UITheme.make_label("อาชีพ", 13))
	_job_box = SpinBox.new()
	_job_box.min_value = 1
	_job_box.max_value = 100   # ★ รอบ 108 ★ เพดานจ๊อบสูงสุดของทุกอาชีพ (clamp จริงตามอาชีพใน _set_level)
	_job_box.value = 1
	r1.add_child(_job_box)
	_button(r1, "ตั้งเลเวล", _apply_level, 110)

	var r2 := _row(box)
	_button(r2, "+10 เลเวล", func(): _bump_level(10))
	_button(r2, "−10 เลเวล", func(): _bump_level(-10))
	_button(r2, "เลเวลสูงสุด", func(): _set_level(PlayerStats.MAX_LEVEL, PlayerState.stats.max_job_level()))
	_button(r2, "รีเซ็ตเป็น Lv1", func(): _set_level(1, 1))

	# ★ รอบ 106 ★ เปลี่ยนอาชีพ
	box.add_child(UITheme.separator())
	var rj := _row(box)
	rj.add_child(UITheme.make_label("เปลี่ยนอาชีพ", 13))
	_job_option = OptionButton.new()
	_job_option.custom_minimum_size = Vector2(230, 0)
	_fill_jobs()
	rj.add_child(_job_option)
	_button(rj, "เปลี่ยน", _apply_job, 90)
	var rj2 := _row(box)
	_unlock_check = CheckBox.new()   # ★ รอบ 108 ★ ธงรูนเป็นธงเนื้อเรื่องอย่างเดียวแล้ว — ช่องนี้ตั้งธงเควส RB8-RB14 ให้ (ไม่มีผลกับสกิล)
	_unlock_check.text = "ตั้งธงเควสรูน RB8-RB14 ให้ด้วย (เนื้อเรื่อง)"
	_unlock_check.button_pressed = true
	rj2.add_child(_unlock_check)
	_button(rj2, "ล้างสกิลทั้งหมด", func():
		PlayerState.skills.reset(PlayerState.stats)
		PlayerState.refresh()
		_say("ล้างสกิลแล้ว · แต้มสกิล %d" % PlayerState.stats.skill_points))

	box.add_child(UITheme.separator())
	var r3 := _row(box)
	_button(r3, "เต็มเลือด/มานา", func():
		PlayerState.revive(1.0) if PlayerState.is_dead() else null
		PlayerState.heal_hp(PlayerState.stats.max_hp)
		PlayerState.restore_sp(PlayerState.stats.max_sp)
		_say("เลือด/มานาเต็ม"))
	_button(r3, "+20 แต้มสเตตัส", func():
		PlayerState.stats.stat_points += 20
		Events.stats_changed.emit()
		_say("แต้มสเตตัส %d" % PlayerState.stats.stat_points))
	_button(r3, "+10 แต้มสกิล", func():
		PlayerState.stats.skill_points += 10
		Events.skills_changed.emit()
		_say("แต้มสกิล %d" % PlayerState.stats.skill_points))

	var r4 := _row(box)
	_button(r4, "+100,000 ซีนี", func():
		PlayerState.add_zeny(100000)
		_say("ซีนี %d" % PlayerState.zeny))
	_button(r4, "ล้างคูลดาวน์", func():
		PlayerState.cooldowns.clear()
		PlayerState.potion_cooldowns.clear()
		Events.skills_changed.emit()
		Events.inventory_changed.emit()
		_say("ล้างคูลดาวน์สกิล/ยาแล้ว"))

	box.add_child(UITheme.separator())
	_god_check = CheckBox.new()
	_god_check.text = "อมตะ (ไม่เสียเลือดจากอะไรเลย)"
	_god_check.toggled.connect(func(on):
		PlayerState.gm_god_mode = on
		_say("อมตะ: %s" % ("เปิด" if on else "ปิด")))
	box.add_child(_god_check)

	_onehit_check = CheckBox.new()
	_onehit_check.text = "ตีทีเดียวตาย (ดาเมจที่เราทำ = เลือดเต็มของมอน)"
	_onehit_check.toggled.connect(func(on):
		PlayerState.gm_one_hit = on
		_say("ตีทีเดียวตาย: %s" % ("เปิด" if on else "ปิด")))
	box.add_child(_onehit_check)


## ตั้งเลเวลตรง ๆ พร้อมแจกแต้มเท่าที่ควรได้ (เหมือนเลเวลอัพจริง)
func _set_level(lv: int, job: int) -> void:
	var st := PlayerState.stats
	var old := st.level
	var old_job := st.job_level
	st.level = clampi(lv, 1, PlayerStats.MAX_LEVEL)
	st.exp_current = 0
	st.job_level = clampi(job, 1, st.max_job_level())   # ★ รอบ 108 ★
	st.job_exp_current = 0
	# แจกแต้มย้อนหลังตอนเลเวลขึ้น (ลดเลเวลไม่ยึดคืน — ของทดสอบ)
	if st.level > old:
		for l in range(old + 1, st.level + 1):
			st.stat_points += 3 + floori(l / 5.0)
	if st.job_level > old_job:   # ★ รอบ 108 ★ แต้มสกิลตามเลเวลอาชีพที่เพิ่ม (เหมือนจ๊อบขึ้นจริง)
		st.skill_points += st.job_level - old_job
	PlayerState.refresh(false)
	PlayerState.heal_hp(st.max_hp, false)
	PlayerState.restore_sp(st.max_sp)
	Events.level_up.emit(st.level)
	Events.job_level_up.emit(st.job_level)
	Events.exp_changed.emit(st.exp_current, st.exp_to_next())
	Events.job_exp_changed.emit(st.job_exp_current, st.job_exp_to_next())
	refresh()
	_say("ตั้งเลเวล %d / อาชีพ %d" % [st.level, st.job_level])


func _apply_level() -> void:
	_set_level(int(_level_box.value), int(_job_box.value))


# ---------- ★ รอบ 106 ★ เปลี่ยนอาชีพ ----------
func _fill_jobs() -> void:
	_job_option.clear()
	_job_ids.clear()
	var ids: Array[StringName] = []
	for j in JOB_ORDER:
		if GameData.get_job(j) != null: ids.append(j)
	var rest: Array = GameData.jobs.keys().filter(func(k): return StringName(k) not in ids)
	rest.sort()
	for k in rest: ids.append(StringName(k))
	for j in ids:
		var jd: JobData = GameData.get_job(j)
		_job_option.add_item("%s  (%s)" % [jd.display_name, String(j)])
		_job_ids.append(j)


func _apply_job() -> void:
	var i := _job_option.selected
	if i < 0 or i >= _job_ids.size(): return
	change_job(_job_ids[i], _unlock_check.button_pressed)


## เปลี่ยนอาชีพทันที — ตั้งธงชุดเดียวกับการเปลี่ยนอาชีพจริงใน PlayerState.turn_in_quest
## (job_<id> · <id>_awakened · <id>_start_level / _start_job_level) · เลือก Ninth Edge = ผ่าน Runeblade มาด้วย
## unlock = ตั้งธงรูนดวง 4-7 + ninth_inscription_unlocked ให้สกิลรูนเรียนได้ครบ
func change_job(job_id: StringName, unlock: bool = true) -> void:
	var jd: JobData = GameData.get_job(job_id)
	if jd == null:
		_say("ไม่พบอาชีพ %s" % job_id)
		return
	var st := PlayerState.stats
	var old_name: String = st.job().display_name
	st.change_profession(job_id)
	var chain: Array[StringName] = []
	if job_id == &"ninth_edge": chain = [&"runeblade", &"ninth_edge"]
	elif job_id != &"swordsman" and job_id != &"novice": chain = [job_id]
	for jid in chain:
		var sid := String(jid)
		if not PlayerState.has_flag(StringName(sid + "_awakened")):
			PlayerState.set_flag(StringName(sid + "_awakened"))
			PlayerState.set_flag(StringName(sid + "_start_job_level"), st.job_level)
			PlayerState.set_flag(StringName(sid + "_start_level"), st.level)
		PlayerState.set_flag(StringName("job_" + sid))
	# ธง job_<x> ของอาชีพที่ไม่ได้เป็นแล้ว เอาออก (มอนบางตัวสงบตามธงนี้)
	for other in GameData.jobs.keys():
		if StringName(other) not in chain and StringName(other) != job_id:
			PlayerState.clear_flag(StringName("job_" + String(other)))
	if unlock and PlayerState.is_rune_job():
		for f in RUNE_UNLOCK_FLAGS: PlayerState.set_flag(f)
		if job_id == &"ninth_edge": PlayerState.set_flag(&"ninth_inscription_unlocked")
	# Profession switches preserve learned skills and their own point banks.
	PlayerState.refresh()
	PlayerState.heal_hp(st.max_hp, false)
	PlayerState.restore_sp(st.max_sp)
	Events.skills_changed.emit()
	Events.stats_changed.emit()
	Events.job_level_up.emit(st.job_level)
	refresh()
	_say("เปลี่ยนอาชีพ %s → %s · เพดานจ๊อบ %d" % [old_name, jd.display_name, st.max_job_level()])


func _bump_level(delta: int) -> void:
	_set_level(PlayerState.stats.level + delta, PlayerState.stats.job_level + (1 if delta > 0 else -1) * absi(delta) / 2)


# =========================================================
# แท็บ "ระบบ"
# =========================================================
func _build_system_tab(box: VBoxContainer) -> void:
	var r := _row(box)
	r.add_child(UITheme.make_label("ไปแมพ", 13))
	_map_option = OptionButton.new()
	for id in Game.MAPS.keys():
		_map_option.add_item("%s  (%s)" % [Game.map_display_name(id), id])
		_map_option.set_item_metadata(_map_option.item_count - 1, id)
	r.add_child(_map_option)
	_button(r, "วาปไป", _warp_selected, 100)

	var r2 := _row(box)
	_button(r2, "★ เข้าห้อง GM ★", func(): _warp_to(&"gm_room"), 140)
	_button(r2, "กลับพรอนเทรา", func(): _warp_to(&"prontera_town"), 130)

	box.add_child(UITheme.separator())
	box.add_child(UITheme.make_label("ธงเนื้อเรื่อง (ติ๊ก = ตั้งธง)", 13, UITheme.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 3
	box.add_child(grid)
	for entry in STORY_FLAGS:
		var cb := CheckBox.new()
		cb.text = String(entry[0])
		var flag := StringName(entry[1])
		cb.toggled.connect(func(on):
			if on:
				PlayerState.set_flag(flag)
			else:
				PlayerState.clear_flag(flag)
			Events.quest_changed.emit()
			_say("ธง %s: %s" % [flag, "ตั้ง" if on else "ล้าง"]))
		grid.add_child(cb)
		_flag_boxes[flag] = cb

	box.add_child(UITheme.separator())
	var r3 := _row(box)
	_button(r3, "ปลดล็อกทุกบท", func():
		for f in [&"chapter2_open", &"chapter2_done", &"chapter3_visited"]:
			PlayerState.set_flag(f)
		Events.quest_changed.emit()
		refresh()
		_say("ตั้งธงเปิดบท 2-3 แล้ว"))
	_button(r3, "ล้างของตกในแมพ", func():
		var n := 0
		for d in get_tree().get_nodes_in_group("dropped_item"):
			d.queue_free()
			n += 1
		_say("ล้างของตก %d ชิ้น" % n))
	_button(r3, "เก็บของตกทั้งหมด", func():
		var n := 0
		for d in get_tree().get_nodes_in_group("dropped_item"):
			if d.has_method("collect"):
				d.collect()
				n += 1
		_say("เก็บของ %d ชิ้น" % n))


func _warp_selected() -> void:
	var idx := _map_option.selected
	if idx < 0:
		return
	_warp_to(StringName(_map_option.get_item_metadata(idx)))


func _warp_to(map_id: StringName) -> void:
	if not Game.MAPS.has(map_id):
		_say("ไม่มีแมพ %s" % map_id)
		return
	hide_window()
	Game.change_map(map_id, &"default")


# =========================================================
# อัพเดตหน้าต่าง
# =========================================================
func refresh() -> void:
	if _mon_list == null:
		return
	# ★★ รอบ 90 ★★ เติมรายชื่อเฉพาะตอนหน้าต่างเปิดจริง
	# GameWindow._ready() เรียก refresh() ตอนเปิดเกม → ของเดิมไปโหลดมอนครบ 30 ตัวตั้งแต่หน้าไตเติล
	# (ชีทมอนรวม 1.6 GB — เป็นต้นเหตุที่เว็บโหลดนาน/แท็บเด้ง)
	if visible:
		if _mon_list.item_count == 0:
			_fill_monsters()
		if _item_list.item_count == 0:
			_fill_items()
	var st := PlayerState.stats
	if _level_box != null:
		_level_box.value = st.level
		_job_box.value = st.job_level
	if _job_option != null:
		var idx := _job_ids.find(st.job_id)
		if idx >= 0: _job_option.select(idx)
	if _god_check != null:
		_god_check.set_pressed_no_signal(PlayerState.gm_god_mode)
		_onehit_check.set_pressed_no_signal(PlayerState.gm_one_hit)
	for flag in _flag_boxes.keys():
		(_flag_boxes[flag] as CheckBox).set_pressed_no_signal(PlayerState.has_flag(flag))
	if _info != null and _info.text == "":
		_say("แมพตอนนี้: %s · Lv%d" % [Game.map_display_name(PlayerState.current_map_id), st.level])


func _say(text: String) -> void:
	if _info != null:
		_info.text = "» " + text
	Events.say("[GM] " + text)
