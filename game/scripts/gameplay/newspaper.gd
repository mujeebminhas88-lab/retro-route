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

@export_group("Impact")
@export var apex_stretch_amount: float = 0.25
@export var impact_pop_scale: float = 1.6
@export var impact_pop_duration: float = 0.1

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
	var arc_t := sin(t * PI)
	pos.y += arc_t * arc_height
	global_position = pos
	rotate_x(deg_to_rad(spin_degrees_per_sec) * delta)
	# A gentle apex-synced scale pulse (not a directional stretch, which
	# would fight the continuous spin visually) keeps the arc's peak — the
	# hardest moment to judge hit/miss by eye — a touch more readable.
	scale = Vector3.ONE * (1.0 + apex_stretch_amount * arc_t)

	if t >= 1.0:
		_finish()


func _finish() -> void:
	_finished = true
	if _is_hit:
		delivered.emit(_target_mailbox)
		_play_impact_and_free()
	else:
		missed.emit()
		await get_tree().create_timer(miss_lifetime).timeout
		queue_free()


func _play_impact_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * impact_pop_scale, impact_pop_duration * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ZERO, impact_pop_duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
