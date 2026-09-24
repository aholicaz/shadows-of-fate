extends "res://scripts/world/chapter5_parallax.gd"
@export_range(0,9) var tower_theme := 0
@export var floor_variant := 0

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint(): return
	if tower_theme == 1:
		for p in [motes, near_motes]:
			p.direction = Vector2(.25,1)
			p.initial_velocity_min = 18
			p.initial_velocity_max = 32
			p.scale_amount_min = .2
			p.scale_amount_max = .4
	if tower_theme in [0,9]:
		var white := Image.create(1,1,false,Image.FORMAT_RGBA8)
		white.fill(Color.WHITE)
		var tex := ImageTexture.create_from_image(white)
		for i in range(4):
			var ray := Polygon2D.new()
			ray.texture = tex
			ray.position = Vector2(550+i*1150,0)
			ray.z_index = -10
			ray.polygon = PackedVector2Array([Vector2(-40,0),Vector2(40,0),Vector2(-100,860),Vector2(-440,860)])
			ray.uv = PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://Sprites/shaders/prontera_sunshafts.gdshader")
			mat.set_shader_parameter("phase", float(i+floor_variant))
			mat.set_shader_parameter("sunlight",Color(1,.90,.66,.12))
			ray.material = mat
			add_child(ray)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null: return
	var center := camera.get_screen_center_position()
	var size := get_viewport_rect().size/camera.zoom
	var depth: Sprite2D = $Depth
	var tex_size := depth.texture.get_size()
	var fit := maxf((size.y+16)/tex_size.y,(size.x+maxf(0,4200-size.x)*depth_speed+32)/tex_size.x)
	depth.scale = Vector2.ONE*fit
	depth.position = Vector2(center.x+(anchor_x-center.x)*depth_speed,center.y)
	for p in [motes,near_motes]:
		p.position = center
		if previous_size.distance_to(size)>4: p.emission_rect_extents = size*.6
	previous_size = size
	haze.polygon = PackedVector2Array([center-size*.5,center+Vector2(size.x,-size.y)*.5,center+size*.5,center+Vector2(-size.x,size.y)*.5])
