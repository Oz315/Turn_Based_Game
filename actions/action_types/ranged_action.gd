extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name RangedAction

@export var damage: int
@export var max_range: int
@export var min_range: int
@export var projecile_speed: int
@export var animation_name: String = "attack"
@export var projectile_scene: PackedScene = preload("res://actions/projectiles/basic_projectile.tscn")

@export var always_shoot_max_range: bool = true

func random_target(caller: Node2D, target: Vector2i, level: Level) -> Vector2i:
	var caller_pos = level.tile_pos(caller)
	# target a closer tile if the target is closer than max range
	#if validate(caller, target, level):
		#return target
	var dir: Vector2i = (target - caller_pos)
	if dir.y != 0 and dir.x != 0:
		if abs(dir.y) > abs(dir.x):
			dir.x = 0
		else:
			dir.y = 0
	return caller_pos + dir.sign() * max_range

func damage_hint(caller: Node2D, target:Vector2i, level: Level) -> Array[DamageHint]:
	var caller_pos = level.tile_pos(caller)
	var raycast_target: Vector2i = target
	if always_shoot_max_range:
		raycast_target += (target - caller_pos) * max_range
	if validate(caller, target, level):
		
		var a: Array[DamageHint] = []
		var hit: Vector2i = level.axis_aligned_raycast(caller_pos, target, max_range)
		var pos: Vector2i = caller_pos
		var dir = (hit - caller_pos).sign()
		var dst: int = 0
		while true:
			if dst > min_range and dst <= max_range:
				a.append(make_hint(pos, damage))
			if pos == hit or pos == target and not always_shoot_max_range:
				break
			pos += dir
			dst += 1
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
	
	var damage_hints = damage_hint(caller, target, level)
	
	# HACK: assumes the damage hints are ordered by arrow travel, i.e. closest first
	var arrow_target_hint = damage_hints.back()
	
	# no damage
	if arrow_target_hint == null:
		projectile.queue_free()
		return
		
	# wait for the projectile to impact so the turn doesn't end while things are
	# still happening
	await projectile.launch(level.tile_pos(caller), arrow_target_hint.target, projecile_speed, level)
	
	var stuck_in_target: bool = false
	
	# use the damage hints so the damage always lines up with expectations
	for hint in damage_hints:
		var target_node = level.occupancy.get(hint.target)
		
		if target_node != null:
			apply_damage(target_node, damage)
			
			# leave the arrow in the target for fun
			if not always_shoot_max_range and hint.target == target:
				projectile.reparent(target_node, true)
				stuck_in_target = true
				
	if not stuck_in_target:
		projectile.queue_free()
		
	
	if anim_player != null && anim_player.is_playing():
		await anim_player.animation_finished
	
	
