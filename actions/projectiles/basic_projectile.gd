extends Node2D

class_name BasicProjectile

@export var sprite: Texture2D

func launch(start: Vector2i, target: Vector2i, speed: int, level: Level):
	global_position = level.tile_map.map_to_local(start)
	var target_position: Vector2 = level.tile_map.map_to_local(target)
	print("projectile launched")
	look_at(target_position)
	
	var distance = global_position.distance_to(target_position)
	var time = distance / speed
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, time)
	await tween.finished
	print("projectile impact")
	return
