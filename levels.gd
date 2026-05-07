extends Node2D

# added for syntax highlighting / linting / autocomplete
# not sure if it interferes with anything else or not
class_name Level

@onready var tile_map: TileMapLayer
@onready var move_layer: TileMapLayer
@export var turn_limit: int = 15
var astar_grid: AStarGrid2D

var occupancy: Dictionary[Vector2i, Node2D]
signal occupancy_changed

#improved pathing, instead of having player and enemies find the level root, this level root
#just gives its location to them, so its more dynamic and doesn't matter where they hide, so long
#as they are in the right groups
func initialize():
	tile_map = %WalkableTiles
	move_layer = %MoveOverlay
	make_grid()
	var units = get_tree().get_nodes_in_group("player_units") + get_tree().get_nodes_in_group("enemy_units")
	var player = null
	for unit in units:
		if unit is Player:
			player = unit
		unit.level = self #updates the variable level in enemies and player
	SignalBus.any_moved.connect(_on_any_moved)
	SignalBus.any_died.connect(_on_any_moved)
	
	# HACK: Im not sure where to put this, but player turns seem to happen without 
	# the turn() function at the start of each level
	SignalBus.player_turn.emit(player)
		

func tile_pos(node: Node2D):
	return tile_map.local_to_map(node.global_position)

func _on_any_moved():
	update_occupancy()

func _on_any_died(unit):
	update_occupancy()

func update_occupancy():
	occupancy.clear()
	var tree = get_tree()
	if tree == null:
		return
	var units = tree.get_nodes_in_group("player_units") + tree.get_nodes_in_group("enemy_units")
	for unit in units:
		occupancy[tile_map.local_to_map(unit.global_position)] = unit
		if unit is Node:
			unit.tree_exited.connect(update_occupancy)
	occupancy_changed.emit()

#This is in levels so we only have to generate it every new level, from my understanding most of these commands are
#just standard protocol when making an AStarGrid2D, I got this from a Youtube Tutorial btw
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
			if tile_data == null or tile_data.get_custom_data("walkable")  == false:
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
				move_layer.set_cell(target_tile, 0, Vector2i(0,0))

func show_hint(positions, atlas_coords):
	move_layer.clear()
	for pos in positions:
		move_layer.set_cell(pos, 0, atlas_coords)
