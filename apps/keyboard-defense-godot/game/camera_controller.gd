class_name CameraController
extends Camera2D
## Camera controller for large maps with arrow key and click-drag controls.
## Handles smooth scrolling with bounds clamping to map edges.

signal camera_moved(new_position: Vector2)

# =============================================================================
# CONFIGURATION
# =============================================================================

## Camera pan speed in pixels per second
@export var pan_speed: float = 600.0

## Margin in pixels from screen edge to trigger edge panning
@export var edge_pan_margin: int = 32

## Enable/disable edge panning (mouse near screen edges)
@export var edge_pan_enabled: bool = false

## Smoothing factor for camera movement (higher = faster response)
@export var smooth_factor: float = 12.0

## Enable WASD keys for panning (in addition to arrow keys)
@export var wasd_enabled: bool = false

## Enable click-and-drag panning
@export var drag_enabled: bool = true

## Game area height as ratio of viewport (0.736 = 73.6% for keyboard layout)
## Used to calculate camera bounds correctly when UI takes up bottom of screen
@export var game_area_ratio: float = 0.736

## Game area width as ratio of viewport (0.78 = 78% for right sidebar layout)
## Used to calculate camera bounds correctly when UI sidebar takes up right of screen
@export var game_area_width_ratio: float = 0.78


# =============================================================================
# STATE
# =============================================================================

# Map bounds in world coordinates (calculated from origin + size + viewport)
var _map_bounds: Rect2 = Rect2()

# Original map parameters (stored for recalculating bounds on resize)
var _map_origin: Vector2 = Vector2.ZERO
var _map_size: Vector2 = Vector2.ZERO

# Viewport size cache
var _viewport_size: Vector2 = Vector2.ZERO

# Target position for smooth movement
var _target_position: Vector2 = Vector2.ZERO

# Whether camera is currently panning
var _is_panning: bool = false

# Whether to process input (can be disabled during UI interactions)
var _input_enabled: bool = true

# Click-and-drag state
var _is_dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_camera: Vector2 = Vector2.ZERO


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	_target_position = global_position
	# Connect to window resize signal to update viewport size and bounds
	get_tree().root.size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	var old_viewport_size := _viewport_size
	_viewport_size = get_viewport_rect().size
	if _viewport_size == Vector2.ZERO:
		_viewport_size = old_viewport_size  # Keep previous size if invalid
		return
	# Recalculate map bounds with new viewport size using stored original values
	if _map_size != Vector2.ZERO:
		set_map_bounds(_map_origin, _map_size)


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or not drag_enabled:
		return

	# Handle mouse button for drag start/end
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				_is_dragging = true
				_drag_start_mouse = event.position
				_drag_start_camera = global_position
			else:
				# Stop dragging
				_is_dragging = false

	# Handle mouse motion for dragging
	elif event is InputEventMouseMotion and _is_dragging:
		var drag_delta: Vector2 = event.position - _drag_start_mouse
		# Move camera in opposite direction of drag (drag map, not camera)
		var new_pos: Vector2 = _drag_start_camera - drag_delta / zoom
		_target_position = _clamp_to_bounds(new_pos)
		global_position = _target_position
		_is_panning = true


func _process(delta: float) -> void:
	if not _input_enabled:
		return

	var pan_direction := Vector2.ZERO

	# Keyboard panning - Arrow keys
	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1.0
	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1.0
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1.0
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1.0

	# WASD keys (if enabled)
	if wasd_enabled:
		if Input.is_key_pressed(KEY_A):
			pan_direction.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			pan_direction.x += 1.0
		if Input.is_key_pressed(KEY_W):
			pan_direction.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			pan_direction.y += 1.0

	# Edge panning (if enabled)
	if edge_pan_enabled:
		var mouse_pos := get_viewport().get_mouse_position()

		if mouse_pos.x < edge_pan_margin:
			pan_direction.x -= 1.0
		elif mouse_pos.x > _viewport_size.x - edge_pan_margin:
			pan_direction.x += 1.0

		if mouse_pos.y < edge_pan_margin:
			pan_direction.y -= 1.0
		elif mouse_pos.y > _viewport_size.y - edge_pan_margin:
			pan_direction.y += 1.0

	# Apply panning
	if pan_direction != Vector2.ZERO:
		pan_direction = pan_direction.normalized()
		_target_position += pan_direction * pan_speed * delta
		_target_position = _clamp_to_bounds(_target_position)
		_is_panning = true

	# Smooth movement toward target
	var old_pos := global_position
	global_position = global_position.lerp(_target_position, smooth_factor * delta)

	# Emit signal when panning completes
	if _is_panning and global_position.distance_to(_target_position) < 1.0:
		_is_panning = false
		global_position = _target_position
		camera_moved.emit(global_position)

	# Request redraw if position changed
	if global_position != old_pos:
		# GridRenderer will redraw on next frame
		pass


# =============================================================================
# PUBLIC API
# =============================================================================

## Set the map bounds for camera clamping
## origin: Top-left corner of the map in world coordinates
## map_size: Total size of the map in pixels
func set_map_bounds(origin: Vector2, map_size: Vector2) -> void:
	# Store original parameters for recalculating on window resize
	_map_origin = origin
	_map_size = map_size

	# Calculate effective game area size (accounting for keyboard at bottom and sidebar on right)
	var effective_viewport := Vector2(
		_viewport_size.x * game_area_width_ratio,
		_viewport_size.y * game_area_ratio
	)

	# Calculate the valid camera position range
	# Camera position is at center, so we need half-viewport margin
	var half_vp := effective_viewport / (2.0 * zoom)

	# Bounds ensure camera doesn't show area outside the map
	_map_bounds = Rect2(
		origin + half_vp,
		map_size - half_vp * 2.0
	)

	# Handle small maps where bounds might be inverted
	if _map_bounds.size.x < 0:
		_map_bounds.position.x = origin.x + map_size.x / 2.0
		_map_bounds.size.x = 0
	if _map_bounds.size.y < 0:
		_map_bounds.position.y = origin.y + map_size.y / 2.0
		_map_bounds.size.y = 0

	# Clamp current position to new bounds
	_target_position = _clamp_to_bounds(_target_position)
	global_position = _target_position


## Center camera on a world position
## instant: If true, jump immediately; if false, smooth transition
func center_on(world_pos: Vector2, instant: bool = false) -> void:
	_target_position = _clamp_to_bounds(world_pos)
	if instant:
		global_position = _target_position


## Center camera on a grid cell position
func center_on_cell(cell_pos: Vector2i, grid_origin: Vector2, cell_size: Vector2, instant: bool = false) -> void:
	var world_pos := grid_origin + Vector2(
		cell_pos.x * cell_size.x + cell_size.x * 0.5,
		cell_pos.y * cell_size.y + cell_size.y * 0.5
	)
	center_on(world_pos, instant)


## Enable or disable camera input processing
func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_is_dragging = false


## Check if camera is currently panning
func is_panning() -> bool:
	return _is_panning


## Check if camera is currently being dragged
func is_dragging() -> bool:
	return _is_dragging


## Get the current visible world rect
func get_visible_rect() -> Rect2:
	# Use effective game area (accounting for keyboard and sidebar)
	var effective_viewport := Vector2(
		_viewport_size.x * game_area_width_ratio,
		_viewport_size.y * game_area_ratio
	)
	var half_size := effective_viewport / (2.0 * zoom)
	return Rect2(global_position - half_size, half_size * 2.0)


## Get visible tile range for culling
## Returns {"min_x", "max_x", "min_y", "max_y"} in tile coordinates
func get_visible_tile_range(grid_origin: Vector2, cell_size: Vector2, map_w: int, map_h: int) -> Dictionary:
	var visible := get_visible_rect()

	# Convert to tile coordinates with padding for partial tiles
	var min_x := maxi(0, int((visible.position.x - grid_origin.x) / cell_size.x) - 1)
	var max_x := mini(map_w, int((visible.end.x - grid_origin.x) / cell_size.x) + 2)
	var min_y := maxi(0, int((visible.position.y - grid_origin.y) / cell_size.y) - 1)
	var max_y := mini(map_h, int((visible.end.y - grid_origin.y) / cell_size.y) + 2)

	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y
	}


# =============================================================================
# INTERNAL
# =============================================================================

## Clamp a position to the map bounds
func _clamp_to_bounds(pos: Vector2) -> Vector2:
	if _map_bounds.size == Vector2.ZERO:
		return pos

	return Vector2(
		clampf(pos.x, _map_bounds.position.x, _map_bounds.end.x),
		clampf(pos.y, _map_bounds.position.y, _map_bounds.end.y)
	)
