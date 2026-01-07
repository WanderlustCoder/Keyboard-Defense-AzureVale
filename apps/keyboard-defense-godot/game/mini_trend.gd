class_name MiniTrend
extends RefCounted

static func delta(a: float, b: float) -> float:
    return float(a) - float(b)

static func arrow_for_delta(d: float, eps: float = 0.01) -> String:
    if d > eps:
        return "+"
    if d < -eps:
        return "-"
    return "="

static func format_compact_badge(value: float, arrow: String, pct: bool = false) -> String:
    var base: String = ""
    if pct:
        base = "%d%%" % int(round(value * 100.0))
    else:
        base = "%.2f" % value
    if arrow == "":
        return base
    return "%s %s" % [base, arrow]

static func sparkline(values: Array, width: int = 3, charset: String = " .:-=+*#%@") -> String:
    if values.is_empty():
        return "---"
    if width <= 0:
        return ""
    var chars: Array[String] = []
    for i in range(charset.length()):
        chars.append(charset.substr(i, 1))
    if chars.is_empty():
        return ""
    var take_count: int = min(width, values.size())
    var output: Array[String] = []
    for i in range(take_count):
        var value: float = float(values[i])
        var clamped: float = clamp(value, 0.0, 1.0)
        var index: int = int(round(clamped * float(chars.size() - 1)))
        index = clamp(index, 0, chars.size() - 1)
        output.append(chars[index])
    return "".join(output)

static func sparkline_from_recent(recent: Array, key: String, width: int = 3) -> String:
    if not (recent is Array) or recent.is_empty():
        return "---"
    var values: Array = []
    for i in range(recent.size() - 1, -1, -1):
        if typeof(recent[i]) != TYPE_DICTIONARY:
            continue
        values.append(float(recent[i].get(key, 0.0)))
    return sparkline(values, width)

static func format_last3_delta(recent: Array) -> Dictionary:
    var output := {
        "has_delta": false,
        "acc_d": 0.0,
        "hit_d": 0.0,
        "back_d": 0.0,
        "acc_arrow": "",
        "hit_arrow": "",
        "back_arrow": "",
        "text": "Last3: --"
    }
    if not (recent is Array) or recent.size() < 2:
        return output
    var newest = recent[0]
    var oldest = recent[recent.size() - 1]
    if typeof(newest) != TYPE_DICTIONARY or typeof(oldest) != TYPE_DICTIONARY:
        return output
    var acc_d: float = float(newest.get("avg_accuracy", 0.0)) - float(oldest.get("avg_accuracy", 0.0))
    var hit_d: float = float(newest.get("hit_rate", 0.0)) - float(oldest.get("hit_rate", 0.0))
    var back_d: float = float(newest.get("backspace_rate", 0.0)) - float(oldest.get("backspace_rate", 0.0))
    var acc_arrow: String = arrow_for_delta(acc_d)
    var hit_arrow: String = arrow_for_delta(hit_d)
    var back_arrow: String = arrow_for_delta(back_d)
    var acc_text: String = format_compact_badge(float(newest.get("avg_accuracy", 0.0)), acc_arrow, false)
    var hit_text: String = format_compact_badge(float(newest.get("hit_rate", 0.0)), hit_arrow, true)
    var back_text: String = format_compact_badge(float(newest.get("backspace_rate", 0.0)), back_arrow, true)
    var acc_delta: String = _format_delta_text(acc_d, false)
    var hit_delta: String = _format_delta_text(hit_d, true)
    var back_delta: String = _format_delta_text(back_d, true)
    output["has_delta"] = true
    output["acc_d"] = acc_d
    output["hit_d"] = hit_d
    output["back_d"] = back_d
    output["acc_arrow"] = acc_arrow
    output["hit_arrow"] = hit_arrow
    output["back_arrow"] = back_arrow
    output["text"] = "acc %s (%s) | hit %s (%s) | back %s (%s)" % [
        acc_text,
        acc_delta,
        hit_text,
        hit_delta,
        back_text,
        back_delta
    ]
    return output

static func _format_delta_text(value: float, pct: bool) -> String:
    var sign: String = "+" if value >= 0.0 else "-"
    var magnitude: float = abs(value)
    if pct:
        return "%s%d%%" % [sign, int(round(magnitude * 100.0))]
    return "%s%.2f" % [sign, magnitude]
