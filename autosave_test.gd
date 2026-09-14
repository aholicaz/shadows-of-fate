extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error(label)

func _ready() -> void:
	PlayerState.new_game()
	PlayerState.set_process(false)
	var manager = load("res://scripts/core/save_manager.gd").new()
	manager.name = "IsolatedSaveTest"
	manager.save_directory = "res://output/autosave_test/run_%d" % Time.get_ticks_usec()
	add_child(manager)
	manager.set_process(false)
	var map := Node.new()
	add_child(map)
	map.add_to_group("map")
	var player := Node.new()
	add_child(player)
	player.add_to_group("player")
	check(not manager.save_auto(), "inactive sessions never autosave")
	manager._active = true
	manager._elapsed = 179.0
	manager._process(0.5)
	check(not manager.has_save(3), "no early timer save")
	manager._process(0.5)
	check(manager.has_save(3), "autosave after 180 seconds")
	check(not manager.has_save(0), "autosave never writes manual slot")
	var sword := ItemInstance.create(&"flame_sword",1,7,2)
	sword.socket_failures = 2
	sword.socket_locked = true
	sword.bonus_percent = 23.4
	sword.socket_card(&"card_orc_warrior")
	PlayerState.inventory.add(sword)
	Events.socket_result.emit(false,"test",2)
	check(manager._pending == 3.0, "socket transaction queues autosave")
	manager._process(2.0)
	Events.refine_result.emit(true,"test",7)
	check(manager._pending == 1.0, "events coalesce without postponing save")
	manager._process(1.0)
	var snapshot: Dictionary = manager._read_slot(3)
	var found := false
	for item in snapshot.inventory:
		if item != null and item.item_id == "flame_sword":
			found = item.socket_failures == 2 and item.socket_locked and item.refine == 7 and item.cards.size() == 1
	check(found, "snapshot preserves paid weapon progression")
	check(FileAccess.file_exists(manager.slot_path(3)+".bak"), "previous snapshot retained")
	check(manager.save_game(0), "manual save still works")
	var manual: Dictionary = manager._read_slot(0)
	PlayerState.zeny += 1234
	manager.save_auto()
	check(manager._read_slot(0) == manual, "later autosave preserves manual slot")
	PlayerState._is_dead = true
	check(not manager.save_auto(), "no autosave while dead")
	PlayerState._is_dead = false
	Game._is_changing = true
	check(not manager.save_auto(), "no autosave mid-transition")
	Game._is_changing = false
	player.remove_from_group("player")
	check(not manager.save_auto(), "no autosave without live scene player")
	player.add_to_group("player")
	var previous: Dictionary = manager._read_file(manager.slot_path(3)+".bak")
	var file := FileAccess.open(manager.slot_path(3),FileAccess.WRITE)
	file.store_string("truncated")
	file.close()
	check(manager.has_save(3) and manager._read_slot(3) == previous, "corrupt primary falls back to previous snapshot")
	check(manager.load_game(3) and PlayerState.zeny == int(previous.zeny), "backup loads correctly")
	check(not manager._active, "loading suspends saving until map is ready")
	manager.activate()
	check(manager.save_auto(), "can replace corrupt primary safely")
	check(manager._read_file(manager.slot_path(3)+".bak") == previous, "corrupt primary never replaces good backup")
	check(not manager.save_game(3), "manual API cannot overwrite auto slot")
	PlayerState.zeny += 20
	manager._notification(NOTIFICATION_APPLICATION_PAUSED)
	check(manager.slot_info(3).zeny == PlayerState.zeny, "mobile pause notification flushes current progress")
	manager.end_session()
	Events.quest_completed.emit(&"test")
	check(manager._pending == -1.0 and not manager.save_auto(), "title/new game cancels pending autosave")
	check(not SaveManager._active, "test never activates real user save manager")
	if "--preview" in OS.get_cmdline_user_args():
		# Preview reads only isolated test saves, never the user's files.
		var prior: String = SaveManager.save_directory
		SaveManager.save_directory = manager.save_directory
		get_window().size = Vector2i(1280,720)
		get_window().content_scale_size = Vector2i(1280,720)
		UI.shell.open_tab("system")
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		check(get_viewport().get_texture().get_image().save_png("res://output/autosave_test/system.png") == OK,"render auto save slot")
		UI.shell.close()
		var title = load("res://scenes/ui/title_screen.tscn").instantiate()
		add_child(title)
		await get_tree().create_timer(1.0).timeout
		check(title._slot_labels.size() == 4 and not title._buttons[4].disabled, "title exposes loadable auto slot alongside three manual slots")
		await RenderingServer.frame_post_draw
		check(get_viewport().get_texture().get_image().save_png("res://output/autosave_test/title.png") == OK,"render title auto load option")
		SaveManager.save_directory = prior
	print("AUTOSAVE: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
