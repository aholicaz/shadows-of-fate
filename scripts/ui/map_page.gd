## MapPage — หน้า "แผนที่" ใหญ่ในหน้าต่างรวม (รอบ 98)
##
## ใช้ตัววาดเดียวกับมินิแมพมุมขวาบน (Minimap) แต่ขยายเต็มหน้า + ชื่อแมพ/ภูมิภาค + คำอธิบายสัญลักษณ์
## กด M เดิมยังเปิด/ปิดมินิแมพเล็กได้เหมือนเดิม
class_name MapPage
extends GameWindow

var _big: Minimap
var _name_label: Label
var _region_label: Label


func _ready() -> void:
	window_title = "แผนที่"
	super._ready()
	Events.map_changed.connect(func(_id): refresh())


func _build_content() -> void:
	# ---------- หัว: ชื่อแมพ + ภูมิภาค ----------
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	content.add_child(head)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	head.add_child(row)
	var l := PetrolWidgets.ornament(90.0, UITheme.ACCENT, 3.0)
	l.custom_minimum_size = Vector2(90, 12)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	_name_label = UITheme.make_label("", 20, UITheme.TEXT)
	row.add_child(_name_label)
	var r := PetrolWidgets.ornament(90.0, UITheme.ACCENT, 3.0)
	r.custom_minimum_size = Vector2(90, 12)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(r)
	_region_label = UITheme.make_label("", 12, UITheme.TEXT_DIM)
	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_region_label)

	# ---------- แผนที่ใหญ่ ----------
	_big = Minimap.new()
	_big.embedded = true
	_big.name = "BigMap"
	_big.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_big.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_big)
	_big.view.custom_minimum_size = Vector2(0, 360)
	_big.view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_big.view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_big.title_label.visible = false

	# ---------- คำอธิบายสัญลักษณ์ + ปุ่ม ----------
	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 18)
	content.add_child(legend)
	for pair in [["ตัวเรา", Minimap.C_PLAYER], ["มอนสเตอร์", Minimap.C_ENEMY], ["บอส", Minimap.C_BOSS],
			["NPC", Minimap.C_NPC], ["ประตูวาป", Minimap.C_PORTAL], ["ของที่ตก", Minimap.C_ITEM]]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 5)
		var dot := ColorRect.new()
		dot.color = pair[1]
		dot.custom_minimum_size = Vector2(9, 9)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(dot)
		item.add_child(UITheme.make_label(String(pair[0]), 11, UITheme.TEXT_DIM))
		legend.add_child(item)



func refresh() -> void:
	if _name_label == null:
		return
	var id: StringName = PlayerState.current_map_id
	_name_label.text = Game.map_display_name(id)
	_region_label.text = String(HUD.REGION_NAMES.get(id, ""))
	if _big != null:
		_big.visible = true
		_big.view.queue_redraw()


func shell_hints() -> Array:
	return [["M", "เปิด/ปิดหน้าแผนที่"], ["Esc", "ปิด"]]
