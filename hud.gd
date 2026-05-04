extends CanvasLayer

signal end_turn

@onready var loading_screen: ColorRect = $LoadingScreen
@onready var turn_counter: Label = $TurnCounter

func _ready():
	SignalBus.player_turn.connect(_on_player_turn)

func update_turns(current_turn: int, limit: int):
	print("label is updating to new turn " + str(current_turn))
	turn_counter.text = "Turn " + str(current_turn) + "/" + str(limit)

func fade_in(duration: float = 1.0, extra_wait_time: float = 0.5) -> void:
	loading_screen.color.a = 0.0
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(loading_screen, "color:a", 1.0, duration)
	await get_tree().create_timer(duration+extra_wait_time).timeout

func fade_out(duration: float = 1.0, extra_wait_time: float = 0.5) -> void:
	loading_screen.color.a = 1.0
	await get_tree().create_timer(extra_wait_time).timeout
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(loading_screen, "color:a", 0.0, duration)
	await get_tree().create_timer(duration).timeout
	
## Create a button for each action provided, and link it to the players _on_request_action() function
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

func _on_player_turn(player: Player):
	display_actions(player.actions)

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
	
