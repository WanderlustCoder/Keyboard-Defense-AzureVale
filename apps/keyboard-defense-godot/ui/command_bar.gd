extends LineEdit

signal command_submitted(command: String)
signal input_changed(text: String)

var history: Array[String] = []
var history_index: int = 0

func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
    text_submitted.connect(_on_text_submitted)
    text_changed.connect(_on_text_changed)
    set_process_unhandled_key_input(true)
    grab_focus()

func _on_text_submitted(submitted: String) -> void:
    emit_signal("command_submitted", submitted)

func _on_text_changed(new_text: String) -> void:
    emit_signal("input_changed", new_text)

func accept_submission(entry: String) -> void:
    var trimmed: String = entry.strip_edges()
    if trimmed.is_empty():
        return
    history.append(trimmed)
    history_index = history.size()
    clear()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
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
