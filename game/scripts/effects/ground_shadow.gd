class_name GroundShadow
extends MeshInstance3D

## Cheap "blob shadow" decal: raycasts straight down from its parent
## each frame, sits flush with whatever it hits, and fades out with
## height. Avoids relying on dynamic shadow maps for mobile performance.

@export var max_fade_height: float = 6.0
@export var min_alpha: float = 0.0
@export var max_alpha: float = 0.55
@export var ray_length: float = 20.0
@export var ground_offset: float = 0.02

var _material: StandardMaterial3D
var _parent_3d: Node3D


func _ready() -> void:
	_parent_3d = get_parent() as Node3D
	if material_override:
		material_override = material_override.duplicate()
		_material = material_override as StandardMaterial3D


func _process(_delta: float) -> void:
	if not _parent_3d:
		return

	var space_state := get_world_3d().direct_space_state
	var origin := _parent_3d.global_position
	var from := origin + Vector3.UP * 0.5
	var to := from + Vector3.DOWN * ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	if _parent_3d is PhysicsBody3D:
		query.exclude = [(_parent_3d as PhysicsBody3D).get_rid()]

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		visible = false
		return

	visible = true
	var hit_position: Vector3 = result.position
	global_position = Vector3(origin.x, hit_position.y + ground_offset, origin.z)

	var height_above: float = origin.y - hit_position.y
	var alpha := lerpf(max_alpha, min_alpha, clampf(height_above / max_fade_height, 0.0, 1.0))
	if _material:
		var c := _material.albedo_color
		c.a = alpha
		_material.albedo_color = c
