class_name FollowCamera
extends Node3D

## Smooth third-person chase camera. Auto-orients behind whatever
## direction the target is currently facing, since mobile input only
## drives movement (no dedicated look stick) — matching the touch
## control layout. Collision avoidance comes from SpringArm3D's own
## shape cast, configured on the child SpringArm3D/Camera3D in the scene.
##
## Deliberately decoupled from Player's own export names (reads only
## `global_position`, `velocity`, and the optional `landed` signal) so
## this rig could just as easily follow any other CharacterBody3D.

@export var target_path: NodePath
@export var follow_distance: float = 6.0:
	set(value):
		follow_distance = value
		if spring_arm:
			spring_arm.spring_length = value
@export var height_offset: float = 1.6
@export var pitch_degrees: float = -15.0
@export var position_smoothing: float = 8.0
@export var rotation_smoothing: float = 6.0
@export var collision_margin: float = 0.3

@export_group("Anticipation")
@export var anticipation_strength: float = 0.6
@export var anticipation_smoothing: float = 5.0
@export var anticipation_speed_reference: float = 7.5

@export_group("Speed Zoom")
@export var speed_zoom_distance: float = 1.2
@export var speed_zoom_smoothing: float = 4.0
@export var speed_zoom_reference: float = 7.5

@export_group("Turn Tilt")
@export var turn_tilt_max_degrees: float = 3.0
@export var turn_tilt_gain: float = 0.12
@export var turn_tilt_response: float = 8.0

@export_group("Landing Impulse")
@export var landing_impulse_strength: float = 0.12
@export var landing_impulse_decay: float = 9.0
@export var landing_impulse_min_fall_speed: float = 6.0
@export var landing_impulse_fall_speed_reference: float = 14.0

@export_group("Celebration")
@export var celebration_impulse_strength: float = 0.3

@onready var spring_arm: SpringArm3D = $SpringArm3D

var _target: Node3D
var _target_visual: Node3D
var _yaw: float = 0.0
var _prev_target_yaw: float = 0.0
var _has_prev_target_yaw: bool = false
var _anticipation_offset: Vector3 = Vector3.ZERO
var _zoom_current: float = 0.0
var _tilt_current: float = 0.0
var _landing_impulse: float = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path)
	if spring_arm:
		spring_arm.spring_length = follow_distance
		spring_arm.rotation_degrees.x = pitch_degrees
		spring_arm.margin = collision_margin

	_yaw = rotation.y
	if _target:
		global_position = _target.global_position + Vector3.UP * height_offset
		var facing := _get_target_forward()
		if facing.length_squared() > 0.0001:
			_yaw = Basis.looking_at(facing, Vector3.UP).get_euler().y
			rotation.y = _yaw
		if _target.has_signal("landed"):
			_target.landed.connect(_on_target_landed)


func _physics_process(delta: float) -> void:
	if not _target:
		return

	var speed_ratio := 0.0
	if _target is CharacterBody3D:
		speed_ratio = clampf(Vector2(_target.velocity.x, _target.velocity.z).length() / maxf(anticipation_speed_reference, 0.01), 0.0, 1.0)

	var target_anticipation := Vector3.ZERO
	if _target is CharacterBody3D and speed_ratio > 0.001:
		var horizontal_velocity := Vector3(_target.velocity.x, 0.0, _target.velocity.z)
		target_anticipation = horizontal_velocity.normalized() * anticipation_strength * speed_ratio
	_anticipation_offset = _anticipation_offset.lerp(target_anticipation, 1.0 - exp(-anticipation_smoothing * delta))

	var target_pos := _target.global_position + Vector3.UP * height_offset + _anticipation_offset
	global_position = global_position.lerp(target_pos, 1.0 - exp(-position_smoothing * delta))

	_landing_impulse = lerpf(_landing_impulse, 0.0, 1.0 - exp(-landing_impulse_decay * delta))
	global_position.y += _landing_impulse

	var facing := _get_target_forward()
	if facing.length_squared() > 0.0001:
		# Scalar-yaw smoothing (not repeated basis slerp/reassignment) avoids
		# accumulating floating-point orthonormality drift over long sessions.
		var target_yaw := Basis.looking_at(facing, Vector3.UP).get_euler().y
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-rotation_smoothing * delta))
		rotation.y = _yaw

		if _has_prev_target_yaw and delta > 0.0001:
			var yaw_rate := wrapf(target_yaw - _prev_target_yaw, -PI, PI) / delta
			var tilt_target := clampf(rad_to_deg(-yaw_rate) * turn_tilt_gain, -turn_tilt_max_degrees, turn_tilt_max_degrees)
			_tilt_current = lerpf(_tilt_current, tilt_target, 1.0 - exp(-turn_tilt_response * delta))
		_prev_target_yaw = target_yaw
		_has_prev_target_yaw = true
		rotation_degrees.z = _tilt_current

	if speed_zoom_distance != 0.0 and spring_arm:
		var speed_ratio_zoom := 0.0
		if _target is CharacterBody3D:
			speed_ratio_zoom = clampf(Vector2(_target.velocity.x, _target.velocity.z).length() / maxf(speed_zoom_reference, 0.01), 0.0, 1.0)
		var target_zoom := speed_zoom_distance * speed_ratio_zoom
		_zoom_current = lerpf(_zoom_current, target_zoom, 1.0 - exp(-speed_zoom_smoothing * delta))
		spring_arm.spring_length = follow_distance + _zoom_current


func _get_target_forward() -> Vector3:
	if _target_visual == null and _target:
		_target_visual = _target.get_node_or_null("VisualRoot")
	if _target_visual:
		return -_target_visual.global_transform.basis.z
	return Vector3.ZERO


func _on_target_landed(fall_speed: float) -> void:
	if fall_speed < landing_impulse_min_fall_speed:
		return
	var strength := clampf(fall_speed / maxf(landing_impulse_fall_speed_reference, 0.01), 0.0, 1.0)
	_landing_impulse = -landing_impulse_strength * strength


## A small upward camera bump for route-complete celebrations. Reuses
## the same decaying impulse the landing bump already drives — opposite
## sign (rises instead of dips) so it reads as a distinct, positive beat
## rather than another landing.
func celebrate() -> void:
	_landing_impulse = celebration_impulse_strength
