class_name PlayerInput
extends RefCounted

## Stateless helper that merges keyboard input and the on-screen mobile
## controls into a single input contract. Locomotion/throw code queries
## this instead of reading Input/touch nodes directly, so any future
## input source reuses the exact same path without caring which device
## is in use.
##
## Milestone 10 control set: steer (LEFT/RIGHT buttons or A/D, Left/Right
## arrows), brake (BRAKE button or S/Down arrow), throw left/right (a
## directional swipe, or Q/E on keyboard). There is no manual
## acceleration and no joystick -- the bike drives itself.

static func get_steer_input(touch_controls: Node) -> float:
	if touch_controls and touch_controls.has_method("get_steer_input"):
		var touch_val: float = touch_controls.get_steer_input()
		if absf(touch_val) > 0.0001:
			return touch_val
	return Input.get_axis("move_left", "move_right")


static func get_brake_held(touch_controls: Node) -> bool:
	if Input.is_action_pressed("move_back"):
		return true
	if touch_controls and touch_controls.has_method("is_brake_held"):
		return touch_controls.is_brake_held()
	return false


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


static func get_throw_left_just_pressed(touch_controls: Node) -> bool:
	if Input.is_action_just_pressed("throw_left"):
		return true
	if touch_controls and touch_controls.has_method("consume_throw_left_just_pressed"):
		return touch_controls.consume_throw_left_just_pressed()
	return false


static func get_throw_right_just_pressed(touch_controls: Node) -> bool:
	if Input.is_action_just_pressed("throw_right"):
		return true
	if touch_controls and touch_controls.has_method("consume_throw_right_just_pressed"):
		return touch_controls.consume_throw_right_just_pressed()
	return false
