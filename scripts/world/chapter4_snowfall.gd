extends Node2D
## Camera-sized snowfall keeps a consistent density across map lengths/zooms.
@export var amount: int = 200
@export var wind: float = 0.4
var _layers: Array[CPUParticles2D] = []
var _last_size := Vector2.ZERO

func _ready() -> void:
	process_priority = 110
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.4,1])
	gradient.colors = PackedColorArray([Color.WHITE,Color(1,1,1,.85),Color(1,1,1,0)])
	var flake := GradientTexture2D.new()
	flake.width = 16
	flake.height = 16
	flake.fill = GradientTexture2D.FILL_RADIAL
	flake.fill_from = Vector2(.5,.5)
	flake.fill_to = Vector2(1,.5)
	flake.gradient = gradient
	var material := ShaderMaterial.new()
	material.shader = preload("res://Sprites/shaders/chapter4_snowfall.gdshader")
	for near in range(2):
		var snow := CPUParticles2D.new()
		snow.name = "NearFlakes" if near else "FarFlakes"
		snow.z_index = 5 if near else -4
		snow.amount = maxi(12,roundi(amount*(.25 if near else .75)))
		snow.texture = flake
		snow.material = material
		snow.local_coords = true
		snow.lifetime = 10.0
		snow.preprocess = 10.0
		snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		snow.direction = Vector2(wind,1)
		snow.spread = 12.0
		snow.gravity = Vector2.ZERO
		snow.initial_velocity_min = 50.0 if near else 28.0
		snow.initial_velocity_max = 100.0 if near else 60.0
		snow.scale_amount_min = .40 if near else .20
		snow.scale_amount_max = .70 if near else .38
		snow.color = Color(.91,.96,1,.62 if near else .72)
		_layers.append(snow)
		add_child(snow)
	_update_view()

func _process(_delta: float) -> void:
	_update_view()

func _update_view() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:return
	global_position = camera.get_screen_center_position()
	scale = Vector2.ONE/camera.zoom
	var size := get_viewport_rect().size
	if size == _last_size:return
	_last_size = size
	for layer in _layers:
		# Populate the view immediately rather than waiting for flakes from above.
		layer.emission_rect_extents = size*.5+Vector2(100,80)
		layer.restart()
