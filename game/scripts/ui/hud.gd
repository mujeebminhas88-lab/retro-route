class_name HUD
extends CanvasLayer

## In-route HUD: score, deliveries completed, newspapers remaining, the
## route timer, and a brief "Delivery Complete!" flash. Purely
## reactive — it only listens to RouteManager's signals and never
## drives gameplay itself.

@export var route_manager_path: NodePath

@export_group("Celebration")
@export var celebration_overshoot_scale: float = 1.1
@export var celebration_overshoot_duration: float = 0.15
@export var celebration_settle_duration: float = 0.1
@export var celebration_hold_duration: float = 0.6
@export var celebration_fade_duration: float = 0.4

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
	if _complete_tween and _complete_tween.is_valid():
		_complete_tween.kill()

	complete_label.scale = Vector2(0.7, 0.7)
	complete_label.modulate.a = 1.0

	_complete_tween = create_tween()
	_complete_tween.tween_property(complete_label, "scale", Vector2.ONE * celebration_overshoot_scale, celebration_overshoot_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_complete_tween.tween_property(complete_label, "scale", Vector2.ONE, celebration_settle_duration)
	_complete_tween.tween_interval(celebration_hold_duration)
	_complete_tween.tween_property(complete_label, "modulate:a", 0.0, celebration_fade_duration)
