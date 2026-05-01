extends Node2D

#This isn't optimal but do note if we move enemies from there current position this script won't work
@onready var level_root = $"../../.."

signal animation_strike

#I tried to use signals but I kept having issues with it so I just opted for boolean checks
var turn_finished = false
var current_id_path: Array[Vector2i]
#This is meant for showing attack area but I still haven't implemented it yet, though I might just use what Hartley had in the intial version
#but im still trying to adjust it
var target_tile: Vector2i
var intent = false
var health: int = 100

@export var available_actions: Array[TurnAction]

#This was just for testing
#func _ready():
	#print(name, " has groups: ", get_groups(), " and enemy script ", name, " has method ", has_method("take_turn"))

func _ready():
	$GridPositionComponent.tilemap = level_root.tile_map
	update_health()
	return

#How each enemy takes its turn, its movement logic is basically the same as the player except its target is the player
func take_turn():
	turn_finished = false
	#print("take_turn running")
	#This code probably could be optimized by using process mode enable and disable but that breaks things so ill leave it as is
	var player = get_tree().get_first_node_in_group("player_units")
	if not player:
		return
	
	await first_playable_attack(player)	
	
	var id_path = level_root.astar_grid.get_id_path(
		level_root.tile_map.local_to_map(global_position),
		level_root.tile_map.local_to_map(player.global_position)
		).slice(1, -1)
		#This limits movement to two tiles increase this and the 2 in slice for different movement
	if id_path.size() > 2:
		id_path = id_path.slice(0, 2)
	
	if id_path.is_empty() == false:
		current_id_path = id_path
	
	
	#attack_area(player.global_position) #does nothing right now
	

func first_playable_attack(player: Node2D):
	var action_ctx = level_root.get_action_context()
	for action in available_actions:
		print("validating action ", action.name)
		var positions = action.hint(self, action_ctx)
		if not positions.is_empty():
			await action.execute(self, positions.pick_random(), action_ctx)
			break;
	
func attack_area(player_position):
	target_tile = level_root.tile_map.local_to_map(player_position)
	intent = true

func update_health():
	$ProgressBar.value = health

func _emit_animation_strike():
	animation_strike.emit()

func take_damage(damage: int):
	health -= damage
	print("Enemy Took Damage: ", damage)
	update_health()
	return

#Exact same as players
func _physics_process(delta):
	if current_id_path.is_empty():
		turn_finished = true
		return
		
	var target_position = level_root.tile_map.map_to_local(current_id_path.front())
	
	if level_root.occupancy.get(current_id_path.front()) != null:
		current_id_path.clear()
		turn_finished = true
		return
	
	global_position = global_position.move_toward(target_position, 2)
	
	if global_position == target_position:
		SignalBus.any_moved.emit()
		current_id_path.pop_front()
