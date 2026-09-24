## MonsterBase — มอนสเตอร์ทุกตัวใช้สคริปต์นี้ตัวเดียว
##
## เพิ่มมอนใหม่ = สร้างไฟล์ MonsterData (.tres) ใหม่ แล้วลากใส่ช่อง "Data"
## ไม่ต้องเขียนสคริปต์ใหม่ ไม่ต้องสร้าง Scene ใหม่
##
## โครงสร้าง Scene:
##   Monster (CharacterBody2D)  <- ใส่สคริปต์นี้
##   ├── AnimatedSprite2D
##   └── CollisionShape2D  (ใช้ CapsuleShape2D)
extends CharacterBody2D

enum State { IDLE, WANDER, CHASE, ATTACK, HURT, DEAD }

## มอนใจดีที่ถูกตี จะไล่ตามต่ออีกกี่วินาทีหลังคลาดสายตา
## ★ รอบ 44: ไม่ใช้แล้ว ★ — โดนตี/เห็นผู้เล่น = ไล่ไม่หยุดจนกว่าผู้เล่นหรือมอนตัวนั้นตาย
const AGGRO_MEMORY := 8.0

## ★ ขนาดตัวเลขดาเมจ ★ อยากให้ใหญ่ขึ้นอีก แก้สองเลขนี้
const DAMAGE_FONT_SIZE := 32
const DAMAGE_FONT_CRIT := 40
## ★ รอบ 146 ★ เอฟเฟกต์คริ: แฉกทองเดิม (ปิด) · สโลว์เมื่อคริกิน ≥ x ของ MaxHP มอน · ช้าเหลือกี่เท่า · นานกี่วิ (เวลาจริง)
const CRIT_GOLD_BURST := true
## ★ รอบ 150 ★ เดิม 10% ของ MaxHP → มอนธรรมดาโดนคริแทบทุกทีก็เข้าเงื่อนไข สกิลหลายฮิตยิ่งต่อกันเป็นสโลว์ยาว (ผู้ใช้: "เหมือนโดนสโล")
## ตอนนี้: ต้องกิน ≥25% MaxHP · มอนเลเวลไม่ต่ำกว่าผู้เล่นเกิน 8 · เว้นอย่างน้อย CRIT_SLOWMO_COOLDOWN วิ · ช้าแค่ 0.65 เท่า 0.12 วิ
const CRIT_SLOWMO_HP_FRACTION := 0.25
const CRIT_SLOWMO_SCALE := 0.65
const CRIT_SLOWMO_TIME := 0.12
const CRIT_SLOWMO_COOLDOWN := 6.0
const CRIT_SLOWMO_LEVEL_GAP := 8

signal died(monster: Node, data: MonsterData)
signal ground_slam_impact(origin: Vector2, radius: float, skill: bool, hit_index: int)
signal projectile_released(projectile: MonsterProjectile, release_frame: int)

const LAVA_SLAM_FX = preload("res://scripts/entities/lava_slam_fx.gd")

## ★ ลาก MonsterData (.tres) มาใส่ตรงนี้ ★
@export var data: MonsterData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var hp: int = 1
var _wound_time := 0.0
var _wound_bonus := 0.0
var _wound_label: Label
var state: State = State.IDLE
var spawn_position: Vector2
var facing: int = -1

var _player: Node2D = null
var _attack_timer := 0.0
var _wander_timer := 0.0
var _wander_dir := 0
var _look_timer := 0.0
## ★ กันติดกำแพง (รอบ 35) ★ จะเดินแต่ไม่ขยับ = ติด
var _stuck_time := 0.0
var _last_x := 0.0
var _want_vx := 0.0   # ความเร็วที่ "ตั้งใจ" ก่อน move_and_slide (มันแก้ velocity ให้หลังไถล)      # ★ หันมองรอบ ๆ ระหว่างยืนพัก (รอบ 33) ★ 0 = ไม่ต้องหัน
var _hurt_flash := 0.0
var _hp_bar: ProgressBar
var _aggro := false
var _aggro_timer := 0.0
## ★ รอบ 44 — "ล็อกเป้า" แล้ว ★ มอนที่เห็นผู้เล่น (ตัวดุ) หรือโดนตี (ทุกตัว)
## จะไล่ตามได้ไกลไม่จำกัด ไม่สนระยะ leash/detect อีก จนกว่าผู้เล่นตาย หรือมันตาย
var _aggro_locked := false
var _jump_cd := 0.0
var _skill_cd := 0.0
var _special_cast_count := 0
var _spawn_locked := false
var _fit_cache: Dictionary = {}
## ★ รอบ 83 ★ ความสูงของท่าอ้างอิง (-1 = ยังไม่ได้วัด)
var _ref_tallest: float = -1.0
## ★ รอบ 54 — บิน ★ เฟสของการโยกขึ้นลง (สุ่มเริ่ม ไม่งั้นทั้งฝูงโยกพร้อมกัน)
var _hover_t: float = randf() * TAU
## โหลดฉากของตกไว้ล่วงหน้า (รอบ 44 — เดิม load() ตอนมอนตาย)
const DROPPED_ITEM_SCENE: PackedScene = preload("res://scenes/items/dropped_item.tscn")


## ให้ Spawner เรียกหลังวางตำแหน่งเสร็จ เพื่อบอกว่า "บ้าน" อยู่ตรงไหน
func set_home(pos: Vector2) -> void:
	spawn_position = pos
	_last_x = global_position.x
	# ★ สุ่มจังหวะเริ่มต้น ★ ไม่งั้นมอนทั้งฝูงจะเดิน/หยุดพร้อมกันเป๊ะ ดูเป็นหุ่นยนต์
	_wander_timer = randf() * 1.5
	_wander_dir = 0 if randf() < 0.35 else (-1 if randf() < 0.5 else 1)
	_spawn_locked = true


func _ready() -> void:
	add_to_group("enemy")
	if not _spawn_locked:
		spawn_position = global_position

	if data == null:
		push_error("[Monster] ยังไม่ได้ใส่ MonsterData ให้ %s" % name)
		set_physics_process(false)
		return

	if get_meta(&"champion", false):   # ★ รอบ 158 ★ สปอว์นเนอร์สุ่มให้เป็นแชมเปี้ยน
		_make_champion()
	hp = data.max_hp
	_apply_visual()
	_create_hp_bar()
	if is_champion:
		_attach_champion_fx()
	preload("res://scripts/entities/foot_shadow.gd").attach(self)
	_aggro = data.ai_type == MonsterData.AIType.AGGRESSIVE and not _calmed()
	# กันบอสร่ายสกิลใส่ทันทีที่เห็นหน้า
	_skill_cd = data.skill_cooldown * 0.5
	# ★ รอบ 105 ★ ย้อมสี + พูดตอนเกิด
	if data.tint != Color.WHITE:
		sprite.modulate = data.tint
	if not data.spawn_lines.is_empty():
		_say_line(data.spawn_lines[randi() % data.spawn_lines.size()], Color("#c9d6ff"))


# =========================================================
# ★ รอบ 158 ★ มอนแชมเปี้ยน — สปอว์นเนอร์สุ่ม MonsterSpawner.CHAMPION_CHANCE ในแมพทุ่ง (ไม่ใช่บอส)
# ตัวใหญ่ขึ้น + ป้ายชื่อทอง + ออร่าใต้เท้า (ไม่ย้อมสี) · เก่งขึ้น ~3 เท่า · EXP/ซีนี ×3 · ทอยดรอป 2 รอบ
# =========================================================
const CHAMPION_HP := 3.0
const CHAMPION_ATK := 1.5
const CHAMPION_DEF := 1.2
const CHAMPION_REWARD := 3.0
const CHAMPION_SCALE := 1.3
var is_champion := false

# ★ รอบ 182 ★ ตราทองของแชมเปี้ยน (ระบบ B บท 9) — สุ่ม 1 อย่าง (Lv < 60) หรือ 1-2 อย่าง ตอนเกิด · ชื่อตราโชว์ใต้ป้ายแชมเปี้ยน
## ตั้งเองได้ก่อน add_child: set_meta("gold_marks", [..]) · กันบางตรา: set_meta("gold_mark_exclude", [..])
const GOLD_MARK_NAMES := {&"gold_shield": "โล่ทอง", &"haste": "เร่งรีบ", &"split": "แตกร่าง",
	&"reflect": "สะท้อน", &"warden": "ผู้พิทักษ์", &"regen": "ฟื้นฟู"}
const GOLD_SHIELD_CUT := 0.6      ## โล่ทอง: ตีธรรมดาเข้าแค่ 40% · โดนสกิล 1 ที = โล่แตก
const GOLD_SHIELD_BACK := 8.0     ## โล่แตกแล้วกลับมาใน 8 วิ
const GOLD_HASTE := 1.35          ## เร่งรีบ: เดินเร็ว ×1.35 · ตีถี่ขึ้น (คูลดาวน์ ÷1.35)
const GOLD_WARDEN_RANGE := 420.0  ## ผู้พิทักษ์: มอนตัวอื่นในระยะนี้รับดาเมจ -30%
const GOLD_WARDEN_CUT := 0.3
const GOLD_REFLECT := 0.1         ## สะท้อน: โดนคริ → เด้งกลับ 10% ของดาเมจ (ไม่เกิน 5% HP สูงสุดผู้เล่น · 0.5 วิ/ครั้ง)
const GOLD_REFLECT_CAP := 0.05
const GOLD_REGEN := 0.015         ## ฟื้นฟู: ไม่โดนตี 3 วิ → ฟื้น 1.5% HP/วิ
const GOLD_SPLIT_HP := 0.2        ## แตกร่าง: ตายแล้วแยก 2 ตัวเล็ก HP 20% (ไม่มี EXP/ของ/นับเควส)
var gold_marks: Array[StringName] = []
var gold_shield_up := false
var _gold_shield_back := 0.0
var _gold_regen_idle := 0.0
var _gold_regen_acc := 0.0
var _gold_reflect_cd := 0.0


static func roll_gold_marks(level: int, exclude: Array = []) -> Array[StringName]:
	var pool: Array = GOLD_MARK_NAMES.keys().filter(func(k): return not exclude.has(k))
	pool.shuffle()
	var n := 1 if level < 60 else randi_range(1, 2)
	var out: Array[StringName] = []
	for i in range(mini(n, pool.size())):
		out.append(pool[i])
	return out


func gold_mark_text() -> String:
	var names: Array[String] = []
	for m in gold_marks:
		names.append(String(GOLD_MARK_NAMES.get(m, m)))
	return " · ".join(names)


func gold_regenerating() -> bool:
	return &"regen" in gold_marks and _gold_regen_idle >= 3.0 and data != null and hp < data.max_hp


func _make_champion() -> void:
	is_champion = true
	var d: MonsterData = data.duplicate()
	d.max_hp = int(d.max_hp * CHAMPION_HP)
	d.atk_min = int(round(d.atk_min * CHAMPION_ATK))
	d.atk_max = int(round(d.atk_max * CHAMPION_ATK))
	d.def = int(round(d.def * CHAMPION_DEF))
	d.exp_reward = int(round(d.exp_reward * CHAMPION_REWARD))
	d.job_exp_reward = int(round(d.job_exp_reward * CHAMPION_REWARD))
	d.zeny_min = int(round(d.zeny_min * CHAMPION_REWARD))
	d.zeny_max = int(round(d.zeny_max * CHAMPION_REWARD))
	if d.display_height > 0.0:
		d.display_height *= CHAMPION_SCALE
	else:
		d.sprite_scale *= CHAMPION_SCALE
	d.hp_bar_offset_y *= CHAMPION_SCALE
	SkillFxScale.apply(d, CHAMPION_SCALE)   # ★ รอบ 172 ★ ตัวใหญ่ขึ้น = ภาพสกิลใหญ่ตาม
	# ★ รอบ 182 ★ ตราทอง
	if has_meta(&"gold_marks"):
		gold_marks.assign(get_meta(&"gold_marks"))
	else:
		gold_marks = roll_gold_marks(d.level, get_meta(&"gold_mark_exclude", []))
	if &"haste" in gold_marks:
		d.move_speed *= GOLD_HASTE
		d.attack_cooldown /= GOLD_HASTE
	gold_shield_up = &"gold_shield" in gold_marks
	if &"warden" in gold_marks:
		add_to_group(&"gold_warden")
	data = d


func _attach_champion_fx() -> void:
	var aura = preload("res://scripts/entities/champion_aura.gd").new()
	aura.name = "ChampionAura"
	aura.radius = maxf(60.0, hit_width() * 0.75)
	add_child(aura)
	aura.position = foot_position() - global_position
	var tag := Label.new()
	tag.name = "ChampionTag"
	tag.text = "★ แชมเปี้ยน ★"
	if not gold_marks.is_empty():   # ★ รอบ 182 ★ ชื่อตราทองบรรทัดที่สอง
		tag.text += "\n" + gold_mark_text()
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", Color("#ffd86a"))
	tag.add_theme_color_override("font_outline_color", Color("#3a2408"))
	tag.add_theme_constant_override("outline_size", 5)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.size = Vector2(200, 22 if gold_marks.is_empty() else 52)
	tag.position = Vector2(-100, data.hp_bar_offset_y - (26 if gold_marks.is_empty() else 60))
	tag.z_index = 101
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)
	Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - 50), "แชมเปี้ยนปรากฏตัว!", Color("#ffd86a"), 20, 0)
	if not gold_marks.is_empty():   # ★ รอบ 182 ★
		var fx = preload("res://scripts/entities/gold_mark_fx.gd").new()
		fx.name = "GoldMarkFX"
		fx.monster = self
		add_child(fx)


# ★ รอบ 182 ★ ตราทอง — ปรับดาเมจที่ผู้เล่นทำ (โล่ทอง · ผู้พิทักษ์ใกล้ ๆ · สะท้อน)
func _gold_mark_damage(dmg: int, source: StringName, crit: bool) -> int:
	var out := float(dmg)
	if gold_shield_up:
		if source not in [&"", &"basic", &"basic_finisher"]:
			gold_shield_up = false
			_gold_shield_back = GOLD_SHIELD_BACK
			Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - hover_lift() - 40), "โล่ทองแตก!", Color("#ffe27a"), 22, 0)
		else:
			out *= 1.0 - GOLD_SHIELD_CUT
	if _gold_warden_near():
		out *= 1.0 - GOLD_WARDEN_CUT
	_gold_regen_idle = 0.0
	if crit and &"reflect" in gold_marks and _gold_reflect_cd <= 0.0:
		_gold_reflect_cd = 0.5
		var p := get_tree().get_first_node_in_group("player")
		if p != null and p.has_method("take_damage") and not PlayerState.is_dead():
			var back := mini(int(out * GOLD_REFLECT), int(PlayerState.stats.max_hp * GOLD_REFLECT_CAP))
			if back > 0:
				p.take_damage(back, 0.0, signi(int(p.global_position.x - global_position.x)))
	return maxi(1, int(round(out)))


func _gold_warden_near() -> bool:
	for w in get_tree().get_nodes_in_group(&"gold_warden"):
		if w != self and is_instance_valid(w) and not w.is_dead() and w.global_position.distance_to(global_position) <= GOLD_WARDEN_RANGE:
			return true
	return false


func _tick_gold_marks(delta: float) -> void:
	_gold_reflect_cd -= delta
	if &"gold_shield" in gold_marks and not gold_shield_up:
		_gold_shield_back -= delta
		if _gold_shield_back <= 0.0:
			gold_shield_up = true
	if &"regen" in gold_marks:
		_gold_regen_idle += delta
		if gold_regenerating():
			_gold_regen_acc += data.max_hp * GOLD_REGEN * delta
			var add := int(_gold_regen_acc)
			if add > 0:
				_gold_regen_acc -= add
				hp = mini(data.max_hp, hp + add)
				_update_hp_bar()


## แตกร่าง — ตัวเล็ก 2 ตัว (ไม่มีรางวัล ไม่นับเควส)
func _gold_split() -> void:
	if scene_file_path == "" or get_parent() == null:
		return
	var scene: PackedScene = load(scene_file_path)
	for side in [-1, 1]:
		var d: MonsterData = data.duplicate()
		d.max_hp = maxi(1, int(data.max_hp * GOLD_SPLIT_HP))
		d.atk_min = int(data.atk_min * 0.5)
		d.atk_max = int(data.atk_max * 0.5)
		d.exp_reward = 0
		d.job_exp_reward = 0
		d.zeny_min = 0
		d.zeny_max = 0
		d.drops = d.drops.duplicate()
		d.drops.clear()
		if d.display_height > 0.0:
			d.display_height *= 0.6
		else:
			d.sprite_scale *= 0.6
		d.hp_bar_offset_y *= 0.6
		var m = scene.instantiate()
		m.data = d
		m.set_meta(&"split_child", true)
		m.position = position + Vector2(side * 70.0, 0.0)
		get_parent().add_child.call_deferred(m)


# =========================================================
# ★ รอบ 105 ★ มอนใจดีตามเงื่อนไข + พูด
# =========================================================
var _calm_cache := -1.0
var _calm_value := false

## ผู้เล่นมีธง/ไอเทมที่ทำให้มอนตัวนี้ไม่ไล่ตีไหม (เช็คซ้ำทุก 1 วิ ไม่ต้องไล่กระเป๋าทุกเฟรม)
func _calmed() -> bool:
	if data == null or (data.calm_if_flag == &"" and data.calm_if_item == &""):
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - _calm_cache < 1.0:
		return _calm_value
	_calm_cache = now
	_calm_value = (data.calm_if_flag != &"" and PlayerState.has_flag(data.calm_if_flag)) \
			or (data.calm_if_item != &"" and PlayerState.inventory != null and PlayerState.inventory.count_of(data.calm_if_item) > 0)
	return _calm_value


func _say_line(text: String, color: Color) -> void:
	if text.strip_edges() == "":
		return
	Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - hover_lift() - 30), text, color, 16, 0)


func _apply_visual() -> void:
	if data.sprite_frames != null:
		sprite.sprite_frames = data.sprite_frames
	sprite.scale = data.sprite_scale
	sprite.offset = data.sprite_offset
	if data.fit_fixed_anchor_enabled and not sprite.frame_changed.is_connected(_apply_fit):
		sprite.frame_changed.connect(_apply_fit)

	if collision != null and collision.shape is CapsuleShape2D:
		var shape := (collision.shape as CapsuleShape2D).duplicate() as CapsuleShape2D
		shape.radius = data.hitbox_size.x * 0.5
		shape.height = maxf(data.hitbox_size.y, shape.radius * 2.0)
		collision.shape = shape

	_play("Idle")
	_apply_fit()


# =========================================================
# ปรับขนาด/จัดเท้าให้ยืนระนาบเดียวกับผู้เล่น
# =========================================================
## ตำแหน่งเท้าในโลก — ใช้เทียบระนาบกับผู้เล่น
func foot_position() -> Vector2:
	if data == null:
		return global_position
	return global_position + Vector2(0.0, data.foot_offset())


## ★ ขนาดตัวจริงบนจอ (กว้าง, สูง) ★ ใช้ตัดสินว่าดาบผู้เล่นฟันถึงไหม
## ขยายมอนให้ใหญ่ขึ้น = กรอบนี้ใหญ่ตามเอง ไม่ต้องไปแก้ระยะที่ไหนอีก
func body_size() -> Vector2:
	var w := 40.0
	var h := 60.0
	if data != null:
		w = maxf(data.hitbox_size.x, 16.0)
		h = maxf(data.hitbox_size.y, 16.0)
		if data.display_height > 0.0:
			h = maxf(h, data.display_height)
	# ถ้าไม่ได้ตั้ง Display Height ก็วัดจากสไปรท์จริง
	if sprite != null and sprite.sprite_frames != null:
		var info: Dictionary = _fit_frames(sprite.animation)
		if not info.is_empty():
			# ★ รอบ 83/86 ★ ใช้ "ความสูงที่ใช้คิดสเกล" ของท่านั้น กรอบตัวจะได้นิ่ง
			# ไม่โตตามอาวุธที่ยกขึ้นตอนตี และไม่เพี้ยนตอนถอยไปย่อแยกท่า
			var t: float = float(info.get("fit_from", info.tallest))
			h = maxf(h, t * absf(sprite.scale.y))
	# ตัวสูงแต่กล่องชนแคบมาก ๆ ให้กว้างขึ้นหน่อย ไม่งั้นฟันยาก
	w = maxf(w, h * 0.35)
	return Vector2(w, h)


## ★★ รอบ 87 — ความกว้างของ "กรอบโดนตี" ★★
## วัดจากภาพจริงของท่าที่กำลังเล่น (ไม่ใช่กล่องชนพื้นที่แคบกว่าตัวมาก)
## ใช้เฉพาะตอนผู้เล่นฟันโดนเท่านั้น — ระยะที่ "มอนตีเรา" ยังใช้ body_size() เหมือนเดิม
func hit_width() -> float:
	var w := body_size().x
	if data == null or not data.hit_box_from_sprite:
		return w
	if sprite == null or sprite.sprite_frames == null:
		return w
	var info: Dictionary = _fit_frames(sprite.animation)
	if info.is_empty():
		return w
	var drawn: float = float(info.get("widest", 0.0)) * absf(sprite.scale.x)
	return maxf(w, drawn * data.hit_box_width_ratio)


## ★ กรอบตัวมอนในพิกัดโลก ★ (เท้าอยู่ขอบล่าง)
func body_rect() -> Rect2:
	var f := foot_position()
	var s := body_size()
	s.x = hit_width()
	# ★ รอบ 54: มอนบิน — กรอบโดนฟันลอยขึ้นตามภาพ (ฟันที่พื้นจะไม่โดน ต้องฟันที่ตัวมัน) ★
	return Rect2(f.x - s.x * 0.5, f.y - s.y - hover_lift(), s.x, s.y)


## ระยะที่มอนตัวนี้ตีถึง — วัดจาก "ขอบตัวมัน" ออกไป
## (บอสตัวใหญ่จะได้ไม่ต้องเอาจุดกึ่งกลางมาจ่อตัวผู้เล่นถึงจะตีโดน)
##
## ★ รอบ 66 ★ มอนยิงกระสุน (Projectile Texture + Ranged Attack) ใช้ระยะยิงแทน
## → เห็นผู้เล่นปุ๊บก็ยืนยิงได้เลย ไม่ต้องเดินเข้ามาประชิด
func attack_reach() -> float:
	if data == null:
		return 70.0
	if data.is_ranged():
		return data.ranged_reach()
	return data.attack_range + body_size().x * 0.5


## ระยะที่ใช้ตัดสินว่า "ตีติดตัว" โดนไหม — ของมอนยิงไกลไม่เกี่ยว
func melee_reach() -> float:
	if data == null:
		return 70.0
	return data.attack_range + body_size().x * 0.5


func _apply_fit() -> void:
	if data == null or sprite.sprite_frames == null:
		return
	if data.display_height <= 0.0 and not data.align_feet:
		return

	var info: Dictionary = _fit_frames(sprite.animation)
	if info.is_empty():
		return

	var k: float = info.scale
	sprite.scale = Vector2(k, k)
	if data.fit_fixed_anchor_enabled:
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		var source_anchor: Vector2 = data.fit_animation_anchors.get(sprite.animation, data.fit_fixed_anchor)
		var anchor := source_anchor - texture.get_size() * 0.5
		var soles: PackedFloat32Array = info.get("soles", PackedFloat32Array())
		if sprite.frame < soles.size() and soles[sprite.frame] > 0.0:
			anchor.y = soles[sprite.frame] - texture.get_height() * 0.5
		sprite.offset.x = data.sprite_offset.x + (anchor.x if sprite.flip_h else -anchor.x)
		sprite.offset.y = data.sprite_offset.y
		if data.align_feet:
			sprite.offset.y += data.foot_offset() / k - anchor.y
		return

	var list: Array = info.frames
	if list.is_empty():
		return
	var fd: Dictionary = list[clampi(sprite.frame, 0, list.size() - 1)]

	sprite.offset.x = data.sprite_offset.x + (fd.dx_use if sprite.flip_h else -fd.dx_use)
	if data.align_feet:
		sprite.offset.y = data.sprite_offset.y + data.foot_offset() / k - fd.bottom_use


## วัดขนาดจริงของมอน (ไม่นับพื้นที่โปร่งใส) แล้วจำไว้
func _fit_frames(anim: StringName) -> Dictionary:
	if _fit_cache.has(anim):
		return _fit_cache[anim]

	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(anim):
		return {}

	# ★ รอบ 44 — วัดผ่าน SpriteFit (วัดครั้งเดียวทั้งเกมต่อชนิดมอน ไม่ใช่ทุกครั้งที่เกิด) ★
	var base: Dictionary = SpriteFit.measure(frames, anim)
	if base.is_empty():
		return {}
	var list: Array = base.frames
	var tallest: float = base.tallest

	# ★★ รอบ 83 — ทุกท่าตัวเท่ากัน ★★
	# เดิมวัด "ท่าที่กำลังเล่น" แล้วย่อให้สูงเท่า display_height พอดี
	# ท่าที่ยกอาวุธสูง (เช่น Attack ของผู้พิทักษ์เตาหลอม กรอบสูง 423 เทียบ Idle 375)
	# เลยโดนย่อทั้งตัวลง 11% → มอนหดตอนตี ซึ่งไม่ใช่สิ่งที่ควรเป็น
	# ตอนนี้วัดจาก "ท่าอ้างอิง" (ปกติคือ Idle) ท่าเดียว แล้วใช้สเกลนั้นกับทุกท่า
	var scale_from: float = tallest
	if data.fit_uniform_scale:
		var ref := _reference_tallest()
		# ★ รอบ 86 ★ ใช้สเกลของท่าอ้างอิงเฉพาะตอนที่ท่านี้สูงกว่าไม่มาก
		# ชีทบางท่า (Run ของออร์ค/มูนัค/อสูรสายฟ้า) วาดตัวมอนใหญ่กว่า Idle ถึง 2.2 เท่า
		# ถ้าใช้สเกลเดียวกันตัวจะบวมเป็น 2 เท่าทั้งตัว → กรณีนั้นถอยกลับไปย่อแยกทีละท่า
		if ref > 0.0 and (data.fit_fixed_anchor_enabled or tallest <= ref * data.fit_max_overshoot):
			scale_from = ref

	var k: float = data.sprite_scale.y
	if data.display_height > 0.0:
		k = data.display_height / maxf(1.0, scale_from)
	# คาลิเบรตขนาดลำตัวของแต่ละชีท โดยไม่วัดตามอาวุธที่เหวี่ยงในแต่ละเฟรม
	k *= maxf(0.01, float(data.fit_animation_scales.get(anim, 1.0)))

	var info := {"scale": k, "frames": list, "tallest": tallest, "fit_from": scale_from,
		"widest": float(base.get("widest", 0.0))}
	if data.fit_fixed_anchor_enabled and data.fit_foot_region.has_area() and data.fit_foot_animations.has(String(anim)):
		info["soles"] = SpriteFit.measure_soles(frames, anim, data.fit_foot_region)
	_fit_cache[anim] = info
	return info


## ความสูงของ "ท่าอ้างอิง" ที่ใช้คิดสเกลให้ทุกท่า (0 = หาไม่เจอ ให้ใช้ท่าตัวเองไปตามเดิม)
func _reference_tallest() -> float:
	if _ref_tallest >= 0.0:
		return _ref_tallest
	_ref_tallest = 0.0
	var frames := sprite.sprite_frames
	if frames == null:
		return 0.0
	var want: Array = [String(data.fit_reference_anim), "Idle", "Stand", "Run", "Walk"]
	for candidate in want:
		if String(candidate) == "":
			continue
		var real := _real_anim(String(candidate))
		if real == "" or frames.get_frame_count(real) <= 0:
			continue
		var base: Dictionary = SpriteFit.measure(frames, StringName(real))
		if base.is_empty():
			continue
		_ref_tallest = float(base.tallest)
		break
	return _ref_tallest


func _process(delta: float) -> void:
	_apply_fit()
	_apply_hover(delta)
	if _is_corpse:
		_process_corpse(delta)


# =========================================================
# ★ บิน / ลอยเหนือพื้น (รอบ 54) ★
# ตัวมอน (กล่องชน/foot_position) ยังอยู่บนพื้นตามเดิม → AI, ระนาบ, ระยะตี ไม่เปลี่ยน
# ยกเฉพาะ "ภาพ + หลอดเลือด" ขึ้นไป และ body_rect() (กรอบโดนฟัน) ขยับตามให้ผู้เล่นฟันโดนที่ตัวจริง
# =========================================================
## มอนบินตายแล้วร่วงลงพื้นเร็วแค่ไหน (พิกเซล/วินาที)
const HOVER_FALL_SPEED := 320.0

## ระยะที่ภาพลอยเหนือพื้นตอนนี้ (พิกเซลโลก · 0 = มอนธรรมดา)
func hover_lift() -> float:
	if data == null or not data.flying or state == State.DEAD:
		return 0.0
	return data.hover_height + sin(_hover_t) * data.hover_bob


func _apply_hover(delta: float) -> void:
	if data == null or not data.flying:
		return
	if state == State.DEAD:
		# ตายแล้วร่วงลงพื้น (ไม่วูบหายทันที)
		sprite.position.y = move_toward(sprite.position.y, 0.0, HOVER_FALL_SPEED * delta)
		return
	_hover_t += delta * TAU * data.hover_bob_speed
	var lift := hover_lift()
	sprite.position.y = -lift
	if _hp_bar != null:
		_hp_bar.position.y = data.hp_bar_offset_y - lift


# =========================================================
# PHYSICS
# =========================================================
func _physics_process(delta: float) -> void:
	_tick_wound(delta)
	_tick_burn(delta)
	if not gold_marks.is_empty() and state != State.DEAD:
		_tick_gold_marks(delta)   # ★ รอบ 182 ★
	_check_boss_intro()
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		if _hurt_flash <= 0.0:
			sprite.modulate = Color.WHITE

	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _jump_cd > 0.0:
		_jump_cd -= delta
	if _skill_cd > 0.0:
		_skill_cd -= delta

	# ★ รอบ 44 — ความโกรธไม่จางอีกแล้ว ★ (เดิมมอนใจดีเลิกไล่หลัง 8 วิ)
	# เลิกไล่อย่างเดียวคือผู้เล่นตาย → กลับไปเดินเล่นตามปกติ
	_player = get_tree().get_first_node_in_group("player")
	if _aggro_locked and (_player == null or not is_instance_valid(_player) or PlayerState.is_dead()):
		_aggro_locked = false
		_aggro = data.ai_type == MonsterData.AIType.AGGRESSIVE

	# ★ รอบ 181 ★ โดนโซ่พันธะ (Ninth Edge) — ยืนนิ่งช่วงสั้น ไม่เดิน ไม่เริ่มท่าใหม่ (บอสไม่โดน)
	if Time.get_ticks_msec() < int(get_meta("rb_stun_until", 0)):
		velocity.x = move_toward(velocity.x, 0.0, data.move_speed * 4.0 * delta)
		move_and_slide()
		return

	if state == State.ATTACK or state == State.HURT:
		velocity.x = move_toward(velocity.x, 0.0, data.move_speed * 4.0 * delta)
		move_and_slide()
		return

	# ★ รอบ 155 ★ ผู้เล่นกำลังคุย/อ่านป้ายในแมพทุ่ง → ยืนรอเฉย ๆ ไม่เดินเข้าหา ไม่ตี
	if PlayerState.has_method("talk_truce") and PlayerState.call("talk_truce"):
		velocity.x = move_toward(velocity.x, 0.0, data.move_speed * 4.0 * delta)
		if state != State.IDLE:
			state = State.IDLE
			_play("Idle")
		move_and_slide()
		return

	var home_offset := global_position.x - spawn_position.x
	# ★ รอบ 44 — ล็อกเป้าแล้วไม่มี "กำแพงระยะ" ★ ไล่ไปได้ทั่วแมพ
	var too_far_from_home: bool = (not _aggro_locked) and data.leash_range > 0.0 \
		and absf(home_offset) > data.leash_range

	# ------- ตัดสินใจว่าจะสู้ไหม -------
	# วัดจาก "ตำแหน่งเท้า" ทั้งคู่ จะได้ไม่เพี้ยนเพราะกล่องชนคนละขนาด
	var distance := INF
	var to_player_x := 0.0
	if _player != null and is_instance_valid(_player) and not PlayerState.is_dead():
		var player_foot: Vector2 = _player.foot_position() if _player.has_method("foot_position") \
			else _player.global_position
		var to_player: Vector2 = player_foot - foot_position()
		distance = to_player.length()
		to_player_x = to_player.x

	# มอนดุ = เห็นแล้วไล่เลย / มอนใจดี = ไล่เฉพาะตอนถูกตี
	# ★ รอบ 105 ★ มอนใจดีตามเงื่อนไข (ธง/ไอเทม) = ทำตัวเหมือน PASSIVE จนกว่าจะโดนตี
	var hostile: bool = _aggro or (data.ai_type == MonsterData.AIType.AGGRESSIVE and not _calmed())
	# ★★ รอบ 87 — บอสไล่ทั่วสนาม ★★
	# เดิมบอสรอให้ผู้เล่นเข้าระยะ Detect Range ก่อน ระหว่างนั้นเดินวนอยู่ในวง Wander Range
	# ของตัวเอง (อสูรสายฟ้า detect 420 · wander 260) → ดูเหมือน "วิ่งวนอยู่กับที่"
	# ตอนนี้บอสล็อกเป้าทันทีที่ผู้เล่นยังไม่ตายและอยู่ในแมพเดียวกัน
	if data.is_boss and data.boss_arena_aggro and not _aggro_locked \
			and data.ai_type != MonsterData.AIType.STATIONARY \
			and _player != null and is_instance_valid(_player) and not PlayerState.is_dead():
		_set_aggro()
		hostile = true
	# ★ รอบ 44 — มอนดุที่ "เห็น" ผู้เล่นครั้งแรก (เข้าระยะ detect) = ล็อกเป้าทันที ★
	if hostile and not _aggro_locked and distance <= data.detect_range \
			and data.ai_type != MonsterData.AIType.STATIONARY:
		_set_aggro()
	# ล็อกเป้าแล้ว = ไล่ได้ไกลไม่จำกัด (เดิมจำกัดที่ detect/leash → มอนวิ่งไปชน "กำแพงระยะ" แล้วหยุด)
	var chase_range: float = INF if _aggro_locked else data.detect_range
	var will_engage: bool = hostile and distance <= chase_range and not too_far_from_home

	if data.ai_type == MonsterData.AIType.STATIONARY:
		velocity.x = 0.0
		if hostile and _try_skill(distance, to_player_x):
			move_and_slide()
			return
		if distance <= attack_reach():
			_face_to(to_player_x)
			_try_attack()
		else:
			_play("Idle")

	elif will_engage:
		# ★ บอสร่ายสกิลได้จากระยะไกลกว่าการตีปกติ ★
		if _try_skill(distance, to_player_x):
			move_and_slide()
			return
		if distance <= attack_reach():
			velocity.x = 0.0
			_face_to(to_player_x)
			_try_attack()
		else:
			state = State.CHASE
			_face_to(to_player_x)
			var chase_dir := signi(int(signf(to_player_x)))
			# มอนที่กระโดดไม่ได้ จะไม่เดินตกเหวตามผู้เล่น
			if data.jump_force == 0.0 and not _has_ground_ahead(chase_dir):
				velocity.x = 0.0
				_play("Idle")
			else:
				velocity.x = chase_dir * data.move_speed
				_play("Run")
				if data.jump_while_chasing:
					_try_hop(1.0)

	elif too_far_from_home:
		# เดินกลับบ้าน
		state = State.WANDER
		var back := signf(-home_offset)
		velocity.x = back * data.move_speed * 0.6
		_face_to(back)
		_play("Run")
		if data.jump_while_chasing:
			_try_hop(0.8)

	else:
		_do_wander(delta)

	_want_vx = velocity.x
	_sync_run_anim_speed()
	move_and_slide()
	_check_stuck(delta)


## ★ รอบ 87 ★ เล่นท่าวิ่งช้าลงตามความเร็วที่ขยับจริง
## เดินเตร่ (wander_speed 50) แต่เล่นท่า Run ที่วาดไว้สำหรับวิ่ง 390 = ดูเหมือนวิ่งอยู่กับที่
func _sync_run_anim_speed() -> void:
	if sprite == null or data == null:
		return
	var real := _real_anim("Run")
	if real == "" or sprite.animation != StringName(real):
		if not is_equal_approx(sprite.speed_scale, 1.0):
			sprite.speed_scale = 1.0
		return
	var top: float = maxf(1.0, data.move_speed)
	sprite.speed_scale = clampf(absf(velocity.x) / top, 0.35, 1.0)


## มีพื้นอยู่ข้างหน้าไหม (กันมอนเดินตกขอบแมพ/ตกแท่น)
func _has_ground_ahead(dir: int) -> bool:
	if dir == 0 or not is_on_floor():
		return true
	var space := get_world_2d().direct_space_state
	# ★★ รอบ 87 — ยิงเรย์จาก "ปลายเท้า" ★★
	# เดิมยิงจาก global_position (จุดกำเนิด) ซึ่งอยู่กลางตัว — มอนตัวสูง (บอสสูง 300 px)
	# จุดกำเนิดอยู่เหนือพื้นเกิน 110 px เรย์เลยไม่เคยเจอพื้น = คิดว่าข้างหน้าเป็นเหวตลอด
	# ผลคือบอสหยุดเดินดื้อ ๆ ทั้งที่พื้นเรียบ ("วิ่งวนไม่ขยับไปไหน")
	var foot := foot_position()
	var ahead := foot + Vector2(dir * (data.hitbox_size.x * 0.5 + 14.0), -10.0)
	var query := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 120.0))
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return not space.intersect_ray(query).is_empty()


## กระโดดตามจังหวะ ไม่ใช่กระโดดรัวทุกเฟรม
func _try_hop(power_scale: float = 1.0) -> void:
	if data.jump_force == 0.0:
		return
	if data.flying and data.flying_no_hop:
		return                      # ★ รอบ 54: มอนบินไม่กระโดด (โยกขึ้นลงแทน) ★
	if not is_on_floor() or _jump_cd > 0.0:
		return
	velocity.y = data.jump_force * power_scale
	_jump_cd = maxf(0.15, data.jump_interval)
	_play("Jump")


# =========================================================
# ★★ กันมอนติดกำแพง (รอบ 35) ★★
# =========================================================
## ขยับได้ช้ากว่านี้ (พิกเซล/วินาที) ทั้งที่สั่งให้เดิน = ถือว่าติด
const STUCK_SPEED := 8.0
## ติดนานเกินนี้ (วินาที) ถึงจะแก้ให้
const STUCK_LIMIT := 0.7

func _check_stuck(delta: float) -> void:
	if state == State.DEAD or state == State.ATTACK or state == State.HURT:
		_stuck_time = 0.0
		_last_x = global_position.x
		return
	var moved: float = absf(global_position.x - _last_x)
	_last_x = global_position.x

	# สั่งให้เดินอยู่ แต่แทบไม่ขยับ = โดนอะไรบางอย่างขวาง
	if absf(_want_vx) > 1.0 and moved < STUCK_SPEED * delta:
		_stuck_time += delta
	else:
		_stuck_time = maxf(0.0, _stuck_time - delta * 2.0)
		return

	if _stuck_time < STUCK_LIMIT:
		return
	_stuck_time = 0.0
	_free_from_wall()


## ★ หลุดจากกำแพง ★ กลับตัว + ย้าย "บ้าน" มาฝั่งนี้
## ถ้าไม่ย้ายบ้าน ระบบ leash จะลากมันกลับไปชนกำแพงเดิมซ้ำ ๆ ไม่จบ
func _free_from_wall() -> void:
	var away: int = -signi(int(signf(_want_vx)))
	if away == 0:
		away = -facing

	# กระโดดข้ามได้ก็ลองข้ามก่อน (มอนที่กระโดดไม่ได้ jump_force = 0)
	if data.jump_force < 0.0 and is_on_floor():
		velocity.y = data.jump_force

	# กำลังไล่ผู้เล่นอยู่ ไม่ต้องเลิกไล่ แค่ลองกระโดดข้าม
	if state == State.CHASE:
		return

	_wander_dir = away
	_wander_timer = randf_range(1.2, 2.2)
	_look_timer = 0.0
	velocity.x = away * data.wander_speed
	_face_to(away)
	# ★ ย้ายบ้านมาอยู่ฝั่งที่เดินได้ ★
	spawn_position.x = global_position.x + away * 60.0


# =========================================================
# เดินเล่นไปมารอบจุดเกิด
# =========================================================
func _do_wander(delta: float) -> void:
	if data.wander_speed <= 0.0:
		state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, data.move_speed)
		_play("Idle")
		return

	state = State.WANDER
	_wander_timer -= delta

	if _wander_timer <= 0.0:
		_pick_new_wander()

	var offset := global_position.x - spawn_position.x
	var limit: float = data.wander_range
	if data.leash_range > 0.0:
		limit = minf(limit, data.leash_range * 0.9)

	# ออกนอกอาณาเขต -> เดินกลับ (ตั้งเวลาไว้ด้วย จะได้ไม่สลับทิศทุกเฟรม)
	if absf(offset) > limit:
		var back := -1 if offset > 0.0 else 1
		if _wander_dir != back:
			_wander_dir = back
			_wander_timer = randf_range(1.0, 2.0)

	# ชนกำแพง หรือ ข้างหน้าเป็นเหว -> กลับตัว
	elif _wander_dir != 0 and (is_on_wall() or not _has_ground_ahead(_wander_dir)):
		_wander_dir = -_wander_dir
		_wander_timer = randf_range(1.0, 2.0)

	if _wander_dir == 0:
		# ★ ยืนพัก ★ หยุดสนิทแล้วเล่นท่า Idle
		velocity.x = move_toward(velocity.x, 0.0, data.wander_speed * 4.0)
		_play("Idle")
		# หันไปมองอีกด้านหนึ่งกลางช่วงพัก — ทำให้ดูเหมือนกำลังมองรอบ ๆ ไม่ใช่ค้างแข็ง
		if _look_timer > 0.0:
			_look_timer -= delta
			if _look_timer <= 0.0:
				_face_to(-facing)
	else:
		velocity.x = _wander_dir * data.wander_speed
		_face_to(_wander_dir)
		_play("Run")
		if data.hop_while_wandering:
			_try_hop(0.55)


func _pick_new_wander() -> void:
	# ★★ สลับ "เดิน" กับ "ยืนพัก" ★★ (รอบ 33 — ปรับค่าได้ต่อมอนในไฟล์ .tres)
	# ห้ามพักติดกัน 2 รอบ (เช็ค _wander_dir != 0) ไม่งั้นมอนจะยืนแช่ยาวผิดปกติ
	if _wander_dir != 0 and randf() < data.wander_pause_chance:
		_wander_dir = 0
		_wander_timer = randf_range(data.wander_pause_min, data.wander_pause_max)
		# หันมองรอบ ๆ ประมาณกลางช่วงพัก
		_look_timer = _wander_timer * randf_range(0.35, 0.65) \
			if randf() < data.wander_look_chance else 0.0
	else:
		_wander_dir = -1 if randf() < 0.5 else 1
		_wander_timer = randf_range(data.wander_walk_min, data.wander_walk_max)
		_look_timer = 0.0


func _face_to(dir_x: float) -> void:
	if dir_x == 0.0:
		return
	facing = 1 if dir_x > 0.0 else -1
	sprite.flip_h = facing > 0   # สไปรท์ต้นฉบับหันซ้าย


## ★ ชื่ออนิเมชันที่ระบบยอมรับ ★
## ตั้งชื่อแบบไหนก็ได้ในลิสต์ และ "ตัวพิมพ์เล็ก-ใหญ่ไม่สำคัญ" (Die = die = DIE)
## ถ้าไม่มีชื่อไหนเลย จะไล่ลงไปใช้ตัวสำรองท้ายลิสต์แทน (กันมอนค้าง/หาย)
const ANIM_FALLBACK := {
	"Idle": ["Idle", "Stand"],
	"Run": ["Run", "Walk", "Move", "Jump", "Idle"],
	"Jump": ["Jump", "Hop", "Run", "Idle"],
	"Attack": ["Attack", "Atk", "Attact", "Idle"],
	"Hit": ["Hit", "Hurt", "Damage", "Idle"],
	"Death": ["Death", "Die", "Dead", "Dying", "Hit", "Idle"],
}

var _anim_lookup: Dictionary = {}   # ชื่อตัวพิมพ์เล็ก -> ชื่อจริงใน SpriteFrames


## หาชื่ออนิเมชันจริง โดยไม่สนตัวพิมพ์เล็ก-ใหญ่
func _real_anim(anim_name: String) -> String:
	if sprite.sprite_frames == null:
		return ""
	if sprite.sprite_frames.has_animation(anim_name):
		return anim_name
	if _anim_lookup.is_empty():
		for a in sprite.sprite_frames.get_animation_names():
			_anim_lookup[String(a).to_lower()] = String(a)
	return _anim_lookup.get(anim_name.to_lower(), "")


## เล่นท่านี้ แล้วคืนชื่อท่าที่ได้เล่นจริง ("" = ไม่มีท่าไหนใช้ได้เลย)
##
## ★ restart ★ ใส่ true เมื่อ "เริ่มท่าใหม่จริง ๆ" (เริ่มร่ายสกิล / เริ่มตี / โดนตี)
## ท่าพวกนี้ถูกเรียกครั้งเดียวต่อการกระทำ ไม่ได้เรียกทุกเฟรม เลยบังคับให้เริ่มที่เฟรม 0 ได้
##
## ★ กับดัก 94 (รอบ 65) ★ ท่าที่ปิด loop พอเล่นจบจะค้างที่เฟรมสุดท้าย และ is_playing() = false
## เงื่อนไขเดิมเช็คแค่ "ชื่อท่าเปลี่ยน" หรือ "หยุดอยู่ + ท่านี้วนซ้ำ" → ท่าปิด loop ที่ค้างอยู่
## จะไม่ถูกสั่งเล่นซ้ำเลย ★ อาการ: บอสร่ายสกิลรอบสองแล้วยืนแข็งค้างท่าเดิม สายฟ้าลงแต่ตัวไม่ขยับ ★
## (เจอกับท่า "คำราม" ของอสูรสายฟ้าหลังปิด loop ในรอบ 64)
func _play(anim: String, restart: bool = false) -> String:
	if sprite.sprite_frames == null:
		return ""
	for candidate in ANIM_FALLBACK.get(anim, [anim]):
		var real := _real_anim(String(candidate))
		if real != "" and sprite.sprite_frames.get_frame_count(real) > 0:
			# ★ รอบ 54 — กับดัก 82 ★ มอนที่มีท่าเดียว (เช่นฮอร์เน็ต มีแค่ Idle): ตอนใส่ SpriteFrames
			# Godot จะตั้ง sprite.animation เป็นท่านั้นให้เอง "แต่ไม่เล่น" → เช็คแค่ชื่อไม่พอ ต้องเช็ค is_playing ด้วย
			# (ท่าที่ไม่วนซ้ำแล้วเล่นจบ เช่น Attack/Death ไม่ต้องเริ่มใหม่ ไม่งั้นจะกระตุกวนไปเรื่อย)
			var switched := false
			if restart:
				sprite.play(real)
				sprite.set_frame_and_progress(0, 0.0)
				switched = true
			elif sprite.animation != real or (not sprite.is_playing() and sprite.sprite_frames.get_animation_loop(real)):
				sprite.play(real)
				switched = true
			if switched:
				# ★★ รอบ 88 ★★ (1) ความเร็วภาพของท่าวิ่ง (รอบ 87) ต้องไม่ติดมากับท่าอื่น
				# เดิม _sync_run_anim_speed() ถูกเรียกท้าย _physics_process ซึ่งสถานะ ATTACK/HURT
				# return ออกก่อนถึง → มอนที่เดินเตร่อยู่ (ภาพ 0.35×) พอเริ่มตี/โดนตี ท่านั้นเล่นช้า 3 เท่า
				# จังหวะดาเมจของ attack_follow_anim เลื่อนตาม = "ท่าเพี้ยน"
				if String(real).to_lower() != "run":
					sprite.speed_scale = 1.0
				# (2) จัดสเกล/ตำแหน่งให้ท่าใหม่ทันที ไม่รอ _process รอบถัดไป
				# ท่าที่ใช้สเกลต่างกัน (ชีท Run ของออร์ควาดใหญ่กว่า Idle 2.2 เท่า) จะได้ไม่มีเฟรม
				# ที่ภาพใหม่ถูกวาดด้วยสเกลของท่าเก่า (ตัวกระพริบใหญ่/เล็กวูบเดียวตอนเปลี่ยนท่า)
				_apply_fit()
			return real
	return ""


## อนิเมชันนี้เล่นครบ 1 รอบใช้เวลากี่วินาที
func _anim_length(anim: String) -> float:
	if anim == "" or sprite.sprite_frames == null:
		return 0.0
	if not sprite.sprite_frames.has_animation(anim):
		return 0.0
	var frames := sprite.sprite_frames.get_frame_count(anim)
	var speed := sprite.sprite_frames.get_animation_speed(anim)
	if frames <= 0 or speed <= 0.0:
		return 0.0
	var total := 0.0
	for i in range(frames):
		total += sprite.sprite_frames.get_frame_duration(anim, i)
	return total / speed


# =========================================================
# ★ สกิลมอนสเตอร์ / สกิลบอส ★
#
# ตั้งค่าทุกอย่างใน MonsterData (.tres) ไม่ต้องแก้โค้ด
# ชื่อท่าใน SpriteFrames เอามาจากช่อง Skill Anim
# ไม่มีท่านั้น -> ถอยไปใช้ "Skill" -> ถอยไป "Attack"
# =========================================================
func _try_skill(distance: float, to_player_x: float) -> bool:
	if not data.has_skill():
		return false
	if state == State.ATTACK or _skill_cd > 0.0:
		return false
	if distance > data.skill_range:
		return false
	if randf() > data.skill_chance:
		# พลาดจังหวะนี้ รออีกนิดค่อยสุ่มใหม่ (ไม่ต้องรอเต็มคูลดาวน์)
		_skill_cd = 1.0
		return false
	velocity.x = 0.0
	_face_to(to_player_x)
	if BossSkillSet.has_set(self):   # ★ รอบ 158 ★ บอสบท 5-7 หมุนเวียน 3 ท่า
		_cast_rotation_skill()
	else:
		_cast_skill()
	return true


# =========================================================
# ★ รอบ 158 ★ บอสสกิล 3 ท่า (ตาราง BossSkillSet) — ท่า 1 = สกิลเดิมใน .tres
# =========================================================
var _rotation_index := 0
var _variant_cache: Dictionary = {}

func _cast_rotation_skill() -> void:
	var slot := _rotation_index % 3
	_rotation_index += 1
	var skill := BossSkillSet.skill_of(data.id, slot)
	if slot == 0 or skill.is_empty():
		_cast_skill()
		return
	if String(skill.get("type", "")) == "variant":
		# ใช้ระบบสกิลเดิมทั้งหมด แค่สลับค่าบางช่องชั่วคราว (ชื่อ/จำนวนสายฟ้า ฯลฯ)
		var base := data
		if not _variant_cache.has(slot):
			var v: MonsterData = data.duplicate()
			var changes: Dictionary = skill.get("set", {})
			for k in changes.keys():
				v.set(StringName(k), changes[k])
			v.skill_name = String(skill.get("name", v.skill_name))
			_variant_cache[slot] = v
		data = _variant_cache[slot]
		await _cast_skill()
		if is_instance_valid(self) and state != State.DEAD:
			data = base
		return
	state = State.ATTACK
	velocity.x = 0.0
	_skill_cd = data.skill_cooldown
	if _play("Skill", true) == "":
		_play("Attack", true)
	if not get_meta("hide_skill_notice", false) and not data.get_meta("hide_skill_notice", false):
		Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - 26 - hover_lift()),
			String(skill.get("name", "")), Color("#ff9a4a"), 22, 0)
	var fx = preload("res://scripts/entities/boss_zone_skill.gd").cast(self, skill, int(_rotation_index / 3.0))
	await fx.finished
	if not is_instance_valid(self) or state == State.DEAD:
		return
	state = State.IDLE
	_attack_timer = maxf(_attack_timer, data.attack_cooldown * 0.5)


func _cast_skill() -> void:
	state = State.ATTACK
	velocity.x = 0.0
	_skill_cd = data.skill_cooldown

	# ท่าสกิล: Skill Anim -> "Skill" -> ท่าโจมตีปกติ
	# ★ restart = true ★ ร่ายซ้ำต้องเริ่มท่าใหม่เสมอ ไม่งั้นค้างเฟรมสุดท้าย (กับดัก 94)
	var played := ""
	if data.skill_anim != &"":
		played = _play(String(data.skill_anim), true)
	if played == "":
		played = _play("Skill", true)
	if played == "":
		played = _play("Attack", true)

	if data.id == &"stone_hrungnir":
		_special_cast_count += 1
		if _special_cast_count % 2 == 1:
			var earthbreak = preload("res://scripts/entities/hrungnir_earthbreak.gd").cast(self)
			await earthbreak.finished
			if state != State.DEAD:
				state = State.IDLE
				_attack_timer = maxf(_attack_timer, data.attack_cooldown * 0.5)
			return
	if data.id == &"gullveig_ember" or (data.id == &"baphomet" and _special_cast_count % 2 == 0):
		var kind := "meteor" if data.id == &"gullveig_ember" and _special_cast_count % 2 == 0 else "flame_jet"
		if data.id == &"baphomet": kind = "scythe"
		_special_cast_count += 1
		var fx = preload("res://scripts/entities/boss_signature_skill.gd").cast(self, kind, facing)
		await fx.finished
		if state != State.DEAD:
			state = State.IDLE
			_attack_timer = maxf(_attack_timer, data.attack_cooldown * 0.5)
		return
	if data.id == &"baphomet": _special_cast_count += 1

	if data.skill_name != "" and not get_meta("hide_skill_notice", false) and not data.get_meta("hide_skill_notice", false):
		Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - 26 - hover_lift()),
			data.skill_name, Color("#ff9a4a"), 22, 0)

	# ★ เอฟเฟกต์สกิล ★ เกิดเป็นโหนดแยกในแมพ เลยใหญ่/ไกลเกินตัวมอนได้
	if data.skill_hand_projectiles:
		await _run_hand_projectiles(played, data.skill_damage_mult, true)
		return
	if data.skill_ground_slam:
		await _run_ground_slam_animation(played, true)
		return

	# ใส่ SpriteFrames ลงช่อง "Skill Effect Frames" ใน MonsterData แล้วมันทำงานเอง
	if data.skill_effect_frames != null:
		SkillEffect.spawn_monster(data, self, facing)

	# ★ สายฟ้าฟาดเป็นแนว (รอบ 64) ★ ตั้ง Skill Bolt Count > 0 ใน MonsterData
	# ตัวมันจัดการเวลา/วงเตือน/ดาเมจของแต่ละเส้นเอง (ไม่ผูกกับ Skill Windup)
	if data.skill_bolt_count > 0:
		LightningStrike.cast(data, self, facing)

	# ★ คลื่นเคียวมืดวิ่งบนพื้น (รอบ 78 · บาฟโฟเมท) ★ ตั้ง Skill Wave Count > 0
	# ตัวมันปล่อยทีละลูก/ไล่พื้น/คิดดาเมจเอง (กระโดดข้ามหรือพุ่งหลบทะลุได้)
	if data.skill_wave_count > 0:
		DarkWave.cast(data, self, facing)

	await get_tree().create_timer(data.skill_windup).timeout
	if state == State.DEAD or not is_instance_valid(self):
		return

	# ★ สกิลขว้างบอลโค้ง (รอบ 36) ★ บอลไปตกที่ตำแหน่งผู้เล่นแล้วระเบิดเอง — ดาเมจคิดตอนระเบิด
	if data.skill_projectile_texture != null:
		var target: Vector2 = foot_position() + Vector2(facing * 300.0, 0)
		if _player != null and is_instance_valid(_player):
			target = _player.foot_position() if _player.has_method("foot_position") else _player.global_position
		MonsterProjectile.fire_lob(data, self, target)
	elif data.skill_bolt_count <= 0 and data.skill_wave_count <= 0:
		# ★ สายฟ้า/คลื่นคิดดาเมจเองทีละลูกแล้ว ★ ไม่ต้องทำดาเมจรอบตัวซ้ำอีก
		_skill_hit()

	await get_tree().create_timer(maxf(0.05, data.skill_duration - data.skill_windup)).timeout
	if state == State.DEAD or not is_instance_valid(self):
		return
	state = State.IDLE
	_attack_timer = maxf(_attack_timer, data.attack_cooldown * 0.5)


## จังหวะที่สกิลระเบิดจริง
func _skill_hit() -> void:
	if _player == null or not is_instance_valid(_player) or PlayerState.is_dead():
		return
	var pf: Vector2 = _player.foot_position() if _player.has_method("foot_position") \
		else _player.global_position
	var diff: Vector2 = pf - foot_position()
	if absf(diff.x) > data.skill_radius_x or absf(diff.y) > data.skill_radius_y:
		Events.floating_text(_player.global_position + Vector2(0, -40), "หลบได้!",
			Color("#cccccc"), 20, 3)
		return

	var result := Combat.monster_skill_hits_player(data, PlayerState.stats, data.skill_damage_mult)
	if result.miss: return
	var damage: int = result.damage
	if _player.has_method("take_damage"):
		var dir := signi(int(pf.x - global_position.x))
		_player.take_damage(damage, data.skill_knockback, dir)


# =========================================================
# โจมตี
# =========================================================
func _try_attack() -> void:
	if state == State.ATTACK:
		return
	if _attack_timer > 0.0:
		# ★ รอบ 66 ★ ยืนรอคูลดาวน์ = กลับไปท่ายืน
		# (ไม่งั้นค้างเฟรมสุดท้ายของท่าโจมตี — เห็นชัดมากกับมอนยิงไกลที่ยืนอยู่กับที่)
		_play("Idle")
		return
	_attack()


func _attack() -> void:
	state = State.ATTACK
	velocity.x = 0.0
	var played := _play("Attack", true)   # ★ ตีซ้ำต้องเริ่มท่าใหม่ทุกครั้ง (กับดัก 94)
	if data.attack_ground_slam:
		await _run_ground_slam_animation(played, false)
		return
	if data.is_ranged() and not data.projectile_hand_positions.is_empty():
		await _run_hand_projectiles(played)
		return

	# ★ รอบ 66/69 — จับจังหวะตามภาพ ★ ตั้ง Attack Hit Frames ไว้ = คิดเวลาจากเฟรมจริง
	# (เปลี่ยน fps ของท่าเมื่อไหร่ ดาเมจก็ยังออกตรงจังหวะเดิม ไม่ต้องแก้ Windup)
	# ★ ใส่ได้หลายเฟรม = ตีหลายทีในท่าเดียว ★ (เช่น อสูรสายฟ้าตะปบ 2 ที)
	var times: Array[float] = []
	if played != "":
		for f in data.attack_hit_frame_list():
			times.append(_anim_time_to_frame(played, f))
	if times.is_empty():
		times.append(data.attack_windup)

	var elapsed := 0.0
	for t in times:
		var wait: float = maxf(0.0, t - elapsed)
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
		if state == State.DEAD or not is_instance_valid(self):
			return
		elapsed = maxf(elapsed, t)
		_attack_hit(times.size())

	# ★ หางท่า ★ เปิด Attack Follow Anim = รอจนภาพเล่นจบจริง (ท่ายาว ๆ จะได้ไม่ถูกตัดกลางคัน)
	var tail: float = data.attack_duration
	if data.attack_follow_anim and played != "":
		tail = _anim_length(played) - elapsed
	await get_tree().create_timer(maxf(0.05, tail)).timeout
	if state == State.DEAD or not is_instance_valid(self):
		return
	state = State.IDLE
	_attack_timer = data.attack_cooldown


## จับเฟรมจริง จึงไม่เลื่อนจังหวะเมื่อเปลี่ยน FPS หรือ duration ของ SpriteFrames
func _run_ground_slam_animation(anim: String, skill: bool) -> void:
	var frames: Array[int] = []
	if skill:
		for frame in data.skill_hit_frames:
			if frame >= 0 and not frames.has(frame):
				frames.append(frame)
	else:
		frames = data.attack_hit_frame_list()
	frames.sort()
	if anim != "" and sprite.sprite_frames.has_animation(anim):
		var count := sprite.sprite_frames.get_frame_count(anim)
		var hit_index := 0
		for frame in frames:
			if frame >= count:
				continue
			while state == State.ATTACK and sprite.animation == StringName(anim) and sprite.frame < frame:
				# ★ รอบ 109 ★ มอนถูกลบ/เปลี่ยนแมพระหว่างรอเฟรม → get_tree() เป็น null (error 'physics_frame' on null instance)
				if not is_inside_tree(): return
				await get_tree().physics_frame
			if not is_inside_tree() or state != State.ATTACK or sprite.animation != StringName(anim):
				return
			_apply_fit()
			_ground_slam_hit(skill, hit_index)
			hit_index += 1
		while state == State.ATTACK and sprite.animation == StringName(anim) and sprite.is_playing():
			if not is_inside_tree(): return
			await get_tree().physics_frame
	if not is_inside_tree() or state != State.ATTACK:
		return
	state = State.IDLE
	_attack_timer = data.attack_cooldown * (0.5 if skill else 1.0)


func _ground_slam_origin() -> Vector2:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var point := data.ground_slam_anchor - texture.get_size() * 0.5
	if sprite.flip_h:
		point.x = -point.x
	point += sprite.offset
	var at := sprite.to_global(point)
	var foot_y := foot_position().y
	var query := PhysicsRayQueryParameters2D.create(Vector2(at.x, foot_y - 70), Vector2(at.x, foot_y + 90), 1)
	query.exclude = [get_rid()]
	var ground := get_world_2d().direct_space_state.intersect_ray(query)
	at.y = ground.position.y if not ground.is_empty() else foot_y
	return at


func _play_ground_slam_sound(at: Vector2, skill: bool) -> void:
	var key := data.skill_slam_sfx if skill else data.attack_slam_sfx
	if key.is_empty() or Game.sfx == null:
		return
	var gain := 0.70 if skill else 0.85
	if is_instance_valid(_player):
		# Nearby impacts stay solid; distant monsters fade out.
		gain *= 1.0 - smoothstep(450.0, 1400.0, at.distance_to(_player.global_position))
	if gain > 0.001:
		Game.sfx.play(key, gain, 0.035)


func _ground_slam_hit(skill: bool, hit_index: int) -> void:
	var at := _ground_slam_origin()
	var radius := data.skill_slam_radius if skill else data.attack_slam_radius
	LAVA_SLAM_FX.spawn(get_parent(), at, radius, skill, hit_index)
	_play_ground_slam_sound(at, skill)
	ground_slam_impact.emit(at, radius, skill, hit_index)
	if not is_instance_valid(_player) or PlayerState.is_dead():
		return
	var pf: Vector2 = _player.foot_position() if _player.has_method("foot_position") else _player.global_position
	if absf(pf.x - at.x) > radius or absf(pf.y - at.y) > data.slam_height:
		return
	var result := Combat.monster_skill_hits_player(data, PlayerState.stats, data.skill_damage_mult) if skill else Combat.monster_hits_player(data, PlayerState.stats)
	if result.miss:
		Events.floating_text(_player.global_position + Vector2(0, -40), "MISS", Color("#cccccc"), 20, 3)
		return
	var mult := 1.0
	var force := data.skill_knockback if skill else data.knockback_force
	if _player.has_method("take_damage"):
		_player.take_damage(maxi(1, int(round(result.damage * mult))), force, signi(int(pf.x - at.x)))


## ★ ดาเมจ 1 ที ของท่าโจมตีปกติ ★ (ท่าที่ตีหลายทีจะเรียกซ้ำตามจำนวนเฟรมที่ตั้งไว้)
## hits = ตีทั้งหมดกี่ทีในท่านี้ — ตี 1 ทีจะไม่โดนตัวคูณ "ต่อที" เลย (ของเดิมไม่เปลี่ยน)
func _attack_hit(hits: int = 1, release_frame: int = -1, cast_mult: float = 1.0, skill_cast: bool = false) -> void:
	var mult: float = 1.0
	if hits > 1 and data.attack_hit_damage_mult > 0.0:
		mult = data.attack_hit_damage_mult

	# ★ รอบ 178 ★ เลเซอร์จากมือ (ราชินีหนาม) — พุ่งเร็ว ยาวไกล
	if data.attack_laser:
		_fire_laser(release_frame, mult * cast_mult)
		return

	# ★ โจมตีระยะไกล (รอบ 36) ★ ใส่รูปกระสุนไว้ = ยิงบอลแทนตีติดตัว
	if data.projectile_texture != null:
		if data.projectile_aim_at_player and is_instance_valid(_player):
			_face_to(_player.global_position.x - global_position.x)
		var aim := Vector2.INF
		if data.projectile_aim_at_player and is_instance_valid(_player):
			aim = _player.body_rect().get_center() if _player.has_method("body_rect") else _player.global_position
		var shot := MonsterProjectile.fire_straight(data, self, facing, projectile_origin(release_frame),aim)
		if shot != null:
			shot.damage_mult = mult * cast_mult
			shot.is_skill = skill_cast
			projectile_released.emit(shot,release_frame)
		return

	if _player == null or not is_instance_valid(_player) or PlayerState.is_dead():
		return
	var pf: Vector2 = _player.foot_position() if _player.has_method("foot_position") \
		else _player.global_position
	var dist := foot_position().distance_to(pf)
	if dist > melee_reach() + 25.0:
		return
	var result := Combat.monster_hits_player(data, PlayerState.stats)
	if result.miss:
		Events.floating_text(_player.global_position + Vector2(0, -40), "MISS", Color("#cccccc"), 20, 3)
		return
	if not _player.has_method("take_damage"):
		return
	var dir := signi(int(_player.global_position.x - global_position.x))
	_player.take_damage(maxi(1, int(round(result.damage * mult))), data.knockback_force, dir)


## ★ รอบ 178 ★ ยิงเลเซอร์จากมือ — เล็งหาตัวผู้เล่น (เอียงได้ไม่เกิน Laser Max Angle) ถ้าผู้เล่นอยู่ด้านหน้า
func _fire_laser(release_frame: int, mult: float) -> MonsterLaserFX:
	var from := projectile_origin(release_frame)
	var aim := Vector2(float(facing), 0.0)
	if is_instance_valid(_player) and not PlayerState.is_dead():
		var col := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var tp: Vector2 = (col.global_transform * col.shape.get_rect()).get_center() \
			if col != null and col.shape != null else _player.global_position
		if (tp.x - from.x) * float(facing) > 0.0:
			var lim := deg_to_rad(data.laser_max_angle)
			var ang := clampf(atan2(tp.y - from.y, absf(tp.x - from.x)), -lim, lim)
			aim = Vector2(cos(ang) * float(facing), sin(ang))
	var fx := MonsterLaserFX.fire(self, from, aim, _player, mult)
	if not data.laser_sfx.is_empty() and Game.sfx != null:
		var gain := 0.6
		if is_instance_valid(_player):
			gain *= 1.0 - smoothstep(700.0, 1600.0, from.distance_to(_player.global_position))
		if gain > 0.001:
			Game.sfx.play(data.laser_sfx, gain, 0.05)
	return fx


func projectile_origin(release_frame: int = -1) -> Vector2:
	var frame := sprite.frame if release_frame < 0 else release_frame
	if data.projectile_hand_positions.has(frame):
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		var point: Vector2 = data.projectile_hand_positions[frame] - texture.get_size()*.5
		if sprite.flip_h: point.x = -point.x
		return sprite.to_global(point+sprite.offset)
	return foot_position()+Vector2(data.projectile_offset.x*facing,data.projectile_offset.y)


func _hand_cast_active(played: String) -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(sprite) \
		and state == State.ATTACK and sprite.animation == StringName(played)


func _run_hand_projectiles(played: String, cast_mult: float = 1.0, skill_cast: bool = false) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(sprite): return
	var cast_tree := get_tree()
	# SceneTree can outlive this monster during map replacement. Cancel the
	# suspended cast even if the same node is later attached to another map.
	var cancelled := [false]
	var cancel_cast := func(): cancelled[0] = true
	tree_exiting.connect(cancel_cast, CONNECT_ONE_SHOT)
	await _continue_hand_projectiles(played,cast_mult,skill_cast,cast_tree,cancelled)
	if tree_exiting.is_connected(cancel_cast): tree_exiting.disconnect(cancel_cast)


func _continue_hand_projectiles(played: String, cast_mult: float, skill_cast: bool, cast_tree: SceneTree, cancelled: Array) -> void:
	var frames := data.attack_hit_frame_list()
	frames.sort()
	if played == "" or not sprite.sprite_frames.has_animation(played):
		state = State.IDLE
		return
	for frame in frames:
		if frame >= sprite.sprite_frames.get_frame_count(played): continue
		while not cancelled[0] and _hand_cast_active(played) and sprite.frame < frame:
			await cast_tree.process_frame
		if cancelled[0] or not _hand_cast_active(played): return
		if data.projectile_aim_at_player and is_instance_valid(_player): _face_to(_player.global_position.x-global_position.x)
		_apply_fit()
		_attack_hit(frames.size(),frame,cast_mult,skill_cast)
	while not cancelled[0] and _hand_cast_active(played) and sprite.is_playing():
		await cast_tree.process_frame
	if not cancelled[0] and _hand_cast_active(played):
		state = State.IDLE
		_attack_timer = data.attack_cooldown


## ★ รอบ 66 ★ ท่านี้เล่นถึงเฟรมที่ idx ใช้เวลากี่วินาที (คิดจาก duration ของแต่ละเฟรม / fps)
func _anim_time_to_frame(anim: String, idx: int) -> float:
	if anim == "" or sprite.sprite_frames == null:
		return 0.0
	if not sprite.sprite_frames.has_animation(anim):
		return 0.0
	var fps: float = sprite.sprite_frames.get_animation_speed(anim)
	if fps <= 0.0:
		return 0.0
	var n: int = sprite.sprite_frames.get_frame_count(anim)
	var last: int = clampi(idx, 0, maxi(0, n - 1))
	var t := 0.0
	for i in range(last):
		t += sprite.sprite_frames.get_frame_duration(anim, i) / fps
	return t


# =========================================================
# รับดาเมจจากผู้เล่น
# =========================================================
func take_damage_from_player(skill_mult: float = 1.0, use_matk: bool = false, from_dir: int = 0,
		wound_bonus: float = 0.0, wound_duration: float = 0.0, source: StringName = &"") -> void:
	if get_meta("encounter_locked", false): return
	if state == State.DEAD:
		return

	var physical_bonus := 1.0 + _wound_bonus if _wound_time > 0.0 and not use_matk else 1.0
	if source == &"":
		var player := get_tree().get_first_node_in_group("player")
		if player != null: source = player.get("_rb_attack_tag")
	var heavy := source in [&"anvil_cleave", &"faultline", &"worldcleaver", &"erasing_cut"]
	var mastery := PlayerState.skills.level_of(&"tempered_might") if heavy else 0
	# ★ รอบ 105 ★ Ninth Edge — คมที่มีชื่อ (มองข้าม DEF) · ท่ายืนทลายกำแพง (DEF ≥ 100) · อักขระที่เก้า (วงคริ 100%)
	var ignore_def := mastery * 0.05 + PlayerState.skills.level_of(&"named_edge") * 0.04
	var can_crit := not heavy and source not in [&"rune_echo", &"twin_echo", &"ninth_inscription"]
	# ★ รอบ 181 ★ อ่านรอยพันธะรวมเข้าคมยืนยันนาม (ใช้ระดับที่สูงกว่า ไม่ทบกัน)
	var wb := maxi(PlayerState.skills.level_of(&"wallbreaker_stance"), PlayerState.skills.level_of(&"named_edge"))
	if wb > 0:
		physical_bonus *= 1.0 + minf(0.04 * wb, maxf(0.0, data.def) * 0.0002 * wb)
	# ★ รอบ 105 ★ ดาบนาม (บท 6): ดาเมจ +1% ต่อ «ชื่อที่ทิ้งไว้» ในกระเป๋า สูงสุด +20%
	var wpn = PlayerState.equipment.weapon() if PlayerState.equipment != null else null
	if GameData.get_skill(source) != null:
		physical_bonus *= 1.0 + PlayerState.stats.skill_damage_percent / 100.0
	if wpn != null and wpn.item_id == &"name_blade" and PlayerState.inventory != null:
		physical_bonus *= 1.0 + 0.01 * mini(20, PlayerState.inventory.count_of(&"left_name"))
	var rb_node = get_tree().get_first_node_in_group("player")
	rb_node = rb_node.get("runeblade") if rb_node != null else null
	if rb_node != null and rb_node.has_method("named_multiplier"):
		physical_bonus *= rb_node.named_multiplier(self, source)
	if rb_node != null and rb_node.has_method("inscription_covers") and rb_node.inscription_covers(global_position):
		ignore_def += 0.25
		can_crit = not heavy and source not in [&"rune_echo", &"twin_echo", &"ninth_inscription"]
	var element := 0
	if wpn != null and wpn.data() != null: element = wpn.data().attack_element
	var result := Combat.player_hits_monster(PlayerState.stats, data, skill_mult * physical_bonus * (1.0 + mastery*0.04), use_matk, element, can_crit, minf(1.0, ignore_def))

	# ★ โหมด GM ตีทีเดียวตาย (รอบ 80) ★ ตีปุ๊บตายปั๊บ ไม่พลาด ไม่สนธาตุ/เกราะ
	# ใช้ไล่เก็บดรอป/ดูท่าตาย/เทสต์เควสฆ่ามอนเร็ว ๆ — เปิดจากหน้าต่าง GM (F10) เท่านั้น
	if OS.is_debug_build() and PlayerState.gm_one_hit:
		take_damage(maxi(1, hp), true, from_dir)
		return

	if result.miss:
		Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y - hover_lift()), "MISS", Color("#cccccc"), 20, 3)
		_set_aggro()
		return

	var final_damage := maxi(1, int(result.damage))
	if not gold_marks.is_empty() or get_tree().has_group(&"gold_warden"):   # ★ รอบ 182 ★ ตราทอง
		final_damage = _gold_mark_damage(final_damage, source, bool(result.crit))
	var dealt := mini(hp, final_damage)
	take_damage(final_damage, bool(result.crit), from_dir)
	_drain_to_player(dealt)
	if source not in [&"rune_echo", &"twin_echo", &"element_burn", &"element_chain"]:
		_apply_weapon_element(element, dealt, from_dir)
	Events.runic_hit.emit(self, source, bool(result.crit))
	if int(result.damage) > 0 and wound_bonus > 0.0:
		apply_wound(wound_bonus, wound_duration)


func take_skill_damage(mult: float, magical: bool, direction: int, source: StringName,
		wound: float = 0.0, duration: float = 0.0) -> void:
	take_damage_from_player(mult, magical, direction, wound, duration, source)


func apply_wound(bonus: float, duration: float) -> void:
	if state == State.DEAD or duration <= 0.0:
		return
	_wound_bonus = maxf(_wound_bonus if _wound_time > 0 else 0.0, clampf(bonus, 0.0, 1.0))
	_wound_time = maxf(_wound_time, duration)
	if _wound_label == null:
		_wound_label = UITheme.make_label("", 13, Color("#ffc56b"))
		_wound_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_wound_label)
	_wound_label.text = "เปิดแผล +%.0f%%" % (_wound_bonus * 100.0)
	_wound_label.position = Vector2(-42, data.hp_bar_offset_y - hover_lift() - 22)
	_wound_label.show()


func _tick_wound(delta: float) -> void:
	_wound_time = maxf(0.0, _wound_time - delta)
	if _wound_time <= 0.0 or state == State.DEAD:
		_wound_bonus = 0.0
		if _wound_label != null:
			_wound_label.hide()


var _burn_left := 0.0
var _burn_tick := 0.0
var _burn_damage := 0
var _burn_label: Label

func _apply_weapon_element(element: int, dealt: int, direction: int) -> void:
	if dealt <= 0: return
	var caster := get_tree().get_first_node_in_group("player")
	if caster == null: return
	if element == 1 and state != State.DEAD:
		if _burn_left <= 0.0: _burn_tick = 1.0
		_burn_left = 3.05
		# A heavy cast cannot snapshot thousands of damage into a minor status effect.
		_burn_damage = maxi(1, int(minf(dealt * 0.2, PlayerState.stats.atk * 0.2)))
		if _burn_label == null:
			_burn_label = UITheme.make_label("เผาไหม้", 13, Color("#ff9457"))
			add_child(_burn_label)
		_burn_label.position = Vector2(-30, data.hp_bar_offset_y - hover_lift() - 40)
		_burn_label.show()
	elif element == 4:
		var now := Time.get_ticks_msec()
		if now < int(caster.get_meta("lightning_ready_ms", 0)) or randf() >= 0.25: return
		var targets := get_tree().get_nodes_in_group("enemy")
		targets.sort_custom(func(a,b): return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
		var count := 0
		for enemy in targets:
			if enemy == self or not enemy.has_method("take_damage") or enemy.is_dead(): continue
			if global_position.distance_to(enemy.global_position) > 280.0: continue
			var ray := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
			if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
			caster.set_meta("lightning_ready_ms", now + 600)
			var line := Line2D.new()
			line.width = 4.0
			line.default_color = Color("#90e9ff")
			line.z_index = 65
			get_parent().add_child(line)
			line.add_point(line.to_local(global_position))
			line.add_point(line.to_local((global_position + enemy.global_position) * 0.5 + Vector2(0,-35)))
			line.add_point(line.to_local(enemy.global_position))
			var tween := line.create_tween()
			tween.tween_property(line, "modulate:a", 0.0, 0.18)
			tween.tween_callback(line.queue_free)
			# Direct secondary damage deliberately bypasses drains, echoes, runes and further procs.
			enemy.take_damage(maxi(1, int(minf(dealt * 0.3, PlayerState.stats.atk * 0.6))), false, direction)
			count += 1
			if count >= 2: break

func _tick_burn(delta: float) -> void:
	if _burn_left <= 0.0: return
	if state == State.DEAD:
		_burn_left = 0.0
	else:
		var active_delta := minf(delta, _burn_left)
		_burn_left = maxf(0.0, _burn_left - delta)
		_burn_tick -= active_delta
		if _burn_tick <= 0.0:
			_burn_tick += 1.0
			take_damage(_burn_damage)
	if _burn_left <= 0.0 and _burn_label != null: _burn_label.hide()


## ★ รอบ 45 — ดูดเลือด/ดูดมานา ★ ได้คืน = % ของดาเมจที่ทำได้ (ตัวเลขลอยสีเขียว/ฟ้าเล็ก ๆ)
func _drain_to_player(damage: int) -> void:
	if damage <= 0:
		return
	var st := PlayerState.stats
	if st == null:
		return
	PlayerState.apply_hp_drain(damage)
	PlayerState.apply_sp_drain(damage)   # ★ รอบ 121 ★ โชว์ "+N SP" ที่ตัวละคร


## ทำดาเมจตรง ๆ (ใช้กับกับดัก/สกิลพิเศษ)
func take_damage(amount: int, is_crit: bool = false, from_dir: int = 0) -> void:
	if get_meta("encounter_locked", false): return
	if state == State.DEAD:
		return

	hp = maxi(0, hp - amount)
	_set_aggro()
	if is_crit and amount > 0:
		# Painted silver critical sparkle plus the existing crack overlay.
		if CRIT_GOLD_BURST:
			preload("res://scripts/entities/critical_burst_fx.gd").spawn(self)
		preload("res://scripts/entities/crack_overlay_fx.gd").spawn(self)
		# คริที่กินเลือดมากพอ → ภาพช้าลงแป๊บนึง (ไม่ทำทุกคริ จะเวียนหัว)
		if data != null and data.max_hp > 0 and float(amount) >= float(data.max_hp) * CRIT_SLOWMO_HP_FRACTION \
				and data.level >= PlayerState.stats.level - CRIT_SLOWMO_LEVEL_GAP:
			preload("res://scripts/entities/crack_overlay_fx.gd").slow_mo(CRIT_SLOWMO_SCALE, CRIT_SLOWMO_TIME, CRIT_SLOWMO_COOLDOWN)

	# ★ ตัวเลขดาเมจ — ใหญ่และหนา ★ คริติคอลใหญ่กว่าอีก
	var text := str(amount) + ("!" if is_crit else "")
	Events.floating_text(
		global_position + Vector2(randf_range(-6, 6), data.hp_bar_offset_y - hover_lift()),
		text,
		Combat.damage_color(is_crit, false),
		DAMAGE_FONT_CRIT if is_crit else DAMAGE_FONT_SIZE,
		1
	)
	Events.damage_dealt.emit(self, amount, is_crit)

	_update_hp_bar()
	sprite.modulate = Color(1, 0.45, 0.45)
	_hurt_flash = 0.12

	# กระเด็นเล็กน้อย
	if from_dir != 0:
		velocity.x = from_dir * 60.0

	if hp <= 0:
		_die()
	elif state != State.ATTACK:
		_play("Hit", true)   # ★ โดนตีรัว ๆ ต้องสะดุ้งใหม่ทุกครั้ง (กับดัก 94)


## ป้าย MVP เด้งเหนือหัวผู้เล่นตอนล้มบอส
func _show_mvp() -> void:
	var title: String = data.boss_title if data.boss_title != "" else "MVP"
	var p := get_tree().get_first_node_in_group("player")
	var at: Vector2 = p.global_position + Vector2(0, -110) if p != null \
		else global_position + Vector2(0, -120)
	Events.floating_text(at, title, Color("#ffd44a"), 52, 6)
	Events.say("%s!  ล้ม %s ได้แล้ว" % [title, data.display_name])
	Events.boss_killed.emit(data.id, data.display_name)


func _set_aggro() -> void:
	_aggro = true
	_aggro_timer = AGGRO_MEMORY
	# ★ รอบ 44 — ล็อกเป้าถาวร (จนกว่าผู้เล่นตาย/มอนตาย) ★ ตัวนิ่ง (STATIONARY) ไม่ไล่อยู่แล้ว
	if data != null and data.ai_type != MonsterData.AIType.STATIONARY:
		_aggro_locked = true


## ล็อกเป้าอยู่ไหม (ไว้ให้เทสต์/ระบบอื่นดู)
func is_aggro_locked() -> bool:
	return _aggro_locked


func is_dead() -> bool:
	return state == State.DEAD


# =========================================================
# ตาย + ดรอปของ
# =========================================================
func _die() -> void:
	# ★ รอบ 105 ★ ตายแล้วพูด (มินิบอส/บอสบท 4-6)
	if data != null and not data.death_lines.is_empty():
		_say_line(data.death_lines[randi() % data.death_lines.size()], Color("#ffd8a8"))

	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	collision.set_deferred("disabled", true)
	sprite.modulate = Color.WHITE
	if _hp_bar != null:
		_hp_bar.hide()

	# ★ รอบ 56 — บอส/มอนที่ตั้ง Respawn Persistent: จำเวลาตายไว้ในเซฟ ★
	# ออกแมพแล้วเข้าใหม่ก็ยังต้องรอจนครบ (กันวนออก-เข้าเพื่อฟาร์มบอสรัว ๆ)
	if data.uses_persistent_respawn():
		PlayerState.lock_respawn(data.id, data.persistent_respawn_seconds())

	# --- รางวัล ---
	var rewards := data.experience_for(PlayerState.stats.level)
	var job_exp: int = rewards.job
	PlayerState.gain_exp(rewards.base, job_exp)
	var zeny := data.roll_zeny()
	if zeny > 0:
		PlayerState.add_zeny(zeny)

	# ★ EXP กับ Job EXP อยู่บรรทัดเดียวกัน และลอยแยกทางกับตัวเลขดาเมจ ★
	if not get_meta(&"split_child", false):   # ★ รอบ 182 ★ ร่างที่แตกจากตราทองไม่นับเควส/ไม่มีรางวัล
		Events.floating_text(global_position + Vector2(0, data.hp_bar_offset_y + sprite.position.y),
			"+%d EXP   +%d JOB" % [rewards.base, job_exp], Color("#8ad6ff"), 18, 4)
		Events.monster_killed.emit(data.id, data.level)

	# ★ ล้มบอส = ป้าย MVP เหนือหัวผู้เล่น + ตั้งธงเนื้อเรื่อง killed_<id> (รอบ 38) ★
	# ธงนี้ใช้ปลดล็อก LoreObject / เควส เช่น killed_forge_guardian เปิดแบบร่างค้อน
	if data.is_boss:
		_show_mvp()
		PlayerState.set_flag(StringName("killed_" + String(data.id)))

	_spawn_drops()
	if &"split" in gold_marks:   # ★ รอบ 182 ★
		_gold_split()
	died.emit(self, data)

	# ★ ท่าตาย ★
	# ชื่อท่าตั้งเป็น Death / Die / Dead ก็ได้ (พิมพ์เล็ก-ใหญ่ไม่สำคัญ)
	var played := _play("Death", true)   # ★ เริ่มท่าตายที่เฟรม 0 เสมอ (กับดัก 94)
	if played != "":
		sprite.frame = 0
		sprite.play(played)   # เริ่มใหม่จากเฟรมแรกเสมอ

	# รอให้ท่าตายเล่นจบจริง ๆ ไม่ใช่ตัดทิ้งที่ 0.6 วินาทีเหมือนเดิม
	var wait: float = data.death_time
	if wait <= 0.0:
		wait = _anim_length(played)
		# หยุดกลางเฟรมสุดท้าย เผื่อท่าตายตั้ง loop ไว้ จะได้ไม่วนกลับไปเฟรมแรก
		var n := sprite.sprite_frames.get_frame_count(played) if played != "" else 0
		if wait > 0.0 and n > 1:
			wait *= 1.0 - 0.5 / float(n)
	if wait <= 0.0:
		wait = 0.6
	wait = clampf(wait, 0.2, 4.0)

	# ค้างท่าสุดท้ายไว้แป๊บหนึ่ง (ถ้าท่าตั้ง loop ไว้ จะได้ไม่วนซ้ำ)
	await get_tree().create_timer(wait).timeout
	if not is_instance_valid(self):
		return
	sprite.pause()

	# ★ รอบ 75 — วิดีโอคัทซีนตอนตาย ★ (เล่นหลังท่าตายเล่นจบ ก่อนกลายเป็นศพ/จางหาย)
	await _play_death_video()
	if not is_instance_valid(self):
		return

	# ★ รอบ 59 — บอส (คูลดาวน์ข้ามแมพ): ค้าง "เฟรมสุดท้ายของท่าตาย" ไว้ + นับถอยหลังเกิดใหม่ ★
	# เช่น คิงโพริงตายเหลือมงกุฎตกอยู่กับพื้น แล้วมีป้ายบอกว่าอีกกี่วินาทีจะเกิด
	if data.uses_persistent_respawn():
		_become_corpse(played)
		return

	# จาง ๆ หายไป
	if data.death_fade > 0.0:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, data.death_fade)
		await tween.finished
	queue_free()


# =========================================================
# ★★ ศพบอส + นับถอยหลังเกิดใหม่ (รอบ 59) ★★
#
# บอสตายแล้วไม่หายไป — ค้างเฟรมสุดท้ายของท่าตายไว้ (คิงโพริง = มงกุฎบนพื้น)
# พร้อมป้าย "เกิดใหม่ใน m:ss" ที่นับจาก PlayerState.respawn_locks (เวลาเดียวกับที่สปอว์นเนอร์ใช้)
# ครบเวลา → ศพจางหาย → สปอว์นเนอร์เกิดตัวใหม่ให้เอง
# เข้าแมพใหม่ตอนบอสยังตาย → สปอว์นเนอร์เรียก spawn_as_corpse() ให้ศพโผล่พร้อมป้ายเหมือนเดิม
# =========================================================
## ป้ายนับถอยหลังอยู่สูงกว่าหลอดเลือดเท่าไหร่
const CORPSE_LABEL_LIFT := 10.0
## ศพจางหายใช้เวลากี่วินาที
const CORPSE_FADE := 0.8

var _is_corpse := false
var _corpse_label: Label


## เข้าโหมดศพ (เรียกหลังท่าตายเล่นจบ) — played = ชื่อท่าตายที่เล่นไป ("" = ไม่มี)
func _become_corpse(played: String) -> void:
	_is_corpse = true
	remove_from_group("enemy")          # ไม่ให้ดาบ/สกิล/AI นับศพเป็นศัตรู
	set_physics_process(false)
	collision.set_deferred("disabled", true)
	if _hp_bar != null:
		_hp_bar.hide()
	sprite.modulate = Color.WHITE
	# ค้างที่เฟรมสุดท้ายของท่าตายเสมอ (กันท่าตั้ง loop หรือ death_time สั้นกว่าท่า)
	if played != "" and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(played):
		var n := sprite.sprite_frames.get_frame_count(played)
		if sprite.animation != played:
			sprite.animation = played
		sprite.frame = maxi(0, n - 1)
	sprite.pause()
	_build_corpse_label()


## ★ ให้สปอว์นเนอร์เรียกตอนเข้าแมพแล้วบอสยังติดคูลดาวน์ ★ — เกิดมาเป็นศพเลย ไม่ให้ของ ไม่ให้ EXP
func spawn_as_corpse() -> void:
	if data == null:
		return
	state = State.DEAD
	hp = 0
	velocity = Vector2.ZERO
	var played := _play("Death", true)   # ★ เริ่มท่าตายที่เฟรม 0 เสมอ (กับดัก 94)
	_become_corpse(played)


func is_corpse() -> bool:
	return _is_corpse


func _build_corpse_label() -> void:
	if _corpse_label != null:
		return
	_corpse_label = Label.new()
	_corpse_label.name = "RespawnLabel"
	_corpse_label.add_theme_font_size_override("font_size", 15)
	_corpse_label.add_theme_color_override("font_color", Color("#ffd54a"))
	_corpse_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_corpse_label.add_theme_constant_override("outline_size", 5)
	_corpse_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_corpse_label.z_index = 100
	add_child(_corpse_label)
	_update_corpse_label()


func _update_corpse_label() -> void:
	if _corpse_label == null:
		return
	var left: float = PlayerState.respawn_remaining(data.id)
	var secs := int(ceilf(left))
	_corpse_label.text = "%s เกิดใหม่ใน %d:%02d" % [data.display_name, secs / 60, secs % 60]
	_corpse_label.reset_size()
	_corpse_label.position = Vector2(-_corpse_label.size.x * 0.5,
		data.hp_bar_offset_y - CORPSE_LABEL_LIFT - _corpse_label.size.y + sprite.position.y)


func _process_corpse(_delta: float) -> void:
	_update_corpse_label()
	if PlayerState.respawn_remaining(data.id) > 0.0:
		return
	# ครบเวลา → จางหาย แล้วสปอว์นเนอร์เกิดตัวใหม่ให้
	_is_corpse = false
	set_process(false)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, CORPSE_FADE)
	if _corpse_label != null:
		tween.parallel().tween_property(_corpse_label, "modulate:a", 0.0, CORPSE_FADE)
	await tween.finished
	if is_instance_valid(self):
		queue_free()


func _spawn_drops() -> void:
	var drops := data.roll_drops()
	if is_champion:   # ★ รอบ 158 ★ แชมเปี้ยนทอยดรอป 2 รอบ
		drops.append_array(data.roll_drops())
	if drops.is_empty():
		return

	var scene: PackedScene = DROPPED_ITEM_SCENE
	if scene == null:
		# ถ้ายังไม่มี scene ให้ใส่เข้ากระเป๋าตรง ๆ กันของหาย
		for inst in drops:
			PlayerState.gain_item(inst)
		return

	var parent := get_parent()
	var i := 0
	var n := drops.size()
	for inst in drops:
		var node := scene.instantiate()
		# ★ รอบ 98 ★ ระเบิดออกเป็นพัดรอบตัวมอน — ชิ้นที่ i กางไปตามลำดับ ไม่กองทับกัน
		if node.has_method("launch"):
			var t: float = 0.5 if n <= 1 else float(i) / float(n - 1)
			node.launch(t, 150.0 if n > 1 else 60.0)
		parent.add_child(node)
		node.global_position = global_position + Vector2(0.0, -20.0)
		if node.has_method("setup"):
			node.setup(inst)
		i += 1


# =========================================================
# หลอดเลือด
# =========================================================
func _create_hp_bar() -> void:
	# ★ รอบ 87 ★ บอสที่ใช้หลอดใหญ่กลางจอ ไม่ต้องมีหลอดเล็กเหนือหัวอีก
	if data != null and data.is_boss and data.use_boss_bar:
		return
	_hp_bar = ProgressBar.new()
	_hp_bar.name = "HPBar"
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = hp
	_hp_bar.show_percentage = false
	_hp_bar.size = Vector2(48, 6)
	_hp_bar.position = Vector2(-24, data.hp_bar_offset_y)
	_hp_bar.z_index = 100

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.06, 0.06, 0.9)
	bg.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.78, 0.22) if is_champion else Color(0.2, 0.85, 0.3)   # ★ รอบ 158 ★ แชมเปี้ยน = หลอดทอง
	fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", fill)

	add_child(_hp_bar)


func _update_hp_bar() -> void:
	if _hp_bar == null:
		return
	_hp_bar.value = hp
	var ratio := float(hp) / maxf(1.0, float(data.max_hp))
	var fill := _hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = Color(0.9, 0.2, 0.2) if ratio < 0.3 else (Color(1.0, 0.78, 0.22) if is_champion else Color(0.2, 0.85, 0.3))


# =========================================================
# ★ วิดีโอเปิดตัวบอส (รอบ 41) ★
# ผู้เล่นเดินเข้าใกล้บอสครั้งแรก (ระยะ Intro Range) = เล่นวิดีโอที่ตั้งไว้ 1 ครั้ง
# จำด้วยธง seen_intro_<id> (เก็บลงเซฟ) — โหลดเซฟ/กลับมาใหม่ไม่เล่นซ้ำ
# =========================================================
var _intro_done := false

func _check_boss_intro() -> void:
	if _intro_done:
		return
	# ★ รอบ 42: ไม่บังคับว่าต้อง is_boss ★ ขอแค่ตั้งช่อง Intro Video ก็ใช้ได้
	# (บาฟโฟเมทไม่ได้ติ๊ก is_boss ไว้ วิดีโอเลยไม่เล่น — เจอตอนตรวจข้อมูลรอบ 42)
	if data == null or data.intro_video == "" or state == State.DEAD:
		_intro_done = true
		return
	var intro_flag := StringName("seen_intro_" + String(data.id))
	if PlayerState.has_flag(intro_flag):
		_intro_done = true
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or PlayerState.is_dead():
		return
	if global_position.distance_to(player.global_position) > data.intro_range:
		return
	_intro_done = true
	PlayerState.set_flag(intro_flag)
	UI.play_video(data.intro_video)


# =========================================================
# ★ วิดีโอคัทซีนตอนตาย (รอบ 75) ★
# เล่นหลังท่าตายเล่นจบ — ผู้เล่นเห็นมอนล้มก่อน แล้วค่อยตัดเข้าคลิป
# (อสูรสายฟ้าตาย → แสงไหลลงดินไปทางเหนือ · คิงโพริงตาย → เศษแก้วในตัว)
# จำด้วยธง seen_death_<id> เก็บลงเซฟ — ฟาร์มบอสซ้ำไม่ต้องดูคลิปทุกรอบ
# =========================================================
func _play_death_video() -> void:
	if data == null or data.death_video == "" or not ResourceLoader.exists(data.death_video):
		return
	var flag := StringName("seen_death_" + String(data.id))
	if data.death_video_once:
		if PlayerState.has_flag(flag):
			return
		PlayerState.set_flag(flag)
	await UI.play_video(data.death_video)
