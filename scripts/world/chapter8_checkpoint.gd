extends Area2D
const Tower = preload("res://scripts/world/chapter8_tower_data.gd")
var nearby := false
var busy := false
var label: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(240, 260)
	shape.shape = rect
	shape.position.y = -100
	add_child(shape)
	var stone := Sprite2D.new()
	stone.name = "RootStone"
	stone.texture = preload("res://Sprites/items/chapter8/c8_root_heart.png")
	stone.position = Vector2(0, -75)
	stone.scale = Vector2.ONE * 0.65
	add_child(stone)
	label = Label.new()
	label.position = Vector2(-150, -200)
	label.text = "ศิลาราก • เลือกชั้นที่เปิดแล้ว"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
	body_entered.connect(func(body):
		if body.is_in_group("player"): nearby = true; label.text = "กด F • เลือกจุดพัก / กลับล่าผู้คุม")
	body_exited.connect(func(body):
		if body.is_in_group("player"): nearby = false; label.text = "ศิลาราก • เลือกชั้นที่เปิดแล้ว")

static func destinations() -> Array:
	var result: Array = []
	for floor_number in range(1, Tower.FLOOR_COUNT + 1):
		if floor_number != 1 and floor_number % 5 != 0 and floor_number % 5 != 1: continue
		if not Tower.can_enter(floor_number): continue
		result.append({"id":Tower.floor_id(floor_number), "name":"ชั้น %d • %s" % [floor_number,Tower.THEMES[Tower.theme(floor_number)]], "chapter":8, "kind":"field", "hops":0, "cost":0, "ok":true, "why":""})
	return result

func _unhandled_input(event: InputEvent) -> void:
	if not nearby or busy or not event.is_action_pressed("interact") or UI.is_any_window_open(): return
	get_viewport().set_input_as_handled()
	busy = true
	var destination := await UI.choose_warp(destinations())
	busy = false
	if destination != &"" and Tower.can_enter(int(String(destination).get_slice("_",1))):
		Game.change_map(destination)
