class_name TouchControls
extends CanvasLayer

## Mobile control surface. Two groups, deliberately kept apart on
## screen: three large hold buttons across the bottom -- LEFT, BRAKE,
## RIGHT -- for riding, and two contextual one-tap arrows at the
## vertical middle-left/middle-right edges for throwing. There is no
## joystick (the bike drives itself) and, as of Milestone 10.2, no swipe
## gesture either -- swipe throwing was removed completely (unreliable
## on real phones, per player feedback) in favor of a simple tap that
## only appears when a delivery is actually available.
##
## Exposes the same query contract PlayerInput/Thrower expect
## (get_steer_input / is_brake_held / consume_throw_left_just_pressed /
## consume_throw_right_just_pressed / jump passthrough) so any future
## input source can read it without change.
##
## Only active while the route is actually ACTIVE: BRAKE sits bottom-
## center, the same screen region as the route intro's START ROUTE
## button and the results screen's PLAY AGAIN button, so leaving these
## controls live (and eating clicks) outside ACTIVE would silently break
## both of those buttons. Disabling also just makes sense on its own --
## there's nothing to steer/brake/throw before the ride begins.

@export var route_manager_path: NodePath

@onready var left_button: TouchButton = $LeftButton
@onready var brake_button: TouchButton = $BrakeButton
@onready var right_button: TouchButton = $RightButton
@onready var throw_left_arrow: ThrowArrowButton = $ThrowLeftArrow
@onready var throw_right_arrow: ThrowArrowButton = $ThrowRightArrow

var _left_held: bool = false
var _right_held: bool = false
var _brake_held: bool = false
var _throw_left_just_pressed: bool = false
var _throw_right_just_pressed: bool = false
var _route_manager: RouteManager


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
	if throw_left_arrow:
		throw_left_arrow.tapped.connect(func(): _throw_left_just_pressed = true)
	if throw_right_arrow:
		throw_right_arrow.tapped.connect(func(): _throw_right_just_pressed = true)

	_route_manager = get_node_or_null(route_manager_path)
	if _route_manager:
		_route_manager.state_changed.connect(_on_state_changed)
	_set_controls_enabled(false)


func _process(_delta: float) -> void:
	if not _route_manager or _route_manager.state != RouteManager.State.ACTIVE:
		return
	var valid_side := _route_manager.get_valid_throw_side()
	var locked := _route_manager.has_pending_hit()
	if throw_left_arrow:
		throw_left_arrow.set_valid(valid_side == -1)
		throw_left_arrow.set_locked(locked)
	if throw_right_arrow:
		throw_right_arrow.set_valid(valid_side == 1)
		throw_right_arrow.set_locked(locked)


func _on_state_changed(new_state: RouteManager.State) -> void:
	_set_controls_enabled(new_state == RouteManager.State.ACTIVE)


func _set_controls_enabled(value: bool) -> void:
	if not value:
		_left_held = false
		_right_held = false
		_brake_held = false
	if left_button:
		left_button.set_enabled(value)
	if right_button:
		right_button.set_enabled(value)
	if brake_button:
		brake_button.set_enabled(value)
	if throw_left_arrow:
		throw_left_arrow.set_enabled(value)
	if throw_right_arrow:
		throw_right_arrow.set_enabled(value)


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
	if _throw_left_just_pressed:
		_throw_left_just_pressed = false
		return true
	return false


func consume_throw_right_just_pressed() -> bool:
	if _throw_right_just_pressed:
		_throw_right_just_pressed = false
		return true
	return false
