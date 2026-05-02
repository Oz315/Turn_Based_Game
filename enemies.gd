extends Node2D

#this is updated by level, check levels.gd for more details
var level

#I tried to use signals but I kept having issues with it so I just opted for boolean checks
var turn_finished = false
var current_id_path: Array[Vector2i]
var target_tile: Vector2i
var intent = false

# _emit_action_strike is keyframed in animations to trigger damage in attack scripts
signal action_strike
func _emit_action_strike():
	action_strike.emit()

# The list of actions/attacks this unit can play
@export var actions: Array[TurnAction] = [preload("res://actions/basic_attack.tres")]

@onready var health_bar = $ProgressBar
@onready var health_component = $HealthComponent

func _ready():
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	health_component.health = health_component.max_health
	health_bar.value = 100

func _on_health_changed(delta: int):
	health_bar.value += delta

func _on_health_depleted():
	# die, somehow
	# TODO
	queue_free()
	pass

#This was just for testing
#func _ready():
	#print(name, " has groups: ", get_groups(), " and enemy script ", name, " has method ", has_method("take_turn"))

#How each enemy takes its turn, its movement logic is basically the same as the player except its target is the player
func take_turn():
	#print("take_turn running")
	var player = get_tree().get_first_node_in_group("player_units")
	if not player:
		return
	var id_path = level.astar_grid.get_id_path(
		level.tile_map.local_to_map(global_position),
		level.tile_map.local_to_map(player.global_position)
		).slice(1, -1) #note this slice stop enemies from moving onto the players tile but will still overlap with other enemies
		#This limits movement to two tiles increase this and the 2 in slice for different movement
	if id_path.size() > 2:
		id_path = id_path.slice(0, 2)
	if id_path.is_empty() == false:
		current_id_path = id_path
	attack_area(player.global_position)
	turn_finished = true
	
func attack_area(player_position):
	target_tile = level.tile_map.local_to_map(player_position)
	intent = true


#Exact same as players
func _physics_process(delta):
	if current_id_path.is_empty():
		return
	var target_position = level.tile_map.map_to_local(current_id_path.front())
	
	global_position = global_position.move_toward(target_position, 2)
	
	if global_position == target_position:
		current_id_path.pop_front()
		SignalBus.any_moved.emit()
