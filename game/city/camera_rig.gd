extends Node3D

signal selection_requested(screen_position: Vector2)

var camera: Camera3D
var dragging := false
var press_position := Vector2.ZERO
var drag_distance := 0.0
var rotate_drag := false

func _ready() -> void:
	rotation.y = deg_to_rad(-22.0)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 64.0
	camera.position = Vector3(0, 51, 46)
	add_child(camera)
	camera.look_at(global_position)
	camera.current = true

func clamp_zoom(value: float) -> float:
	return clampf(value, 15.0, 90.0)

func can_select(over_ui: bool, distance: float) -> bool:
	return not over_ui and distance <= 6.0

func focus_on(point: Vector3) -> void:
	position = Vector3(point.x, 0, point.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and event.pressed:
			dragging = true
			rotate_drag = event.button_index == MOUSE_BUTTON_RIGHT
			press_position = event.position
			drag_distance = 0.0
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = clamp_zoom(camera.size - 3.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = clamp_zoom(camera.size + 3.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		drag_distance = maxf(drag_distance, press_position.distance_to(event.position))
		if drag_distance > 6.0:
			if rotate_drag:
				rotation.y -= event.relative.x * 0.006
			else:
				var offset := Vector3(-event.relative.x, 0, -event.relative.y * 1.45)
				position += offset.rotated(Vector3.UP, rotation.y) * camera.size / get_viewport().get_visible_rect().size.y
				position.x = clampf(position.x, -38.0, 38.0)
				position.z = clampf(position.z, -30.0, 30.0)
	elif event is InputEventMouseButton and not event.pressed and dragging:
		if event.button_index == (MOUSE_BUTTON_RIGHT if rotate_drag else MOUSE_BUTTON_LEFT):
			drag_distance = maxf(drag_distance, press_position.distance_to(event.position))
			var over_ui := get_viewport().gui_get_hovered_control() != null
			if not rotate_drag and can_select(over_ui, drag_distance):
				selection_requested.emit(event.position)
			dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		dragging = false
