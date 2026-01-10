# Keybind & Input System Guide

This document explains the keybind conflict detection, resolution, and input remapping system in Keyboard Defense.

## Overview

The keybind system manages input mappings and detects conflicts:

```
Input Actions → Key Signatures → Conflict Detection → Resolution Plan → Apply Changes
      ↓               ↓                  ↓                  ↓               ↓
  ui_accept      K=13|S=0...      find duplicates      suggest F1-F12    update InputMap
```

## Key Signatures

### Signature Format

Each keybind is represented as a unique signature string:

```gdscript
# game/keybind_conflicts.gd:7
static func key_signature(ev: InputEvent) -> String:
    if not (ev is InputEventKey):
        return ""
    var key_event: InputEventKey = ev
    var keycode: int = int(key_event.keycode)
    if keycode <= 0:
        return ""
    return "K=%d|S=%d|C=%d|A=%d|M=%d" % [
        keycode,                              # K = Keycode
        _bool_to_int(key_event.shift_pressed),  # S = Shift
        _bool_to_int(key_event.ctrl_pressed),   # C = Ctrl
        _bool_to_int(key_event.alt_pressed),    # A = Alt
        _bool_to_int(key_event.meta_pressed)    # M = Meta/Cmd
    ]
```

Example signatures:
- `K=32|S=0|C=0|A=0|M=0` = Space
- `K=13|S=0|C=0|A=0|M=0` = Enter
- `K=65|S=1|C=0|A=0|M=0` = Shift+A
- `K=83|S=0|C=1|A=0|M=0` = Ctrl+S

### Keybind Dictionary

```gdscript
# game/keybind_conflicts.gd:22
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
```

### Event from Keybind

```gdscript
# game/keybind_conflicts.gd:33
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
```

## Action Signature Mapping

### Building the Map

Maps each action to its key signatures:

```gdscript
# game/keybind_conflicts.gd:80
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
```

Example result:
```gdscript
{
    "ui_accept": ["K=13|S=0|C=0|A=0|M=0", "K=32|S=0|C=0|A=0|M=0"],
    "ui_cancel": ["K=16777217|S=0|C=0|A=0|M=0"],
    "toggle_settings": ["K=16777244|S=0|C=0|A=0|M=0"]
}
```

## Conflict Detection

### Finding Conflicts

Identifies when multiple actions share the same key:

```gdscript
# game/keybind_conflicts.gd:99
static func find_conflicts(action_sig_map: Dictionary) -> Dictionary:
    # Build reverse map: signature -> [actions]
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

    # Filter to only conflicts (2+ actions)
    var result: Dictionary = {}
    for signature in signature_map.keys():
        var actions: Array = signature_map.get(signature, [])
        if actions.size() < 2:
            continue
        actions.sort()
        result[signature] = actions

    return result
```

### Formatting Conflicts

```gdscript
# game/keybind_conflicts.gd:123
static func format_conflicts(conflicts: Dictionary, signature_to_display: Callable) -> Array[String]:
    var lines: Array[String] = []
    for signature in conflicts.keys():
        var actions: Array = conflicts.get(signature, [])
        var action_labels: Array[String] = []
        for action_name in actions:
            action_labels.append(str(action_name))
        action_labels.sort()
        var signature_text: String = signature_to_label(signature)
        lines.append("CONFLICT: %s -> %s" % [signature_text, ", ".join(action_labels)])
    return lines
```

## Safe Key Pool

### Function Keys (F1-F12)

```gdscript
# game/keybind_conflicts.gd:753
static func fn_keycode(n: int) -> int:
    match n:
        1: return KEY_F1
        2: return KEY_F2
        # ... through F12
        12: return KEY_F12
    return 0
```

### Safe Keys for Remapping

```gdscript
# game/keybind_conflicts.gd:153
static func safe_key_pool_entries() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []

    # Function keys F1-F12
    for n in range(1, 13):
        var keycode: int = fn_keycode(n)
        if keycode > 0:
            entries.append({"keycode": keycode, "label": "F%d" % n})

    # Navigation keys
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
```

### Candidate Tiers

```gdscript
# game/keybind_conflicts.gd:179
static func safe_key_candidate_tiers() -> Array:
    var tiers: Array = []
    var base_entries: Array[Dictionary] = []   # F1, F2, etc.
    var ctrl_entries: Array[Dictionary] = []   # Ctrl+F1, Ctrl+F2, etc.

    for entry in safe_key_pool_entries():
        var keycode: int = int(entry.get("keycode", 0))
        var label: String = str(entry.get("label", ""))

        # Tier 0: Plain keys
        var base_signature: String = _signature_for_keycode(keycode)
        if base_signature != "":
            base_entries.append({"signature": base_signature, "label": label, "tier": 0})

        # Tier 1: Ctrl + key
        var ctrl_signature: String = _signature_for_keycode_with_modifiers(keycode, false, true, false, false)
        if ctrl_signature != "":
            ctrl_entries.append({"signature": ctrl_signature, "label": "Ctrl+%s" % label, "tier": 1})

    tiers.append(base_entries)
    tiers.append(ctrl_entries)
    return tiers
```

## Conflict Resolution

### Building a Resolution Plan

```gdscript
# game/keybind_conflicts.gd:198
static func build_resolution_plan(action_sig_map: Dictionary) -> Dictionary:
    var conflicts: Dictionary = find_conflicts(action_sig_map)
    var plan := {"conflicts": conflicts, "changes": [], "unresolved": []}

    if conflicts.is_empty():
        return plan

    # Build list of actions needing new keys
    var candidates: Array[String] = []
    for signature in conflicts.keys():
        var actions: Array = conflicts.get(signature, [])
        actions.sort()
        # Keep first action, reassign others
        for i in range(1, actions.size()):
            var action_name: String = actions[i]
            if not candidates.has(action_name):
                candidates.append(action_name)
    candidates.sort()

    # Get unused safe keys
    var used: Dictionary = _collect_used_signatures(action_sig_map)
    var available: Array[String] = _unused_safe_key_signatures(used)

    # Assign new keys
    for action_name in candidates:
        if available.is_empty():
            plan["unresolved"].append({
                "action": action_name,
                "reason": "No unused safe keys available."
            })
            continue

        var new_signature: String = str(available.pop_front())
        used[new_signature] = true
        plan["changes"].append({
            "action": action_name,
            "from_signature": old_signature,
            "to_signature": new_signature
        })

    return plan
```

### Applying Resolution

```gdscript
# game/keybind_conflicts.gd:258
static func apply_resolution_plan(action_sig_map: Dictionary, plan: Dictionary) -> Dictionary:
    var updated: Dictionary = action_sig_map.duplicate(true)
    var changes: Array = plan.get("changes", [])

    for change in changes:
        var action_name: String = str(change.get("action", ""))
        var signature: String = str(change.get("to_signature", ""))
        if signature == "":
            updated[action_name] = []
        else:
            updated[action_name] = [signature]

    return updated
```

## Text Formatting

### Signature to Label

```gdscript
# game/keybind_conflicts.gd:143
static func signature_to_label(signature: String) -> String:
    var event: InputEventKey = _event_from_signature(signature)
    if event == null:
        return signature
    return key_text_from_event(event)
```

Converts `K=65|S=1|C=0|A=0|M=0` to `Shift+A`.

### Event from Signature

```gdscript
# game/keybind_conflicts.gd:781
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
```

## Settings Export

### Export Payload

```gdscript
# game/keybind_conflicts.gd:298
static func build_settings_export_payload(
    actions: Array[String],
    keybinds: Dictionary,
    action_sig_map: Dictionary,
    ...
) -> Dictionary:
    var payload: Dictionary = {}
    payload["schema"] = "typing-defense.settings-export"
    payload["schema_version"] = 4
    payload["game"] = {"name": GAME_NAME, "version": read_game_version()}
    payload["keybinds"] = keybind_entries
    payload["conflicts"] = conflict_entries
    payload["resolve_plan"] = resolve_plan
    return payload
```

### Export JSON

```gdscript
# game/keybind_conflicts.gd:414
static func format_settings_export_json(payload: Dictionary) -> String:
    return JSON.stringify(ordered, "  ")
```

## Integration Examples

### Settings Panel Integration

```gdscript
var actions: Array[String] = ["ui_accept", "ui_cancel", "toggle_settings", ...]

func _update_keybind_display() -> void:
    var sig_map := KeybindConflicts.build_action_signature_map(actions)
    var conflicts := KeybindConflicts.find_conflicts(sig_map)

    if conflicts.is_empty():
        conflict_label.text = "No conflicts"
        conflict_label.modulate = Color.GREEN
    else:
        var lines := KeybindConflicts.format_conflicts(conflicts, Callable())
        conflict_label.text = "\n".join(lines)
        conflict_label.modulate = Color.RED

func _on_auto_resolve_pressed() -> void:
    var sig_map := KeybindConflicts.build_action_signature_map(actions)
    var plan := KeybindConflicts.build_resolution_plan(sig_map)

    # Preview changes
    var lines := KeybindConflicts.format_resolution_plan(
        plan,
        _action_label,
        _signature_label
    )
    preview_text.text = "\n".join(lines)

func _on_apply_resolution_pressed() -> void:
    var sig_map := KeybindConflicts.build_action_signature_map(actions)
    var plan := KeybindConflicts.build_resolution_plan(sig_map)
    var updated := KeybindConflicts.apply_resolution_plan(sig_map, plan)

    # Apply to InputMap
    for action_name in updated.keys():
        var signatures: Array = updated[action_name]
        InputMap.action_erase_events(action_name)
        for signature in signatures:
            var event := KeybindConflicts._event_from_signature(signature)
            if event:
                InputMap.action_add_event(action_name, event)
```

### Rebinding a Key

```gdscript
func _on_rebind_key(action: String, new_event: InputEventKey) -> void:
    var new_signature := KeybindConflicts.key_signature(new_event)

    # Check for conflicts
    var sig_map := KeybindConflicts.build_action_signature_map(actions)
    for other_action in sig_map.keys():
        if other_action == action:
            continue
        if sig_map[other_action].has(new_signature):
            _show_conflict_warning(other_action)
            return

    # Apply new binding
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, new_event)
    _save_keybinds()
```

### Suggesting Unused Key

```gdscript
func _suggest_key_for_action(action: String) -> String:
    var sig_map := KeybindConflicts.build_action_signature_map(actions)
    return KeybindConflicts.suggest_unused_safe_key(sig_map)
```

## Testing

```gdscript
func test_key_signature():
    var event := InputEventKey.new()
    event.keycode = KEY_A
    event.shift_pressed = true

    var sig := KeybindConflicts.key_signature(event)
    assert("K=65" in sig)  # KEY_A = 65
    assert("S=1" in sig)   # Shift pressed

    _pass("test_key_signature")

func test_find_conflicts():
    var sig_map := {
        "action_a": ["K=65|S=0|C=0|A=0|M=0"],
        "action_b": ["K=65|S=0|C=0|A=0|M=0"],  # Same key!
        "action_c": ["K=66|S=0|C=0|A=0|M=0"]
    }

    var conflicts := KeybindConflicts.find_conflicts(sig_map)
    assert(conflicts.size() == 1)
    assert(conflicts.values()[0].has("action_a"))
    assert(conflicts.values()[0].has("action_b"))

    _pass("test_find_conflicts")

func test_resolution_plan():
    var sig_map := {
        "action_a": ["K=65|S=0|C=0|A=0|M=0"],
        "action_b": ["K=65|S=0|C=0|A=0|M=0"]
    }

    var plan := KeybindConflicts.build_resolution_plan(sig_map)
    assert(plan.changes.size() > 0)  # At least one change

    var updated := KeybindConflicts.apply_resolution_plan(sig_map, plan)
    var new_conflicts := KeybindConflicts.find_conflicts(updated)
    assert(new_conflicts.is_empty())  # Resolved!

    _pass("test_resolution_plan")

func test_signature_roundtrip():
    var event := InputEventKey.new()
    event.keycode = KEY_F5
    event.ctrl_pressed = true

    var sig := KeybindConflicts.key_signature(event)
    var restored := KeybindConflicts._event_from_signature(sig)

    assert(restored.keycode == KEY_F5)
    assert(restored.ctrl_pressed == true)

    _pass("test_signature_roundtrip")
```
