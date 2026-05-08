extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name MeleeAction


@export var range: int
@export var animation_name: String = "attack"
@export var damage: int

func damage_hint(caller: Node2D, target:Vector2i, level: Level) -> Array[DamageHint]:
	var caller_pos = level.tile_pos(caller)
	if validate(caller, target, level):
		var a: Array[DamageHint] = []
		var dir: Vector2i = sign(target - caller_pos)
		if dir.y != 0 and dir.x != 0:
			dir.y = 0
			
		if dir.y == 0:
			for x in range(1, range + 1):
				a.append(make_hint(caller_pos + Vector2i(x * dir.x, 0), damage))
		else:
			for y in range(1, range + 1):
				a.append(make_hint(caller_pos + Vector2i(0, y * dir.y), damage))
		
		return a
	return []

func random_target(caller: Node2D, target: Vector2i, level: Level) -> Vector2i:
	var caller_pos = level.tile_pos(caller)
	if validate(caller, target, level):
		return target
	var dir: Vector2i = sign(target - caller_pos)
	if dir.y != 0 and dir.x != 0:
		dir.y = 0
	return caller_pos + dir * range
	
	

func hint(caller: Node2D, level: Level) -> Array[Vector2i]:
	
	# iterate over everyone other than the player and show a hint
	# at their position if they are within range
	
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
	
	if not shared_axis(level.tile_pos(caller), target):
		return false
		
	return level.tile_pos(caller).distance_to(target) <= range
	
func execute(caller: Node2D, target:Vector2i, level: Level):
	var opponent = level.occupancy.get(target)
	
	if opponent == null:
		return
	
	var anim_player = caller.get_node("AnimationPlayer") as AnimationPlayer
	
	# play the attack animation and wait for the keyframed signal to apply damage
	if anim_player != null:
		anim_player.play(animation_name)
		await caller.action_strike
	
	apply_damage(opponent, damage)
	
	if anim_player != null && anim_player.is_playing():
		await anim_player.animation_finished
