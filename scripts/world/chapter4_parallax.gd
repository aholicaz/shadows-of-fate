@tool
extends Node2D
## The entire painting height fits between the visible sky and the rear of the
## walkway. Horizontal repeats reuse the texture, not large stretched copies.
@export var anchor_x: float = 2500.0
@export_range(0.0,1.0) var depth_speed: float = 0.22
@export var ground_back_y: float = 790.0
@export var snow_amount: int = 90
@export var wind: float = 0.4
@export var rising_motes: bool = false
@export var particle_color: Color = Color(.75,.88,1,.48)

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	process_priority = 100
	var snowfall := preload("res://scripts/world/chapter4_snowfall.gd").new()
	snowfall.amount = 80 if rising_motes else clampi(snow_amount * 2,130,300)
	snowfall.wind = wind
	add_child(snowfall)
	if not rising_motes:
		return
	var dust := CPUParticles2D.new()
	dust.name = "AtmosphericParticles"
	dust.position = Vector2(anchor_x,420 if rising_motes else 160)
	dust.z_index = -3
	dust.amount = maxi(1,snow_amount)
	dust.lifetime = 14.0
	dust.preprocess = 3.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(3400,500)
	dust.direction = Vector2(wind,-1 if rising_motes else 1)
	dust.spread = 20.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 10.0
	dust.initial_velocity_max = 30.0 if rising_motes else 55.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.4
	dust.color = particle_color
	add_child(dust)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var visible_size := get_viewport_rect().size/camera.zoom
	# Only 8 world units of overscan: preserve mountain peaks/aurora above.
	var top := center.y-visible_size.y*.5-8.0
	var bottom := maxf(ground_back_y+16.0,top+100.0)
	var depth := $Depth as Sprite2D
	var fit: float = (bottom-top)/depth.texture.get_height()
	depth.scale = Vector2(fit,fit)
	depth.position = Vector2(anchor_x+(center.x-anchor_x)*(1.0-depth_speed),(top+bottom)*.5)
	var region_width := maxf(12000.0,(visible_size.x+12000.0)/fit)
	depth.region_rect = Rect2(depth.texture.get_width()*.5-region_width*.5,0,region_width,depth.texture.get_height())
	# A far background and the ground together must cover the entire viewport.
	# Reuse the last foundation texels below the walkable strip for very tall views.
	var foundation := get_node_or_null("FoundationFill") as Polygon2D
	if foundation != null:
		var end_y := maxf(1500.0,center.y+visible_size.y*.5+32.0)
		foundation.polygon = PackedVector2Array([Vector2(-6000,1335),Vector2(12000,1335),Vector2(12000,end_y),Vector2(-6000,end_y)])
