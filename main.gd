extends Node2D

# HERE IS WHERE YOU ADD YOUR LEVELS
# Just click and drage them from the filesystem here, and make sure they're in the all_levels folder
var level_list = [
	"res://all_levels/level1.tscn",
	"res://all_levels/level2.tscn",
	"res://all_levels/level3.tscn",
	"res://all_levels/level4.tscn",
	"res://all_levels/level5.tscn",
	"res://all_levels/level6.tscn"
]

var in_level_transition = false

var current_level = 0
# So the best thing we can do is have each level as its own scene, its not the most pretty but its most
# optimal and from what I've read the best practice in cases like ours
# If you want to make a new level, please make it from the levels.tscn in the folder all_levels, its the 'base level structure'
# Just right-click it and click new inherited scene
func _ready():
	load_level(level_list[current_level])
	#Signal from HUD will tell TurnQueue to do its enemies_turn function
	$HUD.end_turn.connect($TurnQueue.enemies_turn)
	$HUD.fade_out()
	SignalBus.any_died.connect(_on_unit_died)
	SignalBus.inc_turn.connect(turn_update)
	SignalBus.reset_turns.connect($TurnQueue.reset_turns_count)
	SignalBus.retry.connect(retry_level)

func turn_update(current_turn: int):
	#print("updating turn counter")
	var level = $Levels.get_child(0)
	if level:
		$HUD.update_turns(current_turn, level.turn_limit)
	else:
		print("cant find turn label")
	if current_turn > level.turn_limit:
		show_game_over("turns")

func load_level(level):
	for child in $Levels.get_children():
		child.queue_free()
	var new_level = load(level).instantiate()
	$Levels.add_child(new_level)
	new_level.initialize()
	$Camera2D.update_borders(new_level.get_level_borders())
	await $HUD.fade_out()
	if !$Music.playing:
		$Music.play()
	$HUD.update_turns(1, new_level.turn_limit)
	SignalBus.reset_turns.emit()
	$TurnQueue.player_turn()
	#print("loaded level ", level)
	
	in_level_transition = false


func _on_unit_died(unit):
	if in_level_transition:
		return

	await get_tree().process_frame #if you remove this it'll miss the enemy death check

	var enemies = get_tree().get_nodes_in_group("enemy_units")
	if enemies.is_empty() or enemies.size() == 1 and enemies[0] == unit:
		advance_level()
	var player = get_tree().get_nodes_in_group("player_units")
	if player.is_empty():
		# couldn't think of a better way than this though there should be one, I can't think of it right now
		show_game_over("health")

func retry_level():
	in_level_transition = true
	load_level(level_list[current_level])

func show_game_over(how: String):
	await $HUD.fade_in()
	var game_over_scene = load("res://game_over_screen.tscn").instantiate()
	game_over_scene.lose_message(how)
	# If we don't add it to the canvas layer of HUD, it can get a bit buggy with it overlapping with units and astar grid
	$HUD.add_child(game_over_scene)

func game_win():
	get_tree().change_scene_to_file("res://game_win.tscn")

func advance_level():
	in_level_transition = true
	await $HUD.level_win()
	await $HUD.fade_in()
	#print("no more enemies remain")
	current_level += 1
	if current_level < level_list.size():
		load_level(level_list[current_level])
	else:
		$Music.stop()
		game_win()
