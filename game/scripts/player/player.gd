class_name Player
extends CharacterBody3D

## Arcade auto-runner BMX controller (Milestone 10 redesign). The bike
## always travels forward along world -Z at an automatic cruise speed --
## there is no manual throttle and no heading rotation from steering.
## LEFT/RIGHT input is a smoothed *lateral* velocity (a strafe across the
## road), not a turn, so the bike can never spin, oversteer, or reverse
## its facing. This is a deliberate departure from the earlier
## heading-based BMX steering: that model made "swerve too much" and
## "which way is the bike even facing" real problems once the player
## stopped manually driving. A constant forward axis also means the
## rider's left/right and world -X/+X are identical by construction, so
## Thrower's throw-left/throw-right can never be reversed by camera
## angle, tilt, or steering -- there is nothing to reverse it.
##
## A small cosmetic yaw/lean still plays on steering input for feel, but
## it never drives movement -- VisualRoot's rotation is purely
## decorative here, unlike the old model where it was the whole steering
## mechanism.

enum LocomotionState { GROUNDED, AIRBORNE }

@export_group("Auto-Run")
@export var auto_cruise_speed: float = 6.5
@export var speed_response: float = 6.0
@export var brake_speed: float = 2.0
@export var brake_response: float = 10.0

@export_group("Lateral Steering")
@export var max_lateral_speed: float = 4.5
@export var steering_response: float = 9.0
@export var steering_return_response: float = 7.0
@export var high_speed_steering_reduction: float = 0.55
@export var lateral_bounds: float = 6.2
@export var lateral_correction_strength: float = 10.0
@export var lateral_correction_margin: float = 0.6

@export_group("Visual Feel")
@export var cosmetic_lean_max_degrees: float = 14.0
@export var cosmetic_pitch_max_degrees: float = 5.0
@export var lean_response: float = 10.0
@export var wheel_spin_rate: float = 2.5

@export_group("Suspension")
@export var suspension_bounce_amount: float = 0.03
@export var suspension_bounce_frequency: float = 9.0
@export var suspension_landing_compress: float = 0.12
@export var suspension_response: float = 16.0

@export_group("Jump")
@export var jump_height: float = 1.4
@export var jump_time_to_peak: float = 0.35
@export var jump_time_to_descend: float = 0.28
@export var max_fall_speed: float = 20.0
@export var jump_cut_gravity_multiplier: float = 2.5

@export_group("Landing")
@export var landing_velocity_threshold: float = 6.0

@export_group("Wiring")
@export var camera_rig_path: NodePath
@export var touch_controls_path: NodePath
@export var route_manager_path: NodePath

@export_group("Boost Hook")
## Multiplies auto_cruise_speed while a future boost is active. Nothing
## in this milestone sets this above 1.0 -- it exists purely so a later
## boost feature can plug in without touching the movement math again.
@export var boost_speed_multiplier: float = 1.0

signal jumped
signal landed(fall_speed: float)
signal state_changed(new_state: LocomotionState)

var state: LocomotionState = LocomotionState.AIRBORNE
var is_boosting: bool = false

var _rise_gravity: float
var _fall_gravity: float
var _jump_velocity: float
var _was_on_floor: bool = false
var _forward_speed: float = 0.0
var _lateral_speed: float = 0.0
var _current_roll: float = 0.0
var _current_pitch: float = 0.0
var _is_braking: bool = false
var _bounce_phase: float = 0.0
var _landing_compress: float = 0.0
var _suspension_offset: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var lean_pivot: Node3D = get_node_or_null("VisualRoot/LeanPivot")
@onready var wheel_pivots: Array = [get_node_or_null("VisualRoot/LeanPivot/FrontWheelPivot"), get_node_or_null("VisualRoot/LeanPivot/RearWheelPivot")]
@onready var dust_emitter: Node3D = get_node_or_null("DustEmitter")
@onready var landing_dust: Node3D = get_node_or_null("LandingDust")
@onready var ride_audio: AudioStreamPlayer3D = get_node_or_null("RideAudio")
@onready var landing_audio: AudioStreamPlayer3D = get_node_or_null("LandingAudio")
@onready var camera_rig: Node3D = get_node_or_null(camera_rig_path)
@onready var touch_controls: Node = get_node_or_null(touch_controls_path)
@onready var _route_manager: RouteManager = get_node_or_null(route_manager_path)


func _ready() -> void:
	_rise_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	_fall_gravity = (2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)
	_jump_velocity = _rise_gravity * jump_time_to_peak
	_was_on_floor = is_on_floor()
	if ride_audio:
		ride_audio.volume_db = -80.0
		ride_audio.play()


func _physics_process(delta: float) -> void:
	var route_active := _route_manager != null and _route_manager.state == RouteManager.State.ACTIVE

	if route_active:
		var steering_input := PlayerInput.get_steer_input(touch_controls)
		var braking := PlayerInput.get_brake_held(touch_controls)
		_update_forward_speed(braking, delta)
		_update_lateral_speed(steering_input, delta)
	else:
		# No movement at all before GO (idle/countdown) or once the route
		# is complete -- there is nothing ahead to ride into.
		_forward_speed = 0.0
		_lateral_speed = 0.0
		_is_braking = false

	velocity.x = _lateral_speed
	velocity.z = -_forward_speed

	var velocity_y_before_move := velocity.y
	_apply_gravity(delta)
	_handle_jump()

	move_and_slide()
	_apply_lateral_bounds()

	var grounded := is_on_floor()
	_update_landing(velocity_y_before_move)
	_update_state(grounded)
	_update_visual_effects(grounded)
	_update_cosmetic_lean(delta)
	_update_suspension(grounded, delta)
	_update_wheel_spin(delta)
	_update_ride_audio(grounded, delta)


func _update_forward_speed(braking: bool, delta: float) -> void:
	_is_braking = braking
	var target := brake_speed if braking else auto_cruise_speed * boost_speed_multiplier
	var response := brake_response if braking else speed_response
	_forward_speed = lerpf(_forward_speed, target, 1.0 - exp(-response * delta))


func _update_lateral_speed(steering_input: float, delta: float) -> void:
	# Steering authority shrinks as forward speed approaches cruise (and
	# opens back up under braking) -- "limit excessive steering at high
	# speed" from the design brief, expressed directly rather than as a
	# side effect of some other formula.
	var speed_ratio := clampf(_forward_speed / maxf(auto_cruise_speed, 0.01), 0.0, 1.0)
	var authority := lerpf(1.0, high_speed_steering_reduction, speed_ratio)
	var target := steering_input * max_lateral_speed * authority
	var response := steering_response if absf(steering_input) > 0.001 else steering_return_response
	_lateral_speed = lerpf(_lateral_speed, target, 1.0 - exp(-response * delta))


func _apply_lateral_bounds() -> void:
	# A soft push back toward the road before the hard bound, then a hard
	# clamp -- the player can never ride off the playable corridor, but
	# it reads as a gentle correction rather than hitting an invisible wall.
	var edge := lateral_bounds - lateral_correction_margin
	if absf(position.x) > edge:
		var over := absf(position.x) - edge
		var push := -signf(position.x) * lateral_correction_strength * over
		velocity.x += push * get_physics_process_delta_time()
	position.x = clampf(position.x, -lateral_bounds, lateral_bounds)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -0.5
		return

	var g: float
	if velocity.y > 0.0:
		g = _rise_gravity if PlayerInput.get_jump_held(touch_controls) else _rise_gravity * jump_cut_gravity_multiplier
	else:
		g = _fall_gravity
	velocity.y = maxf(velocity.y - g * delta, -max_fall_speed)


func _handle_jump() -> void:
	if is_on_floor() and PlayerInput.get_jump_just_pressed(touch_controls):
		velocity.y = _jump_velocity
		jumped.emit()


func _update_landing(velocity_y_before_move: float) -> void:
	var grounded := is_on_floor()
	if grounded and not _was_on_floor:
		var fall_speed := absf(velocity_y_before_move)
		landed.emit(fall_speed)
		_landing_compress = -suspension_landing_compress
		if fall_speed >= landing_velocity_threshold:
			if visual_root and visual_root.has_method("play_landing_feedback"):
				visual_root.play_landing_feedback()
			if landing_dust and landing_dust.has_method("burst"):
				landing_dust.burst()
			if landing_audio:
				landing_audio.pitch_scale = randf_range(0.92, 1.08)
				landing_audio.play()
	_was_on_floor = grounded


func _update_state(grounded: bool) -> void:
	var new_state := LocomotionState.GROUNDED if grounded else LocomotionState.AIRBORNE
	if new_state != state:
		state = new_state
		state_changed.emit(state)


func _update_visual_effects(grounded: bool) -> void:
	if dust_emitter and dust_emitter.has_method("set_dust_emitting"):
		dust_emitter.set_dust_emitting(grounded and _forward_speed > auto_cruise_speed * 0.15)


func _update_cosmetic_lean(delta: float) -> void:
	if not lean_pivot:
		return
	# Purely decorative -- driven by lateral speed, but never fed back
	# into velocity/heading, so it can't affect throw direction or
	# movement stability no matter how it's tuned.
	var lean_ratio := clampf(_lateral_speed / maxf(max_lateral_speed, 0.01), -1.0, 1.0)
	var target_roll := -lean_ratio * deg_to_rad(cosmetic_lean_max_degrees)
	_current_roll = lerpf(_current_roll, target_roll, 1.0 - exp(-lean_response * delta))
	lean_pivot.rotation.z = _current_roll

	var target_pitch := deg_to_rad(cosmetic_pitch_max_degrees) if _is_braking else 0.0
	_current_pitch = lerpf(_current_pitch, target_pitch, 1.0 - exp(-lean_response * delta))
	lean_pivot.rotation.x = _current_pitch


func _update_suspension(grounded: bool, delta: float) -> void:
	if not lean_pivot:
		return
	var ride_bounce := 0.0
	if grounded and _forward_speed > 0.01:
		_bounce_phase += suspension_bounce_frequency * delta
		var speed_ratio := clampf(_forward_speed / auto_cruise_speed, 0.0, 1.0)
		ride_bounce = sin(_bounce_phase) * suspension_bounce_amount * speed_ratio
	_landing_compress = lerpf(_landing_compress, 0.0, 1.0 - exp(-suspension_response * delta))
	_suspension_offset = ride_bounce + _landing_compress
	lean_pivot.position.y = _suspension_offset


func _update_wheel_spin(delta: float) -> void:
	if wheel_pivots.is_empty():
		return
	var spin := wheel_spin_rate * _forward_speed * delta
	for wheel_pivot in wheel_pivots:
		if wheel_pivot:
			wheel_pivot.rotation.x -= spin


func _update_ride_audio(grounded: bool, delta: float) -> void:
	if not ride_audio:
		return
	var speed_ratio := clampf(_forward_speed / auto_cruise_speed, 0.0, 1.0)
	var target_db := linear_to_db(0.05 + 0.35 * speed_ratio) if grounded and speed_ratio > 0.02 else -80.0
	ride_audio.volume_db = lerpf(ride_audio.volume_db, target_db, 1.0 - exp(-6.0 * delta))
	ride_audio.pitch_scale = 0.85 + 0.3 * speed_ratio
