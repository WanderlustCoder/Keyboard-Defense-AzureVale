class_name ScenarioReport
extends RefCounted

static func build_report(results: Array, meta: Dictionary) -> Dictionary:
    var ok_count: int = 0
    var fail_count: int = 0
    var failed_ids: Array[String] = []
    var baseline_pass_count: int = 0
    var target_total_count: int = 0
    var target_met_count: int = 0
    for result in results:
        var baseline_failures: Array = result.get("baseline_failures", result.get("failures", []))
        if baseline_failures.is_empty():
            baseline_pass_count += 1
        var target_expected: bool = bool(result.get("target_expected", false))
        if target_expected:
            target_total_count += 1
            var target_failures: Array = result.get("target_failures", [])
            if target_failures.is_empty():
                target_met_count += 1
        if bool(result.get("pass", false)):
            ok_count += 1
        else:
            fail_count += 1
            failed_ids.append(str(result.get("id", "unknown")))
    return {
        "meta": meta,
        "summary": {
            "total": results.size(),
            "ok": ok_count,
            "fail": fail_count,
            "failed_ids": failed_ids,
            "baseline_pass_count": baseline_pass_count,
            "target_met_count": target_met_count,
            "target_total_count": target_total_count
        },
        "results": results
    }

static func default_output_path() -> String:
    var timestamp: String = str(Time.get_unix_time_from_system())
    return "user://scenario_reports/%s.json" % timestamp

static func write_report(report: Dictionary, output_path: String, out_dir: String = "") -> Dictionary:
    var path: String = _resolve_output_path(output_path, out_dir)
    var report_with_path: Dictionary = report.duplicate(true)
    report_with_path["report_path"] = path
    _ensure_directory(path)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Failed to open report path: %s" % path}
    file.store_string(JSON.stringify(report_with_path, "  "))
    file.close()
    return {"ok": true, "path": path, "report": report_with_path}

static func write_last_summary(lines: Array[String], out_dir: String = "") -> Dictionary:
    var path: String = _summary_path(out_dir)
    _ensure_directory(path)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Failed to open summary path: %s" % path}
    for line in lines:
        file.store_line(str(line))
    file.close()
    return {"ok": true, "path": path}

static func _resolve_output_path(output_path: String, out_dir: String) -> String:
    var path: String = _normalize_output_path(output_path)
    if path != "":
        return path
    var normalized_dir: String = _normalize_dir(out_dir)
    if normalized_dir != "":
        return _join_path(normalized_dir, "%s.json" % str(Time.get_unix_time_from_system()))
    return default_output_path()

static func _summary_path(out_dir: String) -> String:
    var normalized_dir: String = _normalize_dir(out_dir)
    if normalized_dir != "":
        return _join_path(normalized_dir, "last_summary.txt")
    return "user://scenario_reports/last_summary.txt"

static func _normalize_output_path(path: String) -> String:
    var trimmed: String = str(path).strip_edges()
    if trimmed == "":
        return ""
    if trimmed.begins_with("res://") or trimmed.begins_with("user://"):
        return trimmed
    if trimmed.is_absolute_path():
        return trimmed
    if trimmed.begins_with("./"):
        trimmed = trimmed.substr(2)
    return "res://%s" % trimmed

static func _normalize_dir(path: String) -> String:
    var trimmed: String = str(path).strip_edges()
    if trimmed == "":
        return ""
    if trimmed.ends_with("/"):
        trimmed = trimmed.substr(0, trimmed.length() - 1)
    if trimmed.begins_with("res://") or trimmed.begins_with("user://"):
        return trimmed
    if trimmed.is_absolute_path():
        return trimmed
    if trimmed.begins_with("./"):
        trimmed = trimmed.substr(2)
    return "res://%s" % trimmed

static func _join_path(dir_path: String, file_name: String) -> String:
    if dir_path == "":
        return file_name
    if dir_path.ends_with("/"):
        return dir_path + file_name
    return dir_path + "/" + file_name

static func _ensure_directory(path: String) -> void:
    var base_dir: String = path.get_base_dir()
    if base_dir == "":
        return
    if path.begins_with("user://"):
        DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/" + path.substr(7).get_base_dir())
    elif path.begins_with("res://"):
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir))
    elif base_dir.is_absolute_path():
        DirAccess.make_dir_recursive_absolute(base_dir)
    else:
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir))

