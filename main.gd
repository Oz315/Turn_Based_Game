extends Node2D

#We can use an array of packed scenes to not have such specific paths but if we do that
# it just has the problem of loading all the levels at once, which is what we were trying to avoid in the
# first place
var level_list = [
	"res://all_levels/level1.tscn",
	"res://all_levels/level2.tscn"
]

#this is a temporary fix to a problem i was having
var in_level_transition = false

var current_level = 0
# So the best thing we can do is have each level as its own scene, its not the most enjoyable but its most
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
#making this a function so we can call it to load the other levels

func turn_update(current_turn: int):
	print("updating turn counter")
	var level = $Levels.get_child(0)
	if level:
		$HUD.update_turns(current_turn, level.turn_limit)
	else:
		print("cant find labels")
	if current_turn > level.turn_limit:
		print("turn limit reached, you lose")
		#should end game

func load_level(level):
	for child in $Levels.get_children():
		child.queue_free()
	var new_level = load(level).instantiate()
	$Levels.add_child(new_level)
	new_level.initialize()
	await $HUD.fade_out()
	$HUD.update_turns(1, new_level.turn_limit)
	print("loaded level ", level)
	in_level_transition = false


func _on_unit_died(unit):
	if in_level_transition:
		return

	await get_tree().process_frame #if you remove this it'll miss the enemy death check

	var enemies = get_tree().get_nodes_in_group("enemy_units")
	if enemies.is_empty() or enemies.size() == 1 and enemies[0] == unit:
		advance_level()


func advance_level():
	in_level_transition = true
	#if we want to have a victory screen gotta call it before the fade_in
	await $HUD.fade_in()
	print("no more enemies remain")
	current_level += 1
	if current_level < level_list.size():
		load_level(level_list[current_level])
	else:
		#should have some signal to hud to print a victory screen
		print("you win")
