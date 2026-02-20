class_name PerfMonitor
extends RefCounted
## Performance monitoring utilities for tracking FPS, frame times, and system health.

const ObjectPool = preload("res://game/object_pool.gd")

# =============================================================================
# FRAME TIMING
# =============================================================================

## Rolling window for FPS calculation
static var _frame_times: Array[float] = []
const FRAME_WINDOW_SIZE := 60

## Frame time thresholds (milliseconds)
const FRAME_TIME_TARGET := 16.67  # 60 FPS
const FRAME_TIME_WARNING := 20.0   # 50 FPS
const FRAME_TIME_CRITICAL := 33.33 # 30 FPS

## Track frame time
static func record_frame_time(delta: float) -> void:
	_frame_times.append(delta * 1000.0)  # Convert to ms
	if _frame_times.size() > FRAME_WINDOW_SIZE:
		_frame_times.pop_front()


## Get average FPS over window
static func get_avg_fps() -> float:
	if _frame_times.is_empty():
		return 0.0
	var avg_ms := 0.0
	for t in _frame_times:
		avg_ms += t
	avg_ms /= _frame_times.size()
	return 1000.0 / avg_ms if avg_ms > 0 else 0.0


## Get minimum FPS (worst frame)
static func get_min_fps() -> float:
	if _frame_times.is_empty():
		return 0.0
	var max_time := 0.0
	for t in _frame_times:
		max_time = maxf(max_time, t)
	return 1000.0 / max_time if max_time > 0 else 0.0


## Get frame time statistics
static func get_frame_stats() -> Dictionary:
	if _frame_times.is_empty():
		return {
			"avg_ms": 0.0,
			"min_ms": 0.0,
			"max_ms": 0.0,
			"avg_fps": 0.0,
			"min_fps": 0.0,
			"status": "unknown"
		}

	var total := 0.0
	var min_t := INF
	var max_t := 0.0

	for t in _frame_times:
		total += t
		min_t = minf(min_t, t)
		max_t = maxf(max_t, t)

	var avg_ms := total / _frame_times.size()
	var status := "good"
	if max_t > FRAME_TIME_CRITICAL:
		status = "critical"
	elif max_t > FRAME_TIME_WARNING:
		status = "warning"

	return {
		"avg_ms": avg_ms,
		"min_ms": min_t,
		"max_ms": max_t,
		"avg_fps": 1000.0 / avg_ms if avg_ms > 0 else 0.0,
		"min_fps": 1000.0 / max_t if max_t > 0 else 0.0,
		"status": status
	}


# =============================================================================
# MEMORY TRACKING
# =============================================================================

## Get basic memory info
static func get_memory_stats() -> Dictionary:
	return {
		"static_mem": Performance.get_monitor(Performance.MEMORY_STATIC),
		"static_mem_max": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"orphan_count": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	}


# =============================================================================
# RENDER TRACKING
# =============================================================================

## Get render statistics
static func get_render_stats() -> Dictionary:
	return {
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"vertices": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"2d_items": 0,  # Not available in Godot 4.2
		"2d_draw_calls": 0  # Not available in Godot 4.2
	}


# =============================================================================
# POOL TRACKING
# =============================================================================

## Get object pool statistics
static func get_pool_stats() -> Dictionary:
	return ObjectPool.get_all_stats()


# =============================================================================
# COMPREHENSIVE REPORT
# =============================================================================

## Get full performance report
static func get_full_report() -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"frame": get_frame_stats(),
		"memory": get_memory_stats(),
		"render": get_render_stats(),
		"pools": get_pool_stats()
	}


## Get performance summary as formatted string
static func get_summary_text() -> String:
	var frame := get_frame_stats()
	var memory := get_memory_stats()
	var render := get_render_stats()

	var lines: Array[String] = []
	lines.append("=== Performance Monitor ===")
	lines.append("FPS: %.1f (min: %.1f) [%s]" % [frame.avg_fps, frame.min_fps, frame.status])
	lines.append("Frame: %.2fms avg, %.2fms max" % [frame.avg_ms, frame.max_ms])
	lines.append("Memory: %.1f MB static" % [memory.static_mem / 1048576.0])
	lines.append("Objects: %d nodes, %d orphans" % [memory.node_count, memory.orphan_count])
	lines.append("Draw calls: %d (2D: %d)" % [render.draw_calls, render["2d_draw_calls"]])

	var pool_stats := get_pool_stats()
	if not pool_stats.is_empty():
		lines.append("--- Object Pools ---")
		for pool_name in pool_stats.keys():
			var ps: Dictionary = pool_stats[pool_name]
			lines.append("  %s: %d active, %d reused" % [pool_name, ps.get("current_active", 0), ps.get("reused", 0)])

	return "\n".join(lines)


## Check if performance is acceptable
static func is_performance_ok() -> bool:
	var frame := get_frame_stats()
	return frame.status != "critical"


## Reset all tracking
static func reset() -> void:
	_frame_times.clear()


# =============================================================================
# PROFILING HELPERS
# =============================================================================

## Simple scope timer for profiling code sections
class ScopeTimer extends RefCounted:
	var _name: String
	var _start_time: int
	var _threshold_ms: float

	func _init(name: String, threshold_ms: float = 1.0) -> void:
		_name = name
		_threshold_ms = threshold_ms
		_start_time = Time.get_ticks_usec()

	func stop() -> float:
		var elapsed_us: int = Time.get_ticks_usec() - _start_time
		var elapsed_ms: float = elapsed_us / 1000.0
		if elapsed_ms > _threshold_ms:
			print("[PERF] %s: %.2fms" % [_name, elapsed_ms])
		return elapsed_ms


## Start a scope timer (returns timer to stop manually, or auto-stops on GC)
static func start_timer(name: String, threshold_ms: float = 1.0) -> ScopeTimer:
	return ScopeTimer.new(name, threshold_ms)


## Measure a callable and return elapsed time in ms
static func measure(callable: Callable) -> float:
	var start: int = Time.get_ticks_usec()
	callable.call()
	return (Time.get_ticks_usec() - start) / 1000.0
