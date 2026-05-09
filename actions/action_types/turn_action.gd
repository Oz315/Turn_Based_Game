extends Resource
## Base class for attacks
##
## To make a new attack, derive a class from this one and override hint(), validate(),
## and execute(). See actions/melee_action.gd
## Add helpers to this class if they can be resused across attacks, like walkable_cells()

class_name TurnAction

@export var icon: Texture2D = preload("res://actions/icons/no_icon_attack.png")
@export var name: String = "Unnamed Attack"
@export var tooltip: String = "If you are reading this you forgot to specialize the tooltip for your new attack"

## Helper class to hold a position and damage amount.
## Represents the damage a tile will recieve from an attack next turn
class DamageHint:
	var dmg: int
	var target: Vector2i

func make_hint(target: Vector2i, dmg: int) -> DamageHint:
	var h: DamageHint = DamageHint.new()
	h.dmg = dmg
	h.target = target
	return h

# use the levels ASTAR grid to find walkable cells within a given range
func walkable_cells(pos: Vector2i, range: int, level: Level) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range, range):
		for y in range(-range, range):
			var p = pos + Vector2i(x, y)
			if not level.astar_grid.is_in_bounds(p.x, p.y):
				continue
			if not level.astar_grid.is_point_solid(p):
				cells.append(p)
	return cells

func occupied_cells(pos: Vector2i, range: int, level: Level) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for opponent_pos in level.occupancy:
		if pos.distance_to(opponent_pos) <= range:
			cells.append(opponent_pos)
	return cells

func shared_axis(a: Vector2i, b: Vector2i) -> bool:
	return a.x == b.x or a.y == b.y

# Maybe these helpers should be pulled up into Levels or a separate Utils class
static func health_component(node: Node) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child
	return null

static func keep_dominant_axis(v: Vector2i) -> Vector2i:
	if abs(v.x) >  abs(v.y):
		return Vector2i(v.x, 0)
	else:
		return Vector2i(0, v.y)

## Takes occlusion into account, won't point into a wall if it can help it
static func approx_linear_direction(source: Vector2i, target: Vector2i, level: Level, offset: int = 0) -> Vector2i:
	var v: Vector2i = target - source
	var c: Array[Vector2i] = []
	if abs(v.x) >  abs(v.y):
		c.append(Vector2i(v.x, 0))
		c.append(Vector2i(0, v.y))
		c.append(Vector2i(0, -v.y))
		c.append(Vector2i(-v.x, 0))
	else:
		c.append(Vector2i(v.x, 0))
		c.append(Vector2i(0, v.y))
		c.append(Vector2i(0, -v.y))
		c.append(Vector2i(-v.x, 0))
	for candidate in c:
		if not level.blocks_projectiles(source + sign(candidate) + sign(candidate) * offset):
			return sign(candidate)
	return Vector2i(1, 0)
	
	

## returns true if damage was applied, false otherwise
static func apply_damage(node: Node, dmg: int) -> bool:
	if node == null:
		return false
	var hc = health_component(node)
	if hc == null:
		return false
	hc.take_damage(dmg)
	return true

# override in attack scripts. See melee_action.gd

## Pick a random cell to attack, even if there is nothing there.
## At this point this is basically the enemy attack AI so maybe it should go into
## the enemy resources, if they only have one or two attacks?
func random_target(caller: Node2D, target: Vector2i, level: Level) -> Vector2i:
	return target

# Which cells would take damage from this attack?
func damage_hint(caller: Node2D, target:Vector2i, level: Level) -> Array[DamageHint]:
	return []

## Return an array of all grid positions that are valid targets for this action
func hint(caller: Node2D, level: Level) -> Array[Vector2i]:
	return []

## Check if a target is valid for this action
func validate(caller: Node2D, target:Vector2i, level: Level) -> bool:
	return true

## Play animations, apply damage, spawn projectiles, etc
func execute(caller: Node2D, target:Vector2i, level: Level):
	var anim = caller.get_node("AnimatedSprite2D")
	if anim:
		anim.play("attack")
	print(caller.name, " does nothing to ", target)
