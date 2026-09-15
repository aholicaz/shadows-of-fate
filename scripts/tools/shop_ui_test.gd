extends Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	SaveManager.end_session()
	PlayerState.new_game()
	UI.set_in_game(true)
	PlayerState.inventory.add_id(&"bat_fang", 3)
	PlayerState.inventory.add_id(&"red_potion", 2)
	PlayerState.inventory.add_id(&"gullveig_ash", 1)
	UI.open(&"inventory")
	UI._on_shop_opened(["red_potion", "orange_potion", "blue_potion", "wooden_sword"])
	await get_tree().process_frame
	var shop = UI.windows[&"shop"]
	assert(shop.visible and not UI.shell.visible)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/mobile_ui/shop_buy.png")
	shop._set_mode(false)
	var entries = shop.junk_candidates()
	assert(entries.size() == 1 and entries[0].instance.item_id == &"bat_fang")
	var before = PlayerState.zeny
	var expected = entries[0].value
	shop._sell_junk()
	await get_tree().process_frame
	assert(UI.confirm.is_open())
	UI.confirm._answer(false)
	assert(PlayerState.zeny == before and shop.junk_candidates().size() == 1)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/mobile_ui/shop_sell.png")
	shop._sell_junk()
	await get_tree().process_frame
	UI.confirm._answer(true)
	assert(PlayerState.zeny == before + expected and shop.junk_candidates().is_empty())
	assert(shop.visible and not UI.shell.visible)
	print("SHOP_UI_PASS: single window, junk eligibility, cancellation, confirmed proceeds, protected materials")
	get_tree().quit()
