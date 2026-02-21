using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class EventsCoreTests
{
    [Fact]
    public void TriggerEvent_SetsPendingEventOnState()
    {
        var state = CreateState();

        Events.TriggerEvent(state, "evt_intro", EventData("Mysterious Visitor", "A stranger approaches.", new List<object>()));

        Assert.Equal("evt_intro", state.PendingEvent["event_id"]);
        Assert.True(state.PendingEvent.ContainsKey("title"));
        Assert.True(state.PendingEvent.ContainsKey("description"));
        Assert.True(state.PendingEvent.ContainsKey("choices"));
    }

    [Fact]
    public void TriggerEvent_ReturnsOkTrue()
    {
        var state = CreateState();

        var result = Events.TriggerEvent(state, "evt_trader", EventData("Traveling Trader", "He offers wares.", new List<object>()));

        Assert.True((bool)result["ok"]);
    }

    [Fact]
    public void TriggerEvent_CopiesTitleAndDescription()
    {
        var state = CreateState();

        Events.TriggerEvent(state, "evt_library", EventData("Hidden Library", "Dusty tomes line the walls.", new List<object>()));

        Assert.Equal("Hidden Library", state.PendingEvent["title"]);
        Assert.Equal("Dusty tomes line the walls.", state.PendingEvent["description"]);
    }

    [Fact]
    public void TriggerEvent_UsesDefaultsWhenFieldsMissing()
    {
        var state = CreateState();

        Events.TriggerEvent(state, "evt_defaulted", new Dictionary<string, object>());

        Assert.Equal("Unknown Event", state.PendingEvent["title"]);
        Assert.Equal("", state.PendingEvent["description"]);
        var choices = Assert.IsType<List<object>>(state.PendingEvent["choices"]);
        Assert.Empty(choices);
    }

    [Fact]
    public void TriggerEvent_MessageFallsBackToEventIdWhenTitleMissing()
    {
        var state = CreateState();

        var result = Events.TriggerEvent(state, "evt_fallback", new Dictionary<string, object>());

        Assert.Equal("Event triggered: evt_fallback", result["message"]);
    }

    [Fact]
    public void HasPendingEvent_FalseInitially()
    {
        var state = CreateState();

        Assert.False(Events.HasPendingEvent(state));
    }

    [Fact]
    public void HasPendingEvent_TrueAfterTrigger()
    {
        var state = CreateState();
        Events.TriggerEvent(state, "evt_sign", EventData("Road Sign", "An arrow points east.", new List<object>()));

        Assert.True(Events.HasPendingEvent(state));
    }

    [Fact]
    public void SkipEvent_ClearsPendingEvent()
    {
        var state = CreateState();
        Events.TriggerEvent(state, "evt_ruins", EventData("Ancient Ruins", "Broken stone arches.", new List<object>()));

        Events.SkipEvent(state);

        Assert.Empty(state.PendingEvent);
        Assert.False(Events.HasPendingEvent(state));
    }

    [Fact]
    public void SkipEvent_ReturnsOkTrueWhenPendingEventExists()
    {
        var state = CreateState();
        Events.TriggerEvent(state, "evt_feast", EventData("Village Feast", "Music fills the square.", new List<object>()));

        var result = Events.SkipEvent(state);

        Assert.True((bool)result["ok"]);
        Assert.Equal("Skipped event: Village Feast", result["message"]);
    }

    [Fact]
    public void SkipEvent_ReturnsOkFalseWhenNoPendingEvent()
    {
        var state = CreateState();

        var result = Events.SkipEvent(state);

        Assert.False((bool)result["ok"]);
        Assert.Equal("No pending event.", result["error"]);
    }

    [Fact]
    public void ResolveChoice_WithNoPendingEvent_ReturnsOkFalse()
    {
        var state = CreateState();

        var result = Events.ResolveChoice(state, 0);

        Assert.False((bool)result["ok"]);
        Assert.Equal("No pending event.", result["error"]);
    }

    [Fact]
    public void ResolveChoice_WithNegativeChoiceIndex_ReturnsOkFalse()
    {
        var state = CreateState();
        Events.TriggerEvent(state, "evt_dilemma", EventData("Fork in the Road", "Choose a direction.", new List<object> { Choice(new List<object>()) }));

        var result = Events.ResolveChoice(state, -1);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Invalid choice.", result["error"]);
        Assert.True(Events.HasPendingEvent(state));
    }

    [Fact]
    public void ResolveChoice_WithOutOfRangeChoiceIndex_ReturnsOkFalse()
    {
        var state = CreateState();
        Events.TriggerEvent(state, "evt_dilemma", EventData("Fork in the Road", "Choose a direction.", new List<object> { Choice(new List<object>()) }));

        var result = Events.ResolveChoice(state, 1);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Invalid choice.", result["error"]);
        Assert.True(Events.HasPendingEvent(state));
    }

    [Fact]
    public void ResolveChoice_WithInvalidChoiceData_ReturnsOkFalse()
    {
        var state = CreateState();
        Events.TriggerEvent(state, "evt_broken", EventData("Corrupted Event", "Choice payload is malformed.", new List<object> { "not_a_choice_dict" }));

        var result = Events.ResolveChoice(state, 0);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Invalid choice data.", result["error"]);
        Assert.True(Events.HasPendingEvent(state));
    }

    [Fact]
    public void ResolveChoice_WithValidChoice_ClearsEventAndAppliesEffects()
    {
        var state = CreateState();
        state.Resources["wood"] = 1;
        state.Gold = 10;

        var effects = new List<object>
        {
            Effect("resource_add", ("resource", "wood"), ("amount", 3)),
            Effect("gold_add", ("amount", -2))
        };

        Events.TriggerEvent(state, "evt_tradeoff", EventData("Risky Trade", "A costly shortcut.", new List<object> { Choice(effects) }));

        Events.ResolveChoice(state, 0);

        Assert.Equal(4, state.Resources["wood"]);
        Assert.Equal(8, state.Gold);
        Assert.Empty(state.PendingEvent);
        Assert.False(Events.HasPendingEvent(state));
    }

    [Fact]
    public void ResolveChoice_ReturnsOkTrueOnSuccess()
    {
        var state = CreateState();
        var effects = new List<object> { Effect("gold_add", ("amount", 5)) };
        Events.TriggerEvent(state, "evt_reward", EventData("Found Cache", "A stash of coins.", new List<object> { Choice(effects) }));

        var result = Events.ResolveChoice(state, 0);

        Assert.True((bool)result["ok"]);
        Assert.Equal("Resolved: Found Cache", result["message"]);
        var messages = Assert.IsType<List<string>>(result["effects"]);
        Assert.Single(messages);
        Assert.Equal("+5 gold", messages[0]);
    }

    [Fact]
    public void ResolveChoice_WithNoEffectsList_StillSucceedsAndReturnsEmptyEffects()
    {
        var state = CreateState();
        var choice = new Dictionary<string, object> { ["text"] = "Observe quietly" };
        Events.TriggerEvent(state, "evt_quiet", EventData("Silent Glade", "Nothing stirs.", new List<object> { choice }));

        var result = Events.ResolveChoice(state, 0);

        Assert.True((bool)result["ok"]);
        var messages = Assert.IsType<List<string>>(result["effects"]);
        Assert.Empty(messages);
        Assert.Empty(state.PendingEvent);
    }

    [Fact]
    public void ResolveChoice_IgnoresInvalidEffectsAndEmptyMessages()
    {
        var state = CreateState();

        var effects = new List<object>
        {
            "bad_effect_shape",
            Effect("set_flag", ("flag", "met_scout")),
            Effect("gold_add", ("amount", 2))
        };

        Events.TriggerEvent(state, "evt_mix", EventData("Scouting Report", "Mixed outcome.", new List<object> { Choice(effects) }));

        var result = Events.ResolveChoice(state, 0);

        Assert.True((bool)result["ok"]);
        Assert.True((bool)state.EventFlags["met_scout"]);
        Assert.Equal(12, state.Gold);
        var messages = Assert.IsType<List<string>>(result["effects"]);
        Assert.Single(messages);
        Assert.Equal("+2 gold", messages[0]);
    }

    [Fact]
    public void MultipleTriggerSkipCycles_WorkAsExpected()
    {
        var state = CreateState();

        Events.TriggerEvent(state, "evt_one", EventData("First Event", "First description.", new List<object>()));
        var firstSkip = Events.SkipEvent(state);
        Events.TriggerEvent(state, "evt_two", EventData("Second Event", "Second description.", new List<object>()));
        var secondSkip = Events.SkipEvent(state);

        Assert.True((bool)firstSkip["ok"]);
        Assert.True((bool)secondSkip["ok"]);
        Assert.Equal("Skipped event: Second Event", secondSkip["message"]);
        Assert.Empty(state.PendingEvent);
        Assert.False(Events.HasPendingEvent(state));
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create("events_core_tests");
        state.PendingEvent.Clear();
        state.EventFlags.Clear();
        return state;
    }

    private static Dictionary<string, object> EventData(string title, string description, List<object> choices)
    {
        return new Dictionary<string, object>
        {
            ["title"] = title,
            ["description"] = description,
            ["choices"] = choices
        };
    }

    private static Dictionary<string, object> Choice(List<object> effects)
    {
        return new Dictionary<string, object>
        {
            ["text"] = "Choose",
            ["effects"] = effects
        };
    }

    private static Dictionary<string, object> Effect(string type, params (string Key, object Value)[] entries)
    {
        var effect = new Dictionary<string, object>
        {
            ["type"] = type
        };

        foreach (var (key, value) in entries)
            effect[key] = value;

        return effect;
    }
}
