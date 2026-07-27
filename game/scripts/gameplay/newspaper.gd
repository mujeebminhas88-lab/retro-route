class_name Newspaper
extends Node3D

## Kinematic (non-physics) throw projectile. Hit/miss is decided once,
## at launch time, from throw distance vs. max_range — not from runtime
## collision — which keeps delivery deterministic and easy to follow.
## `launch()` takes an explicit target position rather than reading the
## mailbox itself, so a future manual-aim mode can pass any point here
## without changing this class at all.

signal delivered(mailbox: Node3D)
signal missed

@export var flight_duration: float = 0.5
@export var arc_height: float = 2.0
@export var spin_degrees_per_sec: float = 620.0
@export var miss_lifetime: float = 0.6

var _start: Vector3
var _end: Vector3
var _elapsed: float = 0.0
var _target_mailbox: Node3D
var _is_hit: bool = false
var _finished: bool = false


func launch(start: Vector3, target_mailbox: Node3D, max_range: float) -> void:
	_start = start
	_target_mailbox = target_mailbox

	var target_point: Vector3 = target_mailbox.get_delivery_point() if target_mailbox.has_method("get_delivery_point") else target_mailbox.global_position
	var to_target := target_point - start
	var flat_distance := Vector2(to_target.x, to_target.z).length()

	if flat_distance <= max_range:
		_is_hit = true
		_end = target_point
	else:
		_is_hit = false
		var flat_dir := Vector2(to_target.x, to_target.z).normalized()
		_end = start + Vector3(flat_dir.x, 0.0, flat_dir.y) * max_range

	_elapsed = 0.0
	global_position = _start


func _process(delta: float) -> void:
	if _finished:
		return

	_elapsed += delta
	var t := clampf(_elapsed / flight_duration, 0.0, 1.0)
	var pos := _start.lerp(_end, t)
	pos.y += sin(t * PI) * arc_height
	global_position = pos
	rotate_x(deg_to_rad(spin_degrees_per_sec) * delta)

	if t >= 1.0:
		_finish()


func _finish() -> void:
	_finished = true
	if _is_hit:
		delivered.emit(_target_mailbox)
		queue_free()
	else:
		missed.emit()
		await get_tree().create_timer(miss_lifetime).timeout
		queue_free()
