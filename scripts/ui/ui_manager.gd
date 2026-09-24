## UI — ตัวจัดการหน้าจอทั้งหมด (Autoload ชื่อ "UI")
## สร้าง HUD และหน้าต่างทุกบานด้วยโค้ด ไม่ต้องจัด Scene เอง
## หมายเหตุ: ไฟล์นี้ห้ามใส่ class_name เพราะจะชนกับชื่อ Autoload
extends Node

var layer: CanvasLayer
var hud: HUD
var boss_bar: BossBar
var confirm: ConfirmDialog
var card_popup: CardGetPopup
var item_popup: ItemInfoPopup
## ★ กล่องสนทนาแบบมีรูปตัวละคร ★
var dialogue: DialogueBox
## ★ ปุ่มจอสัมผัสสำหรับมือถือ ★
var touch: TouchControls
var hotbar: HotbarBar   # ★ รอบ 168 ★
## ★ แผนที่ย่อมุมขวาบน ★
## ★ แถบปุ่มไอคอนใต้มินิแมพ ★
var menu_bar: IconMenuBar
## ★ หน้าจอตอนตาย (คำอวยพรจากธอร์ + ปุ่มเกิดใหม่) ★
var death_popup: DeathPopup
var windows: Dictionary = {}   # StringName -> GameWindow
## ★ รอบ 98 ★ หน้าต่างรวมแบบแท็บ (สเตตัส/สวมใส่/กระเป๋า/สกิล/การ์ด/เควส/แผนที่/ระบบ)
var shell: MenuShell
## แท็บไหนใช้หน้าต่าง id ไหน
## ★ รอบ 102 ★ เอาแท็บ "equipment" ออก — ชี้หน้าต่างเดียวกับ "status" อยู่แล้ว
## (ถ้าปล่อยไว้ register_page จะตั้ง shell_tab ของหน้านั้นเป็น "equipment" ซึ่งไม่มีปุ่มแท็บแล้ว
##  → กด C เปิดได้แต่ไม่มีแท็บไหนสว่าง) · ปุ่ม C ยังเปิดหน้าเดิมผ่าน windows[&"equipment"]
const SHELL_TABS := {
	"status": &"equipment", "inventory": &"inventory", "skills": &"skills",
	"cards": &"cards", "quests": &"quests", "map": &"map", "system": &"system",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	layer = CanvasLayer.new()
	layer.name = "UILayer"
	layer.layer = 100
	add_child(layer)

	var root := Control.new()
	root.name = "UIRoot"
	# ★ ต้อง _and_offsets_ ★ ไม่งั้นกรอบยังกว้าง 0 (ดูหมายเหตุใน hud.gd)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# ---------- HUD ----------
	hud = HUD.new()
	hud.name = "HUD"
	root.add_child(hud)

	# ---------- ★ หลอดเลือดบอสใบใหญ่ กลางจอด้านบน (รอบ 87) ★ ----------
	# โผล่เองเมื่อมีบอสอยู่ใกล้ ไม่ต้องเรียกจากที่ไหน
	boss_bar = BossBar.new()
	root.add_child(boss_bar)

	# ---------- ★ มินิแมพ + แถบปุ่มไอคอน (มุมขวาบน) ★ ----------
	# ใส่ก่อนหน้าต่าง จะได้อยู่หลังหน้าต่างเวลาเปิดทับกัน

	menu_bar = IconMenuBar.new()
	root.add_child(menu_bar)

	# ---------- ★ หน้าต่างรวม (รอบ 98) ★ ใส่ก่อนหน้าต่างลอย (ร้านค้า/ตีบวก) จะได้อยู่ใต้พวกนั้น ----------
	shell = MenuShell.new()
	root.add_child(shell)

	# ---------- หน้าต่างต่าง ๆ ----------
	# ★ รอบ 45 — หน้าสวมใส่ + สเตตัส รวมเป็นหน้าเดียว ★ id "status" กับ "equipment" ชี้หน้าต่างเดียวกัน (C หรือ E เปิดได้ทั้งคู่)
	_add_window(&"equipment", EquipmentWindow.new(), Vector2(30, 60))
	windows[&"status"] = windows[&"equipment"]
	_add_window(&"inventory", InventoryWindow.new(), Vector2(830, 60))
	# ★ ผังสกิลวางชิดซ้าย ★ เผื่อที่ให้กล่องรายละเอียดเด้งอยู่ข้างขวาได้ ไม่ต้องมาทับผัง
	_add_window(&"skills", SkillWindow.new(), Vector2(60, 110))
	_add_window(&"shop", ShopWindow.new(), Vector2(500, 70))
	_add_window(&"refine", RefineWindow.new(), Vector2(500, 70))
	_add_window(&"craft", CraftWindow.new(), Vector2(110, 16))   # ★ รอบ 132 ★ คราฟต์
	_add_window(&"card_fusion", CardFusionWindow.new(), Vector2(110, 16))   # ★ รอบ 154 ★ ย่อยการ์ด
	_add_window(&"guild_rank", GuildRankWindow.new(), Vector2(130, 40))   # ★ รอบ 158 ★ ขั้นกิลด์
	_add_window(&"socket", SocketWindow.new(), Vector2(520, 90))
	_add_window(&"storage", StorageWindow.new(), Vector2(500, 70))   # ★ รอบ 122 ★ คลัง
	_add_window(&"cards", CardAlbumWindow.new(), Vector2(300, 60))
	_add_window(&"system", SystemWindow.new(), Vector2(420, 140))
	_add_window(&"quests", QuestWindow.new(), Vector2(340, 100))
	# ★ รอบ 98 — หน้าแผนที่ใหญ่ (แท็บ "แผนที่") ★
	# ★ รอบ 102 ★ แท็บแผนที่เปลี่ยนจากมินิแมพขยาย (MapPage) เป็นแผนที่โลก (WorldMapPage)
	# มินิแมพมุมจอยังอยู่เหมือนเดิม กด M เปิด/ปิดได้ · MapPage เดิมยังอยู่ในโปรเจกต์ ไม่ได้ลบ
	_add_window(&"map", WorldMapPage.new(), Vector2(300, 60))
	# ★ รอบ 80 — ห้องเครื่องมือ GM (F10) ★ ไม่มีปุ่มในเมนู เปิดด้วยปุ่มลัดอย่างเดียว
	if OS.is_debug_build(): _add_window(&"gm", GMWindow.new(), Vector2(340, 60))
	# ★ รอบ 163 ★ โรงตีเหล็ก (ตีบวก · เจาะรู · รูที่ 3 · คราฟต์ ในหน้าต่างเดียว) — ย้ายหน้าคราฟต์เดิมเข้าไปเป็นแท็บ
	var smith := BlacksmithWindow.new()
	_add_window(&"blacksmith", smith, Vector2(80, 40))
	smith.host_craft(windows[&"craft"] as CraftWindow)
	# ★ รอบ 163 ★ บอร์ดใบประกาศล่า (แทนเมนูในกล่องสนทนา)
	_add_window(&"bounty", BountyBoardWindow.new(), Vector2(110, 40))

	# ★ รอบ 98 ★ ย้ายหน้าต่างที่เป็นแท็บเข้าไปในหน้าต่างรวม
	for tab in SHELL_TABS.keys():
		var w: GameWindow = windows.get(SHELL_TABS[tab], null)
		if w != null:
			shell.register_page(String(tab), w)

	# ---------- กล่องรายละเอียดไอเทม (เด้งข้างหน้าต่าง) ----------
	item_popup = ItemInfoPopup.new()
	item_popup.name = "ItemInfoPopup"
	layer.add_child(item_popup)

	# ---------- popup ได้การ์ดใบใหม่ ----------
	card_popup = CardGetPopup.new()
	card_popup.name = "CardGetPopup"
	layer.add_child(card_popup)

	# ---------- ★ ปุ่มจอสัมผัส (มือถือ) ★ ----------
	# อยู่ใต้กล่องสนทนา/หน้าต่าง แต่เหนือเกม
	touch = TouchControls.new()
	layer.add_child(touch)
	# ★ รอบ 168 ★ แถบลัด 8 ช่อง (คอม) — โชว์เมื่อไม่ได้ใช้ปุ่มจอสัมผัส
	hotbar = HotbarBar.new()
	layer.add_child(hotbar)

	# ---------- ★ กล่องสนทนา ★ ----------
	# ใส่ที่ CanvasLayer โดยตรง จะได้อ้างขนาด "จอ" ตรง ๆ (กล่องกินเต็มจอ)
	dialogue = DialogueBox.new()
	dialogue.name = "DialogueBox"
	layer.add_child(dialogue)

	# ---------- ★ หน้าจอตอนตาย ★ ----------
	# ต้องอยู่เกือบบนสุด (ทับทุกอย่างยกเว้นกล่องยืนยัน)
	death_popup = DeathPopup.new()
	layer.add_child(death_popup)

	# ---------- กล่องยืนยัน ----------
	confirm = ConfirmDialog.new()
	confirm.name = "ConfirmDialog"
	# ใส่ไว้ที่ CanvasLayer โดยตรง (ไม่ใช่ใน UIRoot)
	# กล่องจะได้อ้างอิงขนาด "จอ" ตรง ๆ แล้วจัดตัวเองไว้กลางจอได้ถูกต้อง
	layer.add_child(confirm)

	Events.shop_opened.connect(_on_shop_opened)
	Events.refine_npc_opened.connect(_on_refine_opened)
	Events.craft_npc_opened.connect(_on_craft_opened)   # ★ รอบ 132 ★
	Events.card_fusion_opened.connect(_on_card_fusion_opened)   # ★ รอบ 154 ★
	Events.guild_rank_opened.connect(_on_guild_rank_opened)   # ★ รอบ 158 ★
	Events.socket_npc_opened.connect(_on_socket_opened)
	Events.storage_opened.connect(_on_storage_opened)   # ★ รอบ 122 ★
	Events.toggle_window.connect(toggle)


## ★ รอบ 88 ★ F11 สลับเต็มจอ ↔ หน้าต่าง (เต็มจอแบบ borderless ไม่กระพริบตอนสลับ alt-tab)
func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _add_window(id: StringName, window: GameWindow, pos: Vector2) -> void:
	window.name = String(id)
	window.position = pos
	window.hide()
	layer.get_node("UIRoot").add_child(window)
	windows[id] = window


# =========================================================
# ปุ่มลัด
# =========================================================
## ถามผู้เล่นแล้วรอคำตอบ — ใช้แบบ: var ok: bool = await UI.ask("หัวข้อ", "ข้อความ")
func ask(title: String, message: String, yes_text: String = "ตกลง", no_text: String = "ยกเลิก") -> bool:
	confirm.ask(title, message, yes_text, no_text)
	return await confirm.answered


## โชว์รายละเอียดไอเทมข้าง ๆ หน้าต่างที่กดมา
func show_item(inst: ItemInstance, anchor: Control = null, extra: String = "") -> void:
	if item_popup != null:
		item_popup.show_item(inst, anchor, extra)


## โชว์รายละเอียดจากแม่แบบไอเทม (ร้านค้า)
func show_item_data(d: ItemData, anchor: Control = null, extra: String = "") -> void:
	if item_popup != null:
		item_popup.show_data(d, anchor, extra)


## ★ เล่นบทสนทนา ★ ใช้แบบ: var pick: int = await UI.talk([{...}, {...}])
## รายละเอียดคีย์ของแต่ละบรรทัดดูที่หัวไฟล์ scripts/ui/dialogue_box.gd
func talk(script: Array) -> int:
	if dialogue == null:
		return -1
	return await dialogue.play(script)


## คุยประโยคเดียวจบ (ไม่มีตัวเลือก)
func say_as(speaker: String, text: String, portrait: Variant = null, side: int = 0) -> void:
	await talk([{"name": speaker, "text": text, "portrait": portrait, "side": side}])


## ★ โชว์กล่องรายละเอียดแบบกำหนดเอง (ใช้กับสกิล) ★ ใส่ปุ่มการกระทำมาด้วยได้
func show_info(title: String, art: Texture2D, body: String, anchor: Control = null,
		color: Color = UITheme.TEXT, actions: Array = []) -> void:
	if item_popup != null:
		item_popup.show_info(title, art, body, anchor, color, actions)


func hide_item_popup() -> void:
	if item_popup != null:
		item_popup.hide_popup()


## จุดที่คลิกทับหน้าต่าง/แผงบนจอหรือเปล่า
## ใช้กันไม่ให้ "คลิกซ้ายในหน้าต่างกระเป๋า" กลายเป็นการฟันดาบไปด้วย
func is_point_over_ui(point: Vector2) -> bool:
	if is_asking():
		return true
	# ★ รอบ 98 ★ หน้าต่างรวมเปิดอยู่ = มีม่านคลุมทั้งจอ คลิกตรงไหนก็ไม่ใช่การสั่งตีมอน
	if shell != null and shell.visible:
		return true
	# แตะปุ่มบนจอ = ไม่ใช่การสั่งตีมอน
	if touch != null and touch.is_over(point):
		return true
	if hotbar != null and hotbar.is_over(point):   # ★ รอบ 168 ★ คลิกแถบลัด = ไม่ใช่การสั่งตีมอน
		return true
	for w: GameWindow in windows.values():
		if w.is_visible_in_tree() and w.get_global_rect().has_point(point):   # ★ รอบ 163 ★
			return true
	if item_popup != null and item_popup.visible \
			and item_popup.get_global_rect().has_point(point):
		return true
	# ★ มินิแมพ + แถบปุ่มไอคอน ★ คลิกตรงนี้ไม่ใช่การสั่งตีมอน
	for p in [menu_bar]:
		if p != null and p.visible and p.get_global_rect().has_point(point):
			return true
	if hud != null:
		for p in [hud.top_panel, hud.bottom_panel, hud.hotkey_panel]:
			if p != null and p.visible and p.get_global_rect().has_point(point):
				return true
	return false


## ★ รอบ 98 ★ ไอคอนเล็กที่ยังไม่มีไฟล์ (ระบบวาดแทนให้ชั่วคราว) — ดูรายชื่อที่ PetrolWidgets.GLYPHS
func missing_ui_icons() -> Array[String]:
	return PetrolWidgets.missing_glyphs()


func is_asking() -> bool:
	if _warp_open: return true
	if death_popup != null and death_popup.is_open():
		return true
	if card_popup != null and card_popup.is_open():
		return true
	if dialogue != null and dialogue.is_open():
		return true
	return confirm != null and confirm.is_open()


## ★ อยู่ในเกมไหม (รอบ 32) ★ หน้าหลัก/หน้าโหลดจะซ่อน HUD + ปิดปุ่มลัดทั้งหมด
var in_game := true

func set_in_game(on: bool) -> void:
	in_game = on
	layer.visible = on
	if not on:
		close_all()


func _unhandled_input(event: InputEvent) -> void:
	if not in_game:
		return
	if is_asking():
		return
	if event.is_action_pressed("toggle_status"):
		toggle(&"status")
	elif event.is_action_pressed("toggle_inventory"):
		toggle(&"inventory")
	elif event.is_action_pressed("toggle_equipment"):
		toggle(&"equipment")
	elif event.is_action_pressed("toggle_skills"):
		toggle(&"skills")
	elif event.is_action_pressed("toggle_cards"):
		toggle(&"cards")
	elif event.is_action_pressed("toggle_menu"):
		toggle(&"system")
	elif event.is_action_pressed("toggle_quests"):
		toggle(&"quests")
	elif InputMap.has_action("toggle_gm") and event.is_action_pressed("toggle_gm"):
		toggle(&"gm")
	elif InputMap.has_action("toggle_fullscreen") and event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
	elif InputMap.has_action("toggle_minimap") and event.is_action_pressed("toggle_minimap"):
		toggle(&"map")
	elif event.is_action_pressed("close_windows"):
		close_all()
	elif event.is_action_pressed("quick_save"):
		SaveManager.save_game(0)
		var sysw: GameWindow = windows.get(&"system", null)
		if sysw != null:
			sysw.refresh()
	elif event.is_action_pressed("quick_load"):
		if SaveManager.load_game(0):
			Game.reload_map()
	else:
		return
	get_viewport().set_input_as_handled()


func toggle(id: StringName) -> void:
	if id == &"gm" and not OS.is_debug_build(): return
	if shell != null and shell.is_tab(String(id)):
		shell.toggle_tab(String(id))
		return
	var w: GameWindow = windows.get(id, null)
	if w == null:
		return
	w.toggle()


func open(id: StringName) -> void:
	if id == &"craft":   # ★ รอบ 163 ★ หน้าคราฟต์อยู่ในโรงตีเหล็กแล้ว
		open_blacksmith("craft")
		return
	if id == &"gm" and not OS.is_debug_build(): return
	if shell != null and shell.is_tab(String(id)):
		shell.open_tab(String(id))
		return
	var w: GameWindow = windows.get(id, null)
	if w != null:
		w.show_window()


func close(id: StringName) -> void:
	if shell != null and shell.is_tab(String(id)):
		var page := shell.page_of(String(id))
		if page != null and shell.is_showing(page):
			shell.close()
		return
	var w: GameWindow = windows.get(id, null)
	if w != null:
		w.hide_window()


func close_all() -> void:
	hide_item_popup()
	if shell != null:
		shell.close()
	for w: GameWindow in windows.values():
		if not w.embedded:
			w.hide_window()
	var inv := windows.get(&"inventory") as InventoryWindow
	if inv != null:
		inv.sell_mode = false


func is_any_window_open() -> bool:
	if shell != null and shell.visible:
		return true
	for w: GameWindow in windows.values():
		if w.is_visible_in_tree():   # ★ รอบ 163 ★ หน้าคราฟต์ฝังอยู่ในโรงตีเหล็ก (visible แต่พ่อซ่อน)
			return true
	return false


# =========================================================
# NPC เรียกใช้
# =========================================================
func _on_shop_opened(item_ids: Array) -> void:
	var shop := windows.get(&"shop") as ShopWindow
	if shop == null:
		return
	close_all()
	shop.open_shop(item_ids)


func _on_refine_opened() -> void:
	open_blacksmith("refine")   # ★ รอบ 163 ★ เดิม open(&"refine")


## ★ รอบ 163 ★ เปิดโรงตีเหล็กที่แท็บ refine · socket · third · craft
func open_blacksmith(tab_id: String) -> void:
	close_all()
	var w := windows.get(&"blacksmith") as BlacksmithWindow
	if w != null:
		w.open_tab(tab_id)


## ★ รอบ 163 ★ บอร์ดใบประกาศของเมือง (NPC ที่ติ๊ก has_bounty_board)
func open_bounty_board(town: StringName) -> void:
	close_all()
	var w := windows.get(&"bounty") as BountyBoardWindow
	if w != null:
		w.open_board(town)


## ★ รอบ 132 ★ คราฟต์ — หน้าต่างใหญ่ ปิดหน้าอื่นก่อนเหมือนคลัง
func _on_craft_opened() -> void:
	open_blacksmith("craft")   # ★ รอบ 163 ★ คราฟต์เป็นแท็บในโรงตีเหล็ก


## ★ รอบ 154 ★ ย่อยการ์ด — หน้าต่างใหญ่ ปิดหน้าอื่นก่อน
func _on_guild_rank_opened() -> void:   # ★ รอบ 158 ★
	close_all()
	open(&"guild_rank")


func _on_card_fusion_opened() -> void:
	close_all()
	var w = windows.get(&"card_fusion")
	if w != null and w.has_method("reset_for_open"):
		w.reset_for_open()
	open(&"card_fusion")


func _on_socket_opened() -> void:
	open_blacksmith("socket")   # ★ รอบ 163 ★


## ★ รอบ 122 ★ คลัง — ปิดหน้าต่างอื่นก่อนเหมือนร้านค้า
func _on_storage_opened() -> void:
	close_all()
	open(&"storage")


# =========================================================
# ★ เล่นวิดีโอเต็มจอ (รอบ 41) ★ ใช้กับฉากเปิดตัวบอส / คัทซีน
# เกมหยุดชั่วคราวระหว่างเล่น · กด Enter / Esc / คลิก เพื่อข้ามได้
# =========================================================
var video_playing := false

func play_video(path: String) -> void:
	if video_playing or path == "" or not ResourceLoader.exists(path):
		return
	video_playing = true
	var was_paused := get_tree().paused
	get_tree().paused = true

	var vlayer := CanvasLayer.new()
	vlayer.layer = 150
	vlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(vlayer)

	# ★ CanvasLayer ไม่มี modulate — ห่อทุกอย่างใน Control แล้วเฟดที่ตัวนี้แทน ★
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	vlayer.add_child(wrap)

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(black)

	var vid := VideoStreamPlayer.new()
	vid.stream = load(path)
	vid.expand = true
	vid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(vid)
	vid.play()

	var hint := Label.new()
	hint.text = "Enter / คลิก = ข้าม"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -240
	hint.offset_top = -46
	hint.offset_right = -20
	hint.offset_bottom = -16
	wrap.add_child(hint)

	# จางเข้า
	wrap.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(wrap, "modulate:a", 1.0, 0.25)

	# รอจนวิดีโอจบ หรือผู้เล่นกดข้าม (กันกดพลาด: เริ่มรับปุ่มหลัง 0.4 วิ)
	var t := 0.0
	while is_instance_valid(vid) and vid.is_playing():
		await get_tree().process_frame
		t += get_process_delta_time()
		# ★ ใช้ is_action_pressed (ค้าง) ไม่ใช่ just_pressed — ตอนเกม pause เฟรม input
		# กับเฟรม await ไม่ตรงกัน just_pressed จะหลุดมือ (กับดักข้อ 15) ★
		if t > 0.4 and (Input.is_action_pressed("ui_accept")
				or Input.is_action_pressed("ui_cancel")
				or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			break

	var out := create_tween()
	out.tween_property(wrap, "modulate:a", 0.0, 0.25)
	await out.finished
	vlayer.queue_free()
	get_tree().paused = was_paused
	video_playing = false


var _warp_open := false
func choose_warp(targets: Array) -> StringName:
	if _warp_open: return &""
	_warp_open = true
	var page := preload("res://scripts/ui/warp_selector.gd").new()
	page.targets = targets
	layer.add_child(page)
	var was_paused := get_tree().paused
	get_tree().paused = true
	var destination: StringName = await page.chosen
	page.queue_free()
	get_tree().paused = was_paused
	_warp_open = false
	return destination
