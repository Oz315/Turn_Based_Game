extends Control

func lose_message(how: String):
	if how == "health":
		$FailureMessage.text += "\nYou lost all your health"
	elif how == "turns":
		$FailureMessage.text += "\nYou ran out of turns and couldn't reach Darkwing in time"


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_retry_pressed():
	SignalBus.retry.emit()
	queue_free()
