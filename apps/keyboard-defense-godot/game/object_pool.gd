class_name ObjectPool
extends RefCounted
## Generic object pool for reusing Node instances.
## Reduces garbage collection overhead from frequent create/destroy cycles.

## Pool statistics for monitoring
var stats := {
	"created": 0,
	"reused": 0,
	"returned": 0,
	"peak_active": 0,
	"current_active": 0
}

var _pool: Array = []
var _active: Array = []
var _factory: Callable
var _reset_func: Callable
var _max_pool_size: int
var _parent: Node = null

## Create a new object pool
## factory: Callable that creates a new instance
## reset_func: Callable that resets an instance for reuse (receives the instance)
## max_pool_size: Maximum number of inactive objects to keep (0 = unlimited)
func _init(factory: Callable, reset_func: Callable = Callable(), max_pool_size: int = 100) -> void:
	_factory = factory
	_reset_func = reset_func
	_max_pool_size = max_pool_size


## Set parent node for pooled objects
func set_parent(parent: Node) -> void:
	_parent = parent


## Pre-warm the pool by creating instances ahead of time
func prewarm(count: int) -> void:
	for i in range(count):
		var obj = _create_instance()
		if obj is Node:
			obj.visible = false
		_pool.append(obj)


## Get an object from the pool (creates new if pool is empty)
func acquire():
	var obj

	if _pool.is_empty():
		obj = _create_instance()
		stats.created += 1
	else:
		obj = _pool.pop_back()
		stats.reused += 1

	_active.append(obj)
	stats.current_active = _active.size()
	stats.peak_active = maxi(stats.peak_active, stats.current_active)

	# Make visible and reset
	if obj is Node:
		obj.visible = true

	if _reset_func.is_valid():
		_reset_func.call(obj)

	return obj


## Return an object to the pool for reuse
func release(obj) -> void:
	var idx := _active.find(obj)
	if idx == -1:
		return  # Not from this pool

	_active.remove_at(idx)
	stats.current_active = _active.size()
	stats.returned += 1

	# Hide the object
	if obj is Node:
		obj.visible = false

	# Only keep up to max_pool_size inactive objects
	if _max_pool_size > 0 and _pool.size() >= _max_pool_size:
		if obj is Node:
			obj.queue_free()
		return

	_pool.append(obj)


## Release all active objects back to pool
func release_all() -> void:
	for obj in _active.duplicate():
		release(obj)


## Clear the entire pool (frees all objects)
func clear() -> void:
	for obj in _active:
		if obj is Node and is_instance_valid(obj):
			obj.queue_free()
	_active.clear()

	for obj in _pool:
		if obj is Node and is_instance_valid(obj):
			obj.queue_free()
	_pool.clear()

	stats.current_active = 0


## Get pool statistics
func get_stats() -> Dictionary:
	return stats.duplicate()


## Get count of available pooled objects
func get_available_count() -> int:
	return _pool.size()


## Get count of currently active objects
func get_active_count() -> int:
	return _active.size()


func _create_instance():
	var obj = _factory.call()
	if obj is Node and _parent != null:
		_parent.add_child(obj)
		obj.visible = false
	return obj


# =============================================================================
# STATIC POOL MANAGER
# =============================================================================

## Global pool registry for shared pools
static var _pools: Dictionary = {}


## Get or create a named pool
static func get_pool(pool_name: String, factory: Callable = Callable(), reset_func: Callable = Callable(), max_size: int = 100) -> ObjectPool:
	if _pools.has(pool_name):
		return _pools[pool_name]

	if not factory.is_valid():
		push_error("ObjectPool: Cannot create pool '%s' without factory" % pool_name)
		return null

	# Use load() to reference own class from static context
	var object_pool_class = load("res://game/object_pool.gd")
	var pool = object_pool_class.new(factory, reset_func, max_size)
	_pools[pool_name] = pool
	return pool


## Check if a named pool exists
static func has_pool(pool_name: String) -> bool:
	return _pools.has(pool_name)


## Clear a specific named pool
static func clear_pool(pool_name: String) -> void:
	if _pools.has(pool_name):
		_pools[pool_name].clear()
		_pools.erase(pool_name)


## Clear all named pools
static func clear_all_pools() -> void:
	for pool_name in _pools.keys():
		_pools[pool_name].clear()
	_pools.clear()


## Get statistics for all pools
static func get_all_stats() -> Dictionary:
	var all_stats := {}
	for pool_name in _pools.keys():
		all_stats[pool_name] = _pools[pool_name].get_stats()
	return all_stats
