class_name TouchControls
extends CanvasLayer

## Mobile control surface: a virtual joystick for movement and a jump
## button. Exposes the same query contract PlayerInput expects
## (get_move_vector / is_jump_held / consume_jump_just_pressed) so any
## future locomotion (including BMX) can read it without change.

@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var jump_button: TouchButton = $JumpButton

var _jump_just_pressed: bool = false
var _jump_held: bool = false


func _ready() -> void:
	if jump_button:
		jump_button.button_pressed.connect(_on_jump_pressed)
		jump_button.button_released.connect(_on_jump_released)


func _on_jump_pressed() -> void:
	_jump_held = true
	_jump_just_pressed = true


func _on_jump_released() -> void:
	_jump_held = false


func get_move_vector() -> Vector2:
	return joystick.get_vector() if joystick else Vector2.ZERO


func is_jump_held() -> bool:
	return _jump_held


func consume_jump_just_pressed() -> bool:
	if _jump_just_pressed:
		_jump_just_pressed = false
		return true
	return false
