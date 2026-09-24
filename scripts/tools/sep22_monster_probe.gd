extends "res://scripts/entities/monster_base.gd"
## Test-only observer; the real combat method still runs unchanged.
var hit_trace: Array[int] = []
func _attack_hit(hits: int = 1, release_frame: int = -1, cast_mult: float = 1.0, skill_cast: bool = false) -> void:
	hit_trace.append(sprite.frame)
	super._attack_hit(hits, release_frame, cast_mult, skill_cast)
