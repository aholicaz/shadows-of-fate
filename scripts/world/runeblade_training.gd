extends "res://scripts/world/map_base.gd"
func _ready() -> void:
	var bg = load("res://scenes/world/chapter3/runeblade_training_background.tscn").instantiate()
	add_child(bg)
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(1100,960)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2200,120)
	col.shape = shape
	floor_body.add_child(col)
	add_child(floor_body)
	var spawns := Node2D.new()
	spawns.name = "SpawnPoints"
	var marker := Marker2D.new()
	marker.name = "default"
	marker.position = Vector2(450,770)
	spawns.add_child(marker)
	add_child(spawns)
	super._ready()
	if Game.music: Game.music.play_for_map(&"vanir_town")
