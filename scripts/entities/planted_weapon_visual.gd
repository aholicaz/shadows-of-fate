extends Node2D
const GEOMETRY = preload("res://scripts/entities/weapon_blade_geometry.gd")
var weapon_id: StringName
var blade: Sprite2D

func configure(inst: ItemInstance) -> void:
	var item := inst.data() if inst!=null else null
	if item==null: return
	weapon_id=item.id
	var texture := item.equip_texture
	if texture==null: texture=item.icon
	if texture==null: return
	blade=Sprite2D.new()
	blade.texture=texture
	blade.centered=false
	blade.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var points: Vector4=GEOMETRY.POINTS.get(texture.resource_path,Vector4(texture.get_width()*0.15,texture.get_height()*0.85,texture.get_width()*0.85,texture.get_height()*0.15))
	var tip := Vector2(points.x,points.y)
	var grip := Vector2(points.z,points.w)
	blade.offset=-tip
	blade.rotation=Vector2.UP.angle()-(grip-tip).angle()
	blade.scale=Vector2.ONE*230.0/maxf(1.0,tip.distance_to(grip))
	add_child(blade)

func _draw() -> void:
	# Bare-handed fallback only; equipped weapons always use their own artwork.
	if blade==null:
		draw_line(Vector2.ZERO,Vector2(0,-220),Color("#b9f1ff"),8,true)
		draw_line(Vector2(-25,-180),Vector2(25,-180),Color("#dfbe79"),5,true)
