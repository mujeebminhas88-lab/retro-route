class_name RouteManager
extends Node3D

## Owns the whole route session: state (idle/countdown/active/complete),
## timing, and delivery statistics. Milestone 10 changed the route from
## a fixed hand-placed mailbox list to a streamed one -- mailboxes don't
## exist ahead of time, so RoadStreamer (or any future spawner) calls
## register_mailbox() as each one is placed, and this class queues and
## activates them in arrival order. Route completion is now a delivery
## COUNT (delivery_target) rather than "reached the end of the list",
## since a streamed route has no fixed end.
##
## Newspaper and Mailbox stay ignorant of any of this — this is the
## single place that decides what a throw/delivery means for the
## current run.

enum State { IDLE, COUNTDOWN, ACTIVE, COMPLETE }

const COUNTDOWN_STEPS: Array[String] = ["3", "2", "1", "GO!"]

signal state_changed(new_state: State)
signal countdown_step(text: String)
signal score_changed(new_score: int)
signal deliveries_changed(completed: int, target: int)
signal newspapers_changed(remaining: int)
signal time_changed(seconds: float)
signal delivery_succeeded(mailbox: Node3D)
signal delivery_missed
signal route_completed(stats: Dictionary)
## Fires once, the instant the route becomes ACTIVE (GO). A distinct
## signal from state_changed so listeners that only care about "the ride
## just began" (RoadStreamer's initial fill, a future boost hook) don't
## need to match on the State enum.
signal route_started

@export var delivery_target: int = 20
@export var points_per_delivery: int = 10
@export var delivery_sound_pitch_variance: float = 0.06
## Newspaper supply is generous rather than exactly-sized, since a
## streamed route has no fixed length to size it against -- large enough
## that it's effectively unlimited across a normal run to delivery_target,
## while keeping the exact same consume/refund-on-miss mechanic proven
## in Milestone 9 (a miss still never permanently costs the run).
@export var bundle_padding: int = 500
@export var countdown_step_duration: float = 0.8
## If the player rides this far past the active mailbox without
## delivering, it's skipped and the next queued one activates instead --
## a missed/ignored mailbox can never permanently stall progress toward
## delivery_target.
@export var mailbox_skip_margin: float = 6.0

const FLOATING_POPUP_SCENE := preload("res://scenes/ui/FloatingPopup.tscn")

var score: int = 0
var state: State = State.IDLE

var _active_mailbox: Node3D = null
var _pending_mailboxes: Array[Node3D] = []
## Counts hit-labeled newspapers that are still mid-flight (Thrower
## decides hit/miss the instant a throw is released, but the newspaper
## takes flight_duration to actually land). Without this, a correctly
## thrown newspaper could still lose its delivery: if the player kept
## riding during that ~0.5s flight and crossed mailbox_skip_margin before
## the newspaper landed, _check_skip_passed_mailbox() would already have
## deactivated the target and moved on, so the eventual delivered signal
## would arrive for a mailbox that's no longer _active_mailbox and get
## treated as a stale miss -- a genuinely correct, well-timed throw
## silently failing. Pausing the skip check while any hit is still
## resolving closes that window; the stall risk is bounded by a single
## newspaper's flight_duration, negligible next to mailbox_skip_margin.
var _pending_hit_count: int = 0
var _deliveries_completed: int = 0
var _throws_made: int = 0
var _hits_made: int = 0
var _newspapers_remaining: int = 0
var _route_time: float = 0.0
var _countdown_step_index: int = 0
var _countdown_step_elapsed: float = 0.0

@onready var _sfx_player: AudioStreamPlayer3D = $DeliverySfx
@onready var _celebration_sfx: AudioStreamPlayer3D = get_node_or_null("CelebrationSfx")
@onready var _celebration_burst: GPUParticles3D = get_node_or_null("CelebrationBurst")
@onready var _camera: Node = get_node_or_null("../CameraRig")
@onready var _player: Node3D = get_node_or_null("../Player")


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
			_check_skip_passed_mailbox()


func start_route() -> void:
	if state != State.IDLE:
		return
	_begin_countdown()


func restart_route() -> void:
	if state != State.COMPLETE:
		return
	# A fresh run needs a fresh streamed world, not the tail end of the
	# last one -- RoadStreamer listens for state_changed back to
	# COUNTDOWN and resets itself before GO.
	_active_mailbox = null
	_pending_mailboxes.clear()
	_begin_countdown()


func consume_newspaper() -> bool:
	if state != State.ACTIVE or _newspapers_remaining <= 0:
		return false
	_newspapers_remaining -= 1
	_throws_made += 1
	newspapers_changed.emit(_newspapers_remaining)
	return true


func get_active_mailbox() -> Node3D:
	return _active_mailbox if state == State.ACTIVE else null


## Called by Thrower the instant it commits to a hit (before the
## newspaper has actually landed) so the skip-margin safety net can't
## pull the target out from under an already-correct throw. See
## _pending_hit_count's doc comment.
func notify_hit_committed() -> void:
	_pending_hit_count += 1


## Called by RoadStreamer (or any future mailbox spawner) as each new
## mailbox is placed into the world. Queued in arrival order; if there's
## no currently active mailbox, this one (or the front of the queue)
## activates immediately.
func register_mailbox(mailbox: Node3D) -> void:
	mailbox.set_active(false)
	_pending_mailboxes.append(mailbox)
	_activate_next_if_needed()


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
	_route_time = 0.0
	_newspapers_remaining = delivery_target + bundle_padding
	_active_mailbox = null
	_pending_hit_count = 0

	state_changed.emit(state)
	score_changed.emit(score)
	deliveries_changed.emit(_deliveries_completed, delivery_target)
	newspapers_changed.emit(_newspapers_remaining)
	time_changed.emit(_route_time)
	route_started.emit()

	_activate_next_if_needed()


func _activate_next_if_needed() -> void:
	if state != State.ACTIVE or _active_mailbox != null:
		return
	if _pending_mailboxes.is_empty():
		return
	_active_mailbox = _pending_mailboxes.pop_front()
	_active_mailbox.set_active(true)


func _check_skip_passed_mailbox() -> void:
	if not _active_mailbox or not _player:
		return
	if _pending_hit_count > 0:
		return
	if _player.global_position.z < _active_mailbox.global_position.z - mailbox_skip_margin:
		_active_mailbox.set_active(false)
		_active_mailbox = null
		_activate_next_if_needed()


func _on_delivered(mailbox: Node3D) -> void:
	_pending_hit_count = maxi(_pending_hit_count - 1, 0)

	if mailbox != _active_mailbox:
		# A second throw was already in flight toward this mailbox when
		# the first one landed and delivered it (rapid-fire throwing at
		# the same still-active target) -- this one is stale. Treat it
		# like a miss (refund the newspaper) rather than double-crediting
		# a single mailbox for two throws.
		_on_missed()
		return

	_hits_made += 1
	score += points_per_delivery
	score_changed.emit(score)
	_deliveries_completed += 1
	deliveries_changed.emit(_deliveries_completed, delivery_target)
	delivery_succeeded.emit(mailbox)

	if mailbox.has_method("play_delivered_feedback"):
		mailbox.play_delivered_feedback()

	_spawn_score_popup(mailbox)
	_play_delivery_sound(mailbox)

	_active_mailbox = null

	if _deliveries_completed >= delivery_target:
		_complete_route()
	else:
		_activate_next_if_needed()


func _on_missed() -> void:
	# A miss never permanently costs the route — refund the newspaper so
	# frustration stays low.
	_newspapers_remaining += 1
	newspapers_changed.emit(_newspapers_remaining)
	delivery_missed.emit()


func _complete_route() -> void:
	state = State.COMPLETE
	state_changed.emit(state)

	if _active_mailbox:
		_active_mailbox.set_active(false)
		_active_mailbox = null

	var accuracy := 100.0 if _throws_made == 0 else (float(_hits_made) / float(_throws_made)) * 100.0
	var is_new_best := SaveData.save_best_score_if_higher(score)
	var stats := {
		"score": score,
		"deliveries": _deliveries_completed,
		"total": delivery_target,
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
