extends CanvasLayer

signal end_turn

func display_actions(actions: Array[TurnAction]):
	for n in $ActionContainer.get_children():
		$ActionContainer.remove_child(n)
		n.queue_free() 
	
	for action in actions:
		var btn = Button.new()
		btn.icon = action.icon
		btn.text = action.name
		btn.pressed.connect(_on_attack_pressed.bind(btn, action))
		$ActionContainer.add_child(btn)

func _on_attack_pressed(btn: Button, action: TurnAction):
	var player = get_tree().get_first_node_in_group("player_units")
	player._on_request_action(action)

#This locking function of ui is because of issues I was having with the player turn starting before enemies finished moving
func lock_ui(locked):
	for button in get_children():
		if button is Button:
			button.disabled = locked
			button.modulate.a = 1 if !locked else 0.5
	for button in $ActionContainer.get_children():
		if button is Button:
			button.disabled = locked
			button.modulate.a = 1 if !locked else 0.5

func _on_move_pressed():
	get_tree().call_group("player_units", "_enable_move")


func _on_end_turn_pressed():
	lock_ui(true)
	end_turn.emit()
	#print("group call done for end turn")
	
