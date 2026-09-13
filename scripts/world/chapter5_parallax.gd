@tool
extends Node2D
@export var anchor_x := 2500.0
@export var depth_speed := .20
@export var atmosphere := Color(.9,.86,.58,.4)
@export var mote_amount := 65
@export var rising := false
@export var mist_strength := .045
var motes: CPUParticles2D
var near_motes: CPUParticles2D
var haze: Polygon2D
var previous_size := Vector2.ZERO
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	process_priority = 100
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	var flake := GradientTexture2D.new()
	flake.width=16; flake.height=16
	flake.gradient=gradient
	flake.fill=GradientTexture2D.FILL_RADIAL
	flake.fill_from=Vector2(.5,.5); flake.fill_to=Vector2(1,.5)
	for i in range(2):
		var p := CPUParticles2D.new()
		p.name="NearMotes" if i else "FarMotes"
		p.z_index=5 if i else -4
		p.amount=maxi(8,roundi(mote_amount*(.25 if i else .75)))
		p.texture=flake
		p.local_coords=true
		p.lifetime=14
		p.preprocess=14
		p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.direction=Vector2(.12,-1) if rising else Vector2(.6,-.2)
		p.spread=35
		p.gravity=Vector2.ZERO
		p.initial_velocity_min=8
		p.initial_velocity_max=22 if rising else 14
		p.scale_amount_min=.13
		p.scale_amount_max=.35 if i else .22
		p.color=atmosphere
		add_child(p)
		if i: near_motes=p
		else: motes=p
	haze=Polygon2D.new()
	haze.name="SoftAtmosphere"
	haze.z_index=-2
	var material := ShaderMaterial.new()
	material.shader=preload("res://Sprites/shaders/chapter5_atmosphere.gdshader")
	material.set_shader_parameter("tint",atmosphere)
	material.set_shader_parameter("strength",mist_strength)
	haze.material=material
	haze.uv=PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	add_child(haze)
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera==null:return
	var center:=camera.get_screen_center_position()
	var size:=get_viewport_rect().size/camera.zoom
	var top:=center.y-size.y*.5-8
	var bottom:=maxf(786,top+100)
	var depth: Sprite2D=$Depth
	var fit:float=(bottom-top)/depth.texture.get_height()
	depth.scale=Vector2(fit,fit)
	depth.position=Vector2(anchor_x+(center.x-anchor_x)*(1-depth_speed),(top+bottom)*.5)
	var width:=maxf(12000,(size.x+12000)/fit)
	depth.region_rect=Rect2(depth.texture.get_width()*.5-width*.5,0,width,depth.texture.get_height())
	for p in [motes,near_motes]:
		p.position=center
		if previous_size.distance_to(size)>4:p.emission_rect_extents=size*.6
	previous_size=size
	haze.polygon=PackedVector2Array([center-size*.5,center+Vector2(size.x,-size.y)*.5,center+size*.5,center+Vector2(-size.x,size.y)*.5])
