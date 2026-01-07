extends SceneTree

const ScenarioLoader = preload("res://tools/scenario_harness/scenario_loader.gd")
const ScenarioRunner = preload("res://tools/scenario_harness/scenario_runner.gd")
const ScenarioReport = preload("res://tools/scenario_harness/scenario_report.gd")
const ScenarioTypes = preload("res://tools/scenario_harness/scenario_types.gd")

func _initialize() -> void:
    Engine.set("print_to_stdout", true)
    Engine.set("print_error_messages", true)
    ProjectSettings.set_setting("application/run/disable_stdout", false)
    ProjectSettings.set_setting("application/run/disable_stderr", false)
    ProjectSettings.set_setting("application/run/flush_stdout_on_print", true)
    ProjectSettings.set_setting("debug/settings/stdout/print", true)
    ProjectSettings.set_setting("debug/settings/stdout/verbose", false)

    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.is_empty():
        args = OS.get_cmdline_args()
    var options: Dictionary = parse_args(args)
    if not bool(options.get("ok", false)):
        printerr(str(options.get("error", "Invalid arguments")))
        print("[scenarios] ERROR bad_args")
        quit(2)
        return
    if bool(options.get("help", false)):
        _print_help()
        quit(0)
        return

    var load_result: Dictionary = ScenarioLoader.load_scenarios()
    if not bool(load_result.get("ok", false)):
        printerr(str(load_result.get("error", "Failed to load scenarios")))
        for err in load_result.get("errors", []):
            printerr(str(err))
        print("[scenarios] ERROR load_failed")
        quit(2)
        return

    var data: Dictionary = load_result.get("data", {})
    var scenarios: Array = data.get("scenarios", [])
    var tag_filters: Array[String] = []
    for tag in options.get("tags", []):
        tag_filters.append(str(tag).to_lower())
    var exclude_filters: Array[String] = []
    for tag in options.get("exclude_tags", []):
        exclude_filters.append(str(tag).to_lower())
    var filtered: Array = ScenarioTypes.filter_scenarios(
        scenarios,
        tag_filters,
        exclude_filters,
        str(options.get("priority", ""))
    )
    if bool(options.get("list", false)):
        for scenario in filtered:
            print(str(scenario.get("id", "unknown")))
        quit(0)
        return

    var selected: Array = []
    var scenario_id: String = str(options.get("scenario_id", ""))
    if scenario_id != "":
        var found: bool = false
        for scenario in scenarios:
            if str(scenario.get("id", "")) == scenario_id:
                selected.append(scenario)
                found = true
                break
        if not found:
            printerr("Scenario not found: %s" % scenario_id)
            print("[scenarios] ERROR missing_scenario")
            quit(2)
            return
    else:
        selected = filtered
    if selected.is_empty():
        printerr("No scenarios matched filters.")
        print("[scenarios] ERROR empty_selection")
        quit(2)
        return

    var results: Array = []
    for scenario in selected:
        results.append(ScenarioRunner.run(scenario, {"enforce_targets": options.get("enforce_targets", false)}))

    var meta: Dictionary = _build_meta(options, selected)
    var report: Dictionary = ScenarioReport.build_report(results, meta)
    var write_result: Dictionary = ScenarioReport.write_report(
        report,
        str(options.get("out_path", "")),
        str(options.get("out_dir", ""))
    )
    if not bool(write_result.get("ok", false)):
        printerr(str(write_result.get("error", "Failed to write report")))
        print("[scenarios] ERROR write_failed")
        quit(2)
        return
    report = write_result.get("report", report)

    var summary: Dictionary = report.get("summary", {})
    var failed_ids: Array = summary.get("failed_ids", [])
    var report_path: String = str(report.get("report_path", ""))
    var target_eval: bool = bool(options.get("targets", false)) or bool(options.get("enforce_targets", false))
    var print_metrics: bool = bool(options.get("print_metrics", false))
    var summary_lines: Array[String] = []
    if report_path != "":
        print("[scenarios] report %s" % report_path)
        summary_lines.append("[scenarios] report %s" % report_path)
    var target_total: int = int(summary.get("target_total_count", 0))
    var target_met: int = int(summary.get("target_met_count", 0))
    if target_eval and target_total > 0:
        print("[targets] MET %d/%d" % [target_met, target_total])
        summary_lines.append("[targets] MET %d/%d" % [target_met, target_total])
    if print_metrics:
        for result in results:
            var line: String = _format_metrics_line(result)
            if line != "":
                print(line)
                summary_lines.append(line)
    if failed_ids.is_empty():
        print("[scenarios] OK %d" % int(summary.get("total", 0)))
        summary_lines.append("[scenarios] OK %d" % int(summary.get("total", 0)))
        ScenarioReport.write_last_summary(summary_lines, str(options.get("out_dir", "")))
        quit(0)
        return

    print("[scenarios] FAIL %s" % ", ".join(failed_ids))
    summary_lines.append("[scenarios] FAIL %s" % ", ".join(failed_ids))
    ScenarioReport.write_last_summary(summary_lines, str(options.get("out_dir", "")))
    quit(1)

static func parse_args(args: PackedStringArray) -> Dictionary:
    var options := {
        "ok": true,
        "help": false,
        "list": false,
        "scenario_id": "",
        "out_path": "",
        "out_dir": "",
        "tags": [],
        "exclude_tags": [],
        "priority": "",
        "enforce_targets": false,
        "targets": false,
        "print_metrics": false
    }
    var engine_args: Array[String] = ["--path", "--script", "--headless", "--log-file"]
    var i: int = 0
    while i < args.size():
        var arg: String = str(args[i])
        match arg:
            "--", "--headless", "--all":
                pass  # Skip: "--" is separator, "--headless" is engine flag, "--all" is default behavior
            "--path", "--script", "--log-file":
                if i + 1 < args.size():
                    i += 1  # Skip engine args that take a value
            "--help", "-h":
                options.help = true
            "--list":
                options.list = true
            "--scenario":
                if i + 1 >= args.size():
                    return {"ok": false, "error": "--scenario requires an id"}
                i += 1
                options.scenario_id = str(args[i])
            "--tag":
                if i + 1 >= args.size():
                    return {"ok": false, "error": "--tag requires a value"}
                i += 1
                options.tags.append(str(args[i]).to_lower())
            "--exclude-tag":
                if i + 1 >= args.size():
                    return {"ok": false, "error": "--exclude-tag requires a value"}
                i += 1
                options.exclude_tags.append(str(args[i]).to_lower())
            "--priority":
                if i + 1 >= args.size():
                    return {"ok": false, "error": "--priority requires a value"}
                i += 1
                options.priority = str(args[i]).to_upper()
            "--out":
                if i + 1 >= args.size():
                    return {"ok": false, "error": "--out requires a path"}
                i += 1
                options.out_path = str(args[i])
            "--out-dir":
                if i + 1 >= args.size():
                    return {"ok": false, "error": "--out-dir requires a path"}
                i += 1
                options.out_dir = str(args[i])
            "--enforce-targets":
                options.enforce_targets = true
            "--targets":
                options.targets = true
            "--print-metrics":
                options.print_metrics = true
            _:
                if arg.begins_with("--"):
                    return {"ok": false, "error": "Unknown argument: %s" % arg}
        i += 1
    return options

func _print_help() -> void:
    print("Scenario harness options:")
    print("  --list                 List scenario ids")
    print("  --all                  Run all scenarios (default)")
    print("  --scenario <id>        Run a single scenario")
    print("  --tag <tag>            Filter by tag (repeatable)")
    print("  --exclude-tag <tag>    Exclude scenarios with a tag (repeatable)")
    print("  --priority <P0|P1>      Filter by priority")
    print("  --out <path>           Write report JSON to path")
    print("  --out-dir <path>       Write report + summary to directory")
    print("  --enforce-targets      Treat target expectations as failures")
    print("  --targets              Evaluate targets and print target summary")
    print("  --print-metrics        Print compact per-scenario metrics")

func _build_meta(options: Dictionary, selected: Array) -> Dictionary:
    var info: Dictionary = Engine.get_version_info()
    var ids: Array[String] = []
    for scenario in selected:
        ids.append(str(scenario.get("id", "unknown")))
    return {
        "timestamp": Time.get_datetime_string_from_system(),
        "engine_version": "%s.%s.%s" % [str(info.get("major", "")), str(info.get("minor", "")), str(info.get("patch", ""))],
        "scenario_ids": ids,
        "out_path": str(options.get("out_path", "")),
        "out_dir": str(options.get("out_dir", "")),
        "filters": {
            "tags": options.get("tags", []),
            "exclude_tags": options.get("exclude_tags", []),
            "priority": str(options.get("priority", ""))
        }
    }

func _format_metrics_line(result: Dictionary) -> String:
    if typeof(result) != TYPE_DICTIONARY:
        return ""
    var metrics: Dictionary = result.get("metrics", {})
    if metrics.is_empty():
        return ""
    var parts: Array[String] = []
    parts.append("id=%s" % str(result.get("id", "unknown")))
    parts.append("day=%d" % int(metrics.get("day", 0)))
    parts.append("phase=%s" % str(metrics.get("phase", "")))
    parts.append("buildings=%d" % int(metrics.get("buildings_count", 0)))
    parts.append("explored=%d" % int(metrics.get("explored_count", 0)))
    parts.append("res.wood=%d" % int(metrics.get("resources_wood", 0)))
    parts.append("res.stone=%d" % int(metrics.get("resources_stone", 0)))
    parts.append("res.food=%d" % int(metrics.get("resources_food", 0)))
    if metrics.has("typing_accuracy"):
        parts.append("typing.acc=%.2f" % float(metrics.get("typing_accuracy", 0.0)))
    return " ".join(parts)

