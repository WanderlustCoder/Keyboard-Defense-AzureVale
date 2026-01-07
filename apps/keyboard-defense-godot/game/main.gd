extends Node2D

const DefaultState = preload("res://sim/default_state.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const GameState = preload("res://sim/types.gd")
const SimIntents = preload("res://sim/intents.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimWords = preload("res://sim/words.gd")
const SimTypingFeedback = preload("res://sim/typing_feedback.gd")
const SimTypingStats = preload("res://sim/typing_stats.gd")
const SimTypingTrends = preload("res://sim/typing_trends.gd")
const PracticeGoals = preload("res://sim/practice_goals.gd")
const SimLessons = preload("res://sim/lessons.gd")
const SimBalance = preload("res://sim/balance.gd")
const SimBalanceReport = preload("res://sim/balance_report.gd")
const GamePersistence = preload("res://game/persistence.gd")
const TypingProfile = preload("res://game/typing_profile.gd")
const GoalTheme = preload("res://game/goal_theme.gd")
const RebindableActions = preload("res://game/rebindable_actions.gd")
const ControlsFormatter = preload("res://game/controls_formatter.gd")
const KeybindConflicts = preload("res://game/keybind_conflicts.gd")
const MiniTrend = preload("res://game/mini_trend.gd")
const LessonsSort = preload("res://game/lessons_sort.gd")
const LessonHealth = preload("res://game/lesson_health.gd")
const OnboardingFlow = preload("res://game/onboarding_flow.gd")

@onready var stats_label: Label = $CanvasLayer/UIRoot/StatsPanel/StatsLabel     
@onready var ui_root: Control = $CanvasLayer/UIRoot
@onready var goal_badge: RichTextLabel = $CanvasLayer/UIRoot/StatsPanel/GoalBadge
@onready var goal_legend: RichTextLabel = $CanvasLayer/UIRoot/StatsPanel/GoalLegend
@onready var lesson_health_label: Label = $CanvasLayer/UIRoot/StatsPanel/LessonHealthLabel
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
@onready var controls_text: RichTextLabel = $CanvasLayer/UIRoot/SettingsPanel/ControlsText
@onready var lessons_settings_text: RichTextLabel = $CanvasLayer/UIRoot/SettingsPanel/LessonsSettingsText
@onready var tutorial_panel: Panel = $CanvasLayer/UIRoot/TutorialPanel
@onready var tutorial_label: RichTextLabel = $CanvasLayer/UIRoot/TutorialPanel/TutorialLabel
@onready var lesson_panel: Panel = $CanvasLayer/UIRoot/LessonPanel
@onready var lesson_label: RichTextLabel = $CanvasLayer/UIRoot/LessonPanel/LessonLabel
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
var lesson_visible: bool = false
var tutorial_visible: bool = false
var awaiting_bind_action: String = ""
var profile: Dictionary = {}
var onboarding: Dictionary = {}
var onboarding_flags: Dictionary = {}
var typing_history: Array = []
var lifetime: Dictionary = {}
var current_goal: String = "balanced"
var preferred_lesson: String = ""
var lesson_progress: Dictionary = {}
var lessons_sort_mode: String = "default"
var lessons_sparkline: bool = true
var economy_note_shown: bool = false
var ui_scale_percent: int = 100
var compact_panels: bool = false
var cycle_goal_keybind: Dictionary = {}
var toggle_settings_keybind: Dictionary = {}
var toggle_lessons_keybind: Dictionary = {}
var toggle_trend_keybind: Dictionary = {}
var toggle_compact_keybind: Dictionary = {}
var toggle_history_keybind: Dictionary = {}
var toggle_report_keybind: Dictionary = {}

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
    if controls_text != null:
        controls_text.bbcode_enabled = false
        if lessons_settings_text != null:
            lessons_settings_text.bbcode_enabled = false
        if tutorial_label != null:
            tutorial_label.bbcode_enabled = true
        if lesson_label != null:
            lesson_label.bbcode_enabled = true
        if tutorial_panel != null:
            tutorial_panel.visible = false
    if lesson_panel != null:
        lesson_panel.visible = false
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
    _reset_onboarding_flags()
    _append_log(["Type 'help' to see commands."])
    _refresh_hud()
    command_bar.grab_focus()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _apply_ui_scale(ui_scale_percent)

func _input(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed and not event.echo:
                if awaiting_bind_action != "":
                        _handle_bind_action(event)
                        return
                if KeybindConflicts.event_matches_action_exact(event, "toggle_settings"):
                        _toggle_settings_hotkey()
                        get_viewport().set_input_as_handled()
                        return
                if KeybindConflicts.event_matches_action_exact(event, "toggle_lessons"):
                        _toggle_lessons_hotkey()
                        get_viewport().set_input_as_handled()
                        return
                if KeybindConflicts.event_matches_action_exact(event, "toggle_trend"):
                        _toggle_trend_hotkey()
                        get_viewport().set_input_as_handled()
                        return
                if KeybindConflicts.event_matches_action_exact(event, "toggle_compact"):
                        _toggle_compact_hotkey()
                        get_viewport().set_input_as_handled()
                        return
                if KeybindConflicts.event_matches_action_exact(event, "toggle_history"):
                        _toggle_history_hotkey()
                        get_viewport().set_input_as_handled()
                        return
                if KeybindConflicts.event_matches_action_exact(event, "toggle_report"):
                        _toggle_report_hotkey()
                        get_viewport().set_input_as_handled()
                        return
                if KeybindConflicts.event_matches_action_exact(event, "cycle_goal"):
                        _cycle_goal_hotkey()
                        get_viewport().set_input_as_handled()
                        return

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
        if intent_kind == "ui_version":
            command_bar.accept_submission(trimmed)
            _apply_version()
            return
        if intent_kind == "help":
            command_bar.accept_submission(trimmed)
            _apply_help(parsed.intent)
            return
        if intent_kind == "ui_lessons_toggle":
            _apply_lessons_toggle()
            return
        if intent_kind == "ui_lessons_reset":
            _apply_lessons_reset(parsed.intent)
            return
        if intent_kind == "ui_lessons_sort":
            _apply_lessons_sort(parsed.intent)
            return
        if intent_kind == "ui_lessons_sparkline":
            _apply_lessons_sparkline(parsed.intent)
            return
        if intent_kind == "ui_settings_toggle":
            command_bar.accept_submission(trimmed)
            _apply_settings_toggle()
            return
        if intent_kind == "ui_settings_show":
            _apply_settings_show()
            return
        if intent_kind == "ui_settings_hide":
            _apply_settings_hide()
            return
        if intent_kind == "ui_settings_lessons":
            _apply_settings_lessons()
            return
        if intent_kind == "ui_settings_prefs":
            _apply_settings_prefs()
            return
        if intent_kind == "ui_settings_scale":
            _apply_settings_scale(parsed.intent)
            return
        if intent_kind == "ui_settings_compact":
            _apply_settings_compact(parsed.intent)
            return
        if intent_kind == "ui_settings_verify":
            _apply_settings_verify()
            return
        if intent_kind == "ui_settings_conflicts":
            _apply_settings_conflicts()
            return
        if intent_kind == "ui_settings_resolve":
            _apply_settings_resolve(parsed.intent)
            return
        if intent_kind == "ui_settings_export":
            _apply_settings_export(parsed.intent)
            return
        if intent_kind == "ui_balance_verify":
            _apply_balance_verify()
            return
        if intent_kind == "ui_balance_summary":
            _apply_balance_summary(parsed.intent)
            return
        if intent_kind == "ui_balance_export":
            _apply_balance_export(parsed.intent)
            return
        if intent_kind == "ui_balance_diff":
            _apply_balance_diff(parsed.intent)
            return
        if intent_kind == "ui_tutorial_toggle":
            _apply_tutorial_toggle()
            return
        if intent_kind == "ui_tutorial_restart":
            _apply_tutorial_restart()
            return
        if intent_kind == "ui_tutorial_skip":
            _apply_tutorial_skip()
            return
        if intent_kind == "ui_bind_action":
            command_bar.accept_submission(trimmed)
            _apply_bind_action(parsed.intent)
            return
        if intent_kind == "ui_bind_action_reset":
            command_bar.accept_submission(trimmed)
            _apply_bind_action_reset(parsed.intent)
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
        _apply_result(result, intent_kind)
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
            _apply_result(defend_result, "defend_input")
            return

    _append_log(["Error: %s" % parsed.get("error", "Unknown error")])

func _apply_result(result: Dictionary, intent_kind: String = "") -> void:
    var prev_phase: String = state.phase
    var prev_lesson: String = state.lesson_id
    state = result.state
    _append_log(result.events)
    if result.has("request"):
        var request_result: Dictionary = _handle_request(result.request)
        if request_result.has("state"):
            state = request_result.state
        if request_result.has("events"):
            _append_log(request_result.events)
    _advance_onboarding(intent_kind, result.events, prev_phase, state.phase)
    _refresh_hud()
    _handle_phase_change(prev_phase, state.phase)
    if state.lesson_id != prev_lesson:
        _sync_lesson_preference()
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
    _refresh_tutorial_panel()
    _refresh_lesson_health()
    _refresh_settings_panel()
    _refresh_lesson_panel()
    _refresh_report_panel()
    _refresh_history_panel()
    _refresh_trend_panel()
    _maybe_log_economy_guardrails()

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
        command_bar.placeholder_text = "Type a command (help/status/gather/build/explore/end/cursor/inspect/map/demolish/upgrade/preview/wait/overlay/enemies/report/history/trend/lesson/lessons)"

func _refresh_tutorial_panel() -> void:
        if tutorial_panel == null or tutorial_label == null:
                return
        _ensure_onboarding_state()
        var enabled: bool = bool(onboarding.get("enabled", true))       
        tutorial_panel.visible = enabled and tutorial_visible
        if not enabled or not tutorial_visible:
                tutorial_label.text = ""
                return
        var step_index: int = int(onboarding.get("step", 0))
        var completed: bool = bool(onboarding.get("completed", false))  
        if completed:
                step_index = OnboardingFlow.step_count()
        tutorial_label.text = OnboardingFlow.format_step(step_index)

func _advance_onboarding(intent_kind: String, events: Array, prev_phase: String, new_phase: String) -> void:
        _ensure_onboarding_state()
        if bool(onboarding.get("completed", false)):
                return
        if not bool(onboarding.get("enabled", true)):
                return
        _update_onboarding_flags(intent_kind, events, prev_phase, new_phase)
        var snapshot: Dictionary = _build_onboarding_snapshot(prev_phase, new_phase)
        var step_index: int = OnboardingFlow.clamp_step(int(onboarding.get("step", 0)))
        var next_step: int = OnboardingFlow.advance(step_index, snapshot)
        if next_step == step_index:
                return
        onboarding["step"] = next_step
        if next_step >= OnboardingFlow.step_count():
                onboarding["completed"] = true
                onboarding["enabled"] = false
                _append_log(["Tutorial completed. Use 'tutorial restart' to replay."])
        _persist_onboarding_state()
        _refresh_tutorial_panel()

func _event_has_prefix(events: Array, prefix: String) -> bool:
        for event in events:
                if str(event).begins_with(prefix):
                        return true
        return false

func _default_onboarding_flags() -> Dictionary:
        return {
                "used_help_or_status": false,
                "did_gather": false,
                "did_build": false,
                "did_explore": false,
                "entered_night": false,
                "hit_enemy": false,
                "reached_dawn": false,
                "opened_lessons": false,
                "opened_settings": false,
                "toggled_tutorial": false
        }

func _reset_onboarding_flags() -> void:
        onboarding_flags = _default_onboarding_flags()

func _update_onboarding_flags(intent_kind: String, events: Array, prev_phase: String, new_phase: String) -> void:
        if onboarding_flags.is_empty():
                _reset_onboarding_flags()
        if intent_kind == "help" or intent_kind == "status":
                onboarding_flags["used_help_or_status"] = true
        if intent_kind == "gather" and _event_has_prefix(events, "Gathered "):
                onboarding_flags["did_gather"] = true
        if intent_kind == "build" and _event_has_prefix(events, "Built "):
                onboarding_flags["did_build"] = true
        if intent_kind == "explore" and _event_has_prefix(events, "Discovered tile"):
                onboarding_flags["did_explore"] = true
        if prev_phase != "night" and new_phase == "night":
                onboarding_flags["entered_night"] = true
        if _event_has_prefix(events, "Hit "):
                onboarding_flags["hit_enemy"] = true
        if prev_phase == "night" and new_phase == "day":
                onboarding_flags["reached_dawn"] = true
        if intent_kind == "ui_lessons_toggle" and lesson_visible:
                onboarding_flags["opened_lessons"] = true
        if intent_kind.begins_with("ui_settings") and settings_visible:
                onboarding_flags["opened_settings"] = true
        if intent_kind.begins_with("ui_tutorial"):
                onboarding_flags["toggled_tutorial"] = true

func _build_onboarding_snapshot(prev_phase: String, new_phase: String) -> Dictionary:
        var buildings_total: int = 0
        for value in state.buildings.values():
                buildings_total += int(value)
        return {
                "phase": new_phase,
                "day": state.day,
                "used_help_or_status": bool(onboarding_flags.get("used_help_or_status", false)),
                "did_gather": bool(onboarding_flags.get("did_gather", false)),
                "did_build": bool(onboarding_flags.get("did_build", false)),
                "did_explore": bool(onboarding_flags.get("did_explore", false)),
                "entered_night": bool(onboarding_flags.get("entered_night", false)),
                "hit_enemy": bool(onboarding_flags.get("hit_enemy", false)),
                "reached_dawn": bool(onboarding_flags.get("reached_dawn", false)),
                "opened_lessons": bool(onboarding_flags.get("opened_lessons", false)),
                "opened_settings": bool(onboarding_flags.get("opened_settings", false)),
                "toggled_tutorial": bool(onboarding_flags.get("toggled_tutorial", false)),
                "buildings_total": buildings_total,
                "explored_count": state.discovered.size(),
                "prev_phase": prev_phase
        }

func _ensure_onboarding_state() -> void:
        if onboarding.is_empty():
                onboarding = TypingProfile.default_onboarding_state()

func _persist_onboarding_state() -> void:
        var result: Dictionary = TypingProfile.set_onboarding(profile, onboarding)
        profile = result.get("profile", profile)
        onboarding = TypingProfile.get_onboarding(profile)
        if not result.get("ok", true):
                _append_log(["Onboarding save failed: %s" % str(result.get("error", "unknown error"))])

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
    if not settings_visible and awaiting_bind_action != "":
        awaiting_bind_action = ""
        _append_log(["Keybind canceled."])
    _refresh_settings_panel()
    _advance_onboarding("ui_settings_toggle", [], state.phase, state.phase)
    command_bar.grab_focus()

func _apply_settings_show() -> void:
    settings_visible = true
    _append_log(["Settings: ON"])
    _refresh_settings_panel()
    _advance_onboarding("ui_settings_show", [], state.phase, state.phase)
    command_bar.grab_focus()

func _apply_settings_hide() -> void:
    if settings_visible and awaiting_bind_action != "":
        awaiting_bind_action = ""
        _append_log(["Keybind canceled."])
    settings_visible = false
    _append_log(["Settings: OFF"])
    _refresh_settings_panel()
    _advance_onboarding("ui_settings_hide", [], state.phase, state.phase)
    command_bar.grab_focus()

func _apply_settings_lessons() -> void:
    var lesson_id: String = state.lesson_id
    var lesson_name: String = SimLessons.lesson_label(lesson_id)
    var sort_mode: String = TypingProfile.get_lessons_sort(profile)
    var sparkline_enabled: bool = TypingProfile.get_lessons_sparkline(profile)
    var spark_text: String = "ON" if sparkline_enabled else "OFF"
    var lines: Array[String] = []
    lines.append("Settings: Lessons")
    lines.append("Lesson: %s (%s)" % [lesson_name, lesson_id])
    lines.append("Sort: %s" % sort_mode)
    lines.append("Sparklines: %s" % spark_text)
    lines.append(LessonHealth.legend_line())
    lines.append("Commands: lessons sort default|recent|name | lessons sparkline on|off")
    _append_log(lines)
    if not settings_visible:
        settings_visible = true
    _refresh_settings_panel()
    _advance_onboarding("ui_settings_lessons", [], state.phase, state.phase)
    command_bar.grab_focus()

func _apply_settings_prefs() -> void:
    var lesson_id: String = state.lesson_id
    var lesson_name: String = SimLessons.lesson_label(lesson_id)
    var goal_label: String = PracticeGoals.goal_label(current_goal)
    var sort_mode: String = TypingProfile.get_lessons_sort(profile)
    var sparkline_enabled: bool = TypingProfile.get_lessons_sparkline(profile)
    var spark_text: String = "ON" if sparkline_enabled else "OFF"
    var lines: Array[String] = []
    lines.append("Settings: Prefs")
    lines.append("Phase: %s | Day: %d" % [state.phase, state.day])
    lines.append("Lesson: %s (%s)" % [lesson_name, lesson_id])
    lines.append("Goal: %s (%s)" % [goal_label, current_goal])
    lines.append("Lessons sort: %s" % sort_mode)
    lines.append("Lessons sparklines: %s" % spark_text)
    lines.append("UI scale: %d%%" % ui_scale_percent)
    lines.append("Compact panels: %s" % ("ON" if compact_panels else "OFF"))
    lines.append(LessonHealth.legend_line())
    lines.append("Panels: Settings %s | Lessons %s | Trend %s | History %s | Report %s" % [
        _panel_state(settings_panel),
        _panel_state(lesson_panel),
        _panel_state(trend_panel),
        _panel_state(history_panel),
        _panel_state(report_panel)
    ])
    lines.append("Keybinds:")
    var controls: String = ControlsFormatter.format_controls_list(RebindableActions.actions())
    for line in controls.split("\n"):
        if line != "":
            lines.append("  %s" % line)
    lines.append("Reminders: goal next | goal <id> | lesson <id> | lesson next")
    lines.append("           lessons sort default|recent|name | lessons sparkline on|off | bind <action>")
    lines.append("           settings scale|font 80..140 | settings compact on|off|toggle")
    lines.append("           settings verify | settings conflicts | settings resolve | settings export")
    _append_log(lines)
    _advance_onboarding("ui_settings_prefs", [], state.phase, state.phase)
    command_bar.grab_focus()

func _apply_settings_scale(intent: Dictionary) -> void:
    var mode: String = str(intent.get("mode", "show"))
    var updated_scale: int = ui_scale_percent
    if mode == "show":
        _append_log(["UI scale: %d%% (settings scale|font 80..140 | + | - | reset)" % ui_scale_percent])
        command_bar.grab_focus()
        return
    if mode == "reset":
        updated_scale = 100
    elif mode == "set":
        updated_scale = int(intent.get("value", ui_scale_percent))
    elif mode == "step":
        var delta: int = int(intent.get("delta", 0))
        var options: Array = TypingProfile.UI_SCALE_VALUES
        var idx: int = options.find(ui_scale_percent)
        if idx < 0:
            idx = options.find(100)
        idx = clamp(idx + delta, 0, options.size() - 1)
        updated_scale = int(options[idx])
    var result: Dictionary = TypingProfile.set_ui_scale_percent(profile, updated_scale)
    profile = result.get("profile", profile)
    ui_scale_percent = TypingProfile.get_ui_scale_percent(profile)
    if not result.get("ok", true):
        _append_log(["UI scale save failed: %s" % str(result.get("error", "unknown error"))])
    _apply_ui_scale(ui_scale_percent)
    _append_log(["UI scale set to %d%%." % ui_scale_percent])
    _refresh_settings_panel()
    command_bar.grab_focus()

func _apply_settings_compact(intent: Dictionary) -> void:
    var mode: String = str(intent.get("mode", "show"))
    if mode == "show":
        _append_log(["Compact panels: %s (settings compact on|off|toggle)" % ("ON" if compact_panels else "OFF")])
        command_bar.grab_focus()
        return
    if mode == "toggle":
        compact_panels = not compact_panels
    elif mode == "on":
        compact_panels = true
    elif mode == "off":
        compact_panels = false
    var result: Dictionary = TypingProfile.set_compact_panels(profile, compact_panels)
    profile = result.get("profile", profile)
    if not result.get("ok", true):
        _append_log(["Compact panels save failed: %s" % str(result.get("error", "unknown error"))])
    var state_text: String = "ON" if compact_panels else "OFF"
    _append_log(["Compact panels: %s" % state_text])
    _refresh_settings_panel()
    _refresh_lesson_panel()
    _refresh_history_panel()
    _refresh_trend_panel()
    _refresh_wave_panel()
    command_bar.grab_focus()

func _apply_help(intent: Dictionary) -> void:
    var topic_raw: String = str(intent.get("topic", ""))
    var lines: Array[String] = build_help_lines(topic_raw, RebindableActions.actions())
    _append_log(lines)
    command_bar.grab_focus()

func _apply_version() -> void:
    var lines: Array[String] = build_version_lines()
    _append_log(lines)
    command_bar.grab_focus()

func _apply_settings_verify() -> void:
    var viewport_rect: Rect2 = get_viewport().get_visible_rect()
    var size: Vector2 = viewport_rect.size
    var width: int = int(round(size.x))
    var height: int = int(round(size.y))
    var keybind_actions: Array[String] = [
        "toggle_settings",
        "toggle_lessons",
        "toggle_trend",
        "toggle_compact",
        "toggle_history",
        "toggle_report",
        "cycle_goal"
    ]
    var panel_states: Dictionary = {
        "settings": _panel_state(settings_panel),
        "lessons": _panel_state(lesson_panel),
        "trend": _panel_state(trend_panel),
        "history": _panel_state(history_panel),
        "report": _panel_state(report_panel)
    }
    var conflicts: Dictionary = _detect_keybind_conflicts()
    var lines: Array[String] = build_settings_verify_lines(
        width,
        height,
        ui_scale_percent,
        compact_panels,
        panel_states,
        keybind_actions,
        conflicts
    )
    _append_log(lines)
    command_bar.grab_focus()

func _apply_settings_conflicts() -> void:
    var lines: Array[String] = []
    var action_map: Dictionary = _build_keybind_action_map()
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_map)
    if conflicts.is_empty():
        lines.append("Keybind conflicts: none")
    else:
        lines.append("Keybind conflicts: %d" % conflicts.size())
        var display_conflicts: Dictionary = _conflicts_with_display_names(conflicts)
        var conflict_lines: Array[String] = KeybindConflicts.format_conflicts(
            display_conflicts,
            Callable(KeybindConflicts, "signature_to_label")
        )
        for line in conflict_lines:
            lines.append(line)
        var suggestion: String = KeybindConflicts.suggest_unused_safe_key(action_map)
        if suggestion != "":
            lines.append("Tip: Rebind an action with: bind <action> <key> (try %s, unused among rebindable actions)." % suggestion)
    _append_log(lines)
    command_bar.grab_focus()

func _apply_settings_resolve(intent: Dictionary) -> void:
    var apply_changes: bool = bool(intent.get("apply", false))
    var action_map: Dictionary = _build_keybind_action_map()
    var plan: Dictionary = KeybindConflicts.build_resolution_plan(action_map)
    var conflicts: Dictionary = plan.get("conflicts", {})
    if typeof(conflicts) != TYPE_DICTIONARY or conflicts.is_empty():
        _append_log([KeybindConflicts.no_conflicts_message()])
        command_bar.grab_focus()
        return
    if not apply_changes:
        var plan_lines: Array[String] = KeybindConflicts.format_resolution_plan(
            plan,
            Callable(self, "_action_display_name"),
            Callable(KeybindConflicts, "signature_to_label")
        )
        _append_log(plan_lines)
        command_bar.grab_focus()
        return
    var lines: Array[String] = []
    lines.append("Keybind resolve apply:")
    var changes: Variant = plan.get("changes", [])
    var unresolved: Array = []
    if typeof(plan.get("unresolved", [])) == TYPE_ARRAY:
        unresolved = plan.get("unresolved", []).duplicate(true)
    var applied_changes: Array = []
    var applied_count: int = 0
    if typeof(changes) == TYPE_ARRAY:
        for change in changes:
            if typeof(change) != TYPE_DICTIONARY:
                continue
            var action_name: String = str(change.get("action", ""))
            if action_name == "":
                continue
            var from_signature: String = str(change.get("from_signature", ""))
            var to_signature: String = str(change.get("to_signature", ""))
            var keybind: Dictionary = KeybindConflicts.keybind_from_signature(to_signature)
            if int(keybind.get("keycode", 0)) <= 0:
                unresolved.append({
                    "action": action_name,
                    "signature": from_signature,
                    "reason": "Invalid key signature."
                })
                continue
            var result: Dictionary = TypingProfile.set_keybind(profile, action_name, keybind)
            profile = result.get("profile", profile)
            var normalized: Dictionary = TypingProfile.get_keybind(profile, action_name)
            _set_cached_keybind(action_name, normalized)
            _apply_keybind(action_name, normalized)
            if not result.get("ok", true):
                lines.append("Warning: keybind save failed for %s (%s)." % [
                    _action_display_name(action_name),
                    str(result.get("error", "unknown error"))
                ])
            applied_changes.append(change)
            applied_count += 1
    var applied_lines: Array[String] = KeybindConflicts.format_resolution_changes(
        applied_changes,
        Callable(self, "_action_display_name"),
        Callable(KeybindConflicts, "signature_to_label"),
        "APPLIED"
    )
    for line in applied_lines:
        lines.append(line)
    lines.append("Changes applied: %d" % applied_count)
    var remaining_conflicts: Dictionary = _detect_keybind_conflicts()
    if remaining_conflicts.is_empty():
        lines.append("Conflicts remaining: 0")
    else:
        lines.append("Conflicts remaining: %d" % remaining_conflicts.size())
        var display_conflicts: Dictionary = _conflicts_with_display_names(remaining_conflicts)
        var conflict_lines: Array[String] = KeybindConflicts.format_conflicts(
            display_conflicts,
            Callable(KeybindConflicts, "signature_to_label")
        )
        for line in conflict_lines:
            lines.append(line)
    var unresolved_lines: Array[String] = KeybindConflicts.format_resolution_unresolved(
        unresolved,
        Callable(self, "_action_display_name"),
        Callable(KeybindConflicts, "signature_to_label")
    )
    for line in unresolved_lines:
        lines.append(line)
    _append_log(lines)
    _refresh_settings_panel()
    _refresh_controls_text()
    _refresh_goal_legend()
    command_bar.grab_focus()

func _apply_settings_export(intent: Dictionary) -> void:
    var save: bool = bool(intent.get("save", false))
    var actions: Array[String] = []
    for action_name in RebindableActions.actions():
        actions.append(str(action_name))
    actions.sort()
    var keybinds: Dictionary = {}
    for action_name in actions:
        keybinds[action_name] = TypingProfile.get_keybind(profile, action_name)
    var action_map: Dictionary = KeybindConflicts.build_action_signature_map(actions)
    var scale_percent: int = TypingProfile.get_ui_scale_percent(profile)
    var ui_scale: float = float(scale_percent) / 100.0
    var ui_compact: bool = TypingProfile.get_compact_panels(profile)
    var ui_state: Dictionary = {"scale": ui_scale, "compact": ui_compact}
    var game_state: Dictionary = {
        "name": "Keyboard Defense",
        "version": KeybindConflicts.read_game_version()
    }
    var version_info: Dictionary = Engine.get_version_info()
    var major: int = int(version_info.get("major", 0))
    var minor: int = int(version_info.get("minor", 0))
    var patch: int = int(version_info.get("patch", 0))
    var godot_text: String = ""
    if major != 0 or minor != 0 or patch != 0:
        godot_text = "%d.%d.%d" % [major, minor, patch]
    else:
        godot_text = str(version_info.get("string", ""))
    if godot_text == "":
        godot_text = "0.0.0"
    var engine_state: Dictionary = {
        "godot": godot_text,
        "major": major,
        "minor": minor,
        "patch": patch
    }
    var window_width: int = 0
    var window_height: int = 0
    var viewport := get_viewport()
    if viewport != null:
        var size: Vector2 = viewport.get_visible_rect().size
        window_width = max(0, int(round(size.x)))
        window_height = max(0, int(round(size.y)))
    var window_state: Dictionary = {"width": window_width, "height": window_height}
    var panels_state: Dictionary = {
        "settings": settings_panel != null and settings_panel.visible,
        "lessons": lesson_panel != null and lesson_panel.visible,
        "trend": trend_panel != null and trend_panel.visible,
        "history": history_panel != null and history_panel.visible,
        "report": report_panel != null and report_panel.visible
    }
    var payload: Dictionary = KeybindConflicts.build_settings_export_payload(
        actions,
        keybinds,
        action_map,
        ui_state,
        engine_state,
        window_state,
        panels_state,
        game_state
    )
    var json_text: String = KeybindConflicts.format_settings_export_json(payload)
    if save:
        var path: String = "user://settings_export.json"
        var file := FileAccess.open(path, FileAccess.WRITE)
        if file != null:
            file.store_string(json_text)
            file.close()
        print("Saved to user://settings_export.json")
        _append_log(["Saved to user://settings_export.json"])
    else:
        print(json_text)
    command_bar.grab_focus()

func _apply_balance_verify() -> void:
    var output: String = SimBalanceReport.balance_verify_output()
    print(output)
    var lines: PackedStringArray = output.split("\n", false)
    _append_log(lines)
    command_bar.grab_focus()

func _apply_balance_summary(intent: Dictionary) -> void:
    var group: String = str(intent.get("group", ""))
    var output: String = SimBalanceReport.balance_summary_output(group)
    print(output)
    var lines: PackedStringArray = output.split("\n", false)
    _append_log(lines)
    command_bar.grab_focus()

func _apply_balance_export(intent: Dictionary) -> void:
    var save: bool = bool(intent.get("save", false))
    var group: String = str(intent.get("group", "all"))
    if save:
        var result: Dictionary = SimBalanceReport.save_balance_export(group)
        var line: String = str(result.get("line", SimBalanceReport.SAVE_LINE))
        print(line)
        _append_log([line])
    else:
        var json_text: String = SimBalanceReport.balance_export_json(group)
        print(json_text)
        if not json_text.begins_with("{"):
            _append_log([json_text])
    command_bar.grab_focus()

func _apply_balance_diff(intent: Dictionary) -> void:
    var group: String = str(intent.get("group", "all"))
    var output: String = SimBalanceReport.balance_diff_output(group)
    print(output)
    var lines: PackedStringArray = output.split("\n", false)
    _append_log(lines)
    command_bar.grab_focus()

func _apply_tutorial_toggle() -> void:
        _ensure_onboarding_state()
        tutorial_visible = not tutorial_visible
        onboarding["ever_shown"] = true
        var state_text: String = "ON" if tutorial_visible else "OFF"
        _append_log(["Tutorial: %s" % state_text])
        _persist_onboarding_state()
        _refresh_tutorial_panel()
        _advance_onboarding("ui_tutorial_toggle", [], state.phase, state.phase)
        command_bar.grab_focus()

func _apply_tutorial_restart() -> void:
        _ensure_onboarding_state()
        var reset_result: Dictionary = TypingProfile.reset_onboarding(profile)
        profile = reset_result.get("profile", profile)
        onboarding = TypingProfile.get_onboarding(profile)
        if not reset_result.get("ok", true):
                _append_log(["Onboarding reset failed: %s" % str(reset_result.get("error", "unknown error"))])
        tutorial_visible = true
        _reset_onboarding_flags()
        _append_log(["Tutorial restarted."])
        _refresh_tutorial_panel()
        _advance_onboarding("ui_tutorial_restart", [], state.phase, state.phase)
        command_bar.grab_focus()

func _apply_tutorial_skip() -> void:
        _ensure_onboarding_state()
        onboarding["enabled"] = false
        onboarding["completed"] = true
        onboarding["step"] = OnboardingFlow.step_count()
        onboarding["ever_shown"] = true
        tutorial_visible = false
        _append_log(["Tutorial skipped. Use 'tutorial restart' to replay."])
        _persist_onboarding_state()
        _refresh_tutorial_panel()
        _advance_onboarding("ui_tutorial_skip", [], state.phase, state.phase)
        command_bar.grab_focus()

func _panel_state(panel: CanvasItem) -> String:
    if panel == null:
        return "UNKNOWN"
    return "ON" if panel.visible else "OFF"

func _apply_bind_action(intent: Dictionary) -> void:
        var action_name: String = str(intent.get("action", ""))
        if not _is_rebindable_action(action_name):
                _append_log(["Unknown bind action: %s" % action_name])
                command_bar.grab_focus()
                return
        var key_text: String = str(intent.get("key_text", "")).strip_edges()
        if key_text != "":
                var keybind: Dictionary = _keybind_from_text(key_text)
                if int(keybind.get("keycode", 0)) > 0:
                        awaiting_bind_action = ""
                        _set_action_keybind(action_name, keybind, "%s bound: %%s" % _action_display_name(action_name))
                else:
                        _append_log(["Unknown key: %s" % key_text, "Use: bind <action> and press a key."])
                command_bar.grab_focus()
                return
        settings_visible = true
        awaiting_bind_action = action_name
        _append_log(["Press a key for %s (Esc to cancel)." % _action_display_name(action_name)])
        _refresh_settings_panel()
        command_bar.grab_focus()

func _apply_bind_action_reset(intent: Dictionary) -> void:
    var action_name: String = str(intent.get("action", ""))
    if not _is_rebindable_action(action_name):
        _append_log(["Unknown bind action: %s" % action_name])
        command_bar.grab_focus()
        return
    awaiting_bind_action = ""
    var defaults: Dictionary = TypingProfile.default_keybinds().get(action_name, {})
    _set_action_keybind(action_name, defaults, "%s reset: %%s" % _action_display_name(action_name))
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

func _sync_lesson_preference() -> void:
    preferred_lesson = SimLessons.normalize_lesson_id(state.lesson_id)
    if not lesson_progress.has(preferred_lesson):
        lesson_progress[preferred_lesson] = TypingProfile.default_lesson_progress_entry()
    profile["lesson_progress"] = lesson_progress
    var result: Dictionary = TypingProfile.set_lesson(profile, preferred_lesson)
    profile = result.get("profile", profile)
    if not result.get("ok", true):
        _append_log(["Lesson update failed: %s" % str(result.get("error", "unknown error"))])
    _refresh_settings_panel()
    _refresh_report_panel()
    _refresh_lesson_panel()

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

func _toggle_settings_hotkey() -> void:
        _apply_settings_toggle()
        command_bar.grab_focus()

func _toggle_lessons_hotkey() -> void:
        _apply_lessons_toggle()
        command_bar.grab_focus()

func _toggle_trend_hotkey() -> void:
        trend_visible = not trend_visible
        _refresh_trend_panel()
        command_bar.grab_focus()

func _toggle_compact_hotkey() -> void:
        compact_panels = not compact_panels
        var result: Dictionary = TypingProfile.set_compact_panels(profile, compact_panels)
        profile = result.get("profile", profile)
        if not result.get("ok", true):
                _append_log(["Compact panels save failed: %s" % str(result.get("error", "unknown error"))])
        var state_text: String = "ON" if compact_panels else "OFF"
        _append_log(["Compact Panels: %s" % state_text])
        _refresh_settings_panel()
        _refresh_lesson_panel()
        _refresh_history_panel()
        _refresh_trend_panel()
        _refresh_wave_panel()
        command_bar.grab_focus()

func _toggle_history_hotkey() -> void:
        history_visible = not history_visible
        var state_text: String = "ON" if history_visible else "OFF"
        _append_log(["History panel: %s" % state_text])
        _refresh_history_panel()
        command_bar.grab_focus()

func _toggle_report_hotkey() -> void:
        _apply_report({"mode": "toggle"})
        command_bar.grab_focus()

func _handle_bind_action(event: InputEventKey) -> void:
    if event.keycode == KEY_ESCAPE:
        awaiting_bind_action = ""
        _append_log(["Keybind canceled."])
        _refresh_settings_panel()
        get_viewport().set_input_as_handled()
        command_bar.grab_focus()
        return
    if _is_modifier_key(event.keycode):
        return
    var action_name: String = awaiting_bind_action
    if action_name == "":
        return
    var keybind: Dictionary = _keybind_from_event(event)
    awaiting_bind_action = ""
    _set_action_keybind(action_name, keybind, "%s bound: %%s" % _action_display_name(action_name))
    get_viewport().set_input_as_handled()
    command_bar.grab_focus()

func _set_action_keybind(action_name: String, keybind: Dictionary, log_message: String) -> void:
    var result: Dictionary = TypingProfile.set_keybind(profile, action_name, keybind)
    profile = result.get("profile", profile)
    var normalized: Dictionary = TypingProfile.get_keybind(profile, action_name)
    _set_cached_keybind(action_name, normalized)
    _apply_keybind(action_name, normalized)
    if not result.get("ok", true):
        _append_log(["Keybind update failed: %s" % str(result.get("error", "unknown error"))])
    _append_log([log_message % _format_keybind_text(normalized)])
    _warn_keybind_conflicts(action_name)
    _refresh_settings_panel()
    _refresh_controls_text()
    _refresh_goal_legend()

func _set_cached_keybind(action_name: String, keybind: Dictionary) -> void:
        if action_name == "cycle_goal":
                cycle_goal_keybind = keybind
        elif action_name == "toggle_settings":
                toggle_settings_keybind = keybind
        elif action_name == "toggle_lessons":
                toggle_lessons_keybind = keybind
        elif action_name == "toggle_trend":
                toggle_trend_keybind = keybind
        elif action_name == "toggle_compact":
                toggle_compact_keybind = keybind
        elif action_name == "toggle_history":
                toggle_history_keybind = keybind
        elif action_name == "toggle_report":
                toggle_report_keybind = keybind

func _is_rebindable_action(action_name: String) -> bool:
    return RebindableActions.actions().has(action_name)

func _action_display_name(action_name: String) -> String:
    return RebindableActions.display_name(action_name)

static func build_version_lines() -> Array[String]:
    var game_version: String = _game_version_text()
    var engine_version: String = _engine_version_text()
    return [
        "Keyboard Defense v%s" % game_version,
        "Godot v%s" % engine_version
    ]

static func _game_version_text() -> String:
    return KeybindConflicts.read_game_version()

static func _engine_version_text() -> String:
    var version_info: Dictionary = Engine.get_version_info()
    var major: int = int(version_info.get("major", 0))
    var minor: int = int(version_info.get("minor", 0))
    var patch: int = int(version_info.get("patch", 0))
    if major != 0 or minor != 0 or patch != 0:
        return "%d.%d.%d" % [major, minor, patch]
    var fallback: String = str(version_info.get("string", ""))
    if fallback == "":
        fallback = "0.0.0"
    return fallback

static func build_help_lines(topic_raw: String, action_ids: Array[String]) -> Array[String]:
    var topic: String = topic_raw.strip_edges().to_lower()
    if topic == "":
        return _build_help_quick_start_lines(action_ids)
    if topic == "settings":
        return _build_help_settings_lines()
    if topic == "hotkeys":
        return _build_help_hotkeys_lines(action_ids)
    if topic == "topics":
        return _build_help_topics_lines()
    if topic == "play":
        return _build_help_play_lines(action_ids)
    if topic == "accessibility":
        return _build_help_accessibility_lines(action_ids)
    return ["Unknown help topic: %s. Try help." % topic_raw]

static func _build_help_quick_start_lines(action_ids: Array[String]) -> Array[String]:
    var lines: Array[String] = []
    lines.append("Quick start:")
    lines.append("Commands:")
    lines.append("  settings verify")
    lines.append("  settings conflicts")
    lines.append("  settings resolve")
    lines.append("  settings resolve apply")
    lines.append("  settings export")
    lines.append("  settings export save")
    lines.append("  balance verify")
    lines.append("  balance export")
    lines.append("  balance export save")
    lines.append("  balance diff")
    lines.append("  balance summary [group]")
    lines.append("  help settings")
    lines.append("  help hotkeys")
    lines.append("  help topics")
    lines.append("Tip: type help hotkeys to list all hotkeys.")
    lines.append("Tip: type help topics to see all help topics.")
    lines.append("Current hotkeys:")
    var actions: Array[String] = []
    for action_id in action_ids:
        actions.append(str(action_id))
    actions.sort()
    for action_id in actions:
        var binding: String = ControlsFormatter.binding_text_for_action(action_id)
        lines.append("  %s: %s" % [action_id, binding])
    return lines

static func _binding_text_or_unbound(action_id: String) -> String:
    var binding: String = ControlsFormatter.binding_text_for_action(action_id)
    if binding == "" or binding == "Unbound" or binding == "Missing (InputMap)":
        return "unbound"
    return binding

static func _build_help_settings_lines() -> Array[String]:
    return [
        "Settings help:",
        "  settings verify",
        "  settings conflicts",
        "  settings resolve",
        "  settings resolve apply",
        "  settings export",
        "  settings export save"
    ]

static func _build_help_topics_lines() -> Array[String]:
    return [
        "Help topics:",
        "  settings",
        "  hotkeys",
        "  play",
        "  accessibility",
        "  topics"
    ]

static func _build_help_play_lines(action_ids: Array[String]) -> Array[String]:
    var lessons_binding: String = _binding_text_or_unbound("toggle_lessons")
    var settings_binding: String = _binding_text_or_unbound("toggle_settings")
    var goal_binding: String = _binding_text_or_unbound("cycle_goal")
    var report_binding: String = _binding_text_or_unbound("toggle_report")
    var lines: Array[String] = []
    lines.append("How to play:")
    lines.append("  1) Open Lessons: toggle_lessons (%s)" % lessons_binding)
    lines.append("  2) Open Settings: toggle_settings (%s)" % settings_binding)
    lines.append("  3) Change goal: cycle_goal (%s)" % goal_binding)
    lines.append("  4) View report: toggle_report (%s)" % report_binding)
    lines.append("  5) Check setup: settings verify")
    lines.append("  6) If conflicts: settings conflicts, then settings resolve apply")
    return lines

static func _build_help_accessibility_lines(action_ids: Array[String]) -> Array[String]:
    var settings_binding: String = _binding_text_or_unbound("toggle_settings")
    var lessons_binding: String = _binding_text_or_unbound("toggle_lessons")
    var lines: Array[String] = []
    lines.append("Accessibility:")
    lines.append("  Open Settings: toggle_settings (%s)" % settings_binding)
    lines.append("  Open Lessons: toggle_lessons (%s)" % lessons_binding)
    lines.append("  Scale UI: settings scale <percent>")
    lines.append("  Compact on: settings compact on")
    lines.append("  Compact off: settings compact off")
    lines.append("  Check conflicts: settings conflicts")
    lines.append("  Auto-fix conflicts: settings resolve apply")
    lines.append("  Export diagnostics: settings export save")
    lines.append("  Manual checklist: docs/ACCESSIBILITY_VERIFICATION.md")
    return lines

static func _build_help_hotkeys_lines(action_ids: Array[String]) -> Array[String]:
    var lines: Array[String] = []
    lines.append("Hotkeys:")
    var actions: Array[String] = []
    for action_id in action_ids:
        actions.append(str(action_id))
    actions.sort()
    for action_id in actions:
        var binding: String = _binding_text_or_unbound(action_id)
        if binding == "unbound":
            binding = "(unbound)"
        lines.append("  %s: %s" % [action_id, binding])
    var action_map: Dictionary = KeybindConflicts.build_action_signature_map(actions)
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_map)
    if conflicts.is_empty():
        lines.append("Conflicts: none")
    else:
        lines.append("Conflicts: present (run settings conflicts or settings resolve apply)")
    return lines

static func build_settings_verify_lines(
    width: int,
    height: int,
    ui_scale_percent: int,
    compact_panels: bool,
    panel_states: Dictionary,
    keybind_actions: Array[String],
    conflicts: Dictionary
) -> Array[String]:
    var lines: Array[String] = []
    lines.append("Settings Verify:")
    lines.append("Window: %dx%d" % [width, height])
    lines.append("UI scale: %d%%" % ui_scale_percent)
    lines.append("Compact panels: %s" % ("ON" if compact_panels else "OFF"))
    var keybind_parts: Array[String] = []
    for action_name in keybind_actions:
        var action_id: String = str(action_name)
        var binding: String = ControlsFormatter.binding_text_for_action(action_id)
        keybind_parts.append("%s=%s" % [action_id, binding])
    lines.append("Keybinds: %s" % "; ".join(keybind_parts))
    if conflicts.is_empty():
        lines.append("Keybind conflicts: none")
    else:
        lines.append("Keybind conflicts: %d" % conflicts.size())
        var display_conflicts: Dictionary = _conflicts_with_display_names_static(conflicts)
        var conflict_lines: Array[String] = KeybindConflicts.format_conflicts(
            display_conflicts,
            Callable(KeybindConflicts, "signature_to_label")
        )
        for line in conflict_lines:
            lines.append(line)
        lines.append("Tip: run \"settings resolve apply\" to auto-fix conflicts.")
    lines.append("Panels: settings=%s lessons=%s trend=%s history=%s report=%s" % [
        str(panel_states.get("settings", "UNKNOWN")),
        str(panel_states.get("lessons", "UNKNOWN")),
        str(panel_states.get("trend", "UNKNOWN")),
        str(panel_states.get("history", "UNKNOWN")),
        str(panel_states.get("report", "UNKNOWN"))
    ])
    var recs: Array[String] = []
    if width <= 1280 and not compact_panels:
        recs.append("settings compact on")
    if width <= 1280 and ui_scale_percent > 110:
        recs.append("settings scale 110")
    if width >= 1920 and ui_scale_percent < 100:
        recs.append("settings scale 100")
    if recs.is_empty():
        lines.append("Recommendations: none")
    else:
        lines.append("Recommendations: %s" % "; ".join(recs))
    if conflicts.is_empty():
        lines.append("Next: type help for a quick start.")
    return lines

static func _conflicts_with_display_names_static(conflicts: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    var signatures: Array = conflicts.keys()
    signatures.sort()
    for signature in signatures:
        var actions: Variant = conflicts.get(signature, [])
        if typeof(actions) != TYPE_ARRAY:
            continue
        var names: Array[String] = []
        for action_name in actions:
            names.append(RebindableActions.display_name(str(action_name)))
        names.sort()
        result[signature] = names
    return result

func _build_keybind_action_map() -> Dictionary:
    var actions: Array[String] = []
    for action_name in RebindableActions.actions():
        actions.append(action_name)
    return KeybindConflicts.build_action_signature_map(actions)

func _detect_keybind_conflicts() -> Dictionary:
    var action_map: Dictionary = _build_keybind_action_map()
    return KeybindConflicts.find_conflicts(action_map)

func _conflicts_with_display_names(conflicts: Dictionary) -> Dictionary:
    return _conflicts_with_display_names_static(conflicts)

func _warn_keybind_conflicts(action_name: String) -> void:
    var action_map: Dictionary = _build_keybind_action_map()
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_map)
    if conflicts.is_empty():
        return
    var relevant: Dictionary = {}
    for signature in conflicts.keys():
        var actions: Variant = conflicts.get(signature, [])
        if typeof(actions) != TYPE_ARRAY:
            continue
        if actions.has(action_name):
            relevant[signature] = actions
    if relevant.is_empty():
        return
    var signatures: Array = relevant.keys()
    signatures.sort()
    var lines: Array[String] = []
    for signature in signatures:
        var actions: Array = relevant.get(signature, [])
        var names: Array[String] = []
        for action_id in actions:
            names.append(_action_display_name(str(action_id)))
        names.sort()
        var key_label: String = KeybindConflicts.signature_to_label(signature)
        lines.append("Warning: Keybind conflict detected for %s: %s." % [key_label, ", ".join(names)])
    var suggestion: String = KeybindConflicts.suggest_unused_safe_key(action_map)
    if suggestion != "":
        lines.append("Suggestion: bind %s %s (unused among rebindable actions)." % [action_name, suggestion])
    lines.append("Run \"settings verify\" for details.")
    _append_log(lines)

func _log_startup_keybind_conflicts() -> void:
    var action_map: Dictionary = _build_keybind_action_map()
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_map)
    if conflicts.is_empty():
        return
    var display_conflicts: Dictionary = _conflicts_with_display_names(conflicts)
    var conflict_lines: Array[String] = KeybindConflicts.format_conflicts(
        display_conflicts,
        Callable(KeybindConflicts, "signature_to_label")
    )
    if conflict_lines.is_empty():
        return
    var lines: Array[String] = []
    lines.append("Warning: Keybind conflicts detected.")
    for line in conflict_lines:
        lines.append(line)
    var suggestion: String = KeybindConflicts.suggest_unused_safe_key(action_map)
    if suggestion != "":
        var action_hint: String = "toggle_settings"
        if conflicts.size() > 0:
            var signatures: Array = conflicts.keys()
            signatures.sort()
            if not signatures.is_empty():
                var first_signature: String = str(signatures[0])
                var actions: Variant = conflicts.get(first_signature, [])
                if typeof(actions) == TYPE_ARRAY and not actions.is_empty():
                    action_hint = str(actions[0])
        lines.append("Suggestion: bind %s %s (unused among rebindable actions)." % [action_hint, suggestion])
    lines.append("Run \"settings verify\" for details.")
    _append_log(lines)

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
    var binding_text: String = ControlsFormatter.binding_text_for_action("cycle_goal")
    var line_two: String = "%s: cycle goals | goal <id>" % binding_text
    goal_legend.text = "%s\n%s" % [line_one, line_two]

func _refresh_lesson_health() -> void:
    if lesson_health_label == null:
        return
    var lesson_id: String = state.lesson_id
    var lesson_name: String = SimLessons.lesson_label(lesson_id)
    var entry: Dictionary = _lesson_progress_entry(lesson_id)
    var recent: Array = entry.get("recent", [])
    lesson_health_label.text = LessonHealth.build_hud_text(
        lesson_name,
        lesson_id,
        recent,
        lessons_sparkline
    )

func _refresh_settings_panel() -> void:
    if settings_panel == null or settings_label == null:
        return
    settings_panel.visible = settings_visible
    if not settings_visible:
        settings_label.text = ""
        if controls_text != null:
            controls_text.text = ""
        if lessons_settings_text != null:
            lessons_settings_text.text = ""
        return
    var lines: Array[String] = []
    lines.append("[b]Settings[/b]")
    lines.append("Lesson: %s (%s)" % [SimLessons.lesson_label(state.lesson_id), state.lesson_id])
    if awaiting_bind_action != "":
        lines.append("Binding: %s" % _action_display_name(awaiting_bind_action))
        lines.append("Press a key to bind.")
        lines.append("Esc cancels.")
    else:
        lines.append("Type: lesson <id>")
        lines.append("Type: lesson next/prev")
        lines.append("Type: lesson sample [n]")
        lines.append("Type: lessons (toggle panel)")
        lines.append("Type: lessons reset [all]")
        lines.append("Type: lessons sort default|recent|name")
        lines.append("Type: lessons sparkline on|off")
        lines.append("Tip: lessons sparkline off reduces panel noise")
        lines.append("UI Scale: %d%% (settings scale|font 80..140 | + | - | reset)" % ui_scale_percent)
        lines.append("Compact Panels: %s (settings compact on|off|toggle)" % ("ON" if compact_panels else "OFF"))
        lines.append("Compact effect: hides lesson samples; trims history; caps wave list.")
        lines.append("Type: settings verify")
        lines.append("Type: bind <action>")
        lines.append("Type: bind <action> reset")
        lines.append(RebindableActions.format_actions_hint())
    settings_label.text = "\n".join(lines)
    _refresh_controls_text()
    _refresh_lessons_settings_text()

func _refresh_controls_text() -> void:
    if controls_text == null:
        return
    var actions: PackedStringArray = RebindableActions.actions()
    controls_text.text = ControlsFormatter.format_controls_list(actions)        

func _refresh_lessons_settings_text() -> void:
    if lessons_settings_text == null:
        return
    var sort_mode: String = TypingProfile.get_lessons_sort(profile)
    var sparkline_enabled: bool = TypingProfile.get_lessons_sparkline(profile)
    var lines: Array[String] = []
    lines.append("Lessons sort: %s" % sort_mode)
    lines.append("Sparklines: %s" % ("ON" if sparkline_enabled else "OFF"))
    lines.append(LessonHealth.legend_line())
    lines.append("Commands: lessons sort default|recent|name | lessons sparkline on|off")
    lines.append("Economy: Day %d+ stone catch-up on explores." % SimBalance.MIDGAME_STONE_CATCHUP_DAY)
    lines.append("Day %d+: low-food bonus + storage caps; explore yields soften." % SimBalance.MIDGAME_FOOD_BONUS_DAY)
    lines.append("See docs for details.")
    lessons_settings_text.text = "\n".join(lines)

func _maybe_log_economy_guardrails() -> void:
    if economy_note_shown:
        return
    var activate_day: int = min(SimBalance.MIDGAME_STONE_CATCHUP_DAY, SimBalance.MIDGAME_FOOD_BONUS_DAY)
    if state.day < activate_day:
        return
    economy_note_shown = true
    var update: Dictionary = TypingProfile.set_economy_note_shown(profile, true)
    profile = update.get("profile", profile)
    if not update.get("ok", true):
        _append_log(["Economy note save failed: %s" % str(update.get("error", "unknown error"))])
    _append_log([
        "Economy guardrails active: explore yields soften; low-food boost; stone catch-up. See Settings -> Economy."
    ])

func _refresh_lesson_panel() -> void:
    if lesson_panel == null or lesson_label == null:
        return
    lesson_panel.visible = lesson_visible
    if not lesson_visible:
        lesson_label.text = ""
        return
    var lesson_id: String = state.lesson_id
    var lesson: Dictionary = SimLessons.get_lesson(lesson_id)
    var lines: Array[String] = []
    lines.append("[b]Lesson Browser[/b]")
    lines.append("Active: %s (%s)" % [SimLessons.lesson_label(lesson_id), lesson_id])
    if compact_panels:
        lines.append(_lesson_active_trend_line(lesson_id))
        var compact_entry: Dictionary = _lesson_progress_entry(lesson_id)
        lines.append(_lesson_compact_progress_line(compact_entry))
        lines.append("Lessons:")
        var compact_ids: PackedStringArray = SimLessons.lesson_ids()
        var compact_lessons_by_id: Dictionary = {}
        var compact_data: Dictionary = SimLessons.load_data()
        if compact_data.get("ok", false):
            compact_lessons_by_id = compact_data.get("data", {}).get("by_id", {})
        compact_ids = LessonsSort.sort_ids(compact_ids, lesson_progress, lessons_sort_mode, compact_lessons_by_id)
        for entry_id in compact_ids:
            var entry_progress: Dictionary = _lesson_progress_entry(str(entry_id))
            var nights: int = int(entry_progress.get("nights", 0))
            var avg_acc: float = _safe_div(float(entry_progress.get("sum_accuracy", 0.0)), nights) * 100.0
            var marker: String = ">" if entry_id == lesson_id else " "
            lines.append("%s %s (%s) | nights %d | avg acc %.0f%%" % [
                marker,
                SimLessons.lesson_label(str(entry_id)),
                entry_id,
                nights,
                avg_acc
            ])
        lines.append("Use: lesson <id> | lesson next | lesson prev")
        lines.append("Use: lessons (toggle panel) | lessons reset [all]")
        lesson_label.text = "\n".join(lines)
        return
    var description: String = SimLessons.lesson_description(lesson_id)
    if description != "":
        lines.append(description)
    lines.append(_lesson_active_trend_line(lesson_id))
    var active_spark: String = _lesson_active_sparkline_line(lesson_id)
    if active_spark != "":
        lines.append(active_spark)
    lines.append("Sort: %s (use lessons sort default|recent|name)" % lessons_sort_mode)
    lines.append("Prefs: sort=%s, sparkline=%s" % [lessons_sort_mode, "on" if lessons_sparkline else "off"])
    if lesson.is_empty():
        lines.append("Lesson data unavailable.")
    else:
        var lengths: Dictionary = lesson.get("lengths", {})
        var scout_range: Array = lengths.get("scout", [])
        var raider_range: Array = lengths.get("raider", [])
        var armored_range: Array = lengths.get("armored", [])
        lines.append("Lengths: scout %s | raider %s | armored %s" % [
            _range_text(scout_range),
            _range_text(raider_range),
            _range_text(armored_range)
        ])
    lines.append("")
    lines.append_array(_lesson_progress_lines(lesson_id))
    lines.append("")
    lines.append("Samples:")
    var samples: Dictionary = _lesson_samples(lesson_id)
    for kind in ["scout", "raider", "armored"]:
        var words: Array = samples.get(kind, [])
        lines.append("%s: %s" % [kind, ", ".join(words)])
    lines.append("")
    lines.append("Lessons:")
    var lesson_ids: PackedStringArray = SimLessons.lesson_ids()
    var lessons_by_id: Dictionary = {}
    var lessons_data: Dictionary = SimLessons.load_data()
    if lessons_data.get("ok", false):
        lessons_by_id = lessons_data.get("data", {}).get("by_id", {})
    lesson_ids = LessonsSort.sort_ids(lesson_ids, lesson_progress, lessons_sort_mode, lessons_by_id)
    for entry_id in lesson_ids:
        var entry_progress: Dictionary = _lesson_progress_entry(str(entry_id))
        var nights: int = int(entry_progress.get("nights", 0))
        var avg_acc: float = _safe_div(float(entry_progress.get("sum_accuracy", 0.0)), nights) * 100.0
        var marker: String = ">" if entry_id == lesson_id else " "
        lines.append("%s %s (%s) | nights %d | avg acc %.0f%%" % [
            marker,
            SimLessons.lesson_label(str(entry_id)),
            entry_id,
            nights,
            avg_acc
        ])
    lines.append("Use: lesson <id> | lesson next | lesson prev | lesson sample [n]")
    lines.append("Use: lessons (toggle panel) | lessons reset [all]")
    lesson_label.text = "\n".join(lines)

func _lesson_progress_entry(lesson_id: String) -> Dictionary:
        if lesson_progress.has(lesson_id) and typeof(lesson_progress.get(lesson_id)) == TYPE_DICTIONARY:
                return TypingProfile.normalize_lesson_progress_entry(lesson_progress.get(lesson_id))
        return TypingProfile.default_lesson_progress_entry()

func _lesson_compact_progress_line(entry: Dictionary) -> String:
        var nights: int = int(entry.get("nights", 0))
        if nights <= 0:
                return "Progress: no nights completed yet."
        var avg_accuracy: float = _safe_div(float(entry.get("sum_accuracy", 0.0)), nights) * 100.0
        var best_accuracy: float = float(entry.get("best_accuracy", 0.0)) * 100.0
        var passes: int = int(entry.get("goal_passes", 0))
        var recent: Array = entry.get("recent", [])
        var has_delta: bool = recent is Array and recent.size() >= 2
        var score: int = LessonHealth.score_recent(recent)
        var health: String = LessonHealth.label_for_score(score, has_delta)
        return "Progress: nights %d | avg acc %.0f%% | best acc %.0f%% | goals %d | health %s" % [
                nights,
                avg_accuracy,
                best_accuracy,
                passes,
                health
        ]

func _lesson_progress_lines(lesson_id: String) -> Array[String]:
    var entry: Dictionary = _lesson_progress_entry(lesson_id)
    var nights: int = int(entry.get("nights", 0))
    var lines: Array[String] = []
    if nights <= 0:
        lines.append("Progress: no nights completed yet.")
        lines.append("Last3: --")
        lines.append("Recent (last 3): --")
        return lines
    var avg_accuracy: float = _safe_div(float(entry.get("sum_accuracy", 0.0)), nights) * 100.0
    var avg_hit: float = _safe_div(float(entry.get("sum_hit_rate", 0.0)), nights) * 100.0
    var avg_backspace: float = _safe_div(float(entry.get("sum_backspace_rate", 0.0)), nights) * 100.0
    var best_accuracy: float = float(entry.get("best_accuracy", 0.0)) * 100.0
    var best_hit: float = float(entry.get("best_hit_rate", 0.0)) * 100.0
    var passes: int = int(entry.get("goal_passes", 0))
    var last_day: int = int(entry.get("last_day", 0))
    lines.append("Progress: nights %d | goal passes %d | avg acc %.0f%% | avg hit %.0f%% | avg back %.0f%% | best acc %.0f%% | best hit %.0f%% | last day %d" % [
        nights,
        passes,
        avg_accuracy,
        avg_hit,
        avg_backspace,
        best_accuracy,
        best_hit,
        last_day
    ])
    lines.append(_lesson_mini_trend_line(entry))
    var sparkline: String = _lesson_sparkline_line(entry)
    if sparkline != "":
        lines.append(sparkline)
    lines.append_array(_format_lesson_recent(entry))
    return lines

func _format_lesson_recent(entry: Dictionary) -> Array[String]:
    var recent: Array = entry.get("recent", [])
    var lines: Array[String] = []
    if not (recent is Array) or recent.is_empty():
        lines.append("Recent (last 3): --")
        return lines
    lines.append("Recent (last 3):")
    var count: int = min(3, recent.size())
    for i in range(count):
        if typeof(recent[i]) != TYPE_DICTIONARY:
            continue
        var rec: Dictionary = recent[i]
        var entry_text: String = TypingProfile.format_recent_entry(rec)
        if entry_text != "":
            lines.append("  %s" % entry_text)
    return lines

func _lesson_mini_trend_line(entry: Dictionary) -> String:
    var recent: Array = entry.get("recent", [])
    var trend: Dictionary = MiniTrend.format_last3_delta(recent)
    if not bool(trend.get("has_delta", false)):
        return "Last3: --"
    if recent.is_empty() or typeof(recent[0]) != TYPE_DICTIONARY:
        return "Last3: --"
    var newest: Dictionary = recent[0]
    var acc_value: float = float(newest.get("avg_accuracy", 0.0))
    var hit_value: float = float(newest.get("hit_rate", 0.0))
    var back_value: float = float(newest.get("backspace_rate", 0.0))
    var acc_d: float = float(trend.get("acc_d", 0.0))
    var hit_d: float = float(trend.get("hit_d", 0.0))
    var back_d: float = float(trend.get("back_d", 0.0))
    var acc_arrow: String = str(trend.get("acc_arrow", ""))
    var hit_arrow: String = str(trend.get("hit_arrow", ""))
    var back_arrow: String = str(trend.get("back_arrow", ""))
    var acc_text: String = MiniTrend.format_compact_badge(acc_value, acc_arrow, false)
    var hit_text: String = MiniTrend.format_compact_badge(hit_value, hit_arrow, true)
    var back_text: String = MiniTrend.format_compact_badge(back_value, back_arrow, true)
    var acc_delta: String = _format_delta_value(acc_d, false)
    var hit_delta: String = _format_delta_value(hit_d, true)
    var back_delta: String = _format_delta_value(back_d, true)
    var acc_marker: String = _metric_marker(acc_d, false)
    var hit_marker: String = _metric_marker(hit_d, false)
    var back_marker: String = _metric_marker(back_d, true)
    var trend_status: String = _trend_status(acc_d, hit_d, back_d)
    return "Last3: acc %s (%s)%s | hit %s (%s)%s | back %s (%s)%s | Trend: %s" % [
        acc_text,
        acc_delta,
        acc_marker,
        hit_text,
        hit_delta,
        hit_marker,
        back_text,
        back_delta,
        back_marker,
        trend_status
    ]

func _lesson_active_trend_line(lesson_id: String) -> String:
    var entry: Dictionary = _lesson_progress_entry(lesson_id)
    var trend_line: String = _lesson_mini_trend_line(entry)
    if trend_line.begins_with("Last3:"):
        return "Active %s" % trend_line
    return trend_line

func _lesson_active_sparkline_line(lesson_id: String) -> String:
    if not lessons_sparkline:
        return ""
    var entry: Dictionary = _lesson_progress_entry(lesson_id)
    var line: String = _lesson_sparkline_line(entry)
    if line == "":
        return ""
    return line.replace("Spark:", "Active Spark:")

func _lesson_sparkline_line(entry: Dictionary) -> String:
    if not lessons_sparkline:
        return ""
    var recent: Array = entry.get("recent", [])
    if not (recent is Array) or recent.is_empty():
        return ""
    var acc_line: String = MiniTrend.sparkline_from_recent(recent, "avg_accuracy", 3)
    var hit_line: String = MiniTrend.sparkline_from_recent(recent, "hit_rate", 3)
    var back_line: String = MiniTrend.sparkline_from_recent(recent, "backspace_rate", 3)
    return "Spark: acc %s | hit %s | back %s" % [acc_line, hit_line, back_line]

func _format_delta_value(value: float, pct: bool) -> String:
    var sign: String = "+" if value >= 0.0 else "-"
    var magnitude: float = abs(value)
    if pct:
        return "%s%d%%" % [sign, int(round(magnitude * 100.0))]
    return "%s%.2f" % [sign, magnitude]

func _metric_marker(delta: float, invert_good: bool) -> String:
    var eps: float = 0.01
    if invert_good:
        if delta < -eps:
            return " (GOOD)"
        if delta > eps:
            return " (WARN)"
        return ""
    if delta > eps:
        return " (GOOD)"
    if delta < -eps:
        return " (WARN)"
    return ""

func _trend_status(acc_d: float, hit_d: float, back_d: float) -> String:
    var eps: float = 0.01
    var score: int = 0
    if acc_d > eps:
        score += 1
    if hit_d > eps:
        score += 1
    if back_d < -eps:
        score += 1
    if score >= 2:
        return "GOOD"
    if score <= 0:
        return "WARN"
    return "OK"

func _lesson_samples(lesson_id: String) -> Dictionary:
    var used: Dictionary = {}
    var samples: Dictionary = {}
    for kind in ["scout", "raider", "armored"]:
        var words: Array[String] = []
        for i in range(3):
            var word: String = SimWords.word_for_enemy("lesson-sample", 1, kind, i + 1, used, lesson_id)
            if word != "":
                words.append(word)
                used[word] = true
        if words.is_empty():
            words.append("n/a")
        samples[kind] = words
    return samples

func _range_text(value: Array) -> String:
    if value is Array and value.size() >= 2:
        return "%d-%d" % [int(value[0]), int(value[1])]
    return "?"

func _safe_div(numerator: float, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return numerator / float(denominator)

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
        return KeybindConflicts.keybind_from_event(event)

func _keybind_from_text(text: String) -> Dictionary:
        return KeybindConflicts.keybind_from_text(text)

func _format_keybind_text(keybind: Dictionary) -> String:
        var text: String = KeybindConflicts.keybind_to_text(keybind)
        if text == "":
                return "Unbound"
        return text

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
    var lesson_line: String = "Lesson: %s (%s)" % [SimLessons.lesson_label(state.lesson_id), state.lesson_id]
    var header_text: String = "%s\n%s" % [header, lesson_line]
    if last_report_text == "":
        report_label.text = "%s\nNo report available yet." % header_text
    else:
        report_label.text = "%s\n%s" % [header_text, last_report_text]

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

func _apply_lessons_toggle() -> void:
    lesson_visible = not lesson_visible
    var state_text: String = "ON" if lesson_visible else "OFF"
    _append_log(["Lessons panel: %s" % state_text])
    _refresh_lesson_panel()
    _advance_onboarding("ui_lessons_toggle", [], state.phase, state.phase)
    command_bar.grab_focus()

func _apply_lessons_reset(intent: Dictionary) -> void:
    var scope: String = str(intent.get("scope", "current"))
    if scope == "all":
        lesson_progress = TypingProfile.default_lesson_progress_map()
        _append_log(["Lesson progress reset for all lessons."])
    else:
        lesson_progress = TypingProfile.reset_lesson_progress(lesson_progress, state.lesson_id)
        _append_log(["Lesson progress reset for %s (%s)." % [SimLessons.lesson_label(state.lesson_id), state.lesson_id]])
    _persist_profile()
    _refresh_lesson_panel()
    _refresh_settings_panel()
    command_bar.grab_focus()

func _apply_lessons_sort(intent: Dictionary) -> void:
    var mode: String = str(intent.get("mode", "")).to_lower()
    if mode == "" or mode == "show":
        _append_log(["Lessons sort: %s" % lessons_sort_mode, "Use: lessons sort default|recent|name"])
        command_bar.grab_focus()
        return
    if mode != "default" and mode != "recent" and mode != "name":
        _append_log(["Unknown lessons sort mode: %s" % mode, "Use: lessons sort default|recent|name"])
        command_bar.grab_focus()
        return
    lessons_sort_mode = mode
    var result: Dictionary = TypingProfile.set_lessons_sort(profile, lessons_sort_mode)
    profile = result.get("profile", profile)
    if not result.get("ok", true):
        _append_log(["Lessons sort update failed: %s" % str(result.get("error", "unknown error"))])
    _append_log(["Lessons sort: %s" % lessons_sort_mode])
    _refresh_lesson_panel()
    _refresh_lesson_health()
    _refresh_settings_panel()
    command_bar.grab_focus()

func _apply_lessons_sparkline(intent: Dictionary) -> void:
    var mode: String = str(intent.get("mode", "")).to_lower()
    if mode == "" or mode == "show":
        var state_text: String = "ON" if lessons_sparkline else "OFF"
        _append_log(["Lessons sparkline: %s" % state_text, "Use: lessons sparkline on|off"])
        command_bar.grab_focus()
        return
    if intent.has("enabled"):
        lessons_sparkline = bool(intent.get("enabled", lessons_sparkline))
    else:
        _append_log(["Use: lessons sparkline on|off"])
        command_bar.grab_focus()
        return
    var result: Dictionary = TypingProfile.set_lessons_sparkline(profile, lessons_sparkline)
    profile = result.get("profile", profile)
    if not result.get("ok", true):
        _append_log(["Lessons sparkline update failed: %s" % str(result.get("error", "unknown error"))])
    var enabled_text: String = "ON" if lessons_sparkline else "OFF"
    _append_log(["Lessons sparkline: %s" % enabled_text])
    _refresh_lesson_panel()
    _refresh_lesson_health()
    _refresh_settings_panel()
    command_bar.grab_focus()

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
    preferred_lesson = TypingProfile.get_lesson(profile)
    profile["preferred_lesson"] = preferred_lesson
    if state != null:
        state.lesson_id = preferred_lesson
    lesson_progress = TypingProfile.get_lesson_progress_map(profile)
    profile["lesson_progress"] = lesson_progress
    lessons_sort_mode = TypingProfile.get_lessons_sort(profile)
    lessons_sparkline = TypingProfile.get_lessons_sparkline(profile)
    ui_scale_percent = TypingProfile.get_ui_scale_percent(profile)
    compact_panels = TypingProfile.get_compact_panels(profile)
    profile["ui_prefs"] = profile.get("ui_prefs", {})
    profile["ui_prefs"]["lessons_sort"] = lessons_sort_mode
    profile["ui_prefs"]["lessons_sparkline"] = lessons_sparkline
    profile["ui_prefs"]["ui_scale_percent"] = ui_scale_percent
    profile["ui_prefs"]["compact_panels"] = compact_panels
    economy_note_shown = TypingProfile.get_economy_note_shown(profile)
    profile["ui_prefs"]["economy_note_shown"] = economy_note_shown
    onboarding = TypingProfile.get_onboarding(profile)
    profile["ui_prefs"]["onboarding"] = onboarding
    tutorial_visible = bool(onboarding.get("enabled", true)) and not bool(onboarding.get("completed", false))
    if bool(onboarding.get("enabled", true)) and not bool(onboarding.get("completed", false)) and not bool(onboarding.get("ever_shown", false)):
        onboarding["ever_shown"] = true
        tutorial_visible = true
        var onboarding_result: Dictionary = TypingProfile.set_onboarding(profile, onboarding)
        profile = onboarding_result.get("profile", profile)
        onboarding = TypingProfile.get_onboarding(profile)
        if not onboarding_result.get("ok", true):
            _append_log(["Onboarding save failed: %s" % str(onboarding_result.get("error", "unknown error"))])
        _append_log(["Tutorial is ON. Type 'tutorial' to hide/show."])
    _apply_profile_keybinds()
    _log_startup_keybind_conflicts()
    _apply_ui_scale(ui_scale_percent)
    _refresh_controls_text()
    _refresh_history_panel()
    _refresh_trend_panel()
    _refresh_goal_legend()
    _refresh_settings_panel()

func _apply_ui_scale(scale_percent: int) -> void:
        ui_scale_percent = TypingProfile.get_ui_scale_percent({"ui_prefs": {"ui_scale_percent": scale_percent}})
        var scale_factor: float = float(ui_scale_percent) / 100.0
        var window: Window = get_window()
        if window != null:
                var has_scale_factor: bool = false
                var has_scale_mode: bool = false
                for prop in window.get_property_list():
                        var prop_name: String = str(prop.get("name", ""))
                        if prop_name == "content_scale_factor":
                                has_scale_factor = true
                        elif prop_name == "content_scale_mode":
                                has_scale_mode = true
                if has_scale_factor:
                        window.content_scale_factor = scale_factor
                        if has_scale_mode:
                                window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
                        return
        if ui_root == null:
                return
        ui_root.pivot_offset = Vector2.ZERO
        ui_root.scale = Vector2(scale_factor, scale_factor)
        var viewport_size: Vector2 = get_viewport_rect().size
        ui_root.position = Vector2.ZERO
        ui_root.size = viewport_size / scale_factor

func _apply_profile_keybinds() -> void:
    for action_name in RebindableActions.actions():
        var keybind: Dictionary = TypingProfile.get_keybind(profile, action_name)
        _set_cached_keybind(action_name, keybind)
        _apply_keybind(action_name, keybind)

func _persist_profile() -> void:
        profile["typing_history"] = typing_history
        profile["lifetime"] = lifetime
        profile["practice_goal"] = current_goal
        profile["preferred_lesson"] = preferred_lesson
        profile["lesson_progress"] = lesson_progress
        profile["ui_prefs"] = profile.get("ui_prefs", {})
        profile["ui_prefs"]["lessons_sort"] = lessons_sort_mode
        profile["ui_prefs"]["lessons_sparkline"] = lessons_sparkline
        profile["ui_prefs"]["onboarding"] = onboarding
        profile["ui_prefs"]["economy_note_shown"] = economy_note_shown
        profile["ui_prefs"]["ui_scale_percent"] = ui_scale_percent
        profile["ui_prefs"]["compact_panels"] = compact_panels
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
    _update_lesson_progress(report)
    _persist_profile()
    _refresh_history_panel()
    _refresh_trend_panel()
    _refresh_lesson_panel()
    _refresh_lesson_health()

func _update_lesson_progress(report: Dictionary) -> void:
    var thresholds: Dictionary = PracticeGoals.thresholds(current_goal)
    var goal_met: bool = SimTypingTrends.report_meets_goal(report, thresholds)
    lesson_progress = TypingProfile.update_lesson_progress(lesson_progress, state.lesson_id, report, goal_met)

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
    var max_entries: int = 3 if compact_panels else 5
    var shown: int = min(typing_history.size(), max_entries)
    lines.append("Typing History (last %d)" % shown)
    var thresholds: Dictionary = PracticeGoals.thresholds(current_goal)
    var start: int = max(0, typing_history.size() - max_entries)
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
    var history_source: Array = typing_history
    if compact_panels and typing_history.size() > 3:
        history_source = typing_history.slice(typing_history.size() - 3, typing_history.size())
    var summary: Dictionary = SimTypingTrends.summarize(history_source, current_goal)
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
    if compact_panels:
        lines.append(SimTypingTrends.format_trend_text(summary))
        trend_label.text = "\n".join(lines)
        return
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
                var loaded_lesson: String = str(load_result.state.lesson_id)
                if loaded_lesson != "":
                    var lesson_update: Dictionary = TypingProfile.set_lesson(profile, loaded_lesson)
                    profile = lesson_update.get("profile", profile)
                    preferred_lesson = TypingProfile.get_lesson(profile)
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
        var max_enemies: int = 5 if compact_panels else entries.size()
        var shown: int = min(entries.size(), max_enemies)
        for i in range(shown):
            var entry: Dictionary = entries[i]
            var entry_pos: Vector2i = entry.get("pos", Vector2i.ZERO)
            var entry_id: int = int(entry.get("id", 0))
            var is_candidate: bool = candidate_lookup.has(entry_id)
            var is_exact: bool = entry_id == exact_id
            var marker: String = "> " if entry_id == typing_focus_id else "  "
            var word_text: String = _format_wave_word(str(entry.get("word", "")), typed, is_candidate, is_exact)
            var ready_suffix: String = " [READY]" if is_exact else ""
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
            if not compact_panels:
                var bar_text: String = _format_progress_bar(str(entry.get("word", "")), typed, is_candidate, is_exact)
                lines.append("    %s" % bar_text)
        if entries.size() > shown:
            lines.append("  (+%d more)" % (entries.size() - shown))
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

