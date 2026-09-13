extends Node2D

var title := "อักขระ"
var action: Callable
var label: Label
var busy := false
var draw_marker := true
var tint := Color("#efbd69")
var reveal_flag: StringName = &""
var hidden_title := "[F] ซุ้มรากเก่า"

func _process(_delta: float) -> void:
	if reveal_flag != &"": label.text = title if PlayerState.has_flag(reveal_flag) else hidden_title

func _ready() -> void:
	label = UITheme.make_label(title, 18, tint)
	label.position = Vector2(-180, -150)
	label.custom_minimum_size.x = 360
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	queue_redraw()

func _draw() -> void:
	if not draw_marker: return
	draw_colored_polygon(PackedVector2Array([Vector2(-30,0),Vector2(-25,-100),Vector2(0,-123),Vector2(25,-100),Vector2(30,0)]),Color("#26313b"))
	draw_polyline(PackedVector2Array([Vector2(0,-100),Vector2(-13,-72),Vector2(0,-43),Vector2(13,-72),Vector2(0,-100),Vector2(0,-24)]),tint,3,true)

func _unhandled_input(event: InputEvent) -> void:
	if busy or UI.is_asking() or UI.is_any_window_open() or not event.is_action_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.foot_position().distance_to(global_position) > 150:
		return
	get_viewport().set_input_as_handled()
	busy = true
	await action.call()
	busy = false
