extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name RangedAction

@export var damage: int
@export var max_range: int
@export var min_range: int
@export var projecile_speed: int
@export var animation_name: String = "attack"
@export var projectile_scene: PackedScene = preload("res://actions/projectiles/basic_projectile.tscn")


func random_target(caller: Node2D, target: Vector2i, level: Level) -> Vector2i:
	var caller_pos = level.tile_pos(caller)
	if validate(caller, target, level):
		return target
	var dir: Vector2i = (target - caller_pos)
	if dir.y != 0 and dir.x != 0:
		if abs(dir.y) > abs(dir.x):
			dir.x = 0
		else:
			dir.y = 0
	return caller_pos + dir.sign() * max_range

func damage_hint(caller: Node2D, target:Vector2i, level: Level) -> Array[DamageHint]:
	var caller_pos = level.tile_pos(caller)
	if validate(caller, target, level):
		var dst = target.distance_to(caller_pos)
		var a: Array[DamageHint] = []
		var dir: Vector2i = sign(target - caller_pos)
		if dir.y != 0 and dir.x != 0:
			dir.y = 0
			
		if dir.y == 0:
			for x in range(min_range, max_range + 1):
				a.append(make_hint(caller_pos + Vector2i(x * dir.x, 0), damage))
		else:
			for y in range(min_range, max_range + 1):
				a.append(make_hint(caller_pos + Vector2i(0, y * dir.y), damage))
		
		return a
	return []

func hint(caller: Node2D, level: Level) -> Array[Vector2i]:
	# iterate over everyone other than the player and show a hint at their 
	# position if they are within range
	var caller_pos = level.tile_pos(caller)
	var cells: Array[Vector2i] = []
	for pos in level.occupancy:
		if validate(caller, pos, level):
			cells.append(pos)
	return cells
	
func validate(caller: Node2D, target:Vector2i, level: Level) -> bool:
	var opponent = level.occupancy.get(target)
	if opponent == caller:
		return false
	var dst = level.tile_pos(caller).distance_to(target)
	
	if not shared_axis(level.tile_pos(caller), target):
		return false
	
	var occluded = false

	return dst <= max_range and dst >= min_range
	
func execute(caller: Node2D, target:Vector2i, level: Level):
	
	var projectile = projectile_scene.instantiate()
	caller.add_child(projectile)
	
	var anim_player = caller.get_node("AnimationPlayer") as AnimationPlayer
	
	# play the attack animation and wait for the keyframed signal to apply damage
	if anim_player != null:
		anim_player.play(animation_name)
		await caller.action_strike
	
	# wait for the projectile to impact so the turn doesn't end while things are
	# still happening
	await projectile.launch(level.tile_pos(caller), target, projecile_speed, level)
	
	var target_node = level.occupancy.get(target)
	
	if target_node != null:
		# leave the arrow in the target for fun
		projectile.reparent(target_node, true)
		apply_damage(target_node, damage)
	else:
		projectile.queue_free()
	
	if anim_player != null && anim_player.is_playing():
		await anim_player.animation_finished
	
	
