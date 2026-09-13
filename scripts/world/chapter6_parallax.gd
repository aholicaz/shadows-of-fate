extends "res://scripts/world/chapter5_parallax.gd"
## Preserve the upper composition and show the distant river beneath open bridge arches.
func _process(delta: float) -> void:
	super._process(delta)
	var camera=get_viewport().get_camera_2d()
	if camera==null:return
	var center:Vector2=camera.get_screen_center_position()
	var size:Vector2=get_viewport_rect().size/camera.zoom
	var top:float=center.y-size.y*.5-8
	var bottom:float=maxf(786,center.y+size.y*.5+8)
	var depth:Sprite2D=$Depth
	var fit:float=(bottom-top)/depth.texture.get_height()
	depth.scale=Vector2(fit,fit)
	depth.position=Vector2(anchor_x+(center.x-anchor_x)*(1-depth_speed),(top+bottom)*.5)
	var width:float=maxf(12000,(size.x+12000)/fit)
	depth.region_rect=Rect2(depth.texture.get_width()*.5-width*.5,0,width,depth.texture.get_height())
