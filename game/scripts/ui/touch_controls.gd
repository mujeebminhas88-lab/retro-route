class_name TouchControls
extends CanvasLayer

## Mobile control surface: a virtual joystick for movement plus jump and
## throw buttons. Exposes the same query contract PlayerInput expects
## (get_move_vector / is_jump_held / consume_jump_just_pressed /
## consume_throw_just_pressed) so any future locomotion or aiming mode
## can read it without change.

@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var jump_button: TouchButton = $JumpButton
@onready var throw_button: TouchButton = $ThrowButton

var _jump_just_pressed: bool = false
var _jump_held: bool = false
var _throw_just_pressed: bool = false


func _ready() -> void:
	if jump_button:
		jump_button.button_pressed.connect(_on_jump_pressed)
		jump_button.button_released.connect(_on_jump_released)
	if throw_button:
		throw_button.button_pressed.connect(_on_throw_pressed)


func _on_jump_pressed() -> void:
	_jump_held = true
	_jump_just_pressed = true


func _on_jump_released() -> void:
	_jump_held = false


func _on_throw_pressed() -> void:
	_throw_just_pressed = true


func get_move_vector() -> Vector2:
	return joystick.get_vector() if joystick else Vector2.ZERO


func is_jump_held() -> bool:
	return _jump_held


func consume_jump_just_pressed() -> bool:
	if _jump_just_pressed:
		_jump_just_pressed = false
		return true
	return false


func consume_throw_just_pressed() -> bool:
	if _throw_just_pressed:
		_throw_just_pressed = false
		return true
	return false
