## DroppedItem — ไอเทมที่ตกอยู่บนพื้น
##
## โครงสร้าง Scene (res://scenes/items/dropped_item.tscn):
##   DroppedItem (Area2D)  <- ใส่สคริปต์นี้
##   ├── Sprite2D           (ไอคอนไอเทม จะถูกเปลี่ยนอัตโนมัติ)
##   ├── CollisionShape2D   (CircleShape2D รัศมี ~16)
##   └── Label              (ชื่อไอเทม)
extends Area2D

## ★ เก็บอัตโนมัติเมื่อเดินผ่านไหม ★
## ★ รอบ 98 ★ ค่าเริ่มต้น true = เดินผ่านแล้วของ "ลอยเข้าตัว" เอง ไม่ต้องกด F (กด F ยังใช้ได้เหมือนเดิม)
@export var auto_pickup: bool = true
@export var pickup_delay: float = 0.4
@export var lifetime: float = 60.0
## ระยะที่ขึ้นป้าย "กด F" / ระยะเก็บอัตโนมัติ — วัดจาก "ปลายเท้า" ของผู้เล่น
@export var auto_pickup_range_x: float = 70.0
@export var auto_pickup_range_y: float = 80.0
## ★ รอบ 98 ★ ความเร็วที่ของลอยเข้าหาตัวผู้เล่นตอนเก็บ (px/วิ) — ยิ่งมากยิ่งพุ่งไว
@export var magnet_speed: float = 900.0
## ★ รอบ 98 ★ ระเบิดออกจากตัวมอน: ความแรงเริ่มต้น (แนวนอน) และแรงดีดขึ้น
## ตั้งผ่าน launch() จากมอน ถ้าไม่ได้ตั้งจะสุ่มเล็ก ๆ แบบเดิม
@export var burst_speed_min: float = 160.0
@export var burst_speed_max: float = 300.0
@export var burst_up_min: float = 260.0
@export var burst_up_max: float = 420.0

var instance: ItemInstance
var _age := 0.0
var _can_pickup := false
var _collected := false
var _velocity := Vector2.ZERO
var _sprite: Sprite2D
var _base_sprite_y := 0.0
var _ground_y := INF
var _landed := false
var _hint: Label
## ★ รอบ 98 ★ กำลังลอยเข้าหาตัวผู้เล่น (โดนดูดแล้ว) — ไม่ตกพื้นต่อ ไม่หมดอายุ
var _magnet := false
var _launched := false
var _full_notice_cd := 0.0


func _ready() -> void:
	add_to_group("dropped_item")
	monitoring = true
	if not _launched:
		_velocity = Vector2(randf_range(-60, 60), -180)
	_build_hint()
	await get_tree().create_timer(pickup_delay).timeout
	_can_pickup = true


## ★ รอบ 98 ★ ระเบิดออกจากตัวมอน — มอนเรียกก่อน add_child
## angle_t = 0..1 ตำแหน่งของชิ้นนี้ในพัด (ชิ้นแรกซ้ายสุด ชิ้นสุดท้ายขวาสุด) ให้ของกระจายรอบตัวไม่กองกัน
## spread_deg = มุมกางของพัด (180 = กระจายครึ่งวงกลมด้านบนเต็มที่)
func launch(angle_t: float, spread_deg: float = 150.0) -> void:
	_launched = true
	var half := deg_to_rad(spread_deg) * 0.5
	var a := lerpf(-half, half, clampf(angle_t, 0.0, 1.0)) + deg_to_rad(randf_range(-8.0, 8.0))
	var speed := randf_range(burst_speed_min, burst_speed_max)
	# a = 0 คือพุ่งขึ้นตรง ๆ · ซ้าย/ขวาคือกางออก · ชิ้นที่กางมากกว่าได้แรงแนวนอนมากกว่า
	_velocity = Vector2(sin(a) * speed, -randf_range(burst_up_min, burst_up_max) * (0.7 + 0.3 * cos(a)))


## ป้าย "กด F เก็บ" ที่ลอยเหนือไอเทม จะโผล่เฉพาะตอนผู้เล่นเดินเข้ามาใกล้
func _build_hint() -> void:
	_hint = Label.new()
	_hint.name = "PickupHint"
	_hint.text = "กด F เก็บ"
	_hint.visible = false
	_hint.z_index = 20
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(-60, -78)
	_hint.custom_minimum_size = Vector2(120, 0)
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color("#ffe14a"))
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 5)
	add_child(_hint)


func _update_hint() -> void:
	if _hint == null:
		return
	# ★ รอบ 98 ★ เก็บอัตโนมัติอยู่แล้ว ไม่ต้องบอกให้กด F
	if _collected or not _can_pickup or auto_pickup:
		_hint.visible = false
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_hint.visible = false
		return
	var foot: Vector2 = player.foot_position() if player.has_method("foot_position") \
		else player.global_position
	var offset: Vector2 = global_position - foot
	_hint.visible = absf(offset.x) < auto_pickup_range_x and absf(offset.y) < auto_pickup_range_y
	if _hint.visible:
		_hint.position.y = -78 + sin(_age * 5.0) * 3.0


## ยิงเรย์จากจุดปัจจุบันไปยังจุดถัดไป ถ้าเจอพื้นก็หยุดตรงนั้น
## (ต้องเช็คทุกเฟรมระหว่างตก เพราะตอนสร้าง ไอเทมยังไม่ถูกย้ายไปตำแหน่งจริง)
func _ground_between(from: Vector2, to: Vector2) -> Vector2:
	var world := get_world_2d()
	if world == null:
		return Vector2.INF
	var query := PhysicsRayQueryParameters2D.create(from, to + Vector2(0.0, 4.0))
	query.collision_mask = 1
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector2.INF
	return hit.position


func setup(inst: ItemInstance) -> void:
	instance = inst
	_refresh_visual()


func _refresh_visual() -> void:
	if instance == null:
		return
	var d := instance.data()
	if d == null:
		return

	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and d.icon != null:
		spr.texture = d.icon
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# ย่อให้ขนาดพอดีกับพื้น ไม่ว่าไฟล์ภาพจะใหญ่แค่ไหน
		if d.drop_display_size > 0.0:
			var tex_size := d.icon.get_size()
			var longest := maxf(1.0, maxf(tex_size.x, tex_size.y))
			var k := d.drop_display_size / longest
			spr.scale = Vector2(k, k)
			# ให้ "ก้นภาพ" อยู่ที่จุดกำเนิดของไอเทม (ซึ่งจะแตะพื้นพอดี)
			spr.position.y = -tex_size.y * k * 0.5
		_sprite = spr
		_base_sprite_y = spr.position.y

	var label := get_node_or_null("Label") as Label
	if label != null:
		label.text = instance.display_name()
		if instance.count > 1:
			label.text += " x%d" % instance.count
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 13)


func _physics_process(delta: float) -> void:
	# ★ รอบ 98 ★ โดนดูดแล้ว → ลอยเข้าหากลางตัวผู้เล่นแล้วเก็บ
	if _magnet:
		_age += delta
		var player := get_tree().get_first_node_in_group("player")
		if player == null or not is_instance_valid(player):
			_magnet = false
			return
		var target: Vector2 = player.global_position
		var to := target - global_position
		var step := magnet_speed * delta * (1.0 + _age * 0.5)
		if to.length() <= step + 6.0:
			global_position = target
			_finish_collect()
		else:
			global_position += to.normalized() * step
			scale = scale.lerp(Vector2(0.6, 0.6), 6.0 * delta)
		return

	# เด้งขึ้นแล้วตกลง "พื้น" แล้วหยุดนิ่ง
	if not _landed:
		_velocity.y += 900.0 * delta
		_velocity.x = move_toward(_velocity.x, 0.0, 120.0 * delta)
		var next := global_position + _velocity * delta

		if _velocity.y > 0.0:
			var ground := _ground_between(global_position, next)
			if ground != Vector2.INF:
				next = ground
				_velocity = Vector2.ZERO
				_landed = true
				_ground_y = ground.y

		global_position = next

		# กันร่วงหายลงเหวถ้าแมพตรงนั้นไม่มีพื้น
		if not _landed and _age > 2.5:
			_velocity = Vector2.ZERO
			_landed = true

	_age += delta
	if _full_notice_cd > 0.0:
		_full_notice_cd -= delta

	# ลอยขึ้นลงเบา ๆ ให้สังเกตเห็นง่าย
	if _sprite != null and _landed:
		_sprite.position.y = _base_sprite_y + sin(_age * 3.0) * 3.0

	if lifetime > 0.0 and _age > lifetime:
		queue_free()
		return
	if lifetime > 0.0 and _age > lifetime - 5.0:
		modulate.a = 0.4 + 0.6 * absf(sin(_age * 6.0))

	_update_hint()

	# ★ รอบ 98 ★ รอให้ตกถึงพื้นก่อนค่อยดูด (ของที่ระเบิดลอยผ่านหัวไม่โดนดูดกลางอากาศ)
	if auto_pickup and _can_pickup and not _collected and _landed and _full_notice_cd <= 0.0:
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			# ★ เทียบกับ "ปลายเท้า" ผู้เล่น ★
			# จุดกำเนิดของผู้เล่นอยู่กลางลำตัว (สูงจากพื้น ~ครึ่งหนึ่งของกล่องชน)
			# ถ้าวัดจากจุดกำเนิด ของที่ตกอยู่แทบเท้าจะดูห่างเป็นร้อยพิกเซล จนเก็บไม่ได้
			var foot: Vector2 = player.foot_position() if player.has_method("foot_position") \
				else player.global_position
			var offset: Vector2 = global_position - foot
			if absf(offset.x) < auto_pickup_range_x and absf(offset.y) < auto_pickup_range_y:
				collect()


## เก็บไอเทมเข้ากระเป๋า — ★ รอบ 98 ★ ถ้ากระเป๋ามีที่ ของจะ "ลอยเข้าตัว" ก่อนแล้วค่อยเข้ากระเป๋า
func collect() -> void:
	if _collected or instance == null or not _can_pickup or _magnet:
		return
	if not PlayerState.inventory.can_add(instance):
		# บอกครั้งเดียวแล้วพักไว้ ไม่งั้นยืนทับของแล้วข้อความเด้งทุกเฟรม
		Events.say("กระเป๋าเต็ม")
		_full_notice_cd = 2.0
		return
	_magnet = true
	_age = 0.0
	_landed = true
	_velocity = Vector2.ZERO
	if _hint != null:
		_hint.visible = false
	var label := get_node_or_null("Label") as Label
	if label != null:
		label.visible = false
	set_deferred("monitoring", false)


## เข้ากระเป๋าจริง (ถึงตัวผู้เล่นแล้ว) — เดิมคือ collect() ทั้งก้อน
func _finish_collect() -> void:
	_magnet = false
	if _collected or instance == null:
		return

	var leftover := PlayerState.gain_item(instance)
	if leftover >= instance.count:
		Events.say("กระเป๋าเต็ม")
		return

	_collected = true
	var got := instance.count - leftover
	Events.floating_text(
		global_position,
		"%s x%d" % [instance.display_name(), got],
		Color("#9be7ff"),
		18,
		5
	)

	if leftover > 0:
		instance.count = leftover
		_collected = false
		_refresh_visual()
		scale = Vector2.ONE
		var label := get_node_or_null("Label") as Label
		if label != null:
			label.visible = true
		set_deferred("monitoring", true)
		Events.say("กระเป๋าเต็ม เก็บได้ไม่หมด")
		return

	queue_free()
