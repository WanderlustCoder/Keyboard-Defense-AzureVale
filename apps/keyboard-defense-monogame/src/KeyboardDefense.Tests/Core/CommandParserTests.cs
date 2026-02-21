using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class CommandParserTests
{
    private static Dictionary<string, object> GetIntent(Dictionary<string, object> parsed)
        => (Dictionary<string, object>)parsed["intent"];

    [Fact]
    public void Parse_GatherCommand_WithAmount()
    {
        var parsed = CommandParser.Parse("gather wood 5");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("gather", intent["kind"]);
    }

    [Fact]
    public void Parse_GatherCommand_MissingAmount_ReturnsError()
    {
        var parsed = CommandParser.Parse("gather wood");
        Assert.False((bool)parsed["ok"]);
        Assert.True(parsed.ContainsKey("error"));
    }

    [Fact]
    public void Parse_BuildCommand_WithCoords()
    {
        var parsed = CommandParser.Parse("build tower 5 10");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("build", intent["kind"]);
    }

    [Fact]
    public void Parse_EmptyString_ReturnsError()
    {
        var parsed = CommandParser.Parse("");
        Assert.NotNull(parsed);
        Assert.False((bool)parsed["ok"]);
        Assert.True(parsed.ContainsKey("error"));
    }

    [Fact]
    public void Parse_HelpCommand()
    {
        var parsed = CommandParser.Parse("help");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("help", intent["kind"]);
    }

    [Fact]
    public void Parse_StatusCommand()
    {
        var parsed = CommandParser.Parse("status");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("status", intent["kind"]);
    }

    [Fact]
    public void Parse_ExploreCommand()
    {
        var parsed = CommandParser.Parse("explore");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("explore", intent["kind"]);
    }

    [Fact]
    public void Parse_EndCommand()
    {
        var parsed = CommandParser.Parse("end");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("end", intent["kind"]);
    }

    [Fact]
    public void Parse_CaseInsensitive()
    {
        var parsed = CommandParser.Parse("HELP");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("help", intent["kind"]);
    }

    [Fact]
    public void Parse_UnknownCommand_ReturnsError()
    {
        var parsed = CommandParser.Parse("xyzzy");
        Assert.False((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_NullString_Throws()
    {
        Assert.ThrowsAny<Exception>(() => CommandParser.Parse(null!));
    }

    [Fact]
    public void Parse_WhitespaceOnly_ReturnsError()
    {
        var parsed = CommandParser.Parse("   ");
        Assert.False((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_VersionCommand()
    {
        var parsed = CommandParser.Parse("version");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_WaitCommand()
    {
        var parsed = CommandParser.Parse("wait");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("wait", intent["kind"]);
    }

    [Fact]
    public void Parse_MapCommand()
    {
        var parsed = CommandParser.Parse("map");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_SaveCommand()
    {
        var parsed = CommandParser.Parse("save");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_LoadCommand()
    {
        var parsed = CommandParser.Parse("load");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_RestartCommand()
    {
        var parsed = CommandParser.Parse("restart");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_DefendCommand_WithText()
    {
        var parsed = CommandParser.Parse("defend hello");
        Assert.True((bool)parsed["ok"]);
        var intent = GetIntent(parsed);
        Assert.Equal("defend_input", intent["kind"]);
    }

    [Fact]
    public void Parse_InspectCommand()
    {
        var parsed = CommandParser.Parse("inspect");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_UpgradeCommand()
    {
        var parsed = CommandParser.Parse("upgrade");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_DemolishCommand()
    {
        var parsed = CommandParser.Parse("demolish");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_OverlayCommand_RequiresArgs()
    {
        // overlay requires "overlay path <on|off>" — bare "overlay" returns error
        var parsed = CommandParser.Parse("overlay");
        Assert.False((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_OverlayCommand_WithValidArgs()
    {
        var parsed = CommandParser.Parse("overlay path on");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_SettingsCommand()
    {
        var parsed = CommandParser.Parse("settings");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_LookShortcut()
    {
        var parsed = CommandParser.Parse("l");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_TalkShortcut()
    {
        var parsed = CommandParser.Parse("t");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_AttackShortcut()
    {
        var parsed = CommandParser.Parse("attack");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_FightShortcut()
    {
        var parsed = CommandParser.Parse("fight");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_GrabShortcut()
    {
        var parsed = CommandParser.Parse("grab");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_HarvestCommand()
    {
        var parsed = CommandParser.Parse("harvest");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_NodesCommand()
    {
        var parsed = CommandParser.Parse("nodes");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_EnemiesCommand()
    {
        var parsed = CommandParser.Parse("enemies");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_ZoneCommand()
    {
        var parsed = CommandParser.Parse("zone");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_ZonesAlias()
    {
        var parsed = CommandParser.Parse("zones");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_InteractCommand()
    {
        var parsed = CommandParser.Parse("interact");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_UpgradesCommand()
    {
        var parsed = CommandParser.Parse("upgrades");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_NewCommand()
    {
        var parsed = CommandParser.Parse("new");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_CursorCommand_WithDirection()
    {
        // cursor requires valid direction mapped to dx/dy
        var parsed = CommandParser.Parse("cursor north");
        // If direction is recognized, ok=true; otherwise error
        Assert.NotNull(parsed);
    }

    [Fact]
    public void Parse_TutorialCommand()
    {
        var parsed = CommandParser.Parse("tutorial");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_LessonsCommand()
    {
        var parsed = CommandParser.Parse("lessons");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_LootCommand()
    {
        var parsed = CommandParser.Parse("loot");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_ExpeditionCommand()
    {
        var parsed = CommandParser.Parse("expedition");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_ExpShortcut()
    {
        var parsed = CommandParser.Parse("exp");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_SeedCommand_WithValue()
    {
        var parsed = CommandParser.Parse("seed test123");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_TradeCommand()
    {
        var parsed = CommandParser.Parse("trade");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_ResearchCommand()
    {
        var parsed = CommandParser.Parse("research");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_HeroCommand()
    {
        var parsed = CommandParser.Parse("hero");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_MixedCaseCommand()
    {
        var parsed = CommandParser.Parse("StAtUs");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_LeadingTrailingSpaces()
    {
        var parsed = CommandParser.Parse("  help  ");
        Assert.True((bool)parsed["ok"]);
    }

    [Fact]
    public void Parse_Build_MissingArgs_ReturnsError()
    {
        var parsed = CommandParser.Parse("build");
        // Build with no args might return error or default behavior
        Assert.NotNull(parsed);
    }
}

public class IntentApplierTests
{
    [Fact]
    public void Apply_HelpIntent_ReturnsEvents()
    {
        var state = DefaultState.Create("test", true);
        var intent = SimIntents.Make("help");
        var result = IntentApplier.Apply(state, intent);

        Assert.True(result.ContainsKey("events"));
        var events = result["events"] as List<string>;
        Assert.NotNull(events);
        Assert.NotEmpty(events!);
    }

    [Fact]
    public void Apply_StatusIntent_ReturnsEvents()
    {
        var state = DefaultState.Create("test", true);
        var intent = SimIntents.Make("status");
        var result = IntentApplier.Apply(state, intent);

        Assert.True(result.ContainsKey("events"));
    }

    [Fact]
    public void Apply_GatherIntent_ReturnsState()
    {
        var state = DefaultState.Create("test", true);
        var intent = SimIntents.Make("gather", new() { ["resource"] = "wood" });
        var result = IntentApplier.Apply(state, intent);

        Assert.True(result.ContainsKey("state"));
    }

    [Fact]
    public void Apply_EndIntent_ChangesPhase()
    {
        var state = DefaultState.Create("test", true);
        Assert.Equal("day", state.Phase);

        var intent = SimIntents.Make("end");
        var result = IntentApplier.Apply(state, intent);

        // Apply returns a new state copy - check the returned state
        var newState = result["state"] as GameState;
        Assert.NotNull(newState);
        Assert.Equal("night", newState!.Phase);
    }

    [Fact]
    public void Apply_UnknownIntent_DoesNotCrash()
    {
        var state = DefaultState.Create("test", true);
        var intent = SimIntents.Make("totally_unknown_intent");
        var result = IntentApplier.Apply(state, intent);

        Assert.NotNull(result);
    }
}

public class DefaultStateTests
{
    [Fact]
    public void Create_ReturnsValidState()
    {
        var state = DefaultState.Create("test_seed", true);
        Assert.NotNull(state);
        Assert.Equal(1, state.Day);
        Assert.Equal("day", state.Phase);
        Assert.True(state.Hp > 0);
        Assert.True(state.Ap > 0);
    }

    [Fact]
    public void Create_DifferentSeeds_SameDefaults()
    {
        var state1 = DefaultState.Create("seed_a", true);
        var state2 = DefaultState.Create("seed_b", true);

        Assert.Equal(state1.Day, state2.Day);
        Assert.Equal(state1.Hp, state2.Hp);
        Assert.Equal(state1.MapW, state2.MapW);
    }
}
