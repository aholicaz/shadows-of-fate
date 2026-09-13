extends AnimatedSprite2D
## Register the existing authored idle frames to the rear pavement; keep their timing.
@export var actor_height := 215.0
var measurements: Dictionary
func _ready() -> void:
	measurements = SpriteFit.measure(sprite_frames, animation)
	if measurements.is_empty(): return
	var s: float = actor_height / maxf(1.0, measurements.tallest)
	scale = Vector2(s,s)
	frame_changed.connect(_register)
	_register()
func _register() -> void:
	if measurements.is_empty() or frame >= measurements.frames.size(): return
	var datum: Dictionary = measurements.frames[frame]
	position = Vector2(-float(datum.dx_use)*scale.x,-32-float(datum.bottom_use)*scale.y)
