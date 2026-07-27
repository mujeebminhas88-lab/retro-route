class_name HUD
extends CanvasLayer

## Minimal HUD: current score and a brief "Delivery Complete!" flash.
## Purely reactive — it only listens to DeliveryManager's signals and
## never drives gameplay itself.

@export var delivery_manager_path: NodePath

@onready var score_label: Label = $ScoreLabel
@onready var complete_label: Label = $DeliveryCompleteLabel

var _delivery_manager: DeliveryManager
var _complete_tween: Tween


func _ready() -> void:
	complete_label.modulate.a = 0.0
	_delivery_manager = get_node_or_null(delivery_manager_path)
	if _delivery_manager:
		_delivery_manager.score_changed.connect(_on_score_changed)
		_delivery_manager.delivery_succeeded.connect(_on_delivery_succeeded)
		_on_score_changed(_delivery_manager.score)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func _on_delivery_succeeded(_mailbox: Node3D) -> void:
	if _complete_tween and _complete_tween.is_valid():
		_complete_tween.kill()

	complete_label.scale = Vector2(0.7, 0.7)
	complete_label.modulate.a = 1.0

	_complete_tween = create_tween()
	_complete_tween.tween_property(complete_label, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_complete_tween.tween_property(complete_label, "scale", Vector2(1.0, 1.0), 0.1)
	_complete_tween.tween_interval(0.6)
	_complete_tween.tween_property(complete_label, "modulate:a", 0.0, 0.4)
