using System.Collections.Generic;

namespace KeyboardDefense.Core.Intent;

/// <summary>
/// Intent factory for command creation.
/// Ported from sim/intents.gd (SimIntents class).
/// </summary>
public static class SimIntents
{
    public static Dictionary<string, object> Make(string kind, Dictionary<string, object>? data = null)
    {
        var intent = new Dictionary<string, object> { ["kind"] = kind };
        if (data != null)
        {
            foreach (var (key, value) in data)
            {
                intent[key] = value;
            }
        }
        return intent;
    }

    public static List<string> HelpLines()
    {
        return new List<string>
        {
            "Commands:",
            "  help - list commands",
            "  version - show game and engine versions",
            "  status - show phase and resources",
            "  gather <resource> <amount> - add resources (day only)",
            "  build <type> [x y] - place a building (day only)",
            "  build types: farm, lumber, quarry, wall, tower",
            "  auto-towers: auto_sentry, auto_spark, auto_thorns (Tier 1)",
            "  explore - reveal a tile and gain loot (day only)",
            "  interact - interact with nearby point of interest (day only)",
            "  choice <id> - select an event choice",
            "  skip - skip the current event",
            "  upgrades [kingdom|unit] - show upgrade tree",
            "  buy <kingdom|unit> <id> - purchase an upgrade",
            "  cursor <x> <y> - move cursor",
            "  cursor <dir> [n] - move cursor up/down/left/right",
            "  inspect [x y] - inspect tile at cursor or coords",
            "  map - print ASCII map",
            "  demolish [x y] - remove a structure (day only)",
            "  preview <type|none> - toggle build preview",
            "  wait - advance a night step without a miss penalty (night only)",
            "  overlay path <on|off> - toggle path overlay",
            "  upgrade [x y] - upgrade a tower or auto-tower (day only)",
            "  target <mode> - set targeting: nearest, strongest, fastest, weakest, first",
            "  enemies - list active enemies",
            "  report - toggle typing report panel",
            "  settings - toggle settings panel",
            "  end - finish day and begin night",
            "  seed <string> - set RNG seed",
            "  defend <text> - debug alias for night input",
            "  restart - restart after game over",
            "  save - write savegame.json",
            "  load - load savegame.json",
            "  new - start a new run",
            "Night:",
            "  Type an enemy word and press Enter",
            "Examples:",
            "  gather wood 10",
            "  build farm",
            "  build tower 9 5",
            "  explore",
            "  interact",
            "  choice a",
            "  cursor 8 5",
            "  cursor up 3",
        };
    }
}
