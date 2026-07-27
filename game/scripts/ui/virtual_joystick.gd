class_name VirtualJoystick
extends Control

## On-screen analog stick. Tracks a single touch (or mouse, for desktop
## browser testing) by index from the moment it lands inside the base
## circle, and keeps following that same pointer anywhere on screen
## until release — so drags aren't lost if the finger leaves the base.

signal vector_changed(vec: Vector2)

@export var dead_zone: float = 0.08
@export var base_color: Color = Color(1, 1, 1, 0.18)
@export var knob_color: Color = Color(1, 1, 1, 0.45)

const MOUSE_POINTER_INDEX := -2

var _active_pointer_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO
var _output: Vector2 = Vector2.ZERO
var _base_radius: float
var _knob_radius: float


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_radius = size.x * 0.5
	_knob_radius = _base_radius * 0.45


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_pointer_press(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		if event.index == _active_pointer_index:
			_update_knob(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer_press(MOUSE_POINTER_INDEX, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		if _active_pointer_index == MOUSE_POINTER_INDEX:
			_update_knob(event.position)


func _handle_pointer_press(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _active_pointer_index == -1 and _get_global_rect().has_point(pos):
			_active_pointer_index = index
			_update_knob(pos)
			get_viewport().set_input_as_handled()
	elif index == _active_pointer_index:
		_reset()


func _get_global_rect() -> Rect2:
	return Rect2(global_position, size)


func _update_knob(global_point: Vector2) -> void:
	var center := global_position + size * 0.5
	var offset := global_point - center
	if offset.length() > _base_radius:
		offset = offset.normalized() * _base_radius
	_knob_offset = offset

	var normalized := offset / _base_radius
	_output = Vector2.ZERO if normalized.length() < dead_zone else normalized
	queue_redraw()
	vector_changed.emit(_output)


func _reset() -> void:
	_active_pointer_index = -1
	_knob_offset = Vector2.ZERO
	_output = Vector2.ZERO
	queue_redraw()
	vector_changed.emit(_output)


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, _base_radius, base_color)
	draw_circle(center + _knob_offset, _knob_radius, knob_color)


func get_vector() -> Vector2:
	return _output
