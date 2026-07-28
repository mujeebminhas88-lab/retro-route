class_name Thrower
extends Node

## Directional swipe/keypress throwing (Milestone 10). A left throw
## always launches toward world -X, a right throw toward world +X --
## because Player's forward is a constant world -Z (see player.gd; the
## bike never rotates its heading), the rider's actual left/right and
## world -X/+X are the same thing by construction, so this can never be
## reversed by camera angle, tilt, or steering.
##
## A throw only counts as a hit when the route's current active mailbox
## is on the thrown side *and* within a forgiving along-route (Z) window
## of the player (hit_z_tolerance) -- the player needs to be roughly at
## the right point in the route and pick the correct side; fine lateral
## positioning isn't required. A correct throw's newspaper flies
## straight to that mailbox's real position (a small aiming assist);
## anything else is a clean, deterministic miss that flies out to the
## chosen side and lands.

@export var route_manager_path: NodePath
@export var throw_height_offset: float = 1.1
@export var hit_z_tolerance: float = 5.0
@export var throw_side_distance: float = 7.0

const NEWSPAPER_SCENE := preload("res://scenes/world/Newspaper.tscn")

@onready var _player: Player = get_parent()
@onready var _route_manager: RouteManager = get_node_or_null(route_manager_path)
@onready var _throw_audio: AudioStreamPlayer3D = get_node_or_null("../ThrowAudio")


func _physics_process(_delta: float) -> void:
	if not _route_manager or _route_manager.state != RouteManager.State.ACTIVE:
		return
	if PlayerInput.get_throw_left_just_pressed(_player.touch_controls):
		_throw(-1)
	elif PlayerInput.get_throw_right_just_pressed(_player.touch_controls):
		_throw(1)


func _throw(side: int) -> void:
	if not _route_manager.consume_newspaper():
		return
	if _player.visual_root and _player.visual_root.has_method("play_throw_feedback"):
		_player.visual_root.play_throw_feedback()

	var start := _player.global_position + Vector3.UP * throw_height_offset
	var end := start + Vector3(float(side) * throw_side_distance, 0.0, 0.0)
	var target_mailbox := _route_manager.get_active_mailbox()
	var hit := false

	if target_mailbox:
		var mailbox_side := signf(target_mailbox.global_position.x)
		var same_side := mailbox_side == 0.0 or signf(float(side)) == mailbox_side
		var within_range := absf(target_mailbox.global_position.z - _player.global_position.z) <= hit_z_tolerance
		hit = same_side and within_range
		if hit:
			end = target_mailbox.get_delivery_point() if target_mailbox.has_method("get_delivery_point") else target_mailbox.global_position
			_route_manager.notify_hit_committed()

	var newspaper: Newspaper = NEWSPAPER_SCENE.instantiate()
	_player.get_parent().add_child(newspaper)
	_route_manager.register_newspaper(newspaper)
	newspaper.launch(start, end, hit, target_mailbox if hit else null)

	if _throw_audio:
		_throw_audio.pitch_scale = randf_range(0.95, 1.08)
		_throw_audio.play()
