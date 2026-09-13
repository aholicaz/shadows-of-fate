from pathlib import Path
import shutil
p=Path('scripts/ui/skill_window.gd')
old=p.read_text(encoding='utf-8-sig')
backup=Path('output/balance/original/scripts/ui/skill_window.gd')
backup.parent.mkdir(parents=True,exist_ok=True)
if not backup.exists(): shutil.copy2(p,backup)
tail=old[old.index('## ★ รอบ 56 ★ บรรทัด'):]
head='''## Skill library, inline upgrade details and a persistent four-slot loadout.
class_name SkillWindow
extends GameWindow

const GROUPS := ["ทั้งหมด", "นักดาบ", "รูนพื้นฐาน", "ตีไว / คริ", "สกิลหนัก", "อักขระที่เก้า"]
const SPEED := [&"blade_rhythm", &"keen_inscription", &"rune_flurry", &"unbroken_edge"]
const HEAVY := [&"tempered_might", &"anvil_cleave", &"faultline", &"worldcleaver"]
var _selected: StringName = &""
var _category := 0
var _tiles: Dictionary = {}
var _filters: Array[Button] = []
var _point_label: Label
var _grid: GridContainer
var _detail: VBoxContainer
var _hotbar: HBoxContainer
var _scroll: ScrollContainer
var _status: Label

func _ready() -> void:
\twindow_title = "สกิลและชุดต่อสู้"
\tsuper._ready()
\tif not embedded: custom_minimum_size = Vector2(760,560)
\tEvents.skills_changed.connect(refresh)
\tEvents.stats_changed.connect(refresh)

func _build_content() -> void:
\tcontent.add_theme_constant_override("separation",10)
\tvar heading := HBoxContainer.new()
\tcontent.add_child(heading)
\tvar title := UITheme.make_label("เลือกสกิล • สร้างสไตล์ต่อสู้",20,UITheme.TEXT)
\ttitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\theading.add_child(title)
\t_point_label = UITheme.make_label("",16,UITheme.GOOD)
\theading.add_child(_point_label)
\tvar tabs := HFlowContainer.new()
\ttabs.add_theme_constant_override("h_separation",5)
\tcontent.add_child(tabs)
\tfor i in range(GROUPS.size()):
\t\tvar index := i
\t\tvar button := UITheme.make_button(GROUPS[i])
\t\tbutton.toggle_mode = true
\t\tbutton.add_theme_font_size_override("font_size",13)
\t\tbutton.pressed.connect(func(): _category=index; refresh())
\t\ttabs.add_child(button)
\t\t_filters.append(button)
\tvar body := HBoxContainer.new()
\tbody.size_flags_vertical = Control.SIZE_EXPAND_FILL
\tbody.add_theme_constant_override("separation",12)
\tcontent.add_child(body)
\t_scroll = ScrollContainer.new()
\t_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
\t_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
\t_scroll.custom_minimum_size = Vector2(300,220)
\tbody.add_child(_scroll)
\t_grid = GridContainer.new()
\t_grid.columns = 2
\t_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t_grid.add_theme_constant_override("h_separation",8)
\t_grid.add_theme_constant_override("v_separation",8)
\t_scroll.add_child(_grid)
\tvar detail_panel := PanelContainer.new()
\tdetail_panel.custom_minimum_size.x = 300
\tdetail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tdetail_panel.size_flags_stretch_ratio = 0.85
\tdetail_panel.add_theme_stylebox_override("panel",UITheme.inner_style(Color("#162438"),8,12))
\tbody.add_child(detail_panel)
\tvar detail_scroll := ScrollContainer.new()
\tdetail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
\tdetail_panel.add_child(detail_scroll)
\t_detail = VBoxContainer.new()
\t_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t_detail.add_theme_constant_override("separation",10)
\tdetail_scroll.add_child(_detail)
\t_status = UITheme.make_label("เลือกสกิล แล้วกดช่องด้านล่างเพื่อติดตั้ง",13,UITheme.TEXT_DIM)
\tcontent.add_child(_status)
\t_hotbar = HBoxContainer.new()
\t_hotbar.add_theme_constant_override("separation",8)
\tcontent.add_child(_hotbar)

func _clear(node: Node) -> void:
\tfor child in node.get_children():
\t\tnode.remove_child(child)
\t\tchild.queue_free()

func _group(id: StringName) -> int:
\tif id in SPEED: return 3
\tif id in HEAVY: return 4
\tif id in SkillBook.NINTH_SKILLS: return 5
\tif id in SkillBook.RUNE_SKILLS: return 2
\treturn 1

func refresh() -> void:
\tif _grid == null or PlayerState.skills == null: return
\tvar st := PlayerState.stats
\t_point_label.text = "%d แต้ม  |  Job %d/%d" % [st.skill_points,st.job_level,st.max_job_level()]
\tvar available := GameData.skills_for_job(st.job_id)
\tif _selected == &"" and not available.is_empty(): _selected=available[0].id
\tfor i in range(_filters.size()): _filters[i].set_pressed_no_signal(i==_category)
\t_clear(_grid)
\t_tiles.clear()
\tfor skill: SkillData in available:
\t\tif _category==0 or _group(skill.id)==_category: _card(skill)
\tif _tiles.is_empty():
\t\tvar empty := UITheme.make_label("ยังไม่มีสกิลในสายนี้สำหรับอาชีพปัจจุบัน",14,UITheme.TEXT_DIM)
\t\tempty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\t\t_grid.add_child(empty)
\t_show_popup()
\t_loadout()

func _card(s: SkillData) -> void:
\tvar lv := PlayerState.skills.level_of(s.id)
\tvar selected := s.id==_selected
\tvar can := PlayerState.skills.can_learn(s.id,PlayerState.stats)
\tvar button := Button.new()
\tbutton.name = "Skill_"+String(s.id)
\tbutton.custom_minimum_size = Vector2(138,112)
\tbutton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tbutton.add_theme_stylebox_override("normal",UITheme.panel_style(Color("#243d54") if selected else Color("#182538"), UITheme.ACCENT if selected else Color("#314456"),7,2,8))
\tbutton.add_theme_stylebox_override("hover",UITheme.panel_style(Color("#2b435b"),UITheme.ACCENT,7,2,8))
\tbutton.pressed.connect(func(): _select(s.id))
\t_grid.add_child(button)
\t_tiles[s.id]=button
\tvar box := VBoxContainer.new()
\tbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tbox.offset_left=9; box.offset_right=-9; box.offset_top=7; box.offset_bottom=-7
\tbox.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tbutton.add_child(box)
\tvar top := HBoxContainer.new()
\ttop.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tbox.add_child(top)
\tvar icon := TextureRect.new()
\ticon.texture=s.icon
\ticon.custom_minimum_size=Vector2(36,36)
\ticon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
\ticon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\ticon.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tif lv==0: icon.modulate=Color(0.65,0.7,0.8)
\ttop.add_child(icon)
\tvar rank := UITheme.make_label("%d / %d"%[lv,s.max_level],14,UITheme.GOOD if lv>0 else UITheme.TEXT_DIM)
\trank.size_flags_horizontal=Control.SIZE_EXPAND_FILL
\trank.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
\trank.mouse_filter=Control.MOUSE_FILTER_IGNORE
\ttop.add_child(rank)
\tvar name_label := UITheme.make_label(s.display_name,13,UITheme.TEXT)
\tname_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\tname_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tbox.add_child(name_label)
\tvar status := "อัปเกรดได้" if can else ("เรียนแล้ว" if lv>0 else "ยังล็อก")
\tif s.type==SkillData.SkillType.PASSIVE: status += " • ติดตัว"
\tvar hint := UITheme.make_label(status,11,UITheme.GOOD if can else UITheme.TEXT_DIM)
\thint.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tbox.add_child(hint)

func _select(id: StringName) -> void:
\t_selected=id
\trefresh()

func _learn(id: StringName) -> void:
\t_selected=id
\tPlayerState.learn_skill(id)
\trefresh()

## Kept as an internal name for callers; details now live inside this window.
func _show_popup() -> void:
\t_clear(_detail)
\tvar skill := GameData.get_skill(_selected)
\tif skill==null: return
\tvar book := PlayerState.skills
\tvar lv := book.level_of(_selected)
\tvar title := UITheme.make_label(skill.display_name,20,UITheme.ACCENT)
\ttitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\t_detail.add_child(title)
\tvar body := RichTextLabel.new()
\tbody.bbcode_enabled=true
\tbody.fit_content=true
\tbody.scroll_active=false
\tbody.size_flags_horizontal=Control.SIZE_EXPAND_FILL
\tbody.add_theme_font_size_override("normal_font_size",14)
\tbody.text=describe(skill,lv)
\t_detail.add_child(body)
\tif lv<skill.max_level:
\t\tvar next := "เลเวล %d → %d"%[lv,lv+1]
\t\tif skill.damage_mult(maxi(1,lv))>0 and skill.type not in [SkillData.SkillType.PASSIVE,SkillData.SkillType.BUFF]:
\t\t\tnext += "  •  ดาเมจ %.0f%% → %.0f%%"%[skill.damage_mult(maxi(1,lv))*100,skill.damage_mult(lv+1)*100]
\t\tvar preview := UITheme.make_label(next,13,UITheme.GOOD)
\t\tpreview.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\t\t_detail.add_child(preview)
\tvar can := book.can_learn(_selected,PlayerState.stats)
\tvar upgrade := UITheme.make_button("เรียนสกิล • 1 แต้ม" if lv==0 else ("เลเวลสูงสุดแล้ว" if lv>=skill.max_level else "อัปเกรดเป็น Lv.%d • 1 แต้ม"%(lv+1)))
\tupgrade.name="UpgradeSkill"
\tupgrade.custom_minimum_size.y=42
\tupgrade.disabled=not can
\tupgrade.pressed.connect(func(): _learn(skill.id))
\t_detail.add_child(upgrade)
\tif not can and lv<skill.max_level:
\t\tvar reason := UITheme.make_label(book.learn_blocker(_selected,PlayerState.stats),13,UITheme.BAD)
\t\treason.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\t\t_detail.add_child(reason)

func _loadout() -> void:
\t_clear(_hotbar)
\tvar selected_skill := GameData.get_skill(_selected)
\tvar assignable := selected_skill!=null and selected_skill.type!=SkillData.SkillType.PASSIVE and PlayerState.skills.is_learned(_selected)
\t_status.text="ติดตั้ง %s → กดช่อง 1–4 ด้านล่าง"%selected_skill.display_name if assignable else "สกิลติดตัวทำงานอัตโนมัติ • เรียนสกิลกดใช้แล้วเลือกช่องเพื่อติดตั้ง"
\tfor i in range(SkillBook.HOTKEY_COUNT):
\t\tvar index := i
\t\tvar id := PlayerState.skills.hotkey_at(i)
\t\tvar s := GameData.get_skill(id)
\t\tvar col := VBoxContainer.new()
\t\tcol.size_flags_horizontal=Control.SIZE_EXPAND_FILL
\t\t_hotbar.add_child(col)
\t\tvar button := UITheme.make_button("%d  %s"%[i+1,s.display_name if s!=null else "ช่องว่าง"])
\t\tbutton.name="Hotkey%d"%(i+1)
\t\tbutton.custom_minimum_size=Vector2(100,42)
\t\tbutton.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
\t\tbutton.add_theme_font_size_override("font_size",12)
\t\tbutton.disabled=not assignable
\t\tbutton.tooltip_text="ใส่สกิลที่เลือกในช่อง %d%s"%[i+1," (แทน "+s.display_name+")" if s!=null else ""]
\t\tbutton.pressed.connect(func(): _assign_hotkey(index))
\t\tcol.add_child(button)
\t\tvar clear := UITheme.make_button("ถอดออก" if s!=null else "—")
\t\tclear.add_theme_font_size_override("font_size",10)
\t\tclear.disabled=s==null
\t\tclear.pressed.connect(func(): PlayerState.skills.set_hotkey(index,&""); refresh())
\t\tcol.add_child(clear)

func _assign_hotkey(index: int) -> void:
\tvar skill := GameData.get_skill(_selected)
\tif skill==null or skill.type==SkillData.SkillType.PASSIVE or not PlayerState.skills.is_learned(_selected): return
\tPlayerState.skills.set_hotkey(index,_selected)
\trefresh()

func shell_hints() -> Array:
\treturn [["K","ปิดสกิล"],["คลิก","เลือกสกิล / ติดตั้งช่องลัด"]]

'''
p.write_text(head+tail,encoding='utf-8')
