class_name SwipeThrowGesture
extends Control

## Full-screen swipe recognizer for directional newspaper throws: swipe
## left throws left, swipe right throws right. Uses _unhandled_input
## specifically (not _input) so a touch that started on one of the
## LEFT/BRAKE/RIGHT buttons never also registers as a swipe -- Godot
## skips _unhandled_input entirely for any event a button already
## claimed via set_input_as_handled() during the _input phase, which is
## exactly the property this relies on.
##
## Milestone 10.1: tracks every concurrent pointer (a Dictionary keyed by
## touch index), not just one. The previous single-`int` tracker silently
## dropped a second finger's whole gesture -- press *and* eventual
## release -- if it began before the first finger's release had been
## processed. On a phone doing fast alternating throws (or simply
## holding a control with one hand while swiping with the other), two
## touches overlapping in time is normal, not an edge case, so this was
## a real "rapid swipes fail to register" bug, not just a theoretical one.

@export var min_swipe_distance: float = 60.0
@export var max_swipe_duration: float = 0.8

const MOUSE_POINTER_INDEX := -2

## index -> { start_pos: Vector2, hold_duration: float }
var _tracked_pointers: Dictionary = {}
var _throw_left_just_pressed: bool = false
var _throw_right_just_pressed: bool = false
var _enabled: bool = true

## Briefly true right after a completed gesture is rejected (too slow,
## too short, or too vertical) -- a self-contained visual pulse so a
## deliberate swipe that just missed the threshold reads as "didn't
## register, try again" rather than silently nothing happening at all.
var _reject_flash: float = 0.0
const REJECT_FLASH_DURATION := 0.18


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	for state in _tracked_pointers.values():
		state.hold_duration += delta
	if _reject_flash > 0.0:
		_reject_flash = maxf(_reject_flash - delta, 0.0)
		queue_redraw()


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_tracked_pointers.clear()


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(MOUSE_POINTER_INDEX, event.position, event.pressed)


func _handle_pointer(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		_tracked_pointers[index] = { "start_pos": pos, "hold_duration": 0.0 }
	elif _tracked_pointers.has(index):
		var state: Dictionary = _tracked_pointers[index]
		_tracked_pointers.erase(index)
		_evaluate_swipe(state.start_pos, state.hold_duration, pos)


func _evaluate_swipe(start_pos: Vector2, hold_duration: float, end_pos: Vector2) -> void:
	if hold_duration > max_swipe_duration:
		_reject()
		return
	var delta := end_pos - start_pos
	if absf(delta.x) < min_swipe_distance or absf(delta.x) < absf(delta.y):
		_reject()
		return
	if delta.x < 0.0:
		_throw_left_just_pressed = true
	else:
		_throw_right_just_pressed = true


func _reject() -> void:
	_reject_flash = REJECT_FLASH_DURATION
	queue_redraw()


func _draw() -> void:
	if _reject_flash > 0.0:
		var alpha := 0.12 * (_reject_flash / REJECT_FLASH_DURATION)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, alpha))


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
