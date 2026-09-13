extends Node2D
var player
var caption: Label
var checks := 0
var failures := 0

func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: ",text)
	else:
		failures += 1
		push_error(text)

func _draw() -> void:
	draw_rect(Rect2(0,0,1600,1000),Color("#0c1625"))
	draw_rect(Rect2(0,575,1600,425),Color("#1b2c38"))
	draw_line(Vector2(0,575),Vector2(1600,575),Color("#668d9f"),3)
	for x in range(0,1600,80): draw_line(Vector2(x,575),Vector2(x+70,1000),Color("#223b49"),1)

func shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/balance/"+name+".png")

func _ready() -> void:
	get_tree().create_timer(45).timeout.connect(func(): push_error("BALANCE PREVIEW TIMEOUT"); get_tree().quit(1))
	get_window().mode=Window.MODE_WINDOWED
	get_window().size=Vector2i(1280,720)
	get_window().content_scale_size=Vector2i(1280,720)
	PlayerState.new_game()
	PlayerState.set_process(false)
	PlayerState.stats.job_id=&"runeblade"
	PlayerState.stats.level=70
	PlayerState.stats.job_level=60
	PlayerState.stats.skill_points=12
	PlayerState.stats.base_str=65
	PlayerState.stats.base_agi=55
	PlayerState.stats.base_dex=45
	PlayerState.skills.learned={&"slash":5,&"blade_rhythm":5,&"keen_inscription":5,&"rune_flurry":3,&"tempered_might":5,&"anvil_cleave":5,&"faultline":5,&"worldcleaver":3,&"runic_vessel":3}
	PlayerState.refresh()
	UI.shell.open_tab("skills")
	var skills: SkillWindow=UI.windows[&"skills"]
	check(skills._filters[2].text=="???","future profession name stays secret before promotion")
	skills._filters[2].pressed.emit()
	check(skills._tiles.is_empty() and skills._selected==&"" and skills._detail_actions.get_child_count()==0,"secret profession exposes no skills, details or upgrade actions")
	await shot("skill_window_secret")
	PlayerState.stats.job_id=&"ninth_edge"
	skills.refresh()
	check(skills._filters[2].text=="Ninth Edge" and skills._tiles.has(&"ninth_inscription"),"promotion reveals the profession and its skills")
	skills._select(&"ninth_inscription")
	await shot("skill_window_promoted")
	PlayerState.stats.job_id=&"runeblade"
	skills._category=1
	skills._select(&"rune_lunge")
	await get_tree().create_timer(0.2).timeout
	check(skills._tiles.has(&"rune_lunge") and not skills._tiles.has(&"slash"),"Runeblade page contains its skills without mixing professions")
	var before:=PlayerState.stats.skill_points
	var upgrade: Button=skills.find_child("UpgradeSkill",true,false)
	check(upgrade!=null and not upgrade.disabled,"inline learn button is enabled for valid prerequisites")
	upgrade.pressed.emit()
	check(PlayerState.skills.level_of(&"rune_lunge")==1 and PlayerState.stats.skill_points==before-1,"UI learn spends exactly one point")
	var slot: Button=skills.find_child("Hotkey2",true,false)
	slot.pressed.emit()
	check(PlayerState.skills.hotkey_at(1)==&"rune_lunge","bottom slot button installs selected skill")
	skills._select(&"tempered_might")
	skills._assign_hotkey(0)
	check(PlayerState.skills.hotkey_at(0)!=&"tempered_might","passive skill cannot enter active loadout")
	skills._category=1
	skills._select(&"rune_flurry")
	await get_tree().create_timer(0.2).timeout
	check(not UI.item_popup.visible,"skill details never open external item popup")
	check(UI.shell.frame.get_global_rect().encloses(skills._hotbar.get_global_rect()),"hotbar stays inside menu frame")
	check(UI.shell.frame.get_global_rect().encloses(skills._detail_actions.get_global_rect()),"upgrade controls stay visible inside the frame")
	await shot("skill_window")
	skills._category=1
	skills._select(&"worldcleaver")
	await get_tree().create_timer(0.1).timeout
	await shot("skill_window_heavy")
	# Render effects against actual game character proportions, facing both ways.
	UI.shell.close()
	UI.layer.hide()
	var gallery := VBoxContainer.new()
	gallery.position=Vector2(36,20)
	gallery.add_theme_constant_override("separation",16)
	add_child(gallery)
	gallery.add_child(UITheme.make_label("Skill icon review · 96 px",24,Color("#dfedff")))
	var icon_grid := GridContainer.new()
	icon_grid.columns=6
	icon_grid.add_theme_constant_override("h_separation",12)
	icon_grid.add_theme_constant_override("v_separation",12)
	gallery.add_child(icon_grid)
	var icons_ok := true
	for id in SkillBook.RUNE_SKILLS:
		var skill := GameData.get_skill(id)
		icons_ok = icons_ok and skill.icon!=null and skill.icon.get_width()==256 and skill.icon.get_height()==256
		var cell := VBoxContainer.new()
		cell.custom_minimum_size=Vector2(185,164)
		icon_grid.add_child(cell)
		var texture := TextureRect.new()
		texture.texture=skill.icon
		texture.custom_minimum_size=Vector2(96,96)
		texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(texture)
		var label := UITheme.make_label(skill.display_name,14,Color("#dfedff"))
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(label)
	check(icons_ok,"all 17 painted icons load at the native import limit of 256 px")
	await shot("skill_icon_gallery")
	gallery.queue_free()
	player=load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.position=Vector2(490,430)
	player.set_physics_process(false)
	caption=UITheme.make_label("",28,Color("#dfedff"))
	caption.position=Vector2(60,45)
	add_child(caption)
	for dir in [-1,1]:
		player.facing=dir
		player._update_facing()
		player.position=Vector2(490 if dir==1 else 790,430)
		for id in [&"faultline",&"worldcleaver"]:
			PlayerState.stats.sp=1000
			PlayerState.cooldowns.clear()
			player.runeblade.charges=3
			caption.text=GameData.get_skill(id).display_name+"  /  "+("ซ้าย" if dir<0 else "ขวา")
			player.runeblade.cast(id)
			await get_tree().create_timer(0.7 if id==&"faultline" else 1.05).timeout
			await shot(String(id)+("_left" if dir<0 else "_right"))
			await get_tree().create_timer(2.2).timeout
		PlayerState.stats.sp=1000
		PlayerState.cooldowns.clear()
		caption.text="พุ่งกรีดอักขระ  /  "+("ซ้าย" if dir<0 else "ขวา")
		player.runeblade.cast(&"rune_lunge")
		for frame in range(14):
			await get_tree().physics_frame
			if player._dash_time>0: player._dash_step(1.0/60)
		await shot("lunge"+("_left" if dir<0 else "_right"))
		for frame in range(35):
			await get_tree().physics_frame
			if player._dash_time>0: player._dash_step(1.0/60)
	player.queue_free()
	await get_tree().process_frame
	print("BALANCE UI PREVIEW: %d checks; failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
