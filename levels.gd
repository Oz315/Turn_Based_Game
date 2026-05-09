extends Node2D

# added for syntax highlighting / linting / autocomplete
# not sure if it interferes with anything else or not
class_name Level

@onready var tile_map: TileMapLayer
@onready var move_layer: TileMapLayer
@onready var attack_hint_layer: TileMapLayer
@onready var ground_layer: TileMapLayer
@export var turn_limit: int = 15
var astar_grid: AStarGrid2D

var occupancy: Dictionary[Vector2i, Node2D]
var damage_hints: Array[TurnAction.DamageHint]

## The number of player turns remaining before the fire goes out
var flaming_tiles: Dictionary[Vector2i, int]

signal occupancy_changed

#improved pathing, instead of having player and enemies find the level root, this level root
#just gives its location to them, so its more dynamic and doesn't matter where they hide, so long
#as they are in the right groups
func initialize():
	tile_map = %WalkableTiles
	move_layer = %MoveOverlay
	attack_hint_layer = %AttackOverlay
	ground_layer = %Ground
	make_grid()
	var units = get_tree().get_nodes_in_group("player_units") + get_tree().get_nodes_in_group("enemy_units")
	var player = null
	for unit in units:
		if unit is Player:
			player = unit
		unit.level = self #updates the variable level in enemies and player
	SignalBus.any_moved.connect(_on_any_moved)
	SignalBus.any_died.connect(_on_any_moved)

	SignalBus.player_turn.connect(_on_player_turn)

	# HACK: Im not sure where to put this, but player turns seem to happen without
	# the turn() function at the start of each level
	SignalBus.player_turn.emit(player)



func tile_pos(node: Node2D):
	return tile_map.local_to_map(node.global_position)

func _on_any_moved():
	update_occupancy()

func _on_any_died(unit):
	update_occupancy()

func _on_player_turn(player):
	update_flaming_tiles()

func update_occupancy():
	occupancy.clear()
	var tree = get_tree()
	if tree == null:
		return
	var units = tree.get_nodes_in_group("player_units") + tree.get_nodes_in_group("enemy_units")
	for unit in units:
		occupancy[tile_map.local_to_map(unit.global_position)] = unit
		if unit is Node and not unit.is_connected("tree_exited", update_occupancy):
			unit.tree_exited.connect(update_occupancy)
	occupancy_changed.emit()

#This is in levels so we only have to generate it every new level, from my understanding most of these commands are
#just standard protocol when making an AStarGrid2D, I got this from a Youtube Tutorial btw
# Diagonal movement is now possible, within the WalkableTiles there is now a black tile
# which should just be treated as a tile you can walk pass but never land on, put it for corners where you
# want the player to step up
func make_grid():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(32, 32)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)

			var tile_data = tile_map.get_cell_tile_data(tile_position)
			#This ground_data is so that it checks if there is "ground" beneath the player so that they
			#don't just fly into the sky

			#its a long if statement but just checking for the custom data
			if tile_data == null:
				astar_grid.set_point_solid(tile_position)

#this function is what paints over the black outline for where the player can move
#I'm thinking this can be made to work with the attack_range too
func _move_range(player_pos, range):
	move_layer.clear()
	var player_tile = tile_map.local_to_map(player_pos)

	for x in range(-range, range+1):
		for y in range(-range, range+1):
			var target_tile = player_tile + Vector2i(x,y)

			var path = astar_grid.get_id_path(player_tile, target_tile)
			if path.size() > 0 and path.size() <= range+1:
				var tile_data = tile_map.get_cell_tile_data(target_tile)
				if (tile_data == null or tile_data.get_custom_data("air") == true) and not occupancy.has(target_tile):
					continue
				move_layer.set_cell(target_tile, 0, Vector2i(0,0))

## Used by ranged_action.gd to stop arrows from going through solid objects.
## A separate function because I wasn't sure which tilemap would be best
func blocks_projectiles(pos: Vector2i) -> bool:
	var walkable = tile_map.get_cell_source_id(pos) != -1
	var empty = ground_layer.get_cell_source_id(pos) == -1
	return not walkable and not empty

## return the closest cell that is not obstructed, snapped to linear/axis-aligned directions
func axis_aligned_raycast(origin: Vector2i, target: Vector2i, max_range: int = 30):
	var dir: Vector2i = sign(target - origin)
	if dir.y != 0 and dir.x != 0:
		if abs(dir.y) > abs(dir.x):
			dir.x = 0
		else:
			dir.y = 0
	var pos: Vector2i = origin
	for i in range(max_range):
		if blocks_projectiles(pos + dir):
			break
		pos += dir
	return pos
	

func cell_on_ground(pos: Vector2i) -> bool:
	if ground_layer == null:
		return false
	# "on ground" if there is a foreground cell beneath it but no cell at the position

	# allow fire to be placed on fire
	var occupied = ground_layer.get_cell_source_id(pos) != -1 and ground_layer.get_cell_source_id(pos) != 13

	# disallow fire to be placed over air, fire, platforms, or water
	var denylist: Array[int] = [-1,  13, 5, 12]
	var floating = denylist.has(ground_layer.get_cell_source_id(pos + Vector2i(0, 1)))
	return not occupied and not floating

func update_flaming_tiles():
	var to_remove: Array[Vector2i] = []
	for pos in flaming_tiles:

		var t = flaming_tiles[pos]
		t -= 1
		flaming_tiles[pos] = t
		if t <= 0:
			to_remove.append(pos)
		else:
			ground_layer.set_cell(pos, 13, Vector2i(0, 0))
	for pos in to_remove:
		flaming_tiles.erase(pos)
		ground_layer.erase_cell(pos)


func add_flaming_tile(pos: Vector2i, duration: int):
	if duration <= 0 or !cell_on_ground(pos):
		return

	var last = flaming_tiles.get_or_add(pos, 0)
	flaming_tiles[pos] = last + duration
	ground_layer.set_cell(pos, 13, Vector2i(0, 0))

func show_hint(positions: Array[Vector2i], atlas_coords: Vector2i):
	move_layer.clear()
	for pos in positions:
		move_layer.set_cell(pos, 0, atlas_coords)

func add_damage_hints(new_damage_hints: Array[TurnAction.DamageHint]):
	damage_hints.append_array(new_damage_hints)
	show_damage_hints()

func remove_damage_hints(new_damage_hints: Array[TurnAction.DamageHint]):
	for hint in new_damage_hints:
		damage_hints.erase(hint)

	show_damage_hints()

func show_damage_hints():
	if attack_hint_layer == null:
		return
	attack_hint_layer.clear()
	for hint in damage_hints:
		attack_hint_layer.set_cell(hint.target, 0, Vector2i(2, 0))
