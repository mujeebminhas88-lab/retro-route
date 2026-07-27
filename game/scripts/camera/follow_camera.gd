class_name FollowCamera
extends Node3D

## Smooth third-person chase camera. Auto-orients behind whatever
## direction the target is currently facing, since mobile input only
## drives movement (no dedicated look stick) — matching the touch
## control layout. Collision avoidance comes from SpringArm3D's own
## shape cast, configured on the child SpringArm3D/Camera3D in the scene.

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

@onready var spring_arm: SpringArm3D = $SpringArm3D

var _target: Node3D
var _target_visual: Node3D
var _yaw: float = 0.0


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


func _physics_process(delta: float) -> void:
	if not _target:
		return

	var target_pos := _target.global_position + Vector3.UP * height_offset
	global_position = global_position.lerp(target_pos, 1.0 - exp(-position_smoothing * delta))

	var facing := _get_target_forward()
	if facing.length_squared() > 0.0001:
		# Scalar-yaw smoothing (not repeated basis slerp/reassignment) avoids
		# accumulating floating-point orthonormality drift over long sessions.
		var target_yaw := Basis.looking_at(facing, Vector3.UP).get_euler().y
		_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-rotation_smoothing * delta))
		rotation.y = _yaw


func _get_target_forward() -> Vector3:
	if _target_visual == null and _target:
		_target_visual = _target.get_node_or_null("VisualRoot")
	if _target_visual:
		return -_target_visual.global_transform.basis.z
	return Vector3.ZERO
