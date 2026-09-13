from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'balance_preview.gd').read_text(encoding='utf-8')
s=s.replace('res://output/balance/','res://output/balance_v2/').replace('BALANCE UI PREVIEW:','BALANCE V2 VISUAL:')
s=s.replace('PlayerState.stats.job_id=&"runeblade"','PlayerState.stats.change_profession(&"runeblade")',1)
s=s.replace('var upgrade: Button=skills.find_child("UpgradeSkill",true,false)','var upgrade: Button=skills.find_child("QuickLearn_rune_lunge",true,false)')
s=s.replace('inline learn button is enabled for valid prerequisites','tree node plus button is enabled for valid prerequisites')
s=s.replace('await shot("skill_window")','''skills._scroll.scroll_vertical=0
	await shot("skill_tree")''')
s=s.replace('await shot("skill_window_heavy")','await shot("skill_tree_ultimate")')
s=s.replace('player.position=Vector2(490,430)','''player.position=Vector2(490,430)
	PlayerState.equipment.equip(Equipment.EquipSlot.WEAPON,ItemInstance.create(&"runic_blade"))
	PlayerState.refresh()''')
old='''		for id in [&"faultline",&"worldcleaver"]:
'''
new='''		# All authored idle frames must carry the equipped sword's grip, mirrored correctly.
		player._play("Idle_Runeblade",true)
		player.sprite.stop()
		var visual: CharacterVisual=player.get_node("EquipVisual")
		var layer: AnimatedSprite2D=visual._layers[Equipment.EquipSlot.WEAPON]
		var first_position := Vector2.ZERO
		var moved := false
		var aligned := true
		for frame in range(32):
			player.sprite.set_frame_and_progress(frame,0.0)
			player._apply_auto_fit()
			visual._process(0)
			var pose: Vector3=preload("res://scripts/entities/runeblade_hand_track.gd").IDLE[frame]
			var expected: Vector2 = Vector2(pose.x,pose.y)-player.sprite.sprite_frames.get_frame_texture(&"Idle_Runeblade",frame).get_size()/2
			if player.sprite.flip_h: expected.x=-expected.x
			aligned=aligned and layer.position.distance_to(player.sprite.offset+expected)<0.01
			if frame==0: first_position=layer.position
			else: moved=moved or layer.position.distance_to(first_position)>5.0
			caption.text="Runeblade Idle / "+("ซ้าย" if dir<0 else "ขวา")
			await shot("idle_%s_%02d"%["left" if dir<0 else "right",frame])
		check(aligned and moved,"all 32 idle grips move with the authored hand, facing "+str(dir))
		for id in [&"faultline",&"worldcleaver"]:
'''
assert old in s;s=s.replace(old,new)
s=s.replace('player.position=Vector2(490 if dir==1 else 790,430)','player.position=Vector2(330 if dir==1 else 950,430)')
# Validate the cast snapshots the actual equipped artwork.
old='''			await shot(String(id)+("_left" if dir<0 else "_right"))'''
new='''			if id==&"faultline":
				var equipped_ok := false
				for field in player.runeblade.get_children():
					if field.get_script()==preload("res://scripts/entities/runic_blade_field.gd"):
						equipped_ok=field.weapon_visual.weapon_id==&"runic_blade" and field.weapon_visual.blade.texture==PlayerState.equipment.weapon().data().equip_texture
				check(equipped_ok,"planted field renders the equipped sword, facing "+str(dir))
			await shot(String(id)+("_left" if dir<0 else "_right"))'''
assert old in s;s=s.replace(old,new)
(ROOT/'balance_v2_preview.gd').write_text(s,encoding='utf-8')
(ROOT/'balance_v2_preview.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://balance_v2_preview.gd" id="1"]\n[node name="BalanceV2Preview" type="Node2D"]\nscript = ExtResource("1")\n',encoding='utf-8')
print('V2 visual preview prepared.')
