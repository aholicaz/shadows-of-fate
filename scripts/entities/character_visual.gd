## CharacterVisual — ระบบซ้อนเลเยอร์ตัวละคร (Paper Doll แบบ Ragnarok)
##
## ตัวละครฐาน = ตัวเปล่า (AnimatedSprite2D ปกติ)
## อุปกรณ์ที่สวม = เลเยอร์ AnimatedSprite2D ซ้อนทับ เล่นเฟรมตรงกับตัวเปล่าเป๊ะ ๆ
##
## โครงสร้าง Scene:
##   Player (CharacterBody2D)
##   ├── AnimatedSprite2D   <- ตัวเปล่า (body)
##   ├── EquipVisual        <- ใส่สคริปต์นี้ (Node2D)
##   └── CollisionShape2D
##
## อุปกรณ์แต่ละชิ้นตั้งภาพได้ 2 แบบใน ItemData:
##   A) Equip Sprite Frames — ภาพเคลื่อนไหวครบทุกท่า (แนะนำ เหมือน RO)
##   B) Equip Texture       — ภาพนิ่งใบเดียว ติดกับตัวไปเฉย ๆ (ทำง่าย ใช้ชั่วคราวได้)
class_name CharacterVisual
extends Node2D

const BLADE_HAND_TRACK = preload("res://scripts/entities/blade_hand_track.gd")
const RUNE_HAND_TRACK = preload("res://scripts/entities/runeblade_hand_track.gd")

## ลำดับการวาด (ตัวแรก = อยู่หลังสุด)
const LAYER_ORDER := [
	Equipment.EquipSlot.GARMENT,
	Equipment.EquipSlot.SHOES,
	Equipment.EquipSlot.ARMOR,
	Equipment.EquipSlot.OFFHAND,
	Equipment.EquipSlot.WEAPON,
	Equipment.EquipSlot.HEAD,
]

## ตัวเปล่าที่จะให้เลเยอร์เดินตาม
@export var body_path: NodePath = ^"../AnimatedSprite2D"
## ดึงของที่สวมอยู่จาก PlayerState อัตโนมัติ (ปิดถ้าใช้กับ NPC/ศัตรู)
@export var use_player_equipment: bool = true

## Grip positions in the original Idle PNG canvas (frame_01..05,07..10).
@export var idle_hand_positions := PackedVector2Array([
	Vector2(449, 426), Vector2(447, 425), Vector2(443, 424),
	Vector2(440, 423), Vector2(438, 423), Vector2(441, 424),
	Vector2(444, 425), Vector2(448, 426), Vector2(449, 426)])

var body: AnimatedSprite2D

var _layers: Dictionary = {}      # EquipSlot -> AnimatedSprite2D
var _layer_data: Dictionary = {}  # EquipSlot -> ItemData
var _attack_body: Sprite2D
var _hand_cover: Sprite2D
var _body_replaced := false
var _original_self_modulate := Color.WHITE


func _ready() -> void:
	body = get_node_or_null(body_path) as AnimatedSprite2D
	if body == null:
		push_warning("[CharacterVisual] หา AnimatedSprite2D ของตัวเปล่าไม่เจอที่ %s" % body_path)
		return
	# Idle weapons share the body's depth, but draw before it so the hand covers
	# the grip. Negative depth puts them behind map backgrounds at z = 0.
	if body.get_parent() == get_parent():
		get_parent().move_child.call_deferred(self, body.get_index())

	_build_layers()
	_attack_body = Sprite2D.new()
	_attack_body.name = "BareHandComboBody"
	_attack_body.hide()
	add_child(_attack_body)
	_hand_cover = Sprite2D.new()
	_hand_cover.name = "FingersOverGrip"
	_hand_cover.z_index = 2
	_hand_cover.region_enabled = true
	_hand_cover.hide()
	add_child(_hand_cover)

	if use_player_equipment:
		Events.equipment_changed.connect(refresh_from_player)
		refresh_from_player()


func _build_layers() -> void:
	for i in range(LAYER_ORDER.size()):
		var slot: int = LAYER_ORDER[i]
		var layer := AnimatedSprite2D.new()
		layer.name = "Layer_%s" % Equipment.SLOT_NAMES.get(slot, str(slot))
		layer.centered = body.centered
		layer.flip_v = body.flip_v
		layer.texture_filter = body.texture_filter
		layer.hide()
		# ค่าเริ่มต้น: ผ้าคลุม/รองเท้าอยู่หลัง ที่เหลืออยู่หน้า
		layer.z_index = -1 if slot == Equipment.EquipSlot.GARMENT else i
		add_child(layer)
		_layers[slot] = layer


# =========================================================
# อัพเดตภาพตามของที่สวมอยู่
# =========================================================
func refresh_from_player() -> void:
	if not use_player_equipment or PlayerState.equipment == null:
		return
	for slot in _layers.keys():
		var inst: ItemInstance = PlayerState.equipment.get_item(slot)
		set_layer(slot, inst.data() if inst != null else null)


## ตั้งภาพของเลเยอร์เอง (ใช้กับ NPC / ตัวละครอื่น)
func set_layer(slot: int, item: ItemData) -> void:
	var layer: AnimatedSprite2D = _layers.get(slot)
	if layer == null:
		return

	_layer_data[slot] = item
	if slot == Equipment.EquipSlot.WEAPON:
		_restore_body()

	if item == null:
		layer.sprite_frames = null
		layer.hide()
		return

	if item.equip_sprite_frames != null:
		# --- แบบ A: ภาพเคลื่อนไหวครบทุกท่า ---
		layer.sprite_frames = item.equip_sprite_frames
	elif item.equip_texture != null:
		# --- แบบ B: ภาพนิ่งใบเดียว สร้าง SpriteFrames ให้อัตโนมัติ ---
		var frames := SpriteFrames.new()
		frames.add_frame(&"default", item.equip_texture)
		layer.sprite_frames = frames
	else:
		layer.sprite_frames = null
		layer.hide()
		return

	layer.z_index = item.equip_z_index
	layer.show()


# =========================================================
# ซิงก์เฟรมให้ตรงกับตัวเปล่าทุกเฟรม — หัวใจของระบบ
# =========================================================
func _process(_delta: float) -> void:
	if body == null:
		return

	# เดินตามตำแหน่ง/ขนาดของตัวเปล่า เพื่อให้ภาพซ้อนตรงกันเสมอ
	position = body.position
	scale = body.scale
	rotation = body.rotation
	visible = body.visible
	_restore_body()

	var body_anim := body.animation
	var body_frame := body.frame
	var flipped := body.flip_h

	for slot in _layers.keys():
		var layer: AnimatedSprite2D = _layers[slot]
		if body_anim == &"Idle_Runeblade" and slot != Equipment.EquipSlot.WEAPON:
			layer.hide()
			continue
		layer.modulate = body.modulate
		var frames := layer.sprite_frames
		if frames == null:
			continue
		var socket_item: ItemData = _layer_data.get(slot)
		if socket_item != null and socket_item.equip_follow_idle_hand:
			_sync_idle_hand(layer, socket_item)
			continue
		layer.position = Vector2.ZERO
		layer.scale = Vector2.ONE
		layer.rotation = 0.0
		layer.centered = body.centered
		layer.flip_v = body.flip_v
		layer.texture_filter = body.texture_filter

		# หาอนิเมชันที่ตรงกัน ถ้าอุปกรณ์ชิ้นนี้ไม่มีท่านั้นก็ซ่อนไป
		# (ชื่อท่าไม่สนตัวพิมพ์เล็ก-ใหญ่ เหมือนที่ตัวละคร/มอนใช้)
		var anim := _match_anim(frames, body_anim)
		if anim == &"":
			# SpriteFrames จะมีอนิเมชันชื่อ "default" ติดมาเสมอ ต้องเช็คว่ามีเฟรมจริงด้วย
			if frames.has_animation(&"default") and frames.get_frame_count(&"default") > 0:
				anim = &"default"
			else:
				layer.hide()
				continue

		layer.show()
		if layer.animation != anim:
			layer.animation = anim

		var count := frames.get_frame_count(anim)
		layer.frame = clampi(body_frame, 0, maxi(0, count - 1))
		layer.flip_h = flipped

		# ตำแหน่งเยื้อง: ใช้ของตัวเปล่าเป็นฐาน แล้วบวกค่าเยื้องของอุปกรณ์
		var item: ItemData = _layer_data.get(slot)
		var extra := Vector2.ZERO
		var z: int = layer.z_index
		if item != null:
			extra = item.equip_offset
			z = item.equip_z_index_flipped if (flipped and item.use_flipped_z) else item.equip_z_index
		if flipped:
			extra.x = -extra.x
		layer.offset = body.offset + extra
		layer.z_index = z


## ซ่อน/โชว์เลเยอร์อุปกรณ์ทั้งหมด (เช่น ตอนตัวละครล่องหน)
## หาชื่อท่าในอุปกรณ์ที่ตรงกับท่าของตัวเปล่า (ไม่สนตัวพิมพ์เล็ก-ใหญ่)
## คืน &"" ถ้าไม่มีท่านั้นเลย
func _sync_idle_hand(layer: AnimatedSprite2D, item: ItemData) -> void:
	if _sync_attack_hand(layer, item):
		return
	# Unsupported poses keep their original baked-in equipment.
	var job_idle := body.animation == &"Idle_Runeblade"
	if (String(body.animation).to_lower() != "idle" and not job_idle) or idle_hand_positions.is_empty():
		layer.hide()
		return
	var texture := body.sprite_frames.get_frame_texture(body.animation, body.frame)
	if texture == null:
		layer.hide()
		return
	var hand := idle_hand_positions[clampi(body.frame, 0, idle_hand_positions.size() - 1)]
	var wrist_rotation := 0.0
	if job_idle:
		var poses: Array=RUNE_HAND_TRACK.IDLE
		var current: Vector3=poses[body.frame%poses.size()]
		var next: Vector3=poses[(body.frame+1)%poses.size()]
		var pose := current.lerp(next,body.frame_progress)
		hand=Vector2(pose.x,pose.y)
		wrist_rotation=pose.z
	if body.centered:
		hand -= texture.get_size() * 0.5
	if body.flip_h:
		hand.x = -hand.x
	if body.flip_v:
		hand.y = -hand.y
	var mirror := Vector2(-1.0 if body.flip_h else 1.0,-1.0 if body.flip_v else 1.0)
	layer.position = body.offset + hand + item.equip_offset*mirror
	layer.centered = false
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	layer.offset = -item.equip_grip
	layer.flip_h = false
	layer.flip_v = false
	layer.scale = Vector2(-1.0 if body.flip_h else 1.0, -1.0 if body.flip_v else 1.0) * item.equip_hand_scale
	var angle := deg_to_rad(item.equip_hand_rotation_degrees+wrist_rotation)
	layer.rotation = -angle if body.flip_h != body.flip_v else angle
	layer.z_index = maxi(0, item.equip_z_index)
	layer.show()


func _restore_body() -> void:
	if _body_replaced and is_instance_valid(body):
		body.self_modulate = _original_self_modulate
	_body_replaced = false
	if is_instance_valid(_attack_body):
		_attack_body.hide()
	if is_instance_valid(_hand_cover):
		_hand_cover.hide()


func _exit_tree() -> void:
	_restore_body()


func _sync_attack_hand(layer: AnimatedSprite2D, item: ItemData) -> bool:
	var anim := String(body.animation)
	var frames := item.equip_attack_body_frames
	if frames == null or not BLADE_HAND_TRACK.POSES.has(anim) or not frames.has_animation(anim):
		return false
	var poses: Array = BLADE_HAND_TRACK.POSES[anim]
	if body.frame >= poses.size() or body.frame >= frames.get_frame_count(anim):
		return false
	var texture := frames.get_frame_texture(anim, body.frame)
	if texture == null:
		return false
	var pose: Vector4 = poses[body.frame]
	var grip := Vector2(pose.x, pose.y)
	var hand := grip - texture.get_size() * 0.5 if body.centered else grip
	var mirror := Vector2(-1.0 if body.flip_h else 1.0, -1.0 if body.flip_v else 1.0)
	layer.position = body.offset + hand * mirror + item.equip_offset * mirror
	layer.centered = false
	layer.offset = -item.equip_grip
	layer.flip_h = false
	layer.flip_v = false
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	layer.scale = mirror * item.equip_hand_scale * pose.w
	var angle := deg_to_rad(item.equip_hand_rotation_degrees + pose.z)
	layer.rotation = -angle if body.flip_h != body.flip_v else angle
	layer.z_index = 1
	layer.modulate = body.modulate
	layer.show()
	# Replace only the rendered body. Original animation/fit/hit timing data stay intact.
	_original_self_modulate = body.self_modulate
	_body_replaced = true
	body.self_modulate.a = 0.0
	_attack_body.texture = texture
	_attack_body.centered = body.centered
	_attack_body.offset = body.offset
	_attack_body.flip_h = body.flip_h
	_attack_body.flip_v = body.flip_v
	_attack_body.texture_filter = body.texture_filter
	_attack_body.modulate = body.modulate * _original_self_modulate
	_attack_body.show()
	# Reuse the source hand pixels above the weapon, so the hilt sits inside the fist.
	_hand_cover.texture = texture
	_hand_cover.region_rect = Rect2(grip - Vector2(10, 10), Vector2(20, 20))
	_hand_cover.position = body.offset + hand * mirror
	_hand_cover.flip_h = body.flip_h
	_hand_cover.flip_v = body.flip_v
	_hand_cover.texture_filter = body.texture_filter
	_hand_cover.modulate = _attack_body.modulate
	_hand_cover.show()
	return true


func _match_anim(frames: SpriteFrames, want: StringName) -> StringName:
	if frames.has_animation(want):
		return want
	var lower := String(want).to_lower()
	for a in frames.get_animation_names():
		if String(a).to_lower() == lower:
			return StringName(a)
	return &""


func set_layers_visible(v: bool) -> void:
	for layer: AnimatedSprite2D in _layers.values():
		layer.visible = v and layer.sprite_frames != null
