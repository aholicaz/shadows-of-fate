extends RefCounted
## Hundred-floor story ascent; individual scenes keep memory bounded.
## ★ รอบ 179 ★ ขยาย 50 → 100 ชั้น (ธีม 10-19 · ผู้คุมใหม่ 10 ตัว · UPPER_PACKS 6-15)
const FLOOR_COUNT := 100
## ★ รอบ 182 ★ ชั้น 51-100: มอนเวฟมีโอกาสเป็นแชมเปี้ยนตราทอง (เวฟละไม่เกิน 1 ตัว · ไม่มีตราแตกร่าง)
const CHAMPION_CHANCE := 0.12
const CHAMPION_FROM_FLOOR := 51
const Loot = preload("res://scripts/world/chapter8_loot.gd")
# Session-only GM preview, never serialized as story progress.
static var gm_test := false
const THEMES := ["รากแห่งความทรงจำ", "กิ่งพายุเยือกแข็ง", "สวนสะท้อนนาม", "เส้นเลือดคำสาบาน", "กิ่งนาฬิกาหยุดเวลา", "บึงจันทร์เหนือเมฆ", "เตาหลอมดวงอาทิตย์", "หอจดหมายเหตุดารา", "รอยแยกไร้ชื่อ", "มงกุฎแห่งรุ่งอรุณ",
	"กิ่งฟ้าคำราม", "ทะเลเมฆเหนือยอดไม้", "สะพานรุ้งร้าว", "คุกเทพที่ถูกลืม", "ลานหอกวาลคีรี", "หอนาฬิกาปลายกาล", "หอจดหมายเหตุต้องห้าม", "รากเน่าใต้บัลลังก์", "รอยแยกแห่งคำโกหก", "ประตูแอสการ์ด"]
const BOSSES := ["king_poring", "stormscar", "baphomet", "forge_guardian", "thorn_matriarch", "wall_shieldbearer", "stone_hrungnir", "forge_guardian", "stormscar", "stone_hrungnir", "radiant_alfr", "light_forsaken", "gullveig_ember", "baphomet", "radiant_alfr", "false_judge", "chained_garm", "kiln_sentinel", "oath_warden", "chained_garm"]
const PACKS := [
	["poring", "lunatic", "fabre", "wolf", "hornet", "orc_warrior", "munak", "baphomet_jr"],
	["pitman", "steel_beetle", "forge_golem", "rune_watcher", "silent_wraith", "root_crawler", "thorn_hound", "war_wraith"],
	["frost_wolf", "snow_hawk", "ice_troll", "stone_soldier", "echo_wraith", "crystal_stag", "reflection", "hollow_elf"],
	["hel_hound", "mist_ghost", "drowned", "name_warden", "nidhogg_spawn", "cinder_hound", "ash_knight", "ember_oracle", "chainbound_ogre"]]
const PAIRS := [
	["king_poring", "stormscar"], ["forge_guardian", "thorn_matriarch"],
	["baphomet", "wall_shieldbearer"], ["stone_hrungnir", "light_forsaken"],
	["c8_mirror_hunter", "radiant_alfr"], ["gullveig_ember", "forge_guardian"],
	["false_judge", "chained_garm"], ["baphomet", "kiln_sentinel"],
	["oath_warden", "radiant_alfr"], ["c8_name_eater", "chained_garm"]]
const HEAVY := ["orc_warrior", "forge_golem", "steel_beetle", "ice_troll", "stone_soldier", "name_warden", "ash_knight", "chainbound_ogre"]
const SWARM := ["poring", "lunatic", "fabre", "root_crawler", "drowned", "cinder_hound"]

static func wave_sizes(number: int) -> Array:
	if number <= 5: return [6, 7, 7]
	if number <= 10: return [8, 8, 8]
	if number <= 15: return [6, 6, 7, 7]
	if number <= 30: return [7, 7, 8, 8]
	if number <= 40: return [8, 8, 8, 8]
	if number <= 80: return [7, 7, 7, 7, 8]
	return [8, 8, 8, 8, 8]

static func wave_roster(number: int, wave: int) -> Array:
	if number == 1:
		return [["poring", "poring", "poring", "lunatic", "lunatic", "lunatic"], ["fabre", "fabre", "fabre", "wolf", "wolf", "wolf", "wolf"], ["orc_warrior", "orc_warrior", "wolf", "wolf", "wolf", "hornet", "hornet"]][wave]
	var pool: Array = PACKS[theme(number)] if number <= 20 else UPPER_PACKS[theme(number) - 4]
	var result: Array = []
	# Six species per floor, three per wave; rotating pairs avoid identical encounters.
	for i in range(wave_sizes(number)[wave]):
		result.append(pool[((number - 1) * 2 + wave + i % 3) % pool.size()])
	return result

static func boss_roster(number: int) -> Array:
	if number > 20:
		var old: String = BOSSES[(number * 3) % BOSSES.size()]
		if number % 5 == 0: return [NEW_IDS[theme(number)], old]
		var other: String = BOSSES[(number * 3 + 5) % BOSSES.size()]
		if old == other: other = "king_poring" if old != "king_poring" else "baphomet"
		return [old, other]
	if number >= 11: return PAIRS[number - 11]
	if number % 5 == 0: return [NEW_IDS[theme(number)], BOSSES[number - 1]]
	return [BOSSES[number - 1]]

const NEW_IDS := Loot.GUARDIANS
const NEW_NAMES := ["เวอร์ดัน ผู้คุมรากพันธนาการ", "สกาลด์ ผู้ขับลำนำพายุ", "อีรา ผู้ล่าหลังเงาสะท้อน", "นามสูญ ผู้กลืนทะเบียน", "โฮรา ผู้คุมชั่วโมง", "เซเลน ผู้พยากรณ์กระแสจันทร์", "สุริยราช สิงห์เตาหลอม", "อัสตรา ผู้รักษาดารา", "เนธรา ผู้ทอสุญญะ", "ออโรรา ผู้พิทักษ์มงกุฎ",
	"บรอนน์ ผู้ป่าวประกาศอสุนี", "เมฆา ผู้ต้อนฝูงเมฆ", "ไอริส ผู้เฝ้าสะพานรุ้งร้าว", "กริมนีร์ ผู้คุมเทพที่ถูกลืม", "เฮลกา วาลคีรีหอกหัก", "เอออน ผู้เฝ้าปลายกาล", "สคริฟ ผู้เผาพงศาวดาร", "เนียด ผู้แทะรากบัลลังก์", "ลุกเนอร์ ผู้ถักคำโกหก", "เงาแห่งค้อน ผู้เฝ้าประตูทอง"]
const SKILL_NAMES := ["คุกราก • ออกจากแนวอักขระ", "ลำนำพายุ • หลบแนวฟ้าผ่าสามจังหวะ", "เงาไล่ล่า • อย่าถอยกลับรอยเดิม", "พิพากษานาม • สลับช่องว่าง", "ลูกตุ้มย้อนเวลา • หลบแล้วกลับช่องเดิม", "น้ำขึ้นจันทร์ดับ • กระโดดคลื่นและหลบเสา", "สุริยะล่าเหยื่อ • หลบกรงเล็บก่อนแสงระเบิด", "วงโคจรปิดนาม • เคลื่อนตามช่องว่าง", "ใยสุญญะ • ออกขอบก่อนกลับกลาง", "รุ่งอรุณสุดท้าย • อ่านลำดับสามผนึก",
	"อสุนีป่าวประกาศ • หลบฟ้าผ่าแล้วพุ่งผ่านรากกวาด", "คลื่นเมฆ • พุ่งผ่านคลื่นต่ำ แล้วอย่ายืนกลางวง", "สะพานรุ้งแตก • ขยับหนีเป้าแล้วหาช่องว่าง", "โซ่คุกเทพ • ออกจากเสาแล้วเข้ากลางวง", "หอกร่วงฟ้า • ถอยจากกลางแล้วหลบฟ้าผ่า", "เข็มปลายกาล • ตามจังหวะลูกตุ้มแล้วหาช่องว่าง", "เผาพงศาวดาร • อ่านช่องว่างสองชุดติดกัน", "รากเน่ากลืนบัลลังก์ • เข้าออกวงแล้วพุ่งผ่านคลื่น", "ใยคำโกหก • ออกขอบแล้วขยับหนีเป้า", "เงาค้อนพิพากษา • อ่านสามผนึกแล้วหลบกรงเล็บ"]
const UPPER_PACKS := [
	["steel_beetle", "rune_watcher", "forge_golem", "stone_soldier", "ash_knight", "reflection", "pitman", "chainbound_ogre"],
	["drowned", "mist_ghost", "frost_wolf", "crystal_stag", "echo_wraith", "snow_hawk", "hollow_elf", "silent_wraith"],
	["cinder_hound", "ember_oracle", "ash_knight", "forge_golem", "hel_hound", "orc_warrior", "steel_beetle", "chainbound_ogre"],
	["rune_watcher", "reflection", "hollow_elf", "crystal_stag", "name_warden", "echo_wraith", "ember_oracle", "silent_wraith"],
	["nidhogg_spawn", "war_wraith", "hel_hound", "name_warden", "mist_ghost", "baphomet_jr", "thorn_hound", "chainbound_ogre"],
	["crystal_stag", "stone_soldier", "ash_knight", "rune_watcher", "nidhogg_spawn", "ice_troll", "ember_oracle", "reflection"],
	# ★ รอบ 179 ★ ชั้น 51-100
	["snow_hawk", "frost_wolf", "war_wraith", "stone_soldier", "echo_wraith", "ice_troll", "slag_mantis", "ash_knight"],   # กิ่งฟ้าคำราม
	["light_moth", "hollow_moth", "water_nymph", "mist_sprite", "mist_ghost", "crystal_stag", "snow_hawk", "erased_voice"],   # ทะเลเมฆเหนือยอดไม้
	["reflection", "crystal_stag", "light_eater_bloom", "garden_keeper", "hollow_elf", "light_moth", "water_nymph", "rune_watcher"],   # สะพานรุ้งร้าว
	["chainbound_ogre", "name_warden", "erased_voice", "ferryman", "silent_wraith", "war_wraith", "stone_soldier", "nidhogg_spawn"],   # คุกเทพที่ถูกลืม
	["ash_knight", "stone_soldier", "vanir_sentinel", "war_wraith", "ember_oracle", "slag_mantis", "frost_wolf", "chainbound_ogre"],   # ลานหอกวาลคีรี
	["rune_watcher", "forge_golem", "steel_beetle", "echo_wraith", "silent_wraith", "reflection", "ice_troll", "hollow_elf"],   # หอนาฬิกาปลายกาล
	["name_warden", "erased_voice", "ember_oracle", "rune_watcher", "hollow_elf", "reflection", "war_wraith", "ferryman"],   # หอจดหมายเหตุต้องห้าม
	["root_crawler", "withered_treant", "thorn_hound", "bog_lurker", "nidhogg_spawn", "hel_hound", "drowned", "light_eater_bloom"],   # รากเน่าใต้บัลลังก์
	["reflection", "mist_ghost", "hel_hound", "nidhogg_spawn", "erased_voice", "echo_wraith", "silent_wraith", "baphomet_jr"],   # รอยแยกแห่งคำโกหก
	["ash_knight", "chainbound_ogre", "ember_oracle", "name_warden", "stone_soldier", "war_wraith", "cinder_hound", "slag_mantis"]   # ประตูแอสการ์ด
]

static func floor_id(number: int) -> StringName:
	return StringName("yggdrasil_%02d" % number)

static func clear_flag(number: int) -> StringName:
	return StringName("c8_floor_%02d_clear" % number)

static func theme(number: int) -> int:
	return clampi((number - 1) / 5, 0, THEMES.size() - 1)

static func can_enter(number: int) -> bool:
	return number >= 1 and number <= FLOOR_COUNT and (gm_test or (PlayerState.has_flag(&"chapter7_done") and (number == 1 or PlayerState.has_flag(clear_flag(number - 1)))))

static func make_enemy(source: MonsterData, number: int, boss: bool, guardian := false) -> MonsterData:
	# Shallow copy intentionally shares immutable animation/texture resources only.
	# Never mutate the campaign resource or its drop entries.
	var result := source.duplicate() as MonsterData
	result.set_meta("tower_source", source.id)
	result.set_meta("tower_floor", number)
	result.set_meta("tower_guardian", guardian)
	result.id = StringName("c8_%02d_%s" % [number, source.id])
	result.display_name = "%s · ชั้น %d" % [source.display_name, number]
	result.level = 110 + number
	var step := float(number - 1)
	# Continue the Chapter 7 curve, including reused early-chapter creatures.
	var hp_base := 380000.0 if boss else 56000.0
	if guardian: hp_base = 520000.0
	var hp_scale := 1.0
	var attack_scale := 1.0
	if boss and (number >= 11 or number % 5 == 0):
		hp_scale = 0.65
		attack_scale = 0.85
	elif not boss:
		hp_scale = 0.65 if String(source.id) in HEAVY else (0.30 if String(source.id) in SWARM else 0.40)
		attack_scale = 0.85 if String(source.id) in HEAVY else (0.60 if String(source.id) in SWARM else 0.72)
	result.max_hp = int(hp_scale * hp_base * (1.0 + step * 0.052))
	result.atk_max = int(attack_scale * (2700.0 if boss else 2000.0) * (1.0 + step * 0.027))
	result.atk_min = int(result.atk_max * 0.88)
	result.def = int((170.0 if boss else 135.0) + step * 2.5)
	result.mdef = int(result.def * 0.75)
	result.hit = 205 + number * 2
	result.flee = 42 + number
	result.crit = mini(source.crit, 5)
	result.is_boss = boss
	result.use_boss_bar = boss
	result.boss_arena_aggro = boss
	result.ai_type = MonsterData.AIType.AGGRESSIVE
	result.move_speed = clampf(source.move_speed, 100.0, 190.0) * (1.0 + step * 0.005)
	result.detect_range = 5000.0
	result.leash_range = 0.0
	result.calm_if_flag = &""
	result.calm_if_item = &""
	result.spawn_lines = PackedStringArray()
	result.death_lines = PackedStringArray()
	result.intro_video = ""
	result.death_video = ""
	result.respawn_persistent = false
	result.respawn_time = 0.1
	result.respawn_time_persistent = 0.1
	# EXP remains first-clear only. Legitimate re-entry supports money and equipment hunting.
	result.exp_reward = 0
	result.job_exp_reward = 0
	result.zeny_min = 0 if gm_test else (1000 + number * 60 if boss else 80 + number * 5)
	result.zeny_max = 0 if gm_test else int(result.zeny_min * 1.4)
	# The empty branch of a ternary is an untyped Array in GDScript.
	# Assign the typed table first and clear only the duplicate in GM mode.
	result.drops = Loot.table(source, number, boss)
	if gm_test: result.drops.clear()
	result.attack_cooldown = clampf(source.attack_cooldown, 1.6, 1.9)
	if boss:
		result.skill_damage_mult = clampf(source.skill_damage_mult, 3.0, 6.0)   # ★ รอบ 153/179 ★ (เดิม 2.4-3.0)
		result.skill_chance = 0.8
	if guardian:
		result.skill_chance = 1.0
		result.skill_range = 2200.0
		result.skill_cooldown = 7.5 if number <= 50 else 11.0   # ★ รอบ 179 ★ ท่าผสม 2 ชุดยาวขึ้น
		result.skill_windup = 1.35
		result.skill_duration = 4.4
	elif boss:
		result.skill_cooldown = maxf(6.0, source.skill_cooldown * (0.95 - step * 0.008))
		result.skill_windup = maxf(0.9, source.skill_windup)
	return result

# Fixed first-clear rewards; independent of the number of spawned enemies.
static func clear_exp(number: int) -> int:
	return floori(PlayerStats.exp_needed_at(110 + clampi(number, 1, FLOOR_COUNT)) * (0.20 if number <= 20 else 0.40))

static func repeat_exp(number: int) -> int:
	return floori(PlayerStats.exp_needed_at(110 + clampi(number, 1, FLOOR_COUNT)) * 0.05)

static func clear_job_exp(number: int) -> int:
	return 8000 + clampi(number, 1, FLOOR_COUNT) * 400
