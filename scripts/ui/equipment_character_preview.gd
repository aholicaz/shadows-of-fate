extends Control
## Independent idle doll; shares the game's hand tracking, never the player's state.
const RUNE = preload("res://scripts/entities/runeblade_visual.gd")
# New chapter weapons have icon art but no world equipment registration yet.
# Normalized grip + rotation measured against that existing art, preview only.
const ICON_GRIPS := {
	"bone_greatsword": Vector3(0.78, 0.22, 62),
	"conduit_edge": Vector3(0.77, 0.19, 62),
	"ferryman_oar_blade": Vector3(0.77, 0.23, 62),
	"frost_edge": Vector3(0.78, 0.22, 62),
	"garm_fang": Vector3(0.79, 0.24, 62),
	"light_crystal_sword": Vector3(0.78, 0.22, 62),
	"mist_saber": Vector3(0.76, 0.22, 62),
	"name_blade": Vector3(0.23, 0.23, 152),
	"prism_blade": Vector3(0.28, 0.73, 242),
	"stag_horn_saber": Vector3(0.74, 0.80, 332),
	"stone_hrungnir_blade": Vector3(0.75, 0.23, 62),
	"troll_cleaver": Vector3(0.78, 0.25, 62),
	"wall_greatsword": Vector3(0.75, 0.22, 62),
}
var body: AnimatedSprite2D
var visual: CharacterVisual
var fit: Dictionary = {}
var stage: Node2D
static var art_bounds: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	stage = Node2D.new()
	add_child(stage)
	body = AnimatedSprite2D.new()
	body.name = "AnimatedSprite2D"
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	stage.add_child(body)
	visual = CharacterVisual.new()
	visual.use_player_equipment = false
	stage.add_child(visual)
	visual.set_process(false)
	resized.connect(refresh)
	refresh()

func refresh() -> void:
	if body == null: return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		body.hide()
		visual.hide()
		visual.set_process(false)
		return
	var source: AnimatedSprite2D = player.get("sprite")
	if source == null or source.sprite_frames == null: return
	var anim: String = player._resolve_anim("Idle")
	if not player._uses_runeblade_visual(): anim = player._real_anim("Idle")
	if anim.is_empty(): return
	body.sprite_frames = source.sprite_frames
	body.flip_h = bool(player.get("sprite_faces_left"))
	body.show()
	visual.set_process(true)
	body.play(anim)
	var height := minf(size.y * 0.82, size.x * 1.30)
	if RUNE.is_pose(body.sprite_frames, anim):
		fit = RUNE.fit(body.sprite_frames, height, anim)
	else:
		fit = SpriteFit.measure(body.sprite_frames, anim)
		fit = fit.duplicate()
		fit["scale"] = height / maxf(1.0, float(fit.get("tallest", 1.0)))
	for slot in CharacterVisual.LAYER_ORDER:
		var inst: ItemInstance = PlayerState.equipment.get_item(slot)
		var item: ItemData = inst.data() if inst != null else null
		if item != null and item.equip_texture == null and item.equip_sprite_frames == null and ICON_GRIPS.has(String(item.id)) and item.icon != null:
			item = item.duplicate()
			var grip: Vector3 = ICON_GRIPS[String(item.id)]
			item.equip_texture = item.icon
			item.equip_follow_idle_hand = true
			item.equip_grip = Vector2(grip.x, grip.y) * item.icon.get_size()
			item.equip_hand_rotation_degrees = grip.z
			item.equip_hand_scale = 480.0 / maxf(item.icon.get_width(), item.icon.get_height())
		visual.set_layer(slot, item)
	_process(0.0)
	_fit_stage()

func _fit_stage() -> void:
	# Fit the entire idle cycle once, so long swords stay inside the doll panel
	# without breathing changes in scale as the character animates.
	var saved_frame := body.frame
	var saved_progress := body.frame_progress
	var bounds := Rect2()
	for i in range(body.sprite_frames.get_frame_count(body.animation)):
		body.set_frame_and_progress(i, 0.0)
		_process(0.0)
		visual._process(0.0)
		var body_rect := _sprite_bounds(body)
		bounds = body_rect if i == 0 else bounds.merge(body_rect)
		for layer in visual._layers.values():
			if layer.visible and layer.sprite_frames != null:
				bounds = bounds.merge(visual.transform * _sprite_bounds(layer))
	body.set_frame_and_progress(saved_frame, saved_progress)
	_process(0.0)
	visual._process(0.0)
	var k := minf((size.x - 8.0) / maxf(bounds.size.x, 1.0), (size.y - 16.0) / maxf(bounds.size.y, 1.0))
	stage.scale = Vector2.ONE * maxf(k, 0.01)
	stage.position = Vector2(size.x * 0.5, size.y * 0.78) - Vector2(bounds.get_center().x, bounds.end.y) * k

func _sprite_bounds(spr: AnimatedSprite2D) -> Rect2:
	var tex := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	var key := tex.get_rid()
	if not art_bounds.has(key):
		var img := SpriteFit._frame_image(tex, {})
		art_bounds[key] = Rect2(img.get_used_rect()) if img != null else Rect2(Vector2.ZERO, tex.get_size())
	var rect: Rect2 = art_bounds[key]
	if spr.centered: rect.position -= tex.get_size() * 0.5
	if spr.flip_h: rect.position.x = -rect.end.x
	if spr.flip_v: rect.position.y = -rect.end.y
	rect.position += spr.offset
	return spr.transform * rect

func _process(_delta: float) -> void:
	if body == null or fit.is_empty() or not is_visible_in_tree(): return
	var poses: Array = fit.get("frames", [])
	if poses.is_empty(): return
	var pose: Dictionary = poses[mini(body.frame, poses.size() - 1)]
	body.scale = Vector2.ONE * float(pose.get("scale", fit.scale))
	body.position = Vector2.ZERO
	body.offset = Vector2(float(pose.dx_use) if body.flip_h else -float(pose.dx_use), -float(pose.bottom_use))
	RUNE.update_idle(body)
