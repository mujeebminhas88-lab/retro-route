class_name SquashStretch
extends Node3D

## Lightweight scale-based feedback for a parent locomotion controller
## to call into on notable events (landing, jump start, bump, ...).
## Reusable by any character, not just the current placeholder body.

@export var squash_scale: Vector3 = Vector3(1.3, 0.65, 1.3)
@export var squash_duration: float = 0.08
@export var recover_duration: float = 0.18

@export_group("Jump Feedback")
@export var jump_squash_scale: Vector3 = Vector3(0.85, 1.2, 0.85)
@export var jump_squash_duration: float = 0.06
@export var jump_recover_duration: float = 0.14

@export_group("Throw Feedback")
@export var throw_squash_scale: Vector3 = Vector3(1.18, 0.88, 1.08)
@export var throw_squash_duration: float = 0.05
@export var throw_recover_duration: float = 0.12

var _tween: Tween


func play_landing_feedback() -> void:
	_play_squash(squash_scale, squash_duration, recover_duration)


func play_jump_feedback() -> void:
	_play_squash(jump_squash_scale, jump_squash_duration, jump_recover_duration)


func play_throw_feedback() -> void:
	_play_squash(throw_squash_scale, throw_squash_duration, throw_recover_duration)


func _play_squash(target_scale: Vector3, squash_time: float, recover_time: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	scale = Vector3.ONE
	_tween = create_tween()
	_tween.tween_property(self, "scale", target_scale, squash_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector3.ONE, recover_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
