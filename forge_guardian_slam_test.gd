extends Node

class DamageProbe extends Node2D:
	var hits := 0
	func foot_position() -> Vector2:
		return global_position
	func take_damage(_amount: int, _force: float, _direction: int) -> void:
		hits += 1

var failures := 0
var impacts: Array[Dictionary] = []
var boss: CharacterBody2D
var probe: DamageProbe
var shot_name := ""
var floor_y := 0.0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func on_impact(at: Vector2, radius: float, skill: bool, index: int) -> void:
	impacts.append({"frame":boss.sprite.frame,"at":at,"radius":radius,"skill":skill,"index":index})
	if shot_name != "" and index == 0 and DisplayServer.get_name() != "headless":
		var label := shot_name
		await get_tree().create_timer(0.08).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://output/forge_guardian_slam/" + label + ".png")

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	get_window().content_scale_size = Vector2i(1280,720)
	var map = load("res://scenes/maps/cold_forge.tscn").instantiate()
	map.get_node("Spawners").free()
	add_child(map)
	var ground: CollisionShape2D = map.get_node("Terrain/Ground/Shape")
	floor_y = ground.global_position.y - ground.shape.size.y * 0.5
	map.player.set_physics_process(false)
	map.player.global_position = Vector2(1850, floor_y - 120)
	map.camera.position_smoothing_enabled = false
	map.camera.global_position = Vector2(1550, 470)
	map.camera.zoom = Vector2(0.7,0.7)
	map.camera.offset = Vector2.ZERO
	UI.layer.hide()
	probe = DamageProbe.new()
	map.add_child(probe)
	boss = load("res://scenes/monsters/monster.tscn").instantiate()
	boss.data = load("res://data/monsters/forge_guardian.tres").duplicate()
	boss.data.hit = 100000
	map.add_child(boss)
	boss.set_physics_process(false)
	boss.global_position = Vector2(1550, floor_y - boss.data.foot_offset())
	boss._player = probe
	boss.ground_slam_impact.connect(on_impact)
	# Verify every pose and animation transition against one world-space root.
	var sprite_frames: SpriteFrames = boss.sprite.sprite_frames
	var reference_scale: Vector2 = Vector2.ONE * boss._fit_frames(&"Idle").scale
	for direction in [-1, 1]:
		boss._face_to(direction)
		for anim in sprite_frames.get_animation_names():
			boss._play(String(anim), true)
			boss.sprite.pause()
			for frame in range(sprite_frames.get_frame_count(anim)):
				boss.sprite.frame = frame
				boss._apply_fit()
				var tex := sprite_frames.get_frame_texture(anim, frame)
				var root: Vector2 = boss.data.fit_fixed_anchor - tex.get_size() * 0.5
				var soles: PackedFloat32Array = boss._fit_frames(anim).get("soles", PackedFloat32Array())
				if not soles.is_empty():
					check(soles[frame] >= 430.0 and soles[frame] <= 450.0, "Detected sole stays inside the authored boot area")
					root.y = soles[frame] - tex.get_height() * 0.5
				if boss.sprite.flip_h:
					root.x = -root.x
				var world_root: Vector2 = boss.sprite.to_global(root + boss.sprite.offset)
				check(world_root.distance_to(boss.foot_position()) < 0.01, "%s frame %d: stable root" % [anim, frame])
				var calibration: float = boss.data.fit_animation_scales.get(anim, 1.0)
				check(boss.sprite.scale.is_equal_approx(reference_scale * calibration), "Calibrated scale stays constant throughout each animation")
				check(tex.get_size() == Vector2(512,512), "Every frame uses the correct sheet grid")
	# Measured opaque torso/feet heights, excluding the hammer: walk 384, attack 361.
	check(absf(384.0 * boss._fit_frames(&"Run").scale - 361.0 * boss._fit_frames(&"Attack").scale) < 1.0, "Walking and attacking body heights match within one world pixel")
	# Repeated slams must traverse the intermediate hammer poses, never teleport 15 -> 12.
	for frame in range(1, sprite_frames.get_frame_count("Skill")):
		var previous: AtlasTexture = sprite_frames.get_frame_texture("Skill", frame - 1)
		var current: AtlasTexture = sprite_frames.get_frame_texture("Skill", frame)
		var previous_cell := int(previous.region.position.y / 512) * 8 + int(previous.region.position.x / 512)
		var current_cell := int(current.region.position.y / 512) * 8 + int(current.region.position.x / 512)
		check(absi(current_cell - previous_cell) == 1, "Skill uses adjacent source poses at every transition")
	for direction in [-1,1]:
		boss._face_to(direction)
		probe.global_position = Vector2(1550 + direction * 210, floor_y)
		probe.hits = 0
		impacts.clear()
		shot_name = "normal_left" if direction < 0 else "normal_right"
		await boss._attack()
		check(impacts.size() == 1, "Normal attack emits exactly one impact")
		check(probe.hits == 1, "Normal attack applies one damage event")
		check(impacts[0].frame == 15, "Normal impact matches frame 15")
		check(signf(impacts[0].at.x - boss.global_position.x) == direction, "Hammer origin mirrors with facing")
		check(absf(impacts[0].at.y - floor_y) < 1.0, "Explosion rests on collider floor")
		await get_tree().create_timer(0.9).timeout
	boss._face_to(-1)
	probe.global_position = Vector2(1340,floor_y)
	probe.hits = 0
	impacts.clear()
	shot_name = "skill_lava"
	await boss._cast_skill()
	check(probe.hits == 5, "Skill applies exactly five damage events")
	check(impacts.size() == 5, "Skill emits exactly five lava explosions")
	for i in range(impacts.size()):
		check(impacts[i].frame == [15,21,27,33,39][i], "Every slam is synchronized to the authored impact frame")
		check(impacts[i].radius > boss.data.attack_slam_radius, "Skill area exceeds normal attack")
	# Escaping the damage area must work even while all five visuals still occur.
	probe.global_position = Vector2(400,floor_y)
	probe.hits = 0
	impacts.clear()
	shot_name = ""
	await boss._cast_skill()
	check(probe.hits == 0 and impacts.size() == 5, "Outside radius avoids all five hits")
	# Death cancels the remaining sequence, without leaving a delayed damage timer.
	impacts.clear()
	boss._cast_skill()
	while impacts.is_empty():
		await get_tree().physics_frame
	boss.state = boss.State.DEAD
	await get_tree().create_timer(2.0).timeout
	check(impacts.size() == 1, "Death interrupts remaining four hits")
	check(get_tree().get_nodes_in_group("lava_slam_fx").is_empty(), "All temporary lava nodes expire")
	var other = load("res://data/monsters/baphomet.tres")
	check(not other.attack_ground_slam and not other.skill_ground_slam, "Other bosses retain existing attacks")
	print("FORGE_GUARDIAN_SLAM_TEST: all animation roots/scales + sheet grid + adjacent skill poses + normal + mirror + five hits + frame sync + range + death cancellation + FX cleanup; %d failures" % failures)
	get_tree().quit(failures)
