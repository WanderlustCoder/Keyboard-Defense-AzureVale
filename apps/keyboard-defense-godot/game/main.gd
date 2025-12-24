extends Node2D

const DefaultState = preload("res://sim/default_state.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const GameState = preload("res://sim/types.gd")
const SimIntents = preload("res://sim/intents.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimTypingFeedback = preload("res://sim/typing_feedback.gd")
const SimTypingStats = preload("res://sim/typing_stats.gd")
const SimTypingTrends = preload("res://sim/typing_trends.gd")
const PracticeGoals = preload("res://sim/practice_goals.gd")
const GamePersistence = preload("res://game/persistence.gd")
const TypingProfile = preload("res://game/typing_profile.gd")
const GoalTheme = preload("res://game/goal_theme.gd")

@onready var stats_label: Label = $CanvasLayer/UIRoot/StatsPanel/StatsLabel
@onready var goal_badge: RichTextLabel = $CanvasLayer/UIRoot/StatsPanel/GoalBadge
@onready var goal_legend: RichTextLabel = $CanvasLayer/UIRoot/StatsPanel/GoalLegend
@onready var prompt_panel: Panel = $CanvasLayer/UIRoot/PromptPanel
@onready var prompt_label: Label = $CanvasLayer/UIRoot/PromptPanel/PromptLabel
@onready var log_label: RichTextLabel = $CanvasLayer/UIRoot/LogPanel/LogLabel
@onready var command_bar: LineEdit = $CanvasLayer/UIRoot/CommandBar
@onready var inspect_label: RichTextLabel = $CanvasLayer/UIRoot/InspectPanel/InspectLabel
@onready var legend_label: Label = $CanvasLayer/UIRoot/LegendPanel/LegendLabel  
@onready var wave_panel: Panel = $CanvasLayer/UIRoot/WavePanel
@onready var wave_label: RichTextLabel = $CanvasLayer/UIRoot/WavePanel/WaveLabel
@onready var typing_panel: Panel = $CanvasLayer/UIRoot/TypingFeedbackPanel      
@onready var typing_label: RichTextLabel = $CanvasLayer/UIRoot/TypingFeedbackPanel/TypingFeedbackLabel
@onready var report_panel: Panel = $CanvasLayer/UIRoot/TypingReportPanel        
@onready var report_label: RichTextLabel = $CanvasLayer/UIRoot/TypingReportPanel/TypingReportText
@onready var settings_panel: Panel = $CanvasLayer/UIRoot/SettingsPanel
@onready var settings_label: RichTextLabel = $CanvasLayer/UIRoot/SettingsPanel/SettingsLabel
@onready var history_panel: Panel = $CanvasLayer/UIRoot/HistoryPanel
@onready var history_label: RichTextLabel = $CanvasLayer/UIRoot/HistoryPanel/HistoryLabel
@onready var trend_panel: Panel = $CanvasLayer/UIRoot/TrendPanel
@onready var trend_label: RichTextLabel = $CanvasLayer/UIRoot/TrendPanel/TrendLabel
@onready var grid_renderer: Node2D = $GridRenderer

var state: GameState
var preview_type: String = ""
var overlay_path_enabled: bool = false
var typing_candidates: Dictionary = {}
var typing_candidate_ids: Array = []
var typing_focus_id: int = -1
var typing_stats: SimTypingStats
var last_input_text: String = ""
var last_report_text: String = ""
var last_report: Dictionary = {}
var report_visible: bool = false
var history_visible: bool = false
var trend_visible: bool = false
var settings_visible: bool = false
var awaiting_cycle_goal_bind: bool = false
var profile: Dictionary = {}
var typing_history: Array = []
var lifetime: Dictionary = {}
var current_goal: String = "balanced"
var cycle_goal_keybind: Dictionary = {}

func _ready() -> void:
	state = DefaultState.create()
	typing_stats = SimTypingStats.new()
	if command_bar.has_signal("command_submitted"):
		command_bar.command_submitted.connect(_on_command_submitted)
	if command_bar.has_signal("input_changed"):
		command_bar.input_changed.connect(_on_input_changed)
	if wave_label != null:
		wave_label.bbcode_enabled = true
	if typing_label != null:
		typing_label.bbcode_enabled = true
	if goal_badge != null:
		goal_badge.bbcode_enabled = true
	if goal_legend != null:
		goal_legend.bbcode_enabled = true
	if report_label != null:
		report_label.bbcode_enabled = true
	if report_panel != null:
		report_panel.visible = false
	if settings_label != null:
		settings_label.bbcode_enabled = true
	if settings_panel != null:
		settings_panel.visible = false
	if history_label != null:
		history_label.bbcode_enabled = false
	if history_panel != null:
		history_panel.visible = false
	if trend_label != null:
		trend_label.bbcode_enabled = true
	if trend_panel != null:
		trend_panel.visible = false
	_load_profile()
	_append_log(["Type 'help' to see commands."])
	_refresh_hud()
	command_bar.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if awaiting_cycle_goal_bind:
			_handle_cycle_goal_bind(event)
			return
		if event.is_action_pressed("cycle_goal"):
			_cycle_goal_hotkey()
			get_viewport().set_input_as_handled()

func _on_command_submitted(command: String) -> void:
	var is_night: bool = state.phase == "night"
	if is_night and typing_stats != null:
		typing_stats.on_enter_pressed()
	var trimmed: String = command.strip_edges()
	if trimmed.is_empty():
		if is_night and typing_stats != null:
			typing_stats.record_incomplete_enter("empty")
		_refresh_typing_feedback(command)
		return

	var parsed: Dictionary = CommandParser.parse(trimmed)
	if parsed.get("ok", false):
		var intent_kind: String = str(parsed.intent.get("kind", ""))
		if is_night and typing_stats != null:
			if intent_kind == "defend_input":
				typing_stats.record_command_enter(intent_kind, false)
				typing_stats.record_defend_attempt(command, state.enemies)
			else:
				typing_stats.record_command_enter(intent_kind, intent_kind == "wait")
		if intent_kind == "ui_preview":
			command_bar.accept_submission(trimmed)
			_apply_preview(parsed.intent)
			return
		if intent_kind == "ui_overlay":
			command_bar.accept_submission(trimmed)
			_apply_overlay(parsed.intent)
			return
		if intent_kind == "ui_report":
			command_bar.accept_submission(trimmed)
			_apply_report(parsed.intent)
			return
		if intent_kind == "ui_goal_show":
			command_bar.accept_submission(trimmed)
			_apply_goal_show()
			return
		if intent_kind == "ui_goal_set":
			command_bar.accept_submission(trimmed)
			_apply_goal_set(parsed.intent)
			return
		if intent_kind == "ui_goal_next":
			command_bar.accept_submission(trimmed)
			_apply_goal_next()
			return
		if intent_kind == "ui_settings_toggle":
			command_bar.accept_submission(trimmed)
			_apply_settings_toggle()
			return
		if intent_kind == "ui_bind_cycle_goal":
			command_bar.accept_submission(trimmed)
			_apply_bind_cycle_goal()
			return
		if intent_kind == "ui_bind_cycle_goal_reset":
			command_bar.accept_submission(trimmed)
			_apply_bind_cycle_goal_reset()
			return
		if intent_kind == "ui_history":
			command_bar.accept_submission(trimmed)
			_apply_history(parsed.intent)
			return
		if intent_kind == "ui_trend":
			command_bar.accept_submission(trimmed)
			_apply_trend(parsed.intent)
			return
		command_bar.accept_submission(trimmed)
		var result: Dictionary = IntentApplier.apply(state, parsed.intent)
		_apply_result(result)
		return

	if state.phase == "night":
		var route: Dictionary = SimTypingFeedback.route_night_input(false, "", command, state.enemies)
		var action: String = str(route.get("action", ""))
		if action == "incomplete":
			if typing_stats != null:
				typing_stats.record_incomplete_enter(str(route.get("reason", "incomplete")))
			_append_log(["Incomplete: keep typing."])
			_refresh_typing_feedback(command)
			command_bar.grab_focus()
			return
		if action == "defend":
			if typing_stats != null:
				typing_stats.record_defend_attempt(command, state.enemies)
			command_bar.accept_submission(trimmed)
			var defend_intent: Dictionary = {"kind": "defend_input", "text": command}
			var defend_result: Dictionary = IntentApplier.apply(state, defend_intent)
			_apply_result(defend_result)
			return

	_append_log(["Error: %s" % parsed.get("error", "Unknown error")])

func _apply_result(result: Dictionary) -> void:
	var prev_phase: String = state.phase
	state = result.state
	_append_log(result.events)
	if result.has("request"):
		var request_result: Dictionary = _handle_request(result.request)
		if request_result.has("state"):
			state = request_result.state
		if request_result.has("events"):
			_append_log(request_result.events)
	_refresh_hud()
	_handle_phase_change(prev_phase, state.phase)
	command_bar.grab_focus()

func _refresh_hud() -> void:
	stats_label.text = IntentApplier._format_status(state)
	_update_prompt()
	_update_command_hint()
	if grid_renderer.has_method("update_state"):
		grid_renderer.update_state(state)
	if grid_renderer.has_method("set_preview_type"):
		grid_renderer.set_preview_type(preview_type)
	if grid_renderer.has_method("set_path_overlay"):
		grid_renderer.set_path_overlay(overlay_path_enabled)
	_refresh_inspector()
	_refresh_legend()
	_refresh_typing_feedback(command_bar.text)
	_refresh_goal_badge()
	_refresh_goal_legend()
	_refresh_settings_panel()
	_refresh_report_panel()
	_refresh_history_panel()
	_refresh_trend_panel()

func _update_prompt() -> void:
	if state.phase == "night":
		prompt_panel.visible = true
		prompt_label.text = "DEFEND: type an enemy word"
	elif state.phase == "game_over":
		prompt_panel.visible = true
		prompt_label.text = "GAME OVER - type restart"
	else:
		prompt_panel.visible = false
		prompt_label.text = ""

func _update_command_hint() -> void:
	if state.phase == "night":
		command_bar.placeholder_text = "Type an enemy word to attack. Commands still work (status/map/inspect)"
	elif state.phase == "game_over":
		command_bar.placeholder_text = "Type restart to begin again"
	else:
		command_bar.placeholder_text = "Type a command (help/status/gather/build/explore/end/cursor/inspect/map/demolish/upgrade/preview/wait/overlay/enemies/report/history/trend)"

func _handle_phase_change(prev_phase: String, new_phase: String) -> void:
	if prev_phase != "night" and new_phase == "night":
		if typing_stats != null:
			typing_stats.start_night(state.day, state.night_wave_total, Time.get_ticks_msec())
		last_input_text = command_bar.text
		report_visible = false
		_refresh_report_panel()
		return
	if prev_phase == "night" and new_phase != "night":
		_show_typing_report()
		_clear_typing_feedback()
		return
	if new_phase == "game_over" and prev_phase != "night":
		_show_typing_report()

func _show_typing_report() -> void:
	if typing_stats == null:
		return
	var report_dict: Dictionary = typing_stats.to_report_dict()
	last_report_text = typing_stats.to_report_text()
	last_report = report_dict
	if last_report_text == "":
		return
	_append_log(["Typing Report:"])
	_append_log(last_report_text.split("\n"))
	_record_typing_report(report_dict)
	report_visible = true
	_refresh_report_panel()
	_refresh_goal_badge()

func _apply_report(intent: Dictionary) -> void:
	var mode: String = str(intent.get("mode", "toggle"))
	if mode == "show":
		report_visible = true
	elif mode == "hide":
		report_visible = false
	else:
		report_visible = not report_visible
	if report_visible and last_report_text == "":
		last_report_text = "No report available yet."
	_refresh_report_panel()
	command_bar.grab_focus()

func _apply_settings_toggle() -> void:
	settings_visible = not settings_visible
	if not settings_visible and awaiting_cycle_goal_bind:
		awaiting_cycle_goal_bind = false
		_append_log(["Keybind canceled."])
	_refresh_settings_panel()
	command_bar.grab_focus()

func _apply_bind_cycle_goal() -> void:
	settings_visible = true
	awaiting_cycle_goal_bind = true
	_append_log(["Press a key for cycle_goal (Esc to cancel)."])
	_refresh_settings_panel()
	command_bar.grab_focus()

func _apply_bind_cycle_goal_reset() -> void:
	awaiting_cycle_goal_bind = false
	_set_cycle_goal_keybind(TypingProfile.default_keybinds().get("cycle_goal", {}), "Cycle goal reset: %s")
	command_bar.grab_focus()

func _set_goal_and_refresh(goal_id: String, log_message: String) -> void:
	var result: Dictionary = TypingProfile.set_goal(profile, goal_id)
	profile = result.get("profile", profile)
	current_goal = TypingProfile.get_goal(profile)
	if not result.get("ok", true):
		_append_log(["Goal update failed: %s" % str(result.get("error", "unknown error"))])
	_append_log([log_message % PracticeGoals.goal_label(current_goal)])
	_refresh_trend_panel()
	_refresh_history_panel()
	_refresh_report_panel()
	_refresh_goal_badge()
	_refresh_goal_legend()

func _cycle_goal_hotkey() -> void:
	var goals: PackedStringArray = PracticeGoals.all_goal_ids()
	if goals.is_empty():
		return
	var current_index: int = goals.find(current_goal)
	var next_index: int = 0
	if current_index >= 0:
		next_index = (current_index + 1) % goals.size()
	var next_goal: String = goals[next_index]
	_set_goal_and_refresh(next_goal, "Goal cycled: %s")
	command_bar.grab_focus()

func _handle_cycle_goal_bind(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		awaiting_cycle_goal_bind = false
		_append_log(["Keybind canceled."])
		_refresh_settings_panel()
		get_viewport().set_input_as_handled()
		command_bar.grab_focus()
		return
	if _is_modifier_key(event.keycode):
		return
	var keybind: Dictionary = _keybind_from_event(event)
	awaiting_cycle_goal_bind = false
	_set_cycle_goal_keybind(keybind, "Cycle goal bound: %s")
	get_viewport().set_input_as_handled()
	command_bar.grab_focus()

func _set_cycle_goal_keybind(keybind: Dictionary, log_message: String) -> void:
	var result: Dictionary = TypingProfile.set_keybind(profile, "cycle_goal", keybind)
	profile = result.get("profile", profile)
	cycle_goal_keybind = TypingProfile.get_keybind(profile, "cycle_goal")
	_apply_keybind("cycle_goal", cycle_goal_keybind)
	if not result.get("ok", true):
		_append_log(["Keybind update failed: %s" % str(result.get("error", "unknown error"))])
	_append_log([log_message % _format_keybind_text(cycle_goal_keybind)])
	_refresh_settings_panel()
	_refresh_goal_legend()

func _latest_report_for_badge() -> Dictionary:
	if not last_report.is_empty():
		return last_report
	if typing_history.is_empty():
		return {}
	var entry = typing_history[typing_history.size() - 1]
	if typeof(entry) == TYPE_DICTIONARY:
		return entry
	return {}

func _refresh_goal_badge() -> void:
	if goal_badge == null:
		return
	var goal_label: String = PracticeGoals.goal_label(current_goal)
	var goal_hex: String = GoalTheme.hex_for_goal(current_goal)
	var report_source: Dictionary = _latest_report_for_badge()
	var goal_line: String = "GOAL: [color=%s][b]%s[/b][/color]" % [goal_hex, goal_label]
	if report_source.is_empty():
		goal_badge.text = "%s\nStatus: -- (play a night)" % goal_line
		return
	var thresholds: Dictionary = PracticeGoals.thresholds(current_goal)
	var passed: bool = SimTypingTrends.report_meets_goal(report_source, thresholds)
	var status_word: String = "PASS" if passed else "NOT YET"
	var status_hex: String = GoalTheme.hex_for_pass(passed)
	var status_line: String = "Status: [color=%s]%s[/color]" % [status_hex, status_word]
	goal_badge.text = "%s\n%s" % [goal_line, status_line]

func _refresh_goal_legend() -> void:
	if goal_legend == null:
		return
	var goals: PackedStringArray = PracticeGoals.all_goal_ids()
	var parts: Array[String] = []
	for goal_id in goals:
		var label: String = PracticeGoals.goal_label(goal_id)
		var hex: String = GoalTheme.hex_for_goal(goal_id)
		var entry: String = "[color=%s]%s[/color]" % [hex, label]
		if goal_id == current_goal:
			entry = "[b][color=%s][%s][/color][/b]" % [hex, label]
		parts.append(entry)
	var line_one: String = "Goals: %s" % " ".join(parts)
	var binding_text: String = _format_keybind_text(cycle_goal_keybind)
	var line_two: String = "%s: cycle goals | goal <id>" % binding_text
	goal_legend.text = "%s\n%s" % [line_one, line_two]

func _refresh_settings_panel() -> void:
	if settings_panel == null or settings_label == null:
		return
	settings_panel.visible = settings_visible
	if not settings_visible:
		settings_label.text = ""
		return
	var lines: Array[String] = []
	lines.append("[b]Settings[/b]")
	lines.append("Cycle goal: %s" % _format_keybind_text(cycle_goal_keybind))
	if awaiting_cycle_goal_bind:
		lines.append("Press a key to bind cycle_goal.")
		lines.append("Esc cancels.")
	else:
		lines.append("Type: bind cycle_goal")
		lines.append("Type: bind cycle_goal reset")
	settings_label.text = "\n".join(lines)

func _apply_keybind(action_name: String, keybind: Dictionary) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)
	var keycode: int = int(keybind.get("keycode", 0))
	if keycode <= 0:
		return
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.shift_pressed = bool(keybind.get("shift", false))
	event.alt_pressed = bool(keybind.get("alt", false))
	event.ctrl_pressed = bool(keybind.get("ctrl", false))
	event.meta_pressed = bool(keybind.get("meta", false))
	InputMap.action_add_event(action_name, event)

func _keybind_from_event(event: InputEventKey) -> Dictionary:
	return {
		"keycode": event.keycode,
		"shift": event.shift_pressed,
		"alt": event.alt_pressed,
		"ctrl": event.ctrl_pressed,
		"meta": event.meta_pressed
	}

func _format_keybind_text(keybind: Dictionary) -> String:
	var keycode: int = int(keybind.get("keycode", 0))
	if keycode <= 0:
		return "Unbound"
	var parts: Array[String] = []
	if bool(keybind.get("ctrl", false)):
		parts.append("Ctrl")
	if bool(keybind.get("alt", false)):
		parts.append("Alt")
	if bool(keybind.get("shift", false)):
		parts.append("Shift")
	if bool(keybind.get("meta", false)):
		parts.append("Meta")
	var key_text: String = OS.get_keycode_string(keycode)
	if key_text == "":
		key_text = str(keycode)
	parts.append(key_text)
	return "+".join(parts)

func _is_modifier_key(keycode: int) -> bool:
	return keycode == KEY_SHIFT or keycode == KEY_CTRL or keycode == KEY_ALT or keycode == KEY_META

func _refresh_report_panel() -> void:
	if report_panel == null or report_label == null:
		return
	report_panel.visible = report_visible
	var goal_label: String = PracticeGoals.goal_label(current_goal)
	var thresholds: Dictionary = PracticeGoals.thresholds(current_goal)
	var goal_status: String = "--"
	var passed: bool = false
	if not last_report.is_empty():
		passed = SimTypingTrends.report_meets_goal(last_report, thresholds)
		goal_status = "PASS" if passed else "NOT YET"
	var goal_hex: String = GoalTheme.hex_for_goal(current_goal)
	var status_text: String = goal_status
	if goal_status != "--":
		status_text = "[color=%s]%s[/color]" % [GoalTheme.hex_for_pass(passed), goal_status]
	var header: String = "[color=%s][b]Goal: %s[/b][/color] (%s)" % [goal_hex, goal_label, status_text]
	if last_report_text == "":
		report_label.text = "%s\nNo report available yet." % header
	else:
		report_label.text = "%s\n%s" % [header, last_report_text]

func _apply_goal_show() -> void:
	var goal_list: PackedStringArray = PracticeGoals.all_goal_ids()
	_append_log([
		"Current goal: %s" % PracticeGoals.goal_label(current_goal),
		"Goals: %s" % ", ".join(Array(goal_list)),
		"Use: goal <id> or goal next"
	])
	trend_visible = true
	_refresh_trend_panel()

func _apply_goal_set(intent: Dictionary) -> void:
	var raw_goal: String = str(intent.get("goal_id", ""))
	var normalized: String = PracticeGoals.normalize_goal(raw_goal)
	var raw_normalized: String = raw_goal.strip_edges().to_lower()
	if raw_goal != "" and not PracticeGoals.is_valid(raw_normalized):
		_append_log(["Unknown goal '%s'; using Balanced." % raw_goal])
	_set_goal_and_refresh(normalized, "Goal set to: %s")

func _apply_goal_next() -> void:
	var goals: PackedStringArray = PracticeGoals.all_goal_ids()
	var current_index: int = goals.find(current_goal)
	var next_index: int = 0
	if current_index >= 0:
		next_index = (current_index + 1) % goals.size()
	var next_goal: String = goals[next_index]
	_set_goal_and_refresh(next_goal, "Goal set to: %s")

func _apply_history(intent: Dictionary) -> void:
	var mode: String = str(intent.get("mode", "toggle"))
	if mode == "clear":
		typing_history.clear()
		history_visible = false
		_persist_profile()
		_append_log(["Typing history cleared."])
	elif mode == "show":
		history_visible = true
	elif mode == "hide":
		history_visible = false
	else:
		history_visible = not history_visible
	_refresh_history_panel()
	command_bar.grab_focus()

func _apply_trend(intent: Dictionary) -> void:
	var mode: String = str(intent.get("mode", "toggle"))
	if mode == "show":
		trend_visible = true
	elif mode == "hide":
		trend_visible = false
	else:
		trend_visible = not trend_visible
	_refresh_trend_panel()
	command_bar.grab_focus()

func _load_profile() -> void:
	var result: Dictionary = TypingProfile.load_profile()
	if result.get("ok", false):
		profile = result.get("profile", {})
	else:
		profile = TypingProfile.default_profile()
		_append_log(["Profile load failed: %s" % str(result.get("error", "unknown error"))])
	typing_history = profile.get("typing_history", [])
	lifetime = profile.get("lifetime", _default_lifetime())
	current_goal = TypingProfile.get_goal(profile)
	profile["practice_goal"] = current_goal
	cycle_goal_keybind = TypingProfile.get_keybind(profile, "cycle_goal")
	_apply_keybind("cycle_goal", cycle_goal_keybind)
	_refresh_history_panel()
	_refresh_trend_panel()
	_refresh_goal_legend()
	_refresh_settings_panel()

func _persist_profile() -> void:
	profile["typing_history"] = typing_history
	profile["lifetime"] = lifetime
	profile["practice_goal"] = current_goal
	var result: Dictionary = TypingProfile.save_profile(profile)
	if not result.get("ok", false):
		_append_log(["Profile save failed: %s" % str(result.get("error", "unknown error"))])

func _default_lifetime() -> Dictionary:
	return {
		"nights": 0,
		"defend_attempts": 0,
		"hits": 0,
		"misses": 0
	}

func _record_typing_report(report: Dictionary) -> void:
	typing_history.append(report.duplicate(true))
	while typing_history.size() > 5:
		typing_history.pop_front()
	lifetime["nights"] = int(lifetime.get("nights", 0)) + 1
	lifetime["defend_attempts"] = int(lifetime.get("defend_attempts", 0)) + int(report.get("defend_attempts", 0))
	lifetime["hits"] = int(lifetime.get("hits", 0)) + int(report.get("hits", 0))
	lifetime["misses"] = int(lifetime.get("misses", 0)) + int(report.get("misses", 0))
	_persist_profile()
	_refresh_history_panel()
	_refresh_trend_panel()

func _refresh_history_panel() -> void:
	if history_panel == null or history_label == null:
		return
	history_panel.visible = history_visible
	if not history_visible:
		history_label.text = ""
		return
	if typing_history.is_empty():
		history_label.text = "Typing History\n(no reports yet)"
		return
	var lines: Array[String] = []
	lines.append("Typing History (last %d)" % typing_history.size())
	var thresholds: Dictionary = PracticeGoals.thresholds(current_goal)
	var start: int = max(0, typing_history.size() - 5)
	for i in range(typing_history.size() - 1, start - 1, -1):
		var entry: Dictionary = typing_history[i]
		lines.append(_format_history_entry(entry, thresholds))
	history_label.text = "\n".join(lines)

func _format_history_entry(entry: Dictionary, thresholds: Dictionary) -> String:
	var day: int = int(entry.get("night_day", 0))
	var accuracy: float = float(entry.get("avg_accuracy", 0.0)) * 100.0
	var hit_rate: float = float(entry.get("hit_rate", 0.0)) * 100.0
	var backspace: float = float(entry.get("backspace_rate", 0.0)) * 100.0
	var attempts: int = int(entry.get("defend_attempts", 0))
	var pass_text: String = "PASS" if SimTypingTrends.report_meets_goal(entry, thresholds) else "--"
	return "Day %d | %s | acc %.0f%% | hit %.0f%% | backspace %.0f%% | attempts %d" % [
		day,
		pass_text,
		accuracy,
		hit_rate,
		backspace,
		attempts
	]

func _refresh_trend_panel() -> void:
	if trend_panel == null or trend_label == null:
		return
	trend_panel.visible = trend_visible
	if not trend_visible:
		trend_label.text = ""
		return
	var summary: Dictionary = SimTypingTrends.summarize(typing_history, current_goal)
	var lines: Array[String] = []
	var goal_label: String = str(summary.get("goal_label", "Goal"))
	var goal_desc: String = str(summary.get("goal_description", ""))
	var thresholds: Dictionary = summary.get("thresholds", {})
	var goal_hex: String = GoalTheme.hex_for_goal(current_goal)
	var has_history: bool = int(summary.get("count", 0)) > 0
	var passed: bool = bool(summary.get("goal_met", false))
	var goal_status: String = "PASS" if passed else "NOT YET"
	if not has_history:
		goal_status = "--"
	var status_text: String = goal_status
	if goal_status != "--":
		status_text = "[color=%s]%s[/color]" % [GoalTheme.hex_for_pass(passed), goal_status]
	lines.append("Goal: [color=%s][b]%s[/b][/color] (%s)" % [goal_hex, goal_label, status_text])
	if goal_desc != "":
		lines.append(goal_desc)
	lines.append("Targets: hit>=%.2f acc>=%.2f back<=%.2f inc<=%.2f" % [
		float(thresholds.get("min_hit_rate", 0.0)),
		float(thresholds.get("min_accuracy", 0.0)),
		float(thresholds.get("max_backspace_rate", 1.0)),
		float(thresholds.get("max_incomplete_rate", 1.0))
	])
	lines.append("")
	lines.append(SimTypingTrends.format_trend_text(summary))
	var suggestions: Array = summary.get("suggestions", [])
	if not suggestions.is_empty():
		lines.append("")
		lines.append("Coach:")
		for suggestion in suggestions:
			lines.append("- %s" % str(suggestion))
	trend_label.text = "\n".join(lines)

func _on_input_changed(text: String) -> void:
	if state.phase == "night":
		if typing_stats != null:
			typing_stats.on_text_changed(last_input_text, text)
		last_input_text = text
		_refresh_typing_feedback(text)
	else:
		last_input_text = text
		_clear_typing_feedback()

func _refresh_typing_feedback(text: String) -> void:
	if state.phase != "night":
		_clear_typing_feedback()
		return
	typing_candidates = SimTypingFeedback.enemy_candidates(state.enemies, text)
	typing_candidate_ids = typing_candidates.get("candidate_ids", [])
	typing_focus_id = _select_focus_enemy(typing_candidate_ids)
	_update_typing_label()
	_refresh_wave_panel()
	if grid_renderer.has_method("set_enemy_highlights"):
		grid_renderer.set_enemy_highlights(typing_candidate_ids, typing_focus_id)

func _clear_typing_feedback() -> void:
	typing_candidates = {}
	typing_candidate_ids = []
	typing_focus_id = -1
	if typing_panel != null:
		typing_panel.visible = false
	if typing_label != null:
		typing_label.text = ""
	_refresh_wave_panel()
	if grid_renderer.has_method("set_enemy_highlights"):
		grid_renderer.set_enemy_highlights([], -1)

func _update_typing_label() -> void:
	if typing_label == null or typing_panel == null:
		return
	if state.phase != "night":
		typing_panel.visible = false
		typing_label.text = ""
		return
	typing_panel.visible = true
	var typed: String = str(typing_candidates.get("typed", ""))
	var exact_id: int = int(typing_candidates.get("exact_id", -1))
	var candidate_ids: Array = typing_candidates.get("candidate_ids", [])
	var expected: Array = typing_candidates.get("expected_next_chars", [])
	var suggestions: Array = typing_candidates.get("suggestions", [])
	var lines: Array[String] = []
	if typed == "":
		lines.append("Type an enemy word to attack.")
	elif exact_id != -1:
		var exact_word: String = _enemy_word(exact_id, typed)
		lines.append("READY: %s  Press Enter" % exact_word)
	elif candidate_ids.size() > 0:
		lines.append("Targeting: %d candidate(s)." % candidate_ids.size())
		var expected_text: String = _format_expected_chars(expected)
		if expected_text != "":
			lines.append("Next expected: %s" % expected_text)
		if candidate_ids.size() == 1:
			var focus_text: String = _enemy_brief(int(candidate_ids[0]))
			if focus_text != "":
				lines.append("Focus: %s" % focus_text)
	else:
		lines.append("No enemy word starts with '%s'. Backspace to correct." % typed)
		var suggestion_text: String = _format_suggestions(suggestions)
		if suggestion_text != "":
			lines.append("Closest: %s" % suggestion_text)
		var expected_text: String = _format_expected_chars(expected)
		if expected_text != "":
			lines.append("Expected next: %s" % expected_text)
	typing_label.text = "\n".join(lines)

func _format_expected_chars(chars: Array) -> String:
	if chars.is_empty():
		return ""
	var parts: Array[String] = []
	for char in chars:
		var text: String = str(char)
		if text != "":
			parts.append(text)
	if parts.is_empty():
		return ""
	return ", ".join(parts)

func _format_suggestions(suggestions: Array) -> String:
	if suggestions.is_empty():
		return ""
	var parts: Array[String] = []
	for suggestion in suggestions:
		if typeof(suggestion) != TYPE_DICTIONARY:
			continue
		var word: String = str(suggestion.get("word", ""))
		if word != "":
			parts.append(word)
		if parts.size() >= 3:
			break
	if parts.is_empty():
		return ""
	return ", ".join(parts)

func _enemy_word(enemy_id: int, fallback: String) -> String:
	var enemy: Dictionary = _enemy_for_id(enemy_id)
	if enemy.is_empty():
		return fallback
	var word: String = str(enemy.get("word", ""))
	if word == "":
		return fallback
	return word

func _enemy_brief(enemy_id: int) -> String:
	var enemy: Dictionary = _enemy_for_id(enemy_id)
	if enemy.is_empty():
		return ""
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	return "#%d %s (%d,%d)" % [enemy_id, str(enemy.get("kind", "")), pos.x, pos.y]

func _enemy_for_id(enemy_id: int) -> Dictionary:
	for enemy in state.enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		if int(enemy.get("id", 0)) == enemy_id:
			return enemy
	return {}

func _select_focus_enemy(candidate_ids: Array) -> int:
	if candidate_ids.is_empty():
		return -1
	var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
	var best_id: int = -1
	var best_dist: int = 999999
	for enemy in state.enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var enemy_id: int = int(enemy.get("id", 0))
		if not candidate_ids.has(enemy_id):
			continue
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		var dist: int = SimEnemies.dist_at(dist_field, pos, state.map_w)
		var sort_dist: int = dist if dist >= 0 else 999999
		if best_id == -1 or sort_dist < best_dist or (sort_dist == best_dist and enemy_id < best_id):
			best_id = enemy_id
			best_dist = sort_dist
	return best_id

func _append_log(lines: Array) -> void:
	for line in lines:
		if str(line).is_empty():
			continue
		log_label.append_text("%s\n" % str(line))

func _handle_request(request: Dictionary) -> Dictionary:
	var kind: String = str(request.get("kind", ""))
	match kind:
		"save":
			var save_result: Dictionary = GamePersistence.save_state(state)
			if save_result.get("ok", false):
				return {"events": ["Saved to %s." % save_result.get("path", GamePersistence.SAVE_PATH)]}
			return {"events": ["Save failed: %s" % save_result.get("error", "unknown error")]}
		"load":
			var load_result: Dictionary = GamePersistence.load_state()
			if load_result.get("ok", false):
				return {"state": load_result.state, "events": ["Loaded savegame."]}
			return {"events": ["Load failed: %s" % load_result.get("error", "unknown error")]}
		"autosave":
			var auto_result: Dictionary = GamePersistence.save_state(state)
			if auto_result.get("ok", false):
				return {"events": []}
			return {"events": ["Warning: autosave failed (%s)." % auto_result.get("error", "unknown error")]}
	return {"events": []}

func _is_known_command(verb: String) -> bool:
	return SimIntents.COMMANDS.has(verb)

func _apply_preview(intent: Dictionary) -> void:
	preview_type = str(intent.get("building", ""))
	if preview_type == "none":
		preview_type = ""
	if preview_type.is_empty():
		_append_log(["Preview cleared."])
	else:
		_append_log(["Preview: %s" % preview_type])
	if grid_renderer.has_method("set_preview_type"):
		grid_renderer.set_preview_type(preview_type)
	_refresh_inspector()
	command_bar.grab_focus()

func _apply_overlay(intent: Dictionary) -> void:
	if str(intent.get("name", "")) != "path":
		_append_log(["Unknown overlay request."])
		return
	overlay_path_enabled = bool(intent.get("enabled", false))
	var state_text: String = "ON" if overlay_path_enabled else "OFF"
	_append_log(["Path overlay: %s" % state_text])
	if grid_renderer.has_method("set_path_overlay"):
		grid_renderer.set_path_overlay(overlay_path_enabled)
	_refresh_legend()
	command_bar.grab_focus()

func _refresh_inspector() -> void:
	if inspect_label == null:
		return
	var pos: Vector2i = state.cursor_pos
	var report: Dictionary = SimBuildings.get_tile_report(state, pos)
	var lines: Array[String] = []
	lines.append("Cursor: (%d,%d) | Phase: %s" % [pos.x, pos.y, state.phase])
	var discovered: bool = bool(report.get("discovered", false))
	var terrain: String = str(report.get("terrain", ""))
	var structure: String = str(report.get("structure", ""))
	lines.append("Discovered: %s" % ("yes" if discovered else "no"))
	lines.append("Terrain: %s" % (terrain if terrain != "" else "unknown"))
	lines.append("Structure: %s" % (structure if structure != "" else "none"))
	if bool(report.get("is_base", false)):
		lines.append("Tile: base")
	var adjacency: Dictionary = report.get("adjacency", {})
	lines.append("Adjacency: water %d | forest %d | mountain %d | wall %d" % [
		int(adjacency.get("water", 0)),
		int(adjacency.get("forest", 0)),
		int(adjacency.get("mountain", 0)),
		int(adjacency.get("wall", 0))
	])
	var structure_level: int = int(report.get("structure_level", 0))
	if structure == "tower":
		lines.append("Tower level: %d" % structure_level)
		var tower_stats: Dictionary = report.get("tower_stats", {})
		lines.append("Tower stats: range %d dmg %d shots %d" % [
			int(tower_stats.get("range", 0)),
			int(tower_stats.get("damage", 0)),
			int(tower_stats.get("shots", 0))
		])
		var upgrade_preview: Dictionary = report.get("upgrade_preview", {})
		if bool(upgrade_preview.get("ok", false)):
			var next_level: int = int(upgrade_preview.get("next_level", structure_level + 1))
			var next_stats: Dictionary = upgrade_preview.get("stats", {})
			lines.append("Upgrade -> L%d: cost %s | range %d dmg %d shots %d" % [
				next_level,
				_format_resource_list(upgrade_preview.get("cost", {}), false),
				int(next_stats.get("range", 0)),
				int(next_stats.get("damage", 0)),
				int(next_stats.get("shots", 0))
			])
		else:
			lines.append("Upgrade: MAX LEVEL")

	lines.append("Build preview:")
	var previews: Dictionary = report.get("previews", {})
	var types: Array[String] = SimBuildings.list_types()
	if preview_type != "" and types.has(preview_type):
		types.erase(preview_type)
		types.insert(0, preview_type)
	for building_type in types:
		var preview: Dictionary = previews.get(building_type, {})
		lines.append(_format_preview_line(building_type, preview))

	inspect_label.text = "\n".join(lines)

func _refresh_legend() -> void:
	if legend_label == null:
		return
	var overlay_text: String = "PATH OVERLAY: %s" % ("ON" if overlay_path_enabled else "OFF")
	legend_label.text = "Legend: . plains f forest m mountain ~ water ? unknown | F/L/Q/W/T buildings (T1-3) | @ cursor | B base | r/s/a enemies | %s" % overlay_text

func _refresh_wave_panel() -> void:
	if wave_label == null or wave_panel == null:
		return
	if state.phase != "night":
		wave_panel.visible = false
		wave_label.text = ""
		return
	wave_panel.visible = true
	var lines: Array[String] = []
	lines.append("Wave: %d/%d" % [state.night_spawn_remaining, state.night_wave_total])
	var stats_line: String = _format_typing_stats_line()
	if stats_line != "":
		lines.append(stats_line)
	if state.enemies.is_empty():
		lines.append("Enemies: none")
	else:
		var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
		var typed: String = str(typing_candidates.get("typed", ""))
		var candidate_ids: Array = typing_candidates.get("candidate_ids", [])
		var exact_id: int = int(typing_candidates.get("exact_id", -1))
		var candidate_lookup: Dictionary = {}
		for enemy_id in candidate_ids:
			candidate_lookup[int(enemy_id)] = true
		var entries: Array = []
		for enemy in state.enemies:
			if typeof(enemy) != TYPE_DICTIONARY:
				continue
			var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
			var dist: int = SimEnemies.dist_at(dist_field, pos, state.map_w)
			var sort_dist: int = dist if dist >= 0 else 9999
			entries.append({
				"id": int(enemy.get("id", 0)),
				"kind": str(enemy.get("kind", "raider")),
				"hp": int(enemy.get("hp", 0)),
				"pos": pos,
				"word": str(enemy.get("word", "")),
				"dist": sort_dist
			})
		entries.sort_custom(Callable(self, "_sort_wave_entry"))
		lines.append("Enemies:")
		for entry in entries:
			var entry_pos: Vector2i = entry.get("pos", Vector2i.ZERO)
			var entry_id: int = int(entry.get("id", 0))
			var is_candidate: bool = candidate_lookup.has(entry_id)
			var is_exact: bool = entry_id == exact_id
			var marker: String = "> " if entry_id == typing_focus_id else "  "
			var word_text: String = _format_wave_word(str(entry.get("word", "")), typed, is_candidate, is_exact)
			var ready_suffix: String = " [READY]" if is_exact else ""
			var bar_text: String = _format_progress_bar(str(entry.get("word", "")), typed, is_candidate, is_exact)
			lines.append("%s#%d %s hp %d (%d,%d) %s%s" % [
				marker,
				entry_id,
				str(entry.get("kind", "raider")),
				int(entry.get("hp", 0)),
				entry_pos.x,
				entry_pos.y,
				word_text,
				ready_suffix
			])
			lines.append("    %s" % bar_text)
	wave_label.text = "\n".join(lines)

func _sort_wave_entry(a: Dictionary, b: Dictionary) -> bool:
	var dist_a: int = int(a.get("dist", 9999))
	var dist_b: int = int(b.get("dist", 9999))
	if dist_a == dist_b:
		return int(a.get("id", 0)) < int(b.get("id", 0))
	return dist_a < dist_b

func _format_wave_word(word: String, typed: String, is_candidate: bool, is_exact: bool) -> String:
	if typed == "" or not is_candidate:
		return word
	var safe_word: String = word
	if typed.length() > safe_word.length():
		return safe_word
	var prefix: String = safe_word.substr(0, typed.length())
	var rest: String = safe_word.substr(typed.length())
	var highlight: String = "[color=#e6d978]%s[/color]" % prefix
	if is_exact:
		highlight = "[b]%s[/b]" % highlight
	return "%s%s" % [highlight, rest]

func _format_progress_bar(word: String, typed: String, is_candidate: bool, is_exact: bool) -> String:
	var normalized_word: String = SimTypingFeedback.normalize_input(word)
	var normalized_typed: String = SimTypingFeedback.normalize_input(typed)
	var word_len: int = normalized_word.length()
	var match_len: int = SimTypingFeedback.prefix_len(normalized_typed, normalized_word)
	var width: int = 10
	var fill: int = 0
	if word_len > 0:
		fill = int(floor(float(match_len) / float(word_len) * width))
		fill = clamp(fill, 0, width)
	var filled: String = "#".repeat(fill)
	var empty: String = ".".repeat(width - fill)
	var bar: String = "[%s%s] %d/%d" % [filled, empty, match_len, word_len]
	if is_exact:
		bar = "[b]%s[/b]" % bar
	elif is_candidate and normalized_typed != "":
		bar = "[color=#c9d98f]%s[/color]" % bar
	return bar

func _format_typing_stats_line() -> String:
	if typing_stats == null:
		return ""
	if state.phase != "night":
		return ""
	var data: Dictionary = typing_stats.to_report_dict()
	var attempts: int = int(data.get("defend_attempts", 0))
	var hits: int = int(data.get("hits", 0))
	var hit_rate: float = float(data.get("hit_rate", 0.0)) * 100.0
	var backspace_rate: float = float(data.get("backspace_rate", 0.0)) * 100.0
	var incomplete: int = int(data.get("incomplete_enters", 0))
	return "Typing: hits %d/%d (%.0f%%) | backspace %.0f%% | incomplete %d" % [
		hits,
		attempts,
		hit_rate,
		backspace_rate,
		incomplete
	]

func _format_preview_line(building_type: String, preview: Dictionary) -> String:
	var ok_text: String = "yes"
	if not bool(preview.get("ok", false)):
		var reason: String = str(preview.get("reason", "blocked"))
		ok_text = "no (%s)" % reason
	var cost_text: String = _format_resource_list(preview.get("cost", {}), false)
	var prod_text: String = _format_resource_list(preview.get("production", {}), true)
	var defense: int = int(preview.get("defense", 0))
	var extra: String = ""
	if building_type == "tower":
		var tower_stats_preview: Dictionary = preview.get("tower_stats", {})
		extra = " | range %d dmg %d shots %d" % [
			int(tower_stats_preview.get("range", 0)),
			int(tower_stats_preview.get("damage", 0)),
			int(tower_stats_preview.get("shots", 0))
		]
	return "%s: buildable %s | cost %s | prod %s | def %d%s" % [
		building_type, ok_text, cost_text, prod_text, defense, extra
	]

func _format_resource_list(values: Dictionary, show_plus: bool) -> String:
	var parts: Array[String] = []
	for key in GameState.RESOURCE_KEYS:
		if not values.has(key):
			continue
		var amount: int = int(values.get(key, 0))
		if amount == 0:
			continue
		if show_plus:
			parts.append("%s +%d" % [key, amount])
		else:
			parts.append("%s %d" % [key, amount])
	if parts.is_empty():
		return "none"
	return ", ".join(parts)
