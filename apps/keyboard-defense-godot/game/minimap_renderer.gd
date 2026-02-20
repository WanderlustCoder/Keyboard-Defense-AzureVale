class_name MinimapRenderer
extends Control
## Minimap renderer showing an overview of the explored map.
## Displays terrain, fog of war, markers for castle/cursor/enemies, and camera viewport.
## Click on minimap to move camera to that location.

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")

signal minimap_clicked(tile_pos: Vector2i)

# =============================================================================
# CONFIGURATION
# =============================================================================

## Size of the minimap in pixels
@export var minimap_size: Vector2 = Vector2(200, 200)

## Background color for the minimap border
@export var border_color: Color = Color(0.6, 0.6, 0.7, 1.0)

## Border width
@export var border_width: float = 3.0

## Terrain colors
@export var plains_color: Color = Color(0.35, 0.45, 0.3, 1.0)
@export var forest_color: Color = Color(0.2, 0.35, 0.2, 1.0)
@export var mountain_color: Color = Color(0.4, 0.38, 0.35, 1.0)
@export var water_color: Color = Color(0.2, 0.35, 0.5, 1.0)

## Fog of war color for undiscovered tiles
@export var fog_color: Color = Color(0.08, 0.08, 0.12, 0.95)

## Castle marker color
@export var castle_color: Color = Color(0.4, 0.6, 1.0, 1.0)

## Cursor marker color
@export var cursor_color: Color = Color(1.0, 0.9, 0.3, 1.0)

## Enemy marker color
@export var enemy_color: Color = Color(0.9, 0.3, 0.3, 1.0)

## Camera viewport rectangle color
@export var viewport_rect_color: Color = Color(1.0, 1.0, 1.0, 0.5)


# =============================================================================
# STATE
# =============================================================================

# Map data
var map_w: int = 64
var map_h: int = 64
var base_pos: Vector2i = Vector2i(32, 32)
var cursor_pos: Vector2i = Vector2i(32, 32)
var discovered: Dictionary = {}
var terrain: Array = []
var enemies: Array = []

# Camera reference for viewport display
var camera: Camera2D = null
var _viewport_size: Vector2 = Vector2.ZERO

# Grid cell size (from main renderer) for viewport calculation
var grid_cell_size: Vector2 = Vector2(52, 52)
var grid_origin: Vector2 = Vector2(0, 0)


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	custom_minimum_size = minimap_size
	size = minimap_size
	# Enable mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Ensure visibility
	visible = true
	modulate = Color.WHITE
	# Initialize viewport size immediately
	_viewport_size = get_viewport_rect().size
	if _viewport_size == Vector2.ZERO:
		_viewport_size = Vector2(1920, 1080)
	# Only use absolute positioning if we're under a CanvasLayer (legacy/overlay mode)
	# When inside a Container, let the parent handle positioning
	if _is_inside_canvas_layer():
		call_deferred("_position_minimap")
		get_tree().root.size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	_viewport_size = get_viewport_rect().size
	if _viewport_size == Vector2.ZERO:
		_viewport_size = Vector2(1920, 1080)
	# Only reposition if we're in overlay mode (under CanvasLayer)
	if _is_inside_canvas_layer():
		position = Vector2(_viewport_size.x - minimap_size.x - 10, 10)
	queue_redraw()


func _position_minimap() -> void:
	# Only use absolute positioning in overlay mode
	if not _is_inside_canvas_layer():
		return
	_viewport_size = get_viewport_rect().size
	if _viewport_size == Vector2.ZERO:
		_viewport_size = Vector2(1920, 1080)
	position = Vector2(_viewport_size.x - minimap_size.x - 10, 10)
	queue_redraw()


## Check if this control is directly under a CanvasLayer (overlay mode)
func _is_inside_canvas_layer() -> bool:
	var parent := get_parent()
	# If parent is a CanvasLayer, we're in overlay mode
	if parent is CanvasLayer:
		return true
	# If parent is a Container, we're embedded in a layout
	if parent is Container:
		return false
	# If parent is Control with layout_mode, we're embedded
	if parent is Control and parent.get("layout_mode") != null:
		return false
	return false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)
			accept_event()
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_handle_click(event.position)
			accept_event()


func _handle_click(local_pos: Vector2) -> void:
	# Convert minimap position to tile coordinates
	var tile_w: float = minimap_size.x / float(map_w)
	var tile_h: float = minimap_size.y / float(map_h)

	var tile_x: int = int(local_pos.x / tile_w)
	var tile_y: int = int(local_pos.y / tile_h)

	# Clamp to map bounds
	tile_x = clampi(tile_x, 0, map_w - 1)
	tile_y = clampi(tile_y, 0, map_h - 1)

	var tile_pos := Vector2i(tile_x, tile_y)

	# Move camera directly if available
	if camera != null:
		var world_pos := grid_origin + Vector2(
			tile_x * grid_cell_size.x + grid_cell_size.x * 0.5,
			tile_y * grid_cell_size.y + grid_cell_size.y * 0.5
		)
		camera.center_on(world_pos, false)

	# Also emit signal for any additional handling
	minimap_clicked.emit(tile_pos)
	queue_redraw()


func _draw() -> void:
	var draw_area := Rect2(Vector2.ZERO, minimap_size)

	# Draw background (dark blue-gray)
	draw_rect(draw_area, Color(0.1, 0.1, 0.15, 1.0), true)

	# Calculate tile size on minimap
	var tile_w: float = minimap_size.x / float(map_w)
	var tile_h: float = minimap_size.y / float(map_h)

	# Draw terrain tiles
	for y in range(map_h):
		for x in range(map_w):
			var index: int = y * map_w + x
			var tile_rect := Rect2(x * tile_w, y * tile_h, tile_w, tile_h)

			if discovered.has(index):
				# Draw terrain color
				var terrain_type: String = _terrain_at(index)
				var color: Color = _terrain_color(terrain_type)
				draw_rect(tile_rect, color, true)
			else:
				# Draw fog
				draw_rect(tile_rect, fog_color, true)

	# Draw castle marker
	var castle_center := Vector2(
		(base_pos.x + 0.5) * tile_w,
		(base_pos.y + 0.5) * tile_h
	)
	var castle_radius: float = maxf(tile_w, tile_h) * 1.5
	draw_circle(castle_center, castle_radius, castle_color)

	# Draw cursor marker
	var cursor_rect := Rect2(
		cursor_pos.x * tile_w - tile_w * 0.5,
		cursor_pos.y * tile_h - tile_h * 0.5,
		tile_w * 2,
		tile_h * 2
	)
	draw_rect(cursor_rect, cursor_color, false, 1.5)

	# Draw enemy markers
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		if not SimMap.in_bounds(pos.x, pos.y, map_w, map_h):
			continue
		var enemy_center := Vector2(
			(pos.x + 0.5) * tile_w,
			(pos.y + 0.5) * tile_h
		)
		var enemy_radius: float = maxf(tile_w, tile_h) * 0.8
		draw_circle(enemy_center, enemy_radius, enemy_color)

	# Draw camera viewport rectangle
	if camera != null:
		var cam_rect := _get_camera_minimap_rect(tile_w, tile_h)
		draw_rect(cam_rect, viewport_rect_color, false, 1.5)

	# Draw border
	draw_rect(draw_area, border_color, false, border_width)


# =============================================================================
# PUBLIC API
# =============================================================================

## Update minimap state from GameState
func update_state(state: GameState) -> void:
	map_w = state.map_w
	map_h = state.map_h
	base_pos = state.base_pos
	cursor_pos = state.cursor_pos
	discovered = state.discovered.duplicate(true)
	terrain = state.terrain.duplicate(true)
	enemies = state.enemies.duplicate(true)
	queue_redraw()


## Set camera reference for viewport rectangle display
func set_camera(cam: Camera2D) -> void:
	camera = cam


## Set grid parameters for viewport calculation
func set_grid_params(cell_size: Vector2, origin: Vector2) -> void:
	grid_cell_size = cell_size
	grid_origin = origin


# =============================================================================
# INTERNAL
# =============================================================================

## Get terrain type at index
func _terrain_at(index: int) -> String:
	if index >= 0 and index < terrain.size():
		return str(terrain[index])
	return "plains"


## Map terrain type to color
func _terrain_color(terrain_type: String) -> Color:
	match terrain_type:
		SimMap.TERRAIN_PLAINS, "plains":
			return plains_color
		SimMap.TERRAIN_FOREST, "forest":
			return forest_color
		SimMap.TERRAIN_MOUNTAIN, "mountain":
			return mountain_color
		SimMap.TERRAIN_WATER, "water":
			return water_color
		_:
			return plains_color


## Calculate camera viewport rectangle on minimap
func _get_camera_minimap_rect(tile_w: float, tile_h: float) -> Rect2:
	if camera == null:
		return Rect2()

	# Ensure viewport size is valid
	var viewport_size := _viewport_size
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size
		if viewport_size == Vector2.ZERO:
			viewport_size = Vector2(1920, 1080)  # Fallback

	var cam_pos: Vector2 = camera.global_position
	var zoom: Vector2 = camera.zoom if camera.zoom != Vector2.ZERO else Vector2.ONE

	# Calculate visible world area
	var half_size: Vector2 = viewport_size / (2.0 * zoom)
	var visible_min: Vector2 = cam_pos - half_size
	var visible_max: Vector2 = cam_pos + half_size

	# Convert to tile coordinates
	var min_tile_x: float = (visible_min.x - grid_origin.x) / grid_cell_size.x
	var max_tile_x: float = (visible_max.x - grid_origin.x) / grid_cell_size.x
	var min_tile_y: float = (visible_min.y - grid_origin.y) / grid_cell_size.y
	var max_tile_y: float = (visible_max.y - grid_origin.y) / grid_cell_size.y

	# Clamp to map bounds for display
	min_tile_x = clampf(min_tile_x, 0.0, float(map_w))
	max_tile_x = clampf(max_tile_x, 0.0, float(map_w))
	min_tile_y = clampf(min_tile_y, 0.0, float(map_h))
	max_tile_y = clampf(max_tile_y, 0.0, float(map_h))

	# Convert to minimap coordinates
	var rect := Rect2(
		min_tile_x * tile_w,
		min_tile_y * tile_h,
		(max_tile_x - min_tile_x) * tile_w,
		(max_tile_y - min_tile_y) * tile_h
	)

	return rect
