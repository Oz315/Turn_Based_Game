extends Control
@onready var win_sound = $Win

func _ready():
	win_sound.play()

	$Panel/Return.hide()
	$FinalMessage.visible_ratio = 0
	await get_tree().create_timer(2.5).timeout
	
	var tween = create_tween()
	tween.tween_property($FinalMessage, "visible_ratio", 1, 9.0)
	await tween.finished
	$Panel/Return.show()


func _on_return_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
