using System.Collections.Generic;

namespace KeyboardDefense.Core.Intent;

/// <summary>
/// Known command keywords for autocomplete/validation.
/// Ported from sim/command_keywords.gd.
/// </summary>
public static class CommandKeywords
{
    public static readonly string[] Keywords =
    {
        "help", "version", "status", "balance",
        "gather", "build", "explore", "interact",
        "choice", "skip", "buy", "upgrades",
        "end", "seed", "defend", "wait",
        "save", "load", "new", "restart",
        "cursor", "inspect", "map", "overlay",
        "preview", "upgrade", "demolish", "enemies",
        "goal", "lesson", "lessons", "settings",
        "bind", "report", "history", "trend", "tutorial",
        "research", "trade", "look", "talk", "take",
        "attack", "loot", "expedition", "harvest",
        "nodes", "hero", "locale", "title", "badge"
    };

    public static IReadOnlyList<string> GetKeywords() => Keywords;
}
