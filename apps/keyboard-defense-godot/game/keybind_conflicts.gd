extends RefCounted
class_name KeybindConflicts

const ControlsFormatter = preload("res://game/controls_formatter.gd")
const GAME_NAME = "Keyboard Defense"

static func key_signature(ev: InputEvent) -> String:
    if not (ev is InputEventKey):
        return ""
    var key_event: InputEventKey = ev
    var keycode: int = int(key_event.keycode)
    if keycode <= 0:
        return ""
    return "K=%d|S=%d|C=%d|A=%d|M=%d" % [
        keycode,
        _bool_to_int(key_event.shift_pressed),
        _bool_to_int(key_event.ctrl_pressed),
        _bool_to_int(key_event.alt_pressed),
        _bool_to_int(key_event.meta_pressed)
    ]

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
    return ControlsFormatter.key_text_from_event(event)

static func keybind_to_text(keybind: Dictionary) -> String:
    return ControlsFormatter.keybind_to_text(keybind)

static func canonicalize_key_text(text: String) -> String:
    return ControlsFormatter.canonicalize_key_text(text)

static func event_from_text(text: String) -> InputEventKey:
    return ControlsFormatter.event_from_text(text)

static func keybind_from_text(text: String) -> Dictionary:
    return ControlsFormatter.keybind_from_text(text)

static func parse_key_text(text: String) -> Dictionary:
    return ControlsFormatter.parse_key_text(text)

static func event_matches_action_exact(event: InputEvent, action: StringName) -> bool:
    if not (event is InputEventKey):
        return false
    if not InputMap.has_action(action):
        return false
    var signature: String = key_signature(event)
    if signature == "":
        return false
    var events: Array = InputMap.action_get_events(action)
    for action_event in events:
        if not (action_event is InputEventKey):
            continue
        if signature == key_signature(action_event):
            return true
    return false

static func build_action_signature_map(actions: Array[String]) -> Dictionary:
    var result: Dictionary = {}
    for action_name in actions:
        var signatures: Array[String] = []
        if InputMap.has_action(action_name):
            var events: Array = InputMap.action_get_events(action_name)
            var seen: Dictionary = {}
            for event in events:
                if not (event is InputEventKey):
                    continue
                var signature: String = key_signature(event)
                if signature == "" or seen.has(signature):
                    continue
                seen[signature] = true
                signatures.append(signature)
        signatures.sort()
        result[action_name] = signatures
    return result

static func find_conflicts(action_sig_map: Dictionary) -> Dictionary:
    var signature_map: Dictionary = {}
    for action_name in action_sig_map.keys():
        var signatures: Variant = action_sig_map.get(action_name, [])
        if typeof(signatures) != TYPE_ARRAY:
            continue
        for signature in signatures:
            if not signature_map.has(signature):
                signature_map[signature] = []
            var actions: Array = signature_map[signature]
            if not actions.has(action_name):
                actions.append(action_name)
            signature_map[signature] = actions
    var result: Dictionary = {}
    var signatures_sorted: Array = signature_map.keys()
    signatures_sorted.sort()
    for signature in signatures_sorted:
        var actions: Array = signature_map.get(signature, [])
        if actions.size() < 2:
            continue
        actions.sort()
        result[signature] = actions
    return result

static func format_conflicts(conflicts: Dictionary, signature_to_display: Callable) -> Array[String]:
    var lines: Array[String] = []
    var signatures: Array = conflicts.keys()
    signatures.sort()
    for signature in signatures:
        var actions: Variant = conflicts.get(signature, [])
        if typeof(actions) != TYPE_ARRAY:
            continue
        var action_labels: Array[String] = []
        for action_name in actions:
            action_labels.append(str(action_name))
        action_labels.sort()
        var signature_text: String = ""
        if signature_to_display.is_valid():
            signature_text = str(signature_to_display.call(signature))
        else:
            signature_text = signature_to_label(signature)
        lines.append("CONFLICT: %s -> %s" % [signature_text, ", ".join(action_labels)])
    return lines

static func signature_to_label(signature: String) -> String:
    var event: InputEventKey = _event_from_signature(signature)
    if event == null:
        return signature
    var label: String = key_text_from_event(event)
    return label

static func no_conflicts_message() -> String:
    return "No conflicts detected."

static func safe_key_pool_entries() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    for n in range(1, 13):
        var keycode: int = fn_keycode(n)
        if keycode > 0:
            entries.append({"keycode": keycode, "label": "F%d" % n})
    entries.append({"keycode": KEY_INSERT, "label": "Insert"})
    entries.append({"keycode": KEY_DELETE, "label": "Delete"})
    entries.append({"keycode": KEY_HOME, "label": "Home"})
    entries.append({"keycode": KEY_END, "label": "End"})
    entries.append({"keycode": KEY_PAGEUP, "label": "PageUp"})
    entries.append({"keycode": KEY_PAGEDOWN, "label": "PageDown"})
    entries.append({"keycode": KEY_PRINT, "label": "PrintScreen"})
    entries.append({"keycode": KEY_SCROLLLOCK, "label": "ScrollLock"})
    entries.append({"keycode": KEY_PAUSE, "label": "Pause"})
    return entries

static func safe_key_pool_signatures() -> Array[String]:
    var signatures: Array[String] = []
    for entry in safe_key_pool_entries():
        var keycode: int = int(entry.get("keycode", 0))
        var signature: String = _signature_for_keycode(keycode)
        if signature != "":
            signatures.append(signature)
    return signatures

static func safe_key_candidate_tiers() -> Array:
    var tiers: Array = []
    var base_entries: Array[Dictionary] = []
    var ctrl_entries: Array[Dictionary] = []
    for entry in safe_key_pool_entries():
        var keycode: int = int(entry.get("keycode", 0))
        if keycode <= 0:
            continue
        var label: String = str(entry.get("label", ""))
        var base_signature: String = _signature_for_keycode_with_modifiers(keycode, false, false, false, false)
        if base_signature != "":
            base_entries.append({"signature": base_signature, "label": label, "tier": 0})
        var ctrl_signature: String = _signature_for_keycode_with_modifiers(keycode, false, true, false, false)
        if ctrl_signature != "":
            ctrl_entries.append({"signature": ctrl_signature, "label": "Ctrl+%s" % label, "tier": 1})
    tiers.append(base_entries)
    tiers.append(ctrl_entries)
    return tiers

static func build_resolution_plan(action_sig_map: Dictionary) -> Dictionary:
    var conflicts: Dictionary = find_conflicts(action_sig_map)
    var plan := {"conflicts": conflicts, "changes": [], "unresolved": []}
    if conflicts.is_empty():
        return plan
    var conflict_signatures: Array = conflicts.keys()
    conflict_signatures.sort()
    var action_conflict_signature: Dictionary = {}
    for signature in conflict_signatures:
        var actions: Variant = conflicts.get(signature, [])
        if typeof(actions) != TYPE_ARRAY:
            continue
        var action_list: Array[String] = []
        for action_name in actions:
            action_list.append(str(action_name))
        action_list.sort()
        for action_name in action_list:
            if not action_conflict_signature.has(action_name):
                action_conflict_signature[action_name] = signature
    var candidates: Array[String] = []
    for signature in conflict_signatures:
        var actions: Variant = conflicts.get(signature, [])
        if typeof(actions) != TYPE_ARRAY:
            continue
        var action_list: Array[String] = []
        for action_name in actions:
            action_list.append(str(action_name))
        action_list.sort()
        for i in range(1, action_list.size()):
            var action_name: String = action_list[i]
            if not candidates.has(action_name):
                candidates.append(action_name)
    candidates.sort()
    var used: Dictionary = _collect_used_signatures(action_sig_map)
    var available: Array[String] = _unused_safe_key_signatures(used)
    for action_name in candidates:
        var old_signature: String = str(action_conflict_signature.get(action_name, ""))
        if available.is_empty():
            plan["unresolved"].append({
                "action": action_name,
                "signature": old_signature,
                "reason": "No unused safe keys available."
            })
            continue
        var new_signature: String = str(available.pop_front())
        if new_signature == "" or used.has(new_signature):
            plan["unresolved"].append({
                "action": action_name,
                "signature": old_signature,
                "reason": "Suggested key is already in use."
            })
            continue
        used[new_signature] = true
        plan["changes"].append({
            "action": action_name,
            "from_signature": old_signature,
            "to_signature": new_signature
        })
    return plan

static func apply_resolution_plan(action_sig_map: Dictionary, plan: Dictionary) -> Dictionary:
    var updated: Dictionary = action_sig_map.duplicate(true)
    var changes: Variant = plan.get("changes", [])
    if typeof(changes) != TYPE_ARRAY:
        return updated
    for change in changes:
        if typeof(change) != TYPE_DICTIONARY:
            continue
        var action_name: String = str(change.get("action", ""))
        if action_name == "":
            continue
        var signature: String = str(change.get("to_signature", ""))
        if signature == "":
            updated[action_name] = []
        else:
            updated[action_name] = [signature]
    return updated

static func format_resolution_plan(plan: Dictionary, action_to_label: Callable, signature_to_display: Callable) -> Array[String]:
    var conflicts: Dictionary = plan.get("conflicts", {})
    if typeof(conflicts) != TYPE_DICTIONARY or conflicts.is_empty():
        return [no_conflicts_message()]
    var lines: Array[String] = []
    lines.append("Keybind resolve plan (dry-run):")
    var changes: Variant = plan.get("changes", [])
    var unresolved: Variant = plan.get("unresolved", [])
    for line in _format_resolution_changes(changes, action_to_label, signature_to_display, "CHANGE"):
        lines.append(line)
    for line in _format_resolution_unresolved(unresolved, action_to_label, signature_to_display):
        lines.append(line)
    if lines.size() == 1:
        lines.append("No safe changes available.")
    return lines

static func format_resolution_changes(changes: Variant, action_to_label: Callable, signature_to_display: Callable, prefix: String) -> Array[String]:
    return _format_resolution_changes(changes, action_to_label, signature_to_display, prefix)

static func format_resolution_unresolved(unresolved: Variant, action_to_label: Callable, signature_to_display: Callable) -> Array[String]:
    return _format_resolution_unresolved(unresolved, action_to_label, signature_to_display)

static func build_settings_export_payload(
    actions: Array[String],
    keybinds: Dictionary,
    action_sig_map: Dictionary,
    ui_state: Variant = null,
    engine_state: Variant = null,
    window_state: Variant = null,
    panels_state: Variant = null,
    game_state: Variant = null
) -> Dictionary:
    var action_list: Array[String] = []
    for action_name in actions:
        action_list.append(str(action_name))
    action_list.sort()
    var keybind_entries: Array = []
    for action_name in action_list:
        var key_text: String = ""
        if keybinds.has(action_name):
            key_text = _canonical_keybind_text(keybinds.get(action_name))
        keybind_entries.append({
            "action": action_name,
            "key": key_text
        })
    var conflicts: Dictionary = find_conflicts(action_sig_map)
    var conflict_entries: Array = []
    var conflict_signatures: Array = conflicts.keys()
    conflict_signatures.sort()
    for signature in conflict_signatures:
        var actions_raw: Variant = conflicts.get(signature, [])
        var action_ids: Array[String] = []
        if typeof(actions_raw) == TYPE_ARRAY:
            for action_name in actions_raw:
                action_ids.append(str(action_name))
        action_ids.sort()
        conflict_entries.append({
            "key": signature_to_label(str(signature)),
            "actions": action_ids
        })
    conflict_entries.sort_custom(Callable(KeybindConflicts, "_sort_export_conflict_entry"))
    var plan: Dictionary = build_resolution_plan(action_sig_map)
    var changes_entries: Array = []
    var changes: Variant = plan.get("changes", [])
    if typeof(changes) == TYPE_ARRAY:
        var ordered_changes: Array = _sort_resolution_entries(changes)
        for change in ordered_changes:
            if typeof(change) != TYPE_DICTIONARY:
                continue
            var action_name: String = str(change.get("action", ""))
            var from_signature: String = str(change.get("from_signature", ""))
            var to_signature: String = str(change.get("to_signature", ""))
            changes_entries.append({
                "action": action_name,
                "from": signature_to_label(from_signature),
                "to": signature_to_label(to_signature)
            })
    var unresolved_entries: Array = []
    var unresolved: Variant = plan.get("unresolved", [])
    if typeof(unresolved) == TYPE_ARRAY:
        var grouped: Dictionary = {}
        for entry in unresolved:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var action_name: String = str(entry.get("action", ""))
            var signature: String = str(entry.get("signature", ""))
            var reason: String = str(entry.get("reason", "Unresolved"))
            var group_key: String = "%s|%s" % [signature, reason]
            if not grouped.has(group_key):
                grouped[group_key] = {
                    "signature": signature,
                    "reason": reason,
                    "actions": []
                }
            var action_group: Array = grouped[group_key]["actions"]
            if action_name != "" and not action_group.has(action_name):
                action_group.append(action_name)
        for group in grouped.values():
            if typeof(group) != TYPE_DICTIONARY:
                continue
            var signature: String = str(group.get("signature", ""))
            var reason: String = str(group.get("reason", "Unresolved"))
            var action_group: Variant = group.get("actions", [])
            var action_ids: Array[String] = []
            if typeof(action_group) == TYPE_ARRAY:
                for action_name in action_group:
                    action_ids.append(str(action_name))
            action_ids.sort()
            unresolved_entries.append({
                "key": signature_to_label(signature),
                "actions": action_ids,
                "reason": reason
            })
        unresolved_entries.sort_custom(Callable(KeybindConflicts, "_sort_export_unresolved_entry"))
    var resolve_plan: Dictionary = {
        "changes": changes_entries,
        "unresolved": unresolved_entries
    }
    var ui: Dictionary = {}
    ui["scale"] = _ui_scale_from_state(ui_state)
    ui["compact"] = _ui_compact_from_state(ui_state)
    var game: Dictionary = _game_from_state(game_state)
    var engine: Dictionary = _engine_from_state(engine_state)
    var window: Dictionary = _window_from_state(window_state)
    var panels: Dictionary = _panels_from_state(panels_state)
    var payload: Dictionary = {}
    payload["schema"] = "typing-defense.settings-export"
    payload["schema_version"] = 4
    payload["game"] = game
    payload["engine"] = engine
    payload["ui"] = ui
    payload["window"] = window
    payload["panels"] = panels
    payload["keybinds"] = keybind_entries
    payload["conflicts"] = conflict_entries
    payload["resolve_plan"] = resolve_plan
    return payload

static func format_settings_export_json(payload: Dictionary) -> String:
    var ordered: Dictionary = {}
    ordered["schema"] = str(payload.get("schema", "typing-defense.settings-export"))
    ordered["schema_version"] = int(payload.get("schema_version", 4))
    var game_raw: Variant = payload.get("game", {})
    var game_ordered: Dictionary = {}
    if typeof(game_raw) == TYPE_DICTIONARY:
        game_ordered["name"] = str(game_raw.get("name", GAME_NAME))
        game_ordered["version"] = str(game_raw.get("version", read_game_version()))
    else:
        game_ordered["name"] = GAME_NAME
        game_ordered["version"] = read_game_version()
    ordered["game"] = game_ordered
    var engine_raw: Variant = payload.get("engine", {})
    var engine_ordered: Dictionary = {}
    if typeof(engine_raw) == TYPE_DICTIONARY:
        engine_ordered["godot"] = str(engine_raw.get("godot", "0.0.0"))
        if engine_raw.has("major"):
            engine_ordered["major"] = int(engine_raw.get("major", 0))
        if engine_raw.has("minor"):
            engine_ordered["minor"] = int(engine_raw.get("minor", 0))
        if engine_raw.has("patch"):
            engine_ordered["patch"] = int(engine_raw.get("patch", 0))
    else:
        engine_ordered["godot"] = "0.0.0"
    ordered["engine"] = engine_ordered
    var ui_raw: Variant = payload.get("ui", {})
    var ui_ordered: Dictionary = {}
    if typeof(ui_raw) == TYPE_DICTIONARY:
        ui_ordered["scale"] = ui_raw.get("scale", 1.0)
        ui_ordered["compact"] = ui_raw.get("compact", false)
    else:
        ui_ordered["scale"] = 1.0
        ui_ordered["compact"] = false
    ordered["ui"] = ui_ordered
    var window_raw: Variant = payload.get("window", {})
    var window_ordered: Dictionary = {}
    if typeof(window_raw) == TYPE_DICTIONARY:
        window_ordered["width"] = int(window_raw.get("width", 0))
        window_ordered["height"] = int(window_raw.get("height", 0))
    else:
        window_ordered["width"] = 0
        window_ordered["height"] = 0
    ordered["window"] = window_ordered
    var panels_raw: Variant = payload.get("panels", {})
    var panels_ordered: Dictionary = {}
    if typeof(panels_raw) == TYPE_DICTIONARY:
        panels_ordered["settings"] = bool(panels_raw.get("settings", false))
        panels_ordered["lessons"] = bool(panels_raw.get("lessons", false))
        panels_ordered["trend"] = bool(panels_raw.get("trend", false))
        panels_ordered["history"] = bool(panels_raw.get("history", false))
        panels_ordered["report"] = bool(panels_raw.get("report", false))
    else:
        panels_ordered["settings"] = false
        panels_ordered["lessons"] = false
        panels_ordered["trend"] = false
        panels_ordered["history"] = false
        panels_ordered["report"] = false
    ordered["panels"] = panels_ordered
    ordered["keybinds"] = payload.get("keybinds", [])
    ordered["conflicts"] = payload.get("conflicts", [])
    var resolve_raw: Variant = payload.get("resolve_plan", {})
    var resolve_ordered: Dictionary = {}
    if typeof(resolve_raw) == TYPE_DICTIONARY:
        resolve_ordered["changes"] = resolve_raw.get("changes", [])
        resolve_ordered["unresolved"] = resolve_raw.get("unresolved", [])
    else:
        resolve_ordered["changes"] = []
        resolve_ordered["unresolved"] = []
    ordered["resolve_plan"] = resolve_ordered
    return JSON.stringify(ordered, "  ")

static func read_game_version() -> String:
    var path: String = "res://VERSION.txt"
    if not FileAccess.file_exists(path):
        return "0.0.0"
    var text: String = FileAccess.get_file_as_string(path)
    if text == "":
        return "0.0.0"
    var first_line: String = text.split("\n", false)[0].strip_edges()
    if first_line == "":
        return "0.0.0"
    return first_line

static func _game_from_state(game_state: Variant) -> Dictionary:
    if typeof(game_state) == TYPE_DICTIONARY and not game_state.is_empty():
        return game_state.duplicate(true)
    return {
        "name": GAME_NAME,
        "version": read_game_version()
    }

static func _engine_from_state(engine_state: Variant) -> Dictionary:
    if typeof(engine_state) == TYPE_DICTIONARY and not engine_state.is_empty():
        return engine_state.duplicate(true)
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
    return {
        "godot": godot_text,
        "major": major,
        "minor": minor,
        "patch": patch
    }

static func _window_from_state(window_state: Variant) -> Dictionary:
    if typeof(window_state) == TYPE_DICTIONARY and not window_state.is_empty():
        return window_state.duplicate(true)
    return {"width": 0, "height": 0}

static func _panels_from_state(panels_state: Variant) -> Dictionary:
    if typeof(panels_state) == TYPE_DICTIONARY and not panels_state.is_empty():
        return panels_state.duplicate(true)
    return {
        "settings": false,
        "lessons": false,
        "trend": false,
        "history": false,
        "report": false
    }

static func keybind_from_signature(signature: String) -> Dictionary:
    var event: InputEventKey = _event_from_signature(signature)
    if event == null:
        return {}
    return {
        "keycode": event.keycode,
        "shift": event.shift_pressed,
        "alt": event.alt_pressed,
        "ctrl": event.ctrl_pressed,
        "meta": event.meta_pressed
    }

static func suggest_unused_safe_key(action_sig_map: Dictionary) -> String:      
    var used: Dictionary = _collect_used_signatures(action_sig_map)
    for tier in safe_key_candidate_tiers():
        for entry in tier:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var signature: String = str(entry.get("signature", ""))
            if signature == "" or used.has(signature):
                continue
            return str(entry.get("label", ""))
    return ""

static func suggest_unused_function_key(action_sig_map: Dictionary) -> String:
    return suggest_unused_safe_key(action_sig_map)

static func _collect_used_signatures(action_sig_map: Dictionary) -> Dictionary:
    var used: Dictionary = {}
    for action_name in action_sig_map.keys():
        var signatures: Variant = action_sig_map.get(action_name, [])
        if typeof(signatures) != TYPE_ARRAY:
            continue
        for signature in signatures:
            var signature_text: String = str(signature)
            if signature_text == "":
                continue
            used[signature_text] = true
    return used

static func _unused_safe_key_signatures(used: Dictionary) -> Array[String]:     
    var available: Array[String] = []
    for tier in safe_key_candidate_tiers():
        for entry in tier:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var signature: String = str(entry.get("signature", ""))
            if signature == "":
                continue
            if not used.has(signature):
                available.append(signature)
    return available

static func _format_resolution_changes(changes: Variant, action_to_label: Callable, signature_to_display: Callable, prefix: String) -> Array[String]:
    var lines: Array[String] = []
    if typeof(changes) != TYPE_ARRAY:
        return lines
    var ordered: Array = _sort_resolution_entries(changes)
    for change in ordered:
        if typeof(change) != TYPE_DICTIONARY:
            continue
        var action_name: String = str(change.get("action", ""))
        if action_name == "":
            continue
        var from_signature: String = str(change.get("from_signature", ""))
        var to_signature: String = str(change.get("to_signature", ""))
        var action_text: String = _format_action_label(action_name, action_to_label)
        var from_label: String = _format_signature_label(from_signature, signature_to_display)
        var to_label: String = _format_signature_label(to_signature, signature_to_display)
        if from_label == "" or to_label == "":
            lines.append("%s: %s" % [prefix, action_text])
        else:
            lines.append("%s: %s %s -> %s" % [prefix, action_text, from_label, to_label])
    return lines

static func _format_resolution_unresolved(unresolved: Variant, action_to_label: Callable, signature_to_display: Callable) -> Array[String]:
    var lines: Array[String] = []
    if typeof(unresolved) != TYPE_ARRAY:
        return lines
    var ordered: Array = _sort_resolution_entries(unresolved)
    for entry in ordered:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var action_name: String = str(entry.get("action", ""))
        if action_name == "":
            continue
        var signature: String = str(entry.get("signature", ""))
        var reason: String = str(entry.get("reason", "Unresolved"))
        var action_text: String = _format_action_label(action_name, action_to_label)
        var signature_label: String = _format_signature_label(signature, signature_to_display)
        if signature_label == "":
            lines.append("UNRESOLVED: %s - %s" % [action_text, reason])
        else:
            lines.append("UNRESOLVED: %s %s - %s" % [action_text, signature_label, reason])
    return lines

static func _format_action_label(action_name: String, action_to_label: Callable) -> String:
    var label: String = action_name
    if action_to_label.is_valid():
        label = str(action_to_label.call(action_name))
    if label == action_name:
        return action_name
    return "%s (%s)" % [label, action_name]

static func _format_signature_label(signature: String, signature_to_display: Callable) -> String:
    if signature == "":
        return ""
    if signature_to_display.is_valid():
        return str(signature_to_display.call(signature))
    return signature_to_label(signature)

static func _canonical_keybind_text(raw: Variant) -> String:
    if typeof(raw) == TYPE_DICTIONARY:
        return ControlsFormatter.keybind_to_text(raw)
    if typeof(raw) == TYPE_STRING:
        return ControlsFormatter.canonicalize_key_text(str(raw))
    return ""

static func _sort_resolution_entries(entries: Array) -> Array:
    var ordered: Array = entries.duplicate(true)
    ordered.sort_custom(Callable(KeybindConflicts, "_sort_resolution_entry"))
    return ordered

static func _sort_resolution_entry(a: Variant, b: Variant) -> bool:
    var a_name: String = ""
    var b_name: String = ""
    if typeof(a) == TYPE_DICTIONARY:
        a_name = str(a.get("action", ""))
    if typeof(b) == TYPE_DICTIONARY:
        b_name = str(b.get("action", ""))
    if a_name == b_name:
        var a_sig: String = ""
        var b_sig: String = ""
        if typeof(a) == TYPE_DICTIONARY:
            if a.has("from_signature"):
                a_sig = str(a.get("from_signature", ""))
            else:
                a_sig = str(a.get("signature", ""))
        if typeof(b) == TYPE_DICTIONARY:
            if b.has("from_signature"):
                b_sig = str(b.get("from_signature", ""))
            else:
                b_sig = str(b.get("signature", ""))
        return a_sig < b_sig
    return a_name < b_name

static func _sort_export_unresolved_entry(a: Variant, b: Variant) -> bool:
    var a_key: String = ""
    var b_key: String = ""
    var a_actions: String = ""
    var b_actions: String = ""
    if typeof(a) == TYPE_DICTIONARY:
        a_key = str(a.get("key", ""))
        var actions_a: Variant = a.get("actions", [])
        if typeof(actions_a) == TYPE_ARRAY:
            a_actions = ", ".join(actions_a)
    if typeof(b) == TYPE_DICTIONARY:
        b_key = str(b.get("key", ""))
        var actions_b: Variant = b.get("actions", [])
        if typeof(actions_b) == TYPE_ARRAY:
            b_actions = ", ".join(actions_b)
    if a_key == b_key:
        return a_actions < b_actions
    return a_key < b_key

static func _sort_export_conflict_entry(a: Variant, b: Variant) -> bool:
    var a_key: String = ""
    var b_key: String = ""
    var a_actions: String = ""
    var b_actions: String = ""
    if typeof(a) == TYPE_DICTIONARY:
        a_key = str(a.get("key", ""))
        var actions_a: Variant = a.get("actions", [])
        if typeof(actions_a) == TYPE_ARRAY:
            a_actions = ", ".join(actions_a)
    if typeof(b) == TYPE_DICTIONARY:
        b_key = str(b.get("key", ""))
        var actions_b: Variant = b.get("actions", [])
        if typeof(actions_b) == TYPE_ARRAY:
            b_actions = ", ".join(actions_b)
    if a_key == b_key:
        return a_actions < b_actions
    return a_key < b_key

static func _ui_scale_from_state(ui_state: Variant) -> float:
    if typeof(ui_state) != TYPE_DICTIONARY:
        return 1.0
    if ui_state.has("scale"):
        var raw: Variant = ui_state.get("scale", 1.0)
        if typeof(raw) == TYPE_FLOAT or typeof(raw) == TYPE_INT:
            return float(raw)
    if ui_state.has("ui_scale_percent"):
        var percent_raw: Variant = ui_state.get("ui_scale_percent", 100)
        if typeof(percent_raw) == TYPE_FLOAT or typeof(percent_raw) == TYPE_INT:
            return float(percent_raw) / 100.0
    if ui_state.has("scale_percent"):
        var percent_alt: Variant = ui_state.get("scale_percent", 100)
        if typeof(percent_alt) == TYPE_FLOAT or typeof(percent_alt) == TYPE_INT:
            return float(percent_alt) / 100.0
    return 1.0

static func _ui_compact_from_state(ui_state: Variant) -> bool:
    if typeof(ui_state) != TYPE_DICTIONARY:
        return false
    if ui_state.has("compact"):
        return bool(ui_state.get("compact", false))
    if ui_state.has("compact_panels"):
        return bool(ui_state.get("compact_panels", false))
    return false

static func fn_keycode(n: int) -> int:
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

static func _event_from_signature(signature: String) -> InputEventKey:
    var parts: Dictionary = {}
    for entry in signature.split("|"):
        var key_value: Array = entry.split("=")
        if key_value.size() != 2:
            continue
        parts[str(key_value[0])] = str(key_value[1])
    var keycode: int = int(parts.get("K", "0"))
    if keycode <= 0:
        return null
    var event := InputEventKey.new()
    event.keycode = keycode
    event.shift_pressed = parts.get("S", "0") == "1"
    event.ctrl_pressed = parts.get("C", "0") == "1"
    event.alt_pressed = parts.get("A", "0") == "1"
    event.meta_pressed = parts.get("M", "0") == "1"
    return event

static func _signature_for_keycode(keycode: int) -> String:
    return _signature_for_keycode_with_modifiers(keycode, false, false, false, false)

static func _signature_for_keycode_with_modifiers(keycode: int, shift: bool, ctrl: bool, alt: bool, meta: bool) -> String:
    if keycode <= 0:
        return ""
    return "K=%d|S=%d|C=%d|A=%d|M=%d" % [
        keycode,
        _bool_to_int(shift),
        _bool_to_int(ctrl),
        _bool_to_int(alt),
        _bool_to_int(meta)
    ]


static func _bool_to_int(value: bool) -> int:
    return 1 if value else 0
