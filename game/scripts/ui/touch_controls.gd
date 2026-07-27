class_name TouchControls
extends CanvasLayer

## Mobile control surface (Milestone 10): three large hold buttons across
## the bottom of the screen -- LEFT, BRAKE, RIGHT -- plus a full-screen
## swipe layer for directional newspaper throws. There is no joystick;
## the bike drives itself, so movement input is reduced to steer/brake.
## Exposes the same query contract PlayerInput/Thrower expect
## (get_steer_input / is_brake_held / consume_throw_left_just_pressed /
## consume_throw_right_just_pressed / jump passthrough) so any future
## input source can read it without change.

@onready var left_button: TouchButton = $LeftButton
@onready var brake_button: TouchButton = $BrakeButton
@onready var right_button: TouchButton = $RightButton
@onready var swipe_gesture: SwipeThrowGesture = $SwipeThrowGesture

var _left_held: bool = false
var _right_held: bool = false
var _brake_held: bool = false


func _ready() -> void:
	if left_button:
		left_button.button_pressed.connect(func(): _left_held = true)
		left_button.button_released.connect(func(): _left_held = false)
	if right_button:
		right_button.button_pressed.connect(func(): _right_held = true)
		right_button.button_released.connect(func(): _right_held = false)
	if brake_button:
		brake_button.button_pressed.connect(func(): _brake_held = true)
		brake_button.button_released.connect(func(): _brake_held = false)


func get_steer_input() -> float:
	var value := 0.0
	if _left_held:
		value -= 1.0
	if _right_held:
		value += 1.0
	return value


func is_brake_held() -> bool:
	return _brake_held


func consume_throw_left_just_pressed() -> bool:
	return swipe_gesture.consume_throw_left_just_pressed() if swipe_gesture else false


func consume_throw_right_just_pressed() -> bool:
	return swipe_gesture.consume_throw_right_just_pressed() if swipe_gesture else false
