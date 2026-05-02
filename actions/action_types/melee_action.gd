extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name MeleeAction

@export var damage: int
@export var range: int
@export var animation_name: String = "attack"

func hint(caller: Node2D, level: Level) -> Array[Vector2i]:
	var caller_pos = level.tile_pos(caller)
	
	var cells: Array[Vector2i] = []
	
	for pos in level.occupancy:
		if validate(caller, pos, level):
			cells.append(pos)
	
	return cells
	
func validate(caller: Node2D, target:Vector2i, level: Level) -> bool:
	var opponent = level.occupancy[target]
	if opponent == caller:
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
