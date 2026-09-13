extends Node2D
var checks := 0
var failures := 0
class Target extends Node2D:
	var hp := 10000
	var hits := 0
	func is_dead() -> bool: return false
	func take_damage_from_player(_mult,_crit,_dir,_push,_stun,_source) -> void:
		hp-=1
		hits+=1
class Caster extends Node2D:
	var _dead := false
	func enemy_rect(enemy: Node2D) -> Rect2:
		return Rect2(enemy.global_position-Vector2(8,100),Vector2(16,100))
class Controller extends Node2D:
	var player: Node2D
	var gains := 0
	func _gain() -> void: gains+=1
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: ",message)
	else:
		failures+=1
		push_error(message)
func _ready() -> void:
	PlayerState.new_game()
	PlayerState.set_process(false)
	var caster := Caster.new()
	add_child(caster)
	var controller := Controller.new()
	controller.player=caster
	add_child(controller)
	var pack: Array=[]
	for i in range(14):
		var target := Target.new()
		add_child(target)
		target.add_to_group("enemy")
		target.position=Vector2(300+i*20,400)
		pack.append(target)
	for id in [&"faultline",&"worldcleaver"]:
		PlayerState.skills.learned[id]=10
		var field=preload("res://scripts/entities/runic_blade_field.gd").new()
		field.configure(controller,id,10,Vector2(440,400),1)
		controller.add_child(field)
		field.set_process(false)
		for target in pack: target.hits=0
		for pulse in range(field.pulses): field.strike()
		var count := 0
		var consistent := true
		for target in pack:
			if target.hits>0: count+=1
			consistent=consistent and target.hits in [0,field.pulses]
		check(count==(10 if id==&"faultline" else 12) and consistent,"14-monster pack respects every pulse's target cap: "+String(id))
		if id==&"faultline": check(controller.gains==1,"six planted-sword pulses generate at most one rune per cast")
		field.free()
	for id in [&"runic_blade",&"flame_sword"]:
		var inst := ItemInstance.create(id)
		var visual=preload("res://scripts/entities/planted_weapon_visual.gd").new()
		visual.configure(inst)
		check(visual.weapon_id==id and visual.blade.texture==inst.data().equip_texture,"planted weapon follows equipped artwork: "+String(id))
		var geometry: Vector4=preload("res://scripts/entities/weapon_blade_geometry.gd").POINTS[inst.data().equip_texture.resource_path]
		var grip: Vector2=visual.blade.transform*(Vector2(geometry.z,geometry.w)+visual.blade.offset)
		check(absf(grip.x)<0.01 and absf(grip.y+230)<0.01,"equipped blade points into the ground: "+String(id))
		visual.free()
	print("BALANCE FIELD: %d checks; failures=%d"%[checks,failures])
	for target in pack: target.free()
	controller.free()
	caster.free()
	get_tree().quit(1 if failures else 0)
