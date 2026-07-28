class_name RoadStreamer
extends Node3D

## Streams a repeating neighborhood block ahead of the player and
## recycles (frees) blocks once they're far enough behind, so the
## visible road never ends and the active node count stays bounded no
## matter how long a route runs. Decoupled from any one neighborhood:
## point `block_scene` at a different packed scene (a different map's
## block) and the streaming logic itself needs no changes.
##
## Each block is expected to expose unique-named `%LeftMailbox` and
## `%RightMailbox` nodes (both real Mailbox instances, kept for visual
## consistency even when not the one currently deliverable). This
## streamer decides which blocks actually get a mailbox registered with
## RouteManager as a deliverable target, alternating sides so both get
## fair, roughly even use.
##
## Blocks are indexed along the player's forward travel distance
## (always -Z; see player.gd) rather than raw world Z, so the math here
## doesn't need to know or care which way "forward" happens to be.
##
## Milestone 10.1: only every `mailbox_spacing_blocks`'th block ahead of
## the start line gets a registered (deliverable) mailbox -- registering
## one on *every* block gave no gap between delivery opportunities, and
## worse, the `blocks_behind` blocks pre-spawned for visual continuity
## behind the player's spawn point were being queued too, so the first
## two "deliveries" of every run activated and were instantly
## auto-skipped (RouteManager's mailbox_skip_margin) within the first
## couple of frames -- a visible flag-color flicker for zero player
## opportunity, immediately followed by a real first mailbox only ~1.6m
## ahead of the spawn line (near-zero reaction time). Requiring
## `index > 0` removes every behind-spawn and start-line block from
## consideration entirely, and the spacing multiple pushes the first
## real target out to a full reaction-time distance.
@export var block_scene: PackedScene
@export var block_length: float = 24.0
@export var blocks_ahead: int = 4
@export var blocks_behind: int = 2
@export var route_manager_path: NodePath
@export var player_path: NodePath

## Gameplay-based pacing, not an arbitrary number: at the bike's cruise
## speed (6.5 m/s, see player.gd's auto_cruise_speed) four blocks is
## 96m / ~14.8s between delivery opportunities -- squarely in Milestone
## 10.2's target 70-100m gap, and enough time to actually ride, steer,
## and look around between deliveries rather than immediately bracing
## for the next one. Braking only ever slows the bike below cruise
## speed, so this spacing is the worst case, never a tighter one.
## History: Milestone 10 shipped 1 (a mailbox on every block -- the
## "too crowded" complaint); Milestone 10.1 raised it to 2 (48m), which
## real-phone testing still found too dense; this is the second, much
## larger correction the brief explicitly asked for, not a small tweak.
@export var mailbox_spacing_blocks: int = 4

@onready var _route_manager: RouteManager = get_node_or_null(route_manager_path)
@onready var _player: Node3D = get_node_or_null(player_path)

var _active_blocks: Array[Node3D] = []
var _next_spawn_index: int = 0
var _next_side_is_left: bool = true
var _started: bool = false


func _ready() -> void:
	if _route_manager:
		_route_manager.state_changed.connect(_on_state_changed)


func _process(_delta: float) -> void:
	if _started and _route_manager and _route_manager.state != RouteManager.State.IDLE:
		_recycle_and_stream()


func _on_state_changed(new_state: RouteManager.State) -> void:
	# Fill the world as soon as the countdown begins (not only once ACTIVE)
	# so the player sees their starting street rather than bare ground
	# while counting down -- also gives the countdown a visible purpose.
	if new_state == RouteManager.State.COUNTDOWN:
		if _started:
			_reset()
		_started = true
		_fill_initial_blocks()


func active_block_count() -> int:
	return _active_blocks.size()


func _fill_initial_blocks() -> void:
	_next_spawn_index = -blocks_behind
	for _i in range(blocks_behind + blocks_ahead):
		_spawn_block(_next_spawn_index)
		_next_spawn_index += 1


func _recycle_and_stream() -> void:
	if not _player:
		return
	var travel_z := -_player.global_position.z
	var player_block_index := floori(travel_z / block_length)

	while _next_spawn_index < player_block_index + blocks_ahead:
		_spawn_block(_next_spawn_index)
		_next_spawn_index += 1

	var min_index := player_block_index - blocks_behind
	var i := 0
	while i < _active_blocks.size():
		var block := _active_blocks[i]
		if int(block.get_meta("block_index")) < min_index:
			block.queue_free()
			_active_blocks.remove_at(i)
		else:
			i += 1


func _spawn_block(index: int) -> void:
	if not block_scene:
		return
	var block := block_scene.instantiate()
	add_child(block)
	block.set_meta("block_index", index)
	block.position = Vector3(0.0, 0.0, -float(index) * block_length)
	_active_blocks.append(block)

	# index > 0 excludes both the blocks_behind visual-continuity blocks
	# (index < 0) and the start-line block itself (index 0, only ~1.6m
	# ahead of spawn -- no meaningful reaction time) from ever becoming a
	# delivery target; the spacing multiple then paces every target after
	# that at a full reaction-time distance apart.
	if index > 0 and index % mailbox_spacing_blocks == 0:
		var mailbox: Node = block.get_node_or_null("%LeftMailbox" if _next_side_is_left else "%RightMailbox")
		_next_side_is_left = not _next_side_is_left
		if mailbox and _route_manager:
			_route_manager.register_mailbox(mailbox)


func _reset() -> void:
	for block in _active_blocks:
		block.queue_free()
	_active_blocks.clear()
	_next_spawn_index = 0
	_next_side_is_left = true
	_started = false
