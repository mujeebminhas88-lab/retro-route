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

@onready var delivery_point: Marker3D = $DeliveryPoint
@onready var flag_mesh: MeshInstance3D = $VisualRoot/Flag
@onready var target_ring: MeshInstance3D = $TargetRing
@onready var visual_root: SquashStretch = $VisualRoot
@onready var delivery_burst: GPUParticles3D = $DeliveryBurst

var is_active: bool = false
var _flag_base_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_flag_base_y = flag_mesh.position.y
	set_active(false)


func _process(delta: float) -> void:
	if not is_active:
		return
	_time += delta
	if target_ring:
		target_ring.rotation.y += delta * target_ring_spin_speed
	flag_mesh.position.y = _flag_base_y + sin(_time * active_bob_speed) * active_bob_height


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


func play_delivered_feedback() -> void:
	if visual_root:
		visual_root.play_landing_feedback()
	if delivery_burst:
		delivery_burst.restart()
		delivery_burst.emitting = true
