class_name DustEmitter
extends GPUParticles3D

## Thin wrapper so locomotion controllers can toggle movement dust
## without touching particle internals. set_dust_emitting() is idempotent
## (skips the property write when the state hasn't changed) to avoid
## restarting the emission cycle every physics frame.
##
## The same script also backs one-shot "puff" nodes (e.g. a landing dust
## kick) — configure that instance with `one_shot = true` in the scene
## and call burst() instead of set_dust_emitting(). Reusing this class
## for both roles avoids a second particle script for what is otherwise
## identical setup (shared material/texture, same tuning shape).

var _emitting_state: bool = false


func _ready() -> void:
	emitting = false
	_emitting_state = false


func set_dust_emitting(value: bool) -> void:
	if value == _emitting_state:
		return
	_emitting_state = value
	emitting = value


func burst() -> void:
	restart()
	emitting = true
