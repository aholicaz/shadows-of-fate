## StoryPoint — จุดกด F ที่มีเหตุการณ์เขียนด้วยโค้ด (รอบ 105)  ต่อยอดจาก runeblade_point.gd ของ ChatGPT
##
## ใช้ใน ch456_campaign.gd: คนแปลกหน้าที่กำแพงตอนกลางคืน · ผลึกเงาสลับร่าง · ผนังที่เก้า (พิธี Ninth Edge) ·
## โซ่สายฟ้าของการ์ม · บัลลังก์ว่างของโอดิน
## รูปร่างชั่วคราว (วาดด้วยโค้ด) เลือกด้วย `shape` — วาดภาพจริงแล้วเอา Sprite2D มาเป็นลูกของโหนดนี้ได้เลย
extends Node2D

var title := "..."
var action: Callable
var label: Label
var busy := false
var tint := Color("#efbd69")
## rune · figure (คนคลุมหน้า) · chain (โซ่) · wall (ผนัง) · throne (บัลลังก์) · crystal (ผลึกดำ) · camp (กองไฟ) · hound (สุนัขนอน)
var shape := "rune"
## ป้ายโชว์เฉพาะเมื่อมีธงนี้ (ว่าง = โชว์เสมอ)
var reveal_flag: StringName = &""
var hidden_title := ""
var reach := 150.0


func _ready() -> void:
	add_to_group("story_point")
	label = UITheme.make_label(title, 18, tint)
	label.position = Vector2(-180, -170)
	label.custom_minimum_size.x = 360
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	queue_redraw()


func _process(_delta: float) -> void:
	if reveal_flag != &"":
		label.text = title if PlayerState.has_flag(reveal_flag) else hidden_title


func set_title(t: String) -> void:
	title = t
	if label != null:
		label.text = t


func _draw() -> void:
	match shape:
		"figure":
			# คนคลุมหน้า — เงาดำ ยืนนิ่ง
			var body := Color("#14121a")
			draw_colored_polygon(PackedVector2Array([Vector2(-26, 0), Vector2(-30, -110), Vector2(-14, -150), Vector2(14, -150), Vector2(30, -110), Vector2(26, 0)]), body)
			draw_circle(Vector2(0, -150), 16, body)
			draw_colored_polygon(PackedVector2Array([Vector2(-20, -146), Vector2(0, -172), Vector2(20, -146)]), body)
			draw_line(Vector2(-6, -140), Vector2(6, -140), Color("#2a2636"), 2)
		"chain":
			for i in range(7):
				draw_arc(Vector2(0, -20 - i * 22), 9, 0, TAU, 12, Color("#8fb8ff"), 3)
			draw_line(Vector2(0, -170), Vector2(0, -320), Color("#8fb8ff"), 4)
			draw_circle(Vector2(0, -10), 6, Color("#dfe9ff"))
		"wall":
			draw_rect(Rect2(-90, -220, 180, 220), Color("#2a2a3a"))
			draw_rect(Rect2(-84, -214, 168, 208), Color("#3a3a50"), false, 2)
			for i in range(5):
				draw_line(Vector2(-70, -190 + i * 36), Vector2(70, -190 + i * 36), Color("#4a4a62"), 1)
		"throne":
			draw_colored_polygon(PackedVector2Array([Vector2(-60, 0), Vector2(-60, -140), Vector2(-40, -200), Vector2(40, -200), Vector2(60, -140), Vector2(60, 0)]), Color("#b28a3c"))
			draw_rect(Rect2(-46, -120, 92, 60), Color("#7a5a22"))
			draw_circle(Vector2(0, -200), 12, Color("#ffd86b"))
		"crystal":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -190), Vector2(34, -100), Vector2(0, 0), Vector2(-34, -100)]), Color("#0e0c14"))
			draw_polyline(PackedVector2Array([Vector2(0, -190), Vector2(34, -100), Vector2(0, 0), Vector2(-34, -100), Vector2(0, -190)]), Color("#6a5a9a"), 2, true)
		"camp":
			draw_circle(Vector2(0, -8), 26, Color("#3a2a1a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -10), Vector2(0, -60), Vector2(14, -10)]), Color("#ff9a3c"))
			draw_colored_polygon(PackedVector2Array([Vector2(-7, -10), Vector2(0, -38), Vector2(7, -10)]), Color("#ffe07a"))
		"hound":
			draw_colored_polygon(PackedVector2Array([Vector2(-90, 0), Vector2(-80, -50), Vector2(-30, -70), Vector2(40, -60), Vector2(90, -30), Vector2(90, 0)]), Color("#1c1820"))
			draw_circle(Vector2(70, -40), 22, Color("#1c1820"))
			draw_circle(Vector2(78, -46), 3, Color("#ff5050"))
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-30, 0), Vector2(-25, -100), Vector2(0, -123), Vector2(25, -100), Vector2(30, 0)]), Color("#26313b"))
			draw_polyline(PackedVector2Array([Vector2(0, -100), Vector2(-13, -72), Vector2(0, -43), Vector2(13, -72), Vector2(0, -100), Vector2(0, -24)]), tint, 3, true)


func _unhandled_input(event: InputEvent) -> void:
	if busy or UI == null or UI.is_asking() or UI.is_any_window_open() or not event.is_action_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.foot_position().distance_to(global_position) > reach:
		return
	get_viewport().set_input_as_handled()
	busy = true
	await action.call()
	busy = false
