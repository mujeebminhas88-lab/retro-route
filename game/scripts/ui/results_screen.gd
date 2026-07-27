class_name ResultsScreen
extends CanvasLayer

## Post-route results overlay: score/deliveries/accuracy/time/best,
## plus the Play Again button. Purely reactive to RouteManager's
## route_completed signal for content, and only feeds a button press
## back upstream (restart_route()) — same relay pattern as the rest of
## the UI layer.

@export var route_manager_path: NodePath

@onready var panel: Control = $Panel
@onready var score_label: Label = $Panel/ScoreLabel
@onready var deliveries_label: Label = $Panel/DeliveriesLabel
@onready var accuracy_label: Label = $Panel/AccuracyLabel
@onready var time_label: Label = $Panel/TimeLabel
@onready var best_label: Label = $Panel/BestLabel
@onready var play_again_button: Button = $Panel/PlayAgainButton

var _route_manager: RouteManager


func _ready() -> void:
	panel.visible = false
	_route_manager = get_node_or_null(route_manager_path)
	if _route_manager:
		_route_manager.route_completed.connect(_on_route_completed)
		_route_manager.state_changed.connect(_on_state_changed)
	play_again_button.pressed.connect(_on_play_again_pressed)


func _on_state_changed(new_state: RouteManager.State) -> void:
	if new_state != RouteManager.State.COMPLETE:
		panel.visible = false


func _on_play_again_pressed() -> void:
	if _route_manager:
		_route_manager.restart_route()


func _on_route_completed(stats: Dictionary) -> void:
	score_label.text = "Score: %d" % stats["score"]
	deliveries_label.text = "Deliveries: %d / %d" % [stats["deliveries"], stats["total"]]
	accuracy_label.text = "Accuracy: %d%%" % roundi(stats["accuracy"])
	time_label.text = "Time: %s" % _format_time(stats["time"])
	best_label.text = "Best Score: %d%s" % [stats["best_score"], "  (New Best!)" if stats["is_new_best"] else ""]
	panel.visible = true


func _format_time(seconds: float) -> String:
	var whole := int(seconds)
	var minutes := whole / 60
	var secs := whole % 60
	var tenths := int((seconds - whole) * 10.0)
	return "%d:%02d.%d" % [minutes, secs, tenths]
