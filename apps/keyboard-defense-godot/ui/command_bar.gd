extends LineEdit

signal command_submitted(command: String)
signal input_changed(text: String)

const HISTORY_BG_COLOR := Color(0.15, 0.18, 0.25, 1.0)  # Slightly blue tint when browsing history
const NORMAL_BG_COLOR := Color(0.1, 0.1, 0.12, 1.0)
const ERROR_BG_COLOR := Color(0.35, 0.1, 0.1, 1.0)  # Red tint for errors

# Error shake animation
const ERROR_SHAKE_DURATION := 0.25
const ERROR_SHAKE_INTENSITY := 6.0
const ERROR_SHAKE_FREQUENCY := 30.0

# Autocomplete popup settings
const AUTOCOMPLETE_MAX_ITEMS := 6
const AUTOCOMPLETE_ITEM_HEIGHT := 24
const AUTOCOMPLETE_BG_COLOR := Color(0.12, 0.14, 0.18, 0.95)
const AUTOCOMPLETE_SELECTED_COLOR := Color(0.25, 0.35, 0.5, 1.0)
const AUTOCOMPLETE_TEXT_COLOR := Color(0.85, 0.9, 0.95, 1.0)
const AUTOCOMPLETE_DIM_COLOR := Color(0.5, 0.55, 0.6, 0.8)

# Known commands for autocomplete
var _known_commands: Array[String] = [
    "help", "status", "gather", "build", "explore", "end", "wait",
    "lessons", "settings", "tutorial", "goal", "history", "trend",
    "bind", "preview", "overlay", "report", "version", "balance"
]

var history: Array[String] = []
var history_index: int = 0
var _history_label: Label = null
var _normal_style: StyleBoxFlat = null
var _history_style: StyleBoxFlat = null
var _error_style: StyleBoxFlat = null
var _base_position: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null
var _flash_tween: Tween = null
var _audio_manager = null
var _settings_manager = null

# Autocomplete state
var _autocomplete_popup: PanelContainer = null
var _autocomplete_list: VBoxContainer = null
var _autocomplete_items: Array[Label] = []
var _autocomplete_matches: Array[String] = []
var _autocomplete_selected: int = -1
var _autocomplete_visible: bool = false

func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
    text_submitted.connect(_on_text_submitted)
    text_changed.connect(_on_text_changed)
    set_process_unhandled_key_input(true)
    _setup_history_indicator()
    _setup_error_style()
    _setup_autocomplete_popup()
    _base_position = position
    _audio_manager = get_node_or_null("/root/AudioManager")
    _settings_manager = get_node_or_null("/root/SettingsManager")
    grab_focus()

func _on_text_submitted(submitted: String) -> void:
    emit_signal("command_submitted", submitted)

func _on_text_changed(new_text: String) -> void:
    emit_signal("input_changed", new_text)
    _update_autocomplete(new_text)

func accept_submission(entry: String) -> void:
    var trimmed: String = entry.strip_edges()
    if trimmed.is_empty():
        return
    history.append(trimmed)
    history_index = history.size()
    clear()
    _clear_history_indicator()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        # Handle Tab for autocomplete
        if event.keycode == KEY_TAB:
            if _autocomplete_visible and not _autocomplete_matches.is_empty():
                _apply_autocomplete()
                accept_event()
                return

        # Handle Escape to close autocomplete
        if event.keycode == KEY_ESCAPE:
            if _autocomplete_visible:
                _hide_autocomplete()
                accept_event()
                return

        # Handle Up/Down for autocomplete selection when visible
        if _autocomplete_visible and not _autocomplete_matches.is_empty():
            if event.keycode == KEY_UP:
                _autocomplete_selected = max(0, _autocomplete_selected - 1)
                _update_autocomplete_selection()
                accept_event()
                return
            elif event.keycode == KEY_DOWN:
                _autocomplete_selected = min(_autocomplete_matches.size() - 1, _autocomplete_selected + 1)
                _update_autocomplete_selection()
                accept_event()
                return

        # Normal history navigation when autocomplete is not active
        if event.keycode == KEY_UP:
            _history_prev()
            accept_event()
        elif event.keycode == KEY_DOWN:
            _history_next()
            accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
    if has_focus():
        return
    if event is InputEventKey and event.pressed and not event.echo:
        grab_focus()

func _history_prev() -> void:
    if history.is_empty():
        return
    if history_index > 0:
        history_index -= 1
    text = history[history_index]
    caret_column = text.length()
    _update_history_indicator()

func _history_next() -> void:
    if history.is_empty():
        return
    if history_index < history.size() - 1:
        history_index += 1
        text = history[history_index]
    else:
        history_index = history.size()
        text = ""
    caret_column = text.length()
    _update_history_indicator()

func _setup_history_indicator() -> void:
    # Create styles for normal and history browsing modes
    _normal_style = StyleBoxFlat.new()
    _normal_style.bg_color = NORMAL_BG_COLOR
    _normal_style.border_color = Color(0.3, 0.35, 0.45, 1.0)
    _normal_style.set_border_width_all(1)
    _normal_style.set_corner_radius_all(4)
    _normal_style.set_content_margin_all(8)

    _history_style = StyleBoxFlat.new()
    _history_style.bg_color = HISTORY_BG_COLOR
    _history_style.border_color = Color(0.4, 0.5, 0.7, 1.0)  # Blue border when in history
    _history_style.set_border_width_all(2)
    _history_style.set_corner_radius_all(4)
    _history_style.set_content_margin_all(8)

    add_theme_stylebox_override("normal", _normal_style)

    # Create history position label (right-aligned inside the input)
    _history_label = Label.new()
    _history_label.add_theme_font_size_override("font_size", 10)
    _history_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8, 0.8))
    _history_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _history_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _history_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
    _history_label.offset_left = -60
    _history_label.offset_right = -8
    _history_label.visible = false
    add_child(_history_label)

func _update_history_indicator() -> void:
    var in_history := history_index < history.size()
    if in_history:
        add_theme_stylebox_override("normal", _history_style)
        if _history_label != null:
            _history_label.text = "↑%d/%d" % [history_index + 1, history.size()]
            _history_label.visible = true
    else:
        add_theme_stylebox_override("normal", _normal_style)
        if _history_label != null:
            _history_label.visible = false

func _clear_history_indicator() -> void:
    add_theme_stylebox_override("normal", _normal_style)
    if _history_label != null:
        _history_label.visible = false

func _setup_error_style() -> void:
    _error_style = StyleBoxFlat.new()
    _error_style.bg_color = ERROR_BG_COLOR
    _error_style.border_color = Color(0.8, 0.2, 0.2, 1.0)  # Red border
    _error_style.set_border_width_all(2)
    _error_style.set_corner_radius_all(4)
    _error_style.set_content_margin_all(8)

## Call this when an invalid command is entered
func show_error_feedback() -> void:
    _flash_error()
    _shake_error()
    if _audio_manager != null and _audio_manager.has_method("play_error"):
        _audio_manager.play_error()

func _flash_error() -> void:
    # Kill existing flash
    if _flash_tween != null and _flash_tween.is_valid():
        _flash_tween.kill()

    # Apply error style
    add_theme_stylebox_override("normal", _error_style)

    # Fade back to normal
    _flash_tween = create_tween()
    _flash_tween.tween_interval(0.15)
    _flash_tween.tween_callback(_restore_normal_style)

func _restore_normal_style() -> void:
    var in_history := history_index < history.size()
    if in_history:
        add_theme_stylebox_override("normal", _history_style)
    else:
        add_theme_stylebox_override("normal", _normal_style)

func _shake_error() -> void:
    # Check reduced motion
    if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
        if _settings_manager.reduced_motion:
            return

    # Kill existing shake
    if _shake_tween != null and _shake_tween.is_valid():
        _shake_tween.kill()

    # Store base position if not set
    if _base_position == Vector2.ZERO:
        _base_position = position

    _shake_tween = create_tween()
    var elapsed := 0.0
    var steps := int(ERROR_SHAKE_DURATION * 60)  # ~60 fps

    for i in range(steps):
        var t := float(i) / float(steps)
        var decay := 1.0 - t
        var offset_x := sin(t * ERROR_SHAKE_FREQUENCY) * ERROR_SHAKE_INTENSITY * decay
        _shake_tween.tween_property(self, "position:x", _base_position.x + offset_x, ERROR_SHAKE_DURATION / float(steps))

    # Return to base position
    _shake_tween.tween_property(self, "position:x", _base_position.x, 0.02)

func _setup_autocomplete_popup() -> void:
    _autocomplete_popup = PanelContainer.new()
    _autocomplete_popup.name = "AutocompletePopup"

    var style := StyleBoxFlat.new()
    style.bg_color = AUTOCOMPLETE_BG_COLOR
    style.border_color = Color(0.3, 0.4, 0.55, 1.0)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    style.set_content_margin_all(4)
    _autocomplete_popup.add_theme_stylebox_override("panel", style)

    _autocomplete_list = VBoxContainer.new()
    _autocomplete_list.add_theme_constant_override("separation", 2)
    _autocomplete_popup.add_child(_autocomplete_list)

    # Create item labels
    for i in range(AUTOCOMPLETE_MAX_ITEMS):
        var label := Label.new()
        label.add_theme_font_size_override("font_size", 12)
        label.add_theme_color_override("font_color", AUTOCOMPLETE_TEXT_COLOR)
        label.custom_minimum_size = Vector2(0, AUTOCOMPLETE_ITEM_HEIGHT)
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.visible = false
        _autocomplete_list.add_child(label)
        _autocomplete_items.append(label)

    _autocomplete_popup.visible = false
    add_child(_autocomplete_popup)

func _update_autocomplete(input_text: String) -> void:
    var trimmed := input_text.strip_edges().to_lower()

    # Only show autocomplete for first word and minimum 1 character
    if trimmed.is_empty() or " " in trimmed:
        _hide_autocomplete()
        return

    # Find matching commands
    _autocomplete_matches.clear()
    for cmd in _known_commands:
        if cmd.begins_with(trimmed) and cmd != trimmed:
            _autocomplete_matches.append(cmd)
        if _autocomplete_matches.size() >= AUTOCOMPLETE_MAX_ITEMS:
            break

    if _autocomplete_matches.is_empty():
        _hide_autocomplete()
        return

    # Update popup items
    for i in range(_autocomplete_items.size()):
        var label: Label = _autocomplete_items[i]
        if i < _autocomplete_matches.size():
            var cmd: String = _autocomplete_matches[i]
            var remaining: int = cmd.length() - trimmed.length()
            label.text = "  %s  (+%d)" % [cmd, remaining]
            label.visible = true
        else:
            label.visible = false

    # Reset selection
    _autocomplete_selected = 0
    _update_autocomplete_selection()

    # Position popup below input
    _autocomplete_popup.position = Vector2(0, size.y + 2)
    _autocomplete_popup.custom_minimum_size = Vector2(size.x, 0)
    _autocomplete_popup.visible = true
    _autocomplete_visible = true

func _update_autocomplete_selection() -> void:
    for i in range(_autocomplete_items.size()):
        var label: Label = _autocomplete_items[i]
        if i == _autocomplete_selected:
            # Highlight selected item
            var style: StyleBoxFlat = StyleBoxFlat.new()
            style.bg_color = AUTOCOMPLETE_SELECTED_COLOR
            style.set_corner_radius_all(2)
            label.add_theme_stylebox_override("normal", style)
            label.add_theme_color_override("font_color", Color.WHITE)
        else:
            # Remove highlight
            label.remove_theme_stylebox_override("normal")
            label.add_theme_color_override("font_color", AUTOCOMPLETE_TEXT_COLOR)

func _apply_autocomplete() -> void:
    if _autocomplete_selected < 0 or _autocomplete_selected >= _autocomplete_matches.size():
        return

    var selected_cmd: String = _autocomplete_matches[_autocomplete_selected]
    text = selected_cmd + " "
    caret_column = text.length()
    _hide_autocomplete()

func _hide_autocomplete() -> void:
    if _autocomplete_popup != null:
        _autocomplete_popup.visible = false
    _autocomplete_visible = false
    _autocomplete_selected = -1
    _autocomplete_matches.clear()
