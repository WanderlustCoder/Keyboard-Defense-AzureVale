extends RefCounted
class_name ControlsAliases

const MODIFIER_ALIASES := {
    "CTRL": "ctrl",
    "CONTROL": "ctrl",
    "ALT": "alt",
    "OPTION": "alt",
    "SHIFT": "shift",
    "META": "meta",
    "CMD": "meta",
    "COMMAND": "meta",
    "SUPER": "meta",
    "WIN": "meta",
    "WINDOWS": "meta"
}

const KEY_ALIASES := {
    "INS": KEY_INSERT,
    "INSERT": KEY_INSERT,
    "DEL": KEY_DELETE,
    "DELETE": KEY_DELETE,
    "HOME": KEY_HOME,
    "END": KEY_END,
    "PAGEUP": KEY_PAGEUP,
    "PGUP": KEY_PAGEUP,
    "PAGEDOWN": KEY_PAGEDOWN,
    "PGDN": KEY_PAGEDOWN,
    "PRINTSCREEN": KEY_PRINT,
    "PRTSC": KEY_PRINT,
    "PRTSCN": KEY_PRINT,
    "PRINT": KEY_PRINT,
    "SCROLLLOCK": KEY_SCROLLLOCK,
    "SCRLK": KEY_SCROLLLOCK,
    "PAUSE": KEY_PAUSE,
    "PAUSEBREAK": KEY_PAUSE,
    "BREAK": KEY_PAUSE
}

static func normalize_token(raw: String) -> String:
    var trimmed: String = raw.strip_edges()
    if trimmed == "":
        return ""
    var upper: String = trimmed.to_upper()
    var compact: String = ""
    for ch in upper:
        if ch == " " or ch == "_" or ch == "-":
            continue
        compact += ch
    return compact

static func is_modifier_token(norm: String) -> bool:
    if norm == "":
        return false
    return MODIFIER_ALIASES.has(norm)

static func apply_modifier_token(event: InputEventKey, norm: String) -> void:
    if event == null or norm == "":
        return
    var mod_name: String = str(MODIFIER_ALIASES.get(norm, ""))
    match mod_name:
        "ctrl":
            event.ctrl_pressed = true
        "alt":
            event.alt_pressed = true
        "shift":
            event.shift_pressed = true
        "meta":
            event.meta_pressed = true

static func keycode_from_token(norm: String) -> int:
    if norm == "":
        return 0
    if KEY_ALIASES.has(norm):
        return int(KEY_ALIASES[norm])
    if norm.begins_with("F") and norm.length() <= 3:
        var f_text: String = norm.substr(1, norm.length() - 1)
        if f_text.is_valid_int():
            return _fn_keycode(int(f_text))
    return 0

static func _fn_keycode(n: int) -> int:
    match n:
        1:
            return KEY_F1
        2:
            return KEY_F2
        3:
            return KEY_F3
        4:
            return KEY_F4
        5:
            return KEY_F5
        6:
            return KEY_F6
        7:
            return KEY_F7
        8:
            return KEY_F8
        9:
            return KEY_F9
        10:
            return KEY_F10
        11:
            return KEY_F11
        12:
            return KEY_F12
    return 0
