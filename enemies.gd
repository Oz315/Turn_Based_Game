extends Node2D

# Type hints
class_name Enemy

#this is updated by level, check levels.gd for more details
var level

#I tried to use signals but I kept having issues with it so I just opted for boolean checks
var is_moving = false
var current_id_path: Array[Vector2i]
var target_tile: Vector2i
var intent = false

signal done_moving

# _emit_action_strike is keyframed in animations to trigger damage in attack scripts
signal action_strike
func _emit_action_strike():
	action_strike.emit()

# The list of actions/attacks this unit can play
@export var actions: TurnAction = preload("res://actions/basic_attack.tres")
@export var enemy_type: EnemyType = preload("res://enemy_types/shark_enemy.tres")

@onready var health_bar = $ProgressBar
@onready var health_component = $HealthComponent

func _ready():
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)

	health_component.health = enemy_type.max_health
	health_bar.max_value = enemy_type.max_health
	health_bar.value = health_component.health
	$AnimatedSprite2D.sprite_frames = enemy_type.sprites
	$AnimatedSprite2D.play("static")

func _on_health_changed(delta: int):
	health_bar.value += delta

func _on_health_depleted():
	# update the occupancy map
	SignalBus.any_died.emit(self)
	
	# die, somehow
	# TODO
	queue_free()
	pass

#This was just for testing
#func _ready():
	#print(name, " has groups: ", get_groups(), " and enemy script ", name, " has method ", has_method("take_turn"))

#How each enemy takes its turn, its movement logic is basically the same as the player except its target is the player
func take_turn():
	if level != null:
		level.occupancy_changed.connect(_on_occupancy_changed)
	#print("take_turn running")
	var player = get_tree().get_first_node_in_group("player_units")
	if not player:
		#should have some code here to end the game, maybe have the player be able to replay the level
		return
	#level.occupancy.erase(level.tile_map.local_to_map(global_position))
	var id_path = level.astar_grid.get_id_path(
		level.tile_map.local_to_map(global_position),
		level.tile_map.local_to_map(player.global_position)
		).slice(1, -1) #note this slice stop enemies from moving onto the players tile but will still overlap with other enemies
		#This limits movement to two tiles increase this and the 2 in slice for different movement
	if id_path.size() > enemy_type.move_range:
		id_path = id_path.slice(0, enemy_type.move_range)
	while id_path.is_empty() == false and level.occupancy.has(id_path[-1]):
		id_path.pop_back()
	if id_path.is_empty() == false:
		current_id_path = id_path
	#level.occupancy[level.tile_map.local_to_map(global_position)] = self
	first_playable_attack(player)
	is_moving = true
	await done_moving
	
	
func first_playable_attack(player: Node2D):
	var positions = actions.hint(self, level)
	for position in positions:
		if level.occupancy.get(position) is Player:
			await actions.execute(self, positions.pick_random(), level)
			break;

func update_intent():
	var positions = actions.hint(self, level)
	for position in positions:
		if level.occupancy.get(position) is Player:
			var hints = actions.damage_hint(self, position, level)
			for hint in hints:
				print("Intending to attack ", hint.target_node.name, " for ", hint.dmg)
			break;

func _on_occupancy_changed():
	update_intent()

#Exact same as players
func _physics_process(delta):
	if current_id_path.is_empty():
		if is_moving:
			SignalBus.any_moved.emit()
			done_moving.emit()
			is_moving = false
		return
	var target_position = level.tile_map.map_to_local(current_id_path.front())
	
	$AnimatedSprite2D.play("walk")
	global_position = global_position.move_toward(target_position, 2)
	
	if global_position == target_position:
		current_id_path.pop_front()
		$AnimatedSprite2D.stop()
		
