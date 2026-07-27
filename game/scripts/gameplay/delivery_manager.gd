class_name DeliveryManager
extends Node3D

## Owns the gameplay loop's bookkeeping: which mailbox is active, the
## score, and triggering feedback on delivery. Newspaper and Mailbox
## stay ignorant of scoring; this is the single place that orchestrates
## "what happens when a delivery lands."

signal score_changed(new_score: int)
signal delivery_succeeded(mailbox: Node3D)
signal delivery_missed

@export var points_per_delivery: int = 10
@export var delivery_sound_pitch_variance: float = 0.06

const FLOATING_POPUP_SCENE := preload("res://scenes/ui/FloatingPopup.tscn")

var score: int = 0

var _mailboxes: Array[Node] = []
var _active_index: int = 0

@onready var _sfx_player: AudioStreamPlayer3D = $DeliverySfx


func _ready() -> void:
	_mailboxes = get_tree().get_nodes_in_group("mailboxes")
	_mailboxes.shuffle()
	if not _mailboxes.is_empty():
		_mailboxes[0].set_active(true)


func get_active_mailbox() -> Node3D:
	if _mailboxes.is_empty():
		return null
	return _mailboxes[_active_index]


func register_newspaper(newspaper: Newspaper) -> void:
	newspaper.delivered.connect(_on_delivered)
	newspaper.missed.connect(_on_missed)


func _on_delivered(mailbox: Node3D) -> void:
	score += points_per_delivery
	score_changed.emit(score)
	delivery_succeeded.emit(mailbox)

	if mailbox.has_method("play_delivered_feedback"):
		mailbox.play_delivered_feedback()

	_spawn_score_popup(mailbox)
	_play_delivery_sound(mailbox)
	_advance_to_next_mailbox()


func _on_missed() -> void:
	delivery_missed.emit()


func _spawn_score_popup(mailbox: Node3D) -> void:
	if not FLOATING_POPUP_SCENE:
		return
	var popup := FLOATING_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.global_position = mailbox.global_position + Vector3.UP * 1.6
	popup.show_text("+%d" % points_per_delivery, Color(1.0, 0.85, 0.2))


func _play_delivery_sound(mailbox: Node3D) -> void:
	if _sfx_player:
		_sfx_player.global_position = mailbox.global_position
		_sfx_player.pitch_scale = 1.0 + randf_range(-delivery_sound_pitch_variance, delivery_sound_pitch_variance)
		_sfx_player.play()


func _advance_to_next_mailbox() -> void:
	if _mailboxes.is_empty():
		return
	if _mailboxes.size() == 1:
		return

	_mailboxes[_active_index].set_active(false)
	var next_index := _active_index
	while next_index == _active_index:
		next_index = randi() % _mailboxes.size()
	_active_index = next_index
	_mailboxes[_active_index].set_active(true)
