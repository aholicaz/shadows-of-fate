## BountyBoard — ใบประกาศล่าของกิลด์นักผจญภัย (★ รอบ 128 ★)
##
## เมืองแต่ละแห่งมีบอร์ด 3 ใบ: ล่ามอน · เก็บวัตถุดิบ · ล่าบอสประจำบท (เปิดเมื่อส่งใบธรรมดาครบ BOSS_UNLOCK_TURNINS)
## ใบถูกสร้างสด ๆ จากมอนในบทของเมืองนั้นที่เลเวลใกล้ผู้เล่น แล้วลงทะเบียนเป็น QuestData ชั่วคราวใน GameData.quests
## (id ขึ้นต้น bounty_) ระบบเควสเดิม (สมุดเควส · HUD · นับฆ่า) จึงใช้ได้ทันทีโดยไม่ต้องแก้
## ส่งใบแล้วได้ EXP (≈5-8% ของหลอดที่เลเวลมอน) · zeny · แร่ตีบวก 1-2 ก้อน · บางใบแถมยา · แต้มกิลด์ → ขั้น F-S
## ★ รอบ 142: ส่งใบแล้วช่องนั้น "พัก" ก่อนออกใบใหม่ (ล่า 5 นาที · เก็บของ 10 นาที · บอส 30 นาที · นับเวลาจริง เซฟไว้ด้วย)
## เก็บใน PlayerState.bounties (เซฟคีย์ "bounties")
class_name BountyBoard
extends RefCounted

const SLOTS := 3
const BOSS_SLOT := 2
## ส่งใบธรรมดาครบกี่ใบ "ในเมืองนั้น" ถึงเปิดใบล่าบอส
const BOSS_UNLOCK_TURNINS := 5
## เลือกมอนที่เลเวลห่างผู้เล่นไม่เกินเท่านี้ (ไม่มีก็เอาตัวที่ใกล้สุด)
const LEVEL_WINDOW := 8
## ค่าเปลี่ยนใบ (ต่อบท)
const REROLL_COST_PER_CHAPTER := 300
## EXP ที่ให้ = สัดส่วนของ EXP ที่ต้องใช้ขึ้นเลเวล "ที่เลเวลมอน"
const EXP_SHARE := 0.05          # ★ รอบ 142 ★ 0.10 → 0.05 (ผู้ใช้: เวลไวเกิน)
const EXP_SHARE_COLLECT := 0.05
const EXP_SHARE_BOSS := 0.08
## zeny = zeny เฉลี่ยของมอน × จำนวนที่ต้องล่า × ตัวนี้
const ZENY_MULT := 0.5           # ★ รอบ 142 ★ 1.5 → 0.5 (ลดเงินเฟ้อ · ≈ ครึ่งหนึ่งของ zeny ที่ได้จากการล่าเองอยู่แล้ว)
const ZENY_MULT_BOSS := 1.0      # ★ รอบ 142 ★ 3.0 → 1.0
## ★ รอบ 142 ★ คูลดาวน์ช่อง (วินาที) หลังส่งใบ — ช่องจะว่างจนกว่าจะครบ
const COOLDOWN_KILL := 300.0
const COOLDOWN_COLLECT := 600.0
const COOLDOWN_BOSS := 1800.0
## ★ รอบ 142 ★ ช่องที่ 2 ออกใบ "เก็บวัตถุดิบ" ด้วยโอกาสเท่านี้ (ที่เหลือเป็นใบล่า) — ของขยะฟาร์มไว้เต็มตัว ไม่ควรออกบ่อย
const COLLECT_CHANCE := 0.35
const KILL_COUNTS := [20, 25, 30, 35, 40]
## เก็บวัตถุดิบ: จำนวน = เป้าล่า (ตัว) × โอกาสดรอป จำกัด 5-20 ชิ้น
const COLLECT_KILL_TARGET := [30, 35, 40]
const COLLECT_MIN_CHANCE := 15.0
## แร่ตีบวก: บท 1-3 ฟราคอน · บท 4+ เอ็มเวเรทาร์คอน (1-2 ก้อน)
const ORE_LOW := &"phracon"
const ORE_HIGH := &"emveretarcon"
const ORE_HIGH_FROM_CHAPTER := 4
## ของแถมใบธรรมดา (โอกาส) — ยาเลือด/ยามานาตามบท
const EXTRA_CHANCE := 0.35
const HP_POTION_BY_CHAPTER := {1: [&"red_potion", 3], 2: [&"orange_potion", 3], 3: [&"white_potion", 2], 4: [&"white_potion", 2], 5: [&"white_potion", 3], 6: [&"white_potion", 3], 7: [&"white_potion", 3]}
const SP_POTION_BY_CHAPTER := {1: [&"blue_potion", 2], 2: [&"blue_potion", 2], 3: [&"blue_potion_2", 2], 4: [&"blue_potion_2", 2], 5: [&"blue_potion_2", 2], 6: [&"blue_potion_2", 3], 7: [&"blue_potion_2", 3]}
## ของแถมใบล่าบอส (สลับกัน)
const BOSS_EXTRAS := [[&"thunder_blessing", 1], [&"wing_of_valkyrie", 1]]
## บอสที่มีฉากสคริปต์ของตัวเอง ไม่ออกใบล่า
const BOSS_EXCLUDE := [&"baphomet"]
const POINTS_NORMAL := 1
const POINTS_BOSS := 3
## ★ รอบ 159 ★ ธงที่ตั้งเมื่อส่งใบประกาศใบแรก (เควสบท 1 «ใบประกาศใบแรก» ใช้เป็นเงื่อนไข)
const FIRST_BOUNTY_FLAG := &"guild_first_bounty"

## ขั้นกิลด์: [ตัวอักษร, แต้มที่ต้องมี, ฉายา]
const RANKS := [
	["F", 0, "นักผจญภัยฝึกหัด"],
	["E", 20, "นักล่ามือใหม่"],
	["D", 50, "นักล่าประจำเมือง"],
	["C", 100, "นักล่ามือฉมัง"],
	["B", 200, "ผู้พิชิตใบประกาศ"],
	["A", 400, "มือล่าชั้นครู"],
	["S", 800, "ตำนานแห่งกิลด์"],
]

## ★ รอบ 158 ★ สิทธิพิเศษตามขั้นกิลด์ F..S — [ส่วนลด %, พรแห่งธอร์นานขึ้น (วินาที)]
## ส่วนลดใช้กับ: ซื้อของร้าน · ค่าวาร์ป · ค่าขอพร · ค่ารักษา · ค่าย่อยการ์ด · ค่าตีบวก
## เลื่อนขั้นทุกครั้ง = แต้มสเตตัสฟรี RANK_STAT_POINTS (เซฟเก่าที่ขั้นสูงอยู่แล้วได้ย้อนหลังตอนโหลด)
const RANK_PERKS := [
	[3, 30],
	[5, 60],
	[8, 90],
	[12, 120],
	[17, 180],
	[23, 240],
	[30, 300],
]
const RANK_STAT_POINTS := 10

## เมือง -> Array[Dictionary] (ใบ 3 ช่อง · ช่องที่ยังล็อกเป็น {} ว่าง)
var boards: Dictionary = {}
## แต้มกิลด์สะสม
var points: int = 0
## ส่งใบธรรมดาไปแล้วกี่ใบ ต่อเมือง
var turned_in: Dictionary = {}
## ส่งใบทั้งหมด (โชว์สถิติ)
var total_turned_in: int = 0
var serial: int = 0
## ★ รอบ 142 ★ "เมือง/ช่อง" -> unix time ที่ช่องนั้นออกใบใหม่ได้
var cooldowns: Dictionary = {}
## ★ รอบ 158 ★ แจกแต้มสเตตัสของขั้นกิลด์ไปถึงขั้น index ไหนแล้ว (กันแจกซ้ำ · เซฟคีย์ rank_rewarded)
var rank_rewarded: int = 0


# =========================================================
# ★ เควสใบประกาศ — QuestData ที่สร้างตอนรัน ★
# =========================================================
class BountyQuest extends QuestData:
	var spec: Dictionary = {}

	func objective_text(progress: int = 0) -> String:
		var list := steps()
		if list.is_empty():
			return ""
		return list[0].line(progress)

	func reward_text() -> String:
		var parts: Array[String] = []
		if reward_item_id != &"" and reward_item_count > 0:
			parts.append("%s x%d" % [GameData.item_name(reward_item_id), reward_item_count])
		var ex: StringName = StringName(spec.get("extra_id", &""))
		if ex != &"":
			parts.append("%s x%d" % [GameData.item_name(ex), int(spec.get("extra_count", 1))])
		if reward_zeny > 0:
			parts.append("%d z" % reward_zeny)
		if reward_exp > 0:
			parts.append("EXP %d" % reward_exp)
		parts.append("แต้มกิลด์ +%d" % int(spec.get("points", 1)))
		return "  ·  ".join(parts)


static func is_bounty(quest_id: StringName) -> bool:
	return String(quest_id).begins_with("bounty_")


# =========================================================
# บอร์ดของเมือง
# =========================================================
## เรียกทุกครั้งก่อนเปิดบอร์ด — เติมช่องที่ว่างให้ครบ (ช่องบอสจะว่างจนกว่าจะปลด)
func ensure_board(town: StringName) -> void:
	var list: Array = boards.get(town, [])
	while list.size() < SLOTS:
		list.append({})
	for i in range(SLOTS):
		var spec: Dictionary = list[i]
		if spec.is_empty():
			if i == BOSS_SLOT and not boss_unlocked(town):
				continue
			if cooldown_left(town, i) > 0.0:
				continue
			spec = _gen_spec(town, i)
			list[i] = spec
		if not spec.is_empty() and GameData.get_quest(StringName(spec["id"])) == null:
			_register(spec)
	boards[town] = list


func specs_of(town: StringName) -> Array:
	return boards.get(town, [])


func boss_unlocked(town: StringName) -> bool:
	return int(turned_in.get(town, 0)) >= BOSS_UNLOCK_TURNINS


func boss_turnins_left(town: StringName) -> int:
	return maxi(0, BOSS_UNLOCK_TURNINS - int(turned_in.get(town, 0)))


## ★ รอบ 142 ★ ช่องนี้ต้องรออีกกี่วินาทีถึงออกใบใหม่ (0 = ออกได้)
func cooldown_left(town: StringName, slot: int) -> float:
	var key := "%s/%d" % [String(town), slot]
	if not cooldowns.has(key):
		return 0.0
	var left: float = float(cooldowns[key]) - Time.get_unix_time_from_system()
	if left <= 0.0:
		cooldowns.erase(key)
		return 0.0
	return left


static func cooldown_of(kind: String) -> float:
	match kind:
		"boss":
			return COOLDOWN_BOSS
		"collect":
			return COOLDOWN_COLLECT
		_:
			return COOLDOWN_KILL


static func cooldown_text(seconds: float) -> String:
	var s := int(ceil(seconds))
	return "%d:%02d" % [s / 60, s % 60]


func reroll_cost(town: StringName) -> int:
	return REROLL_COST_PER_CHAPTER * maxi(1, MapAtlas.chapter_of(town))


## เปลี่ยนใบที่ยังไม่ได้รับ (จ่าย zeny ที่ NPC จัดการเอง) — คืน spec ใหม่
func reroll(town: StringName, slot: int) -> Dictionary:
	var list: Array = boards.get(town, [])
	if slot < 0 or slot >= list.size():
		return {}
	var old: Dictionary = list[slot]
	if not old.is_empty():
		_unregister(StringName(old["id"]))
	var spec := _gen_spec(town, slot, StringName(old.get("monster", &"")))
	list[slot] = spec
	boards[town] = list
	return spec


## ยกเลิกใบที่รับไว้ — ถอดออกจากสมุดเควส แล้วออกใบใหม่ในช่องนั้น
func abandon(quest_id: StringName) -> void:
	var log := PlayerState.quests
	if log != null:
		log.active.erase(quest_id)
		log.progress.erase(quest_id)
		Events.quest_changed.emit()
	_replace_slot_of(quest_id)


## เรียกจาก PlayerState.turn_in_quest หลังส่งใบสำเร็จ — แจกของแถม + แต้ม แล้วออกใบใหม่
func on_turned_in(quest_id: StringName) -> void:
	var q := GameData.get_quest(quest_id)
	var spec: Dictionary = (q as BountyQuest).spec if q is BountyQuest else {}
	var town: StringName = StringName(spec.get("town", &""))
	var ex: StringName = StringName(spec.get("extra_id", &""))
	if ex != &"":
		var inst := ItemInstance.create(ex, int(spec.get("extra_count", 1)))
		if inst != null and PlayerState.inventory.add(inst) > 0:
			Events.say("กระเป๋าเต็ม — %s ที่แถมมาเก็บไม่ได้" % GameData.item_name(ex))
	var pts: int = int(spec.get("points", POINTS_NORMAL))
	var before_rank := rank_index()
	points += pts
	total_turned_in += 1
	PlayerState.set_flag(FIRST_BOUNTY_FLAG)   # ★ รอบ 159 ★ เควส m3_guild_bounty «ใบประกาศใบแรก»
	if spec.get("kind", "") != "boss":
		turned_in[town] = int(turned_in.get(town, 0)) + 1
	# ใบประกาศไม่ค้างในรายการ "ทำเสร็จแล้ว" (ทำซ้ำได้เรื่อย ๆ)
	var log := PlayerState.quests
	if log != null:
		log.completed.erase(quest_id)
	# ★ รอบ 142 ★ ช่องนี้พักก่อนออกใบใหม่
	if town != &"" and spec.has("slot"):
		cooldowns["%s/%d" % [String(town), int(spec["slot"])]] = Time.get_unix_time_from_system() + cooldown_of(String(spec.get("kind", "kill")))
	_replace_slot_of(quest_id)
	if rank_index() > before_rank:
		var gain := claim_rank_rewards()   # ★ รอบ 158 ★
		Events.say("[กิลด์] เลื่อนขั้นเป็น %s — «%s» · แต้มสเตตัส +%d · ส่วนลด %d%% · พรแห่งธอร์ +%s" % [
			rank_letter(), rank_title(), gain, discount_percent(), bless_bonus_text(rank_index())])
	elif town != &"" and boss_unlocked(town) and int(turned_in.get(town, 0)) == BOSS_UNLOCK_TURNINS and spec.get("kind", "") != "boss":
		Events.say("[กิลด์] ใบล่าบอสของเมืองนี้เปิดแล้ว")
	Events.quest_changed.emit()


## ของแถมใส่กระเป๋าได้ไหม (เช็กก่อนส่ง เหมือนของรางวัลหลัก)
func can_receive_extra(quest_id: StringName) -> bool:
	var q := GameData.get_quest(quest_id)
	if not (q is BountyQuest):
		return true
	var bq := q as BountyQuest
	var ex: StringName = StringName(bq.spec.get("extra_id", &""))
	if ex == &"":
		return true
	var inst := ItemInstance.create(ex, int(bq.spec.get("extra_count", 1)))
	return inst == null or PlayerState.inventory.can_add(inst)


# =========================================================
# ขั้นกิลด์
# =========================================================
func rank_index() -> int:
	var idx := 0
	for i in range(RANKS.size()):
		if points >= int(RANKS[i][1]):
			idx = i
	return idx


func rank_letter() -> String:
	return String(RANKS[rank_index()][0])


func rank_title() -> String:
	return String(RANKS[rank_index()][2])


## แต้มที่ต้องมีสำหรับขั้นถัดไป (-1 = สูงสุดแล้ว)
func next_rank_points() -> int:
	var i := rank_index()
	return int(RANKS[i + 1][1]) if i + 1 < RANKS.size() else -1


# =========================================================
# ★ รอบ 158 ★ สิทธิพิเศษตามขั้น
# =========================================================
static func discount_of(idx: int) -> int:
	return int(RANK_PERKS[clampi(idx, 0, RANK_PERKS.size() - 1)][0])


static func bless_bonus_of(idx: int) -> float:
	return float(RANK_PERKS[clampi(idx, 0, RANK_PERKS.size() - 1)][1])


## แต้มสเตตัสฟรีรวมที่ขั้นนี้ให้ (F = 0 · E = 10 · … · S = 60)
static func stat_points_of(idx: int) -> int:
	return clampi(idx, 0, RANKS.size() - 1) * RANK_STAT_POINTS


static func bless_bonus_text(idx: int) -> String:
	var s := int(bless_bonus_of(idx))
	if s < 60:
		return "%d วินาที" % s
	return ("%d นาที" % int(s / 60.0)) if s % 60 == 0 else ("%d:%02d นาที" % [int(s / 60.0), s % 60])


func discount_percent() -> int:
	return discount_of(rank_index())


func bless_bonus_seconds() -> float:
	return bless_bonus_of(rank_index())


## ราคาหลังหักส่วนลดของขั้นนี้ (อย่างน้อย 1 z ถ้าของมีราคา)
func discounted(cost: int) -> int:
	if cost <= 0:
		return cost
	return maxi(1, int(round(float(cost) * float(100 - discount_percent()) / 100.0)))


## ใช้จากที่ไหนก็ได้ — ยังไม่มีข้อมูลกิลด์ = ราคาเต็ม
static func guild_price(cost: int) -> int:
	if PlayerState == null or PlayerState.bounties == null:
		return cost
	return PlayerState.bounties.discounted(cost)


## แจกแต้มสเตตัสของขั้นที่ยังไม่ได้รับ — คืนจำนวนแต้มที่แจก
func claim_rank_rewards() -> int:
	var idx := rank_index()
	if idx <= rank_rewarded:
		return 0
	var gain := (idx - rank_rewarded) * RANK_STAT_POINTS
	rank_rewarded = idx
	if PlayerState != null and PlayerState.stats != null:
		PlayerState.stats.stat_points += gain
		Events.stats_changed.emit()
	return gain


# =========================================================
# สร้างใบ
# =========================================================
func _replace_slot_of(quest_id: StringName) -> void:
	for town in boards.keys():
		var list: Array = boards[town]
		for i in range(list.size()):
			var spec: Dictionary = list[i]
			if not spec.is_empty() and StringName(spec["id"]) == quest_id:
				_unregister(quest_id)
				list[i] = {}
				boards[town] = list
				ensure_board(town)
				return


func _gen_spec(town: StringName, slot: int, avoid: StringName = &"") -> Dictionary:
	var chapter := maxi(1, MapAtlas.chapter_of(town))
	var lv: int = PlayerState.stats.level
	serial += 1
	var spec := {"id": "bounty_%s_%d_%d" % [String(town), slot, serial], "town": town, "chapter": chapter, "slot": slot}
	if slot == BOSS_SLOT:
		var boss := _pick_boss(chapter)
		if boss != null:
			spec["kind"] = "boss"
			spec["monster"] = boss.id
			spec["count"] = 1
			spec["exp"] = int(round(PlayerStats.exp_needed_at(boss.level) * EXP_SHARE_BOSS))
			spec["zeny"] = _round10(int((boss.zeny_min + boss.zeny_max) * 0.5 * ZENY_MULT_BOSS))
			spec["ore_count"] = 2
			var ex: Array = BOSS_EXTRAS[serial % BOSS_EXTRAS.size()]
			spec["extra_id"] = ex[0]
			spec["extra_count"] = int(ex[1])
			spec["points"] = POINTS_BOSS
			_fill_ore(spec, chapter)
			_register(spec)
			return spec
	var mons := _candidates(chapter, lv, avoid)
	if mons.is_empty():
		return {}
	var m: MonsterData = mons[randi() % mons.size()]
	var want_collect: bool = slot == 1 and randf() < COLLECT_CHANCE   # ★ รอบ 142 ★
	var collect := _pick_collect(m) if want_collect else {}
	if want_collect and collect.is_empty():
		# มอนตัวนี้ไม่มีวัตถุดิบดรอปพอ → ลองตัวอื่นในบท
		for other in mons:
			collect = _pick_collect(other)
			if not collect.is_empty():
				m = other
				break
	spec["monster"] = m.id
	var kills: int
	if not collect.is_empty():
		kills = int(COLLECT_KILL_TARGET[randi() % COLLECT_KILL_TARGET.size()])
		spec["kind"] = "collect"
		spec["item"] = collect["item"]
		spec["count"] = clampi(int(round(kills * float(collect["chance"]) / 100.0)), 5, 20)
	else:
		kills = int(KILL_COUNTS[randi() % KILL_COUNTS.size()])
		spec["kind"] = "kill"
		spec["count"] = kills
	spec["exp"] = int(round(PlayerStats.exp_needed_at(m.level) * (EXP_SHARE_COLLECT if not collect.is_empty() else EXP_SHARE)))
	spec["zeny"] = _round10(int((m.zeny_min + m.zeny_max) * 0.5 * kills * ZENY_MULT))
	spec["ore_count"] = 1 + (randi() % 2)
	spec["points"] = POINTS_NORMAL
	if randf() < EXTRA_CHANCE:
		var table: Dictionary = HP_POTION_BY_CHAPTER if randf() < 0.6 else SP_POTION_BY_CHAPTER
		var ex2: Array = table.get(mini(chapter, 7), table[7])
		if GameData.get_item(ex2[0]) != null:
			spec["extra_id"] = ex2[0]
			spec["extra_count"] = int(ex2[1])
	_fill_ore(spec, chapter)
	_register(spec)
	return spec


func _fill_ore(spec: Dictionary, chapter: int) -> void:
	spec["ore_id"] = ORE_HIGH if chapter >= ORE_HIGH_FROM_CHAPTER else ORE_LOW


static func _round10(v: int) -> int:
	return maxi(10, int(round(v / 10.0)) * 10)


## มอนธรรมดาในบทนี้ที่เลเวลใกล้ผู้เล่น
func _candidates(chapter: int, lv: int, avoid: StringName) -> Array:
	var near: Array = []
	var all: Array = []
	var seen: Array = []
	for mid in MapAtlas.maps_of_chapter(chapter):
		if MapAtlas.kind_of(mid) != MapAtlas.KIND_FIELD:
			continue
		for mon_id in MapAtlas.monsters_of(mid):
			if mon_id in seen or mon_id == avoid:
				continue
			seen.append(mon_id)
			var m := GameData.get_monster_info(mon_id)
			if m == null or m.is_boss:
				continue
			all.append(m)
			if absi(m.level - lv) <= LEVEL_WINDOW:
				near.append(m)
	if not near.is_empty():
		return near
	if all.is_empty():
		return all
	all.sort_custom(func(a, b): return absi(a.level - lv) < absi(b.level - lv))
	var best: int = absi(all[0].level - lv)
	return all.filter(func(m): return absi(m.level - lv) <= best + 3)


func _pick_boss(chapter: int) -> MonsterData:
	var found: Array = []
	for mid in MapAtlas.maps_of_chapter(chapter):
		if MapAtlas.kind_of(mid) != MapAtlas.KIND_BOSS:
			continue
		for mon_id in MapAtlas.monsters_of(mid):
			if mon_id in BOSS_EXCLUDE:
				continue
			var m := GameData.get_monster_info(mon_id)
			if m != null and m.is_boss and not (m in found):
				found.append(m)
	if found.is_empty():
		return null
	return found[randi() % found.size()]


## วัตถุดิบที่มอนดรอปบ่อยพอ (≥ COLLECT_MIN_CHANCE) — คืน {item, chance} หรือ {} ถ้าไม่มี
func _pick_collect(m: MonsterData) -> Dictionary:
	var opts: Array = []
	for d in m.drops:
		if d == null or d.item_id == &"" or d.chance < COLLECT_MIN_CHANCE:
			continue
		if d.item_id == ORE_LOW or d.item_id == ORE_HIGH:
			continue
		var it := GameData.get_item(d.item_id)
		if it == null or it.type != ItemData.Type.MATERIAL:
			continue
		opts.append({"item": d.item_id, "chance": d.chance})
	if opts.is_empty():
		return {}
	return opts[randi() % opts.size()]


func _register(spec: Dictionary) -> void:
	if spec.is_empty():
		return
	var q := BountyQuest.new()
	q.spec = spec
	q.id = StringName(spec["id"])
	var m := GameData.get_monster_info(StringName(spec["monster"]))
	var mname: String = m.display_name if m != null else String(spec["monster"])
	var o := ObjectiveData.new()
	match String(spec["kind"]):
		"collect":
			var iname := GameData.item_name(StringName(spec["item"]))
			q.title = "ใบประกาศ: %s %d ชิ้น" % [iname, int(spec["count"])]
			q.description = "กิลด์ต้องการ%s %d ชิ้น (ได้จาก%s)" % [iname, int(spec["count"]), mname]
			o.kind = ObjectiveData.Kind.COLLECT
			o.target = StringName(spec["item"])
			o.count = int(spec["count"])
			o.consume = true
		"boss":
			q.title = "ใบล่าบอส: %s" % mname
			q.description = "ใบประกาศพิเศษของกิลด์ — ปราบ%sให้ได้ 1 ครั้ง" % mname
			o.kind = ObjectiveData.Kind.KILL
			o.target = StringName(spec["monster"])
			o.count = 1
		_:
			q.title = "ใบประกาศ: ล่า%s %d ตัว" % [mname, int(spec["count"])]
			q.description = "กิลด์ประกาศล่า%s %d ตัว" % [mname, int(spec["count"])]
			o.kind = ObjectiveData.Kind.KILL
			o.target = StringName(spec["monster"])
			o.count = int(spec["count"])
	q.objectives = [o] as Array[ObjectiveData]
	q.giver_name = "บอร์ดกิลด์"
	q.dialog_offer = q.description
	q.dialog_progress = "ยังไม่ครบตามใบประกาศ"
	q.dialog_complete = "ครบตามใบประกาศแล้ว นี่ค่าตอบแทนจากกิลด์"
	q.required_level = 1
	q.repeatable = true
	q.reward_item_id = StringName(spec.get("ore_id", ORE_LOW))
	q.reward_item_count = int(spec.get("ore_count", 1))
	q.reward_zeny = int(spec.get("zeny", 0))
	q.reward_exp = int(spec.get("exp", 0))
	GameData.quests[q.id] = q


func _unregister(quest_id: StringName) -> void:
	GameData.quests.erase(quest_id)


## ป้ายสั้น ๆ ของใบ (ใช้ในเมนู)
static func short_label(spec: Dictionary) -> String:
	if spec.is_empty():
		return "(ยังไม่มีใบ)"
	var m := GameData.get_monster_info(StringName(spec.get("monster", &"")))
	var mname: String = m.display_name if m != null else String(spec.get("monster", ""))
	match String(spec.get("kind", "kill")):
		"collect":
			return "เก็บ%s %d ชิ้น" % [GameData.item_name(StringName(spec["item"])), int(spec["count"])]
		"boss":
			return "ล่าบอส %s" % mname
		_:
			return "ล่า%s %d ตัว" % [mname, int(spec["count"])]


# =========================================================
# เซฟ / โหลด
# =========================================================
func to_dict() -> Dictionary:
	var b: Dictionary = {}
	for town in boards.keys():
		var arr: Array = []
		for spec in boards[town]:
			arr.append(_spec_to_save(spec))
		b[String(town)] = arr
	var t: Dictionary = {}
	for town in turned_in.keys():
		t[String(town)] = int(turned_in[town])
	var cd: Dictionary = {}
	for k in cooldowns.keys():
		cd[String(k)] = float(cooldowns[k])
	return {"boards": b, "points": points, "turned_in": t, "total": total_turned_in, "serial": serial, "cooldowns": cd, "rank_rewarded": rank_rewarded}


func from_dict(d: Dictionary) -> void:
	boards.clear()
	turned_in.clear()
	cooldowns.clear()
	var cd = d.get("cooldowns", {})
	if cd is Dictionary:
		for k in cd.keys():
			cooldowns[String(k)] = float(cd[k])
	points = int(d.get("points", 0))
	rank_rewarded = int(d.get("rank_rewarded", 0))   # ★ รอบ 158 ★ เซฟเก่า = 0 → โหลดแล้วได้แต้มย้อนหลัง
	total_turned_in = int(d.get("total", 0))
	serial = int(d.get("serial", 0))
	var t = d.get("turned_in", {})
	if t is Dictionary:
		for k in t.keys():
			turned_in[StringName(k)] = int(t[k])
	var b = d.get("boards", {})
	if b is Dictionary:
		for k in b.keys():
			var list: Array = []
			for raw in b[k]:
				var spec := _spec_from_save(raw)
				list.append(spec)
				if not spec.is_empty():
					_register(spec)
			boards[StringName(k)] = list


static func _spec_to_save(spec: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in spec.keys():
		var v = spec[k]
		out[String(k)] = String(v) if v is StringName else v
	return out


static func _spec_from_save(raw) -> Dictionary:
	if not (raw is Dictionary) or raw.is_empty():
		return {}
	var spec: Dictionary = {}
	for k in raw.keys():
		var v = raw[k]
		if k in ["town", "monster", "item", "ore_id", "extra_id"]:
			spec[String(k)] = StringName(String(v))
		elif v is float:
			spec[String(k)] = int(v)
		else:
			spec[String(k)] = v
	return spec
