## MusicPlayer — เพลงประจำแมพ (รอบ 52)
##
## ★★ ใช้ยังไง: แค่ตั้งชื่อไฟล์ให้ตรงกับ map_id ★★
##   วางไฟล์ที่  Sprites/music/<map_id>.mp3   แล้วจบ — ไม่ต้องแก้โค้ด ไม่ต้องตั้งค่าในฉาก
##   เช่น  Sprites/music/prontera_town.mp3  → เข้าเมืองพรอนเทราแล้วเพลงนี้เล่นเอง
##   แมพไหนยังไม่มีไฟล์ = เงียบ (ไม่ error) วางเพิ่มทีหลังได้เลย
##
##   ชื่อพิเศษ:  title.mp3  = เพลงหน้าหลัก   ·   boss.mp3 = เพลงบอส (เรียกเองด้วย play_key)
##
## รองรับ .mp3 .ogg .wav · หาไฟล์จากหลายโฟลเดอร์ (ดู DIRS) เผื่อย้ายที่เก็บทีหลัง
##
## ★ ไม่ใช่ Autoload ★ Game สร้างให้เป็นลูกตอนเปิดเกม → เรียกใช้ผ่าน  Game.music
## (ทำแบบนี้จะได้ไม่ต้องแก้ project.godot ซึ่งต้องปิด-เปิด Godot ใหม่)
class_name MusicPlayer
extends Node

## โฟลเดอร์ที่จะไปหาไฟล์เพลง (ไล่จากบนลงล่าง เจออันแรกใช้อันนั้น)
const DIRS := ["res://Sprites/music/", "res://music/", "res://Sprites/Music/", "res://audio/music/"]
const EXTS := [".mp3", ".ogg", ".wav"]
## Chapter 4 shares three files; adjoining field maps keep the same playback.
const MAP_TRACKS := {
	"utgard_town": "chapter4_town",
	"frost_pass": "chapter4_field",
	"giant_steppe": "chapter4_field",
	"frozen_hall": "chapter4_field",
	"broken_wall": "chapter4_field",
	"hrungnir_crater": "chapter4_boss",
}
const LAYOUT_PATH := "user://ui_layout.cfg"

## เวลาไล่เสียงตอนสลับเพลง (วินาที)
const FADE_OUT := 0.9
const FADE_IN := 1.1
## ระดับเสียงเริ่มต้น 0.0-1.0
const DEFAULT_VOLUME := 0.6
## เงียบสุด = ปิดเสียงไปเลย (dB ต่ำกว่านี้คนไม่ได้ยินแล้ว)
const SILENT_DB := -60.0

var volume: float = DEFAULT_VOLUME      ## 0.0-1.0 (ผู้ใช้ปรับได้ในเมนูระบบ)
var enabled: bool = true                ## ปิดเพลงทั้งหมด

var _players: Array[AudioStreamPlayer] = []
var _active := 0                        ## ตัวที่กำลังเล่นอยู่ (อีกตัวไว้ไล่เสียงออก)
var _current_key := ""                  ## เพลงที่เล่นอยู่ตอนนี้ (= ชื่อไฟล์ไม่รวมนามสกุล)
var _tween: Tween
## จำว่าหาไฟล์ของ key ไหนไปแล้วบ้าง (กันไล่หาไฟล์ซ้ำ ๆ ทุกครั้งที่เปลี่ยนแมพ)
var _path_cache: Dictionary = {}
var _map_key := ""
var _combat_check_time := 0.0


func _process(delta: float) -> void:
	if _map_key == "" or get_tree().paused:
		return
	_combat_check_time += delta
	if _combat_check_time < 0.25:
		return
	_combat_check_time = 0.0
	_refresh_combat_music()


func _refresh_combat_music() -> void:
	var desired := _map_key
	if _map_key == "cold_forge" and not PlayerState.is_dead():
		for enemy in get_tree().get_nodes_in_group("enemy"):
			var monster_data: Resource = enemy.get("data")
			if monster_data == null or monster_data.get("id") != &"forge_guardian":
				continue
			if int(enemy.get("hp")) > 0 and enemy.has_method("is_aggro_locked") \
					and enemy.is_aggro_locked() and has_track("boss_forge_guardian"):
				desired = "boss_forge_guardian"
				break
	if desired != _current_key and has_track(desired):
		_play_track(desired)


func _ready() -> void:
	name = "MusicPlayer"
	process_mode = Node.PROCESS_MODE_ALWAYS      # เพลงเล่นต่อตอนเกมหยุด (เปิดเมนู/คุย NPC)
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.name = "Music%d" % (i + 1)
		p.bus = "Master"
		p.volume_db = SILENT_DB
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	_load_settings()


# =========================================================
# หาไฟล์เพลง
# =========================================================
## คืน path ของไฟล์เพลงชื่อนี้ (คืน "" ถ้าไม่มี)
func find_track(key: String) -> String:
	key = String(MAP_TRACKS.get(key, key))
	if key == "":
		return ""
	if _path_cache.has(key):
		return String(_path_cache[key])
	var found := ""
	for dir in DIRS:
		for ext in EXTS:
			var path: String = dir + key + ext
			if ResourceLoader.exists(path):
				found = path
				break
		if found != "":
			break
	_path_cache[key] = found
	return found


## มีเพลงของแมพนี้ไหม (ใช้เช็คในเทสต์/เอกสาร)
func has_track(key: String) -> bool:
	return find_track(key) != ""


# =========================================================
# เล่นเพลง
# =========================================================
## เล่นเพลงประจำแมพ — เรียกจาก map_base ตอนโหลดแมพ
func play_for_map(map_id: StringName) -> void:
	_map_key = String(MAP_TRACKS.get(String(map_id), String(map_id)))
	_play_track(_map_key)


## เล่นเพลงตามชื่อไฟล์ (ไม่รวมนามสกุล) · ไม่มีไฟล์ = ไล่เสียงออกแล้วเงียบ
func play_key(key: String) -> void:
	_map_key = ""
	_play_track(key)


func _play_track(key: String) -> void:
	if key == _current_key and _players[_active].playing:
		return                                    # เพลงเดิมอยู่แล้ว — ปล่อยให้เล่นต่อ ไม่ต้องเริ่มใหม่
	var path := find_track(key)
	if path == "":
		_current_key = ""
		stop()
		return
	_current_key = key
	if not enabled:
		return
	_crossfade_to(path)


func _crossfade_to(path: String) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_set_loop(stream)

	var old: AudioStreamPlayer = _players[_active]
	_active = 1 - _active
	var new_p: AudioStreamPlayer = _players[_active]

	new_p.stream = stream
	new_p.volume_db = SILENT_DB
	new_p.play()

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(new_p, "volume_db", _target_db(), FADE_IN)
	if old.playing:
		_tween.tween_property(old, "volume_db", SILENT_DB, FADE_OUT)
		_tween.chain().tween_callback(old.stop)


## ★ สำคัญ ★ เพลงต้องวนซ้ำ ไม่งั้นเล่นจบแล้วเงียบไปเลย
## ตั้งที่ตัว resource ตอนโหลด — ไม่ต้องไปแก้ค่า import ของทุกไฟล์เอง
func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func stop(fade: bool = true) -> void:
	var p: AudioStreamPlayer = _players[_active]
	if not p.playing:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not fade:
		p.stop()
		return
	_tween = create_tween()
	_tween.tween_property(p, "volume_db", SILENT_DB, FADE_OUT)
	_tween.tween_callback(p.stop)


func is_playing() -> bool:
	return _players[_active].playing


func current_track() -> String:
	return _current_key


# =========================================================
# ระดับเสียง (จำไว้ในไฟล์เดียวกับโหมดปุ่มจอสัมผัส)
# =========================================================
func _target_db() -> float:
	if not enabled or volume <= 0.001:
		return SILENT_DB
	return linear_to_db(clampf(volume, 0.0, 1.0))


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	_apply_volume()
	_save_settings()


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		stop()
	elif _current_key != "":
		var key := _current_key
		_current_key = ""          # บังคับให้เริ่มใหม่
		_play_track(key)
	_save_settings()


func _apply_volume() -> void:
	var p: AudioStreamPlayer = _players[_active]
	if p.playing:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		p.volume_db = _target_db()


func volume_percent() -> int:
	return int(round(volume * 100.0))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(LAYOUT_PATH)
	cfg.set_value("music", "volume", volume)
	cfg.set_value("music", "enabled", enabled)
	cfg.save(LAYOUT_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(LAYOUT_PATH) != OK:
		return
	volume = clampf(float(cfg.get_value("music", "volume", DEFAULT_VOLUME)), 0.0, 1.0)
	enabled = bool(cfg.get_value("music", "enabled", true))
