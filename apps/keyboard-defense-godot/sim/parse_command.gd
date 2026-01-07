class_name CommandParser
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimIntents = preload("res://sim/intents.gd")

static func parse(command: String) -> Dictionary:
    var trimmed: String = command.strip_edges()
    if trimmed.is_empty():
        return {"ok": false, "error": "Enter a command. Type 'help' for options."}

    var tokens: PackedStringArray = trimmed.split(" ", false)
    var verb: String = tokens[0].to_lower()

    match verb:
        "help":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("help")}
            if tokens.size() == 2:
                return {"ok": true, "intent": SimIntents.make("help", {"topic": tokens[1]})}
            return {"ok": false, "error": "Usage: help [settings|hotkeys|topics|play|accessibility]"}
        "version":
            if tokens.size() > 1:
                return {"ok": false, "error": "'version' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("ui_version")}
        "status":
            if tokens.size() > 1:
                return {"ok": false, "error": "'status' takes no arguments."}   
            return {"ok": true, "intent": SimIntents.make("status")}
        "balance":
            if tokens.size() == 2 and tokens[1].to_lower() == "verify":
                return {"ok": true, "intent": SimIntents.make("ui_balance_verify")}
            if tokens.size() >= 2 and tokens[1].to_lower() == "summary":
                if tokens.size() > 3:
                    return {"ok": false, "error": "Usage: balance summary [group]"}
                var group: String = tokens[2].to_lower() if tokens.size() == 3 else ""
                return {"ok": true, "intent": SimIntents.make("ui_balance_summary", {"group": group})}
            if tokens.size() >= 2 and tokens[1].to_lower() == "diff":
                if tokens.size() > 3:
                    return {"ok": false, "error": "Usage: balance diff [group]"}
                var group: String = tokens[2].to_lower() if tokens.size() == 3 else "all"
                return {"ok": true, "intent": SimIntents.make("ui_balance_diff", {"group": group})}
            if tokens.size() >= 2 and tokens[1].to_lower() == "export":
                var group: String = "all"
                var save: bool = false
                if tokens.size() == 3:
                    if tokens[2].to_lower() == "save":
                        save = true
                    else:
                        group = tokens[2]
                elif tokens.size() == 4:
                    if tokens[2].to_lower() != "save":
                        return {"ok": false, "error": "Usage: balance export [save] [group]"}
                    save = true
                    group = tokens[3]
                elif tokens.size() > 4:
                    return {"ok": false, "error": "Usage: balance export [save] [group]"}
                return {"ok": true, "intent": SimIntents.make("ui_balance_export", {"save": save, "group": group})}
            return {"ok": false, "error": "Usage: balance verify | balance export [save] [group] | balance diff [group] | balance summary [group]"}
        "end":
            if tokens.size() > 1:
                return {"ok": false, "error": "'end' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("end")}
        "gather":
            if tokens.size() != 3:
                return {"ok": false, "error": "Usage: gather <resource> <amount>"}
            var resource: String = tokens[1].to_lower()
            if not GameState.RESOURCE_KEYS.has(resource):
                return {"ok": false, "error": "Unknown resource: %s" % resource}
            var amount_text: String = tokens[2]
            if not amount_text.is_valid_int():
                return {"ok": false, "error": "Amount must be a positive integer."}
            var amount: int = int(amount_text)
            if amount <= 0:
                return {"ok": false, "error": "Amount must be a positive integer."}
            return {"ok": true, "intent": SimIntents.make("gather", {"resource": resource, "amount": amount})}
        "seed":
            var seed_value: String = ""
            if trimmed.length() > verb.length():
                seed_value = trimmed.substr(verb.length()).strip_edges()
            if seed_value.is_empty():
                return {"ok": false, "error": "Usage: seed <string>"}
            return {"ok": true, "intent": SimIntents.make("seed", {"seed": seed_value})}
        "build":
            if tokens.size() != 2 and tokens.size() != 4:
                return {"ok": false, "error": "Usage: build <type> [x y]"}
            var build_type: String = tokens[1].to_lower()
            if not SimBuildings.is_valid(build_type):
                return {"ok": false, "error": "Unknown build type: %s" % build_type}
            var payload: Dictionary = {"building": build_type}
            if tokens.size() == 4:
                if not tokens[2].is_valid_int() or not tokens[3].is_valid_int():
                    return {"ok": false, "error": "Build coordinates must be integers."}
                payload["x"] = int(tokens[2])
                payload["y"] = int(tokens[3])
            return {"ok": true, "intent": SimIntents.make("build", payload)}
        "explore":
            if tokens.size() > 1:
                return {"ok": false, "error": "'explore' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("explore")}
        "cursor":
            if tokens.size() == 2 or tokens.size() == 3:
                var direction: String = tokens[1].to_lower()
                var dir_map := {
                    "up": Vector2i(0, -1),
                    "down": Vector2i(0, 1),
                    "left": Vector2i(-1, 0),
                    "right": Vector2i(1, 0)
                }
                if dir_map.has(direction):
                    var steps: int = 1
                    if tokens.size() == 3:
                        if not tokens[2].is_valid_int():
                            return {"ok": false, "error": "Cursor steps must be a positive integer."}
                        steps = int(tokens[2])
                        if steps <= 0:
                            return {"ok": false, "error": "Cursor steps must be a positive integer."}
                    var delta: Vector2i = dir_map[direction]
                    return {"ok": true, "intent": SimIntents.make("cursor_move", {"dx": delta.x, "dy": delta.y, "steps": steps})}
            if tokens.size() != 3:
                return {"ok": false, "error": "Usage: cursor <x> <y> OR cursor <direction> [n]"}
            if not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
                return {"ok": false, "error": "Cursor coordinates must be integers."}
            return {"ok": true, "intent": SimIntents.make("cursor", {"x": int(tokens[1]), "y": int(tokens[2])})}
        "inspect":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("inspect")}
            if tokens.size() != 3:
                return {"ok": false, "error": "Usage: inspect [x y]"}
            if not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
                return {"ok": false, "error": "Inspect coordinates must be integers."}
            return {"ok": true, "intent": SimIntents.make("inspect", {"x": int(tokens[1]), "y": int(tokens[2])})}
        "map":
            if tokens.size() > 1:
                return {"ok": false, "error": "'map' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("map")}
        "demolish":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("demolish")}
            if tokens.size() != 3:
                return {"ok": false, "error": "Usage: demolish [x y]"}
            if not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
                return {"ok": false, "error": "Demolish coordinates must be integers."}
            return {"ok": true, "intent": SimIntents.make("demolish", {"x": int(tokens[1]), "y": int(tokens[2])})}
        "preview":
            if tokens.size() != 2:
                return {"ok": false, "error": "Usage: preview <type|none>"}
            var preview_type: String = tokens[1].to_lower()
            if preview_type == "none":
                return {"ok": true, "intent": SimIntents.make("ui_preview", {"building": ""})}
            if not SimBuildings.is_valid(preview_type):
                return {"ok": false, "error": "Unknown build type: %s" % preview_type}
            return {"ok": true, "intent": SimIntents.make("ui_preview", {"building": preview_type})}
        "upgrade":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("upgrade")}
            if tokens.size() != 3:
                return {"ok": false, "error": "Usage: upgrade [x y]"}
            if not tokens[1].is_valid_int() or not tokens[2].is_valid_int():
                return {"ok": false, "error": "Upgrade coordinates must be integers."}
            return {"ok": true, "intent": SimIntents.make("upgrade", {"x": int(tokens[1]), "y": int(tokens[2])})}
        "wait":
            if tokens.size() > 1:
                return {"ok": false, "error": "'wait' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("wait")}
        "overlay":
            if tokens.size() != 3:
                return {"ok": false, "error": "Usage: overlay path <on|off>"}
            if tokens[1].to_lower() != "path":
                return {"ok": false, "error": "Unknown overlay: %s" % tokens[1]}
            var mode: String = tokens[2].to_lower()
            if mode != "on" and mode != "off":
                return {"ok": false, "error": "Usage: overlay path <on|off>"}
            return {"ok": true, "intent": SimIntents.make("ui_overlay", {"name": "path", "enabled": mode == "on"})}
        "enemies":
            if tokens.size() > 1:
                return {"ok": false, "error": "'enemies' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("enemies")}
        "history":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_history", {"mode": "toggle"})}
            if tokens.size() == 2:
                var mode: String = tokens[1].to_lower()
                if mode == "show" or mode == "hide" or mode == "toggle" or mode == "clear":
                    return {"ok": true, "intent": SimIntents.make("ui_history", {"mode": mode})}
            return {"ok": false, "error": "Usage: history [show|hide|clear]"}
        "trend":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_trend", {"mode": "toggle"})}
            if tokens.size() == 2:
                var mode: String = tokens[1].to_lower()
                if mode == "show" or mode == "hide" or mode == "toggle":
                    return {"ok": true, "intent": SimIntents.make("ui_trend", {"mode": mode})}
            return {"ok": false, "error": "Usage: trend [show|hide]"}
        "goal":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_goal_show")}
            if tokens.size() == 2:
                var goal_id: String = tokens[1].to_lower()
                if goal_id == "next":
                    return {"ok": true, "intent": SimIntents.make("ui_goal_next")}
                return {"ok": true, "intent": SimIntents.make("ui_goal_set", {"goal_id": goal_id})}
            return {"ok": false, "error": "Usage: goal [id|next]"}
        "lessons":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_lessons_toggle")}
            if tokens.size() >= 2 and tokens[1].to_lower() == "sort":
                if tokens.size() == 2:
                    return {"ok": true, "intent": SimIntents.make("ui_lessons_sort", {"mode": "show"})}
                if tokens.size() == 3:
                    return {"ok": true, "intent": SimIntents.make("ui_lessons_sort", {"mode": tokens[2].to_lower()})}
                return {"ok": false, "error": "Usage: lessons sort [default|recent|name]"}
            if tokens.size() >= 2 and tokens[1].to_lower() == "sparkline":
                if tokens.size() == 2:
                    return {"ok": true, "intent": SimIntents.make("ui_lessons_sparkline", {"mode": "show"})}
                if tokens.size() == 3:
                    var spark_mode: String = tokens[2].to_lower()
                    if spark_mode == "on" or spark_mode == "off":
                        return {"ok": true, "intent": SimIntents.make("ui_lessons_sparkline", {"enabled": spark_mode == "on"})}
                return {"ok": false, "error": "Usage: lessons sparkline [on|off]"}
            if tokens.size() == 2 and tokens[1].to_lower() == "reset":
                return {"ok": true, "intent": SimIntents.make("ui_lessons_reset", {"scope": "current"})}
            if tokens.size() == 3 and tokens[1].to_lower() == "reset" and tokens[2].to_lower() == "all":
                return {"ok": true, "intent": SimIntents.make("ui_lessons_reset", {"scope": "all"})}
            return {"ok": false, "error": "Usage: lessons [reset [all]] | lessons sort [default|recent|name] | lessons sparkline [on|off]"}
        "lesson":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("lesson_show")}
            if tokens.size() == 2:
                var lesson_arg: String = tokens[1].to_lower()
                if lesson_arg == "next":
                    return {"ok": true, "intent": SimIntents.make("lesson_next")}
                if lesson_arg == "prev":
                    return {"ok": true, "intent": SimIntents.make("lesson_prev")}
                if lesson_arg == "sample":
                    return {"ok": true, "intent": SimIntents.make("lesson_sample", {"count": 3})}
                return {"ok": true, "intent": SimIntents.make("lesson_set", {"lesson_id": lesson_arg})}
            if tokens.size() == 3 and tokens[1].to_lower() == "sample":
                if not tokens[2].is_valid_int():
                    return {"ok": false, "error": "Sample count must be a positive integer."}
                var count: int = int(tokens[2])
                if count <= 0:
                    return {"ok": false, "error": "Sample count must be a positive integer."}
                return {"ok": true, "intent": SimIntents.make("lesson_sample", {"count": count})}
            return {"ok": false, "error": "Usage: lesson [id|next|prev|sample [n]]"}
        "report":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_report", {"mode": "toggle"})}
            if tokens.size() == 2:
                var mode: String = tokens[1].to_lower()
                if mode == "show" or mode == "hide" or mode == "toggle":
                    return {"ok": true, "intent": SimIntents.make("ui_report", {"mode": mode})}
            return {"ok": false, "error": "Usage: report [show|hide]"}
        "settings":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_settings_toggle")}
            if tokens.size() >= 2:
                var mode: String = tokens[1].to_lower()
                if mode == "show":
                    return {"ok": true, "intent": SimIntents.make("ui_settings_show")}
                if mode == "hide":
                    return {"ok": true, "intent": SimIntents.make("ui_settings_hide")}
                if mode == "lessons":
                    return {"ok": true, "intent": SimIntents.make("ui_settings_lessons")}
                if mode == "prefs":
                    return {"ok": true, "intent": SimIntents.make("ui_settings_prefs")}
                if mode == "verify":
                    if tokens.size() == 2:
                        return {"ok": true, "intent": SimIntents.make("ui_settings_verify")}
                    return {"ok": false, "error": "Usage: settings verify"}
                if mode == "conflicts":
                    if tokens.size() == 2:
                        return {"ok": true, "intent": SimIntents.make("ui_settings_conflicts")}
                    return {"ok": false, "error": "Usage: settings conflicts"}
                if mode == "resolve":
                    if tokens.size() == 2:
                        return {"ok": true, "intent": SimIntents.make("ui_settings_resolve", {"apply": false})}
                    if tokens.size() == 3 and tokens[2].to_lower() == "apply":
                        return {"ok": true, "intent": SimIntents.make("ui_settings_resolve", {"apply": true})}
                    return {"ok": false, "error": "Usage: settings resolve [apply]"}
                if mode == "export":
                    if tokens.size() == 2:
                        return {"ok": true, "intent": SimIntents.make("ui_settings_export", {"save": false})}
                    if tokens.size() == 3 and tokens[2].to_lower() == "save":
                        return {"ok": true, "intent": SimIntents.make("ui_settings_export", {"save": true})}
                    return {"ok": false, "error": "Usage: settings export [save]"}
                if mode == "scale" or mode == "font":
                    if tokens.size() == 2:
                        return {"ok": true, "intent": SimIntents.make("ui_settings_scale", {"mode": "show"})}
                    if tokens.size() == 3:
                        var scale_arg: String = tokens[2].to_lower()
                        if scale_arg == "reset":
                            return {"ok": true, "intent": SimIntents.make("ui_settings_scale", {"mode": "reset"})}
                        if scale_arg == "+":
                            return {"ok": true, "intent": SimIntents.make("ui_settings_scale", {"mode": "step", "delta": 1})}
                        if scale_arg == "-":
                            return {"ok": true, "intent": SimIntents.make("ui_settings_scale", {"mode": "step", "delta": -1})}
                        if scale_arg.is_valid_int():
                            return {"ok": true, "intent": SimIntents.make("ui_settings_scale", {"mode": "set", "value": int(scale_arg)})}
                    return {"ok": false, "error": "Usage: settings scale|font [80|90|100|110|120|130|140|+|-|reset]"}
                if mode == "compact":
                    if tokens.size() == 2:
                        return {"ok": true, "intent": SimIntents.make("ui_settings_compact", {"mode": "show"})}
                    if tokens.size() == 3:
                        var compact_arg: String = tokens[2].to_lower()
                        if compact_arg == "on" or compact_arg == "off" or compact_arg == "toggle":
                            return {"ok": true, "intent": SimIntents.make("ui_settings_compact", {"mode": compact_arg})}
                    return {"ok": false, "error": "Usage: settings compact [on|off|toggle]"}
            return {"ok": false, "error": "Usage: settings [show|hide|lessons|prefs|verify|conflicts|resolve|export|scale|font|compact]"}
        "tutorial":
            if tokens.size() == 1:
                return {"ok": true, "intent": SimIntents.make("ui_tutorial_toggle")}
            if tokens.size() == 2:
                var mode: String = tokens[1].to_lower()
                if mode == "restart" or mode == "replay":
                    return {"ok": true, "intent": SimIntents.make("ui_tutorial_restart")}
                if mode == "skip":
                    return {"ok": true, "intent": SimIntents.make("ui_tutorial_skip")}
            return {"ok": false, "error": "Usage: tutorial [restart|skip]"}
        "bind":
            if tokens.size() == 2:
                return {"ok": true, "intent": SimIntents.make("ui_bind_action", {"action": tokens[1].to_lower()})}
            if tokens.size() == 3:
                var action_name: String = tokens[1].to_lower()
                var bind_arg: String = tokens[2]
                if bind_arg.to_lower() == "reset":
                    return {"ok": true, "intent": SimIntents.make("ui_bind_action_reset", {"action": action_name})}
                return {"ok": true, "intent": SimIntents.make("ui_bind_action", {"action": action_name, "key_text": bind_arg})}
            return {"ok": false, "error": "Usage: bind <action> [key|reset]"}
        "defend":
            var text: String = ""
            if trimmed.length() > verb.length():
                text = trimmed.substr(verb.length()).strip_edges()
            if text.is_empty():
                return {"ok": false, "error": "Usage: defend <text>"}
            return {"ok": true, "intent": SimIntents.make("defend_input", {"text": text})}
        "restart":
            if tokens.size() > 1:
                return {"ok": false, "error": "'restart' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("restart")}
        "save":
            if tokens.size() > 1:
                return {"ok": false, "error": "'save' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("save")}
        "load":
            if tokens.size() > 1:
                return {"ok": false, "error": "'load' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("load")}
        "new":
            if tokens.size() > 1:
                return {"ok": false, "error": "'new' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("new")}
        _:
            return {"ok": false, "error": "Unknown command: %s" % verb}

