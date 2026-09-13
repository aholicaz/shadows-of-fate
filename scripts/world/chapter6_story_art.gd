extends Node2D
## Replace only each story point's own placeholder drawing; keep its label and action.
var chains: Array = []
func _ready() -> void:
	call_deferred("_attach")
func _attach() -> void:
	var index := 0
	for point in get_tree().get_nodes_in_group("story_point"):
		if not get_parent().is_ancestor_of(point): continue
		if point.shape in ["wall","throne"]:
			point.self_modulate.a=0
			point.label.position.y=-610 if point.shape=="wall" else -575
		elif point.shape=="chain":
			_add_art(point,"res://Sprites/map/chapter6/organic/chain_anchor.png",270)
			chains.append({"point":point,"flag":StringName("garm_chain_%d" % (index+1))})
			index+=1
		elif point.shape=="hound":
			var path="res://Sprites/monsters/chapter6/runtime/garm_freed.png"
			if ResourceLoader.exists(path):
				_add_art(point,path,270)
				# Paws sit higher than the curled tail in the painting; register paws to the rear road.
				point.get_node("StorySprite").position.y+=78
				var shadow=Sprite2D.new()
				var gradient=Gradient.new()
				gradient.colors=PackedColorArray([Color(0,0,0,.4),Color(0,0,0,0)])
				var tex=GradientTexture2D.new()
				tex.width=128;tex.height=128;tex.gradient=gradient
				tex.fill=GradientTexture2D.FILL_RADIAL
				tex.fill_from=Vector2(.5,.5);tex.fill_to=Vector2(1,.5)
				shadow.texture=tex;shadow.position=Vector2(0,-22)
				shadow.scale=Vector2(2.5,.22);shadow.z_index=-1
				point.add_child(shadow)
func _add_art(point: Node2D,path: String,height: float) -> void:
	var sprite=Sprite2D.new()
	sprite.name="StorySprite"
	sprite.texture=load(path)
	var box=sprite.texture.get_image().get_used_rect()
	var factor=height/box.size.y
	sprite.centered=false
	sprite.scale=Vector2.ONE*factor
	sprite.position=Vector2(-box.get_center().x*factor,-92-box.end.y*factor)
	point.add_child(sprite)
	point.self_modulate.a=0
	point.label.position.y=-height-130
func _process(_delta: float) -> void:
	for chain in chains:
		if is_instance_valid(chain.point):
			chain.point.get_node("StorySprite").modulate=Color(.4,.43,.47) if PlayerState.has_flag(chain.flag) or PlayerState.has_flag(&"garm_resolved") else Color.WHITE
