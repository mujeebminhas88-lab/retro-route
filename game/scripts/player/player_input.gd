class_name PlayerInput
extends RefCounted

## Stateless helper that merges keyboard input and the on-screen touch
## controls (virtual joystick + jump button) into a single input contract.
## Locomotion controllers query this instead of reading Input/touch nodes
## directly, so a future locomotion variant (e.g. BMX steering) can reuse
## the exact same input path without caring which device is in use.

static func get_move_vector(touch_controls: Node) -> Vector2:
	if touch_controls and touch_controls.has_method("get_move_vector"):
		var touch_vec: Vector2 = touch_controls.get_move_vector()
		if touch_vec.length_squared() > 0.0001:
			return touch_vec
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


static func get_speed_scale(touch_controls: Node) -> float:
	if touch_controls and touch_controls.has_method("get_move_vector"):
		var touch_vec: Vector2 = touch_controls.get_move_vector()
		if touch_vec.length_squared() > 0.0001:
			return clampf(touch_vec.length(), 0.0, 1.0)
	return 0.5 if Input.is_action_pressed("walk_modifier") else 1.0


static func get_jump_just_pressed(touch_controls: Node) -> bool:
	if Input.is_action_just_pressed("jump"):
		return true
	if touch_controls and touch_controls.has_method("consume_jump_just_pressed"):
		return touch_controls.consume_jump_just_pressed()
	return false


static func get_jump_held(touch_controls: Node) -> bool:
	if Input.is_action_pressed("jump"):
		return true
	if touch_controls and touch_controls.has_method("is_jump_held"):
		return touch_controls.is_jump_held()
	return false


static func get_throw_just_pressed(touch_controls: Node) -> bool:
	if Input.is_action_just_pressed("throw"):
		return true
	if touch_controls and touch_controls.has_method("consume_throw_just_pressed"):
		return touch_controls.consume_throw_just_pressed()
	return false
