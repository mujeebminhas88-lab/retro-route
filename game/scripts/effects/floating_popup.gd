class_name FloatingPopup
extends Node3D

## Reusable world-space text popup (e.g. "+10") that floats up and
## fades out, then frees itself. Not tied to scoring specifically —
## any system can spawn one and call show_text().

@export var punch_scale: Vector3 = Vector3(1.5, 1.5, 1.5)
@export var punch_duration: float = 0.12
@export var rise_distance: float = 1.4
@export var rise_duration: float = 0.9
@export var fade_delay: float = 0.3

@onready var label: Label3D = $Label3D

var _tween: Tween


func show_text(text: String, color: Color = Color.WHITE) -> void:
	label.text = text
	label.modulate = color

	if _tween and _tween.is_valid():
		_tween.kill()
	label.scale = Vector3.ZERO
	_tween = create_tween()
	_tween.tween_property(label, "scale", punch_scale, punch_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(label, "scale", Vector3.ONE, punch_duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "position:y", position.y + rise_distance, rise_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, rise_duration).set_delay(fade_delay)
	_tween.tween_callback(queue_free)
