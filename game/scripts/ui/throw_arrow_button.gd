class_name ThrowArrowButton
extends Control

## Contextual one-tap throw control (Milestone 10.2, replaces the M10/M10.1
## swipe gesture entirely). Sits at the vertical middle of the screen,
## clear of the bottom LEFT/BRAKE/RIGHT riding controls, and is only
## visible+tappable while a mailbox on this arrow's side is actually
## within the active delivery window -- TouchControls drives that via
## set_valid(), reading RouteManager/Thrower's own hit-window logic, so
## this control never has to know anything about mailboxes itself.
##
## A tap fires immediately on press (not release) for the most
## responsive one-tap feel; there is no swipe distance, hold duration,
## or drag to get right. While a throw is resolving, TouchControls can
## set_locked(true) to dim and briefly ignore new taps (debounce) without
## hiding the control entirely, so the player always sees why nothing
## happened rather than the tap silently vanishing.

signal tapped

@export var side: int = -1 ## -1 = left arrow, 1 = right arrow
@export var base_color: Color = Color(1.0, 0.85, 0.2, 0.85)
@export var pressed_color: Color = Color(1.0, 0.95, 0.5, 0.95)
@export var locked_color: Color = Color(1.0, 0.85, 0.2, 0.35)

const MOUSE_POINTER_INDEX := -2

var _valid: bool = false
var _enabled: bool = true
var _locked: bool = false
var _is_pressed: bool = false
var _active_pointer_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Whether a mailbox on this side is currently within the delivery
## window. Drives both visibility (hidden entirely when not valid, per
## the brief -- "show and enable" / "hide or clearly disable" the
## opposite side) and whether taps are accepted at all.
func set_valid(value: bool) -> void:
	if value == _valid:
		return
	_valid = value
	visible = value and _enabled
	if not value:
		_active_pointer_index = -1
		_set_pressed(false)


## Route-state gate, same pattern as TouchButton's LEFT/BRAKE/RIGHT.
func set_enabled(value: bool) -> void:
	_enabled = value
	visible = value and _valid
	if not value:
		_active_pointer_index = -1
		_set_pressed(false)


## Debounce while a newspaper is resolving -- stays visible (so the
## player can see there's still a target here) but dims and stops
## accepting taps until the milestone's delivery system clears it.
func set_locked(value: bool) -> void:
	_locked = value
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _enabled or not _valid:
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(MOUSE_POINTER_INDEX, event.position, event.pressed)


func _handle_pointer(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _active_pointer_index != -1 or not Rect2(global_position, size).has_point(pos):
			return
		_active_pointer_index = index
		_set_pressed(true)
		get_viewport().set_input_as_handled()
		if not _locked:
			tapped.emit()
	elif index == _active_pointer_index:
		_active_pointer_index = -1
		_set_pressed(false)


func _set_pressed(value: bool) -> void:
	if value == _is_pressed:
		return
	_is_pressed = value
	queue_redraw()


func _draw() -> void:
	var radius := size.x * 0.5
	var center := size * 0.5
	var color := base_color
	if _locked:
		color = locked_color
	elif _is_pressed:
		color = pressed_color
	draw_circle(center, radius, color)

	# A simple chevron arrow (three points), pointing the direction this
	# arrow throws -- unmistakably distinct from the round riding
	# buttons at a glance, no label text needed.
	var arrow_size := radius * 0.7
	var tip := center + Vector2(side * arrow_size * 0.6, 0.0)
	var back_x := center.x - side * arrow_size * 0.6
	var p1 := Vector2(back_x, center.y - arrow_size * 0.7)
	var p2 := Vector2(back_x, center.y + arrow_size * 0.7)
	draw_colored_polygon(PackedVector2Array([tip, p1, p2]), Color(0.15, 0.1, 0.0, 0.9))
