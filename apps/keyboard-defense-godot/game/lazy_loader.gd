class_name LazyLoader
extends RefCounted
## Lazy loading utility for deferring resource loading until needed.
## Reduces startup time and memory usage for infrequently used resources.

## Cache of loaded resources
static var _cache: Dictionary = {}

## Loading statistics
static var _stats := {
	"loads": 0,
	"cache_hits": 0,
	"total_load_time_ms": 0.0
}

## Load a resource lazily (from cache if available)
static func load_resource(path: String) -> Resource:
	if _cache.has(path):
		_stats.cache_hits += 1
		return _cache[path]

	var start_time := Time.get_ticks_msec()
	var resource := load(path)
	var load_time := Time.get_ticks_msec() - start_time

	if resource != null:
		_cache[path] = resource
		_stats.loads += 1
		_stats.total_load_time_ms += load_time

	return resource


## Load and instantiate a scene lazily
static func load_scene(path: String) -> Node:
	var packed_scene: PackedScene = load_resource(path) as PackedScene
	if packed_scene == null:
		push_error("LazyLoader: Failed to load scene: %s" % path)
		return null

	return packed_scene.instantiate()


## Preload multiple resources in the background
static func preload_batch(paths: Array[String], callback: Callable = Callable()) -> void:
	# Load each resource (could be made async with threading in future)
	for path in paths:
		load_resource(path)

	if callback.is_valid():
		callback.call()


## Clear a specific resource from cache
static func clear_resource(path: String) -> void:
	_cache.erase(path)


## Clear all cached resources
static func clear_cache() -> void:
	_cache.clear()


## Get loading statistics
static func get_stats() -> Dictionary:
	return _stats.duplicate()


## Check if a resource is cached
static func is_cached(path: String) -> bool:
	return _cache.has(path)


## Get cache size
static func get_cache_size() -> int:
	return _cache.size()


# =============================================================================
# PANEL MANAGER - Lazy panel instantiation
# =============================================================================

## Registered panel scenes (path -> packed scene or null if not loaded)
static var _panel_registry: Dictionary = {}

## Instantiated panels (path -> instance)
static var _panel_instances: Dictionary = {}


## Register a panel for lazy loading
static func register_panel(panel_id: String, scene_path: String) -> void:
	_panel_registry[panel_id] = scene_path


## Get or create a panel instance
static func get_panel(panel_id: String, parent: Node = null) -> Node:
	# Return existing instance if available
	if _panel_instances.has(panel_id):
		var instance = _panel_instances[panel_id]
		if is_instance_valid(instance):
			return instance

	# Check if registered
	if not _panel_registry.has(panel_id):
		push_error("LazyLoader: Panel not registered: %s" % panel_id)
		return null

	# Load and instantiate
	var scene_path: String = _panel_registry[panel_id]
	var instance := load_scene(scene_path)

	if instance == null:
		return null

	_panel_instances[panel_id] = instance

	# Add to parent if provided
	if parent != null:
		parent.add_child(instance)
		instance.visible = false

	return instance


## Release a panel instance (removes from tree but keeps in cache)
static func release_panel(panel_id: String) -> void:
	if not _panel_instances.has(panel_id):
		return

	var instance = _panel_instances[panel_id]
	if is_instance_valid(instance) and instance.get_parent() != null:
		instance.get_parent().remove_child(instance)


## Destroy a panel instance (frees memory)
static func destroy_panel(panel_id: String) -> void:
	if not _panel_instances.has(panel_id):
		return

	var instance = _panel_instances[panel_id]
	if is_instance_valid(instance):
		instance.queue_free()

	_panel_instances.erase(panel_id)


## Check if a panel is instantiated
static func has_panel_instance(panel_id: String) -> bool:
	if not _panel_instances.has(panel_id):
		return false
	return is_instance_valid(_panel_instances[panel_id])


## Get all registered panel IDs
static func get_registered_panels() -> Array[String]:
	var panels: Array[String] = []
	for key in _panel_registry.keys():
		panels.append(str(key))
	return panels
