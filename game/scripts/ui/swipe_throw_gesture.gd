class_name SwipeThrowGesture
extends Control

## Full-screen swipe recognizer for directional newspaper throws: swipe
## left throws left, swipe right throws right. Uses _unhandled_input
## specifically (not _input) so a touch that started on one of the
## LEFT/BRAKE/RIGHT buttons never also registers as a swipe -- Godot
## skips _unhandled_input entirely for any event a button already
## claimed via set_input_as_handled() during the _input phase, which is
## exactly the property this relies on.

@export var min_swipe_distance: float = 60.0
@export var max_swipe_duration: float = 0.8

const MOUSE_POINTER_INDEX := -2

var _active_pointer_index: int = -1
var _start_pos: Vector2 = Vector2.ZERO
## Accumulated via _process(delta) while a pointer is held, rather than
## differencing two Time.get_ticks_msec() timestamps -- the latter can
## read as wildly inflated when the press/release pair arrives through
## certain synthetic input pipelines (observed under CDP-driven browser
## automation specifically), even though delta-based accumulation
## elsewhere (Player's own movement) tracks real elapsed time correctly
## in the exact same circumstances. Frame-accumulated duration ties this
## measurement to the same clock the rest of gameplay already trusts.
var _hold_duration: float = 0.0
var _throw_left_just_pressed: bool = false
var _throw_right_just_pressed: bool = false
var _enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _active_pointer_index != -1:
		_hold_duration += delta


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_active_pointer_index = -1


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(MOUSE_POINTER_INDEX, event.position, event.pressed)


func _handle_pointer(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _active_pointer_index == -1:
			_active_pointer_index = index
			_start_pos = pos
			_hold_duration = 0.0
	elif index == _active_pointer_index:
		_active_pointer_index = -1
		_evaluate_swipe(pos)


func _evaluate_swipe(end_pos: Vector2) -> void:
	if _hold_duration > max_swipe_duration:
		return
	var delta := end_pos - _start_pos
	if absf(delta.x) < min_swipe_distance:
		return
	if absf(delta.x) < absf(delta.y):
		return
	if delta.x < 0.0:
		_throw_left_just_pressed = true
	else:
		_throw_right_just_pressed = true


func consume_throw_left_just_pressed() -> bool:
	if _throw_left_just_pressed:
		_throw_left_just_pressed = false
		return true
	return false


func consume_throw_right_just_pressed() -> bool:
	if _throw_right_just_pressed:
		_throw_right_just_pressed = false
		return true
	return false
