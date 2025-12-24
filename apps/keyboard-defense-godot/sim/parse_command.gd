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
            if tokens.size() > 1:
                return {"ok": false, "error": "'help' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("help")}
        "status":
            if tokens.size() > 1:
                return {"ok": false, "error": "'status' takes no arguments."}
            return {"ok": true, "intent": SimIntents.make("status")}
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
            return {"ok": false, "error": "Usage: settings"}
        "bind":
            if tokens.size() >= 2 and tokens[1].to_lower() == "cycle_goal":
                if tokens.size() == 2:
                    return {"ok": true, "intent": SimIntents.make("ui_bind_cycle_goal")}
                if tokens.size() == 3 and tokens[2].to_lower() == "reset":
                    return {"ok": true, "intent": SimIntents.make("ui_bind_cycle_goal_reset")}
            return {"ok": false, "error": "Usage: bind cycle_goal [reset]"}
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
