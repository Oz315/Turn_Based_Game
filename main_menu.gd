extends Control

#this main menu shouldn't have much more scripting,
func _on_start_pressed():
	get_tree().change_scene_to_file("res://intro_cutscene.tscn")


func _on_quit_pressed():
	get_tree().quit()
