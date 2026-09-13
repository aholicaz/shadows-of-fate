extends Sprite2D
## Subtle continuous breathing, registered around the opaque sole rather than image centre.
@export var foot_px := 652.0
@export var phase := 0.0
@export var breathe := true
var rest_scale: Vector2
var rest_position: Vector2
var elapsed := 0.0
func _ready() -> void:
	rest_scale = scale
	rest_position = position
func _process(delta: float) -> void:
	if not breathe: return
	elapsed += delta
	var stretch := sin(elapsed * 1.45 + phase) * 0.004
	scale.y = rest_scale.y * (1.0 + stretch)
	position.y = rest_position.y - foot_px * rest_scale.y * stretch
