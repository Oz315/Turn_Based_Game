extends Node2D

@onready var tile_map: TileMapLayer
@onready var ground_layer: TileMapLayer
@onready var move_layer: TileMapLayer

var astar_grid: AStarGrid2D

#This function just grabs the tile map layers and sets them in the right variables
#Please do note the names have to be EXACT otherwise it bugs out, also if we change the heirarchy its gonna bug out
func initialize(level_node: Node2D):
	tile_map = level_node.get_node("Background")
	ground_layer = level_node.get_node("Ground")
	move_layer = level_node.get_node("MoveOverlay")
	make_grid()
		
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
			var ground_data = ground_layer.get_cell_tile_data(tile_position + Vector2i(0, 1))
			
			#its a long if statement but just checking for the custom data
			if tile_data == null or tile_data.get_custom_data("walkable")  == false or ground_data == null or ground_data.get_custom_data("solid") == false:
				astar_grid.set_point_solid(tile_position)

#this function is what paints over the black outline for where the player can move
#I'm thinking this can be made to work with the attack_range too
func _move_range(player_pos):
	move_layer.clear()
	var player_tile = tile_map.local_to_map(player_pos)
	var max_range = 2
	
	for x in range(-max_range, max_range+1):
		for y in range(-max_range, max_range+1):
			var target_tile = player_tile + Vector2i(x,y)
			
			var path = astar_grid.get_id_path(player_tile, target_tile)
			if path.size() > 0 and path.size() <= max_range+1:
				move_layer.set_cell(target_tile, 0, Vector2i(0,0))
