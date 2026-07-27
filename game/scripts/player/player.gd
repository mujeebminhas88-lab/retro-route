class_name Player
extends CharacterBody3D

## Arcade BMX locomotion controller. Vehicle-style controls: steering
## turns the bike, forward/back is throttle/brake. This is not a bicycle
## simulation — no wheel colliders, no suspension, no balancing — it is
## tuned purely for immediate, responsive, Paperboy-style fun.
##
## Facing is still driven by a smoothed scalar `rotation.y` on VisualRoot
## (never by direct basis reassignment), so it never fights with
## VisualRoot's independently-animated squash/stretch `scale`, and so
## Camera/Thrower's read of `visual_root.global_transform.basis.z` keeps
## working unchanged. Lean/pitch visual polish is applied to a separate
## LeanPivot child instead of VisualRoot itself, so it can never corrupt
## that facing vector.

enum LocomotionState { GROUNDED, AIRBORNE }

@export_group("BMX Movement")
@export var top_speed: float = 7.5
@export_range(0.0, 1.0) var reverse_speed_ratio: float = 0.5
@export var acceleration: float = 10.0
@export var braking: float = 16.0
@export var steering_sensitivity: float = 1.6
@export var turning_radius: float = 2.5
@export var min_turn_speed: float = 2.0

@export_group("Visual Feel")
@export var lean_angle_max_degrees: float = 18.0
@export var pitch_angle_max_degrees: float = 6.0
@export var lean_response: float = 10.0
@export var wheel_spin_rate: float = 2.5

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

signal jumped
signal landed(fall_speed: float)
signal state_changed(new_state: LocomotionState)

var state: LocomotionState = LocomotionState.AIRBORNE

var _rise_gravity: float
var _fall_gravity: float
var _jump_velocity: float
var _was_on_floor: bool = false
var _facing_yaw: float = 0.0
var _speed: float = 0.0
var _current_roll: float = 0.0
var _current_pitch: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var lean_pivot: Node3D = get_node_or_null("VisualRoot/LeanPivot")
@onready var wheel_pivots: Array = [get_node_or_null("VisualRoot/LeanPivot/FrontWheelPivot"), get_node_or_null("VisualRoot/LeanPivot/RearWheelPivot")]
@onready var dust_emitter: Node3D = get_node_or_null("DustEmitter")
@onready var camera_rig: Node3D = get_node_or_null(camera_rig_path)
@onready var touch_controls: Node = get_node_or_null(touch_controls_path)


func _ready() -> void:
	_rise_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	_fall_gravity = (2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)
	_jump_velocity = _rise_gravity * jump_time_to_peak
	_was_on_floor = is_on_floor()
	_facing_yaw = visual_root.rotation.y


func _physics_process(delta: float) -> void:
	var move_input := PlayerInput.get_move_vector(touch_controls)
	var throttle_input := -move_input.y
	var steering_input := move_input.x

	_update_speed(throttle_input, delta)
	_update_steering(steering_input, delta)

	var forward := -visual_root.global_transform.basis.z
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed

	var velocity_y_before_move := velocity.y
	_apply_gravity(delta)
	_handle_jump()

	move_and_slide()

	var grounded := is_on_floor()
	_update_landing(velocity_y_before_move)
	_update_state(grounded)
	_update_visual_effects(grounded)
	_update_lean(steering_input, delta)
	_update_pitch(delta)
	_update_wheel_spin(delta)


func _update_speed(throttle_input: float, delta: float) -> void:
	var target_speed := top_speed * throttle_input if throttle_input >= 0.0 else top_speed * reverse_speed_ratio * throttle_input
	var speeding_up := absf(target_speed) > absf(_speed) + 0.001
	var same_direction := (target_speed >= 0.0 and _speed >= -0.01) or (target_speed <= 0.0 and _speed <= 0.01)
	var rate := acceleration if (speeding_up and same_direction) else braking
	_speed = move_toward(_speed, target_speed, rate * delta)


func _update_steering(steering_input: float, delta: float) -> void:
	# Steering is proportional to current speed (like a real bike, you can't
	# pivot sharply at a standstill) but floored by min_turn_speed so a light
	# tap of throttle still lets the bike turn in place instead of feeling stuck.
	if absf(steering_input) < 0.001 or absf(_speed) < 0.001:
		return
	var effective_speed := maxf(absf(_speed), min_turn_speed)
	var turn_sign := signf(_speed)
	# Negative sign: rotation.y decreases to turn the bike's forward vector
	# toward +X (screen-right), matching Basis.looking_at's convention (and
	# the pre-BMX locomotion's), so steering right actually turns right.
	var angular_velocity := -(effective_speed / turning_radius) * steering_sensitivity * steering_input * turn_sign
	_facing_yaw += angular_velocity * delta
	visual_root.rotation.y = _facing_yaw


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
		if fall_speed >= landing_velocity_threshold and visual_root and visual_root.has_method("play_landing_feedback"):
			visual_root.play_landing_feedback()
	_was_on_floor = grounded


func _update_state(grounded: bool) -> void:
	var new_state := LocomotionState.GROUNDED if grounded else LocomotionState.AIRBORNE
	if new_state != state:
		state = new_state
		state_changed.emit(state)


func _update_visual_effects(grounded: bool) -> void:
	if dust_emitter and dust_emitter.has_method("set_dust_emitting"):
		dust_emitter.set_dust_emitting(grounded and absf(_speed) > top_speed * 0.15)


func _update_lean(steering_input: float, delta: float) -> void:
	if not lean_pivot:
		return
	var speed_ratio := clampf(absf(_speed) / top_speed, 0.0, 1.0)
	var target_roll := -steering_input * deg_to_rad(lean_angle_max_degrees) * speed_ratio
	_current_roll = lerpf(_current_roll, target_roll, 1.0 - exp(-lean_response * delta))
	lean_pivot.rotation.z = _current_roll


func _update_pitch(delta: float) -> void:
	if not lean_pivot:
		return
	var speed_ratio := clampf(_speed / top_speed, -1.0, 1.0)
	var target_pitch := -deg_to_rad(pitch_angle_max_degrees) * speed_ratio
	_current_pitch = lerpf(_current_pitch, target_pitch, 1.0 - exp(-lean_response * delta))
	lean_pivot.rotation.x = _current_pitch


func _update_wheel_spin(delta: float) -> void:
	if wheel_pivots.is_empty():
		return
	var spin := wheel_spin_rate * _speed * delta
	for wheel_pivot in wheel_pivots:
		if wheel_pivot:
			wheel_pivot.rotation.x -= spin
