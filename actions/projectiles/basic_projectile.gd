extends Node2D

class_name BasicProjectile

@export var sprite: Texture2D

func update_sprite():
	$Sprite2D.texture = sprite

func launch(start: Vector2i, target: Vector2i, speed: int, level: Level):
	update_sprite()
	global_position = level.tile_map.map_to_local(start)
	var target_position: Vector2 = level.tile_map.map_to_local(target)

	look_at(target_position)
	
	var distance = global_position.distance_to(target_position)
	var time = distance / speed
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, time)
	await tween.finished

	return


# https://forum.godotengine.org/t/2d-throw-item-in-the-air-with-rotation-and-land-on-the-exact-position/112784/6

func lob(start: Vector2i, target: Vector2i, speed: int, arc_height: int, spin: float, level: Level):
	update_sprite()
	global_position = level.tile_map.map_to_local(start)
	var target_position: Vector2 = level.tile_map.map_to_local(target)
	
	look_at(target_position)
	
	# not how math works but close enough
	var apex = level.tile_map.map_to_local(target + start) / 2 - Vector2(0, arc_height)
	var distance = global_position.distance_to(apex) + apex.distance_to(target_position)
	var travel_time = distance / speed

	var tween_x = create_tween().set_parallel()
	tween_x.tween_property(self, "global_position:x", target_position.x, travel_time)
	if spin > 0:
		tween_x.tween_property(self, "rotation", TAU*2*spin, travel_time).from(0)

	var tween_arc := create_tween().set_trans(Tween.TRANS_SINE)
	tween_arc.tween_property(self, "global_position:y", target_position.y - arc_height, travel_time/2.0).set_ease(Tween.EASE_OUT)
	tween_arc.tween_property(self, "global_position:y", target_position.y, travel_time/2.0).set_ease(Tween.EASE_IN)
	
	await tween_x.finished
	if tween_arc.is_running():
		await tween_arc.finished
	
	return
