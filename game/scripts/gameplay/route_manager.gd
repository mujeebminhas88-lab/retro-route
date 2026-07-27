class_name RouteManager
extends Node3D

## Owns the whole route session: state (idle/countdown/active/complete),
## the fixed delivery order, the newspaper bundle, timing, and
## statistics. Newspaper and Mailbox stay ignorant of any of this — this
## is the single place that decides what a throw/delivery means for the
## current run.
##
## The delivery order itself is scene data (`route_mailboxes`), not
## hard-coded here, so this script is reusable for any future
## neighborhood: point it at a different ordered list of mailboxes and
## the whole flow (countdown, bundle, timing, results) comes along for
## free.

enum State { IDLE, COUNTDOWN, ACTIVE, COMPLETE }

const COUNTDOWN_STEPS: Array[String] = ["3", "2", "1", "GO!"]

signal state_changed(new_state: State)
signal countdown_step(text: String)
signal score_changed(new_score: int)
signal deliveries_changed(completed: int, total: int)
signal newspapers_changed(remaining: int)
signal time_changed(seconds: float)
signal delivery_succeeded(mailbox: Node3D)
signal delivery_missed
signal route_completed(stats: Dictionary)

@export var route_mailboxes: Array[NodePath] = []
@export var points_per_delivery: int = 10
@export var delivery_sound_pitch_variance: float = 0.06
@export var bundle_padding: int = 0
@export var countdown_step_duration: float = 0.8

const FLOATING_POPUP_SCENE := preload("res://scenes/ui/FloatingPopup.tscn")

var score: int = 0
var state: State = State.IDLE

var _route_mailboxes: Array[Node] = []
var _route_index: int = 0
var _deliveries_completed: int = 0
var _throws_made: int = 0
var _hits_made: int = 0
var _newspapers_remaining: int = 0
var _bundle_size: int = 0
var _route_time: float = 0.0
var _countdown_step_index: int = 0
var _countdown_step_elapsed: float = 0.0

@onready var _sfx_player: AudioStreamPlayer3D = $DeliverySfx
@onready var _celebration_sfx: AudioStreamPlayer3D = get_node_or_null("CelebrationSfx")
@onready var _celebration_burst: GPUParticles3D = get_node_or_null("CelebrationBurst")
@onready var _camera: Node = get_node_or_null("../CameraRig")
@onready var _player: Node3D = get_node_or_null("../Player")


func _ready() -> void:
	for path in route_mailboxes:
		var mb := get_node_or_null(path)
		if mb:
			_route_mailboxes.append(mb)
			mb.set_active(false)
	_bundle_size = _route_mailboxes.size() + bundle_padding


func _process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_countdown_step_elapsed += delta
			if _countdown_step_elapsed >= countdown_step_duration:
				_countdown_step_elapsed = 0.0
				_countdown_step_index += 1
				if _countdown_step_index >= COUNTDOWN_STEPS.size():
					_begin_active()
				else:
					countdown_step.emit(COUNTDOWN_STEPS[_countdown_step_index])
		State.ACTIVE:
			_route_time += delta
			time_changed.emit(_route_time)


func start_route() -> void:
	if state != State.IDLE:
		return
	_begin_countdown()


func restart_route() -> void:
	if state != State.COMPLETE:
		return
	_begin_countdown()


func consume_newspaper() -> bool:
	if state != State.ACTIVE or _newspapers_remaining <= 0:
		return false
	_newspapers_remaining -= 1
	_throws_made += 1
	newspapers_changed.emit(_newspapers_remaining)
	return true


func get_active_mailbox() -> Node3D:
	if state != State.ACTIVE or _route_index >= _route_mailboxes.size():
		return null
	return _route_mailboxes[_route_index]


func register_newspaper(newspaper: Newspaper) -> void:
	newspaper.delivered.connect(_on_delivered)
	newspaper.missed.connect(_on_missed)


func _begin_countdown() -> void:
	state = State.COUNTDOWN
	_countdown_step_index = 0
	_countdown_step_elapsed = 0.0
	state_changed.emit(state)
	countdown_step.emit(COUNTDOWN_STEPS[0])


func _begin_active() -> void:
	state = State.ACTIVE
	score = 0
	_deliveries_completed = 0
	_throws_made = 0
	_hits_made = 0
	_route_index = 0
	_route_time = 0.0
	_newspapers_remaining = _bundle_size

	for mb in _route_mailboxes:
		mb.set_active(false)
	if not _route_mailboxes.is_empty():
		_route_mailboxes[0].set_active(true)

	state_changed.emit(state)
	score_changed.emit(score)
	deliveries_changed.emit(_deliveries_completed, _route_mailboxes.size())
	newspapers_changed.emit(_newspapers_remaining)
	time_changed.emit(_route_time)


func _on_delivered(mailbox: Node3D) -> void:
	_hits_made += 1
	score += points_per_delivery
	score_changed.emit(score)
	_deliveries_completed += 1
	deliveries_changed.emit(_deliveries_completed, _route_mailboxes.size())
	delivery_succeeded.emit(mailbox)

	if mailbox.has_method("play_delivered_feedback"):
		mailbox.play_delivered_feedback()

	_spawn_score_popup(mailbox)
	_play_delivery_sound(mailbox)
	_advance_route()


func _on_missed() -> void:
	# A miss never permanently costs the route — refund the newspaper so
	# frustration stays low during the prototype phase (per design brief).
	_newspapers_remaining += 1
	newspapers_changed.emit(_newspapers_remaining)
	delivery_missed.emit()


func _advance_route() -> void:
	if _route_index >= _route_mailboxes.size():
		return
	_route_mailboxes[_route_index].set_active(false)
	_route_index += 1
	if _route_index >= _route_mailboxes.size():
		_complete_route()
	else:
		_route_mailboxes[_route_index].set_active(true)


func _complete_route() -> void:
	state = State.COMPLETE
	state_changed.emit(state)

	var accuracy := 100.0 if _throws_made == 0 else (float(_hits_made) / float(_throws_made)) * 100.0
	var is_new_best := SaveData.save_best_score_if_higher(score)
	var stats := {
		"score": score,
		"deliveries": _deliveries_completed,
		"total": _route_mailboxes.size(),
		"accuracy": accuracy,
		"time": _route_time,
		"best_score": SaveData.load_best_score(),
		"is_new_best": is_new_best,
	}

	_play_celebration()
	route_completed.emit(stats)


func _play_celebration() -> void:
	if _celebration_burst:
		_celebration_burst.global_position = _player.global_position + Vector3.UP * 1.2 if _player else global_position
		_celebration_burst.restart()
		_celebration_burst.emitting = true
	if _celebration_sfx:
		_celebration_sfx.play()
	if _camera and _camera.has_method("celebrate"):
		_camera.celebrate()


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
