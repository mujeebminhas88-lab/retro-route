class_name DustEmitter
extends GPUParticles3D

## Thin wrapper so locomotion controllers can toggle movement dust
## without touching particle internals. set_emitting() is idempotent
## (skips the property write when the state hasn't changed) to avoid
## restarting the emission cycle every physics frame.

var _emitting_state: bool = false


func _ready() -> void:
	emitting = false
	_emitting_state = false


func set_dust_emitting(value: bool) -> void:
	if value == _emitting_state:
		return
	_emitting_state = value
	emitting = value
