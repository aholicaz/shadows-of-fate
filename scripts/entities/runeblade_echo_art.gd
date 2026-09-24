extends RefCounted
## Visual-only switch: false restores every original effect path.
const ENABLED := true
const BLADE = preload("res://Sprites/effects/runeblade_echo/blade.png")
const CUT = preload("res://Sprites/effects/runeblade_echo/cut.png")
const SLASH_SHEET = preload("res://Sprites/effects/runeblade_echo/slash_sheet.png")
const RUNE = preload("res://Sprites/effects/runeblade_echo/rune.png")
const TIP := Vector2(65, 358)
const GRIP := Vector2(1820, 358)
const LENGTH := 1755.0

static func active(caster: Node) -> bool:
	return ENABLED and is_instance_valid(caster) and caster.has_method("_uses_runeblade_visual") and caster._uses_runeblade_visual()

static func blade(length: float = 220.0, at_tip: bool = false) -> Sprite2D:
	var art := Sprite2D.new()
	art.texture = BLADE
	art.centered = false
	art.offset = -TIP if at_tip else -GRIP
	art.scale = Vector2.ONE * length / LENGTH
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return art

static func slash_sprite(reach: float = 230.0, direction: int = -1, style: String = "combo1") -> AnimatedSprite2D:
	var path: String = {"combo2":"rise", "combo3":"sweep", "thrust":"thrust", "slam":"slam", "flurry":"flurry", "critical":"critical"}.get(style, "slash")
	var sheet: Texture2D = load("res://Sprites/effects/runeblade_echo/"+path+"_sheet.png")
	var frames := SpriteFrames.new()
	frames.set_animation_loop(&"default", false)
	frames.set_animation_speed(&"default", 40.0)
	var cell := sheet.get_size() / Vector2(4, 2)
	for i in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i % 4, i / 4) * cell, cell)
		if style=="critical": atlas.region=atlas.region.grow(-3.0)
		atlas.filter_clip = true
		frames.add_frame(&"default", atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.set_meta("effect_style", style)
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(-direction, 1) * reach / (cell.y * 0.82)
	return sprite

static func slash_phase(sprite: AnimatedSprite2D, elapsed: float, duration: float = 0.20) -> void:
	sprite.visible = elapsed >= 0.0 and elapsed < duration
	var phase := clampf(elapsed / duration, 0.0, 0.9999) * 8.0
	sprite.set_frame_and_progress(int(phase), fposmod(phase, 1.0))
	if sprite.get_meta("effect_style", "") == "slam":
		# Register the contact point, not the changing silhouette bounds.
		var anchors := [Vector2(0.52,0.88),Vector2(0.64,0.88),Vector2(0.55,0.88),Vector2(0.52,0.89),Vector2(0.52,0.83),Vector2(0.50,0.83),Vector2(0.51,0.82),Vector2(0.52,0.81)]
		var cell := sprite.sprite_frames.get_frame_texture(&"default",sprite.frame).get_size()
		sprite.offset = (Vector2(0.5,0.5)-anchors[sprite.frame])*cell

static func cut(caster: Node2D, at: Vector2, direction: int, reach: float = 230.0,
		index: int = 0, delay: float = 0.0, follow: bool = false, style: String = "") -> Node2D:
	var fx = load("res://scripts/entities/runeblade_echo_burst.gd").new()
	fx.caster = caster
	fx.direction = direction
	fx.reach = reach
	fx.index = index
	fx.delay = delay
	fx.follow = follow
	fx.style = style if not style.is_empty() else "combo%d" % (posmod(index,3)+1)
	if fx.style.begins_with("combo"):
		fx.reach *= 1.45
		at.y -= 35.0
	if fx.style == "flurry":
		fx.reach *= 1.5
		fx.lifetime = 0.12
	elif fx.style == "slam": fx.lifetime = 0.24
	caster.get_parent().add_child(fx)
	caster.get_parent().move_child(fx, caster.get_index())
	fx.global_position = at
	fx.follow_offset = at - caster.global_position
	return fx

static func seal(parent: Node, at: Vector2, size: Vector2, duration: float = 0.28) -> Sprite2D:
	var art := Sprite2D.new()
	art.texture = RUNE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(art)
	art.position = at
	art.scale = size / 760.0
	art.modulate.a = 0.0
	var target_scale := art.scale
	var tween := art.create_tween()
	tween.tween_property(art, "modulate:a", 0.75, minf(0.045,duration*0.2))
	tween.tween_property(art, "modulate:a", 0.0, duration-minf(0.045,duration*0.2))
	tween.parallel().tween_property(art, "scale", target_scale*1.18, duration*0.8)
	tween.tween_callback(art.queue_free)
	return art
