extends Node2D
## Eight painted frames, anchored to the stone ring; light does not affect gameplay.
var fire: AnimatedSprite2D
var light: PointLight2D
var elapsed := 0.0

func _ready() -> void:
	fire = AnimatedSprite2D.new()
	fire.sprite_frames = preload("res://Sprites/effects/snow_campfire/campfire_frames.tres")
	fire.centered = false
	fire.scale = Vector2.ONE * 0.34
	fire.position = Vector2(-224, -430) * 0.34
	fire.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(fire)
	fire.play(&"burn")
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.65), Color(1, 1, 1, 0)])
	var glow := GradientTexture2D.new()
	glow.width = 256
	glow.height = 256
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	light = PointLight2D.new()
	light.texture = glow
	light.texture_scale = 2.1
	light.position = Vector2(0, -44)
	light.color = Color("ffb461")
	light.energy = 0.65
	light.shadow_enabled = false
	add_child(light)

func _process(delta: float) -> void:
	if light == null: return
	elapsed += delta
	light.energy = 0.65 + sin(elapsed * 7.1) * 0.07 + sin(elapsed * 13.7) * 0.035
	light.texture_scale = 2.1 + sin(elapsed * 4.3) * 0.045
