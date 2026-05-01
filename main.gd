extends Node2D

# So the best thing we can do is have each level as its own scene, its not the most enjoyable but its most
# optimal and from what I've read the best practice in cases like ours
# If you want to make a new level, please make it from the levels.tscn in the folder all_levels, its the 'base level structure'
# Just right-click it and click new inherited scene
# Right now this script only grabs the first level but once we have the ability to defeat enemies we can pretty quickly
# add a function to check for that condition and just call the load_level function on the next level like load_level(level%d)
# with the %d being the level number and we just increment it
func _ready():
	load_level("res://all_levels/level1.tscn")
	#Signal from HUD will tell TurnQueue to do its enemies_turn function
	$HUD.end_turn.connect($TurnQueue.enemies_turn)

#making this a function so we can call it to load the other levels
func load_level(level):
	for child in $Levels.get_children():
		child.queue_free()
	var new_level = load(level).instantiate()
	$Levels.add_child(new_level)
	new_level.initialize()
	print("loaded level ", level)
	
