extends Node2D

# Type hints
class_name Enemy

#this is updated by level, check levels.gd for more details
var level: Level

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

var next_attack: TurnAction = null
var next_attack_target: Vector2i = Vector2i(0, 0)
var current_damage_hints: Array[TurnAction.DamageHint] = []

# Description of enemy stats, sprites, and default attacks
@export var enemy_type: EnemyType = preload("res://enemy_types/shark_enemy.tres")

@onready var health_bar = $ProgressBar
@onready var health_component = $HealthComponent
@onready var intent_icon: IntentIcon = $IntentIcon

func _ready():
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)

	health_component.health = enemy_type.max_health
	health_bar.max_value = enemy_type.max_health
	health_bar.value = health_component.health
	$AnimatedSprite2D.sprite_frames = enemy_type.sprites
	$AnimatedSprite2D.play("static")

	# HACK: hard-code the first attack intent
	next_attack = enemy_type.actions[0]
	intent_icon.action = next_attack
	intent_icon.update()

func _on_health_changed(delta: int):
	health_bar.value += delta

func _on_health_depleted():
	# remove any lingering damage hints
	level.remove_damage_hints(current_damage_hints)

	# update the occupancy map
	SignalBus.any_died.emit(self)

	# apparently you need to disconnect signals
	level.occupancy_changed.disconnect(_on_occupancy_changed)

	# die, somehow
	# TODO
	queue_free()
	pass

#This was just for testing
#func _ready():
	#print(name, " has groups: ", get_groups(), " and enemy script ", name, " has method ", has_method("take_turn"))

#How each enemy takes its turn, its movement logic is basically the same as the player except its target is the player
func take_turn():
	if level != null and not level.is_connected("occupancy_changed", _on_occupancy_changed):
		level.occupancy_changed.connect(_on_occupancy_changed)
	#print("take_turn running")
	var player = get_tree().get_first_node_in_group("player_units")
	if not player:
		#should have some code here to end the game, maybe have the player be able to replay the level
		return

	await play_next_attack(player)

	player = get_tree().get_first_node_in_group("player_units")
	if player == null or not is_instance_valid(player):
		#should have some code here to end the game, maybe have the player be able to replay the level
		return

	next_attack = null
	update_intent()

	#level.occupancy.erase(level.tile_map.local_to_map(global_position))
	var id_path = level.astar_grid.get_id_path(
		level.tile_map.local_to_map(global_position),
		level.tile_map.local_to_map(player.global_position)
		).slice(1, -1) #note this slice stop enemies from moving onto the players tile but will still overlap with other enemies
		#This limits movement to two tiles increase this and the 2 in slice for different movement
	if id_path.size() > enemy_type.move_range:
		id_path = id_path.slice(0, enemy_type.move_range)
	while id_path.is_empty() == false:
		var tile_data = level.tile_map.get_cell_tile_data(id_path[-1])
		if (tile_data != null and tile_data.get_custom_data("air") == true) or level.occupancy.has(id_path[-1]):
			id_path.pop_back()
		else:
			break

	if id_path.is_empty() == false:
		current_id_path = id_path

	is_moving = true

	# hide damage hints while moving
	level.remove_damage_hints(current_damage_hints)
	await done_moving
	level.add_damage_hints(current_damage_hints)

	# If the player isn't dead yet, play choose another attack and update intents
	if is_instance_valid(player):
		first_playable_attack(player)


func play_next_attack(player: Player):
	# just do what the hint last turn said we would do
	if next_attack.validate(self, next_attack_target, level):
		await next_attack.execute(self, next_attack_target, level)

	#var positions = next_attack.hint(self, level)
	#for position in positions:
		#if level.occupancy.get(position) is Player:
			#await next_attack.execute(self, positions.pick_random(), level)


## Just play the first attack on any target you can
func first_playable_attack(player: Player) -> void:
	for action in enemy_type.actions:
		var positions = action.hint(self, level)
		for pos in positions:
			if level.occupancy.get(pos) is Player:
				next_attack = action;
				next_attack_target = pos
	next_attack = enemy_type.actions[0]
	next_attack_target = next_attack.random_target(self, level.tile_pos(player), level)
	update_intent()

func best_tile_to_move_to(player_tile: Vector2i) -> Vector2i:
	var enemy_tile = level.tile_map.local_to_map(global_position)
	if next_attack == null: return player_tile
	var best_tile = player_tile
	
	return best_tile
func update_intent():
	intent_icon.action = next_attack
	intent_icon.update()
	if next_attack == null:
		return

	level.remove_damage_hints(current_damage_hints)
	current_damage_hints = next_attack.damage_hint(self, next_attack_target, level)
	level.add_damage_hints(current_damage_hints)


func _on_occupancy_changed():
	if is_queued_for_deletion():
		return
	update_intent()

#Exact same as players
func _physics_process(delta):
	if current_id_path.is_empty():
		if is_moving:
			SignalBus.any_moved.emit()
			if level != null:
				level.update_occupancy() # force an update to avoid race conditions
			done_moving.emit()
			is_moving = false
		return
	var target_position = level.tile_map.map_to_local(current_id_path.front())

	$AnimatedSprite2D.play("walk")
	global_position = global_position.move_toward(target_position, 2)

	if global_position == target_position:
		current_id_path.pop_front()
		$AnimatedSprite2D.stop()
