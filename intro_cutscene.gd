extends Control


func _ready():
	$Story.visible_ratio = 0
	
	var tween = create_tween()
	tween.tween_property($Story, "visible_ratio", 1, 45.0)
	await tween.finished
	$Panel/Continue.text = "Continue"
	
func _on_continue_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
