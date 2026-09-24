## PlayerState — ข้อมูลตัวละครทั้งหมด (Autoload ชื่อ "PlayerState")
## รวม สเตตัส / กระเป๋า / ของสวมใส่ / สกิล / ซีนี / บัฟ ไว้ที่เดียว
## UI และฉากทุกฉากอ่านจากที่นี่
## หมายเหตุ: ไฟล์นี้ห้ามใส่ class_name เพราะจะชนกับชื่อ Autoload
extends Node

const INVENTORY_SIZE := 40
const REGEN_INTERVAL := 3.0   ## ฟื้น HP/SP ทุกกี่วินาที

var stats: PlayerStats
var inventory: Inventory
var equipment: Equipment
var skills: SkillBook
var quests: QuestLog

var zeny: int = 1000
var current_map_id: StringName = &"prontera_field"

## ★ ช่องยาด่วน ★ ช่อง 0 = ปุ่ม Q (ยาเลือด) · ช่อง 1 = ปุ่ม R (ยามานา)
## เลือกยาได้เองจากหน้ากระเป๋า
const ITEM_HOTKEY_COUNT := 2
var item_hotkeys: Array = [&"red_potion", &"blue_potion"]

## บัฟที่ติดอยู่: skill_id -> { "time_left": float, "values": Dictionary, "level": int }
var active_buffs: Dictionary = {}
## คูลดาวน์สกิล: skill_id -> วินาทีที่เหลือ
var cooldowns: Dictionary = {}

# =========================================================
# ★★ คูลดาวน์ยา (รอบ 65) ★★
#
# กินยาแล้วต้องรอถึงจะกินซ้ำได้ — ★ ยาฟื้นเยอะยิ่งรอนาน ★
#   ยาแดง   ฟื้น 45        → 5.0 วิ
#   ยาส้ม   ฟื้น 105       → ~5.6 วิ
#   เนื้อย่าง ฟื้น 70+3%    → ~5.6-6 วิ
#   ยาขาว   ฟื้น 325+5%    → ~9-10 วิ
#   ยาน้ำเงิน ฟื้นมานา 40   → 5.0 วิ
#
# ★ แยกเป็น 2 สาย ★ ยาเลือด (hp) กับ ยามานา (sp) นับคนละอัน
# กินยาเลือดแล้วยังกินยามานาต่อได้ทันที (เหมือน RO ที่แยกกลุ่มดีเลย์)
# ยาที่ฟื้นทั้งเลือดและมานาจะติดคูลดาวน์ทั้งสองสาย
#
# ★ อยากปรับความยาว ★ แก้ 4 ค่าข้างล่างนี้ได้เลย ไม่ต้องแตะที่อื่น
# =========================================================
## คูลดาวน์สั้นสุด (ยาฟื้นน้อย ๆ)
const POTION_CD_MIN := 5.0
## คูลดาวน์ยาวสุด (ยาฟื้นเยอะ ๆ)
const POTION_CD_MAX := 10.0
## ฟื้นเท่านี้หรือน้อยกว่า = คูลดาวน์สั้นสุด
const POTION_HEAL_LOW := 50.0
## ฟื้นเท่านี้หรือมากกว่า = คูลดาวน์ยาวสุด
const POTION_HEAL_HIGH := 400.0

## สายคูลดาวน์ยา: &"hp" / &"sp" -> วินาทีที่เหลือ
var potion_cooldowns: Dictionary = {}
## ★ รอบ 112 ★ คูลดาวน์ "ขอพร" ของหมอ (วินาทีที่เหลือ · ร่วมกันทุกเมือง · เซฟลงไฟล์เซฟ)
var blessing_cd_left: float = 0.0
## ★ รอบ 122 ★ คลัง — ใช้ร่วมกันทุกเมือง (เปิดที่เสาวาปในเมือง) · เซฟลงไฟล์เซฟ
const STORAGE_SIZE := 100
var storage: Inventory = Inventory.new(STORAGE_SIZE)
var storage_zeny: int = 0
## ★ รอบ 128 ★ ใบประกาศล่าของกิลด์ (บอร์ดต่อเมือง · แต้ม · ขั้น)
var bounties: BountyBoard = BountyBoard.new()
## ★ รอบ 154 ★ การ์ดที่ฝังเข้าสมุดแล้ว (id การ์ด → true) — ให้โบนัสถาวร ดู CardAlbum
var card_album: Dictionary = {}

var _regen_timer := 0.0
var _is_dead := false

# =========================================================
# ★★ ธงเนื้อเรื่อง (Story Flags) — รอบ 30 ★★
#
# ใช้จำว่า "เกิดอะไรขึ้นแล้วบ้าง" ในเนื้อเรื่อง เช่น
#   สาบานต่อธอร์แล้วหรือยัง · เจอคนแปลกหน้าแล้วหรือยัง · ดูพิธีฉลองแล้วหรือยัง
#
# เอาไปใช้ได้ 3 ที่:
#   1) เงื่อนไขเควส (ObjectiveData ชนิด FLAG · ช่อง Required Flag ของเควส)
#   2) เลือกบทพูดของ NPC (NPC มีบทพูดหลายชุด ดูที่ npc.gd)
#   3) เปลี่ยนพฤติกรรมเกม เช่น แมพกลางคืน / ข้อความหน้าจอตาย
#
# ตั้งค่า: PlayerState.set_flag(&"saw_ceremony")
# อ่านค่า: PlayerState.has_flag(&"saw_ceremony")
# =========================================================
var story_flags: Dictionary = {}
## ★ รอบ 102 ★ ล้มมอนชนิดไหนไปแล้วกี่ตัว: monster_id -> จำนวน (เก็บลงเซฟด้วย)
var kills: Dictionary = {}

# =========================================================
# ★★ โหมด GM (รอบ 80) — เครื่องมือทดสอบ ★★
# ตั้งจากหน้าต่าง GM (ปุ่ม F10) เท่านั้น · ไม่ถูกเก็บลงเซฟ · เริ่มเกมใหม่ = ปิดเสมอ
# =========================================================
## อมตะ — ผู้เล่นไม่เสียเลือดจากอะไรทั้งนั้น
var gm_god_mode := false
## ตีทีเดียวตาย — ดาเมจที่ผู้เล่นทำใส่มอนกลายเป็นเลือดเต็มของมัน
var gm_one_hit := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	new_game()
	Events.monster_killed.connect(_on_monster_killed)
	# ★ เดินความคืบหน้าเควสชนิดใหม่ ★
	Events.map_changed.connect(_on_map_changed)
	Events.inventory_changed.connect(_on_inventory_changed)
	Events.runic_hit.connect(_on_runic_hit)   # ★ รอบ 105 ★ เควสชนิด "ตีมอนด้วยสกิล"


func _on_monster_killed(monster_id: StringName, _level: int) -> void:
	if quests != null:
		quests.on_monster_killed(monster_id)
	# ★ รอบ 102 ★ จำว่าเคยล้มมอนชนิดไหนไปแล้วกี่ตัว
	# ใช้เป็นเงื่อนไขของเสาวาป ("ล่ามอนในแมพนั้นครบทุกชนิดก่อนถึงวาปไปได้")
	# และโชว์เป็นความคืบหน้าในหน้าแผนที่โลก
	kills[monster_id] = int(kills.get(monster_id, 0)) + 1


## ★ รอบ 105 ★ สกิลโดนมอน → เดินเควสชนิด SKILL_HIT
func _on_runic_hit(target: Node, source: StringName, _critical: bool) -> void:
	if quests == null or target == null or not is_instance_valid(target):
		return
	var d = target.get("data")
	if d != null and source != &"":
		quests.on_skill_hit(d.id, source)


## ★ รอบ 105 ★ อาชีพสายรูน (Runeblade และขั้นถัดไป Ninth Edge) — ใช้แทนการเช็ค == &"runeblade" ตรง ๆ
func is_rune_job() -> bool:
	return stats != null and stats.job_id in [&"runeblade", &"ninth_edge"]


func _on_map_changed(map_id: StringName) -> void:
	if quests != null:
		quests.on_map_entered(map_id)


func _on_inventory_changed() -> void:
	# เงื่อนไข "หาไอเทม" นับสดจากกระเป๋า — แค่แจ้งให้สมุดเควสอัปเดต
	if quests != null:
		quests.refresh_live()


# =========================================================
# ★ ธงเนื้อเรื่อง ★
# =========================================================
## ตั้งธง (ค่าเริ่มต้น = true) · ตั้งซ้ำค่าเดิมจะไม่ยิงสัญญาณซ้ำ
func set_flag(flag: StringName, value: Variant = true) -> void:
	if flag == &"":
		return
	if story_flags.get(flag, null) == value:
		return
	story_flags[flag] = value
	if quests != null:
		quests.refresh_live()
	Events.quest_changed.emit()


func has_flag(flag: StringName) -> bool:
	var v = story_flags.get(flag, false)
	if v is bool:
		return v
	return v != null


## อ่านค่าธงแบบเก็บข้อมูลได้ (เช่น เก็บว่าผู้เล่นตอบอะไร)
func get_flag(flag: StringName, fallback: Variant = false) -> Variant:
	return story_flags.get(flag, fallback)


func clear_flag(flag: StringName) -> void:
	if story_flags.erase(flag):
		Events.quest_changed.emit()


## รับรางวัลเควส แล้วส่งเควส — คืน true ถ้าส่งสำเร็จ
func turn_in_quest(quest_id: StringName) -> bool:
	var q := GameData.get_quest(quest_id)
	if q == null or not quests.is_ready(quest_id):
		return false
	if q.reward_job != &"" and (stats.level < q.required_level or
			(q.required_job != &"" and stats.job_id != q.required_job and not stats.has_profession(q.reward_job)) or
			(q.reward_job_map != &"" and current_map_id != q.reward_job_map)):   # ★ รอบ 105 ★
		return false

	var consumed := {}
	for objective in q.steps():
		if objective.kind == ObjectiveData.Kind.COLLECT and objective.consume:
			consumed[objective.target] = int(consumed.get(objective.target, 0)) + objective.need()
	for item_id in consumed:
		if inventory.count_of(item_id) < int(consumed[item_id]): return false
	var reward: ItemInstance
	if q.reward_item_id != &"" and q.reward_item_count > 0:
		reward = ItemInstance.create(q.reward_item_id, q.reward_item_count)
		if not inventory.can_add_all(reward, consumed):
			Events.say("กระเป๋าเต็ม — เก็บของให้ว่างก่อนแล้วค่อยมาส่งเควส")
			return false
	# Only commit after the entire reward fits. Quest consumption frees its slots first.
	if not quests.turn_in(quest_id): return false
	if reward != null: inventory.add(reward)

	if q.reward_zeny > 0:
		add_zeny(q.reward_zeny)
	if q.reward_exp > 0 and q.id != &"c7_4_ninth_edge":
		var jx: int = q.reward_job_exp if q.reward_job_exp > 0 else int(round(q.reward_exp * 0.7))
		gain_exp(q.reward_exp, jx)
	# ★ รอบ 105 ★ เปลี่ยนอาชีพได้ทุกอาชีพที่มีไฟล์ data/jobs/<id>.tres (runeblade · ninth_edge ...)
	if q.reward_job != &"" and GameData.get_job(q.reward_job) != null and stats.job_id != q.reward_job:
		var jid := String(q.reward_job)
		stats.change_profession(q.reward_job)
		set_flag(StringName(jid + "_awakened"))
		set_flag(StringName(jid + "_start_job_level"), stats.job_level)
		set_flag(StringName(jid + "_start_level"), stats.level)
		set_flag(StringName("job_" + jid))
		_grant_job_starter_skill(q.reward_job)   # ★ รอบ 125 ★
		refresh()
		Events.skills_changed.emit()
	# Chapter 7 grants its first training points after awakening. Earlier ceremonies retain their reward order.
	if q.reward_exp > 0 and q.id == &"c7_4_ninth_edge":
		var jx: int = q.reward_job_exp if q.reward_job_exp > 0 else int(round(q.reward_exp * 0.7))
		gain_exp(q.reward_exp, jx)
	if BountyBoard.is_bounty(q.id):   # ★ รอบ 128 ★ ใบประกาศ: ของแถม + แต้มกิลด์ + ออกใบใหม่
		bounties.on_turned_in(q.id)
	Events.say("[เควสสำเร็จ] %s — ได้รับ %s" % [q.title, q.reward_text()])
	return true


# =========================================================
# เริ่มเกมใหม่
# =========================================================
## ★ รอบ 166 ★ เวลาเล่นสะสม (วินาที · เซฟคีย์ play_time)
var play_time: float = 0.0

## "38:12 ชม." จากวินาที
static func play_time_text(seconds: float) -> String:
	var m := int(seconds / 60.0)
	return "%d:%02d ชม." % [int(m / 60.0), m % 60]


func new_game() -> void:
	play_time = 0.0
	_reset_drains()
	respawn_town = &"prontera_town"
	if is_instance_valid(SaveManager): SaveManager.end_session()
	stats = PlayerStats.new()
	inventory = Inventory.new(INVENTORY_SIZE)
	inventory.enable_quest_pocket()   # ★ รอบ 155 ★
	equipment = Equipment.new()
	skills = SkillBook.new()
	quests = QuestLog.new()
	story_flags.clear()
	kills.clear()
	zeny = 1000
	active_buffs.clear()
	cooldowns.clear()
	potion_cooldowns.clear()
	blessing_cd_left = 0.0
	storage = Inventory.new(STORAGE_SIZE)   # ★ รอบ 122 ★
	storage_zeny = 0
	bounties = BountyBoard.new()   # ★ รอบ 128 ★
	card_album.clear()   # ★ รอบ 154 ★
	item_hotkeys = [&"red_potion", &"blue_potion"]
	_reset_hotbar()   # ★ รอบ 168 ★
	_is_dead = false
	current_map_id = &"prontera_field"

	stats.job_id = &"swordsman"
	stats.level = 1
	stats.job_level = 1
	stats.stat_points = 20

	refresh()
	stats.hp = stats.max_hp
	stats.sp = stats.max_sp

	# ของเริ่มต้น
	inventory.add_id(&"red_potion", 10)
	inventory.add_id(&"novice_sword", 1)
	inventory.add_id(&"cotton_shirt", 1)

	# สวมของเริ่มต้นให้เลย
	for i in range(inventory.size):
		var s := inventory.get_slot(i)
		if s != null and (s.item_id == &"novice_sword" or s.item_id == &"cotton_shirt"):
			equip_from_inventory(i)

	stats.hp = stats.max_hp
	stats.sp = stats.max_sp

	_emit_all()


# =========================================================
# คำนวณค่าพลังใหม่ทั้งหมด — เรียกทุกครั้งที่มีอะไรเปลี่ยน
# =========================================================
func refresh(keep_ratio: bool = true) -> void:
	var flat := equipment.collect_bonus()
	var percent := equipment.collect_percent_bonus()

	# --- สกิลพาสซีฟ ---
	for key in skills.passive_bonus().keys():
		if String(key).ends_with("_percent"):
			percent[key] = float(percent.get(key, 0.0)) + float(skills.passive_bonus()[key])
		else:
			flat[key] = float(flat.get(key, 0)) + float(skills.passive_bonus()[key])

	# --- บัฟ ---
	for skill_id in active_buffs.keys():
		var values: Dictionary = active_buffs[skill_id].get("values", {})
		for key in values.keys():
			var k := StringName(key)
			if String(k).ends_with("_percent"):
				percent[k] = float(percent.get(k, 0.0)) + float(values[key])
			else:
				flat[k] = float(flat.get(k, 0)) + float(values[key])

	# --- ★ รอบ 154 ★ โบนัสสมุดการ์ด (การ์ดที่ฝังแล้ว) ---
	var album := CardAlbum.total(card_album)
	for key in album.keys():
		var k2 := StringName(key)
		if String(k2).ends_with("_percent"):
			percent[k2] = float(percent.get(k2, 0.0)) + float(album[key])
		else:
			flat[k2] = float(flat.get(k2, 0)) + float(album[key])

	# --- ★ รอบ 158 ★ โบนัสชุดเซ็ตอุปกรณ์ (EquipSets) ---
	var sets := EquipSets.total(equipment)
	for key in sets.keys():
		var k3 := StringName(key)
		if String(k3).ends_with("_percent"):
			percent[k3] = float(percent.get(k3, 0.0)) + float(sets[key])
		else:
			flat[k3] = float(flat.get(k3, 0)) + float(sets[key])

	stats.flat_bonus = flat
	stats.percent_bonus = percent
	stats.weapon_atk = equipment.weapon_atk()
	stats.recalculate(keep_ratio)

	# ★ รอบ 50 — ช่องกระเป๋าตาม STR ★ (set_size ปลอดภัยกับของที่มีอยู่แล้ว)
	if inventory != null:
		inventory.set_size(INVENTORY_SIZE + stats.bag_bonus_slots)

	Events.stats_changed.emit()
	Events.hp_changed.emit(stats.hp, stats.max_hp)
	Events.sp_changed.emit(stats.sp, stats.max_sp)


func _emit_all() -> void:
	Events.inventory_changed.emit()
	Events.equipment_changed.emit()
	Events.skills_changed.emit()
	Events.zeny_changed.emit(zeny)
	Events.exp_changed.emit(stats.exp_current, stats.exp_to_next())
	Events.job_exp_changed.emit(stats.job_exp_current, stats.job_exp_to_next())


# =========================================================
# ฟื้นฟู HP/SP + นับเวลาบัฟและคูลดาวน์
# =========================================================
func _process(delta: float) -> void:
	_drain_clock += delta
	if stats == null:
		return

	# คูลดาวน์
	var finished_cd: Array = []
	for sid in cooldowns.keys():
		cooldowns[sid] -= delta
		if cooldowns[sid] <= 0.0:
			finished_cd.append(sid)
	for sid in finished_cd:
		cooldowns.erase(sid)

	# ★ รอบ 166 ★ นับเวลาเล่น (โชว์ในหน้าระบบ/ช่องเซฟ)
	if not _is_dead and not get_tree().paused:
		play_time += delta

	# ★ รอบ 112 ★ คูลดาวน์ขอพร
	if blessing_cd_left > 0.0:
		blessing_cd_left = maxf(0.0, blessing_cd_left - delta)

	# ★ คูลดาวน์ยา (รอบ 65) ★
	var finished_pot: Array = []
	for kind in potion_cooldowns.keys():
		potion_cooldowns[kind] -= delta
		if potion_cooldowns[kind] <= 0.0:
			finished_pot.append(kind)
	for kind in finished_pot:
		potion_cooldowns.erase(kind)
		Events.inventory_changed.emit()   # ให้ปุ่มยาสว่างกลับทันทีที่พร้อม

	# บัฟหมดอายุ
	var expired: Array = []
	for sid in active_buffs.keys():
		active_buffs[sid]["time_left"] -= delta
		if active_buffs[sid]["time_left"] <= 0.0:
			expired.append(sid)
	if not expired.is_empty():
		for sid in expired:
			active_buffs.erase(sid)
		refresh()
		Events.buff_changed.emit()

	# ฟื้นฟู
	if _is_dead:
		return
	_regen_timer += delta
	if _regen_timer >= REGEN_INTERVAL:
		_regen_timer = 0.0
		if stats.hp > 0 and stats.hp < stats.max_hp:
			heal_hp(int(stats.hp_regen * REGEN_INTERVAL), false)
		if stats.sp < stats.max_sp:
			restore_sp(int(stats.sp_regen * REGEN_INTERVAL))


# =========================================================
# HP / SP
# =========================================================
## ★ รอบ 121 ★ text_size = ขนาดตัวเลขที่ลอย (ดูดเลือดใช้เล็กกว่ายา) · text_suffix = ต่อท้าย เช่น " ดูด"
func heal_hp(amount: int, show_text: bool = true, text_size: int = 24, text_suffix: String = "") -> void:
	if amount <= 0:
		return
	var before := stats.hp
	stats.hp = clampi(stats.hp + amount, 0, stats.max_hp)
	if stats.hp >= stats.max_hp:
		stats.hp_drain_remainder = 0.0
	if stats.hp != before:
		Events.hp_changed.emit(stats.hp, stats.max_hp)
		if show_text:
			var p := get_tree().get_first_node_in_group("player")
			if p != null:
				Events.floating_text(p.global_position, "+%d%s" % [stats.hp - before, text_suffix], Color("#5cff7a"), text_size, 0)


# A rolling one-second recovery budget shared by all targets, hits and equipment.
var _drain_clock := 0.0
var _drain_events: Array = []
var _sp_drain_remainder := 0.0

func _reset_drains() -> void:
	_drain_events.clear()
	_sp_drain_remainder = 0.0
	if stats != null: stats.hp_drain_remainder = 0.0

func _drain_allowance(kind: String, requested: float, cap: float) -> float:
	var used := 0.0
	for i in range(_drain_events.size()-1, -1, -1):
		if _drain_clock - float(_drain_events[i].time) >= 1.0:
			_drain_events.remove_at(i)
		elif _drain_events[i].kind == kind:
			used += float(_drain_events[i].amount)
	var granted := minf(maxf(0.0, requested), maxf(0.0, cap-used))
	if granted > 0.0: _drain_events.append({"time":_drain_clock,"kind":kind,"amount":granted})
	return granted

func apply_hp_drain(damage: int) -> void:
	if stats == null: return
	if _is_dead or stats.hp <= 0 or stats.hp >= stats.max_hp or stats.hp_drain_percent <= 0.0:
		stats.hp_drain_remainder = 0.0
		return
	stats.hp_drain_remainder += _drain_allowance("hp", float(maxi(0,damage))*stats.hp_drain_percent/100.0, stats.max_hp*0.02)
	var gain := int(floor(stats.hp_drain_remainder+0.0000001))
	stats.hp_drain_remainder = maxf(0.0,stats.hp_drain_remainder-gain)
	if gain > 0: heal_hp(gain,true,18)

func apply_sp_drain(damage: int) -> void:
	if stats == null: return
	if _is_dead or stats.hp <= 0 or stats.sp >= stats.max_sp or stats.sp_drain_percent <= 0.0:
		_sp_drain_remainder = 0.0
		return
	_sp_drain_remainder += _drain_allowance("sp",float(maxi(0,damage))*stats.sp_drain_percent/100.0,stats.max_sp*0.005)
	var gain := int(floor(_sp_drain_remainder+0.0000001))
	_sp_drain_remainder = maxf(0.0,_sp_drain_remainder-gain)
	if gain > 0: restore_sp(gain,true)

func _return_moved_cards() -> int:
	var items: Array = inventory.slots.duplicate()
	items.append_array(storage.slots)
	items.append_array(equipment.slots.values())
	var returned := 0
	for inst in items:
		if inst == null or inst.data() == null: continue
		for i in range(inst.cards.size()-1,-1,-1):
			var card := GameData.get_card(inst.cards[i])
			if card == null or card.fits_slot == inst.data().slot: continue
			# Expand only when full. Inventory.set_size preserves occupied overflow on refresh.
			if not inventory.can_add(ItemInstance.create(card.id,1)):
				inventory.set_size(inventory.size+1)
			if inventory.add_id(card.id,1)==0:
				inst.remove_card(i)
				returned += 1
	return returned


func take_damage(amount: int) -> void:
	if _is_dead or talk_truce():   # ★ รอบ 155 ★ กำลังคุย/อ่านป้ายในแมพทุ่ง = ไม่โดนตี
		return
	stats.hp = clampi(stats.hp - amount, 0, stats.max_hp)
	Events.hp_changed.emit(stats.hp, stats.max_hp)
	if stats.hp <= 0:
		stats.hp_drain_remainder = 0.0
		_is_dead = true
		_apply_death_penalty()   # ★ รอบ 158 ★
		Events.player_died.emit()


## ★ รอบ 158 ★ ตาย = เสีย EXP 2% ของหลอดเลเวลนี้ (ไม่ลดเลเวล · EXP ไม่ติดลบ)
const DEATH_EXP_LOSS := 0.02
var last_death_exp_loss: int = 0

func _apply_death_penalty() -> void:
	last_death_exp_loss = 0
	var need := stats.exp_to_next()
	if need <= 0 or stats.exp_current <= 0:
		return
	var loss := mini(stats.exp_current, maxi(1, int(round(float(need) * DEATH_EXP_LOSS))))
	stats.exp_current -= loss
	last_death_exp_loss = loss
	Events.exp_changed.emit(stats.exp_current, stats.exp_to_next())
	Events.say("[ตาย] เสีย EXP %d (%d%% ของหลอดเลเวลนี้)" % [loss, int(DEATH_EXP_LOSS * 100)])


## ★ รอบ 121 ★ show_text = ลอยตัวเลข "+N SP" สีฟ้าที่ตัวละคร (ดูดมานาจากการ์ด/ไอเทม)
func restore_sp(amount: int, show_text: bool = false, text_size: int = 18) -> void:
	var before := stats.sp
	stats.sp = clampi(stats.sp + amount, 0, stats.max_sp)
	if stats.sp != before:
		Events.sp_changed.emit(stats.sp, stats.max_sp)
		if show_text:
			var p := get_tree().get_first_node_in_group("player")
			if p != null:
				Events.floating_text(p.global_position + Vector2(0, -22), "+%d SP" % (stats.sp - before), Color("#6fc3ff"), text_size, 0)


func spend_sp(amount: int) -> bool:
	if stats.sp < amount:
		return false
	stats.sp -= amount
	Events.sp_changed.emit(stats.sp, stats.max_sp)
	return true


func is_dead() -> bool:
	return _is_dead


func revive(hp_percent: float = 0.5) -> void:
	_is_dead = false
	stats.hp = maxi(1, int(stats.max_hp * hp_percent))
	stats.sp = maxi(1, int(stats.max_sp * hp_percent))
	active_buffs.clear()
	# ★ รอบ 65 ★ ฟื้นคืนชีพแล้วกินยาได้เลย ไม่ต้องรอคูลดาวน์ค้างจากตอนตาย
	potion_cooldowns.clear()
	refresh(false)


# =========================================================
# EXP / ซีนี
# =========================================================
## ★ ค่าประสบการณ์ Base ★ (ขึ้นเลเวล = ได้แต้มสเตตัส)
func add_exp(amount: int) -> void:
	var gained := stats.add_exp(amount)
	Events.exp_changed.emit(stats.exp_current, stats.exp_to_next())
	if gained > 0:
		refresh(false)
		stats.hp = stats.max_hp
		stats.sp = stats.max_sp
		Events.hp_changed.emit(stats.hp, stats.max_hp)
		Events.sp_changed.emit(stats.sp, stats.max_sp)
		Events.level_up.emit(stats.level)


## ★ ค่าประสบการณ์อาชีพ (Job) ★ (ขึ้น job level = ได้แต้มสกิล)
func add_job_exp(amount: int) -> void:
	var gained := stats.add_job_exp(amount)
	Events.job_exp_changed.emit(stats.job_exp_current, stats.job_exp_to_next())
	if gained > 0:
		refresh(false)
		Events.job_level_up.emit(stats.job_level)


## ได้ทั้งสองหลอดพร้อมกัน (ใช้ตอนฆ่ามอน/ส่งเควส)
func gain_exp(base_exp: int, job_exp: int) -> void:
	if base_exp > 0:
		add_exp(base_exp)
	if job_exp > 0:
		add_job_exp(job_exp)


func add_zeny(amount: int) -> void:
	zeny = maxi(0, zeny + amount)
	Events.zeny_changed.emit(zeny)


## ★ รอบ 132 ★ คราฟต์ตามสูตร (data/recipes) — คืน {"ok": bool, "reason": String, "inst": ItemInstance}
## เผาวัตถุดิบ + ค่าแรง แล้วได้ของแบบ "ของดรอป" ที่โบนัส % สุ่มตามสูตร
func craft(recipe: RecipeData) -> Dictionary:
	if recipe == null or recipe.result() == null:
		return {"ok": false, "reason": "ไม่มีสูตรนี้"}
	if stats.level < recipe.result().required_level:   # ★ รอบ 137 ★ ต้องเลเวลถึงของชิ้นนั้นก่อน
		return {"ok": false, "reason": "ต้องเลเวล %d ก่อนถึงจะคราฟต์%sได้" % [recipe.result().required_level, recipe.result().display_name]}
	if not recipe.has_materials(inventory):
		var m := recipe.first_missing(inventory)
		return {"ok": false, "reason": "วัตถุดิบไม่ครบ — ขาด%s อีก %d" % [GameData.item_name(m[0]), int(m[1])]}
	if zeny < recipe.zeny:
		return {"ok": false, "reason": "ค่าแรงช่างไม่พอ (ต้องใช้ %d z)" % recipe.zeny}
	var inst := ItemInstance.create_crafted(recipe.result_item_id, recipe.result_count, recipe.roll_bonus())
	if not inventory.can_add(inst):
		return {"ok": false, "reason": "กระเป๋าเต็ม — เก็บของให้ว่างก่อนแล้วค่อยคราฟต์"}
	for pair in recipe.material_list():
		inventory.remove_id(pair[0], pair[1])
	spend_zeny(recipe.zeny)
	inventory.add(inst)
	return {"ok": true, "reason": "", "inst": inst}


## ★ รอบ 102 ★ จ่ายเงิน — เงินไม่พอคืน false และไม่หักอะไรเลย (ใช้กับค่าวาปของเสาวาป)
func spend_zeny(amount: int) -> bool:
	if amount <= 0:
		return true
	if zeny < amount:
		return false
	zeny -= amount
	Events.zeny_changed.emit(zeny)
	return true


# =========================================================
# สเตตัส
# =========================================================
func raise_stat(stat: StringName) -> bool:
	if stats.raise_stat(stat):
		refresh()
		return true
	return false


# =========================================================
# ของสวมใส่
# =========================================================
## ใส่ของจากช่องกระเป๋าที่ระบุ
func equip_from_inventory(inv_index: int) -> bool:
	var inst := inventory.get_slot(inv_index)
	if inst == null:
		return false
	var data := inst.data()
	if data == null or not data.is_equipment():
		Events.say("ไอเทมนี้สวมใส่ไม่ได้")
		return false

	# ★ เช็คระดับเลเวล ★
	if stats.level < data.required_level:
		Events.say("ต้องเลเวล %d ขึ้นไปถึงจะใส่ %s ได้ (ตอนนี้ Lv.%d)"
			% [data.required_level, data.display_name, stats.level])
		return false

	# เช็คว่าอาชีพใส่อาวุธชนิดนี้ได้ไหม
	if data.type == ItemData.Type.WEAPON:
		var job := stats.job()
		if not job.weapon_types.is_empty() and data.weapon_type not in job.weapon_types:
			Events.say("อาชีพ %s ใช้อาวุธชนิดนี้ไม่ได้" % job.display_name)
			return false

	# เครื่องประดับ: ถ้าช่อง 1 มีของแล้วให้ไปช่อง 2
	var prefer_second := false
	if data.slot == ItemData.Slot.ACCESSORY:
		prefer_second = equipment.get_item(Equipment.EquipSlot.ACCESSORY_1) != null \
			and equipment.get_item(Equipment.EquipSlot.ACCESSORY_2) == null

	var slot := Equipment.slot_for(data, prefer_second)
	if slot < 0:
		return false

	inventory.set_slot(inv_index, null)
	var old := equipment.equip(slot, inst)
	if old != null:
		inventory.set_slot(inv_index, old)
	refresh()
	return true


func unequip(slot: int) -> bool:
	var inst := equipment.get_item(slot)
	if inst == null:
		return false
	if inventory.is_full():
		Events.say("กระเป๋าเต็ม")
		return false
	equipment.unequip(slot)
	inventory.add(inst)
	refresh()
	return true


# =========================================================
# การ์ดมอนสเตอร์
# =========================================================
## รายการอุปกรณ์ที่ใส่การ์ดใบนี้ได้
## คืน Array ของ { "source": "eq:<slot>" หรือ "inv:<index>", "instance": ItemInstance }
func sockets_for_card(card_id: StringName) -> Array:
	var card := GameData.get_card(card_id)
	var out: Array = []
	if card == null:
		return out

	for slot in equipment.slots.keys():
		var inst: ItemInstance = equipment.get_item(slot)
		if inst != null and inst.can_socket(card):
			out.append({"source": "eq:%d" % slot, "instance": inst,
				"label": "%s (สวมอยู่)" % inst.display_name()})

	for i in range(inventory.size):
		var inst2 := inventory.get_slot(i)
		if inst2 != null and inst2.can_socket(card):
			out.append({"source": "inv:%d" % i, "instance": inst2,
				"label": inst2.display_name()})

	return out


## ใส่การ์ดจากกระเป๋าลงในอุปกรณ์
func socket_card(card_id: StringName, target: ItemInstance) -> bool:
	if target == null:
		return false
	var card := GameData.get_card(card_id)
	if card == null:
		Events.say("ไม่พบการ์ดใบนี้")
		return false
	if not inventory.has(card_id, 1):
		Events.say("ไม่มีการ์ดใบนี้ในกระเป๋า")
		return false
	if not target.can_socket(card):
		Events.say("ใส่ไม่ได้ — ต้องเป็น%sที่ยังมีช่องว่าง" % card.slot_name())
		return false

	inventory.remove_id(card_id, 1)
	target.socket_card(card_id)
	refresh()
	Events.inventory_changed.emit()
	Events.equipment_changed.emit()
	Events.say("ใส่ %s ลงใน %s แล้ว" % [card.display_name, target.display_name()])
	return true


## ถอดการ์ดออกจากอุปกรณ์ (คืนการ์ดกลับเข้ากระเป๋า)
## อยากให้ถอดแล้วการ์ดหายแบบ RO ต้นฉบับ ให้เปลี่ยน return_to_inventory เป็น false
func unsocket_card(target: ItemInstance, index: int, return_to_inventory: bool = true) -> bool:
	if target == null:
		return false
	var card_id := target.remove_card(index)
	if card_id == &"":
		return false
	if return_to_inventory:
		inventory.add_id(card_id, 1)
	refresh()
	Events.inventory_changed.emit()
	Events.equipment_changed.emit()
	Events.say("ถอด %s ออกแล้ว" % GameData.item_name(card_id))
	return true


## ★ ใส่ของเข้ากระเป๋า "ผ่านทางนี้เสมอ" ★
## จะได้ตรวจได้ว่าเป็นการ์ดใบใหม่ที่ยังไม่เคยมี แล้วเด้ง popup ยินดีด้วย
## คืนค่าจำนวนที่ใส่ไม่ได้ (0 = เข้าครบ) เหมือน Inventory.add()
func gain_item(inst: ItemInstance) -> int:
	if inst == null:
		return 0
	var d := inst.data()
	var first_card: bool = d != null and d.is_card() and not card_known(inst.item_id)   # ★ รอบ 154 ★ ฝังแล้วนับว่าเคยได้
	var leftover := inventory.add(inst)
	if first_card and leftover < inst.count:
		Events.card_obtained.emit(inst.item_id)
	return leftover


## ★ ให้ไอเทมจาก id ★ ใช้ตอนอ่าน lore / รางวัลเควส / ของจากเนื้อเรื่อง
## คืนจำนวนที่ใส่กระเป๋าไม่ลง (0 = เข้าครบ)
func gain_item_id(item_id: StringName, count: int = 1) -> int:
	if item_id == &"" or count <= 0:
		return 0
	var d := GameData.get_item(item_id)
	if d == null:
		push_warning("[PlayerState] ไม่รู้จักไอเทม: " + String(item_id))
		return count
	var inst := ItemInstance.new()
	inst.item_id = item_id
	inst.count = count
	var left := gain_item(inst)
	if left < count:
		Events.item_gained.emit(item_id, count - left)
		Events.say("ได้รับ %s x%d" % [d.display_name, count - left])
	return left


## เก็บการ์ดใบนี้ได้แล้วหรือยัง (นับทั้งในกระเป๋าและที่ใส่อยู่ในอุปกรณ์)
func owns_card(card_id: StringName) -> bool:
	if inventory.has(card_id, 1):
		return true
	for slot in equipment.slots.keys():
		var inst: ItemInstance = equipment.get_item(slot)
		if inst != null and card_id in inst.cards:
			return true
	for i in range(inventory.size):
		var inst2 := inventory.get_slot(i)
		if inst2 != null and card_id in inst2.cards:
			return true
	return false


func cards_collected() -> int:
	var n := 0
	for cid in GameData.cards.keys():
		if card_known(cid):   # ★ รอบ 154 ★ รวมใบที่ฝังเข้าสมุดแล้ว
			n += 1
	return n


## ★ รอบ 155 ★ «พักรบตอนคุย» — กล่องบทสนทนาเปิดอยู่ในแมพทุ่ง (ไม่ใช่ลานบอส/หอ) → มอนหยุด ผู้เล่นไม่โดนตี
## ปิดกล่องแล้วยังคุ้มกันต่ออีก TALK_TRUCE_GRACE วินาที จะได้ไม่โดนตีทันทีที่ปิด
const TALK_TRUCE_GRACE := 0.8
var _truce_until_msec: int = 0

func talk_truce() -> bool:
	if MapAtlas.kind_of(current_map_id) != MapAtlas.KIND_FIELD:
		return false
	var now := Time.get_ticks_msec()
	if UI.dialogue != null and UI.dialogue.is_open():
		_truce_until_msec = now + int(TALK_TRUCE_GRACE * 1000.0)
		return true
	return now < _truce_until_msec


## ★ รอบ 154 ★ เคยได้การ์ดใบนี้ไหม (มีอยู่ หรือฝังเข้าสมุดแล้ว) — ใช้โชว์ในสมุด
func card_known(card_id: StringName) -> bool:
	return card_album.has(card_id) or owns_card(card_id)


func card_deposited(card_id: StringName) -> bool:
	return card_album.has(card_id)


## ★ รอบ 154 ★ ฝังการ์ดเข้าสมุด — ใช้การ์ดในกระเป๋า 1 ใบ · ใบละ 1 ครั้ง · คืน {ok, reason}
func deposit_card(card_id: StringName) -> Dictionary:
	var card := GameData.get_card(card_id)
	if card == null or not CardAlbum.can_deposit(card_id):
		return {"ok": false, "reason": "การ์ดใบนี้ฝังเข้าสมุดไม่ได้"}
	if card_album.has(card_id):
		return {"ok": false, "reason": "ฝัง%sเข้าสมุดไปแล้ว" % card.display_name}
	if inventory.count_of(card_id) <= 0:
		return {"ok": false, "reason": "ต้องมี%sในกระเป๋า (ใบที่ใส่ในอุปกรณ์ต้องถอดก่อน)" % card.display_name}
	card_album[card_id] = true
	inventory.remove_id(card_id, 1)
	refresh()
	Events.say("[สมุดการ์ด] ฝัง%s — %s ถาวร" % [card.display_name, CardAlbum.describe(CardAlbum.bonus_of(card_id))])
	# ★ รอบ 158 ★ ฝังใบสุดท้ายของบท = ปลดโบนัสครบชุด
	var cs := CardAlbum.chapter_set_of(card_id)
	if not cs.is_empty() and CardAlbum.chapter_done(cs, card_album):
		Events.say("[สมุดการ์ด] ★ ครบชุดการ์ด%s! โบนัสเพิ่ม %s ถาวร" % [String(cs["name"]), CardAlbum.describe(cs["bonus"])])
	return {"ok": true, "reason": ""}


## ★ รอบ 154 ★ ย่อยการ์ด 5 ใบเกรดเดียวกัน → สุ่ม 1 ใบ · คืน {ok, reason, card_id, first}
func fuse_cards(ids: Array) -> Dictionary:
	var chk := CardAlbum.check_fusion(ids)
	if not bool(chk.ok):
		return {"ok": false, "reason": String(chk.reason)}
	var need: Dictionary = {}
	for cid in ids:
		need[StringName(cid)] = int(need.get(StringName(cid), 0)) + 1
	for cid in need.keys():
		if inventory.count_of(cid) < int(need[cid]):
			return {"ok": false, "reason": "การ์ดในกระเป๋าไม่พอ"}
	var fee: int = int(chk.fee)
	if zeny < fee:
		return {"ok": false, "reason": "เงินไม่พอ — ค่าบริการ %d z" % fee}
	var pool: Array = chk.pool
	var result: CardData = pool[randi() % pool.size()]
	for cid in need.keys():
		inventory.remove_id(cid, int(need[cid]))
	spend_zeny(fee)
	var first := not card_known(result.id)
	gain_item(ItemInstance.create(result.id, 1))
	return {"ok": true, "reason": "", "card_id": result.id, "first": first}


# =========================================================
# ★★ คูลดาวน์ยา (รอบ 65) ★★
# =========================================================
## ยาที่ฟื้น amount หน่วย ติดคูลดาวน์กี่วินาที (ฟื้นน้อย = 5 · ฟื้นเยอะ = 10)
static func potion_cooldown_for(amount: int) -> float:
	if amount <= 0:
		return 0.0
	var t := clampf((float(amount) - POTION_HEAL_LOW) / (POTION_HEAL_HIGH - POTION_HEAL_LOW), 0.0, 1.0)
	return POTION_CD_MIN + (POTION_CD_MAX - POTION_CD_MIN) * t


## ยาชิ้นนี้ฟื้นเลือด/มานาเท่าไหร่ (คิดเปอร์เซ็นต์จากค่าสูงสุดปัจจุบันด้วย)
## คืน { "hp": int, "sp": int }
## ★ รอบ 164 ★ boosted = true → รวมโบนัสพาสซีฟ First Aid (potion_heal_percent) แล้ว · false = ค่าฐานของยา (ใช้คิดคูลดาวน์)
func potion_heal_amounts(data: ItemData, boosted: bool = true) -> Dictionary:
	if data == null or stats == null:
		return {"hp": 0, "sp": 0}
	var mult := 1.0 + (potion_heal_bonus_percent() / 100.0 if boosted else 0.0)
	return {
		"hp": int(round((data.heal_hp + int(stats.max_hp * data.heal_hp_percent / 100.0)) * mult)),
		"sp": int(round((data.heal_sp + int(stats.max_sp * data.heal_sp_percent / 100.0)) * mult)),
	}


## ★ รอบ 164 ★ ยาฟื้นแรงขึ้นกี่ % (พาสซีฟ First Aid 5%/เลเวล · key potion_heal_percent ใน passive_effects)
func potion_heal_bonus_percent() -> float:
	if skills == null:
		return 0.0
	return float(skills.passive_bonus().get(&"potion_heal_percent", 0.0))


## คูลดาวน์ที่ยาชิ้นนี้จะติดถ้ากินตอนนี้ (0 = ไม่ใช่ยาฟื้นพลัง)
func potion_cooldown_of(data: ItemData) -> float:
	if data != null and data.potion_cooldown > 0.0:   # ★ รอบ 115 ★ ยาที่กำหนดคูลดาวน์เองในไฟล์ไอเทม
		return data.potion_cooldown
	var h := potion_heal_amounts(data, false)   # ★ รอบ 164 ★ คูลดาวน์ตามปริมาณฐาน
	return maxf(potion_cooldown_for(int(h.hp)), potion_cooldown_for(int(h.sp)))


## เวลาที่เหลือของสายนั้น (&"hp" หรือ &"sp")
func potion_cooldown_left(kind: StringName) -> float:
	return maxf(0.0, float(potion_cooldowns.get(kind, 0.0)))


## ยาชิ้นนี้ยังกินไม่ได้ เหลืออีกกี่วินาที (0 = กินได้เลย)
func potion_cooldown_left_for(data: ItemData) -> float:
	var h := potion_heal_amounts(data)
	var left := 0.0
	if int(h.hp) > 0:
		left = maxf(left, potion_cooldown_left(&"hp"))
	if int(h.sp) > 0:
		left = maxf(left, potion_cooldown_left(&"sp"))
	return left


## ยาชิ้นนี้ยังกินไม่ได้ เหลืออีกกี่วินาที — เรียกด้วย item_id (ไว้ให้ UI ใช้ง่าย ๆ)
func potion_cooldown_left_of_id(item_id: StringName) -> float:
	if item_id == &"":
		return 0.0
	return potion_cooldown_left_for(GameData.get_item(item_id))


## เริ่มนับคูลดาวน์หลังกินยา (สายไหนก็ต่อสายนั้น เอาค่าที่นานกว่า)
func start_potion_cooldown(hp_amount: int, sp_amount: int, fixed_cd: float = 0.0) -> void:
	# ★ รอบ 115 ★ fixed_cd > 0 = ไอเทมกำหนดคูลดาวน์เอง (ไม่ใช้สูตรตามปริมาณ)
	if hp_amount > 0:
		potion_cooldowns[&"hp"] = maxf(potion_cooldown_left(&"hp"), fixed_cd if fixed_cd > 0.0 else potion_cooldown_for(hp_amount))
	if sp_amount > 0:
		potion_cooldowns[&"sp"] = maxf(potion_cooldown_left(&"sp"), fixed_cd if fixed_cd > 0.0 else potion_cooldown_for(sp_amount))


# =========================================================
# ใช้ไอเทม
# =========================================================
func use_item(inv_index: int) -> bool:
	var inst := inventory.get_slot(inv_index)
	if inst == null:
		return false
	var data := inst.data()
	if data == null:
		return false

	if data.is_equipment():
		return equip_from_inventory(inv_index)

	if data.is_card():
		Events.toggle_window.emit(&"cards")
		return false

	if data.type != ItemData.Type.CONSUMABLE:
		Events.say("ไอเทมนี้ใช้ไม่ได้")
		return false

	# ★ รอบ 45 — ไอเทมพิเศษ: รีสกิล / รีสเตตัส · รอบ 60 — ปีกวาปกลับเมือง ★
	if data.special_effect != &"":
		match data.special_effect:
			&"warp_town":
				# ★ รอบ 120 ★ ปลายทาง = เมืองที่บันทึกจุดเกิดไว้ (ใช้จากเมืองอื่นได้ · ใช้ในเมืองนั้นเองไม่ได้)
				if current_map_id == saved_respawn_town():
					Events.say("อยู่ที่%sอยู่แล้ว" % Game.map_display_name(saved_respawn_town()))
					return false
				if Game._is_changing:
					return false
				inventory.take_from_slot(inv_index, 1)
				refresh()
				Events.say("%s — กลับสู่%s" % [data.display_name, Game.map_display_name(saved_respawn_town())])
				Events.item_used.emit(data.id)
				Game.warp_to_town()
				return true
			&"reset_skills":
				var before := stats.all_skill_points()
				skills.reset(stats)
				inventory.take_from_slot(inv_index, 1)
				refresh()
				Events.say("รีเซ็ตสกิลแล้ว — ได้แต้มสกิลคืน %d แต้ม" % (stats.all_skill_points() - before))
			&"reset_stats":
				var refund := stats.reset_stats()
				inventory.take_from_slot(inv_index, 1)
				refresh()
				Events.say("รีเซ็ตสเตตัสแล้ว — ได้แต้มสเตตัสคืน %d แต้ม" % refund)
			_:
				Events.say("ไอเทมนี้ยังไม่มีผล (%s)" % String(data.special_effect))
				return false
		Events.item_used.emit(data.id)
		return true

	var amounts := potion_heal_amounts(data)
	var heal: int = int(amounts.hp)
	var sp_heal: int = int(amounts.sp)
	var has_buff := data.buff_duration > 0.0 and not data.buff_values.is_empty()

	if heal > 0 and stats.hp >= stats.max_hp and sp_heal <= 0 and not has_buff:
		Events.say("เลือดเต็มอยู่แล้ว")
		return false

	# ★ รอบ 65 — คูลดาวน์ยา ★ ยาแรงยิ่งรอนาน (เช็คก่อนหักของออกจากกระเป๋า)
	var cd_left := potion_cooldown_left_for(data)
	if cd_left > 0.0:
		Events.say("%s ยังไม่พร้อม — รออีก %.1f วินาที" % [data.display_name, cd_left])
		return false

	inventory.take_from_slot(inv_index, 1)
	var base_amt := potion_heal_amounts(data, false)   # ★ รอบ 164 ★ คูลดาวน์ตามปริมาณฐาน (โบนัส First Aid ไม่ทำให้รอนานขึ้น)
	start_potion_cooldown(int(base_amt.hp), int(base_amt.sp), data.potion_cooldown)   # ★ รอบ 115 ★
	if heal > 0:
		heal_hp(heal)
	if sp_heal > 0:
		restore_sp(sp_heal, true, 24)   # ★ รอบ 121 ★ ยา SP ก็ลอยตัวเลข
	if has_buff:
		apply_item_buff(data)
	Events.item_used.emit(data.id)
	return true


## ★ รอบ 45 — บัฟจากไอเทม ★ เก็บใน active_buffs เหมือนบัฟสกิล (คีย์ = "item_<id>") ใช้ซ้ำ = ต่ออายุใหม่
func apply_item_buff(data: ItemData) -> void:
	var key := StringName("item_" + String(data.id))
	active_buffs[key] = {
		"time_left": data.buff_duration,
		"values": data.buff_values.duplicate(),
		"level": 1,
		"name": data.display_name,
		"icon": data.icon,
	}
	refresh()
	Events.buff_changed.emit()
	Events.say("ได้รับบัฟ %s (%d วินาที)" % [data.display_name, int(data.buff_duration)])


# =========================================================
# ★ ช่องยาด่วน (ปุ่ม Q / R) ★
# =========================================================
func item_hotkey_at(index: int) -> StringName:
	if index < 0 or index >= ITEM_HOTKEY_COUNT:
		return &""
	return item_hotkeys[index]


## ตั้งยาลงช่องด่วน (ใส่ &"" = ล้างช่อง)
func set_item_hotkey(index: int, item_id: StringName) -> void:
	if index < 0 or index >= ITEM_HOTKEY_COUNT:
		return
	# ยาชิ้นเดียวกันอยู่ได้ช่องเดียว
	for i in range(ITEM_HOTKEY_COUNT):
		if item_id != &"" and item_hotkeys[i] == item_id:
			item_hotkeys[i] = &""
	item_hotkeys[index] = item_id
	Events.inventory_changed.emit()


# =========================================================
# ★ รอบ 168 ★ แถบลัด 8 ช่อง × 2 หน้า (แบบ A · คอม) — ช่องละ 1 สกิลหรือ 1 ไอเทม
#   ช่อง i = หน้า × 8 + ปุ่ม (0-7 = ปุ่ม 1-8) · หน้า = skills.active_bank (Shift / T สลับ)
#   ช่อง 1-4 ของแต่ละหน้า ซิงก์ไป skills.hotkeys (ปุ่มสกิล 4 วงบนมือถือยังทำงานเหมือนเดิม)
# =========================================================
const HOTBAR_PAGE := 8
const HOTBAR_SIZE := 16
var hotbar: Array = []


func hotbar_page() -> int:
	return skills.active_bank if skills != null else 0


func hotbar_slot(i: int) -> Dictionary:
	if i < 0 or i >= hotbar.size():
		return {}
	return hotbar[i]


## ใส่สกิล/ไอเทมลงช่อง (id ว่าง = ล้างช่อง) · ของเดียวกันอยู่ได้ช่องเดียว
func set_hotbar_slot(i: int, kind: String, id: StringName) -> void:
	if i < 0 or i >= HOTBAR_SIZE:
		return
	if id == &"":
		hotbar[i] = {}
	else:
		for j in range(HOTBAR_SIZE):
			if j != i and String(hotbar[j].get("kind", "")) == kind and StringName(hotbar[j].get("id", &"")) == id:
				hotbar[j] = {}
		hotbar[i] = {"kind": kind, "id": id}
	_sync_skill_hotkeys()
	Events.skills_changed.emit()
	Events.inventory_changed.emit()


func swap_hotbar(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= HOTBAR_SIZE or b >= HOTBAR_SIZE or a == b:
		return
	var t: Dictionary = hotbar[a]
	hotbar[a] = hotbar[b]
	hotbar[b] = t
	_sync_skill_hotkeys()
	Events.skills_changed.emit()


## เรียกจาก SkillBook.set_hotkey (หน้าสกิลแบบเก่า/มือถือ) — ช่องลัดสกิล index 0-7 → แถบลัดหน้า index/4 ปุ่ม index%4
func hotbar_from_skillbook(index: int, skill_id: StringName) -> void:
	if hotbar.size() != HOTBAR_SIZE:
		return
	var i := int(index / 4) * HOTBAR_PAGE + index % 4
	if skill_id != &"":
		for j in range(HOTBAR_SIZE):
			if String(hotbar[j].get("kind", "")) == "skill" and StringName(hotbar[j].get("id", &"")) == skill_id:
				hotbar[j] = {}
		hotbar[i] = {"kind": "skill", "id": skill_id}
	elif String(hotbar[i].get("kind", "")) == "skill":
		hotbar[i] = {}


func _sync_skill_hotkeys() -> void:
	if skills == null or hotbar.size() != HOTBAR_SIZE:
		return
	for p in range(2):
		for j in range(4):
			var e: Dictionary = hotbar[p * HOTBAR_PAGE + j]
			var sid: StringName = StringName(e.get("id", &"")) if String(e.get("kind", "")) == "skill" else &""
			skills.hotkeys[p * 4 + j] = sid


func _reset_hotbar() -> void:
	hotbar = []
	for i in range(HOTBAR_SIZE):
		hotbar.append({})
	# เริ่มเกม: ยาแดงปุ่ม 6 · ยาน้ำเงินปุ่ม 7 (ตามภาพแบบ A)
	hotbar[5] = {"kind": "item", "id": &"red_potion"}
	hotbar[6] = {"kind": "item", "id": &"blue_potion"}
	_sync_skill_hotkeys()


func _hotbar_to_save() -> Array:
	var out: Array = []
	for e: Dictionary in hotbar:
		out.append([String(e.get("kind", "")), String(e.get("id", ""))] if not e.is_empty() else [])
	return out


func _hotbar_from_save(raw) -> void:
	hotbar = []
	for i in range(HOTBAR_SIZE):
		hotbar.append({})
	if raw is Array:
		for i in range(mini((raw as Array).size(), HOTBAR_SIZE)):
			var r = raw[i]
			if r is Array and (r as Array).size() >= 2 and String(r[1]) != "":
				var kind := String(r[0])
				var id := StringName(String(r[1]))
				if kind == "skill":
					var sk := GameData.get_skill(id)
					if sk == null or sk.type == SkillData.SkillType.PASSIVE:
						continue
				elif kind == "item":
					if GameData.get_item(id) == null:
						continue
				else:
					continue
				hotbar[i] = {"kind": kind, "id": id}
	else:
		# เซฟเก่า: ช่องลัดสกิล 8 (ชุด 1 → หน้า 1 ปุ่ม 1-4 · ชุด 2 → หน้า 2 ปุ่ม 1-4) + ยา Q/R → ปุ่ม 6/7
		for k in range(mini(skills.hotkeys.size(), 8)):
			var sid: StringName = skills.hotkeys[k]
			if sid != &"":
				hotbar[int(k / 4) * HOTBAR_PAGE + k % 4] = {"kind": "skill", "id": sid}
		for q in range(ITEM_HOTKEY_COUNT):
			if item_hotkeys[q] != &"":
				hotbar[5 + q] = {"kind": "item", "id": item_hotkeys[q]}
	_sync_skill_hotkeys()


## คำอธิบายสั้นของช่อง (tooltip แถบลัด)
func hotbar_tooltip(i: int) -> String:
	var e := hotbar_slot(i)
	if e.is_empty():
		return "ช่องว่าง — ใส่สกิลจากหน้าสกิล (K) หรือไอเทมจากกระเป๋า (I)"
	var id: StringName = e.id
	if e.kind == "skill":
		var sk := GameData.get_skill(id)
		if sk == null:
			return ""
		var t := "%s  Lv.%d\n%s" % [sk.display_name, skills.level_of(id), sk.description]
		if not skills.is_learned(id):
			t += "\n(ยังไม่ได้เรียน)"
		return t
	var d := GameData.get_item(id)
	if d == null:
		return ""
	var n := inventory.count_of(id) if inventory != null else 0
	var t2 := "%s  (มี %d)" % [d.display_name, n]
	if d.special_effect == &"warp_town":
		t2 += "\nวาร์ปกลับเมืองที่บันทึกจุดเกิด → %s" % Game.map_display_name(saved_respawn_town())
	elif d.buff_duration > 0.0:
		var key := StringName("item_" + String(id))
		t2 += "\nบัพ %d วินาที" % int(d.buff_duration)
		if active_buffs.has(key):
			t2 += " · ติดอยู่ อีก %d วินาที" % int(float(active_buffs[key].get("time_left", 0.0)))
	elif d.description != "":
		t2 += "\n" + d.description
	return t2


## กดปุ่มยาด่วน
func use_item_hotkey(index: int) -> bool:
	var id := item_hotkey_at(index)
	if id == &"":
		Events.say("ยังไม่ได้เลือกยาในช่องนี้ (เปิดกระเป๋าแล้วกดตั้งช่องยา)")
		return false
	if inventory.count_of(id) <= 0:
		Events.say("%s หมดแล้ว" % GameData.item_name(id))
		return false
	return use_item_by_id(id)


func use_item_by_id(item_id: StringName) -> bool:
	for i in range(inventory.size):
		var s := inventory.get_slot(i)
		if s != null and s.item_id == item_id:
			return use_item(i)
	return false


# =========================================================
# สกิล
# =========================================================
func skill_cooldown_left(skill_id: StringName) -> float:
	return float(cooldowns.get(skill_id, 0.0))


func can_use_skill(skill_id: StringName) -> Dictionary:
	var out := {"ok": false, "reason": ""}
	var s := GameData.get_skill(skill_id)
	if s == null:
		out.reason = "ไม่พบสกิล"
		return out
	var lv := skills.level_of(skill_id)
	if lv <= 0:
		out.reason = "ยังไม่ได้เรียนสกิลนี้"
		return out
	if not s.is_active():
		out.reason = "สกิลพาสซีฟใช้เองไม่ได้"
		return out
	if skill_cooldown_left(skill_id) > 0.0:
		out.reason = "ยังคูลดาวน์อยู่"
		return out
	if stats.sp < s.sp_cost(lv):
		out.reason = "SP ไม่พอ"
		return out
	out.ok = true
	return out


## หักค่าใช้จ่ายและเริ่มคูลดาวน์ (player.gd เป็นคนทำดาเมจจริง)
func commit_skill_use(skill_id: StringName) -> bool:
	var check := can_use_skill(skill_id)
	if not check.ok:
		Events.say(check.reason)
		return false
	var s := GameData.get_skill(skill_id)
	var lv := skills.level_of(skill_id)
	spend_sp(s.sp_cost(lv))
	# ★ รอบ 50 — DEX ลดคูลดาวน์ (ดู PlayerStats.cooldown_reduction) ★
	cooldowns[skill_id] = s.cooldown * (1.0 - stats.cooldown_reduction / 100.0)
	Events.skill_used.emit(skill_id, lv)
	return true


## ★ รอบ 125 ★ เปลี่ยนอาชีพแล้วได้ "ท่าเริ่มต้น" Lv 1 ฟรี — ผู้เล่นมีท่าใหม่ใช้ทันที ไม่ต้องรอแต้ม
const JOB_STARTER_SKILL := {&"runeblade": &"rune_lunge"}

func _grant_job_starter_skill(job_id: StringName) -> void:
	var sid: StringName = JOB_STARTER_SKILL.get(job_id, &"")
	if sid == &"" or skills == null or skills.level_of(sid) > 0 or GameData.get_skill(sid) == null:
		return
	skills.learned[sid] = 1
	Events.say("ได้รับท่าใหม่: %s" % GameData.get_skill(sid).display_name)


# =========================================================
# ★ รอบ 122 ★ คลัง (ฝาก-ถอน ของ/ซีนี)
# =========================================================
## ย้ายของจากกระเป๋า → คลัง (count = จำนวน · ของสวมใส่ย้ายทั้งชิ้นพร้อมตีบวก/การ์ด) คืน true ถ้าย้ายได้อย่างน้อย 1
func storage_deposit(inv_index: int, count: int = 1) -> bool:
	return _storage_move(inventory, storage, inv_index, count, "ฝาก")


## ย้ายของจากคลัง → กระเป๋า
func storage_withdraw(storage_index: int, count: int = 1) -> bool:
	return _storage_move(storage, inventory, storage_index, count, "ถอน")


func _storage_move(from: Inventory, to: Inventory, index: int, count: int, verb: String) -> bool:
	var inst := from.get_slot(index)
	if inst == null:
		return false
	var d := inst.data()
	if d == null or d.type == ItemData.Type.QUEST:
		Events.say("ของเควส%sไม่ได้" % verb)
		return false
	var moving: ItemInstance
	if d.is_stackable():
		count = clampi(count, 1, inst.count)
		# ★ ของกอง: สร้างชิ้นใหม่ตามจำนวน (take_from_slot ทำให้อยู่แล้ว)
		moving = from.take_from_slot(index, count)
	else:
		# ★ ของสวมใส่: ย้าย "ชิ้นเดิม" ทั้งชิ้น ไม่ให้การ์ด/ตีบวก/โบนัสหาย
		from.set_slot(index, null)
		moving = inst
	var wanted: int = moving.count
	var leftover := to.add(moving)
	if leftover > 0:
		moving.count = leftover
		from.add(moving)   # คืนส่วนที่ใส่ไม่ลง
	if leftover >= wanted:
		Events.say("%sไม่ได้ — %sเต็ม" % [verb, "คลัง" if to == storage else "กระเป๋า"])
		return false
	return true


func storage_deposit_zeny(amount: int) -> bool:
	amount = mini(amount, zeny)
	if amount <= 0:
		return false
	add_zeny(-amount)
	storage_zeny += amount
	Events.zeny_changed.emit(zeny)
	return true


func storage_withdraw_zeny(amount: int) -> bool:
	amount = mini(amount, storage_zeny)
	if amount <= 0:
		return false
	storage_zeny -= amount
	add_zeny(amount)
	Events.zeny_changed.emit(zeny)
	return true


## ★ รอบ 112 ★ พรจากหมอ (ขอพร) — เก็บใน active_buffs ท่อเดียวกับบัฟไอเทม → HUD/สเตตัสรับไปเอง
func blessing_cooldown_left() -> float:
	return maxf(0.0, blessing_cd_left)


func apply_blessing(key: StringName, buff_name: String, duration: float, values: Dictionary, cooldown: float, icon: Texture2D = null) -> void:
	active_buffs[key] = {
		"time_left": duration,
		"values": values.duplicate(),
		"level": 1,
		"name": buff_name,
		"icon": icon,
	}
	blessing_cd_left = cooldown
	refresh()
	Events.buff_changed.emit()


func apply_buff(skill_id: StringName) -> void:
	var s := GameData.get_skill(skill_id)
	if s == null:
		return
	var lv := skills.level_of(skill_id)
	active_buffs[skill_id] = {
		"time_left": s.duration(lv),
		"values": s.buff_values(lv),
		"level": lv,
	}
	refresh()
	Events.buff_changed.emit()


func learn_skill(skill_id: StringName) -> bool:
	if skills.learn(skill_id, stats):
		refresh()
		return true
	Events.say(skills.learn_blocker(skill_id, stats))
	return false


# =========================================================
# ร้านค้า
# =========================================================
func buy(item_id: StringName, count: int = 1) -> bool:
	var d := GameData.get_item(item_id)
	if d == null:
		return false
	var unit := BountyBoard.guild_price(d.buy_price)   # ★ รอบ 158 ★ ส่วนลดขั้นกิลด์
	var total := unit * count
	if zeny < total:
		Events.say("ซีนีไม่พอ")
		return false
	if inventory.is_full() and not d.is_stackable():
		Events.say("กระเป๋าเต็ม")
		return false
	var leftover := inventory.add_id(item_id, count)
	var bought := count - leftover
	if bought <= 0:
		Events.say("กระเป๋าเต็ม")
		return false
	add_zeny(-unit * bought)
	Events.say("ซื้อ %s x%d" % [d.display_name, bought])
	return true


func sell_slot(inv_index: int, count: int = 1) -> bool:
	var inst := inventory.get_slot(inv_index)
	if inst == null:
		return false
	var d := inst.data()
	if d == null or d.type == ItemData.Type.QUEST or not d.sellable:
		Events.say("ไอเทมนี้ขายไม่ได้")
		return false
	var taken := inventory.take_from_slot(inv_index, count)
	if taken == null:
		return false
	add_zeny(taken.sell_value())
	Events.say("ขาย %s ได้ %d ซีนี" % [taken.display_name(), taken.sell_value()])
	return true


# =========================================================
# เซฟ / โหลด
# =========================================================
# =========================================================
# ★★ คูลดาวน์เกิดใหม่ของบอส (รอบ 56) ★★
#
# เดิม: เวลานับถอยหลังอยู่ในฉากแมพ — ออกแมพแล้วเข้าใหม่ ฉากถูกสร้างใหม่
#       บอสจึงเกิดทันที ผู้เล่นวนออก-เข้าเพื่อฟาร์มบอสรัว ๆ ได้
# ตอนนี้: จำ "เวลาที่เกิดใหม่ได้" ต่อ id มอน ไว้ในเซฟ (นาฬิกาเครื่อง)
#         ออกแมพ ปิดเกม โหลดเซฟ ก็ยังต้องรอจนครบ
# =========================================================
var respawn_locks: Dictionary = {}     ## id มอน -> unix time ที่เกิดใหม่ได้

## ★ รอบ 60 ★ เมืองล่าสุดที่ผู้เล่นเดินเข้าไป (ปีกแห่งวาลคีรีวาปกลับที่นี่)
## MapBase ตั้งให้เองตอนเข้าแมพที่อยู่ในลิสต์ Game.TOWNS
var last_town: StringName = &"prontera_town"
var respawn_town: StringName = &"prontera_town"

func saved_respawn_town() -> StringName:
	return respawn_town if Game.MAPS.has(respawn_town) and Game.is_town(respawn_town) else &"prontera_town"

func bind_respawn_town(map_id: StringName) -> bool:
	if not Game.is_town(map_id): return false
	respawn_town = map_id
	SaveManager.request_autosave()
	return true



## เมืองที่จะวาปกลับ (กันค่าเพี้ยน/แมพถูกลบ = ถอยไปพรอนเทรา)
func home_town() -> StringName:
	if last_town != &"" and Game.MAPS.has(last_town):
		return last_town
	return &"prontera_town"


func set_last_town(map_id: StringName) -> void:
	if Game.is_town(map_id):
		last_town = map_id


## ล็อกไม่ให้มอน id นี้เกิดใหม่อีก seconds วินาที
func lock_respawn(monster_id: StringName, seconds: float) -> void:
	if seconds <= 0.0:
		return
	respawn_locks[monster_id] = Time.get_unix_time_from_system() + seconds


## เหลืออีกกี่วินาทีถึงจะเกิดใหม่ได้ (0 = เกิดได้เลย)
func respawn_remaining(monster_id: StringName) -> float:
	if not respawn_locks.has(monster_id):
		return 0.0
	var left: float = float(respawn_locks[monster_id]) - Time.get_unix_time_from_system()
	if left <= 0.0:
		respawn_locks.erase(monster_id)
		return 0.0
	return left


## เกิดใหม่ได้หรือยัง
func can_respawn(monster_id: StringName) -> bool:
	return respawn_remaining(monster_id) <= 0.0


func _respawn_locks_to_dict() -> Dictionary:
	var out: Dictionary = {}
	for k in respawn_locks.keys():
		out[String(k)] = float(respawn_locks[k])
	return out


func to_dict() -> Dictionary:
	return {
		"version": 1,
		"respawn_locks": _respawn_locks_to_dict(),
		"last_town": String(last_town),
		"respawn_town": String(saved_respawn_town()),
		"stats": stats.to_dict(),
		"inventory": inventory.to_array(),
		"quest_items": inventory.quest_to_array(),   # ★ รอบ 155 ★
		"equipment": equipment.to_dict(),
		"skills": skills.to_dict(),
		"quests": quests.to_dict(),
		"zeny": zeny,
		"item_hotkeys": [String(item_hotkeys[0]), String(item_hotkeys[1])],
		"hotbar": _hotbar_to_save(),   # ★ รอบ 168 ★
		"map": String(current_map_id),
		"flags": _flags_to_dict(),
		"kills": _kills_to_dict(),
		"blessing_cd": blessing_cd_left,   # ★ รอบ 112 ★
		"storage": storage.to_array(),     # ★ รอบ 122 ★
		"storage_zeny": storage_zeny,
		"bounties": bounties.to_dict(),   # ★ รอบ 128 ★
		"card_album": _card_album_to_array(),   # ★ รอบ 154 ★
		"play_time": int(play_time),   # ★ รอบ 166 ★ วินาที
	}


## ★ รอบ 102 ★ เคยล้มมอนชนิดนี้ไปกี่ตัว (0 = ยังไม่เคยล้มเลย)
func kill_count(monster_id: StringName) -> int:
	return int(kills.get(monster_id, 0))


func _card_album_to_array() -> Array:
	var out: Array = []
	for k in card_album.keys():
		out.append(String(k))
	return out


func _kills_to_dict() -> Dictionary:
	var out: Dictionary = {}
	for k in kills.keys():
		out[String(k)] = int(kills[k])
	return out


func _flags_to_dict() -> Dictionary:
	var out: Dictionary = {}
	for k in story_flags.keys():
		out[String(k)] = story_flags[k]
	return out


func from_dict(d: Dictionary) -> void:
	_reset_drains()
	stats = PlayerStats.new()
	inventory = Inventory.new(INVENTORY_SIZE)
	equipment = Equipment.new()
	skills = SkillBook.new()
	quests = QuestLog.new()
	active_buffs.clear()
	cooldowns.clear()
	potion_cooldowns.clear()
	blessing_cd_left = float(d.get("blessing_cd", 0.0))   # ★ รอบ 112 ★ ออก-เข้าเกมไม่ล้างคูลดาวน์ขอพร
	storage = Inventory.new(STORAGE_SIZE)   # ★ รอบ 122 ★ คลัง (เซฟเก่าไม่มี = ว่าง)
	storage.from_array(d.get("storage", []))
	storage_zeny = int(d.get("storage_zeny", 0))
	play_time = float(d.get("play_time", 0))   # ★ รอบ 166 ★ เซฟเก่า = เริ่มนับจาก 0
	bounties = BountyBoard.new()   # ★ รอบ 128 ★ ต้องลงทะเบียนใบก่อนโหลดสมุดเควส
	bounties.from_dict(d.get("bounties", {}))
	card_album.clear()   # ★ รอบ 154 ★
	for cid in d.get("card_album", []):
		card_album[StringName(String(cid))] = true
	_is_dead = false

	stats.from_dict(d.get("stats", {}))
	inventory.from_array(d.get("inventory", []))
	inventory.quest_from_array(d.get("quest_items", []))   # ★ รอบ 155 ★
	inventory.enable_quest_pocket()   # เซฟเก่า: ย้ายของเควสออกจากช่อง
	equipment.from_dict(d.get("equipment", {}))
	skills.from_dict(d.get("skills", {}))
	for jid in JOB_STARTER_SKILL.keys():   # ★ รอบ 125 ★ เซฟเก่าที่เป็นอาชีพนี้แล้วก็ได้ท่าเริ่มต้น
		if stats.has_profession(jid):
			_grant_job_starter_skill(jid)
	quests.from_dict(d.get("quests", {}))
	for qid in quests.active.duplicate():   # ★ รอบ 128 ★ ใบประกาศที่ไม่มีบอร์ดแล้ว (เซฟเพี้ยน) ตัดทิ้ง
		if BountyBoard.is_bounty(qid) and GameData.get_quest(qid) == null:
			quests.active.erase(qid)
			quests.progress.erase(qid)
	zeny = int(d.get("zeny", 0))
	var ih: Array = d.get("item_hotkeys", [])
	item_hotkeys = [&"red_potion", &"blue_potion"]
	for i in range(mini(ih.size(), ITEM_HOTKEY_COUNT)):
		item_hotkeys[i] = StringName(ih[i])
	_hotbar_from_save(d.get("hotbar", null))   # ★ รอบ 168 ★ เซฟเก่า = สร้างจากช่องลัดสกิล 8 + ยา Q/R
	current_map_id = StringName(d.get("map", "prontera_field"))

	last_town = StringName(String(d.get("last_town", "prontera_town")))
	respawn_town = StringName(String(d.get("respawn_town", "prontera_town")))
	respawn_town = saved_respawn_town()
	respawn_locks.clear()
	var rl = d.get("respawn_locks", {})
	if rl is Dictionary:
		for k in rl.keys():
			respawn_locks[StringName(k)] = float(rl[k])

	kills.clear()
	var kd = d.get("kills", {})
	if kd is Dictionary:
		for k in kd.keys():
			kills[StringName(k)] = int(kd[k])

	story_flags.clear()
	var fl = d.get("flags", {})
	if fl is Dictionary:
		for k in fl.keys():
			story_flags[StringName(k)] = fl[k]

	# ★ รอบ 159 ★ เซฟเก่าที่ส่งใบประกาศไปแล้ว นับว่าผ่านเงื่อนไข «ใบประกาศใบแรก»
	if bounties != null and bounties.total_turned_in > 0:
		story_flags[BountyBoard.FIRST_BOUNTY_FLAG] = true
	var returned_cards := _return_moved_cards()
	if returned_cards > 0: Events.say("คืนการ์ดที่เปลี่ยนช่องสวมใส่ %d ใบเข้ากระเป๋าแล้ว" % returned_cards)
	stats.migrate_job_progress(skills,story_flags)
	var rank_gain := bounties.claim_rank_rewards()   # ★ รอบ 158 ★ เซฟเก่าที่ขั้นกิลด์สูงอยู่แล้ว = ได้แต้มสเตตัสย้อนหลัง
	if rank_gain > 0:
		Events.say("[กิลด์] ได้แต้มสเตตัสจากขั้นกิลด์ %s ย้อนหลัง +%d" % [bounties.rank_letter(), rank_gain])
	refresh(false)
	_emit_all()
