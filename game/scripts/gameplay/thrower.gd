class_name Thrower
extends Node

## Spawns Newspaper projectiles toward the delivery manager's active
## mailbox. Aiming is fully automatic today (always targets the active
## mailbox); adding manual aim later only means changing how the target
## position is chosen here — Newspaper's flight/hit-detection logic
## would not need to change.

@export var delivery_manager_path: NodePath
@export var max_throw_range: float = 4.5
@export var throw_height_offset: float = 1.1
@export var throw_forward_offset: float = 0.5

const NEWSPAPER_SCENE := preload("res://scenes/world/Newspaper.tscn")

@onready var _player: Player = get_parent()
@onready var _delivery_manager: DeliveryManager = get_node_or_null(delivery_manager_path)


func _physics_process(_delta: float) -> void:
	if PlayerInput.get_throw_just_pressed(_player.touch_controls):
		_throw()


func _throw() -> void:
	if not _delivery_manager:
		return
	var mailbox := _delivery_manager.get_active_mailbox()
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
	_delivery_manager.register_newspaper(newspaper)
	newspaper.launch(start, mailbox, max_throw_range)
