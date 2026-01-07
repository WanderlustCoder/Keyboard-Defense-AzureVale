extends RefCounted
class_name ControlsFormatter
const RebindableActions = preload("res://game/rebindable_actions.gd")
const ControlsAliases = preload("res://game/controls_aliases.gd")

static func keybind_from_event(event: InputEventKey) -> Dictionary:
    if event == null:
        return {}
    return {
        "keycode": event.keycode,
        "shift": event.shift_pressed,
        "alt": event.alt_pressed,
        "ctrl": event.ctrl_pressed,
        "meta": event.meta_pressed
    }

static func event_from_keybind(keybind: Dictionary) -> InputEventKey:
    var keycode: int = int(keybind.get("keycode", 0))
    if keycode <= 0:
        return null
    var event := InputEventKey.new()
    event.keycode = keycode
    event.physical_keycode = keycode
    event.shift_pressed = bool(keybind.get("shift", false))
    event.alt_pressed = bool(keybind.get("alt", false))
    event.ctrl_pressed = bool(keybind.get("ctrl", false))
    event.meta_pressed = bool(keybind.get("meta", false))
    return event

static func key_text_from_event(event: InputEventKey) -> String:
    if event == null:
        return ""
    if int(event.keycode) <= 0:
        return ""
    return _format_key_event(event)

static func keybind_to_text(keybind: Dictionary) -> String:
    var event: InputEventKey = event_from_keybind(keybind)
    if event == null:
        return ""
    return key_text_from_event(event)

static func canonicalize_key_text(text: String) -> String:
    var event: InputEventKey = event_from_text(text)
    if event == null:
        return ""
    return key_text_from_event(event)

static func event_from_text(text: String) -> InputEventKey:
    var keybind: Dictionary = keybind_from_text(text)
    if keybind.is_empty():
        return null
    return event_from_keybind(keybind)

static func keybind_from_text(text: String) -> Dictionary:
    var parsed: Dictionary = parse_key_text(text)
    if not bool(parsed.get("ok", false)):
        return {}
    var keybind: Variant = parsed.get("keybind", {})
    if typeof(keybind) != TYPE_DICTIONARY:
        return {}
    return keybind

static func parse_key_text(text: String) -> Dictionary:
    var result := {"ok": false, "keybind": {}, "error": ""}
    var normalized: String = text.strip_edges()
    if normalized == "":
        result["error"] = "Expected a key name."
        return result
    var parts: PackedStringArray = normalized.split("+", true)
    var key_token: String = ""
    var event := InputEventKey.new()
    for part in parts:
        var token: String = part.strip_edges()
        if token == "":
            result["error"] = "Invalid key string."
            return result
        var normalized_token: String = ControlsAliases.normalize_token(token)
        if normalized_token == "":
            result["error"] = "Invalid key string."
            return result
        if ControlsAliases.is_modifier_token(normalized_token):
            ControlsAliases.apply_modifier_token(event, normalized_token)
            continue
        if key_token != "":
            result["error"] = "Multiple keys specified."
            return result
        key_token = token
    if key_token == "":
        result["error"] = "Expected a key name."
        return result
    var keycode: int = keycode_from_text(key_token)
    if keycode <= 0:
        result["error"] = "Unknown key."
        return result
    result["ok"] = true
    result["keybind"] = {
        "keycode": keycode,
        "shift": event.shift_pressed,
        "alt": event.alt_pressed,
        "ctrl": event.ctrl_pressed,
        "meta": event.meta_pressed
    }
    return result

static func keycode_from_text(text: String) -> int:
    var key_name: String = text.strip_edges()
    if key_name == "":
        return 0
    var normalized: String = ControlsAliases.normalize_token(key_name)
    if normalized == "":
        return 0
    var alias_code: int = ControlsAliases.keycode_from_token(normalized)
    if alias_code > 0:
        return alias_code
    var upper: String = key_name.to_upper()
    if OS.has_method("find_keycode_from_string"):
        var found: int = int(OS.find_keycode_from_string(upper))
        if found > 0:
            return found
        if normalized != upper:
            found = int(OS.find_keycode_from_string(normalized))
            if found > 0:
                return found
    if normalized.length() == 1:
        return normalized.unicode_at(0)
    return 0

static func binding_text_for_action(action_name: String) -> String:
    if not InputMap.has_action(action_name):
        return "Missing (InputMap)"
    var events: Array = InputMap.action_get_events(action_name)
    if events.is_empty():
        return "Unbound"
    var parts: Array[String] = []
    for event in events:
        if event is InputEventKey:
            var label: String = key_text_from_event(event)
            if label != "":
                parts.append(label)
        else:
            var label_other: String = event.as_text()
            if label_other != "":
                parts.append(label_other)
    if parts.is_empty():
        return "Unbound"
    return " / ".join(parts)

static func format_controls_list(actions: PackedStringArray) -> String:
    if actions.is_empty():
        return "No controls available."
    var labels: Array[String] = []
    var max_len: int = 0
    for action_name in actions:
        var display_name: String = RebindableActions.display_name(action_name)
        var label_text: String = "%s (%s):" % [display_name, action_name]
        labels.append(label_text)
        max_len = max(max_len, label_text.length())
    var pad: int = max(12, max_len)
    var lines: Array[String] = []
    for index in range(actions.size()):
        var action_name: String = actions[index]
        var binding: String = binding_text_for_action(action_name)
        var label: String = labels[index]
        label = label.rpad(pad + 1, " ")
        lines.append("%s %s" % [label, binding])
    return "\n".join(lines)

static func _format_key_event(event: InputEventKey) -> String:
    var parts: Array[String] = []
    if event.ctrl_pressed:
        parts.append("Ctrl")
    if event.alt_pressed:
        parts.append("Alt")
    if event.shift_pressed:
        parts.append("Shift")
    if event.meta_pressed:
        parts.append("Meta")
    var key_text: String = OS.get_keycode_string(event.keycode)
    if key_text == "":
        key_text = str(event.keycode)
    parts.append(key_text)
    return "+".join(parts)
