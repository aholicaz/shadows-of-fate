extends Node2D
## F6 inspection scene. No PlayerState changes or save operations.
const VISUAL = preload("res://scripts/entities/runeblade_visual.gd")
@onready var equipment: CharacterVisual = $EquipVisual
@onready var body: AnimatedSprite2D = $AnimatedSprite2D
var selector: OptionButton
var info: Label
var scrub: HSlider
var updating := false
func _ready() -> void:
	get_window().size = Vector2i(1280,800)
	get_window().content_scale_size = Vector2i(1280,800)
	RenderingServer.set_default_clear_color(Color("16212d"))
	UI.layer.hide()
	var panel := VBoxContainer.new()
	panel.position = Vector2(32,28)
	panel.custom_minimum_size.x = 520
	add_child(panel)
	var title := Label.new()
	title.text = "RUNEBLADE / SPRITE GALLERY"
	title.add_theme_font_size_override("font_size",28)
	panel.add_child(title)
	selector = OptionButton.new()
	panel.add_child(selector)
	var names := body.sprite_frames.get_animation_names()
	for n in names: selector.add_item(String(n))
	selector.item_selected.connect(func(i): play_pose(selector.get_item_text(i)))
	var weapon_selector := OptionButton.new()
	panel.add_child(weapon_selector)
	weapon_selector.add_item("No equipped sword")
	var weapons: Array[ItemData] = []
	for id in GameData.items:
		var item: ItemData = GameData.get_item(id)
		if item.equip_follow_idle_hand:
			weapons.append(item)
			weapon_selector.add_item(item.display_name)
			if item.id==&"katana":
				weapon_selector.select(weapons.size())
				equipment.set_layer(Equipment.EquipSlot.WEAPON,item)
	weapon_selector.item_selected.connect(func(i):equipment.set_layer(Equipment.EquipSlot.WEAPON,null if i==0 else weapons[i-1]))

	var controls := HBoxContainer.new()
	panel.add_child(controls)
	for label in ["Play / Pause","Restart","Flip","Previous frame","Next frame"]:
		var button := Button.new()
		button.text = label
		controls.add_child(button)
		button.pressed.connect(action.bind(label))
	var speed_label := Label.new()
	speed_label.text = "Playback speed"
	panel.add_child(speed_label)
	var speed := HSlider.new()
	speed.min_value = .25
	speed.max_value = 2.0
	speed.step = .25
	speed.value = 1.0
	speed.custom_minimum_size.x = 450
	speed.value_changed.connect(func(v): body.speed_scale=v)
	panel.add_child(speed)
	var frame_label := Label.new()
	frame_label.text = "Frame"
	panel.add_child(frame_label)
	scrub = HSlider.new()
	scrub.step = 1
	scrub.value_changed.connect(func(v):
		if not updating:
			body.pause()
			body.set_frame_and_progress(int(v),0.0))
	panel.add_child(scrub)
	info = Label.new()
	panel.add_child(info)
	play_pose("Idle_Runeblade")
	if "--capture-runeblade-gallery" in OS.get_cmdline_user_args():
		await get_tree().create_timer(.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/runeblade_full/gallery.png")
		get_tree().quit()
func play_pose(pose: String) -> void:
	body.play(pose)
	body.set_frame_and_progress(0,0)
	scrub.max_value = body.sprite_frames.get_frame_count(pose)-1
	for i in selector.item_count:
		if selector.get_item_text(i)==pose: selector.select(i)
func action(label: String) -> void:
	match label:
		"Play / Pause":
			if body.is_playing(): body.pause()
			else: body.play()
		"Restart": play_pose(String(body.animation))
		"Flip": body.flip_h = not body.flip_h
		"Previous frame", "Next frame":
			body.pause()
			var count := body.sprite_frames.get_frame_count(body.animation)
			body.set_frame_and_progress(posmod(body.frame+(1 if label=="Next frame" else -1),count),0)
func _process(_delta: float) -> void:
	if not is_instance_valid(body) or not is_instance_valid(info): return
	var fit: Dictionary = VISUAL.fit(body.sprite_frames,288.0,body.animation)
	var frame: Dictionary = fit.frames[body.frame]
	var k: float = frame.get("scale",fit.scale)
	body.scale = Vector2.ONE*k
	body.offset = Vector2(frame.dx_use if body.flip_h else -frame.dx_use,-frame.bottom_use)
	VISUAL.update_idle(body)
	updating = true
	scrub.value = body.frame
	updating = false
	var bindings: Array[String] = []
	var routes: Dictionary = body.sprite_frames.get_meta("rb_skill_routes",{})
	for key in routes:
		if routes[key]==String(body.animation):bindings.append(String(key))
	info.text = "%s   |   Frame %d / %d   |   %.2fx\n%s" % [body.animation,body.frame+1,body.sprite_frames.get_frame_count(body.animation),body.speed_scale,", ".join(bindings)]
func _draw() -> void:
	draw_rect(Rect2(0,680,1280,120),Color("263442"))
	draw_line(Vector2(0,680),Vector2(1280,680),Color("75889b"),2)
	draw_ellipse_shadow()
func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(720,680),0,Vector2(1,.18))
	draw_circle(Vector2.ZERO,90,Color(0,0,0,.22))
	draw_set_transform(Vector2.ZERO)
