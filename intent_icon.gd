extends Node2D

class_name IntentIcon

@export var action: TurnAction

@export var icon: TextureRect
@export var background: TextureRect
@export var label: Label

func update() -> void:
	if action == null:
		hide()
		return
	show()
	icon.texture = action.icon
	label.text = action.tooltip
	
\
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update()
	hide_hint()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	pass

func show_hint():
	if action == null:
		hide_hint()
		return
	label.text = action.tooltip
	label.show()
	background.show()

func hide_hint():
	label.text = ""
	label.hide()
	background.hide()

func _on_panel_container_mouse_entered() -> void:
	show_hint()
	pass # Replace with function body.


func _on_panel_container_mouse_exited() -> void:
	hide_hint()
	pass # Replace with function body.
