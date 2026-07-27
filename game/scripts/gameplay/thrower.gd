class_name Thrower
extends Node

## Spawns Newspaper projectiles toward the route's active mailbox.
## Aiming is fully automatic today (always targets the active mailbox);
## adding manual aim later only means changing how the target position
## is chosen here — Newspaper's flight/hit-detection logic would not
## need to change.
##
## A brief windup gives the throw weight: pressing the button plays an
## immediate anticipation squash, then the newspaper actually launches
## (and the whoosh plays) a beat later. throw_windup_time = 0 restores
## the old instant-throw behavior.
##
## Each press consumes one newspaper from the route's bundle
## (RouteManager.consume_newspaper()) — a miss refunds it there, not
## here, so Thrower doesn't need to know anything about the bundle's
## rules beyond "ask before throwing."

@export var route_manager_path: NodePath
@export var max_throw_range: float = 4.5
@export var throw_height_offset: float = 1.1
@export var throw_forward_offset: float = 0.5
@export var throw_windup_time: float = 0.08

const NEWSPAPER_SCENE := preload("res://scenes/world/Newspaper.tscn")

@onready var _player: Player = get_parent()
@onready var _route_manager: RouteManager = get_node_or_null(route_manager_path)
@onready var _throw_audio: AudioStreamPlayer3D = get_node_or_null("../ThrowAudio")

var _windup_remaining: float = -1.0


func _physics_process(delta: float) -> void:
	if _windup_remaining >= 0.0:
		_windup_remaining -= delta
		if _windup_remaining <= 0.0:
			_windup_remaining = -1.0
			_throw()
		return

	if PlayerInput.get_throw_just_pressed(_player.touch_controls):
		if not _route_manager or not _route_manager.get_active_mailbox():
			return
		if not _route_manager.consume_newspaper():
			return
		if _player.visual_root and _player.visual_root.has_method("play_throw_feedback"):
			_player.visual_root.play_throw_feedback()
		if throw_windup_time > 0.0:
			_windup_remaining = throw_windup_time
		else:
			_throw()


func _throw() -> void:
	if not _route_manager:
		return
	var mailbox := _route_manager.get_active_mailbox()
	if not mailbox:
		return

	var forward := -_player.visual_root.global_transform.basis.z
	var start := _player.global_position + Vector3.UP * throw_height_offset + forward * throw_forward_offset

	var newspaper: Newspaper = NEWSPAPER_SCENE.instantiate()
	# Spawn as a sibling of the player (world root) rather than under the
	# player or via get_tree().current_scene — the latter is only set by
	# Godot's normal scene-load flow and is unreliable in test harnesses
	# and any future manual scene-composition code path.
	_player.get_parent().add_child(newspaper)
	_route_manager.register_newspaper(newspaper)
	newspaper.launch(start, mailbox, max_throw_range)

	if _throw_audio:
		_throw_audio.pitch_scale = randf_range(0.95, 1.08)
		_throw_audio.play()
