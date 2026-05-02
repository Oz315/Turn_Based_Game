extends Resource
## Base class for attacks
##
## To make a new attack, derive a class from this one and override hint(), validate(), 
## and execute(). See actions/melee_action.gd
## Add helpers to this class if they can be resused across attacks, like walkable_cells()

class_name TurnAction


@export var icon: Texture2D = preload("res://actions/icons/no_icon_attack.png")
@export var name: String = "Unnamed Attack"

# use the levels ASTAR grid to find walkable cells within a given range
func walkable_cells(pos: Vector2i, range: int, level: Level) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(-range, range):
		for y in range(-range, range):
			var p = pos + Vector2i(x, y)
			if not level.astar_grid.is_point_solid(p):
				cells.append(p)
	return cells

func health_component(node: Node) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child
	return null

func apply_damage(node: Node, dmg: int) -> bool:
	var hc = health_component(node)
	if hc == null:
		return false
	hc.take_damage(dmg)
	return true

# override in attack scripts. See melee_action.gd
func hint(caller: Node2D, level: Level) -> Array[Vector2i]:
	return []
	
func validate(caller: Node2D, target:Vector2i, level: Level) -> bool:
	return true
	
func execute(caller: Node2D, target:Vector2i, level: Level):
	print(caller.name, " does nothing to ", target)
