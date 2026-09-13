from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'scripts/ui/skill_window.gd'
b=ROOT/'output/balance_v2/before/scripts/ui/skill_window.gd'
b.parent.mkdir(parents=True,exist_ok=True)
if not b.exists():shutil.copy2(p,b)
s=p.read_text(encoding='utf-8')
def rep(a,b):
    global s
    assert a in s,a[:90]
    s=s.replace(a,b)
rep('var _grid: GridContainer','var _grid: Control')
rep('"ทักษะประจำอาชีพ"','"ผังทักษะประจำอาชีพ"')
rep('_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED','_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO')
rep('_scroll.custom_minimum_size = Vector2(300,220)','_scroll.custom_minimum_size = Vector2(530,220)')
a=s.index('\t_grid = GridContainer.new()');b=s.index('\t_scroll.add_child(_grid)',a)
s=s[:a]+'''\t_grid = preload("res://scripts/ui/skill_tree_canvas.gd").new()
\t_grid.custom_minimum_size=Vector2(530,378)
'''+s[b:]
rep('detail_panel.size_flags_stretch_ratio = 0.85','detail_panel.size_flags_stretch_ratio = 0.72')
rep('PlayerState.stats.job_id!=&"ninth_edge"','not PlayerState.stats.has_profession(&"ninth_edge")')
rep('st.job_id!=&"ninth_edge"','not st.has_profession(&"ninth_edge")')
rep('\t_point_label.text = "%d แต้ม  |  Job %d/%d" % [st.skill_points,st.job_level,st.max_job_level()]\n','')
rep('\t# Show the profession', '''\tvar owner: StringName=[&"swordsman",&"runeblade",&"ninth_edge"][_category]
\tvar record := st.profession_state(owner)
\t_point_label.text="%s • Job %d • %d แต้ม"%[GROUPS[_category],int(record.level),int(record.points)] if st.has_profession(owner) else "ยังไม่ได้เปลี่ยนอาชีพ"
\t# Show the profession''')
rep('\t_tiles.clear()','\t_tiles.clear()\n\t_grid.set_nodes(_tiles)')
rep('\t_show_popup()\n\t_loadout()','\t_grid.set_nodes(_tiles)\n\t_show_popup()\n\t_loadout()')
a=s.index('func _card(');b=s.index('\nfunc _select(',a)
s=s[:a]+'''func _card(s: SkillData) -> void:
\tvar lv := PlayerState.skills.level_of(s.id)
\tvar can := PlayerState.skills.can_learn(s.id,PlayerState.stats)
\tvar selected := s.id==_selected
\tvar button := Button.new()
\tbutton.name="Skill_"+String(s.id)
\tbutton.position=_grid.node_position(s.id)
\tbutton.size=_grid.NODE_SIZE
\tbutton.add_theme_stylebox_override("normal",UITheme.panel_style(Color("#253e4b") if selected else Color("#172735"),UITheme.ACCENT if selected else (Color("#528d83") if lv>0 else Color("#4b5666")),8,2,6))
\tbutton.add_theme_stylebox_override("hover",UITheme.panel_style(Color("#304759"),UITheme.ACCENT,8,2,6))
\tbutton.pressed.connect(func(): _select(s.id))
\tbutton.tooltip_text=s.display_name+"\\n"+s.requirement_text()
\t_grid.add_child(button)
\t_tiles[s.id]=button
\tvar icon := TextureRect.new()
\ticon.texture=s.icon
\ticon.position=Vector2(7,5)
\ticon.size=Vector2(38,38)
\ticon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
\ticon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
\ticon.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tif lv==0: icon.modulate=Color(0.65,0.7,0.8)
\tbutton.add_child(icon)
\tvar rank := UITheme.make_label("%d / %d"%[lv,s.max_level],13,UITheme.GOOD if lv>0 else UITheme.TEXT_DIM)
\trank.position=Vector2(51,13)
\trank.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tbutton.add_child(rank)
\tvar plus := UITheme.make_button("+" if lv<s.max_level else "✓")
\tplus.name="QuickLearn_"+String(s.id)
\tplus.position=Vector2(115,7)
\tplus.custom_minimum_size=Vector2(29,29)
\tplus.size=Vector2(29,29)
\tplus.disabled=not can
\tplus.tooltip_text="อัปเกรด • 1 แต้มของ "+GROUPS[_group(s.id)] if can else PlayerState.skills.learn_blocker(s.id,PlayerState.stats)
\tplus.pressed.connect(func(): _learn(s.id))
\tbutton.add_child(plus)
\tvar label := UITheme.make_label(s.display_name,12,UITheme.TEXT)
\tlabel.position=Vector2(7,46)
\tlabel.size=Vector2(138,30)
\tlabel.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
\tlabel.mouse_filter=Control.MOUSE_FILTER_IGNORE
\tbutton.add_child(label)
\tfor prerequisite in s.required_skills:
\t\tvar parent := StringName(prerequisite)
\t\tif _group(parent)==_category: continue
\t\tvar jump := UITheme.make_button("← %s %d"%[GameData.get_skill(parent).display_name.split(" (")[0],int(s.required_skills[prerequisite])])
\t\tjump.position=button.position+Vector2(0,81)
\t\tjump.add_theme_font_size_override("font_size",10)
\t\tjump.pressed.connect(func(): _category=_group(parent); _select(parent))
\t\t_grid.add_child(jump)
'''+s[b:]
rep('\t_selected=id\n\trefresh()','\t_selected=id\n\trefresh()\n\tif _tiles.has(id): _scroll.ensure_control_visible(_tiles[id])')
rep('"อัปเกรดเป็น Lv.%d • 1 แต้ม"','"อัปเกรดเป็น Lv.%d • 1 แต้ม"')
rep('"เลือกสกิล แล้วกดช่องด้านล่างเพื่อติดตั้ง"','"กด + บนผังเพื่ออัปเกรด • คลิกสกิลเพื่ออ่านและติดตั้ง"')
rep('"สกิลติดตัวทำงานอัตโนมัติ • เรียนสกิลกดใช้แล้วเลือกช่องเพื่อติดตั้ง"','"กด + บนผังเพื่ออัปเกรด • เส้นเชื่อมแสดงสกิลที่ต้องเรียนก่อน"')
p.write_text(s,encoding='utf-8')
print('Skill tree with direct upgrade controls and per-profession points installed.')
