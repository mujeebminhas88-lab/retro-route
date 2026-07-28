class_name Mailbox
extends StaticBody3D

## Delivery target. DeliveryManager owns which mailbox is "active" and
## calls set_active()/play_delivered_feedback() on this node — the
## mailbox itself doesn't know about scoring or the newspaper, keeping
## it reusable for any future target type.

const ACTIVE_COLOR := Color(1.0, 0.85, 0.15)
const ACTIVE_EMISSION := Color(1.0, 0.7, 0.1)
const INACTIVE_COLOR := Color(0.55, 0.55, 0.55)

@export var active_bob_speed: float = 3.0
@export var active_bob_height: float = 0.08
@export var target_ring_spin_speed: float = 1.2

@export_group("Delivery Reaction")
@export var wobble_angle_degrees: float = 14.0
@export var wobble_frequency: float = 18.0
@export var wobble_duration: float = 0.45

@export_group("Delivery Flap")
## How far the flap swings open on a successful delivery, and how long
## the open-then-shut motion takes -- a small, fast, readable "the
## newspaper just went in" cue, not a slow realistic hinge.
@export var flap_open_degrees: float = 75.0
@export var flap_open_duration: float = 0.12
@export var flap_close_duration: float = 0.22

@onready var delivery_point: Marker3D = $DeliveryPoint
@onready var flag_mesh: MeshInstance3D = $VisualRoot/Flag
@onready var target_ring: MeshInstance3D = $TargetRing
@onready var visual_root: SquashStretch = $VisualRoot
@onready var delivery_burst: GPUParticles3D = $DeliveryBurst
@onready var flap_pivot: Node3D = get_node_or_null("VisualRoot/FlapPivot")

var is_active: bool = false
var _flag_base_y: float = 0.0
var _time: float = 0.0
var _wobble_remaining: float = 0.0
var _flap_tween: Tween


func _ready() -> void:
	_flag_base_y = flag_mesh.position.y
	set_active(false)


func _process(delta: float) -> void:
	if is_active:
		_time += delta
		if target_ring:
			target_ring.rotation.y += delta * target_ring_spin_speed
		flag_mesh.position.y = _flag_base_y + sin(_time * active_bob_speed) * active_bob_height

	if _wobble_remaining > 0.0:
		_wobble_remaining = maxf(_wobble_remaining - delta, 0.0)
		var decay := _wobble_remaining / wobble_duration
		visual_root.rotation.z = sin(_wobble_remaining * wobble_frequency) * deg_to_rad(wobble_angle_degrees) * decay
	elif visual_root.rotation.z != 0.0:
		visual_root.rotation.z = 0.0


func get_delivery_point() -> Vector3:
	return delivery_point.global_position if delivery_point else global_position


func set_active(value: bool) -> void:
	is_active = value
	if target_ring:
		target_ring.visible = value

	var mat := flag_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = ACTIVE_COLOR if value else INACTIVE_COLOR
		mat.emission_enabled = value
		if value:
			mat.emission = ACTIVE_EMISSION
			mat.emission_energy_multiplier = 1.5


## Called by RouteManager the instant a newspaper's flight actually
## lands (see Newspaper._finish -> RouteManager._on_delivered) -- so the
## flap swings open in sync with the newspaper visually reaching the
## slot, not with the throw or the score update.
func play_delivered_feedback() -> void:
	if visual_root:
		visual_root.play_landing_feedback()
	if wobble_duration > 0.0:
		_wobble_remaining = wobble_duration
	if delivery_burst:
		delivery_burst.restart()
		delivery_burst.emitting = true
	_play_flap_open()


func _play_flap_open() -> void:
	if not flap_pivot:
		return
	if _flap_tween and _flap_tween.is_valid():
		_flap_tween.kill()
	flap_pivot.rotation.x = 0.0
	_flap_tween = create_tween()
	_flap_tween.tween_property(flap_pivot, "rotation:x", deg_to_rad(-flap_open_degrees), flap_open_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flap_tween.tween_property(flap_pivot, "rotation:x", 0.0, flap_close_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
