extends CanvasLayer

signal end_turn

#This locking function of ui is because of issues I was having with the player turn starting before enemies finished moving
func lock_ui(locked):
	for button in get_children():
		button.disabled = locked
		button.modulate.a = 1 if !locked else 0.5

func _on_move_pressed():
	get_tree().call_group("player_units", "_enable_move")


func _on_end_turn_pressed():
	lock_ui(true)
	end_turn.emit()
	#print("group call done for end turn")
	
