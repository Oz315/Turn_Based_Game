extends Node2D

var current_turn = 1

func reset_turns_count():
	current_turn = 1
#Turn queue is weird because we're loading all levels
func enemies_turn():
	var enemies = get_tree().get_nodes_in_group("enemy_units")
		
	#print("turnqueue: found ", enemies.size(), " enemies")
	for enemy in enemies:
		if !is_instance_valid(enemy):
			continue
		await enemy.take_turn()
		await get_tree().create_timer(0.1).timeout #then wait a bit longer because this code zooms by sometimes
	current_turn += 1
	SignalBus.inc_turn.emit(current_turn)
	player_turn()

# now tell the player its their turn
func player_turn():
	get_parent().get_node("HUD").lock_ui(false)
	
	#This is made so if we have multiple characters for the player to control, it likely won't be possible but just in
	#case its here if we have the time, i think we'd just have to add something to players to like
	# when character sprite clicked then play or something
	var all_players = get_tree().get_nodes_in_group("player_units")
	for player in all_players:
		if player is Player:
			SignalBus.player_turn.emit(player)
			player.new_turn()
