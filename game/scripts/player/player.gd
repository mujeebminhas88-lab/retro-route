class_name Player
extends CharacterBody3D

## Third-person arcade locomotion controller. This is the movement
## foundation for the whole game, not a throwaway prototype controller:
## the BMX locomotion planned for a later milestone will replace the
## walk/run tuning below with ride physics while reusing this same
## state machine, gravity model, camera contract, and input contract.

enum LocomotionState { GROUNDED, AIRBORNE }

@export_group("Movement")
@export var walk_speed: float = 2.5
@export var run_speed: float = 6.0
@export var ground_acceleration: float = 40.0
@export var ground_deceleration: float = 45.0
@export var air_acceleration: float = 14.0
@export_range(0.0, 1.0) var air_control: float = 0.6
@export var rotation_speed: float = 12.0

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

@onready var visual_root: Node3D = $VisualRoot
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
	var speed_scale := PlayerInput.get_speed_scale(touch_controls)
	var has_input := move_input.length_squared() > 0.0001

	var cam_basis: Basis = camera_rig.global_transform.basis if camera_rig else global_transform.basis
	var move_dir := cam_basis.x * move_input.x + cam_basis.z * move_input.y
	move_dir.y = 0.0
	if move_dir.length_squared() > 1.0:
		move_dir = move_dir.normalized()

	var grounded := is_on_floor()
	var target_speed := lerpf(walk_speed, run_speed, speed_scale)
	var target_velocity := move_dir * target_speed if has_input else Vector3.ZERO

	var accel: float
	if grounded:
		accel = ground_acceleration if has_input else ground_deceleration
	else:
		accel = air_acceleration * (air_control if has_input else air_control * 0.5)

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	var velocity_y_before_move := velocity.y
	_apply_gravity(delta)
	_handle_jump()

	move_and_slide()

	_update_landing(velocity_y_before_move)
	_update_facing(move_dir, has_input, delta)
	_update_state(grounded)
	_update_visual_effects(has_input, grounded)


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


func _update_facing(move_dir: Vector3, has_input: bool, delta: float) -> void:
	if not has_input or move_dir.length_squared() < 0.0001:
		return
	# Rotation is applied via the scalar `rotation.y` (not global_transform.basis)
	# so it never fights with VisualRoot's independently-animated squash/stretch
	# `scale`, and never accumulates floating-point drift from repeated basis
	# reassignment across a long play session.
	var target_yaw := Basis.looking_at(move_dir, Vector3.UP).get_euler().y
	_facing_yaw = lerp_angle(_facing_yaw, target_yaw, 1.0 - exp(-rotation_speed * delta))
	visual_root.rotation.y = _facing_yaw


func _update_state(grounded: bool) -> void:
	var new_state := LocomotionState.GROUNDED if grounded else LocomotionState.AIRBORNE
	if new_state != state:
		state = new_state
		state_changed.emit(state)


func _update_visual_effects(has_input: bool, grounded: bool) -> void:
	if dust_emitter and dust_emitter.has_method("set_dust_emitting"):
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		dust_emitter.set_dust_emitting(grounded and has_input and horizontal_speed > walk_speed * 0.5)
