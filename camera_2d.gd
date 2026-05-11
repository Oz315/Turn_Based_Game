extends Camera2D

var _target_zoom: float = 1.0
const MIN_ZOOM: float = 0.8
const MAX_ZOOM: float = 2.0
const ZOOM_INCREMENT = 0.1
const ZOOM_RATE: float = 8.0

func _physics_process(delta: float):
	zoom = lerp(zoom, _target_zoom * Vector2.ONE, ZOOM_RATE * delta)
	
func zoom_in():
	_target_zoom = min(_target_zoom + ZOOM_INCREMENT, MAX_ZOOM)
	set_physics_process(true)

func zoom_out():
	_target_zoom = max(_target_zoom - ZOOM_INCREMENT, MIN_ZOOM)
	set_physics_process(true)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative / zoom
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()

func update_borders(borders):
	# these are the actual limits in the inspector
	limit_left = borders.position.x
	limit_top = borders.position.y
	limit_right = borders.end.x
	limit_bottom = borders.end.y
	
	# just moves the camera inbounds if its outside during a change in level
	force_update_scroll()
