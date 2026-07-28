class_name TouchButton
extends Control

## Simple round on-screen button (used for jump). Matches the same
## draw-based, no-external-asset approach as VirtualJoystick so the
## whole touch UI stays lightweight and easy to reskin later.

signal button_pressed
signal button_released

@export var label_text: String = ""
@export var base_color: Color = Color(1, 1, 1, 0.22)
@export var pressed_color: Color = Color(1, 1, 1, 0.45)

const MOUSE_POINTER_INDEX := -2

var _active_pointer_index: int = -1
var _is_pressed: bool = false
var _enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Disabling both hides the button and stops it from claiming input, so
## it can never sit on top of (and eat clicks meant for) an unrelated
## button occupying the same screen space in a different route state --
## e.g. this control surface's own BRAKE button versus the route intro's
## START ROUTE button, both bottom-center by design.
func set_enabled(value: bool) -> void:
	if value == _enabled:
		return
	_enabled = value
	visible = value
	if not value and _active_pointer_index != -1:
		_active_pointer_index = -1
		_set_pressed(false)


func _input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(MOUSE_POINTER_INDEX, event.position, event.pressed)


func _handle_pointer(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _active_pointer_index == -1 and Rect2(global_position, size).has_point(pos):
			_active_pointer_index = index
			_set_pressed(true)
			get_viewport().set_input_as_handled()
	elif index == _active_pointer_index:
		_active_pointer_index = -1
		_set_pressed(false)


func _set_pressed(value: bool) -> void:
	if value == _is_pressed:
		return
	_is_pressed = value
	queue_redraw()
	if value:
		button_pressed.emit()
	else:
		button_released.emit()


func _draw() -> void:
	var radius := size.x * 0.5
	var center := size * 0.5
	draw_circle(center, radius, pressed_color if _is_pressed else base_color)
	if label_text != "":
		var font := ThemeDB.fallback_font
		var font_size := 22
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.35), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.9))


func is_pressed_now() -> bool:
	return _is_pressed
