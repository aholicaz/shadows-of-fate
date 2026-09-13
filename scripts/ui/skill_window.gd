## Skill library, inline upgrade details and a persistent four-slot loadout.
class_name SkillWindow
extends GameWindow

const GROUPS := ["นักดาบ", "Runeblade", "Ninth Edge"]
var _selected: StringName = &""
var _category := -1
var _tiles: Dictionary = {}
var _filters: Array[Button] = []
var _point_label: Label
var _grid: Control
var _detail: VBoxContainer
var _detail_actions: VBoxContainer
var _hotbar: HBoxContainer
var _scroll: ScrollContainer
var _status: Label

func _ready() -> void:
	window_title = "สกิลและชุดต่อสู้"
	super._ready()
	if not embedded: custom_minimum_size = Vector2(760,560)
	Events.skills_changed.connect(refresh)
	Events.stats_changed.connect(refresh)

func _build_content() -> void:
	content.add_theme_constant_override("separation",10)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := UITheme.make_label("ผังทักษะประจำอาชีพ",20,UITheme.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_point_label = UITheme.make_label("",16,UITheme.GOOD)
	heading.add_child(_point_label)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation",5)
	content.add_child(tabs)
	for i in range(GROUPS.size()):
		var index := i
		var button := UITheme.make_button("???" if i==2 and not PlayerState.stats.has_profession(&"ninth_edge") else GROUPS[i])
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size",13)
		button.pressed.connect(func(): _category=index; _selected=&""; refresh())
		tabs.add_child(button)
		_filters.append(button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	content.add_child(body)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(530,220)
	body.add_child(_scroll)
	_grid = preload("res://scripts/ui/skill_tree_canvas.gd").new()
	_grid.custom_minimum_size=Vector2(530,354)
	_scroll.add_child(_grid)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size.x = 300
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_stretch_ratio = 0.72
	detail_panel.add_theme_stylebox_override("panel",UITheme.inner_style(Color("#162438"),8,12))
	body.add_child(detail_panel)
	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation",10)
	detail_panel.add_child(detail_layout)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_layout.add_child(detail_scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation",10)
	detail_scroll.add_child(_detail)
	_detail_actions = VBoxContainer.new()
	_detail_actions.add_theme_constant_override("separation",8)
	detail_layout.add_child(_detail_actions)
	_status = UITheme.make_label("กด + บนผังเพื่ออัปเกรด • คลิกสกิลเพื่ออ่านและติดตั้ง",13,UITheme.TEXT_DIM)
	content.add_child(_status)
	_hotbar = HBoxContainer.new()
	_hotbar.add_theme_constant_override("separation",8)
	content.add_child(_hotbar)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _group(id: StringName) -> int:
	if id in SkillBook.NINTH_SKILLS: return 2
	if id in SkillBook.RUNE_SKILLS: return 1
	return 0

func refresh() -> void:
	if _grid == null or PlayerState.skills == null: return
	var st := PlayerState.stats
	if _category<0: _category=2 if st.job_id==&"ninth_edge" else (1 if st.job_id==&"runeblade" else 0)
	var owner: StringName=[&"swordsman",&"runeblade",&"ninth_edge"][_category]
	var record := st.profession_state(owner)
	_point_label.text="%s • Job %d • %d แต้ม"%[GROUPS[_category],int(record.level),int(record.points)] if st.has_profession(owner) else "ยังไม่ได้เปลี่ยนอาชีพ"
	# Show the profession's own skills even before promotion, with honest learn requirements.
	var available := GameData.skills_for_job([&"swordsman",&"runeblade",&"ninth_edge"][_category])
	if _selected == &"":
		for s: SkillData in available:
			if _group(s.id)==_category:
				_selected=s.id
				break
	for i in range(_filters.size()):
		_filters[i].set_pressed_no_signal(i==_category)
		_filters[i].text="???" if i==2 and not st.has_profession(&"ninth_edge") else GROUPS[i]
	_clear(_grid)
	_tiles.clear()
	_grid.set_nodes(_tiles)
	if _category==2 and not st.has_profession(&"ninth_edge"):
		_selected=&""
		_clear(_detail)
		_clear(_detail_actions)
		var secret := UITheme.make_label("???",28,UITheme.ACCENT)
		_detail.add_child(secret)
		var message := UITheme.make_label("เส้นทางที่ยังไม่ถูกเปิดเผย\n\nชื่อและทักษะของอาชีพนี้จะปรากฏเมื่อเปลี่ยนอาชีพสำเร็จ",15,UITheme.TEXT_DIM)
		message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(message)
		_loadout()
		_status.text="อาชีพที่ยังไม่ถูกเปิดเผย"
		return
	for skill: SkillData in available:
		if _group(skill.id)==_category: _card(skill)
	if _tiles.is_empty():
		var empty := UITheme.make_label("ยังไม่มีทักษะของอาชีพนี้",14,UITheme.TEXT_DIM)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_grid.add_child(empty)
	_grid.set_nodes(_tiles)
	_show_popup()
	_loadout()

func _card(s: SkillData) -> void:
	var lv := PlayerState.skills.level_of(s.id)
	var can := PlayerState.skills.can_learn(s.id,PlayerState.stats)
	var selected := s.id==_selected
	var button := Button.new()
	button.name="Skill_"+String(s.id)
	button.position=_grid.node_position(s.id)
	button.size=_grid.NODE_SIZE
	button.add_theme_stylebox_override("normal",UITheme.panel_style(Color("#253e4b") if selected else Color("#172735"),UITheme.ACCENT if selected else (Color("#528d83") if lv>0 else Color("#4b5666")),8,2,6))
	button.add_theme_stylebox_override("hover",UITheme.panel_style(Color("#304759"),UITheme.ACCENT,8,2,6))
	button.pressed.connect(func(): _select(s.id))
	button.tooltip_text=s.display_name+"\n"+s.requirement_text()
	_grid.add_child(button)
	_tiles[s.id]=button
	var icon := TextureRect.new()
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.texture=s.icon
	icon.position=Vector2(7,5)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size=Vector2(38,38)
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if lv==0: icon.modulate=Color(0.65,0.7,0.8)
	button.add_child(icon)
	icon.set_deferred("size",Vector2(38,38))
	var rank := UITheme.make_label("%d / %d"%[lv,s.max_level],13,UITheme.GOOD if lv>0 else UITheme.TEXT_DIM)
	rank.position=Vector2(51,13)
	rank.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(rank)
	var plus := UITheme.make_button("+" if lv<s.max_level else "✓")
	plus.name="QuickLearn_"+String(s.id)
	plus.position=Vector2(115,7)
	plus.custom_minimum_size=Vector2(29,29)
	plus.size=Vector2(29,29)
	plus.disabled=not can
	plus.tooltip_text="อัปเกรด • 1 แต้มของ "+GROUPS[_group(s.id)] if can else PlayerState.skills.learn_blocker(s.id,PlayerState.stats)
	plus.pressed.connect(func(): _learn(s.id))
	button.add_child(plus)
	var label := UITheme.make_label(s.display_name,12,UITheme.TEXT)
	label.position=Vector2(7,46)
	label.size=Vector2(138,26)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	for prerequisite in s.required_skills:
		var parent := StringName(prerequisite)
		if _group(parent)==_category: continue
		var jump := UITheme.make_button("← %s %d"%[GameData.get_skill(parent).display_name.split(" (")[0],int(s.required_skills[prerequisite])])
		jump.position=button.position+Vector2(0,81)
		jump.add_theme_font_size_override("font_size",10)
		jump.pressed.connect(func(): _category=_group(parent); _select(parent))
		_grid.add_child(jump)

func _select(id: StringName) -> void:
	_selected=id
	refresh()
	if _tiles.has(id): _scroll.ensure_control_visible(_tiles[id])

func _learn(id: StringName) -> void:
	_selected=id
	PlayerState.learn_skill(id)
	refresh()

## Kept as an internal name for callers; details now live inside this window.
func _show_popup() -> void:
	_clear(_detail)
	_clear(_detail_actions)
	var skill := GameData.get_skill(_selected)
	if skill==null: return
	var book := PlayerState.skills
	var lv := book.level_of(_selected)
	var title := UITheme.make_label(skill.display_name,20,UITheme.ACCENT)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_detail.add_child(title)
	var body := RichTextLabel.new()
	body.bbcode_enabled=true
	body.fit_content=true
	body.scroll_active=false
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size",14)
	body.text=describe(skill,lv)
	_detail.add_child(body)
	if lv<skill.max_level:
		var next := "เลเวล %d → %d"%[lv,lv+1]
		if skill.damage_mult(maxi(1,lv))>0 and skill.type not in [SkillData.SkillType.PASSIVE,SkillData.SkillType.BUFF]:
			next += "  •  ดาเมจ %.0f%% → %.0f%%"%[skill.damage_mult(maxi(1,lv))*100,skill.damage_mult(lv+1)*100]
		var preview := UITheme.make_label(next,13,UITheme.GOOD)
		preview.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_detail_actions.add_child(preview)
	var can := book.can_learn(_selected,PlayerState.stats)
	var upgrade := UITheme.make_button("เรียนสกิล • 1 แต้ม" if lv==0 else ("เลเวลสูงสุดแล้ว" if lv>=skill.max_level else "อัปเกรดเป็น Lv.%d • 1 แต้ม"%(lv+1)))
	upgrade.name="UpgradeSkill"
	upgrade.custom_minimum_size.y=42
	upgrade.disabled=not can
	upgrade.pressed.connect(func(): _learn(skill.id))
	_detail_actions.add_child(upgrade)
	if not can and lv<skill.max_level:
		var reason := UITheme.make_label(book.learn_blocker(_selected,PlayerState.stats),13,UITheme.BAD)
		reason.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_detail_actions.add_child(reason)

func _loadout() -> void:
	_clear(_hotbar)
	var selected_skill := GameData.get_skill(_selected)
	var assignable := selected_skill!=null and selected_skill.type!=SkillData.SkillType.PASSIVE and PlayerState.skills.is_learned(_selected)
	_status.text="ติดตั้ง %s → กดช่อง 1–4 ด้านล่าง"%selected_skill.display_name if assignable else "กด + บนผังเพื่ออัปเกรด • เส้นเชื่อมแสดงสกิลที่ต้องเรียนก่อน"
	for i in range(SkillBook.HOTKEY_COUNT):
		var index := i
		var id := PlayerState.skills.hotkey_at(i)
		var s := GameData.get_skill(id)
		var col := VBoxContainer.new()
		col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_hotbar.add_child(col)
		var button := UITheme.make_button("%d  %s"%[i+1,s.display_name if s!=null else "ช่องว่าง"])
		button.name="Hotkey%d"%(i+1)
		button.custom_minimum_size=Vector2(100,42)
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override("font_size",12)
		button.disabled=not assignable
		button.tooltip_text="ใส่สกิลที่เลือกในช่อง %d%s"%[i+1," (แทน "+s.display_name+")" if s!=null else ""]
		button.pressed.connect(func(): _assign_hotkey(index))
		col.add_child(button)
		var clear := UITheme.make_button("ถอดออก" if s!=null else "—")
		clear.add_theme_font_size_override("font_size",10)
		clear.disabled=s==null
		clear.pressed.connect(func(): PlayerState.skills.set_hotkey(index,&""); refresh())
		col.add_child(clear)

func _assign_hotkey(index: int) -> void:
	var skill := GameData.get_skill(_selected)
	if skill==null or skill.type==SkillData.SkillType.PASSIVE or not PlayerState.skills.is_learned(_selected): return
	PlayerState.skills.set_hotkey(index,_selected)
	refresh()

func shell_hints() -> Array:
	return [["K","ปิดสกิล"],["คลิก","เลือกสกิล / ติดตั้งช่องลัด"]]

## ★ รอบ 56 ★ บรรทัด "โดนกี่ตัว" + บอกว่าเลเวลไหนจะเพิ่มอีก
static func _targets_line(s: SkillData, lv: int, unlimited_text: String) -> String:
	var n: int = s.max_targets_at(lv)
	var text: String = unlimited_text if n <= 0 else "โดนสูงสุด %d ตัว" % n
	if s.max_targets_by_level.is_empty():
		return text
	# หาเลเวลถัดไปที่จำนวนตัวเพิ่มขึ้น
	var next_level := -1
	var next_count := n
	for k in s.max_targets_by_level.keys():
		var need := int(k)
		if need > lv and int(s.max_targets_by_level[k]) > n:
			if next_level < 0 or need < next_level:
				next_level = need
				next_count = int(s.max_targets_by_level[k])
	if next_level > 0:
		text += "  (เลเวล %d → %d ตัว)" % [next_level, next_count]
	return text


## ข้อความรายละเอียดสกิล (BBCode เหมือนกล่องไอเทม)
static func describe(s: SkillData, learned_level: int) -> String:
	var lv: int = maxi(1, learned_level)
	var lines: Array[String] = []

	lines.append("[color=#9aa7bd]ประเภท :[/color] %s" % _type_name(s.type))
	lines.append("[color=#9aa7bd]เลเวลสกิล :[/color] %s%d / %d[/color]"
		% ["[color=#7dffa8]" if learned_level > 0 else "[color=#9aa7bd]",
			learned_level, s.max_level])

	# ---------- เงื่อนไข ----------
	var req := s.requirement_text()
	if req != "":
		var ok: bool = PlayerState.skills.learn_blocker(s.id, PlayerState.stats) == ""
		lines.append("[color=#9aa7bd]เงื่อนไข :[/color] [color=%s]%s[/color]"
			% ["#7dffa8" if ok or learned_level > 0 else "#ff7d7d", req])

	# ---------- ค่าพลังตามชนิดสกิล ----------
	var stats_lines: Array[String] = []
	match s.type:
		SkillData.SkillType.HEAL:
			stats_lines.append("ฟื้นเลือด %d" % s.heal_amount(lv, PlayerState.stats.total_int))
		SkillData.SkillType.BUFF:
			var vals := s.buff_values(lv)
			for k in vals.keys():
				stats_lines.append("%s %+.0f" % [k, vals[k]])
			stats_lines.append("นาน %.0f วินาที" % s.duration(lv))
		SkillData.SkillType.PASSIVE:
			var pv := s.passive_values(lv)
			for k in pv.keys():
				stats_lines.append("%s %+.0f (ติดตัวตลอด)" % [k, pv[k]])
		SkillData.SkillType.ACTIVE_DASH:
			stats_lines.append("ดาเมจ %.0f%% ต่อตัว" % (s.damage_mult(lv) * 100.0))
			stats_lines.append("พุ่งไกล %.0f px" % s.dash_range(lv))
			stats_lines.append(_targets_line(s, lv, "โดนทุกตัวที่ขวางทาง (ตัวละ 1 ครั้ง)"))
		SkillData.SkillType.ACTIVE_WAVE:
			stats_lines.append("ดาเมจกายภาพ %.0f%% · ตัวละ 1 ครั้ง" % (s.damage_mult(lv) * 100.0))
			stats_lines.append("คลื่นไกล %.0f px · ทะลุ %d ตัว" % [s.wave_distance, s.max_targets_at(lv)])
			stats_lines.append("เปิดแผล: รับดาเมจกายภาพ +%.1f%% นาน %.0f วิ" % [s.wound_bonus(lv) * 100.0, s.wound_duration])
		_:
			stats_lines.append("ดาเมจ %.0f%%%s"
				% [s.damage_mult(lv) * 100.0,
					"  x%d ครั้ง" % s.hit_count if s.hit_count > 1 else ""])
			if s.max_targets_at(lv) > 0 or not s.max_targets_by_level.is_empty():
				stats_lines.append(_targets_line(s, lv, ""))
	if s.id in SkillBook.RUNE_SKILLS:
		stats_lines.clear()
		match s.id:
			&"runic_vessel": stats_lines.append("Max HP +%d%% / Max SP +%d%%"%[lv*2,lv*3])
			&"rune_guard": stats_lines.append("โล่ %.0f%% Max HP · 3 วินาที"%((0.02+lv*0.02)*100))
			&"blade_rhythm": stats_lines.append("ASPD +%.1f%% ต่อชั้น · สูงสุด 5 ชั้น"%(lv*0.6))
			&"keen_inscription": stats_lines.append("โอกาสคริ +%d จุดเปอร์เซ็นต์ · ตัวคูณคริ +%.2f"%[lv*2,lv*0.04])
			&"unbroken_edge": stats_lines.append("ใช้ 3 ตรา · ASPD +%d%% · 8 วินาที"%(lv*5))
			&"tempered_might": stats_lines.append("ดาบหนัก +%d%% · มองข้าม DEF %d%%"%[lv*4,lv*5])
			&"ninth_vessel": stats_lines.append("Max HP +%d%% / Max SP +%d%%\nLv.5: เก็บตรารูนได้ 4 ดวง"%[lv*3,lv*4])
			&"named_edge": stats_lines.append("โอกาสคริ +%d จุดเปอร์เซ็นต์ · มองข้าม DEF %d%%"%[lv*3,lv*6])
			&"twin_inscription": stats_lines.append("ใช้ 2 ตรา · เงาดาบ %.0f%% ATK · 6 วินาที"%((0.45+0.05*lv)*100))
			&"wallbreaker_stance": stats_lines.append("ดาเมจ +%.1f%% เมื่อเป้าหมายมี DEF ≥ 100"%(13.0+2.4*lv))
			&"ninth_inscription": stats_lines.append("ใช้ 4 ตรา · วงสลัก 3 วินาที\nระเบิด %.0f%% ATK"%((20.0+2.0*(lv-1))*100))
			_: stats_lines.append("ดาเมจรวมทั้งท่า %.0f%% ATK"%(s.damage_mult(lv)*100))
	if not stats_lines.is_empty():
		var head: String = "ค่าตอนนี้" if learned_level > 0 else "ค่าที่เลเวล 1"
		lines.append("[color=#9aa7bd]%s :[/color]" % head)
		lines.append("[color=#7dffa8]%s[/color]" % "\n".join(stats_lines))

	# ---------- ค่าใช้จ่าย ----------
	if s.type != SkillData.SkillType.PASSIVE:
		var cooldown := s.cooldown * (1.0-PlayerState.stats.cooldown_reduction/100.0)
		lines.append("[color=#9aa7bd]ใช้ SP :[/color] %d        [color=#9aa7bd]คูลดาวน์ :[/color] %.1f วิ"
			% [s.sp_cost(lv), cooldown])
		if PlayerState.stats.cooldown_reduction>0:
			lines.append("[color=#9aa7bd]คูลดาวน์พื้นฐาน %.1f วิ • รวมผลลดคูลดาวน์แล้ว[/color]"%s.cooldown)

	# ---------- คำอธิบาย ----------
	if s.description != "":
		lines.append("")
		lines.append("[color=#c8d0e0]%s[/color]" % s.description)

	return "\n".join(lines)


static func _type_name(t: int) -> String:
	match t:
		SkillData.SkillType.ACTIVE_MELEE: return "โจมตี"
		SkillData.SkillType.ACTIVE_AOE: return "รอบตัว"
		SkillData.SkillType.BUFF: return "บัฟ"
		SkillData.SkillType.HEAL: return "ฟื้นฟู"
		SkillData.SkillType.PASSIVE: return "ติดตัว"
		SkillData.SkillType.ACTIVE_DASH: return "พุ่งฟัน"
		SkillData.SkillType.ACTIVE_WAVE: return "คลื่นดาบ / เปิดแผล"
	return ""
