extends Node2D

# Type hints
class_name Player

#check levels.gd for more details about the level variable here
var level: Level
var current_id_path: Array[Vector2i]
var has_moved = false
var is_moving = false
var is_in_move_animation = false

# Are we waiting on the player to choose a target for the attack?
var is_attacking = false 
# What attack we are waiting on
var current_action: TurnAction = null
# What targets does the player has to choose from
var current_hint: Array[Vector2i] = []
# What target did the player choose
var current_action_target: Vector2i
# Did the player click an attack target and we are waiting for the them to 
# cancel or end the turn?
var current_action_target_chosen: bool = false

var is_in_attack_animation = false
var has_attacked = false
var attack_charge_time =  0

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
	health_bar.max_value = health_component.max_health
	health_bar.value = health_component.health
	actions.append(preload("res://actions/dev_gun.tres"))

func _on_health_changed(delta: int):
	health_bar.value += delta

func _on_health_depleted():
	# update the occupancy map
	SignalBus.any_died.emit(self)
	
	# die, somehow
	# TODO
	queue_free()
	pass

#Just resets the players turn with the boolean change
func new_turn():
	has_moved = false
	has_attacked = false
	print("new turn triggering, this should only be printing once")

#This should be triggering each time you click the move button
func _enable_move():
	if has_moved or has_attacked:
		return
	# This is so that you can "cancel" your movement
	is_moving = not is_moving
	if is_moving:
		level._move_range(global_position, 2)
	else:
		level.move_layer.clear()
	is_attacking = false
	current_action_target_chosen = false
	current_action = null
	current_hint.clear()

func _on_request_action(action: TurnAction):
	if is_attacking or has_attacked:
		return
	
	is_moving = false
	current_action = action
	
	current_hint = action.hint(self, level)

	level.show_hint(current_hint, Vector2i(0, 0))
	is_attacking = true

func _on_confirm_attack():
	if current_action_target_chosen:
		current_action_target_chosen = false
		is_in_attack_animation = true
		level.move_layer.clear()
		current_hint.clear()
		await current_action.execute(self, current_action_target, level)
		has_attacked = true
		is_in_attack_animation = false
		current_action = null
		is_attacking = false


func _input(event):
	#This code was taken from the same Youtube Tutorial as the astar grid creation one, with some modifications of course
	if is_moving == false and is_attacking == false or event.is_action_pressed("click") == false or is_in_attack_animation or has_attacked:
		return

	if is_moving:
		var id_path = level.astar_grid.get_id_path(
			level.tile_map.local_to_map(global_position),
			level.tile_map.local_to_map(get_global_mouse_position())
		).slice(1)
		#This limits the player to moving two tiles, if you want to change it make sure you also change the max_range in the 
		#level script show_range func
		var target_data = level.tile_map.get_cell_tile_data(level.tile_map.local_to_map(get_global_mouse_position()))
		var on_air = target_data != null and target_data.get_custom_data("air") == true
		if id_path.is_empty() == false and (id_path.size() > 0 and id_path.size() <= 2) and not on_air and not level.occupancy.has(level.tile_map.local_to_map(get_global_mouse_position())):
			current_id_path = id_path
			is_moving = false
			level.move_layer.clear()
			has_moved = true
			is_in_move_animation = true
	if is_attacking and not is_in_attack_animation:
		
		var selected_pos = level.tile_map.local_to_map(get_global_mouse_position())
		
		if current_hint.has(selected_pos):
			current_action_target_chosen = true
			current_action_target = selected_pos
			level.show_hint(current_hint, Vector2i(0, 0))
			level.move_layer.set_cell(selected_pos, 0, Vector2i(1, 0)) # Show an attack indicator over the selected tile
		else:
			level.move_layer.clear()
			current_hint.clear()
			is_attacking = false
	

func _physics_process(delta):
	if current_id_path.is_empty():
		if is_in_move_animation:
			is_in_move_animation = false
			
			# If we are standing in fire at the end of our turn, take 1 damage
			if level.flaming_tiles.has(level.tile_pos(self)):
				health_component.take_damage(1)
				
			SignalBus.any_moved.emit()
		return
	var target_position = level.tile_map.map_to_local(current_id_path.front())
	
	#The 2 here just modifies the speed at which the player moves to its target tile
	global_position = global_position.move_toward(target_position, 2)
	
	if global_position == target_position:
		
		current_id_path.pop_front()
