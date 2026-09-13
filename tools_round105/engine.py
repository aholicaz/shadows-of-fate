# -*- coding: utf-8 -*-
## ★★ รอบ 105 — งานเอนจินที่บท 4-6 ต้องใช้ ★★  (เรียกจาก gen_round105.py)
##
## ทุกจุดแก้แบบ "เช็คก่อน แก้เฉพาะที่ยังไม่มี" (patch) — รันซ้ำได้ · สำรอง *_ก่อนรอบ105.bak
##
##  A. objective_data.gd   เงื่อนไขเควสชนิดใหม่ SKILL_HIT ("ตีมอน X ด้วยสกิล Y")
##  B. quest_log.gd        on_skill_hit() · player_state.gd ต่อสัญญาณ runic_hit
##  C. map_base.gd         ★ ร่างที่สอง (กลางคืน / ร่างจาง) ★ variant_flag + กลุ่ม light_only / dim_only
##  D. hud.gd              ชื่ออาชีพว่าง "ไร้นาม" หลังทิ้งชื่อ (บท 6) · สีทองเมื่อเป็น Ninth Edge
##  E. monster_data/base   มอนไม่โจมตีถ้ามีธง/ไอเทม · ย้อมสี (ผี/เงาสะท้อน) · พูดตอนเกิด
##  F. player_state.gd     reward_job รองรับหลายอาชีพ (ninth_edge) · is_rune_job()
##  G. skill_book.gd       สกิล Ninth Edge 6 ตัว · แต้มรูนสูงสุด 30 → 45
##  H. runeblade_combat.gd รูนสะสม 4 · Twin Inscription · Erasing Cut · Ninth Inscription
##  I. death_popup.gd      คำอวยพรจากธอร์ชุดบท 4-5 / บท 6
##  J. game.gd + map_atlas.gd  ทะเบียนแมพบท 4-6
##  K. quest_data.gd       reward_job_map
##  L. npc.gd              show_if_flag / hide_if_flag
##  N. lore_object.gd      auto_read (เดินถึงแล้วนับเลย — objective "ไปให้ถึงจุด")
from common import patch, w, LOG


def apply():
    # =========================================================
    # A. objective_data.gd — SKILL_HIT
    # =========================================================
    patch("scripts/resources/objective_data.gd", [
        ('	FLAG,     ## ธงเนื้อเรื่องถูกตั้งแล้ว — Target = ชื่อธง (นับสด ๆ)\n}',
         '	FLAG,     ## ธงเนื้อเรื่องถูกตั้งแล้ว — Target = ชื่อธง (นับสด ๆ)\n'
         '	## ★ รอบ 105 ★ ตีมอนด้วยสกิล — Target = "id มอน|สกิล" เช่น "wall_shieldbearer|sunder"\n'
         '	## ฝั่งสกิลใส่ id สกิล หรือชื่อกลุ่ม: sunder (สายหนัก) · edge (สายคริ) · ninth (สกิล Ninth Edge)\n'
         '	## ใส่หลายอันคั่นด้วย , · ฝั่งมอนใส่ * = มอนตัวไหนก็ได้\n'
         '	SKILL_HIT,\n}'),
        ('		Kind.FLAG:\n			return String(target)\n	return String(target)',
         '		Kind.FLAG:\n			return String(target)\n'
         '		Kind.SKILL_HIT:\n'
         '			var m2 := GameData.get_monster(skill_hit_monster())\n'
         '			var who := "มอนตัวไหนก็ได้" if skill_hit_monster() == &"*" else (m2.display_name if m2 != null else String(skill_hit_monster()))\n'
         '			return "ใช้%s โดน %s" % [skill_hit_label(), who]\n'
         '	return String(target)\n\n\n'
         '# =========================================================\n'
         '# ★ รอบ 105 ★ SKILL_HIT — "ตีมอน X ด้วยสกิล Y"\n'
         '# =========================================================\n'
         '## กลุ่มสกิลที่เควสอ้างถึงได้ด้วยชื่อสั้น ๆ\n'
         'const SKILL_GROUPS := {\n'
         '	"sunder": [&"anvil_cleave", &"faultline", &"worldcleaver"],\n'
         '	"edge": [&"rune_flurry", &"unbroken_edge", &"rune_echo"],\n'
         '	"ninth": [&"erasing_cut", &"ninth_inscription", &"twin_inscription", &"twin_echo"],\n'
         '}\n'
         'const SKILL_GROUP_NAMES := {"sunder": "สกิลสาย Sunder (ดาบหนัก)", "edge": "สกิลสาย Edge (คม)", "ninth": "สกิล Ninth Edge"}\n\n\n'
         'func skill_hit_monster() -> StringName:\n'
         '	var s := String(target)\n'
         '	return StringName(s.get_slice("|", 0).strip_edges()) if "|" in s else &"*"\n\n\n'
         'func skill_hit_skills() -> Array:\n'
         '	var s := String(target)\n'
         '	var part := s.get_slice("|", 1) if "|" in s else s\n'
         '	var out: Array = []\n'
         '	for p in part.split(",", false):\n'
         '		var k := String(p).strip_edges()\n'
         '		if SKILL_GROUPS.has(k):\n'
         '			out.append_array(SKILL_GROUPS[k])\n'
         '		elif k != "":\n'
         '			out.append(StringName(k))\n'
         '	return out\n\n\n'
         'func skill_hit_label() -> String:\n'
         '	var s := String(target)\n'
         '	var part := s.get_slice("|", 1) if "|" in s else s\n'
         '	var names: Array[String] = []\n'
         '	for p in part.split(",", false):\n'
         '		var k := String(p).strip_edges()\n'
         '		if SKILL_GROUP_NAMES.has(k):\n'
         '			names.append(String(SKILL_GROUP_NAMES[k]))\n'
         '		else:\n'
         '			var sk := GameData.get_skill(StringName(k))\n'
         '			names.append(sk.display_name if sk != null else k)\n'
         '	return "/".join(names)\n\n\n'
         '## เหตุการณ์ "สกิล skill_id โดนมอน monster_id" ตรงกับเงื่อนไขนี้ไหม\n'
         'func matches_skill_hit(monster_id: StringName, skill_id: StringName) -> bool:\n'
         '	if kind != Kind.SKILL_HIT:\n'
         '		return false\n'
         '	var m := skill_hit_monster()\n'
         '	if m != &"*" and m != monster_id:\n'
         '		return false\n'
         '	return skill_id in skill_hit_skills()'),
    ], markers=('SKILL_HIT,', 'func matches_skill_hit'))

    # =========================================================
    # B. quest_log.gd — on_skill_hit  ·  player_state.gd — ต่อสัญญาณ
    # =========================================================
    patch("scripts/core/quest_log.gd", [
        ('## เรียกเมื่อกระเป๋าหรือธงเปลี่ยน — ชนิดที่นับสดไม่ต้องบวกเลข แค่แจ้งให้ UI รู้\nfunc refresh_live() -> void:',
         '## ★ รอบ 105 ★ ตีมอนด้วยสกิล — เงื่อนไขชนิด SKILL_HIT (เช่น "ล้มผู้ถือโล่ด้วยสกิลสาย Sunder")\n'
         'func on_skill_hit(monster_id: StringName, skill_id: StringName) -> void:\n'
         '	for qid in active.duplicate():\n'
         '		var q := GameData.get_quest(qid)\n'
         '		if q == null:\n'
         '			continue\n'
         '		var list := q.steps()\n'
         '		var touched := false\n'
         '		for i in range(list.size()):\n'
         '			var o := list[i]\n'
         '			if not o.matches_skill_hit(monster_id, skill_id):\n'
         '				continue\n'
         '			var before := count_of(qid, i)\n'
         '			if before >= o.need():\n'
         '				continue\n'
         '			_set_progress(qid, i, before + 1, list.size())\n'
         '			touched = true\n'
         '			Events.quest_progress.emit(qid, before + 1, o.need())\n'
         '		if touched:\n'
         '			Events.quest_changed.emit()\n'
         '			_announce_if_ready(qid, q)\n\n\n'
         '## เรียกเมื่อกระเป๋าหรือธงเปลี่ยน — ชนิดที่นับสดไม่ต้องบวกเลข แค่แจ้งให้ UI รู้\nfunc refresh_live() -> void:'),
    ], markers=('func on_skill_hit',))

    patch("scripts/core/player_state.gd", [
        ('	Events.map_changed.connect(_on_map_changed)\n	Events.inventory_changed.connect(_on_inventory_changed)\n',
         '	Events.map_changed.connect(_on_map_changed)\n	Events.inventory_changed.connect(_on_inventory_changed)\n'
         '	Events.runic_hit.connect(_on_runic_hit)   # ★ รอบ 105 ★ เควสชนิด "ตีมอนด้วยสกิล"\n'),
        ('func _on_map_changed(map_id: StringName) -> void:',
         '## ★ รอบ 105 ★ สกิลโดนมอน → เดินเควสชนิด SKILL_HIT\n'
         'func _on_runic_hit(target: Node, source: StringName, _critical: bool) -> void:\n'
         '	if quests == null or target == null or not is_instance_valid(target):\n'
         '		return\n'
         '	var d = target.get("data")\n'
         '	if d != null and source != &"":\n'
         '		quests.on_skill_hit(d.id, source)\n\n\n'
         '## ★ รอบ 105 ★ อาชีพสายรูน (Runeblade และขั้นถัดไป Ninth Edge) — ใช้แทนการเช็ค == &"runeblade" ตรง ๆ\n'
         'func is_rune_job() -> bool:\n'
         '	return stats != null and stats.job_id in [&"runeblade", &"ninth_edge"]\n\n\n'
         'func _on_map_changed(map_id: StringName) -> void:'),
        # F. reward_job หลายอาชีพ — แมพที่ต้องส่งอ่านจาก reward_job_map ของเควส
        ('			(q.required_job != &"" and stats.job_id != q.required_job) or\n			current_map_id != &"vanir_town"):',
         '			(q.required_job != &"" and stats.job_id != q.required_job) or\n'
         '			(q.reward_job_map != &"" and current_map_id != q.reward_job_map)):   # ★ รอบ 105 ★'),
        ('	if q.reward_job == &"runeblade":\n		stats.job_id = &"runeblade"\n		set_flag(&"runeblade_awakened")\n		set_flag(&"runeblade_start_job_level", stats.job_level)\n		set_flag(&"runeblade_start_level", stats.level)\n		refresh()\n		Events.skills_changed.emit()',
         '	# ★ รอบ 105 ★ เปลี่ยนอาชีพได้ทุกอาชีพที่มีไฟล์ data/jobs/<id>.tres (runeblade · ninth_edge ...)\n'
         '	if q.reward_job != &"" and GameData.get_job(q.reward_job) != null:\n'
         '		var jid := String(q.reward_job)\n'
         '		stats.job_id = q.reward_job\n'
         '		set_flag(StringName(jid + "_awakened"))\n'
         '		set_flag(StringName(jid + "_start_job_level"), stats.job_level)\n'
         '		set_flag(StringName(jid + "_start_level"), stats.level)\n'
         '		set_flag(StringName("job_" + jid))\n'
         '		refresh()\n'
         '		Events.skills_changed.emit()'),
    ], markers=('_on_runic_hit)', 'func is_rune_job', 'q.reward_job_map != &""', 'jid + "_awakened"'))

    # K. quest_data.gd — reward_job_map
    patch("scripts/resources/quest_data.gd", [
        ('@export var reward_job: StringName = &""\n',
         '@export var reward_job: StringName = &""\n'
         '## ★ รอบ 105 ★ ต้องส่งเควสเปลี่ยนอาชีพในแมพนี้ (ว่าง = ที่ไหนก็ได้) — ค่าเริ่มต้นวานาเฮมตามพิธี Runeblade เดิม\n'
         '@export var reward_job_map: StringName = &"vanir_town"\n'),
    ], markers=('reward_job_map',))

    # =========================================================
    # C. map_base.gd — ร่างที่สอง (กลางคืน / ร่างจาง) + campaign บท 4-6
    # =========================================================
    patch("scripts/world/map_base.gd", [
        ('@export_group("")\n@export var player_scene: PackedScene',
         '# =========================================================\n'
         '# ★★ ร่างที่สองของแมพ (รอบ 105) ★★  กำแพงตอนกลางคืน (บท 4) · ร่างจางของอัลฟ์เฮม (บท 5)\n'
         '#\n'
         '# แมพเดียวกันมี 2 ร่าง สลับด้วยธงเนื้อเรื่อง ไม่ต้องทำนาฬิกา:\n'
         '#   - ธง Variant Flag ตั้งอยู่ → แมพเป็น "ร่างที่สอง": ย้อมทั้งจอด้วย Variant Tint\n'
         '#     โหนดในกลุ่ม light_only ถูกเอาออก · โหนดในกลุ่ม dim_only ถูกเปิดขึ้นมา (ตั้ง visible = false ไว้ในฉาก)\n'
         '#   - ไม่มีธง → ร่างปกติ: โหนด dim_only ถูกเอาออก\n'
         '# ใช้กับ NPC · MapSpawner · LoreObject · ภาพฉาก ฯลฯ ได้ทุกอย่าง แค่ใส่กลุ่มให้โหนดนั้นใน Inspector (แท็บ Node → Groups)\n'
         '# =========================================================\n'
         '@export_group("ร่างที่สองของแมพ (รอบ 105)")\n'
         '## ธงที่ทำให้แมพเป็นร่างที่สอง เช่น wall_night · shade_view (ว่าง = แมพนี้ไม่มีร่างที่สอง)\n'
         '@export var variant_flag: StringName = &""\n'
         '## แมพนี้เป็นร่างที่สองตลอดเวลา (เช่น ป่าที่แสงจาง บท 5)\n'
         '@export var variant_always: bool = false\n'
         '## สีย้อมทั้งจอตอนเป็นร่างที่สอง\n'
         '@export var variant_tint: Color = Color(0.45, 0.5, 0.72)\n'
         '## ต่อท้ายชื่อแมพตอนโชว์ เช่น " (กลางคืน)"\n'
         '@export var variant_name_suffix: String = ""\n'
         '@export_group("")\n@export var player_scene: PackedScene'),
        ('var player: Node2D\nvar camera: Camera2D\n\n\nfunc _ready() -> void:\n	add_to_group("map")\n',
         'var player: Node2D\nvar camera: Camera2D\n## ★ รอบ 105 ★ ตอนนี้แมพอยู่ในร่างที่สองไหม (อ่านได้จากสคริปต์อื่น)\nvar is_variant := false\n\n\n'
         'func _ready() -> void:\n	add_to_group("map")\n	_apply_variant()   # ★ รอบ 105 ★ ต้องทำก่อนวางผู้เล่น/สปอว์น\n'),
        ('	if map_id in [&"nidavellir_town", &"vanir_town", &"silver_marsh", &"runeblade_training"]:\n		add_child(preload("res://scripts/world/runeblade_campaign.gd").new())\n',
         '	if map_id in [&"nidavellir_town", &"vanir_town", &"silver_marsh", &"runeblade_training"]:\n		add_child(preload("res://scripts/world/runeblade_campaign.gd").new())\n'
         '	# ★ รอบ 105 ★ เหตุการณ์พิเศษของบท 4-6 (คนแปลกหน้า · พิธี Ninth Edge · โซ่การ์ม ฯลฯ)\n'
         '	if chapter >= 4:\n		add_child(preload("res://scripts/world/ch456_campaign.gd").new())\n\n\n'
         '## ★ รอบ 105 ★ ร่างที่สองของแมพ — ดูคำอธิบายที่กลุ่ม "ร่างที่สองของแมพ" ข้างบน\n'
         'func _apply_variant() -> void:\n'
         '	is_variant = variant_always or (variant_flag != &"" and PlayerState.has_flag(variant_flag))\n'
         '	var drop_group := "dim_only" if not is_variant else "light_only"\n'
         '	for node in get_tree().get_nodes_in_group(drop_group):\n'
         '		if is_ancestor_of(node):\n'
         '			node.get_parent().remove_child(node)\n'
         '			node.queue_free()\n'
         '	if not is_variant:\n'
         '		return\n'
         '	for node in get_tree().get_nodes_in_group("dim_only"):\n'
         '		if is_ancestor_of(node) and node is CanvasItem:\n'
         '			node.visible = true\n'
         '	if get_node_or_null("VariantTint") == null:\n'
         '		var cm := CanvasModulate.new()\n'
         '		cm.name = "VariantTint"\n'
         '		cm.color = variant_tint\n'
         '		add_child(cm)\n'
         '	if variant_name_suffix != "":\n'
         '		display_name += variant_name_suffix\n'),
    ], markers=('variant_flag', 'var is_variant', 'ch456_campaign.gd'))

    # =========================================================
    # D. hud.gd — ชื่ออาชีพว่างหลังทิ้งชื่อ · สีทองเมื่อ Ninth Edge
    # =========================================================
    patch("scripts/ui/hud.gd", [
        ('	level_label.text = "Lv.%d  %s  (Job %d)" % [s.level, s.job().display_name, s.job_level]',
         '	# ★ รอบ 105 ★ ทิ้งชื่อที่สะพานเกียลล์ (C6-3) = ชื่ออาชีพว่างจนกว่าจะสลักชื่อใหม่ (Ninth Edge) หรือจบ C6-10\n'
         '	var job_name: String = s.job().display_name\n'
         '	if PlayerState.has_flag(&"name_left") and not PlayerState.has_flag(&"chapter6_done") and s.job_id != &"ninth_edge":\n'
         '		job_name = "— ไร้นาม —"\n'
         '	level_label.text = "Lv.%d  %s  (Job %d)" % [s.level, job_name, s.job_level]\n'
         '	level_label.add_theme_color_override("font_color", Color("#ffd86b") if s.job_id == &"ninth_edge" else UITheme.TEXT)'),
        ('	Events.quest_changed.connect(_refresh_quest)\n',
         '	Events.quest_changed.connect(_refresh_quest)\n	Events.quest_changed.connect(_refresh_level)   # ★ รอบ 105 ★ ธง name_left เปลี่ยน → อัปเดตชื่อ\n'),
    ], markers=('var job_name: String', 'quest_changed.connect(_refresh_level)'))

    # =========================================================
    # E. monster_data.gd + monster_base.gd
    # =========================================================
    patch("scripts/resources/monster_data.gd", [
        ('\n\n## สุ่มไอเทมที่ดรอปทั้งหมด\nfunc roll_drops()',
         '\n\n@export_group("★ รอบ 105 — เงื่อนไขพิเศษ")\n'
         '## ย้อมสีทั้งตัว — ผีใส่ Color(1,1,1,0.5) · เงาสะท้อนใส่สีดำ\n'
         '@export var tint: Color = Color.WHITE\n'
         '## ★ มอนใจดีถ้าผู้เล่นมีธงนี้ ★ (ไม่ไล่ตี แต่ยังสู้กลับถ้าโดนตี) เช่น job_ninth_edge\n'
         '@export var calm_if_flag: StringName = &""\n'
         '## ★ มอนใจดีถ้าผู้เล่นมีไอเทมนี้ในกระเป๋า ★ เช่น giant_child_scarf\n'
         '@export var calm_if_item: StringName = &""\n'
         '## ★ พูดตอนเกิด ★ สุ่ม 1 ประโยคลอยเหนือหัว (เว้นว่าง = ไม่พูด)\n'
         '@export var spawn_lines: PackedStringArray = PackedStringArray()\n'
         '## ★ ตายแล้วพูด ★ สุ่ม 1 ประโยค (บอส/มินิบอสใช้บอกความจริงก่อนสลาย)\n'
         '@export var death_lines: PackedStringArray = PackedStringArray()\n'
         '\n\n## สุ่มไอเทมที่ดรอปทั้งหมด\nfunc roll_drops()'),
    ], markers=('calm_if_flag',))

    patch("scripts/entities/monster_base.gd", [
        ('	_aggro = data.ai_type == MonsterData.AIType.AGGRESSIVE\n	# กันบอสร่ายสกิลใส่ทันทีที่เห็นหน้า\n	_skill_cd = data.skill_cooldown * 0.5\n',
         '	_aggro = data.ai_type == MonsterData.AIType.AGGRESSIVE and not _calmed()\n	# กันบอสร่ายสกิลใส่ทันทีที่เห็นหน้า\n	_skill_cd = data.skill_cooldown * 0.5\n'
         '	# ★ รอบ 105 ★ ย้อมสี + พูดตอนเกิด\n'
         '	if data.tint != Color.WHITE:\n'
         '		sprite.modulate = data.tint\n'
         '	if not data.spawn_lines.is_empty():\n'
         '		_say_line(data.spawn_lines[randi() % data.spawn_lines.size()], Color("#c9d6ff"))\n'),
        ('func _apply_visual() -> void:',
         '# =========================================================\n'
         '# ★ รอบ 105 ★ มอนใจดีตามเงื่อนไข + พูด\n'
         '# =========================================================\n'
         'var _calm_cache := -1.0\n'
         'var _calm_value := false\n\n'
         '## ผู้เล่นมีธง/ไอเทมที่ทำให้มอนตัวนี้ไม่ไล่ตีไหม (เช็คซ้ำทุก 1 วิ ไม่ต้องไล่กระเป๋าทุกเฟรม)\n'
         'func _calmed() -> bool:\n'
         '	if data == null or (data.calm_if_flag == &"" and data.calm_if_item == &""):\n'
         '		return false\n'
         '	var now := Time.get_ticks_msec() / 1000.0\n'
         '	if now - _calm_cache < 1.0:\n'
         '		return _calm_value\n'
         '	_calm_cache = now\n'
         '	_calm_value = (data.calm_if_flag != &"" and PlayerState.has_flag(data.calm_if_flag)) \\\n'
         '			or (data.calm_if_item != &"" and PlayerState.inventory != null and PlayerState.inventory.count_of(data.calm_if_item) > 0)\n'
         '	return _calm_value\n\n\n'
         'func _say_line(text: String, color: Color) -> void:\n'
         '	if text.strip_edges() == "":\n'
         '		return\n'
         '	Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - hover_lift() - 30), text, color, 16, 0)\n\n\n'
         'func _apply_visual() -> void:'),
        ('	var hostile: bool = _aggro or data.ai_type == MonsterData.AIType.AGGRESSIVE\n',
         '	# ★ รอบ 105 ★ มอนใจดีตามเงื่อนไข (ธง/ไอเทม) = ทำตัวเหมือน PASSIVE จนกว่าจะโดนตี\n'
         '	var hostile: bool = _aggro or (data.ai_type == MonsterData.AIType.AGGRESSIVE and not _calmed())\n'),
        # ดาเมจ: Named Edge (มองข้าม DEF) · Wallbreaker Stance (DEF ≥ 100) · Ninth Inscription (คริ 100% + มองข้าม DEF ในวง)
        ('	var heavy := source in [&"anvil_cleave", &"faultline", &"worldcleaver"]\n'
         '	var mastery := PlayerState.skills.level_of(&"tempered_might") if heavy else 0\n'
         '	var result := Combat.player_hits_monster(PlayerState.stats, data, skill_mult * physical_bonus * (1.0 + mastery*0.04), use_matk, 0, not heavy and source != &"rune_echo", mastery*0.05)\n',
         '	var heavy := source in [&"anvil_cleave", &"faultline", &"worldcleaver", &"erasing_cut"]\n'
         '	var mastery := PlayerState.skills.level_of(&"tempered_might") if heavy else 0\n'
         '	# ★ รอบ 105 ★ Ninth Edge — คมที่มีชื่อ (มองข้าม DEF) · ท่ายืนทลายกำแพง (DEF ≥ 100) · อักขระที่เก้า (วงคริ 100%)\n'
         '	var ignore_def := mastery * 0.05 + PlayerState.skills.level_of(&"named_edge") * 0.06\n'
         '	var can_crit := not heavy and source != &"rune_echo" and source != &"twin_echo"\n'
         '	var wb := PlayerState.skills.level_of(&"wallbreaker_stance")\n'
         '	if wb > 0 and data.def >= 100:\n'
         '		physical_bonus *= 1.0 + 0.13 + 0.024 * wb\n'
         '	# ★ รอบ 105 ★ ดาบนาม (บท 6): ดาเมจ +1% ต่อ «ชื่อที่ทิ้งไว้» ในกระเป๋า สูงสุด +20%\n'
         '	var wpn = PlayerState.equipment.weapon() if PlayerState.equipment != null else null\n'
         '	if wpn != null and wpn.item_id == &"name_blade" and PlayerState.inventory != null:\n'
         '		physical_bonus *= 1.0 + 0.01 * mini(20, PlayerState.inventory.count_of(&"left_name"))\n'
         '	var rb_node = get_tree().get_first_node_in_group("player")\n'
         '	rb_node = rb_node.get("runeblade") if rb_node != null else null\n'
         '	if rb_node != null and rb_node.has_method("inscription_covers") and rb_node.inscription_covers(global_position):\n'
         '		ignore_def = 1.0\n'
         '		can_crit = true\n'
         '	var result := Combat.player_hits_monster(PlayerState.stats, data, skill_mult * physical_bonus * (1.0 + mastery*0.04), use_matk, 0, can_crit, minf(1.0, ignore_def))\n'),
        ('func _die() -> void:',
         'func _die() -> void:\n'
         '	# ★ รอบ 105 ★ ตายแล้วพูด (มินิบอส/บอสบท 4-6)\n'
         '	if data != null and not data.death_lines.is_empty():\n'
         '		_say_line(data.death_lines[randi() % data.death_lines.size()], Color("#ffd8a8"))\n'),
    ], markers=('not _calmed()\n	# กันบอส', 'func _calmed', 'and not _calmed())', 'named_edge', 'data.death_lines'))

    # =========================================================
    # G. skill_book.gd — สกิล Ninth Edge · แต้มรูน 45
    # =========================================================
    patch("scripts/core/skill_book.gd", [
        ('const RUNE_SKILLS := [&"runic_vessel",&"rune_guard",&"blade_rhythm",&"keen_inscription",&"rune_flurry",&"unbroken_edge",&"tempered_might",&"anvil_cleave",&"faultline",&"worldcleaver"]\n',
         '## ★ รอบ 105 ★ สกิล Ninth Edge 6 ตัว (wallbreaker_stance · twin_inscription เรียนได้ตั้งแต่ Runeblade หลังผ่าน RB9 / RB11)\n'
         'const NINTH_SKILLS := [&"ninth_vessel",&"named_edge",&"twin_inscription",&"wallbreaker_stance",&"erasing_cut",&"ninth_inscription"]\n'
         'const RUNE_SKILLS := [&"runic_vessel",&"rune_guard",&"blade_rhythm",&"keen_inscription",&"rune_flurry",&"unbroken_edge",&"tempered_might",&"anvil_cleave",&"faultline",&"worldcleaver",\n'
         '	&"ninth_vessel",&"named_edge",&"twin_inscription",&"wallbreaker_stance",&"erasing_cut",&"ninth_inscription"]\n'
         '## สกิลที่ต้องมีธงจากเควสก่อนถึงเรียนได้: สกิล -> [ธง, ข้อความ]\n'
         'const RUNE_SKILL_FLAGS := {\n'
         '	&"wallbreaker_stance": [&"rb_rune_5", "ต้องได้รูนดวงที่ 5 «กำแพง» จากเกอร์ด (RB9) ก่อน"],\n'
         '	&"twin_inscription": [&"rb_rune_7", "ต้องได้รูนดวงที่ 7 «เงา» จากเอย์ร (RB11) ก่อน"],\n'
         '	&"ninth_inscription": [&"ninth_inscription_unlocked", "ต้องผ่านเควส RB14 คมที่จำได้ ก่อน"],\n'
         '}\n'),
        ('func rune_points() -> int:\n	if PlayerState.stats.job_id != &"runeblade": return 0\n	var earned := mini(30, 5 + maxi(0, PlayerState.stats.level - int(PlayerState.get_flag(&"runeblade_start_level",50))))\n',
         '## ★ รอบ 105 ★ แต้มรูนสูงสุด 30 (Runeblade) → 45 (Ninth Edge) · +1 จาก RB8 · +1 จาก RB10\n'
         'func rune_point_cap() -> int:\n'
         '	return 45 if PlayerState.stats.job_id == &"ninth_edge" else 30\n\n'
         'func rune_points() -> int:\n	if not PlayerState.is_rune_job(): return 0\n'
         '	var earned := mini(rune_point_cap(), 5 + maxi(0, PlayerState.stats.level - int(PlayerState.get_flag(&"runeblade_start_level",50))))\n'
         '	if PlayerState.has_flag(&"rb_rune_4"): earned += 1\n'
         '	if PlayerState.has_flag(&"rb_rune_6"): earned += 1\n'),
        ('	if PlayerState.stats.job_id != &"runeblade" or not Game.is_town(PlayerState.current_map_id): return false',
         '	if not PlayerState.is_rune_job() or not Game.is_town(PlayerState.current_map_id): return false'),
        ('	if skill_id == &"worldcleaver" and level_of(&"unbroken_edge") > 0: return false\n	if skill_id == &"unbroken_edge" and level_of(&"worldcleaver") > 0: return false\n	if level_of(skill_id) >= s.max_level:',
         '	if skill_id == &"worldcleaver" and level_of(&"unbroken_edge") > 0: return false\n	if skill_id == &"unbroken_edge" and level_of(&"worldcleaver") > 0: return false\n'
         '	if RUNE_SKILL_FLAGS.has(skill_id) and not PlayerState.has_flag(RUNE_SKILL_FLAGS[skill_id][0]): return false   # ★ รอบ 105 ★\n'
         '	if level_of(skill_id) >= s.max_level:'),
        ('		if rune_points() <= 0: return "ไม่มีแต้ม Runeblade (ได้เพิ่มเมื่อเลเวลตัวละครขึ้น สูงสุด 30 แต้ม)"',
         '		if rune_points() <= 0: return "ไม่มีแต้ม Runeblade (ได้เพิ่มเมื่อเลเวลตัวละครขึ้น สูงสุด %d แต้ม)" % rune_point_cap()\n'
         '		if RUNE_SKILL_FLAGS.has(skill_id) and not PlayerState.has_flag(RUNE_SKILL_FLAGS[skill_id][0]): return String(RUNE_SKILL_FLAGS[skill_id][1])   # ★ รอบ 105 ★'),
    ], markers=('NINTH_SKILLS', 'func rune_point_cap', 'is_rune_job() or not Game.is_town', 'RUNE_SKILL_FLAGS.has(skill_id) and not PlayerState.has_flag(RUNE_SKILL_FLAGS[skill_id][0]): return false', 'rune_point_cap()\n'))

    # =========================================================
    # H. runeblade_combat.gd — รูน 4 · Twin Inscription · Erasing Cut · Ninth Inscription
    # =========================================================
    patch("scripts/entities/runeblade_combat.gd", [
        ('var casting := false\nvar hud: Label\n',
         'var casting := false\nvar hud: Label\n'
         '# ★ รอบ 105 ★ Ninth Edge\n'
         'var twin_time := 0.0          ## อักขระคู่ — เงาดาบตามทุกโจมตี\n'
         'var inscription_time := 0.0   ## อักขระที่เก้า — วงสลักชื่อ\n'
         'var inscription_center := Vector2.ZERO\n'
         'var inscription_lv := 0\n'
         'var inscription_ring: Line2D\n'
         'const INSCRIPTION_RADIUS := 350.0\n\n'
         '## รูนสะสมสูงสุด 3 · Ninth Vessel ระดับ 5 = 4\n'
         'func max_charges() -> int:\n'
         '	return 3 + (1 if PlayerState.skills.level_of(&"ninth_vessel") >= 5 else 0)\n\n'
         '## จุดนี้อยู่ในวงอักขระที่เก้าไหม (monster_base ใช้: คริ 100% + มองข้าม DEF)\n'
         'func inscription_covers(at: Vector2) -> bool:\n'
         '	return inscription_time > 0 and at.distance_to(inscription_center) <= INSCRIPTION_RADIUS + 60\n'),
        ('func _hit(target: Node, source: StringName, _critical: bool) -> void:\n	if PlayerState.stats.job_id != &"runeblade" or source == &"rune_echo": return\n	idle = 0\n',
         'func _hit(target: Node, source: StringName, _critical: bool) -> void:\n	if not PlayerState.is_rune_job() or source == &"rune_echo" or source == &"twin_echo": return\n	idle = 0\n'
         '	# ★ รอบ 105 ★ อักขระคู่ — เงาดาบตามทุกการโจมตี 50→70% ไม่คริ\n'
         '	if twin_time > 0 and is_instance_valid(target) and target.has_method("is_dead") and not target.is_dead():\n'
         '		var tl := PlayerState.skills.level_of(&"twin_inscription")\n'
         '		target.take_damage_from_player(0.45 + 0.05 * tl, false, player.facing, 0, 0, &"twin_echo")\n'),
        ('	charges = mini(3,charges+1)\n	charge_lock = 1.0',
         '	charges = mini(max_charges(),charges+1)\n	charge_lock = 1.0'),
        ('	hud.visible = PlayerState.stats.job_id == &"runeblade" and not player._dead\n',
         '	hud.visible = PlayerState.is_rune_job() and not player._dead\n'),
        ('	if shield_time <= 0: shield = 0\n',
         '	if shield_time <= 0: shield = 0\n'
         '	# ★ รอบ 105 ★ นับถอยหลังอักขระคู่ / อักขระที่เก้า\n'
         '	if twin_time > 0:\n'
         '		twin_time -= delta\n'
         '		if twin_time <= 0:\n'
         '			PlayerState.active_buffs.erase(&"twin_inscription")\n'
         '			PlayerState.refresh()\n'
         '	if inscription_time > 0:\n'
         '		inscription_time -= delta\n'
         '		if inscription_time <= 0:\n'
         '			_inscription_burst()\n'),
        ('	hud.text = "รูน  %s%s   จังหวะ %d/5%s" % ["◆".repeat(charges),"◇".repeat(3-charges),rhythm,"   โล่ %d"%shield if shield>0 else ""]',
         '	hud.text = "รูน  %s%s   จังหวะ %d/5%s%s" % ["◆".repeat(charges),"◇".repeat(max_charges()-charges),rhythm,"   โล่ %d"%shield if shield>0 else "",\n'
         '		("   อักขระคู่ %.1f" % twin_time if twin_time > 0 else "") + ("   ★ อักขระที่เก้า %.1f" % inscription_time if inscription_time > 0 else "")]'),
        ('func cast(id: StringName) -> void:\n	if casting or PlayerState.stats.job_id != &"runeblade": return\n',
         'func cast(id: StringName) -> void:\n	if casting or not PlayerState.is_rune_job(): return\n'),
        ('	var ultimate := id in [&"unbroken_edge",&"worldcleaver"]\n	if ultimate and charges < 3:\n		Events.say("ต้องมีตรารูนครบ 3 ดวง")\n		return\n',
         '	# ★ รอบ 105 ★ ค่ารูนของแต่ละสกิล: อัลติเมต 3 · อักขระคู่ 2 · ฟันลบนาม 3 · อักขระที่เก้า 4\n'
         '	var rune_cost: int = {&"unbroken_edge": 3, &"worldcleaver": 3, &"twin_inscription": 2, &"erasing_cut": 3, &"ninth_inscription": 4}.get(id, 0)\n'
         '	var ultimate := rune_cost > 0\n'
         '	if ultimate and charges < rune_cost:\n'
         '		Events.say("ต้องมีตรารูนครบ %d ดวง" % rune_cost)\n'
         '		return\n'),
        ('	if id == &"unbroken_edge":\n		charges = 0\n		edge_time = 8\n		echo_count = 0\n		PlayerState.active_buffs[id] = {"time_left":8.0,"values":{"aspd_percent":5.0*lv},"level":lv}\n		PlayerState.refresh()\n		return\n',
         '	if id == &"unbroken_edge":\n		charges = 0\n		edge_time = 8\n		echo_count = 0\n		PlayerState.active_buffs[id] = {"time_left":8.0,"values":{"aspd_percent":5.0*lv},"level":lv}\n		PlayerState.refresh()\n		return\n'
         '	# ★ รอบ 105 ★ อักขระคู่ — 6 วิ ทุกโจมตีมีเงาดาบตาม (ใช้ 2 รูน)\n'
         '	if id == &"twin_inscription":\n'
         '		charges -= 2\n'
         '		twin_time = 6.0\n'
         '		PlayerState.active_buffs[id] = {"time_left":6.0,"values":{},"level":lv}\n'
         '		PlayerState.refresh()\n'
         '		_flash(player.foot_position()-Vector2(0,110),150,Color("#b8a6ff"))\n'
         '		return\n'
         '	# ★ รอบ 105 ★ อักขระที่เก้า — สลักชื่อลงพื้นเป็นวง 3 วิ: ทุกโจมตีในวงคริ 100% + มองข้าม DEF · จบแล้วระเบิด 2000% (ใช้ 4 รูน)\n'
         '	if id == &"ninth_inscription":\n'
         '		charges -= 4\n'
         '		inscription_time = 3.0\n'
         '		inscription_lv = lv\n'
         '		inscription_center = player.foot_position()\n'
         '		PlayerState.active_buffs[id] = {"time_left":3.0,"values":{"crit":100.0},"level":lv}\n'
         '		PlayerState.refresh()\n'
         '		_draw_inscription()\n'
         '		Events.floating_text(inscription_center + Vector2(0,-190), "★ อักขระที่เก้า — %s ★" % PlayerState.stats.job().display_name, Color("#ffd86b"), 26, 0)\n'
         '		return\n'),
        ('	var windup := 0.4 if id == &"anvil_cleave" else (0.25 if id == &"faultline" else (0.7 if id == &"worldcleaver" else 0.05))',
         '	var windup := 0.4 if id == &"anvil_cleave" else (0.25 if id == &"faultline" else (0.7 if id == &"worldcleaver" else (0.3 if id == &"erasing_cut" else 0.05)))'),
        ('	var reach := 180.0 if id in [&"rune_flurry",&"anvil_cleave"] else (550.0 if id == &"faultline" else 650.0)\n	var cap := 1 if id == &"rune_flurry" else (3 if id == &"anvil_cleave" else 6)',
         '	if id == &"erasing_cut": charges -= 3   # ★ รอบ 105 ★ ฟันลบนาม ใช้ 3 รูน ฟันหนักครั้งเดียว ลบโล่/บัฟของมอน\n'
         '	var reach := 180.0 if id in [&"rune_flurry",&"anvil_cleave"] else (550.0 if id == &"faultline" else (240.0 if id == &"erasing_cut" else 650.0))\n	var cap := 1 if id in [&"rune_flurry",&"erasing_cut"] else (3 if id == &"anvil_cleave" else 6)'),
        ('func _flash(at: Vector2, radius: float, color: Color) -> void:',
         '# =========================================================\n'
         '# ★ รอบ 105 ★ อักขระที่เก้า — วงบนพื้น + ระเบิดตอนจบ\n'
         '# =========================================================\n'
         'func _draw_inscription() -> void:\n'
         '	if is_instance_valid(inscription_ring): inscription_ring.queue_free()\n'
         '	var line := Line2D.new()\n'
         '	line.global_position = inscription_center\n'
         '	line.width = 5\n'
         '	line.default_color = Color("#ffd86b")\n'
         '	line.z_index = 64\n'
         '	for i in range(41):\n'
         '		var a := TAU * i / 40.0\n'
         '		line.add_point(Vector2(cos(a) * INSCRIPTION_RADIUS, sin(a) * 40))\n'
         '	get_parent().get_parent().add_child(line)\n'
         '	inscription_ring = line\n\n'
         'func _inscription_burst() -> void:\n'
         '	inscription_time = 0\n'
         '	PlayerState.active_buffs.erase(&"ninth_inscription")\n'
         '	PlayerState.refresh()\n'
         '	if is_instance_valid(inscription_ring):\n'
         '		var tween := inscription_ring.create_tween()\n'
         '		tween.tween_property(inscription_ring, "modulate:a", 0.0, 0.4)\n'
         '		tween.tween_callback(inscription_ring.queue_free)\n'
         '	if not is_instance_valid(player) or player._dead: return\n'
         '	var mult := 20.0 + 2.0 * (inscription_lv - 1)\n'
         '	for enemy in get_tree().get_nodes_in_group("enemy"):\n'
         '		if not enemy.has_method("take_damage_from_player") or (enemy.has_method("is_dead") and enemy.is_dead()): continue\n'
         '		if enemy.global_position.distance_to(inscription_center) > INSCRIPTION_RADIUS + 60: continue\n'
         '		var dir := 1 if enemy.global_position.x >= inscription_center.x else -1\n'
         '		enemy.take_damage_from_player(mult, false, dir, 0, 0, &"ninth_inscription")\n'
         '	_flash(inscription_center - Vector2(0, 100), INSCRIPTION_RADIUS, Color("#ffd86b"))\n\n'
         'func _flash(at: Vector2, radius: float, color: Color) -> void:'),
        ('	PlayerState.active_buffs.erase(&"rb_rhythm")\n	PlayerState.active_buffs.erase(&"unbroken_edge")\n	if PlayerState.stats != null',
         '	PlayerState.active_buffs.erase(&"rb_rhythm")\n	PlayerState.active_buffs.erase(&"unbroken_edge")\n	PlayerState.active_buffs.erase(&"twin_inscription")\n	PlayerState.active_buffs.erase(&"ninth_inscription")\n	if PlayerState.stats != null'),
    ], markers=('func max_charges', 'source == &"twin_echo": return', 'mini(max_charges(),charges+1)', 'hud.visible = PlayerState.is_rune_job()',
                'twin_time -= delta', 'max_charges()-charges', 'if casting or not PlayerState.is_rune_job()', 'var rune_cost: int',
                'id == &"twin_inscription":\n		charges -= 2', 'id == &"erasing_cut" else 0.05', 'if id == &"erasing_cut": charges -= 3',
                'func _draw_inscription', 'erase(&"twin_inscription")\n	PlayerState.active_buffs.erase(&"ninth_inscription")'))

    # =========================================================
    # I. death_popup.gd — คำอวยพรจากธอร์เปลี่ยนตามบท
    # =========================================================
    patch("scripts/ui/death_popup.gd", [
        ('const PANEL_W := 520.0\n',
         '## ★ รอบ 105 ★ บท 4-5 (เห็นภาพวาด/เมืองแสงแล้ว) — ธอร์ยังอวยพร แต่น้ำเสียงเริ่มเป็นเจ้านาย\n'
         'const THOR_BLESSINGS_DOUBT := [\n'
         '	"จงลุกขึ้น  เจ้ายังมีประโยชน์กับข้า",\n'
         '	"ยักษ์เขียนประวัติศาสตร์ฝั่งตัวเองเสมอ  อย่าให้ภาพวาดทำเจ้าอ่อนแรง",\n'
         '	"ข้าเห็นเจ้าลังเล  ความลังเลนั่นแหละที่ทำให้เจ้าล้ม",\n'
         '	"แสงของข้าไม่เคยหลอกใคร  มีแต่คนที่ไม่ยอมมอง",\n'
         '	"ลุกขึ้น  ค้อนไม่รอคนที่นอนอยู่",\n'
         '	"เจ้าเชื่อคำของศัตรูง่ายกว่าคำของข้าหรือ  ลุกขึ้นแล้วพิสูจน์ว่าข้าคิดผิด",\n'
         ']\n'
         '## ★ รอบ 105 ★ บท 6 ขึ้นไป (เข้านิฟล์เฮมแล้ว) — เสียงจากฟ้าเบาลง เหมือนพูดกับตัวเอง\n'
         'const THOR_BLESSINGS_COLD := [\n'
         '	"…ลุกขึ้น  ข้ายังต้องการเจ้า",\n'
         '	"คนตายพูดได้ทุกอย่าง  เพราะพวกมันไม่ต้องรับผิดชอบอะไรอีกแล้ว",\n'
         '	"อย่าฟังสิ่งที่อยู่ใต้หมอก  ฟังข้า",\n'
         '	"ชื่อของเจ้ายังอยู่กับข้า  ตราบใดที่เจ้ายังลุกขึ้น",\n'
         '	"เจ้าไปไกลกว่าที่ข้าคิด…  กลับมาเถอะ",\n'
         '	"ฟ้ายังร้องเพื่อเจ้า  แม้เจ้าจะเริ่มไม่ได้ยินมัน",\n'
         ']\n\n'
         'const PANEL_W := 520.0\n'),
        ('	_bless.text = "\\"%s\\"" % THOR_BLESSINGS[randi() % THOR_BLESSINGS.size()]',
         '	var pool: Array = THOR_BLESSINGS   # ★ รอบ 105 ★ ชุดคำอวยพรเปลี่ยนตามบทที่ไปถึง\n'
         '	if PlayerState.has_flag(&"chapter6_visited"):\n'
         '		pool = THOR_BLESSINGS_COLD\n'
         '	elif PlayerState.has_flag(&"chapter4_visited"):\n'
         '		pool = THOR_BLESSINGS_DOUBT\n'
         '	_bless.text = "\\"%s\\"" % pool[randi() % pool.size()]'),
    ], markers=('THOR_BLESSINGS_DOUBT', 'var pool: Array = THOR_BLESSINGS'))

    # =========================================================
    # L. npc.gd — show_if_flag / hide_if_flag
    # =========================================================
    patch("scripts/world/npc.gd", [
        ('@export var dialog_by_flag: Dictionary = {}\n',
         '@export var dialog_by_flag: Dictionary = {}\n'
         '## ★ รอบ 105 ★ NPC คนนี้มีอยู่เฉพาะเมื่อมีธงนี้ (ว่าง = มีเสมอ) เช่น ผีของผู้หลุดจากแสง มีเฉพาะถ้าฆ่าเขา\n'
         '@export var show_if_flag: StringName = &""\n'
         '## ★ รอบ 105 ★ NPC คนนี้หายไปเมื่อมีธงนี้ เช่น อาสมุนด์กลับวิหารหลังผู้เล่นสงสัยเขา\n'
         '@export var hide_if_flag: StringName = &""\n'),
        ('func _ready() -> void:\n	add_to_group("npc")\n	body_entered.connect(_on_body_entered)\n',
         'func _ready() -> void:\n'
         '	# ★ รอบ 105 ★ NPC ที่มี/ไม่มีตามธงเนื้อเรื่อง\n'
         '	if (show_if_flag != &"" and not PlayerState.has_flag(show_if_flag)) or (hide_if_flag != &"" and PlayerState.has_flag(hide_if_flag)):\n'
         '		queue_free()\n'
         '		return\n'
         '	add_to_group("npc")\n	body_entered.connect(_on_body_entered)\n'),
    ], markers=('show_if_flag: StringName', 'not PlayerState.has_flag(show_if_flag)'))


    # =========================================================
    # M. signal_bus.gd + npc.gd — สัญญาณ "คุยกับ NPC แล้ว" (เหตุการณ์ลับของคนแปลกหน้าใช้)
    # =========================================================
    patch("scripts/core/signal_bus.gd", [
        ('signal map_changed(map_id: StringName)\n',
         'signal map_changed(map_id: StringName)\n'
         '## ★ รอบ 105 ★ ผู้เล่นเริ่มคุยกับ NPC (ส่งชื่อที่โชว์บนหัว) — ch456_campaign ใช้ทำเหตุการณ์ลับหลังบทสนทนา\n'
         'signal npc_talked(npc_name: String)\n'),
    ], markers=('signal npc_talked',))
    patch("scripts/world/npc.gd", [
        ('	if PlayerState.quests != null:\n		PlayerState.quests.on_talked_to(npc_name)\n',
         '	if PlayerState.quests != null:\n		PlayerState.quests.on_talked_to(npc_name)\n	Events.npc_talked.emit(npc_name)   # ★ รอบ 105 ★\n'),
    ], markers=('Events.npc_talked.emit',))

    # =========================================================
    # N. lore_object.gd — auto_read
    # =========================================================
    patch("scripts/world/lore_object.gd", [
        ('@export_group("ข้อความบนหัว")\n',
         '## ★ รอบ 105 ★ เดินถึงแล้วนับเลย ไม่ต้องกด F (ใช้ทำเงื่อนไข "ไปให้ถึงจุดนี้") — โชว์ Title สั้น ๆ บนจอแทนกล่องสนทนา\n'
         '@export var auto_read: bool = false\n\n'
         '@export_group("ข้อความบนหัว")\n'),
        ('func _on_body_entered(body: Node) -> void:\n	if body.is_in_group("player"):\n		_player_inside = true\n		if _prompt != null:\n			_prompt.show()\n',
         'func _on_body_entered(body: Node) -> void:\n	if body.is_in_group("player"):\n		_player_inside = true\n'
         '		if auto_read:   # ★ รอบ 105 ★\n'
         '			_auto_read()\n'
         '			return\n'
         '		if _prompt != null:\n			_prompt.show()\n\n\n'
         '## ★ รอบ 105 ★ ถึงจุดนี้แล้ว = อ่านให้เองเงียบ ๆ (ครั้งแรกครั้งเดียว) — ไม่เปิดกล่องสนทนา ไม่ขวางการเล่น\n'
         'func _auto_read() -> void:\n'
         '	if required_flag != &"" and not PlayerState.has_flag(required_flag):\n'
         '		return\n'
         '	if PlayerState.has_flag(_read_flag()):\n'
         '		return\n'
         '	PlayerState.set_flag(_read_flag())\n'
         '	if give_item != &"" and give_item_count > 0:\n'
         '		PlayerState.gain_item_id(give_item, give_item_count)\n'
         '	if set_flag != &"":\n'
         '		PlayerState.set_flag(set_flag)\n'
         '	if title != "":\n'
         '		Events.say(title if text.strip_edges() == "" else "%s — %s" % [title, text.get_slice("\\n", 0)])\n'
         '	if PlayerState.quests != null:\n'
         '		PlayerState.quests.on_read(lore_id)\n'),
    ], markers=('auto_read: bool', 'func _auto_read'))


    # =========================================================
    # O. player.gd — จุดช่วยชีวิตก่อนตาย (S7 คนแปลกหน้าดึงขึ้นจากน้ำ · กลุ่ม death_guard)
    # =========================================================
    patch("scripts/entities/player.gd", [
        ('	if runeblade != null:\n		amount = runeblade.absorb(amount)\n		if amount <= 0: return\n	PlayerState.take_damage(amount)\n',
         '	if runeblade != null:\n		amount = runeblade.absorb(amount)\n		if amount <= 0: return\n'
         '	# ★ รอบ 105 ★ เหตุการณ์ช่วยชีวิต (คนแปลกหน้าดึงขึ้นจากทะเลสาบกระจก) — โหนดในกลุ่ม death_guard ตอบ true = ไม่ตาย\n'
         '	var guard := get_tree().get_first_node_in_group("death_guard")\n'
         '	if guard != null and guard.has_method("try_rescue") and guard.try_rescue(amount):\n'
         '		return\n'
         '	PlayerState.take_damage(amount)\n'),
    ], markers=('death_guard',))

    # =========================================================
    # J. game.gd — ทะเบียนแมพ · เมือง   /   map_atlas.gd — แผนที่โลก
    # =========================================================
    patch("scripts/core/game.gd", [
        ('	&"spring_of_life": "res://scenes/maps/spring_of_life.tscn",\n',
         '	&"spring_of_life": "res://scenes/maps/spring_of_life.tscn",\n'
         '	## ★ บทที่ 4 — โยตุนเฮม (รอบ 105) ★\n'
         '	&"frost_pass": "res://scenes/maps/frost_pass.tscn",\n'
         '	&"utgard_town": "res://scenes/maps/utgard_town.tscn",\n'
         '	&"giant_steppe": "res://scenes/maps/giant_steppe.tscn",\n'
         '	&"frozen_hall": "res://scenes/maps/frozen_hall.tscn",\n'
         '	&"broken_wall": "res://scenes/maps/broken_wall.tscn",\n'
         '	&"hrungnir_crater": "res://scenes/maps/hrungnir_crater.tscn",\n'
         '	## ★ บทที่ 5 — อัลฟ์เฮม (รอบ 105) ★\n'
         '	&"shimmer_road": "res://scenes/maps/shimmer_road.tscn",\n'
         '	&"ljosalf_city": "res://scenes/maps/ljosalf_city.tscn",\n'
         '	&"crystal_garden": "res://scenes/maps/crystal_garden.tscn",\n'
         '	&"mirror_lake": "res://scenes/maps/mirror_lake.tscn",\n'
         '	&"dimming_wood": "res://scenes/maps/dimming_wood.tscn",\n'
         '	&"lightwell_sanctum": "res://scenes/maps/lightwell_sanctum.tscn",\n'
         '	## ★ บทที่ 6 — นิฟล์เฮม + เฮลเฮม (รอบ 105) ★\n'
         '	&"mist_shore": "res://scenes/maps/mist_shore.tscn",\n'
         '	&"eljudnir": "res://scenes/maps/eljudnir.tscn",\n'
         '	&"gjoll_river": "res://scenes/maps/gjoll_river.tscn",\n'
         '	&"hall_of_names": "res://scenes/maps/hall_of_names.tscn",\n'
         '	&"nastrond": "res://scenes/maps/nastrond.tscn",\n'
         '	&"garm_gate": "res://scenes/maps/garm_gate.tscn",\n'
         '	&"odin_seat": "res://scenes/maps/odin_seat.tscn",\n'),
        ('	&"spring_of_life": "บ่อน้ำแห่งชีวิต",\n',
         '	&"spring_of_life": "บ่อน้ำแห่งชีวิต",\n'
         '	&"frost_pass": "ช่องเขาน้ำแข็ง",\n'
         '	&"utgard_town": "อุทการ์ด นครแห่งยักษ์",\n'
         '	&"giant_steppe": "ทุ่งหญ้ายักษ์",\n'
         '	&"frozen_hall": "โถงภาพวาดน้ำแข็ง",\n'
         '	&"broken_wall": "กำแพงที่แตก",\n'
         '	&"hrungnir_crater": "หลุมหัวใจสายฟ้า",\n'
         '	&"shimmer_road": "ทางประกายแสง",\n'
         '	&"ljosalf_city": "ลโยซาลฟ์ นครแห่งแสง",\n'
         '	&"crystal_garden": "สวนผลึก",\n'
         '	&"mirror_lake": "ทะเลสาบกระจก",\n'
         '	&"dimming_wood": "ป่าที่แสงจาง",\n'
         '	&"lightwell_sanctum": "วิหารบ่อแสง",\n'
         '	&"mist_shore": "ฝั่งหมอกน้ำแข็ง",\n'
         '	&"eljudnir": "เอลยุดเนียร์ เมืองของผู้ตาย",\n'
         '	&"gjoll_river": "แม่น้ำเกียลล์",\n'
         '	&"hall_of_names": "โถงแห่งนาม",\n'
         '	&"nastrond": "นาสตรอนด์ ฝั่งศพ",\n'
         '	&"garm_gate": "ประตูของการ์ม",\n'
         '	&"odin_seat": "บัลลังก์ว่างของโอดิน",\n'),
        ('const TOWNS := [&"prontera_town", &"nidavellir_town", &"vanir_town"]',
         'const TOWNS := [&"prontera_town", &"nidavellir_town", &"vanir_town", &"utgard_town", &"ljosalf_city", &"eljudnir"]'),
    ], markers=('&"frost_pass": "res://', '&"frost_pass": "ช่องเขา', '&"utgard_town", &"ljosalf_city"'))

    patch("scripts/core/map_atlas.gd", [
        ('		"links": [&"root_road", &"silver_marsh"],\n',
         '		"links": [&"root_road", &"silver_marsh", &"frost_pass"],\n'),
        ('	3: "บทที่ 3 — วานาเฮม",\n}',
         '	3: "บทที่ 3 — วานาเฮม",\n	4: "บทที่ 4 — โยตุนเฮม",\n	5: "บทที่ 5 — อัลฟ์เฮม",\n	6: "บทที่ 6 — นิฟล์เฮม",\n}'),
        ('	&"spring_of_life": {\n		"chapter": 3, "kind": KIND_BOSS, "level": [60, 60],\n		"monsters": [&"gullveig_ember"],\n		"links": [&"forgotten_battlefield"],\n	},',
         '	&"spring_of_life": {\n		"chapter": 3, "kind": KIND_BOSS, "level": [60, 60],\n		"monsters": [&"gullveig_ember"],\n		"links": [&"forgotten_battlefield"],\n	},\n\n'
         '	# ---------- บทที่ 4 — โยตุนเฮม (รอบ 105) ----------\n'
         '	&"frost_pass": {"chapter": 4, "kind": KIND_FIELD, "level": [60, 63], "monsters": [&"frost_wolf", &"snow_hawk"], "links": [&"vanir_town", &"utgard_town"]},\n'
         '	&"utgard_town": {"chapter": 4, "kind": KIND_TOWN, "level": [0, 0], "monsters": [], "links": [&"frost_pass", &"giant_steppe"]},\n'
         '	&"giant_steppe": {"chapter": 4, "kind": KIND_FIELD, "level": [63, 66], "monsters": [&"snow_mammoth", &"ice_troll", &"snow_hawk"], "links": [&"utgard_town", &"frozen_hall"]},\n'
         '	&"frozen_hall": {"chapter": 4, "kind": KIND_FIELD, "level": [66, 69], "monsters": [&"stone_soldier", &"echo_wraith"], "links": [&"giant_steppe", &"broken_wall"]},\n'
         '	&"broken_wall": {"chapter": 4, "kind": KIND_FIELD, "level": [69, 71], "monsters": [&"ice_troll", &"stone_soldier", &"wall_shieldbearer"], "links": [&"frozen_hall", &"hrungnir_crater"]},\n'
         '	&"hrungnir_crater": {"chapter": 4, "kind": KIND_BOSS, "level": [72, 72], "monsters": [&"stone_hrungnir"], "links": [&"broken_wall", &"shimmer_road"]},\n\n'
         '	# ---------- บทที่ 5 — อัลฟ์เฮม (รอบ 105) ----------\n'
         '	&"shimmer_road": {"chapter": 5, "kind": KIND_FIELD, "level": [72, 75], "monsters": [&"light_moth", &"crystal_stag"], "links": [&"hrungnir_crater", &"ljosalf_city"]},\n'
         '	&"ljosalf_city": {"chapter": 5, "kind": KIND_TOWN, "level": [0, 0], "monsters": [], "links": [&"shimmer_road", &"crystal_garden"]},\n'
         '	&"crystal_garden": {"chapter": 5, "kind": KIND_FIELD, "level": [75, 78], "monsters": [&"crystal_stag", &"light_eater_bloom", &"garden_keeper"], "links": [&"ljosalf_city", &"mirror_lake"]},\n'
         '	&"mirror_lake": {"chapter": 5, "kind": KIND_FIELD, "level": [78, 81], "monsters": [&"reflection", &"water_nymph"], "links": [&"crystal_garden", &"dimming_wood"]},\n'
         '	&"dimming_wood": {"chapter": 5, "kind": KIND_FIELD, "level": [81, 83], "monsters": [&"hollow_elf", &"hollow_moth", &"light_forsaken"], "links": [&"mirror_lake", &"lightwell_sanctum"]},\n'
         '	&"lightwell_sanctum": {"chapter": 5, "kind": KIND_BOSS, "level": [84, 84], "monsters": [&"radiant_alfr"], "links": [&"dimming_wood", &"mist_shore"]},\n\n'
         '	# ---------- บทที่ 6 — นิฟล์เฮม + เฮลเฮม (รอบ 105) ----------\n'
         '	&"mist_shore": {"chapter": 6, "kind": KIND_FIELD, "level": [84, 86], "monsters": [&"mist_ghost", &"hel_hound"], "links": [&"lightwell_sanctum", &"eljudnir"]},\n'
         '	&"eljudnir": {"chapter": 6, "kind": KIND_TOWN, "level": [0, 0], "monsters": [], "links": [&"mist_shore", &"gjoll_river"]},\n'
         '	&"gjoll_river": {"chapter": 6, "kind": KIND_FIELD, "level": [86, 89], "monsters": [&"drowned", &"ferryman", &"hel_hound"], "links": [&"eljudnir", &"hall_of_names"]},\n'
         '	&"hall_of_names": {"chapter": 6, "kind": KIND_FIELD, "level": [89, 91], "monsters": [&"name_warden", &"erased_voice"], "links": [&"gjoll_river", &"nastrond"]},\n'
         '	&"nastrond": {"chapter": 6, "kind": KIND_FIELD, "level": [91, 94], "monsters": [&"drowned", &"nidhogg_spawn", &"false_judge"], "links": [&"hall_of_names", &"garm_gate"]},\n'
         '	&"garm_gate": {"chapter": 6, "kind": KIND_BOSS, "level": [96, 96], "monsters": [&"chained_garm"], "links": [&"nastrond", &"odin_seat"]},\n'
         '	&"odin_seat": {"chapter": 6, "kind": KIND_HIDDEN, "level": [0, 0], "monsters": [], "links": [&"garm_gate"]},'),
    ], markers=('&"silver_marsh", &"frost_pass"]', '4: "บทที่ 4', '&"frost_pass": {"chapter": 4'))

    # =========================================================
    # อาชีพ Ninth Edge + ต่อสายจาก Runeblade
    # =========================================================
    patch("data/jobs/runeblade.tres", [
        ('next_job_ids = Array[StringName]([])', 'next_job_ids = Array[StringName]([&"ninth_edge"])'),
    ], markers=('&"ninth_edge"',))
    w("data/jobs/ninth_edge.tres", '''[gd_resource type="Resource" script_class="JobData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/job_data.gd" id="1_job"]

[resource]
script = ExtResource("1_job")
id = &"ninth_edge"
display_name = "Ninth Edge — คมอักขระที่เก้า"
description = "ผู้ที่สลักชื่อตัวเองเป็นอักขระที่เก้าในโถงที่ชื่อทุกชื่อถูกลบ คมกับแรงกลายเป็นสิ่งเดียวกัน — ดาบที่ธอร์ยังลบไม่ได้"
hp_base = 60
hp_per_level = 18.0
hp_vit_percent = 1.3
sp_base = 16
sp_per_level = 3.5
sp_int_percent = 1.1
atk_mod = 1.4
matk_mod = 0.5
def_mod = 1.3
hit_mod = 1.05
flee_mod = 1.05
aspd_base = 1.15
aspd_agi_percent = 1.25
weapon_types = Array[StringName]([&"sword"])
skill_ids = Array[StringName]([&"sword_mastery", &"hp_recovery", &"bash", &"slash", &"magnum_break", &"endure", &"battle_cry", &"first_aid", &"runic_vessel", &"rune_guard", &"blade_rhythm", &"keen_inscription", &"rune_flurry", &"unbroken_edge", &"tempered_might", &"anvil_cleave", &"faultline", &"worldcleaver", &"ninth_vessel", &"named_edge", &"twin_inscription", &"wallbreaker_stance", &"erasing_cut", &"ninth_inscription"])
job_change_level = 999
next_job_ids = Array[StringName]([])
''')
