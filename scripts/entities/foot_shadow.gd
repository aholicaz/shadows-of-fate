## เงาสัมผัสพื้นแยกจากสไปรต์: ไม่พลิกหรือยืดตามเฟรม animation
class_name FootShadow
extends Sprite2D

@export var ground_size := Vector2(142, 38)
@export_range(0.0, 1.0, 0.05) var shadow_opacity := 0.58
## เลื่อนเข้าแนวทางเดินให้รองทั้งเท้าหน้าและเท้าหลังของภาพมุมเฉียง
@export var floor_offset := Vector2(0, -14)
@export var max_height := 420.0
@export_flags_2d_physics var ground_mask: int = 1

var _body: CharacterBody2D

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	visible = false
	if _body == null or not _body.has_method("foot_position"):
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
	z_index = -1
	process_physics_priority = 100 # หลัง CharacterBody2D เคลื่อนที่ รวมท่าพุ่ง/กระเด็น

func _physics_process(_delta: float) -> void:
	var foot: Vector2 = _body.foot_position()
	var query := PhysicsRayQueryParameters2D.create(foot - Vector2(0, 12), foot + Vector2(0, max_height), ground_mask, [_body.get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y > -0.5:
		visible = false
		return
	var height := maxf(0.0, hit.position.y - foot.y)
	var distance_factor := clampf(height / maxf(1.0, max_height), 0.0, 1.0)
	global_position = hit.position + floor_offset
	global_rotation = 0.0
	global_scale = ground_size / 128.0 * lerpf(1.0, 0.65, distance_factor)
	modulate = Color(1, 1, 1, shadow_opacity * (1.0 - distance_factor))
	visible = modulate.a > 0.01
