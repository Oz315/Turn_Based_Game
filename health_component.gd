extends Node
## A health component. Add as child to a node to let it take damage from attacks,
## assuming its also in the level.occupancy Dictionary
##
## If we want to add resistances or status effects we might do it here?

# mostly from
# https://www.youtube.com/watch?v=52rAz9tK5Fk
class_name HealthComponent

signal health_changed(diff: int)
signal health_depleted

@export var max_health: int = 10
@onready var health: int = max_health: set = set_health, get = get_health

func set_health(v: int):
	var delta = v - health
	health_changed.emit(delta)
	
	health = v
	if health == 0:
		health_depleted.emit()
		SignalBus.any_moved.emit()

func get_health() -> int:
	return health

func take_damage(damage: int):
	var actual = clampi(damage, 0, health)
	health = health - actual
	print ("entity took ", damage, " damage, current health is now: ", health)
