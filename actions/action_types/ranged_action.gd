extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name RangedAction

@export var damage: int
@export var max_range: int
@export var min_range: int
@export var projecile_speed: int
@export var animation_name: String = "attack"
@export var projectile_scene: PackedScene = preload("res://actions/projectiles/basic_projectile.tscn")

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
	var opponent = level.occupancy[target]
	if opponent == caller:
		return false
	var dst = level.tile_pos(caller).distance_to(target)
	return dst <= max_range and dst >= min_range
	
func execute(caller: Node2D, target:Vector2i, level: Level):
	
	var projectile = projectile_scene.instantiate()
	caller.add_child(projectile)
	
	var opponent = level.occupancy.get(target)
	
	if opponent == null:
		return
	
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
	
	if anim_player != null && anim_player.is_playing():
		await anim_player.animation_finished
	
	
