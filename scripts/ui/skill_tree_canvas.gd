extends Control
const POSITIONS := {
	&"runic_vessel":Vector2(0,0), &"rune_guard":Vector2(0,1), &"rune_lunge":Vector2(0,2),
	&"blade_rhythm":Vector2(1,0), &"keen_inscription":Vector2(1,1), &"rune_flurry":Vector2(1,2), &"unbroken_edge":Vector2(1,3),
	&"tempered_might":Vector2(2,0), &"anvil_cleave":Vector2(2,1), &"faultline":Vector2(2,2), &"worldcleaver":Vector2(2,3),
	&"first_aid":Vector2(0,0), &"bash":Vector2(1,0), &"battle_cry":Vector2(0,1), &"slash":Vector2(1,1), &"magnum_break":Vector2(2,1),
	&"sword_mastery":Vector2(0,2), &"hp_recovery":Vector2(1,2), &"endure":Vector2(2,2),
	&"ninth_vessel":Vector2(0,0), &"named_edge":Vector2(1,0), &"wallbreaker_stance":Vector2(2,0),
	&"twin_inscription":Vector2(0,1), &"erasing_cut":Vector2(1,1), &"ninth_inscription":Vector2(1,2)
}
const NODE_SIZE := Vector2(152,74)
var nodes: Dictionary={}

func node_position(id: StringName) -> Vector2:
	return Vector2(10,8)+POSITIONS.get(id,Vector2.ZERO)*Vector2(178,90)

func set_nodes(value: Dictionary) -> void:
	nodes=value
	custom_minimum_size=Vector2(530,354)
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	for id in nodes:
		var skill := GameData.get_skill(id)
		for prerequisite in skill.required_skills:
			var parent := StringName(prerequisite)
			if not nodes.has(parent): continue
			var satisfied := PlayerState.skills.level_of(parent)>=int(skill.required_skills[prerequisite])
			var color := Color("#6dd6c3") if satisfied else Color("#697383")
			var start := node_position(parent)+Vector2(NODE_SIZE.x/2,NODE_SIZE.y)
			var end := node_position(id)+Vector2(NODE_SIZE.x/2,0)
			var middle := (start.y+end.y)/2
			var line := PackedVector2Array([start,Vector2(start.x,middle),Vector2(end.x,middle),end])
			draw_polyline(line,color,2,true)
			draw_colored_polygon(PackedVector2Array([end,end+Vector2(-4,-5),end+Vector2(4,-5)]),color)
			draw_string(font,Vector2(end.x+7,end.y-5),"Lv.%d"%int(skill.required_skills[prerequisite]),HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
