class_name E2EErrorMonitor
extends RefCounted
## Captures errors and performance issues during E2E test execution.

const PerfMonitor = preload("res://game/perf_monitor.gd")

var _capturing: bool = false
var _captured_errors: Array = []
var _captured_warnings: Array = []
var _captured_events: Array[String] = []
var _start_memory: Dictionary = {}
var _perf_thresholds: Dictionary = {
	"max_frame_ms": 33.33,       # 30 FPS minimum
	"max_memory_mb": 500.0,      # Memory limit
	"max_orphan_nodes": 10       # Orphan node limit
}


## Start capturing errors and performance
func start_capture() -> void:
	_capturing = true
	_captured_errors.clear()
	_captured_warnings.clear()
	_captured_events.clear()
	_start_memory = PerfMonitor.get_memory_stats()
	PerfMonitor.reset()


## Stop capturing and return all captured items
func stop_capture() -> Array:
	_capturing = false
	var all_captured: Array = []

	for error in _captured_errors:
		all_captured.append({"type": "error", "message": str(error)})

	for warning in _captured_warnings:
		all_captured.append({"type": "warning", "message": str(warning)})

	var perf_issues: Array = _check_performance()
	for issue in perf_issues:
		all_captured.append({"type": "perf", "message": issue})

	return all_captured


## Record an error
func record_error(message: String) -> void:
	if _capturing:
		_captured_errors.append(message)


## Record a warning
func record_warning(message: String) -> void:
	if _capturing:
		_captured_warnings.append(message)


## Record a single event from operation feedback
func record_event(event: String) -> void:
	if _capturing:
		_captured_events.append(event)


## Record events array from sim layer
func record_events(events: Array) -> void:
	if _capturing:
		for event in events:
			_captured_events.append(str(event))


## Check for performance regressions
func _check_performance() -> Array:
	var issues: Array = []
	var frame_stats: Dictionary = PerfMonitor.get_frame_stats()
	var memory_stats: Dictionary = PerfMonitor.get_memory_stats()

	var max_ms: float = float(frame_stats.get("max_ms", 0.0))
	if max_ms > _perf_thresholds.max_frame_ms:
		issues.append("Frame time exceeded: %.2fms (limit: %.2fms)" % [max_ms, _perf_thresholds.max_frame_ms])

	var memory_mb: float = float(memory_stats.get("static_mem", 0)) / 1048576.0
	if memory_mb > _perf_thresholds.max_memory_mb:
		issues.append("Memory exceeded: %.1fMB (limit: %.1fMB)" % [memory_mb, _perf_thresholds.max_memory_mb])

	var orphans: int = int(memory_stats.get("orphan_count", 0))
	if orphans > _perf_thresholds.max_orphan_nodes:
		issues.append("Orphan nodes: %d (limit: %d)" % [orphans, _perf_thresholds.max_orphan_nodes])

	return issues


## Get all captured events
func get_captured_events() -> Array[String]:
	return _captured_events


## Set performance thresholds
func set_perf_thresholds(thresholds: Dictionary) -> void:
	for key in thresholds.keys():
		if _perf_thresholds.has(key):
			_perf_thresholds[key] = thresholds[key]


## Check if currently capturing
func is_capturing() -> bool:
	return _capturing
