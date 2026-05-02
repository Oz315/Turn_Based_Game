extends Node2D

#check levels.gd for more details about the level variable here
var level
var current_id_path: Array[Vector2i]
var has_moved = false
var is_moving = false
#I haven't implemented an attack mode yet
var is_attacking = false 

# _emit_action_strike is keyframed in animations to trigger damage in attack scripts
signal action_strike
func _emit_action_strike():
	action_strike.emit()

# The list of actions/attacks available to the player
@export var actions: Array[TurnAction] = [preload("res://actions/basic_attack.tres")]

@onready var health_bar = $ProgressBar
@onready var health_component = $HealthComponent

func _ready():
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)

func _on_health_changed(delta: int):
	health_bar.value += delta

func _on_health_depleted():
	# die, somehow
	# TODO
	queue_free()
	pass

#Just resets the players turn with the boolean change
func new_turn():
	has_moved = false
	print("new turn triggering, this should only be printing once")

#This should be triggering each time you click the move button
func _enable_move():
	if has_moved:
		return
	# This is so that you can "cancel" your movement
	is_moving = not is_moving
	if is_moving:
		level._move_range(global_position)
	else:
		level.move_layer.clear()
		
func _input(event):
	#This code was taken from the same Youtube Tutorial as the astar grid creation one, with some modifications of course
	if is_moving == false or event.is_action_pressed("click") == false:
		return
	var id_path = level.astar_grid.get_id_path(
		level.tile_map.local_to_map(global_position),
		level.tile_map.local_to_map(get_global_mouse_position())
	).slice(1)
	#This limits the player to moving two tiles, if you want to change it make sure you also change the max_range in the 
	#level script show_range func
	if id_path.is_empty() == false and (id_path.size() > 0 and id_path.size() <= 2):
		current_id_path = id_path
		is_moving = false
		level.move_layer.clear()
		has_moved = true
	
func _physics_process(delta):
	if current_id_path.is_empty():
		return
	var target_position = level.tile_map.map_to_local(current_id_path.front())
	
	#The 2 here just modifies the speed at which the player moves to its target tile
	global_position = global_position.move_toward(target_position, 2)
	
	if global_position == target_position:
		current_id_path.pop_front()
