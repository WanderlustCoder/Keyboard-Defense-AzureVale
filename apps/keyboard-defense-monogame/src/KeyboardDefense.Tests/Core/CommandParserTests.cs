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
