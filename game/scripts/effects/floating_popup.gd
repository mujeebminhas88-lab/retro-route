class_name FloatingPopup
extends Node3D

## Reusable world-space text popup (e.g. "+10") that floats up and
## fades out, then frees itself. Not tied to scoring specifically —
## any system can spawn one and call show_text().

@onready var label: Label3D = $Label3D

var _tween: Tween


func show_text(text: String, color: Color = Color.WHITE) -> void:
	label.text = text
	label.modulate = color

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", position.y + 1.4, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	_tween.tween_callback(queue_free)
