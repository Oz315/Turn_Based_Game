extends Node2D

#Turn queue is weird because we're loading all levels
func enemies_turn():
	var enemies = get_tree().get_nodes_in_group("enemy_units")
	var active_enemies = []
	
	#filters out enemies in current level
	for enemy in enemies:
		if enemy.is_visible_in_tree():
			active_enemies.append(enemy)
		
	#print("turnqueue: found ", enemies.size(), " enemies")
	for enemy in active_enemies:
		enemy.turn_finished = false
		enemy.take_turn()
		while not enemy.turn_finished:
			await get_tree().process_frame #just wait until enemy finished turn
		await get_tree().create_timer(0.3).timeout #then wait a bit longer because this code zooms by sometimes
			
	player_turn()

# now tell the player its their turn
func player_turn():
	get_parent().get_node("HUD").lock_ui(false)
	var all_players = get_tree().get_nodes_in_group("player_units")
	#again, there should be a better way of only selecting the current level's player
	for player in all_players:
		if player.is_visible_in_tree():
			player.new_turn()
