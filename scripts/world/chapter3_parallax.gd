@tool
extends Node2D
@export var anchor_x: float = 2500.0
@export var floor_y: float = 900.0
@export var open_bridge: bool = false
@export var depth_speed: float = 0.22

func _ready() -> void:
	set_meta("ignore_map_bounds", true)
	process_priority = 100
	if Engine.is_editor_hint(): set_process(false)
	# A physical north gate is distinct from the eastern travel portal.
	if get_parent().get("map_id") == &"vanir_town":
		call_deferred("_dress_city_gates")

func _dress_city_gates() -> void:
	var portal := get_parent().get_node_or_null("Portals/ToFrostPass")
	if portal == null: return
	for child_name in ["AnimatedSprite2D", "Visual", "Warp"]:
		var visual := portal.get_node_or_null(child_name) as CanvasItem
		if visual != null: visual.hide()

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null: return
	var center := to_local(camera.get_screen_center_position())
	var visible_size := get_viewport_rect().size / camera.zoom
	var top := center.y-visible_size.y*0.5-8.0
	var bottom := center.y+visible_size.y*0.5+8.0 if open_bridge else maxf(floor_y-54,top+100)
	var depth := $Depth as Sprite2D
	var fit := (bottom-top)/depth.texture.get_height()
	depth.scale = Vector2.ONE*fit
	depth.position = Vector2(anchor_x+(center.x-anchor_x)*(1-depth_speed),(top+bottom)*0.5)
	var width := (visible_size.x+12000)/fit
	depth.region_rect = Rect2(depth.texture.get_width()*0.5-width*0.5,0,width,depth.texture.get_height())
	var foundation := get_node_or_null("FoundationFill") as Polygon2D
	if foundation != null:
		var end_y := maxf(floor_y+700,center.y+visible_size.y*0.5+32)
		foundation.polygon = PackedVector2Array([Vector2(-6000,floor_y+285),Vector2(12000,floor_y+285),Vector2(12000,end_y),Vector2(-6000,end_y)])
	for child in get_children():
		if child is Sprite2D and child.has_meta("cleared_flag"):
			child.self_modulate = Color(0.55,1.0,0.7) if PlayerState.has_flag(StringName(child.get_meta("cleared_flag"))) else Color.WHITE
