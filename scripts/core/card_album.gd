## CardAlbum — ★ รอบ 154 ★ «ฝังการ์ดเข้าสมุด» + «ย่อยการ์ด»
##
## ฝังเข้าสมุด: การ์ดแต่ละชนิดฝังได้ 1 ครั้ง (ใช้การ์ด 1 ใบ หายไป) → ได้โบนัสถาวรตามตาราง BONUS
##   โบนัสนี้ไม่อิงค่าตอนใส่ในอุปกรณ์ · ไม่มีดูดเลือด/ดูดมานา · เก็บใน PlayerState.card_album (เซฟคีย์ "card_album")
##   ★ เพิ่มการ์ดใหม่ ★ ใส่บรรทัดใน BONUS ด้วย (ไม่ใส่ = ฝังไม่ได้)
##   คีย์ที่ใช้ได้: atk def mdef hit flee crit max_hp max_sp str agi vit int dex luk
##                  aspd_percent crit_damage_percent skill_damage_percent move_speed_percent
##                  cooldown_reduction_percent max_hp_percent max_sp_percent def_percent
##
## ย่อยการ์ด: การ์ดเกรดเดียวกัน 5 ใบ → สุ่มการ์ดเกรดเดียวกัน 1 ใบ ที่ Lv ≤ Lv สูงสุดของใบที่ใส่
##   ย่อยได้เฉพาะเกรด 1-4 (ตำนานย่อยไม่ได้) · การ์ดบอส/หอร้อยชั้นใช้เป็นวัตถุดิบได้ แต่ไม่สุ่มออกมา
class_name CardAlbum
extends RefCounted

const BONUS := {
	# ---------- บท 1 ----------
	&"card_poring": {&"def": 1},
	&"card_fabre": {&"max_hp": 15},
	&"card_lunatic": {&"max_sp": 10},
	&"card_drops": {&"hit": 2},
	&"card_chonchon": {&"flee": 2},
	&"card_hornet": {&"atk": 2},
	&"card_wolf": {&"atk": 3},
	&"card_munak": {&"mdef": 3},
	&"card_orc_warrior": {&"str": 1},
	&"card_king_poring": {&"max_hp": 80, &"luk": 1},
	&"card_stormscar": {&"aspd_percent": 2.0},
	# ---------- บท 2 ----------
	&"card_pitman": {&"hit": 3},
	&"card_steel_beetle": {&"def": 2},
	&"card_ember_bat": {&"flee": 3},
	&"card_magma_slug": {&"max_hp": 40},
	&"card_forge_golem": {&"def": 3},
	&"card_silent_wraith": {&"crit": 1},
	&"card_rune_watcher": {&"max_sp": 30},
	&"card_forge_guardian": {&"def": 6, &"vit": 1},
	# ---------- บท 3 ----------
	&"card_root_crawler": {&"max_hp": 50},
	&"card_thorn_hound": {&"atk": 3},
	&"card_mist_sprite": {&"flee": 4},
	&"card_bog_lurker": {&"mdef": 3},
	&"card_baphomet_jr": {&"crit": 1},
	&"card_withered_treant": {&"vit": 1},
	&"card_vanir_sentinel": {&"def": 4},
	&"card_war_wraith": {&"str": 1},
	&"card_baphomet": {&"atk": 5, &"crit_damage_percent": 2.0},
	&"card_thorn_matriarch": {&"def": 5, &"max_hp": 100},
	&"card_gullveig_ember": {&"skill_damage_percent": 2.0},
	# ---------- บท 4 ----------
	&"card_frost_wolf": {&"hit": 3},
	&"card_snow_hawk": {&"move_speed_percent": 1.0},
	&"card_ice_troll": {&"max_hp": 80},
	&"card_snow_mammoth": {&"vit": 1},
	&"card_stone_soldier": {&"def": 4},
	&"card_echo_wraith": {&"int": 1},
	&"card_wall_shieldbearer": {&"def": 6, &"mdef": 4},
	&"card_stone_hrungnir": {&"atk": 8, &"str": 1},
	# ---------- บท 5 ----------
	&"card_hollow_moth": {&"aspd_percent": 1.0},
	&"card_light_moth": {&"max_sp": 30},
	&"card_crystal_stag": {&"agi": 1},
	&"card_light_eater_bloom": {&"mdef": 4},
	&"card_garden_keeper": {&"max_hp": 100},
	&"card_reflection": {&"crit": 2},
	&"card_water_nymph": {&"cooldown_reduction_percent": 1.0},
	&"card_hollow_elf": {&"dex": 1},
	&"card_light_forsaken": {&"crit_damage_percent": 3.0, &"aspd_percent": 1.0},
	&"card_radiant_alfr": {&"skill_damage_percent": 2.0, &"cooldown_reduction_percent": 1.0},
	# ---------- บท 6 ----------
	&"card_mist_ghost": {&"flee": 5},
	&"card_hel_hound": {&"atk": 5},
	&"card_drowned": {&"max_hp": 120},
	&"card_ferryman": {&"hit": 5},
	&"card_erased_voice": {&"crit_damage_percent": 2.0},
	&"card_name_warden": {&"def": 6},
	&"card_nidhogg_spawn": {&"atk": 6},
	&"card_false_judge": {&"skill_damage_percent": 3.0},
	&"card_chained_garm": {&"max_hp_percent": 2.0, &"def": 5},
	# ---------- บท 7 ----------
	&"card_cinder_hound": {&"atk": 7},
	&"card_slag_mantis": {&"dex": 2},
	&"card_chainbound_ogre": {&"def": 7},
	&"card_ash_knight": {&"str": 2},
	&"card_ember_oracle": {&"skill_damage_percent": 1.0},
	&"card_kiln_sentinel": {&"def": 10, &"def_percent": 2.0},
	&"card_oath_warden": {&"atk": 12, &"skill_damage_percent": 3.0},
	# ---------- หอร้อยชั้น ----------
	&"card_c8_root_jailer": {&"max_hp_percent": 3.0},
	&"card_c8_storm_cantor": {&"skill_damage_percent": 3.0},
	&"card_c8_mirror_hunter": {&"crit_damage_percent": 4.0},
	&"card_c8_name_eater": {&"atk": 15},
	&"card_c8_hour_warden": {&"cooldown_reduction_percent": 2.0},
	&"card_c8_tide_oracle": {&"max_sp_percent": 5.0},
	&"card_c8_sunforged_lion": {&"str": 3},
	&"card_c8_astral_archivist": {&"int": 3},
	&"card_c8_void_weaver": {&"move_speed_percent": 3.0, &"flee": 8},
	&"card_c8_crown_seraph": {&"def_percent": 3.0},
	# ---------- หอร้อยชั้น ชั้น 51-100 (รอบ 179) ----------
	&"card_c8_thunder_herald": {&"aspd_percent": 3.0},
	&"card_c8_cloud_shepherd": {&"max_hp_percent": 4.0},
	&"card_c8_bifrost_warden": {&"crit_damage_percent": 5.0},
	&"card_c8_forgotten_jailer": {&"def_percent": 4.0},
	&"card_c8_spear_valkyrie": {&"atk": 22},
	&"card_c8_last_hour": {&"cooldown_reduction_percent": 3.0},
	&"card_c8_ash_scribe": {&"skill_damage_percent": 4.0},
	&"card_c8_rot_gnawer": {&"vit": 4},
	&"card_c8_lie_weaver": {&"flee": 12, &"move_speed_percent": 4.0},
	&"card_c8_hammer_shadow": {&"str": 4, &"atk": 10},
}

## ★ รอบ 158 ★ โบนัส «ครบชุดบท» — ฝังการ์ดของบทนั้นครบทุกใบ (รวมการ์ดบอส) ได้โบนัสเพิ่มอีกก้อน
## รวมเข้า total() อัตโนมัติ · เพิ่มการ์ดใหม่ในบท = ใส่ id ในรายการ cards ของบทนั้นด้วย
const CHAPTER_SETS := [
	{"chapter": 1, "name": "บท 1", "cards": [&"card_poring", &"card_fabre", &"card_lunatic", &"card_drops", &"card_chonchon", &"card_hornet", &"card_wolf", &"card_munak", &"card_orc_warrior", &"card_king_poring", &"card_stormscar"],
		"bonus": {&"max_hp": 150, &"atk": 5}},
	{"chapter": 2, "name": "บท 2", "cards": [&"card_pitman", &"card_steel_beetle", &"card_ember_bat", &"card_magma_slug", &"card_forge_golem", &"card_silent_wraith", &"card_rune_watcher", &"card_forge_guardian"],
		"bonus": {&"def": 10, &"vit": 2}},
	{"chapter": 3, "name": "บท 3", "cards": [&"card_root_crawler", &"card_thorn_hound", &"card_mist_sprite", &"card_bog_lurker", &"card_baphomet_jr", &"card_withered_treant", &"card_vanir_sentinel", &"card_war_wraith", &"card_baphomet", &"card_thorn_matriarch", &"card_gullveig_ember"],
		"bonus": {&"atk": 12, &"crit_damage_percent": 3.0}},
	{"chapter": 4, "name": "บท 4", "cards": [&"card_frost_wolf", &"card_snow_hawk", &"card_ice_troll", &"card_snow_mammoth", &"card_stone_soldier", &"card_echo_wraith", &"card_wall_shieldbearer", &"card_stone_hrungnir"],
		"bonus": {&"max_hp_percent": 2.0, &"str": 2}},
	{"chapter": 5, "name": "บท 5", "cards": [&"card_hollow_moth", &"card_light_moth", &"card_crystal_stag", &"card_light_eater_bloom", &"card_garden_keeper", &"card_reflection", &"card_water_nymph", &"card_hollow_elf", &"card_light_forsaken", &"card_radiant_alfr"],
		"bonus": {&"skill_damage_percent": 3.0, &"aspd_percent": 2.0}},
	{"chapter": 6, "name": "บท 6", "cards": [&"card_mist_ghost", &"card_hel_hound", &"card_drowned", &"card_ferryman", &"card_erased_voice", &"card_name_warden", &"card_nidhogg_spawn", &"card_false_judge", &"card_chained_garm"],
		"bonus": {&"atk": 20, &"def_percent": 3.0}},
	{"chapter": 7, "name": "บท 7", "cards": [&"card_cinder_hound", &"card_slag_mantis", &"card_chainbound_ogre", &"card_ash_knight", &"card_ember_oracle", &"card_kiln_sentinel", &"card_oath_warden"],
		"bonus": {&"atk": 30, &"skill_damage_percent": 3.0, &"max_hp_percent": 3.0}},
	{"chapter": 8, "name": "หอ ชั้น 1-50", "cards": [&"card_c8_root_jailer", &"card_c8_storm_cantor", &"card_c8_mirror_hunter", &"card_c8_name_eater", &"card_c8_hour_warden", &"card_c8_tide_oracle", &"card_c8_sunforged_lion", &"card_c8_astral_archivist", &"card_c8_void_weaver", &"card_c8_crown_seraph"],
		"bonus": {&"str": 2, &"agi": 2, &"vit": 2, &"int": 2, &"dex": 2, &"luk": 2}},
	{"chapter": 8, "name": "หอ ชั้น 51-100", "cards": [&"card_c8_thunder_herald", &"card_c8_cloud_shepherd", &"card_c8_bifrost_warden", &"card_c8_forgotten_jailer", &"card_c8_spear_valkyrie", &"card_c8_last_hour", &"card_c8_ash_scribe", &"card_c8_rot_gnawer", &"card_c8_lie_weaver", &"card_c8_hammer_shadow"],   # ★ รอบ 179 ★
		"bonus": {&"atk": 25, &"max_hp_percent": 3.0, &"skill_damage_percent": 3.0}},
]

const KEY_NAMES := {
	&"atk": "ATK", &"def": "DEF", &"mdef": "MDEF", &"hit": "HIT", &"flee": "FLEE", &"crit": "CRIT",
	&"max_hp": "MaxHP", &"max_sp": "MaxSP", &"str": "STR", &"agi": "AGI", &"vit": "VIT",
	&"int": "INT", &"dex": "DEX", &"luk": "LUK",
	&"aspd_percent": "ASPD", &"crit_damage_percent": "ดาเมจคริ", &"skill_damage_percent": "ดาเมจสกิล",
	&"move_speed_percent": "ความเร็วเดิน", &"cooldown_reduction_percent": "ลดคูลดาวน์",
	&"max_hp_percent": "MaxHP", &"max_sp_percent": "MaxSP", &"def_percent": "DEF",
}
## ลำดับตอนโชว์ผลรวม
const KEY_ORDER := [&"atk", &"def", &"mdef", &"max_hp", &"max_hp_percent", &"max_sp", &"max_sp_percent", &"hit", &"flee", &"crit",
	&"str", &"agi", &"vit", &"int", &"dex", &"luk", &"def_percent", &"aspd_percent", &"skill_damage_percent",
	&"crit_damage_percent", &"cooldown_reduction_percent", &"move_speed_percent"]

# ---------- ย่อยการ์ด ----------
## เกรดสูงสุดที่ย่อยได้ (5 = ตำนาน · 6 = ตำนาน+ ย่อยไม่ได้)
const FUSION_MAX_GRADE := 4
const FUSION_COUNT := 5
## ค่าบริการ = FUSION_FEE_BASE × เกรด²  → 500 / 2,000 / 4,500 / 8,000 z
const FUSION_FEE_BASE := 500
## การ์ดบอส — ใช้ย่อยได้ แต่ไม่สุ่มออกมา (ต้องล่าเอง) · การ์ดหอร้อยชั้น (id ขึ้นต้น card_c8_) ก็เช่นกัน
const BOSS_CARDS := [&"card_king_poring", &"card_stormscar", &"card_forge_guardian", &"card_baphomet",
	&"card_thorn_matriarch", &"card_gullveig_ember", &"card_wall_shieldbearer", &"card_stone_hrungnir",
	&"card_light_forsaken", &"card_radiant_alfr", &"card_false_judge", &"card_chained_garm",
	&"card_kiln_sentinel", &"card_oath_warden"]


static func bonus_of(card_id: StringName) -> Dictionary:
	return BONUS.get(card_id, {})


static func can_deposit(card_id: StringName) -> bool:
	return not bonus_of(card_id).is_empty()


static func key_text(key: StringName, value: float) -> String:
	var nm: String = KEY_NAMES.get(key, String(key))
	if String(key).ends_with("_percent"):
		var v := ("%.1f" % value).trim_suffix(".0")
		return "%s +%s%%" % [nm, v] if key != &"cooldown_reduction_percent" else "%s %s%%" % [nm, v]
	return "%s +%d" % [nm, int(value)]


static func describe(bonus: Dictionary) -> String:
	var parts: Array[String] = []
	for k in KEY_ORDER:
		if bonus.has(k) and float(bonus[k]) != 0.0:
			parts.append(key_text(k, float(bonus[k])))
	for k in bonus.keys():
		if not (k in KEY_ORDER):
			parts.append(key_text(StringName(k), float(bonus[k])))
	return " · ".join(parts)


## รวมโบนัสจากการ์ดทุกใบที่ฝังแล้ว (+ โบนัสครบชุดบท ★ รอบ 158 ★)
static func total(deposited: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for cid in deposited.keys():
		var b: Dictionary = bonus_of(StringName(cid))
		for k in b.keys():
			out[k] = float(out.get(k, 0.0)) + float(b[k])
	for s: Dictionary in CHAPTER_SETS:
		if chapter_done(s, deposited):
			var sb: Dictionary = s["bonus"]
			for k in sb.keys():
				out[k] = float(out.get(k, 0.0)) + float(sb[k])
	return out


## ★ รอบ 158 ★ ฝังครบชุดบทนี้แล้วหรือยัง
static func chapter_done(s: Dictionary, deposited: Dictionary) -> bool:
	return chapter_count(s, deposited) >= (s["cards"] as Array).size()


static func chapter_count(s: Dictionary, deposited: Dictionary) -> int:
	var n := 0
	for cid in s["cards"]:
		if deposited.has(cid):
			n += 1
	return n


## ชุดบทที่การ์ดใบนี้อยู่ ({} = ไม่มี)
static func chapter_set_of(card_id: StringName) -> Dictionary:
	for s: Dictionary in CHAPTER_SETS:
		if (s["cards"] as Array).has(card_id):
			return s
	return {}


# =========================================================
# ย่อยการ์ด
# =========================================================
static func is_boss_card(card_id: StringName) -> bool:
	return card_id in BOSS_CARDS or String(card_id).begins_with("card_c8_")


static func fusion_fee(grade: int) -> int:
	return BountyBoard.guild_price(FUSION_FEE_BASE * grade * grade)   # ★ รอบ 158 ★ ส่วนลดขั้นกิลด์


static func grade_of(card: CardData) -> int:
	return card.rarity if card != null else 0


## การ์ดที่อาจได้: เกรดเดียวกัน · ไม่ใช่การ์ดบอส/หอ · Lv ≤ max_level — เรียงตาม Lv
static func fusion_pool(grade: int, max_level: int) -> Array[CardData]:
	var out: Array[CardData] = []
	for c: CardData in GameData.all_cards():
		if c.rarity != grade or is_boss_card(c.id):
			continue
		if c.sort_level() > max_level:
			continue
		out.append(c)
	out.sort_custom(func(a: CardData, b: CardData): return a.sort_level() < b.sort_level())
	return out


## ตรวจชุดที่เลือก — คืน {ok, reason, grade, max_level, pool, fee}
static func check_fusion(ids: Array) -> Dictionary:
	var res := {"ok": false, "reason": "", "grade": 0, "max_level": 0, "pool": [], "fee": 0}
	if ids.is_empty():
		res.reason = "เลือกการ์ด %d ใบเกรดเดียวกัน" % FUSION_COUNT
		return res
	var grade := -1
	var max_level := 0
	for cid in ids:
		var c := GameData.get_card(StringName(cid))
		if c == null:
			res.reason = "ไม่รู้จักการ์ด"
			return res
		if grade < 0:
			grade = c.rarity
		elif c.rarity != grade:
			res.reason = "ต้องเป็นการ์ดเกรดเดียวกันทั้งหมด"
			return res
		max_level = maxi(max_level, c.sort_level())
	res.grade = grade
	res.max_level = max_level
	res.fee = fusion_fee(grade)
	if grade > FUSION_MAX_GRADE:
		res.reason = "การ์ดระดับตำนานย่อยไม่ได้"
		return res
	res.pool = fusion_pool(grade, max_level)
	if (res.pool as Array).is_empty():
		res.reason = "ไม่มีการ์ดเกรดนี้ที่ Lv ≤ %d ให้สุ่ม — ใส่การ์ดที่ Lv สูงกว่านี้" % max_level
		return res
	if ids.size() < FUSION_COUNT:
		res.reason = "ใส่อีก %d ใบ" % (FUSION_COUNT - ids.size())
		return res
	res.ok = true
	return res
