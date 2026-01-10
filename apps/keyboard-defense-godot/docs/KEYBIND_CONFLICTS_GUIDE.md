# Keybind Conflicts Guide

This document explains the keybind conflict detection and resolution system that manages input mappings and prevents duplicate key assignments.

## Overview

The KeybindConflicts class provides signature-based conflict detection:

```
Input Event → Generate Signature → Build Map → Find Conflicts → Resolve Plan
      ↓              ↓                 ↓              ↓              ↓
  InputEventKey   K=n|S=n|...    action→signatures  duplicates    suggestions
```

## Class Reference

```gdscript
# game/keybind_conflicts.gd
class_name KeybindConflicts
extends RefCounted
```

## Key Signature Format

Signatures uniquely identify key combinations:

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
        keycode,
        _bool_to_int(key_event.shift_pressed),
        _bool_to_int(key_event.ctrl_pressed),
        _bool_to_int(key_event.alt_pressed),
        _bool_to_int(key_event.meta_pressed)
    ]
```

### Signature Components

| Component | Description | Values |
|-----------|-------------|--------|
| K | Keycode | Godot KEY_* constant |
| S | Shift modifier | 0 or 1 |
| C | Ctrl modifier | 0 or 1 |
| A | Alt modifier | 0 or 1 |
| M | Meta modifier | 0 or 1 |

### Example Signatures

| Key Combo | Signature |
|-----------|-----------|
| F1 | `K=4194332\|S=0\|C=0\|A=0\|M=0` |
| Ctrl+F1 | `K=4194332\|S=0\|C=1\|A=0\|M=0` |
| Shift+A | `K=65\|S=1\|C=0\|A=0\|M=0` |

## Keybind Conversion

### Event to Keybind Dictionary

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

### Dictionary to Event

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

### Signature to Keybind

```gdscript
# game/keybind_conflicts.gd:543
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
```

## Text Formatting

Delegates to ControlsFormatter for display text:

```gdscript
# game/keybind_conflicts.gd:46
static func key_text_from_event(event: InputEventKey) -> String:
    return ControlsFormatter.key_text_from_event(event)

static func keybind_to_text(keybind: Dictionary) -> String:
    return ControlsFormatter.keybind_to_text(keybind)

static func canonicalize_key_text(text: String) -> String:
    return ControlsFormatter.canonicalize_key_text(text)

static func event_from_text(text: String) -> InputEventKey:
    return ControlsFormatter.event_from_text(text)
```

## Action Matching

### Exact Match Check

```gdscript
# game/keybind_conflicts.gd:64
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
```

### Build Action Signature Map

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

Returns: `{action_name: [signature1, signature2, ...]}`

## Conflict Detection

### Find Conflicts

```gdscript
# game/keybind_conflicts.gd:99
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
    # Filter to only signatures with 2+ actions
    var result: Dictionary = {}
    for signature in signature_map.keys():
        var actions: Array = signature_map.get(signature, [])
        if actions.size() < 2:
            continue
        actions.sort()
        result[signature] = actions
    return result
```

Returns: `{signature: [action1, action2, ...]}` for conflicts only

### Format Conflicts

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
        if signature_to_display.is_valid():
            signature_text = str(signature_to_display.call(signature))
        lines.append("CONFLICT: %s -> %s" % [signature_text, ", ".join(action_labels)])
    return lines
```

## Safe Key Pool

Keys that don't conflict with typing (function keys, navigation keys):

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

Safe keys organized by preference:

```gdscript
# game/keybind_conflicts.gd:179
static func safe_key_candidate_tiers() -> Array:
    var tiers: Array = []
    var base_entries: Array[Dictionary] = []
    var ctrl_entries: Array[Dictionary] = []
    for entry in safe_key_pool_entries():
        var keycode: int = int(entry.get("keycode", 0))
        var label: String = str(entry.get("label", ""))
        # Tier 0: Base keys (F1, F2, etc.)
        var base_signature: String = _signature_for_keycode(keycode)
        if base_signature != "":
            base_entries.append({"signature": base_signature, "label": label, "tier": 0})
        # Tier 1: Ctrl+key combinations
        var ctrl_signature: String = _signature_for_keycode_with_modifiers(keycode, false, true, false, false)
        if ctrl_signature != "":
            ctrl_entries.append({"signature": ctrl_signature, "label": "Ctrl+%s" % label, "tier": 1})
    tiers.append(base_entries)
    tiers.append(ctrl_entries)
    return tiers
```

| Tier | Keys | Example |
|------|------|---------|
| 0 | Base function/nav keys | F1, F2, Insert |
| 1 | Ctrl + function/nav keys | Ctrl+F1, Ctrl+Insert |

## Resolution Planning

### Build Resolution Plan

Automatically suggests fixes for conflicts:

```gdscript
# game/keybind_conflicts.gd:198
static func build_resolution_plan(action_sig_map: Dictionary) -> Dictionary:
    var conflicts: Dictionary = find_conflicts(action_sig_map)
    var plan := {"conflicts": conflicts, "changes": [], "unresolved": []}
    if conflicts.is_empty():
        return plan

    # Identify which actions need remapping
    var candidates: Array[String] = []
    for signature in conflicts.keys():
        var actions: Array = conflicts.get(signature, [])
        # Keep first action, remap others
        for i in range(1, actions.size()):
            if not candidates.has(actions[i]):
                candidates.append(actions[i])

    # Find unused safe keys
    var used: Dictionary = _collect_used_signatures(action_sig_map)
    var available: Array[String] = _unused_safe_key_signatures(used)

    # Assign new keys to conflicting actions
    for action_name in candidates:
        if available.is_empty():
            plan["unresolved"].append({
                "action": action_name,
                "reason": "No unused safe keys available."
            })
            continue
        var new_signature: String = str(available.pop_front())
        plan["changes"].append({
            "action": action_name,
            "from_signature": old_signature,
            "to_signature": new_signature
        })
    return plan
```

### Plan Structure

```json
{
    "conflicts": {
        "K=123|S=0|C=0|A=0|M=0": ["action_a", "action_b"]
    },
    "changes": [
        {
            "action": "action_b",
            "from_signature": "K=123|S=0|C=0|A=0|M=0",
            "to_signature": "K=4194332|S=0|C=0|A=0|M=0"
        }
    ],
    "unresolved": [
        {
            "action": "action_c",
            "signature": "K=456|S=0|C=0|A=0|M=0",
            "reason": "No unused safe keys available."
        }
    ]
}
```

### Apply Resolution Plan

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

### Format Resolution Plan

```gdscript
# game/keybind_conflicts.gd:276
static func format_resolution_plan(plan: Dictionary, action_to_label: Callable, signature_to_display: Callable) -> Array[String]:
    var conflicts: Dictionary = plan.get("conflicts", {})
    if conflicts.is_empty():
        return [no_conflicts_message()]
    var lines: Array[String] = []
    lines.append("Keybind resolve plan (dry-run):")
    # Format changes
    for change in plan.get("changes", []):
        var action_text: String = _format_action_label(change.action, action_to_label)
        var from_label: String = signature_to_label(change.from_signature)
        var to_label: String = signature_to_label(change.to_signature)
        lines.append("CHANGE: %s %s -> %s" % [action_text, from_label, to_label])
    # Format unresolved
    for entry in plan.get("unresolved", []):
        lines.append("UNRESOLVED: %s - %s" % [entry.action, entry.reason])
    return lines
```

## Settings Export

### Build Export Payload

Creates comprehensive settings snapshot for debugging/sharing:

```gdscript
# game/keybind_conflicts.gd:298
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
    var payload: Dictionary = {}
    payload["schema"] = "typing-defense.settings-export"
    payload["schema_version"] = 4
    payload["game"] = _game_from_state(game_state)
    payload["engine"] = _engine_from_state(engine_state)
    payload["ui"] = ui  # scale, compact
    payload["window"] = window  # width, height
    payload["panels"] = panels  # settings, lessons, etc.
    payload["keybinds"] = keybind_entries
    payload["conflicts"] = conflict_entries
    payload["resolve_plan"] = resolve_plan
    return payload
```

### Export Schema

```json
{
    "schema": "typing-defense.settings-export",
    "schema_version": 4,
    "game": {"name": "Keyboard Defense", "version": "1.0.0"},
    "engine": {"godot": "4.3.0", "major": 4, "minor": 3, "patch": 0},
    "ui": {"scale": 1.0, "compact": false},
    "window": {"width": 1920, "height": 1080},
    "panels": {
        "settings": false,
        "lessons": false,
        "trend": false,
        "history": false,
        "report": false
    },
    "keybinds": [
        {"action": "cycle_goal", "key": "F7"},
        {"action": "toggle_settings", "key": "F1"}
    ],
    "conflicts": [
        {"key": "F1", "actions": ["toggle_settings", "other_action"]}
    ],
    "resolve_plan": {
        "changes": [{"action": "other_action", "from": "F1", "to": "F8"}],
        "unresolved": []
    }
}
```

### Format Export JSON

```gdscript
# game/keybind_conflicts.gd:414
static func format_settings_export_json(payload: Dictionary) -> String:
    var ordered: Dictionary = {}
    ordered["schema"] = str(payload.get("schema", "typing-defense.settings-export"))
    ordered["schema_version"] = int(payload.get("schema_version", 4))
    ordered["game"] = game_ordered
    ordered["engine"] = engine_ordered
    ordered["ui"] = ui_ordered
    ordered["window"] = window_ordered
    ordered["panels"] = panels_ordered
    ordered["keybinds"] = payload.get("keybinds", [])
    ordered["conflicts"] = payload.get("conflicts", [])
    ordered["resolve_plan"] = resolve_ordered
    return JSON.stringify(ordered, "  ")
```

## Utility Functions

### Suggest Unused Key

```gdscript
# game/keybind_conflicts.gd:555
static func suggest_unused_safe_key(action_sig_map: Dictionary) -> String:
    var used: Dictionary = _collect_used_signatures(action_sig_map)
    for tier in safe_key_candidate_tiers():
        for entry in tier:
            var signature: String = str(entry.get("signature", ""))
            if signature == "" or used.has(signature):
                continue
            return str(entry.get("label", ""))
    return ""
```

### Function Key Lookup

```gdscript
# game/keybind_conflicts.gd:753
static func fn_keycode(n: int) -> int:
    match n:
        1: return KEY_F1
        2: return KEY_F2
        3: return KEY_F3
        4: return KEY_F4
        5: return KEY_F5
        6: return KEY_F6
        7: return KEY_F7
        8: return KEY_F8
        9: return KEY_F9
        10: return KEY_F10
        11: return KEY_F11
        12: return KEY_F12
    return 0
```

### Signature Parsing

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

## Integration Example

```gdscript
# In settings panel or keybind editor
func _check_for_conflicts() -> void:
    var actions: Array[String] = ["cycle_goal", "toggle_settings", "toggle_lessons"]
    var action_sig_map: Dictionary = KeybindConflicts.build_action_signature_map(actions)
    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_sig_map)

    if conflicts.is_empty():
        _show_message(KeybindConflicts.no_conflicts_message())
        return

    # Show conflicts
    var lines: Array[String] = KeybindConflicts.format_conflicts(
        conflicts,
        func(sig): return KeybindConflicts.signature_to_label(sig)
    )
    for line in lines:
        print(line)

    # Build and show resolution plan
    var plan: Dictionary = KeybindConflicts.build_resolution_plan(action_sig_map)
    var plan_lines: Array[String] = KeybindConflicts.format_resolution_plan(
        plan,
        func(action): return action.replace("_", " ").capitalize(),
        func(sig): return KeybindConflicts.signature_to_label(sig)
    )
    for line in plan_lines:
        print(line)

func _export_settings() -> void:
    var actions: Array[String] = TypingProfile.default_keybinds().keys()
    var keybinds: Dictionary = TypingProfile.get_keybinds(profile)
    var action_sig_map: Dictionary = KeybindConflicts.build_action_signature_map(actions)

    var payload: Dictionary = KeybindConflicts.build_settings_export_payload(
        actions,
        keybinds,
        action_sig_map,
        {"ui_scale_percent": 100, "compact_panels": false},
        null,  # engine_state (auto-detected)
        {"width": get_viewport().size.x, "height": get_viewport().size.y},
        {"settings": settings_panel.visible, "lessons": lessons_panel.visible}
    )

    var json_text: String = KeybindConflicts.format_settings_export_json(payload)
    DisplayServer.clipboard_set(json_text)
```

## Testing

```gdscript
func test_signature_generation():
    var event := InputEventKey.new()
    event.keycode = KEY_F1
    event.ctrl_pressed = true

    var sig: String = KeybindConflicts.key_signature(event)
    assert(sig.begins_with("K="))
    assert(sig.contains("|C=1|"))

    _pass("test_signature_generation")

func test_conflict_detection():
    var action_sig_map: Dictionary = {
        "action_a": ["K=4194332|S=0|C=0|A=0|M=0"],
        "action_b": ["K=4194332|S=0|C=0|A=0|M=0"],
        "action_c": ["K=4194333|S=0|C=0|A=0|M=0"]
    }

    var conflicts: Dictionary = KeybindConflicts.find_conflicts(action_sig_map)
    assert(conflicts.size() == 1)
    var conflict_actions: Array = conflicts.values()[0]
    assert(conflict_actions.has("action_a"))
    assert(conflict_actions.has("action_b"))
    assert(not conflict_actions.has("action_c"))

    _pass("test_conflict_detection")

func test_resolution_plan():
    var action_sig_map: Dictionary = {
        "action_a": ["K=4194332|S=0|C=0|A=0|M=0"],
        "action_b": ["K=4194332|S=0|C=0|A=0|M=0"]
    }

    var plan: Dictionary = KeybindConflicts.build_resolution_plan(action_sig_map)
    assert(not plan.conflicts.is_empty())
    assert(plan.changes.size() == 1)
    assert(plan.changes[0].action == "action_b")

    _pass("test_resolution_plan")

func test_safe_key_pool():
    var entries: Array[Dictionary] = KeybindConflicts.safe_key_pool_entries()
    assert(entries.size() >= 12)  # At least F1-F12

    var has_f1: bool = false
    for entry in entries:
        if entry.get("label", "") == "F1":
            has_f1 = true
            break
    assert(has_f1)

    _pass("test_safe_key_pool")
```

## API Quick Reference

| Function | Purpose |
|----------|---------|
| `key_signature(event)` | Generate unique signature from InputEvent |
| `keybind_from_event(event)` | Convert InputEventKey to Dictionary |
| `event_from_keybind(keybind)` | Convert Dictionary to InputEventKey |
| `build_action_signature_map(actions)` | Map action names to signatures |
| `find_conflicts(action_sig_map)` | Find duplicate key assignments |
| `format_conflicts(conflicts, callable)` | Format conflicts as text |
| `build_resolution_plan(action_sig_map)` | Generate automatic fix suggestions |
| `apply_resolution_plan(map, plan)` | Apply planned changes |
| `safe_key_pool_entries()` | Get non-typing keys for rebinding |
| `suggest_unused_safe_key(map)` | Find available safe key |
| `build_settings_export_payload(...)` | Create full settings snapshot |
| `format_settings_export_json(payload)` | Format export as JSON |
