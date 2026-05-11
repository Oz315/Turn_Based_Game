extends Control

@onready var death_sound = $Lose

func _ready():
	death_sound.play()

# could use enums but at this point, this is fine, there's only two points where these lose conditions
# would be satisfied anyway
func lose_message(how: String):
	if how == "health":
		$FailureMessage.text += "\nYou lost all your health"
	elif how == "turns":
		$FailureMessage.text += "\nYou ran out of turns and couldn't reach Darkwing in time"


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_retry_pressed():
	SignalBus.retry.emit()
	# destroy this game screen
	queue_free()
