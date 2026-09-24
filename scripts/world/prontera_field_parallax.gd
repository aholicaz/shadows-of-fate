extends "res://scripts/world/chapter5_parallax.gd"

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	# Canopy openings in the terrain artwork; fixed world anchors prevent sliding.
	var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	var beam_texture := ImageTexture.create_from_image(white)
	var openings := [Vector2(400, -320), Vector2(1280, -310), Vector2(2310, -330), Vector2(3070, -290), Vector2(3970, -315), Vector2(4780, -300), Vector2(5600, -325)]
	for i in range(openings.size()):
		var beam := Polygon2D.new()
		beam.name = "Sunshaft%d" % i
		beam.z_index = -10
		beam.position = openings[i]
		beam.texture = beam_texture
		beam.polygon = PackedVector2Array([Vector2(-50, 0), Vector2(50, 0), Vector2(-140, 850), Vector2(-520, 850)])
		beam.uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		var light_material := ShaderMaterial.new()
		light_material.shader = preload("res://Sprites/shaders/prontera_sunshafts.gdshader")
		light_material.set_shader_parameter("phase", float(i) * 1.7)
		beam.material = light_material
		add_child(beam)

## One distant city, never mirrored or repeated. Terrain stays in world space.
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var size := get_viewport_rect().size / camera.zoom
	var depth: Sprite2D = $Depth
	var tex_size := depth.texture.get_size()
	var travel := maxf(0.0, 5750.0 - size.x) * depth_speed
	var fit := maxf((size.y + 16.0) / tex_size.y, (size.x + travel + 32.0) / tex_size.x)
	depth.scale = Vector2.ONE * fit
	depth.position = Vector2(center.x + (anchor_x - center.x) * depth_speed, center.y)
	for p in [motes, near_motes]:
		p.position = center
		if previous_size.distance_to(size) > 4:
			p.emission_rect_extents = size * .6
	previous_size = size
	haze.polygon = PackedVector2Array([center-size*.5, center+Vector2(size.x,-size.y)*.5, center+size*.5, center+Vector2(-size.x,size.y)*.5])
