## เงาสัมผัสพื้นแยกจากสไปรต์: ไม่พลิกหรือยืดตามเฟรม animation
class_name FootShadow
extends Sprite2D

@export var ground_size := Vector2(142, 38)
@export_range(0.0, 1.0, 0.05) var shadow_opacity := 0.58
## เลื่อนเข้าแนวทางเดินให้รองทั้งเท้าหน้าและเท้าหลังของภาพมุมเฉียง
@export var floor_offset := Vector2(0, -14)
@export var max_height := 420.0
@export_flags_2d_physics var ground_mask: int = 1

@export var fit_actor_size := false
var _body: Node2D
var _npc_sprite: Node2D
var _npc_bounds := Rect2()
var _npc_texture: Texture2D

static func attach(actor: Node2D) -> void:
	var previous := actor.get_node_or_null("FootShadow")
	if previous is FootShadow: return
	if previous != null:
		# Older maps contain static contact patches. Keep their authored data,
		# but render one shared ground-aware shadow instead of stacking two.
		previous.name = "LegacyFootShadow"
		if previous is CanvasItem: previous.hide()
	var shadow := FootShadow.new()
	shadow.name = "FootShadow"
	shadow.fit_actor_size = true
	shadow.shadow_opacity = .46
	shadow.floor_offset = Vector2(0,-7)
	actor.add_child(shadow)
	actor.move_child(shadow,0)

func _npc_foot() -> Vector2:
	if not is_instance_valid(_npc_sprite):
		for child in _body.get_children():
			if child == self: continue
			if (child is Sprite2D and child.texture != null and child.visible) or (child is AnimatedSprite2D and child.sprite_frames != null and child.visible):
				_npc_sprite = child
				break
	if is_instance_valid(_npc_sprite):
		var tex: Texture2D
		var origin := Vector2.ZERO
		var sp := _npc_sprite as Sprite2D
		if sp != null:
			tex = sp.texture
			origin = sp.get_rect().position
		else:
			var asp := _npc_sprite as AnimatedSprite2D
			if asp.sprite_frames != null and asp.sprite_frames.get_frame_count(asp.animation)>0:
				tex = asp.sprite_frames.get_frame_texture(asp.animation,0)
				origin = asp.offset - (tex.get_size()*.5 if asp.centered else Vector2.ZERO)
		if tex != null:
			if tex != _npc_texture:
				_npc_texture = tex
				var img := SpriteFit._frame_image(tex,{})
				if img != null:
					if img.is_compressed(): img.decompress()
					if sp != null and sp.region_enabled: img = img.get_region(Rect2i(sp.region_rect))
					elif sp != null and (sp.hframes>1 or sp.vframes>1):
						var cell := Vector2i(img.get_size())/Vector2i(sp.hframes,sp.vframes)
						img = img.get_region(Rect2i(Vector2i(sp.frame_coords)*cell,cell))
					_npc_bounds = Rect2(img.get_used_rect())
			if _npc_bounds.has_area():
				ground_size = Vector2(clampf(_npc_bounds.size.x*absf(_npc_sprite.global_scale.x)*.7,45,250),26)
				var point := origin+Vector2(_npc_bounds.get_center().x,_npc_bounds.end.y)
				return _npc_sprite.to_global(point)
	var shape := _body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape != null:
		return shape.to_global(Vector2(0,shape.shape.get_rect().end.y))
	return _body.global_position

func _ready() -> void:
	_body = get_parent() as Node2D
	visible = false
	if _body == null:
		set_physics_process(false)
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
	gradient.colors = PackedColorArray([Color.BLACK, Color(0, 0, 0, 0.8), Color(0, 0, 0, 0.25), Color.TRANSPARENT])
	var soft_disc := GradientTexture2D.new()
	soft_disc.width = 128
	soft_disc.height = 128
	soft_disc.gradient = gradient
	soft_disc.fill = GradientTexture2D.FILL_RADIAL
	soft_disc.fill_from = Vector2(0.5, 0.5)
	soft_disc.fill_to = Vector2(1.0, 0.5)
	texture = soft_disc
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit
	z_index = 0 if fit_actor_size else -1
	show_behind_parent = fit_actor_size
	process_physics_priority = 100 # หลัง CharacterBody2D เคลื่อนที่ รวมท่าพุ่ง/กระเด็น

func _physics_process(_delta: float) -> void:
	var foot: Vector2 = _body.foot_position() if _body.has_method("foot_position") else _npc_foot()
	if fit_actor_size and "data" in _body and _body.data != null:
		var h: float = maxf(60.0,_body.data.display_height)
		ground_size = Vector2(clampf(h*.65,45,360),clampf(h*.13,14,65))
	var exclude: Array[RID] = []
	if _body is CollisionObject2D: exclude.append(_body.get_rid())
	var query := PhysicsRayQueryParameters2D.create(foot - Vector2(0, 70 if fit_actor_size else 12), foot + Vector2(0, max_height), ground_mask, exclude)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y > -0.5:
		visible = false
		return
	var height := maxf(0.0, hit.position.y - foot.y)
	if fit_actor_size and _body.has_method("hover_lift"): height += _body.hover_lift()
	var distance_factor := clampf(height / maxf(1.0, max_height), 0.0, 1.0)
	global_position = hit.position + floor_offset
	global_rotation = 0.0
	global_scale = ground_size / 128.0 * lerpf(1.0, 0.65, distance_factor)
	modulate = Color(1, 1, 1, shadow_opacity * (1.0 - distance_factor))
	visible = modulate.a > 0.01
