extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name MeleeAction


@export var range: int
@export var animation_name: String = "attack"
@export var damage: int
@export var hits_all_targets: bool = true

func damage_hint(caller: Node2D, target:Vector2i, level: Level) -> Array[DamageHint]:
	var caller_pos = level.tile_pos(caller)
	var raycast_target: Vector2i = target
	if hits_all_targets:
		raycast_target += (target - caller_pos) * range
	if validate(caller, target, level):
		
		if not hits_all_targets:
			return [make_hint(target, damage)]
			
		var a: Array[DamageHint] = []
		
		var hit: Vector2i = level.axis_aligned_raycast(caller_pos, target, range)
		var pos: Vector2i = caller_pos
		var dir = (hit - caller_pos).sign()
		var dst: int = 0
		while true:
			if dst >= 1 and dst <= range:
				a.append(make_hint(pos, damage))
			if pos == hit:
				break
			pos += dir
			dst += 1
		return a
	return []

func random_target(caller: Node2D, target: Vector2i, level: Level) -> Vector2i:
	var caller_pos = level.tile_pos(caller)
	if validate(caller, target, level):
		return target
	var dir: Vector2i = sign(approx_linear_direction(caller_pos, target, level))
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

	var anim_player = caller.get_node("AnimationPlayer") as AnimationPlayer
	
	# play the attack animation and wait for the keyframed signal to apply damage
	if anim_player != null:
		anim_player.play(animation_name)
		await caller.action_strike
	
	for hint in damage_hint(caller, target, level):
		var target_node = level.occupancy.get(hint.target)
		
		if target_node != null:
			apply_damage(target_node, damage)
			
	if anim_player != null && anim_player.is_playing():
		await anim_player.animation_finished
