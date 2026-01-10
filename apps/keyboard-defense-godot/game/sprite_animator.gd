extends Node
class_name SpriteAnimator
## Central animation controller for sprite-based animations
## Manages frame timing, state transitions, and oneshot animations

const AssetLoader = preload("res://game/asset_loader.gd")

# Animation state per entity
var _animations: Dictionary = {}  # entity_id -> AnimState
var _global_time: float = 0.0
var _asset_loader: AssetLoader

# Reduced motion setting (disable animations when true)
var reduced_motion: bool = false

## Animation state for a single entity
class AnimState:
	var sprite_id: String = ""
	var current_frame: int = 0
	var frame_timer: float = 0.0
	var fps: float = 8.0
	var frame_count: int = 1
	var loop: bool = true
	var playing: bool = true
	var on_complete: Callable
	var base_sprite_id: String = ""  # For reverting after oneshot

	func reset() -> void:
		current_frame = 0
		frame_timer = 0.0
		playing = true

func _ready() -> void:
	_asset_loader = AssetLoader.new()
	_asset_loader._load_manifest()

## Register an animation for an entity
func register_animation(entity_id: int, sprite_id: String, anim_info: Dictionary = {}) -> void:
	if reduced_motion:
		return

	var state := AnimState.new()
	state.sprite_id = sprite_id
	state.frame_count = anim_info.get("frame_count", 1)
	state.fps = anim_info.get("fps", 8.0)
	state.loop = anim_info.get("loop", true)
	state.base_sprite_id = sprite_id

	# If no anim_info provided, try to get from asset loader
	if anim_info.is_empty() and _asset_loader:
		var loaded_info := _asset_loader.get_animation_info(sprite_id)
		if not loaded_info.is_empty():
			state.frame_count = loaded_info.get("frame_count", 1)
			state.fps = loaded_info.get("fps", 8.0)
			state.loop = loaded_info.get("loop", true)

	_animations[entity_id] = state

## Unregister animation for an entity (when entity is removed)
func unregister_animation(entity_id: int) -> void:
	_animations.erase(entity_id)

## Update all animations - call from _process
func update(delta: float) -> void:
	if reduced_motion:
		return

	_global_time += delta

	var completed_oneshots: Array = []

	for entity_id in _animations:
		var state: AnimState = _animations[entity_id]
		if not state.playing:
			continue

		state.frame_timer += delta
		var frame_duration: float = 1.0 / state.fps if state.fps > 0 else 0.125

		while state.frame_timer >= frame_duration:
			state.frame_timer -= frame_duration
			state.current_frame += 1

			if state.current_frame >= state.frame_count:
				if state.loop:
					state.current_frame = 0
				else:
					state.current_frame = state.frame_count - 1
					state.playing = false
					if state.on_complete.is_valid():
						completed_oneshots.append(entity_id)

	# Handle completed oneshots outside iteration
	for entity_id in completed_oneshots:
		var state: AnimState = _animations[entity_id]
		var callback: Callable = state.on_complete

		# Revert to base animation if set
		if not state.base_sprite_id.is_empty() and state.base_sprite_id != state.sprite_id:
			register_animation(entity_id, state.base_sprite_id)

		callback.call()

## Get current frame index for an entity
func get_current_frame(entity_id: int) -> int:
	if not _animations.has(entity_id):
		return 0
	return _animations[entity_id].current_frame

## Get animation state for an entity
func get_animation_state(entity_id: int) -> AnimState:
	return _animations.get(entity_id, null)

## Check if entity has an active animation
func has_animation(entity_id: int) -> bool:
	return _animations.has(entity_id)

## Play a oneshot animation that doesn't loop
func play_oneshot(entity_id: int, sprite_id: String, on_complete: Callable = Callable()) -> void:
	if reduced_motion:
		if on_complete.is_valid():
			on_complete.call()
		return

	# Store current animation as base to revert to
	var base_sprite: String = ""
	if _animations.has(entity_id):
		base_sprite = _animations[entity_id].base_sprite_id

	# Get animation info
	var anim_info: Dictionary = {}
	if _asset_loader:
		anim_info = _asset_loader.get_animation_info(sprite_id)

	var state := AnimState.new()
	state.sprite_id = sprite_id
	state.frame_count = anim_info.get("frame_count", 3)
	state.fps = anim_info.get("fps", 10.0)
	state.loop = false
	state.on_complete = on_complete
	state.base_sprite_id = base_sprite
	state.playing = true

	_animations[entity_id] = state

## Set animation to specific frame (for syncing or pausing)
func set_frame(entity_id: int, frame: int) -> void:
	if not _animations.has(entity_id):
		return
	var state: AnimState = _animations[entity_id]
	state.current_frame = clampi(frame, 0, state.frame_count - 1)

## Pause animation for entity
func pause(entity_id: int) -> void:
	if _animations.has(entity_id):
		_animations[entity_id].playing = false

## Resume animation for entity
func resume(entity_id: int) -> void:
	if _animations.has(entity_id):
		_animations[entity_id].playing = true

## Pause all animations
func pause_all() -> void:
	for entity_id in _animations:
		_animations[entity_id].playing = false

## Resume all animations
func resume_all() -> void:
	for entity_id in _animations:
		_animations[entity_id].playing = true

## Get sprite ID with frame suffix for loading correct texture
func get_frame_sprite_id(entity_id: int) -> String:
	if not _animations.has(entity_id):
		return ""
	var state: AnimState = _animations[entity_id]
	# Format: sprite_id_01, sprite_id_02, etc.
	return "%s_%02d" % [state.sprite_id, state.current_frame + 1]

## Clear all animations (e.g., on scene change)
func clear_all() -> void:
	_animations.clear()

## Get global animation time (useful for procedural effects)
func get_global_time() -> float:
	return _global_time

## Sync multiple entities to same animation phase
func sync_animations(entity_ids: Array) -> void:
	if entity_ids.is_empty():
		return

	# Use first entity as reference
	var ref_state: AnimState = _animations.get(entity_ids[0], null)
	if ref_state == null:
		return

	for i in range(1, entity_ids.size()):
		var entity_id: int = entity_ids[i]
		if _animations.has(entity_id):
			var state: AnimState = _animations[entity_id]
			state.current_frame = ref_state.current_frame
			state.frame_timer = ref_state.frame_timer
