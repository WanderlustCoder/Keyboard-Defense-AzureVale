using System;
using System.Collections.Generic;
using System.Globalization;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Intent;

/// <summary>
/// Parses text commands into intents.
/// Ported from sim/parse_command.gd.
/// </summary>
public static class CommandParser
{
    public static Dictionary<string, object> Parse(string command)
    {
        string trimmed = command.Trim();
        if (string.IsNullOrEmpty(trimmed))
            return Error("Enter a command. Type 'help' for options.");

        string[] tokens = trimmed.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        string verb = tokens[0].ToLowerInvariant();

        return verb switch
        {
            "help" => ParseHelp(tokens),
            "version" => NoArgs(tokens, "version", "ui_version"),
            "status" => NoArgs(tokens, "status", "status"),
            "balance" => ParseBalance(tokens),
            "end" => NoArgs(tokens, "end", "end"),
            "gather" => ParseGather(tokens),
            "seed" => ParseSeed(trimmed, verb),
            "build" => ParseBuild(tokens),
            "explore" => NoArgs(tokens, "explore", "explore"),
            "cursor" => ParseCursor(tokens),
            "inspect" => ParseInspect(tokens),
            "map" => NoArgs(tokens, "map", "map"),
            "zone" or "zones" or "region" => ParseZone(tokens),
            "demolish" => ParseDemolish(tokens),
            "preview" => ParsePreview(tokens),
            "upgrade" => ParseUpgrade(tokens),
            "wait" => NoArgs(tokens, "wait", "wait"),
            "overlay" => ParseOverlay(tokens),
            "enemies" => NoArgs(tokens, "enemies", "enemies"),
            "history" => ParseToggleMode(tokens, "history", "ui_history"),
            "trend" => ParseToggleMode(tokens, "trend", "ui_trend"),
            "goal" => ParseGoal(tokens),
            "lessons" => ParseLessons(tokens),
            "lesson" => ParseLesson(tokens),
            "report" => ParseToggleMode(tokens, "report", "ui_report"),
            "settings" => ParseSettings(tokens),
            "tutorial" => ParseTutorial(tokens),
            "bind" => ParseBind(tokens),
            "defend" => ParseDefend(trimmed, verb),
            "restart" => NoArgs(tokens, "restart", "restart"),
            "save" => NoArgs(tokens, "save", "save"),
            "load" => NoArgs(tokens, "load", "load"),
            "new" => NoArgs(tokens, "new", "new"),
            "interact" => NoArgs(tokens, "interact", "interact_poi"),
            "choice" => ParseChoice(trimmed, tokens),
            "skip" => NoArgs(tokens, "skip", "event_skip"),
            "buy" => ParseBuy(tokens),
            "upgrades" => ParseUpgrades(tokens),
            "research" => ParseResearch(tokens),
            "trade" => ParseTrade(tokens),
            "look" or "l" => NoArgs(tokens, "look", "inspect_tile"),
            "talk" or "t" => NoArgs(tokens, "talk", "interact_poi"),
            "take" or "grab" => NoArgs(tokens, "take", "gather_at_cursor"),
            "attack" or "fight" => NoArgs(tokens, "attack", "engage_enemy"),
            "loot" => ParseLoot(tokens),
            "expedition" or "exp" => ParseExpedition(tokens),
            "harvest" => ParseHarvest(tokens),
            "nodes" => NoArgs(tokens, "nodes", "nodes_list"),
            "hero" => ParseHero(tokens),
            "locale" or "lang" or "language" => ParseLocale(tokens),
            "title" or "titles" => ParseTitle(tokens),
            "badge" or "badges" => Ok(SimIntents.Make("badges_show")),
            "target" or "targeting" => ParseTarget(tokens),
            _ => Error($"Unknown command: {verb}")
        };
    }

    // --- Helpers ---

    private static Dictionary<string, object> Ok(Dictionary<string, object> intent)
        => new() { ["ok"] = true, ["intent"] = intent };

    private static Dictionary<string, object> Error(string message)
        => new() { ["ok"] = false, ["error"] = message };

    private static Dictionary<string, object> NoArgs(string[] tokens, string cmdName, string intentKind)
    {
        if (tokens.Length > 1)
            return Error($"'{cmdName}' takes no arguments.");
        return Ok(SimIntents.Make(intentKind));
    }

    private static bool IsValidInt(string s, out int value)
        => int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out value);

    private static bool IsValidFloat(string s, out float value)
        => float.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out value);

    // --- Command parsers ---

    private static Dictionary<string, object> ParseHelp(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("help"));
        if (tokens.Length == 2)
            return Ok(SimIntents.Make("help", new() { ["topic"] = tokens[1] }));
        return Error("Usage: help [settings|hotkeys|topics|play|accessibility]");
    }

    private static Dictionary<string, object> ParseBalance(string[] tokens)
    {
        if (tokens.Length < 2)
            return Error("Usage: balance verify | balance export [save] [group] | balance diff [group] | balance summary [group]");

        string sub = tokens[1].ToLowerInvariant();
        switch (sub)
        {
            case "verify":
                return Ok(SimIntents.Make("ui_balance_verify"));
            case "summary":
            {
                if (tokens.Length > 3) return Error("Usage: balance summary [group]");
                string group = tokens.Length == 3 ? tokens[2].ToLowerInvariant() : "";
                return Ok(SimIntents.Make("ui_balance_summary", new() { ["group"] = group }));
            }
            case "diff":
            {
                if (tokens.Length > 3) return Error("Usage: balance diff [group]");
                string group = tokens.Length == 3 ? tokens[2].ToLowerInvariant() : "all";
                return Ok(SimIntents.Make("ui_balance_diff", new() { ["group"] = group }));
            }
            case "export":
            {
                string group = "all";
                bool save = false;
                if (tokens.Length == 3)
                {
                    if (tokens[2].ToLowerInvariant() == "save") save = true;
                    else group = tokens[2];
                }
                else if (tokens.Length == 4)
                {
                    if (tokens[2].ToLowerInvariant() != "save")
                        return Error("Usage: balance export [save] [group]");
                    save = true;
                    group = tokens[3];
                }
                else if (tokens.Length > 4)
                    return Error("Usage: balance export [save] [group]");
                return Ok(SimIntents.Make("ui_balance_export", new() { ["save"] = save, ["group"] = group }));
            }
            default:
                return Error("Usage: balance verify | balance export [save] [group] | balance diff [group] | balance summary [group]");
        }
    }

    private static Dictionary<string, object> ParseGather(string[] tokens)
    {
        if (tokens.Length != 3)
            return Error("Usage: gather <resource> <amount>");
        string resource = tokens[1].ToLowerInvariant();
        if (!GameState.ResourceKeys.Contains(resource))
            return Error($"Unknown resource: {resource}");
        if (!IsValidInt(tokens[2], out int amount) || amount <= 0)
            return Error("Amount must be a positive integer.");
        return Ok(SimIntents.Make("gather", new() { ["resource"] = resource, ["amount"] = amount }));
    }

    private static Dictionary<string, object> ParseSeed(string trimmed, string verb)
    {
        string seedValue = trimmed.Length > verb.Length ? trimmed[(verb.Length)..].Trim() : "";
        if (string.IsNullOrEmpty(seedValue))
            return Error("Usage: seed <string>");
        return Ok(SimIntents.Make("seed", new() { ["seed"] = seedValue }));
    }

    private static Dictionary<string, object> ParseBuild(string[] tokens)
    {
        if (tokens.Length != 2 && tokens.Length != 4)
            return Error("Usage: build <type> [x y]");
        string buildType = tokens[1].ToLowerInvariant();
        if (!BuildingsData.IsValid(buildType))
            return Error($"Unknown build type: {buildType}");
        var payload = new Dictionary<string, object> { ["building"] = buildType };
        if (tokens.Length == 4)
        {
            if (!IsValidInt(tokens[2], out int x) || !IsValidInt(tokens[3], out int y))
                return Error("Build coordinates must be integers.");
            payload["x"] = x;
            payload["y"] = y;
        }
        return Ok(SimIntents.Make("build", payload));
    }

    private static Dictionary<string, object> ParseCursor(string[] tokens)
    {
        if (tokens.Length >= 2 && tokens.Length <= 3)
        {
            string direction = tokens[1].ToLowerInvariant();
            var dirMap = new Dictionary<string, (int dx, int dy)>
            {
                ["up"] = (0, -1), ["down"] = (0, 1),
                ["left"] = (-1, 0), ["right"] = (1, 0)
            };
            if (dirMap.TryGetValue(direction, out var delta))
            {
                int steps = 1;
                if (tokens.Length == 3)
                {
                    if (!IsValidInt(tokens[2], out steps) || steps <= 0)
                        return Error("Cursor steps must be a positive integer.");
                }
                return Ok(SimIntents.Make("cursor_move", new() { ["dx"] = delta.dx, ["dy"] = delta.dy, ["steps"] = steps }));
            }
        }
        if (tokens.Length != 3)
            return Error("Usage: cursor <x> <y> OR cursor <direction> [n]");
        if (!IsValidInt(tokens[1], out int cx) || !IsValidInt(tokens[2], out int cy))
            return Error("Cursor coordinates must be integers.");
        return Ok(SimIntents.Make("cursor", new() { ["x"] = cx, ["y"] = cy }));
    }

    private static Dictionary<string, object> ParseInspect(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("inspect"));
        if (tokens.Length != 3)
            return Error("Usage: inspect [x y]");
        if (!IsValidInt(tokens[1], out int x) || !IsValidInt(tokens[2], out int y))
            return Error("Inspect coordinates must be integers.");
        return Ok(SimIntents.Make("inspect", new() { ["x"] = x, ["y"] = y }));
    }

    private static Dictionary<string, object> ParseZone(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("zone_show"));
        if (tokens.Length == 2 && tokens[1].ToLowerInvariant() == "summary")
            return Ok(SimIntents.Make("zone_summary"));
        return Error("Usage: zone [summary]");
    }

    private static Dictionary<string, object> ParseDemolish(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("demolish"));
        if (tokens.Length != 3)
            return Error("Usage: demolish [x y]");
        if (!IsValidInt(tokens[1], out int x) || !IsValidInt(tokens[2], out int y))
            return Error("Demolish coordinates must be integers.");
        return Ok(SimIntents.Make("demolish", new() { ["x"] = x, ["y"] = y }));
    }

    private static Dictionary<string, object> ParsePreview(string[] tokens)
    {
        if (tokens.Length != 2)
            return Error("Usage: preview <type|none>");
        string previewType = tokens[1].ToLowerInvariant();
        if (previewType == "none")
            return Ok(SimIntents.Make("ui_preview", new() { ["building"] = "" }));
        if (!BuildingsData.IsValid(previewType))
            return Error($"Unknown build type: {previewType}");
        return Ok(SimIntents.Make("ui_preview", new() { ["building"] = previewType }));
    }

    private static Dictionary<string, object> ParseUpgrade(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("upgrade"));
        if (tokens.Length != 3)
            return Error("Usage: upgrade [x y]");
        if (!IsValidInt(tokens[1], out int x) || !IsValidInt(tokens[2], out int y))
            return Error("Upgrade coordinates must be integers.");
        return Ok(SimIntents.Make("upgrade", new() { ["x"] = x, ["y"] = y }));
    }

    private static Dictionary<string, object> ParseOverlay(string[] tokens)
    {
        if (tokens.Length != 3)
            return Error("Usage: overlay path <on|off>");
        if (tokens[1].ToLowerInvariant() != "path")
            return Error($"Unknown overlay: {tokens[1]}");
        string mode = tokens[2].ToLowerInvariant();
        if (mode != "on" && mode != "off")
            return Error("Usage: overlay path <on|off>");
        return Ok(SimIntents.Make("ui_overlay", new() { ["name"] = "path", ["enabled"] = mode == "on" }));
    }

    private static Dictionary<string, object> ParseToggleMode(string[] tokens, string cmdName, string intentKind)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make(intentKind, new() { ["mode"] = "toggle" }));
        if (tokens.Length == 2)
        {
            string mode = tokens[1].ToLowerInvariant();
            if (mode is "show" or "hide" or "toggle" or "clear")
                return Ok(SimIntents.Make(intentKind, new() { ["mode"] = mode }));
        }
        return Error($"Usage: {cmdName} [show|hide|clear]");
    }

    private static Dictionary<string, object> ParseGoal(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("ui_goal_show"));
        if (tokens.Length == 2)
        {
            string goalId = tokens[1].ToLowerInvariant();
            if (goalId == "next")
                return Ok(SimIntents.Make("ui_goal_next"));
            return Ok(SimIntents.Make("ui_goal_set", new() { ["goal_id"] = goalId }));
        }
        return Error("Usage: goal [id|next]");
    }

    private static Dictionary<string, object> ParseLessons(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("ui_lessons_toggle"));
        string sub = tokens[1].ToLowerInvariant();
        if (sub == "sort")
        {
            if (tokens.Length == 2) return Ok(SimIntents.Make("ui_lessons_sort", new() { ["mode"] = "show" }));
            if (tokens.Length == 3) return Ok(SimIntents.Make("ui_lessons_sort", new() { ["mode"] = tokens[2].ToLowerInvariant() }));
            return Error("Usage: lessons sort [default|recent|name]");
        }
        if (sub == "sparkline")
        {
            if (tokens.Length == 2) return Ok(SimIntents.Make("ui_lessons_sparkline", new() { ["mode"] = "show" }));
            if (tokens.Length == 3)
            {
                string m = tokens[2].ToLowerInvariant();
                if (m is "on" or "off")
                    return Ok(SimIntents.Make("ui_lessons_sparkline", new() { ["enabled"] = m == "on" }));
            }
            return Error("Usage: lessons sparkline [on|off]");
        }
        if (sub == "reset")
        {
            if (tokens.Length == 2) return Ok(SimIntents.Make("ui_lessons_reset", new() { ["scope"] = "current" }));
            if (tokens.Length == 3 && tokens[2].ToLowerInvariant() == "all")
                return Ok(SimIntents.Make("ui_lessons_reset", new() { ["scope"] = "all" }));
        }
        return Error("Usage: lessons [reset [all]] | lessons sort [default|recent|name] | lessons sparkline [on|off]");
    }

    private static Dictionary<string, object> ParseLesson(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("lesson_show"));
        if (tokens.Length == 2)
        {
            string arg = tokens[1].ToLowerInvariant();
            return arg switch
            {
                "next" => Ok(SimIntents.Make("lesson_next")),
                "prev" => Ok(SimIntents.Make("lesson_prev")),
                "sample" => Ok(SimIntents.Make("lesson_sample", new() { ["count"] = 3 })),
                _ => Ok(SimIntents.Make("lesson_set", new() { ["lesson_id"] = arg }))
            };
        }
        if (tokens.Length == 3 && tokens[1].ToLowerInvariant() == "sample")
        {
            if (!IsValidInt(tokens[2], out int count) || count <= 0)
                return Error("Sample count must be a positive integer.");
            return Ok(SimIntents.Make("lesson_sample", new() { ["count"] = count }));
        }
        return Error("Usage: lesson [id|next|prev|sample [n]]");
    }

    private static Dictionary<string, object> ParseSettings(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("ui_settings_toggle"));
        string mode = tokens[1].ToLowerInvariant();
        return mode switch
        {
            "show" => Ok(SimIntents.Make("ui_settings_show")),
            "hide" => Ok(SimIntents.Make("ui_settings_hide")),
            "lessons" => Ok(SimIntents.Make("ui_settings_lessons")),
            "prefs" => Ok(SimIntents.Make("ui_settings_prefs")),
            "verify" when tokens.Length == 2 => Ok(SimIntents.Make("ui_settings_verify")),
            "conflicts" when tokens.Length == 2 => Ok(SimIntents.Make("ui_settings_conflicts")),
            "resolve" => ParseSettingsResolve(tokens),
            "export" => ParseSettingsExport(tokens),
            "scale" or "font" => ParseSettingsScale(tokens),
            "compact" => ParseSettingsCompact(tokens),
            "motion" or "reducedmotion" => ParseSettingsMotion(tokens),
            "speed" or "gamespeed" => ParseSettingsSpeed(tokens),
            "contrast" or "highcontrast" => ParseSettingsContrast(tokens),
            "hints" or "navhints" or "nav" => ParseSettingsHints(tokens),
            "practice" or "practicemode" => ParseSettingsPractice(tokens),
            _ => Error("Usage: settings [show|hide|lessons|prefs|verify|conflicts|resolve|export|scale|font|compact|motion|speed|contrast|hints|practice]")
        };
    }

    private static Dictionary<string, object> ParseSettingsResolve(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_resolve", new() { ["apply"] = false }));
        if (tokens.Length == 3 && tokens[2].ToLowerInvariant() == "apply")
            return Ok(SimIntents.Make("ui_settings_resolve", new() { ["apply"] = true }));
        return Error("Usage: settings resolve [apply]");
    }

    private static Dictionary<string, object> ParseSettingsExport(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_export", new() { ["save"] = false }));
        if (tokens.Length == 3 && tokens[2].ToLowerInvariant() == "save")
            return Ok(SimIntents.Make("ui_settings_export", new() { ["save"] = true }));
        return Error("Usage: settings export [save]");
    }

    private static Dictionary<string, object> ParseSettingsScale(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_scale", new() { ["mode"] = "show" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg == "reset") return Ok(SimIntents.Make("ui_settings_scale", new() { ["mode"] = "reset" }));
            if (arg == "+") return Ok(SimIntents.Make("ui_settings_scale", new() { ["mode"] = "step", ["delta"] = 1 }));
            if (arg == "-") return Ok(SimIntents.Make("ui_settings_scale", new() { ["mode"] = "step", ["delta"] = -1 }));
            if (IsValidInt(arg, out int val))
                return Ok(SimIntents.Make("ui_settings_scale", new() { ["mode"] = "set", ["value"] = val }));
        }
        return Error("Usage: settings scale|font [80|90|100|110|120|130|140|+|-|reset]");
    }

    private static Dictionary<string, object> ParseSettingsCompact(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_compact", new() { ["mode"] = "show" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg is "on" or "off" or "toggle")
                return Ok(SimIntents.Make("ui_settings_compact", new() { ["mode"] = arg }));
        }
        return Error("Usage: settings compact [on|off|toggle]");
    }

    private static Dictionary<string, object> ParseSettingsMotion(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_motion", new() { ["mode"] = "toggle" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg is "on" or "off" or "toggle" or "reduced" or "full")
                return Ok(SimIntents.Make("ui_settings_motion", new() { ["mode"] = arg }));
        }
        return Error("Usage: settings motion [on|off|toggle|reduced|full]");
    }

    private static Dictionary<string, object> ParseSettingsSpeed(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_speed", new() { ["mode"] = "show" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg is "slower" or "down" or "-") return Ok(SimIntents.Make("ui_settings_speed", new() { ["mode"] = "slower" }));
            if (arg is "faster" or "up" or "+") return Ok(SimIntents.Make("ui_settings_speed", new() { ["mode"] = "faster" }));
            if (arg is "reset" or "normal" or "1" or "1.0") return Ok(SimIntents.Make("ui_settings_speed", new() { ["mode"] = "reset" }));
            if (IsValidFloat(arg, out float val) && val >= 0.5f && val <= 2.0f)
                return Ok(SimIntents.Make("ui_settings_speed", new() { ["mode"] = "set", ["value"] = val }));
        }
        return Error("Usage: settings speed [slower|faster|reset|0.5-2.0]");
    }

    private static Dictionary<string, object> ParseSettingsContrast(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_contrast", new() { ["mode"] = "toggle" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg is "on" or "off" or "toggle" or "high" or "normal")
                return Ok(SimIntents.Make("ui_settings_contrast", new() { ["mode"] = arg }));
        }
        return Error("Usage: settings contrast [on|off|toggle|high|normal]");
    }

    private static Dictionary<string, object> ParseSettingsHints(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_hints", new() { ["mode"] = "toggle" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg is "on" or "off" or "toggle" or "show" or "hide")
                return Ok(SimIntents.Make("ui_settings_hints", new() { ["mode"] = arg }));
        }
        return Error("Usage: settings hints [on|off|toggle|show|hide]");
    }

    private static Dictionary<string, object> ParseSettingsPractice(string[] tokens)
    {
        if (tokens.Length == 2) return Ok(SimIntents.Make("ui_settings_practice", new() { ["mode"] = "toggle" }));
        if (tokens.Length == 3)
        {
            string arg = tokens[2].ToLowerInvariant();
            if (arg is "on" or "off" or "toggle")
                return Ok(SimIntents.Make("ui_settings_practice", new() { ["mode"] = arg }));
        }
        return Error("Usage: settings practice [on|off|toggle]");
    }

    private static Dictionary<string, object> ParseTutorial(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("ui_tutorial_toggle"));
        if (tokens.Length == 2)
        {
            string m = tokens[1].ToLowerInvariant();
            if (m is "restart" or "replay") return Ok(SimIntents.Make("ui_tutorial_restart"));
            if (m == "skip") return Ok(SimIntents.Make("ui_tutorial_skip"));
        }
        return Error("Usage: tutorial [restart|skip]");
    }

    private static Dictionary<string, object> ParseBind(string[] tokens)
    {
        if (tokens.Length == 2)
            return Ok(SimIntents.Make("ui_bind_action", new() { ["action"] = tokens[1].ToLowerInvariant() }));
        if (tokens.Length == 3)
        {
            string action = tokens[1].ToLowerInvariant();
            if (tokens[2].ToLowerInvariant() == "reset")
                return Ok(SimIntents.Make("ui_bind_action_reset", new() { ["action"] = action }));
            return Ok(SimIntents.Make("ui_bind_action", new() { ["action"] = action, ["key_text"] = tokens[2] }));
        }
        return Error("Usage: bind <action> [key|reset]");
    }

    private static Dictionary<string, object> ParseDefend(string trimmed, string verb)
    {
        string text = trimmed.Length > verb.Length ? trimmed[(verb.Length)..].Trim() : "";
        if (string.IsNullOrEmpty(text))
            return Error("Usage: defend <text>");
        return Ok(SimIntents.Make("defend_input", new() { ["text"] = text }));
    }

    private static Dictionary<string, object> ParseChoice(string trimmed, string[] tokens)
    {
        if (tokens.Length < 2)
            return Error("Usage: choice <id> [input text]");
        string choiceId = tokens[1].ToLowerInvariant();
        string inputText = "";
        int prefixLen = tokens[0].Length + 1 + tokens[1].Length;
        if (trimmed.Length > prefixLen)
            inputText = trimmed[prefixLen..].Trim();
        return Ok(SimIntents.Make("event_choice", new() { ["choice_id"] = choiceId, ["input"] = inputText }));
    }

    private static Dictionary<string, object> ParseBuy(string[] tokens)
    {
        if (tokens.Length < 3)
            return Error("Usage: buy <kingdom|unit> <upgrade_id>");
        string category = tokens[1].ToLowerInvariant();
        if (category is not "kingdom" and not "unit")
            return Error("Category must be 'kingdom' or 'unit'");
        return Ok(SimIntents.Make("buy_upgrade", new() { ["category"] = category, ["upgrade_id"] = tokens[2].ToLowerInvariant() }));
    }

    private static Dictionary<string, object> ParseUpgrades(string[] tokens)
    {
        string category = "kingdom";
        if (tokens.Length > 1)
        {
            category = tokens[1].ToLowerInvariant();
            if (category is not "kingdom" and not "unit")
                return Error("Category must be 'kingdom' or 'unit'");
        }
        return Ok(SimIntents.Make("ui_upgrades", new() { ["category"] = category }));
    }

    private static Dictionary<string, object> ParseResearch(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("research_show"));
        string sub = tokens[1].ToLowerInvariant();
        if (sub == "cancel")
            return Ok(SimIntents.Make("research_cancel"));
        return Ok(SimIntents.Make("research_start", new() { ["research_id"] = sub }));
    }

    private static Dictionary<string, object> ParseTrade(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("trade_show"));
        if (tokens.Length < 5)
            return Error("Usage: trade <amount> <resource> for <resource>");
        if (!IsValidInt(tokens[1], out int amount) || amount <= 0)
            return Error("Amount must be a positive number.");
        string fromResource = tokens[2].ToLowerInvariant();
        string connector = tokens[3].ToLowerInvariant();
        if (connector is not "for" and not "to")
            return Error("Usage: trade <amount> <resource> for <resource>");
        string toResource = tokens[4].ToLowerInvariant();
        return Ok(SimIntents.Make("trade_execute", new()
        {
            ["from_resource"] = fromResource,
            ["to_resource"] = toResource,
            ["amount"] = amount
        }));
    }

    private static Dictionary<string, object> ParseLoot(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("loot_preview"));
        if (tokens.Length == 2 && tokens[1].ToLowerInvariant() == "collect")
            return Ok(SimIntents.Make("collect_loot"));
        return Error("Usage: loot [collect]");
    }

    private static Dictionary<string, object> ParseExpedition(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("expeditions_list"));
        if (tokens.Length == 2)
        {
            string sub = tokens[1].ToLowerInvariant();
            if (sub == "status")
                return Ok(SimIntents.Make("expedition_status"));
            return Ok(SimIntents.Make("start_expedition", new() { ["expedition_id"] = sub, ["workers"] = 1 }));
        }
        if (tokens.Length == 3)
        {
            string sub = tokens[1].ToLowerInvariant();
            if (sub == "cancel")
            {
                if (!IsValidInt(tokens[2], out int id))
                    return Error("Expedition ID must be a number.");
                return Ok(SimIntents.Make("cancel_expedition", new() { ["id"] = id }));
            }
            if (!IsValidInt(tokens[2], out int workers))
                return Error("Worker count must be a number.");
            return Ok(SimIntents.Make("start_expedition", new() { ["expedition_id"] = sub, ["workers"] = workers }));
        }
        return Error("Usage: expedition [id [workers]] | expedition status | expedition cancel <id>");
    }

    private static Dictionary<string, object> ParseHarvest(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("harvest_node"));
        if (tokens.Length == 3)
        {
            if (!IsValidInt(tokens[1], out int x) || !IsValidInt(tokens[2], out int y))
                return Error("Harvest coordinates must be integers.");
            return Ok(SimIntents.Make("harvest_node", new() { ["x"] = x, ["y"] = y }));
        }
        return Error("Usage: harvest [x y]");
    }

    private static Dictionary<string, object> ParseHero(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("hero_show"));
        if (tokens.Length == 2)
        {
            string arg = tokens[1].ToLowerInvariant();
            if (arg == "none")
                return Ok(SimIntents.Make("hero_clear"));
            if (!HeroTypes.IsValidHero(arg))
                return Error($"Unknown hero: {arg}. Type 'hero' to see available heroes.");
            return Ok(SimIntents.Make("hero_set", new() { ["hero_id"] = arg }));
        }
        return Error("Usage: hero [hero_id|none]");
    }

    private static Dictionary<string, object> ParseLocale(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("locale_show"));
        if (tokens.Length == 2)
        {
            string arg = tokens[1].ToLowerInvariant();
            if (!Locale.SupportedLocales.Contains(arg))
                return Error($"Unknown locale: {arg}. Type 'locale' to see available languages.");
            return Ok(SimIntents.Make("locale_set", new() { ["locale"] = arg }));
        }
        return Error("Usage: locale [locale_id]");
    }

    private static Dictionary<string, object> ParseTitle(string[] tokens)
    {
        if (tokens.Length == 1)
            return Ok(SimIntents.Make("titles_show"));
        if (tokens.Length == 2)
        {
            string arg = tokens[1].ToLowerInvariant();
            if (arg == "none")
                return Ok(SimIntents.Make("title_clear"));
            if (!Titles.IsValidTitle(arg))
                return Error($"Unknown title: {arg}. Type 'titles' to see your titles.");
            return Ok(SimIntents.Make("title_equip", new() { ["title_id"] = arg }));
        }
        return Error("Usage: title [title_id|none]");
    }

    private static Dictionary<string, object> ParseTarget(string[] tokens)
    {
        if (tokens.Length == 1)
            return Error("Usage: target <nearest|strongest|fastest|weakest|first>");
        if (tokens.Length != 2)
            return Error("Usage: target <nearest|strongest|fastest|weakest|first>");
        string mode = tokens[1].ToLowerInvariant();
        if (mode is not "nearest" and not "strongest" and not "fastest" and not "weakest" and not "first")
            return Error($"Unknown targeting mode: {mode}. Valid: nearest, strongest, fastest, weakest, first");
        return Ok(SimIntents.Make("set_targeting", new() { ["mode"] = mode }));
    }

    private static bool Contains(string[] arr, string value)
    {
        foreach (var item in arr)
            if (item == value) return true;
        return false;
    }
}
