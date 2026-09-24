## Manual slots and one separate, recoverable autosave.
extends Node
const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const AUTO_SLOT := 3
const AUTO_INTERVAL := 180.0
var save_directory := SAVE_DIR
var _active := false
var _elapsed := 0.0
var _pending := -1.0
var _writing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.socket_result.connect(func(_ok, _name, _slots): request_autosave())
	Events.refine_result.connect(func(_ok, _name, _rank): request_autosave())
	Events.quest_completed.connect(func(_id): request_autosave())
	if name == &"SaveManager":
		get_tree().auto_accept_quit = false
		get_tree().root.close_requested.connect(quit_game)

func activate() -> void:
	_active = true
	request_autosave()

func end_session() -> void:
	_active = false
	_elapsed = 0.0
	_pending = -1.0

func request_autosave() -> void:
	if _active and _pending < 0.0: _pending = 3.0

func can_autosave() -> bool:
	return _active and not _writing and not Game._is_changing \
		and PlayerState.stats != null and not PlayerState._is_dead and PlayerState.stats.hp > 0 \
		and get_tree().get_first_node_in_group("player") != null \
		and get_tree().get_first_node_in_group("map") != null

func _process(delta: float) -> void:
	if not _active: return
	if _pending > 0.0: _pending = maxf(0.0, _pending - delta)
	if not get_tree().paused: _elapsed += delta
	if (_elapsed >= AUTO_INTERVAL or _pending == 0.0) and can_autosave():
		if not save_auto():
			_elapsed = 0.0
			_pending = 30.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED: save_auto()

func quit_game() -> void:
	save_auto()
	get_tree().quit()

func slot_path(slot: int) -> String:
	return save_directory.path_join("autosave.json" if slot == AUTO_SLOT else "slot_%d.json" % slot)

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK: return {}
	var parsed = parser.data
	if not parsed is Dictionary or not parsed.get("stats") is Dictionary \
		or not parsed.get("inventory") is Array or not parsed.get("equipment") is Dictionary:
		return {}
	return parsed

func _read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot > AUTO_SLOT: return {}
	var data := _read_file(slot_path(slot))
	return data if not data.is_empty() else _read_file(slot_path(slot) + ".bak")

func has_save(slot: int) -> bool:
	return not _read_slot(slot).is_empty()

func _write_snapshot(slot: int) -> bool:
	if _writing: return false
	_writing = true
	var data := PlayerState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system()
	var map = get_tree().get_first_node_in_group("map")
	data["map_name"] = String(map.display_name) if map != null and "display_name" in map else String(Game.MAP_NAMES.get(PlayerState.current_map_id, PlayerState.current_map_id))
	var ok := _write_recoverable(slot_path(slot), data)
	_writing = false
	if not ok: Events.say("บันทึกเกมไม่สำเร็จ กรุณาตรวจพื้นที่เก็บข้อมูล")
	return ok

func _write_recoverable(path: String, data: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return false
	var temp := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or _read_file(temp).is_empty(): return false
	# Do not rotate corrupt data over the last known good backup.
	if FileAccess.file_exists(path):
		if not _read_file(path).is_empty():
			if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK: return false
			if DirAccess.rename_absolute(path, backup) != OK: return false
		elif DirAccess.remove_absolute(path) != OK: return false
	# If interrupted here, the loader recovers from .bak.
	return DirAccess.rename_absolute(temp, path) == OK

func save_game(slot: int = 0) -> bool:
	if slot < 0 or slot >= SLOT_COUNT: return false
	var ok := _write_snapshot(slot)
	if ok: Events.say("บันทึกเกมแล้ว")
	return ok

func save_auto() -> bool:
	if not can_autosave(): return false
	if not _write_snapshot(AUTO_SLOT): return false
	_elapsed = 0.0
	_pending = -1.0
	Events.say("บันทึกอัตโนมัติแล้ว")
	return true

func load_game(slot: int = 0) -> bool:
	var parsed := _read_slot(slot)
	if parsed.is_empty(): return false
	end_session()
	PlayerState.from_dict(parsed)
	Events.say("โหลดเกมแล้ว")
	return true

func delete_save(slot: int) -> void:
	if slot < 0 or slot > AUTO_SLOT: return
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = slot_path(slot) + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func slot_info(slot: int) -> Dictionary:
	var parsed := _read_slot(slot)
	if parsed.is_empty(): return {}
	var s: Dictionary = parsed.get("stats", {})
	# ★ รอบ 166 ★ เพิ่มเวลาเล่น + ขั้นกิลด์ (หน้าระบบ/หน้าโหลดโชว์ตราขั้น)
	var b = parsed.get("bounties", {})
	var pts: int = int(b.get("points", 0)) if b is Dictionary else 0
	var rank := "F"
	for r in BountyBoard.RANKS:
		if pts >= int(r[1]):
			rank = String(r[0])
	return {"level": s.get("level", 1), "job": s.get("job_id", ""),
		"zeny": parsed.get("zeny", 0), "map": parsed.get("map", ""),
		"map_name": parsed.get("map_name", ""), "saved_at": parsed.get("saved_at", ""),
		"play_time": float(parsed.get("play_time", 0)), "rank": rank}
