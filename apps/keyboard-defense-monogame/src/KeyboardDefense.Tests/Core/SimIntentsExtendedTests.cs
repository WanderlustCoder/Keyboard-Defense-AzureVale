using System.Collections.Generic;
using KeyboardDefense.Core.Intent;

namespace KeyboardDefense.Tests.Core;

public class SimIntentsExtendedTests
{
    [Fact]
    public void Make_BuildIntent_WithPayload_PreservesAllFields()
    {
        var intent = SimIntents.Make("build", new Dictionary<string, object>
        {
            ["building"] = "tower",
            ["x"] = 9,
            ["y"] = 5,
        });

        Assert.Equal("build", intent["kind"]);
        Assert.Equal("tower", intent["building"]);
        Assert.Equal(9, intent["x"]);
        Assert.Equal(5, intent["y"]);
    }

    [Fact]
    public void Make_MoveIntent_WithVector_PreservesDirectionFields()
    {
        var intent = SimIntents.Make("move", new Dictionary<string, object>
        {
            ["dx"] = -1,
            ["dy"] = 2,
        });

        Assert.Equal("move", intent["kind"]);
        Assert.Equal(-1, intent["dx"]);
        Assert.Equal(2, intent["dy"]);
    }

    [Fact]
    public void Make_ExploreIntent_WithoutData_ReturnsKindOnly()
    {
        var intent = SimIntents.Make("explore");

        Assert.Equal("explore", intent["kind"]);
        Assert.Single(intent);
    }

    [Fact]
    public void Make_TradeIntent_WithPayload_PreservesResourcesAndAmount()
    {
        var intent = SimIntents.Make("trade", new Dictionary<string, object>
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 3,
        });

        Assert.Equal("trade", intent["kind"]);
        Assert.Equal("wood", intent["from_resource"]);
        Assert.Equal("stone", intent["to_resource"]);
        Assert.Equal(3, intent["amount"]);
    }

    [Fact]
    public void Make_CraftIntent_WithPayload_PreservesRecipeFields()
    {
        var intent = SimIntents.Make("craft", new Dictionary<string, object>
        {
            ["recipe_id"] = "iron_sword",
            ["quantity"] = 1,
        });

        Assert.Equal("craft", intent["kind"]);
        Assert.Equal("iron_sword", intent["recipe_id"]);
        Assert.Equal(1, intent["quantity"]);
    }

    [Fact]
    public void Make_AttackIntent_WithPayload_PreservesCombatFields()
    {
        var intent = SimIntents.Make("attack", new Dictionary<string, object>
        {
            ["target_id"] = 17,
            ["mode"] = "focused",
        });

        Assert.Equal("attack", intent["kind"]);
        Assert.Equal(17, intent["target_id"]);
        Assert.Equal("focused", intent["mode"]);
    }

    [Fact]
    public void Make_SpecialCommandIntent_AllowsEmptyStringValues()
    {
        var intent = SimIntents.Make("special_command", new Dictionary<string, object>
        {
            ["command"] = string.Empty,
            ["argument"] = string.Empty,
        });

        Assert.Equal("special_command", intent["kind"]);
        Assert.Equal(string.Empty, intent["command"]);
        Assert.Equal(string.Empty, intent["argument"]);
    }

    [Fact]
    public void Make_HelpIntent_WithNullData_ReturnsKindOnly()
    {
        var intent = SimIntents.Make("help", null);

        Assert.Equal("help", intent["kind"]);
        Assert.Single(intent);
    }

    [Fact]
    public void Make_WhenDataContainsKindKey_UsesDataKindValue()
    {
        var intent = SimIntents.Make("build", new Dictionary<string, object>
        {
            ["kind"] = "trade",
            ["amount"] = 4,
        });

        Assert.Equal("trade", intent["kind"]);
        Assert.Equal(4, intent["amount"]);
    }

    [Fact]
    public void Make_WhenDataContainsNullValue_PreservesNullEntry()
    {
        var intent = SimIntents.Make("trade", new Dictionary<string, object>
        {
            ["note"] = null!,
        });

        Assert.Equal("trade", intent["kind"]);
        Assert.True(intent.ContainsKey("note"));
        Assert.Null(intent["note"]);
    }

    [Fact]
    public void HelpLines_ReturnsAllDocumentedLines_InOrder()
    {
        var expected = new List<string>
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

        Assert.Equal(expected, SimIntents.HelpLines());
    }
}
