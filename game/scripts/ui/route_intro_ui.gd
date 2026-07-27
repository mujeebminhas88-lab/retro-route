class_name RouteIntroUI
extends CanvasLayer

## Pre-route overlay: a "START ROUTE" button while idle, then the
## 3-2-1-GO! countdown once pressed. Purely reactive to RouteManager's
## state — the button click is the only thing it feeds back upstream,
## same pattern as TouchControls relaying raw input.

@export var route_manager_path: NodePath

@onready var start_button: Button = $StartButton
@onready var countdown_label: Label = $CountdownLabel

var _route_manager: RouteManager
var _countdown_tween: Tween


func _ready() -> void:
	countdown_label.modulate.a = 0.0
	countdown_label.visible = false
	_route_manager = get_node_or_null(route_manager_path)
	if _route_manager:
		_route_manager.state_changed.connect(_on_state_changed)
		_route_manager.countdown_step.connect(_on_countdown_step)
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	if _route_manager:
		_route_manager.start_route()


func _on_state_changed(new_state: RouteManager.State) -> void:
	start_button.visible = new_state == RouteManager.State.IDLE
	countdown_label.visible = new_state == RouteManager.State.COUNTDOWN


func _on_countdown_step(text: String) -> void:
	countdown_label.text = text
	if _countdown_tween and _countdown_tween.is_valid():
		_countdown_tween.kill()
	countdown_label.scale = Vector2(1.6, 1.6)
	countdown_label.modulate.a = 1.0
	_countdown_tween = create_tween()
	_countdown_tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
