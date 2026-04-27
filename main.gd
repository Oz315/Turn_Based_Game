extends Node2D

# This initializes level 1, change the 0 to a 1  to get level 2, later I hope to have the 
# turn limit be what makes this change levels by just getting all levels children and cycling through an array
# Also we might want to look into PackedScenes, I couldn't quite understand it but it would optimize our game
# apparently a lot more just so we don't have every single level loaded into the levels scene
func _ready():
	var current_level = $Levels.get_child(0)
	$Levels.initialize(current_level)
	#Signal from HUD will tell TurnQueue to do its enemies_turn function
	$HUD.end_turn.connect($TurnQueue.enemies_turn)
