extends TurnAction
## Basic single-target melee attacks with a range, attack animation, and damage amount

class_name AoeAction

## How much damage the attack does dead on
@export var damage: int

## How much damage falls off with each grid cell
@export var falloff: int

@export var self_damage: bool = true

@export var throw_range: int
@export var aoe_range: int
@export var arc_height: int

## Set to 0 to prevent this attack from lighting fires
@export var fire_duration: int = 0

## Measured in pixels/second
@export var projectile_speed: int

## Set to 0 to disable rotation
@export var projectile_spin: float

## Throw animation
@export var animation_name: String = "attack"

## Probably shouldn't change
@export var projectile_scene: PackedScene = preload("res://actions/projectiles/basic_projectile.tscn")
@export var projectile_icon: Texture2D

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
	return caller_pos + dir.sign() * min(abs(dir.x + dir.y), throw_range)

func damage_hint(caller: Node2D, target:Vector2i, level: Level) -> Array[DamageHint]:
	var caller_pos = level.tile_pos(caller)
	if validate(caller, target, level):
		var a: Array[DamageHint] = []
		for x in range(-aoe_range, aoe_range + 1):
			for y in range(-aoe_range, aoe_range + 1):
				var dmg: int = max(damage - min(abs(x), abs(y)) * falloff, 1)
				a.append(make_hint(target + Vector2i(x, y), dmg))
		return a
	return []

func hint(caller: Node2D, level: Level) -> Array[Vector2i]:
	var caller_pos = level.tile_pos(caller)
	var cells: Array[Vector2i] = []
	for pos in walkable_cells(caller_pos, throw_range, level):
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

	return dst <= throw_range
	
func execute(caller: Node2D, target:Vector2i, level: Level):
	
	var projectile = projectile_scene.instantiate()
	projectile.sprite = projectile_icon
	caller.add_child(projectile)
	
	var anim_player = caller.get_node("AnimationPlayer") as AnimationPlayer
	
	# play the attack animation and wait for the keyframed signal to apply damage
	if anim_player != null:
		anim_player.play(animation_name)
		await caller.action_strike
	
	# wait for the projectile to impact so the turn doesn't end while things are
	# still happening
	await projectile.lob(level.tile_pos(caller), target, projectile_speed, arc_height, projectile_spin, level)
	
	var target_node = level.occupancy.get(target)
	
	for hint in damage_hint(caller, target, level):
		target_node = level.occupancy.get(hint.target)
		if target_node != null and (target_node != caller or self_damage):
			apply_damage(target_node, hint.dmg)
		if fire_duration > 0:
			level.add_flaming_tile(hint.target, fire_duration)
					
	projectile.queue_free()
	
	if anim_player != null && anim_player.is_playing():
		await anim_player.animation_finished
	
	
