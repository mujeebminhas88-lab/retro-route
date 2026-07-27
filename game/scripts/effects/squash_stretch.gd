class_name SquashStretch
extends Node3D

## Lightweight scale-based feedback for a parent locomotion controller
## to call into on notable events (landing, jump start, bump, ...).
## Reusable by any character, not just the current placeholder body.

@export var squash_scale: Vector3 = Vector3(1.3, 0.65, 1.3)
@export var squash_duration: float = 0.08
@export var recover_duration: float = 0.18

var _tween: Tween


func play_landing_feedback() -> void:
	_play_squash(squash_scale, squash_duration, recover_duration)


func play_jump_feedback() -> void:
	_play_squash(Vector3(0.85, 1.2, 0.85), 0.06, 0.14)


func _play_squash(target_scale: Vector3, squash_time: float, recover_time: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector3.ONE
	_tween = create_tween()
	_tween.tween_property(self, "scale", target_scale, squash_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector3.ONE, recover_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
