class_name HUD
extends CanvasLayer

## In-route HUD: score, deliveries completed, newspapers remaining, the
## route timer, and a brief hit/miss flash. Purely reactive — it only
## listens to RouteManager's signals and never drives gameplay itself.
##
## Milestone 10.1: added the miss reaction. Previously RouteManager's
## delivery_missed signal had no listeners anywhere -- a miss was
## silent, so a player couldn't tell a genuine miss from an input that
## just didn't register at all. Hit and miss now share one flash
## routine with different text/color so both are always legible.

@export var route_manager_path: NodePath

@export_group("Celebration")
@export var celebration_overshoot_scale: float = 1.1
@export var celebration_overshoot_duration: float = 0.15
@export var celebration_settle_duration: float = 0.1
@export var celebration_hold_duration: float = 0.6
@export var celebration_fade_duration: float = 0.4

@export_group("Miss Feedback")
@export var miss_text: String = "Missed!"
@export var miss_color: Color = Color(0.85, 0.85, 0.9, 1.0)
@export var hit_text: String = "Delivered!"
@export var hit_color: Color = Color(1, 0.85, 0.2, 1)

@onready var score_label: Label = $ScoreLabel
@onready var deliveries_label: Label = $DeliveriesLabel
@onready var newspapers_label: Label = $NewspapersLabel
@onready var timer_label: Label = $TimerLabel
@onready var complete_label: Label = $DeliveryCompleteLabel

var _route_manager: RouteManager
var _complete_tween: Tween


func _ready() -> void:
	complete_label.modulate.a = 0.0
	_route_manager = get_node_or_null(route_manager_path)
	if _route_manager:
		_route_manager.score_changed.connect(_on_score_changed)
		_route_manager.deliveries_changed.connect(_on_deliveries_changed)
		_route_manager.newspapers_changed.connect(_on_newspapers_changed)
		_route_manager.time_changed.connect(_on_time_changed)
		_route_manager.delivery_succeeded.connect(_on_delivery_succeeded)
		_route_manager.delivery_missed.connect(_on_delivery_missed)
		_on_score_changed(_route_manager.score)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func _on_deliveries_changed(completed: int, total: int) -> void:
	deliveries_label.text = "Deliveries: %d / %d" % [completed, total]


func _on_newspapers_changed(remaining: int) -> void:
	newspapers_label.text = "Newspapers: %d" % remaining


func _on_time_changed(seconds: float) -> void:
	var whole := int(seconds)
	timer_label.text = "Time: %d:%02d" % [whole / 60, whole % 60]


func _on_delivery_succeeded(_mailbox: Node3D) -> void:
	_flash_feedback(hit_text, hit_color)


func _on_delivery_missed() -> void:
	_flash_feedback(miss_text, miss_color)


func _flash_feedback(text: String, color: Color) -> void:
	if _complete_tween and _complete_tween.is_valid():
		_complete_tween.kill()

	complete_label.text = text
	complete_label.modulate = color
	complete_label.scale = Vector2(0.7, 0.7)
	complete_label.modulate.a = 1.0

	_complete_tween = create_tween()
	_complete_tween.tween_property(complete_label, "scale", Vector2.ONE * celebration_overshoot_scale, celebration_overshoot_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_complete_tween.tween_property(complete_label, "scale", Vector2.ONE, celebration_settle_duration)
	_complete_tween.tween_interval(celebration_hold_duration)
	_complete_tween.tween_property(complete_label, "modulate:a", 0.0, celebration_fade_duration)
