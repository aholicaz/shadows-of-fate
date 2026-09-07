extends Node
## ตัววัดของ r88 — ทำงานหลังมอนทุกเฟรม แล้วส่งต่อให้ runner เก็บกรอบภาพ
var owner_runner: Node

func _process(_delta: float) -> void:
	if owner_runner != null and owner_runner.has_method("sample"):
		owner_runner.sample()
