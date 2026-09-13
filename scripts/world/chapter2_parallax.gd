@tool
extends Node2D
## Depth moves with the camera; walkway, furniture and lamp fixtures stay in world space.
@export var anchor_x: float = 2500.0
@export var floor_y: float = 884.0
@export var depth_speed: float = 0.22
## Open bridge arches need the distant valley behind the entire viewport.
@export var open_bridge: bool = false

func _ready() -> void:
	set_meta("ignore_map_bounds", true)
	process_priority = 100
	if Engine.is_editor_hint():
		set_process(false)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := to_local(camera.get_screen_center_position())
	var visible_size := get_viewport_rect().size / camera.zoom
	var top := center.y - visible_size.y * 0.5 - 8.0
	var bottom := maxf(floor_y - 74.0, top + 100.0)
	if open_bridge:
		bottom = center.y + visible_size.y * 0.5 + 8.0
	var depth := $Depth as Sprite2D
	var fit := (bottom - top) / depth.texture.get_height()
	depth.scale = Vector2.ONE * fit
	depth.position = Vector2(anchor_x + (center.x-anchor_x)*(1.0-depth_speed), (top+bottom)*0.5)
	var width := (visible_size.x + 12000.0) / fit
	depth.region_rect = Rect2(depth.texture.get_width()*0.5-width*0.5, 0, width, depth.texture.get_height())
	# The residential blocks sit between the distant city and the walkable shops.
	for child in get_children():
		if child is Sprite2D and child.has_meta("city_anchor_x"):
			child.position.x = float(child.get_meta("city_anchor_x")) + (center.x-anchor_x)*0.35
	var end_y := maxf(floor_y + 700.0, center.y + visible_size.y*0.5 + 32.0)
	var foundation := get_node_or_null("FoundationFill") as Polygon2D
	if foundation != null:
		foundation.polygon = PackedVector2Array([Vector2(-6000,floor_y+455),Vector2(12000,floor_y+455),Vector2(12000,end_y),Vector2(-6000,end_y)])
