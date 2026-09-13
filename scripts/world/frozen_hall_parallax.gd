@tool
extends Node2D
## Horizontal camera-relative parallax. Anchored to camera center, never to player position.
@export var anchor_x := 2500.0
@export_range(0.0,1.0) var depth_speed := 0.22
@export_range(0.0,1.0) var arch_speed := 0.62
var _depth_base := Vector2.ZERO
var _arch_base := Vector2.ZERO

func _ready() -> void:
	_depth_base = $Depth.position
	_arch_base = $Arches.position
	if Engine.is_editor_hint():
		set_process(false)
		return
	process_priority = 100
	var snow := preload("res://scripts/world/chapter4_snowfall.gd").new()
	snow.amount = 240
	snow.wind = 0.22
	add_child(snow)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var displacement := camera.get_screen_center_position().x-anchor_x
	$Depth.position = _depth_base + Vector2(displacement*(1.0-depth_speed),0)
	$Arches.position = _arch_base + Vector2(displacement*(1.0-arch_speed),0)
	# Fit the far architecture vertically to the real viewport, including camera
	# limits/offset and expanded aspect ratios. Mirrored regions cover both ends
	# without stretching a single picture across the entire map.
	var visible_size := get_viewport_rect().size / camera.zoom
	# Fit the painting above the walkway, not behind the opaque foundation.
	# This reveals its original roof, moon and aurora instead of cropping them.
	var top := camera.get_screen_center_position().y-visible_size.y*0.5-8.0
	var bottom := maxf(806.0,top+100.0)
	var fit: float = (bottom-top)/$Depth.texture.get_height()
	$Depth.scale = Vector2(fit,fit)
	$Depth.position.y = (top+bottom)*0.5
	var region_width := maxf(12000.0, (visible_size.x+12000.0)/fit)
	$Depth.region_rect = Rect2($Depth.texture.get_width()*.5-region_width*0.5,0,region_width,$Depth.texture.get_height())
