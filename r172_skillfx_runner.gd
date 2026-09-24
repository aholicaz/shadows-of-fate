extends Node
## ★ รอบ 172 ★ ขนาดภาพสกิลมอนสมกับตัว · แชมเปี้ยนสกิลใหญ่ตาม · กรอบสกิลบอสสูงเกินตัวบอส
var ok := 0
var bad := 0
func chk(name: String, cond: bool, extra := "") -> void:
	if cond:
		ok += 1
	else:
		bad += 1
		print("  ✗ ", name, "  ", extra)

const WANT := {
	"echo_wraith": 240.0, "ferryman": 240.0, "garden_keeper": 240.0, "gullveig_ember": 250.0, "light_forsaken": 360.0,
	"mist_ghost": 140.0, "nidhogg_spawn": 160.0, "reflection": 210.0, "snow_mammoth": 500.0, "stone_soldier": 340.0,
	"thorn_matriarch": 300.0, "wall_shieldbearer": 330.0, "water_nymph": 230.0}

func _ready() -> void:
	await get_tree().process_frame
	# ---- 1) ค่าคลื่นในไฟล์ + สัดส่วนภาพต่อตัว ----
	for id in WANT:
		var d: MonsterData = load("res://data/monsters/%s.tres" % id)
		chk(id + " โหลดได้", d != null)
		if d == null: continue
		chk(id + " คลื่นสูง %d" % WANT[id], is_equal_approx(d.skill_wave_height, WANT[id]), str(d.skill_wave_height))
		var vis: float = SkillFxScale.report(d).get("wave", 0.0)
		var body := d.display_height if d.display_height > 0.0 else 300.0
		chk(id + " ภาพคลื่น ≥ 45% ของตัว หรือ ≥ 140", vis >= body * SkillFxScale.MIN_RATIO or vis >= 139.0, "%.0f / %.0f" % [vis, body])
		chk(id + " ช่องโดน ≤ %d (หลบทะลุได้)" % SkillFxScale.HIT_CAP, d.skill_wave_hit_width <= SkillFxScale.HIT_CAP and d.skill_wave_hit_width >= 42.0, str(d.skill_wave_hit_width))
	var bap: MonsterData = load("res://data/monsters/baphomet.tres")
	chk("บาฟโฟเมทคลื่นเดิม 350 (ใหญ่พออยู่แล้ว)", is_equal_approx(bap.skill_wave_height, 350.0))
	var hr: MonsterData = load("res://data/monsters/stone_hrungnir.tres")
	chk("หรุงนีร์เสาศิลา 720", is_equal_approx(hr.skill_bolt_height, 720.0) and is_equal_approx(hr.skill_bolt_hit_width, 122.0))
	var ra: MonsterData = load("res://data/monsters/radiant_alfr.tres")
	chk("อัลฟ์เรืองรอง ลำแสง 660 · กระสุน 140", is_equal_approx(ra.skill_bolt_height, 660.0) and is_equal_approx(ra.projectile_height, 140.0))
	var kp: MonsterData = load("res://data/monsters/king_poring.tres")
	chk("คิงโพริง บอล 125 ระเบิด 300", is_equal_approx(kp.skill_projectile_height, 125.0) and is_equal_approx(kp.skill_explosion_height, 300.0))
	# ---- 2) แชมเปี้ยน ----
	var m: MonsterData = (load("res://data/monsters/snow_mammoth.tres") as MonsterData).duplicate()
	SkillFxScale.apply(m, 1.3)
	chk("แชมเปี้ยน: คลื่น ×1.3", is_equal_approx(m.skill_wave_height, 650.0), str(m.skill_wave_height))
	chk("แชมเปี้ยน: ช่องโดนไม่เกินเพดาน", m.skill_wave_hit_width <= SkillFxScale.HIT_CAP, str(m.skill_wave_hit_width))
	var w: MonsterData = (load("res://data/monsters/water_nymph.tres") as MonsterData).duplicate()
	var hw0 := w.skill_wave_hit_width
	SkillFxScale.apply(w, 1.3)
	chk("แชมเปี้ยน: ช่องโดนโตตาม (ต่ำกว่าเพดาน)", is_equal_approx(w.skill_wave_hit_width, hw0 * 1.3), str(w.skill_wave_hit_width))
	var orig: MonsterData = load("res://data/monsters/water_nymph.tres")
	chk("แชมเปี้ยนไม่แตะไฟล์ต้นฉบับ", is_equal_approx(orig.skill_wave_height, 230.0))
	# ---- 3) มอนจริงเกิดเป็นแชมเปี้ยน ----
	var mon = load("res://scenes/monsters/monster.tscn").instantiate()
	mon.data = load("res://data/monsters/stone_soldier.tres")
	add_child(mon)
	await get_tree().process_frame
	mon._make_champion()
	chk("_make_champion ขยายภาพสกิล", is_equal_approx(mon.data.skill_wave_height, 340.0 * 1.3), str(mon.data.skill_wave_height))
	mon.queue_free()
	# ---- 4) กรอบสกิลบอส: บอสตัวสูง → กรอบสูงเกินตัว · บอสตัวเตี้ย → เท่าเดิม ----
	for pair in [["light_forsaken", 650.0 * 1.1], ["false_judge", 480.0]]:
		var boss = load("res://scenes/monsters/monster.tscn").instantiate()
		boss.data = load("res://data/monsters/%s.tres" % pair[0])
		boss.position = Vector2(600, 500)
		add_child(boss)
		await get_tree().process_frame
		var sk: Dictionary = BossSkillSet.skill_of(boss.data.id, 1)
		var fx = preload("res://scripts/entities/boss_zone_skill.gd").cast(boss, sk, 0)
		var hmin := 99999.0
		var widths := []
		for z in fx.zones:
			if String(z["kind"]) == "pillar": hmin = minf(hmin, z["rect"].size.y)
			widths.append(z["rect"].size.x)
		var body: float = boss.body_size().y
		print("  ", pair[0], " body ", body, " → กรอบสูงสุดต่ำสุด ", hmin, " กว้าง ", widths)
		chk(pair[0] + " กรอบเสาสูง ≥ ตัวบอส", hmin >= body, "%s < %s" % [hmin, body])
		var foot: float = boss.foot_position().y
		var on_ground := true
		for z in fx.zones: on_ground = on_ground and absf(z["rect"].end.y - foot) < 0.5
		chk(pair[0] + " ฐานกรอบยังอยู่ที่พื้น", on_ground)
		fx.queue_free(); boss.queue_free()
	print("== r172 skillfx: %d ผ่าน %d ล้ม ==" % [ok, bad])
	get_tree().quit()
