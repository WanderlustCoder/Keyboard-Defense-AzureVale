using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class EventTablesTests
{
    [Fact]
    public void SelectEvent_ReturnsNull_WhenTableIdIsUnknown()
    {
        var state = CreateState("event_tables_unknown");
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>());

        var selected = EventTables.SelectEvent(state, "missing_table");

        Assert.Null(selected);
    }

    [Fact]
    public void SelectEvent_ReturnsNull_WhenTableHasNoEntries()
    {
        var state = CreateState("event_tables_empty");
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["empty"] = new List<Dictionary<string, object>>()
        });

        var selected = EventTables.SelectEvent(state, "empty");

        Assert.Null(selected);
    }

    [Fact]
    public void SelectEvent_ReturnsOnlyEntryThatMatchesDayConditions()
    {
        var state = CreateState("event_tables_day_conditions");
        state.Day = 7;

        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["day_gated"] = new List<Dictionary<string, object>>
            {
                Entry("too_early", 1.0, Conditions(("min_day", 8))),
                Entry("too_late", 1.0, Conditions(("max_day", 6))),
                Entry("in_window", 1.0, Conditions(("min_day", 5), ("max_day", 9)))
            }
        });

        var selected = EventTables.SelectEvent(state, "day_gated");

        Assert.NotNull(selected);
        Assert.Equal("in_window", selected!["event_id"]);
    }

    [Fact]
    public void SelectEvent_ReturnsNull_WhenRequiredFlagIsMissing()
    {
        var state = CreateState("event_tables_missing_flag");
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["flag_gate"] = new List<Dictionary<string, object>>
            {
                Entry("flagged", 1.0, Conditions(("requires_flag", "met_sage")))
            }
        });

        var selected = EventTables.SelectEvent(state, "flag_gate");

        Assert.Null(selected);
    }

    [Fact]
    public void SelectEvent_SelectsFlaggedEntry_WhenRequiredFlagExists()
    {
        var state = CreateState("event_tables_has_flag");
        state.EventFlags["met_sage"] = true;
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["flag_gate"] = new List<Dictionary<string, object>>
            {
                Entry("flagged", 1.0, Conditions(("requires_flag", "met_sage")))
            }
        });

        var selected = EventTables.SelectEvent(state, "flag_gate");

        Assert.NotNull(selected);
        Assert.Equal("flagged", selected!["event_id"]);
    }

    [Fact]
    public void SetCooldown_BlocksSelectionUntilCooldownDayThenAllowsSelection()
    {
        var state = CreateState("event_tables_cooldown");
        state.Day = 10;
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["cooldown"] = new List<Dictionary<string, object>>
            {
                Entry("cooldown_event")
            }
        });

        EventTables.SetCooldown(state, "cooldown_event", 3);

        Assert.Equal(13, state.EventCooldowns["cooldown_event"]);
        state.Day = 12;
        Assert.Null(EventTables.SelectEvent(state, "cooldown"));

        state.Day = 13;
        var selected = EventTables.SelectEvent(state, "cooldown");

        Assert.NotNull(selected);
        Assert.Equal("cooldown_event", selected!["event_id"]);
    }

    [Fact]
    public void SelectEvent_WeightedDistribution_FavorsHigherWeightEntry()
    {
        var state = CreateState("event_tables_weight_dist");
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["weighted"] = new List<Dictionary<string, object>>
            {
                Entry("light", 1.0),
                Entry("heavy", 4.0)
            }
        });

        const int trials = 12000;
        int lightCount = 0;
        int heavyCount = 0;

        for (int i = 0; i < trials; i++)
        {
            var selected = EventTables.SelectEvent(state, "weighted");
            Assert.NotNull(selected);

            string id = selected!["event_id"].ToString() ?? string.Empty;
            if (id == "heavy")
                heavyCount++;
            else if (id == "light")
                lightCount++;
            else
                Assert.Fail($"Unexpected event id selected: {id}");
        }

        Assert.True(heavyCount > lightCount, "Higher-weight entry should be selected more often.");
        double heavyShare = heavyCount / (double)trials;
        Assert.InRange(heavyShare, 0.72, 0.88);
    }

    [Fact]
    public void SelectEvent_UsesDefaultWeightOfOne_WhenWeightIsMissing()
    {
        var state = CreateState("event_tables_default_weight");
        EventTables.LoadTables(new Dictionary<string, List<Dictionary<string, object>>>
        {
            ["default_weight"] = new List<Dictionary<string, object>>
            {
                Entry("implicit_one"),
                Entry("explicit_three", 3.0)
            }
        });

        const int trials = 12000;
        int implicitOneCount = 0;

        for (int i = 0; i < trials; i++)
        {
            var selected = EventTables.SelectEvent(state, "default_weight");
            Assert.NotNull(selected);
            if ((selected!["event_id"].ToString() ?? string.Empty) == "implicit_one")
                implicitOneCount++;
        }

        double implicitShare = implicitOneCount / (double)trials;
        Assert.InRange(implicitShare, 0.18, 0.32);
    }

    private static GameState CreateState(string seed)
    {
        var state = DefaultState.Create(seed);
        state.EventFlags.Clear();
        state.EventCooldowns.Clear();
        return state;
    }

    private static Dictionary<string, object> Entry(
        string eventId,
        double? weight = null,
        Dictionary<string, object>? conditions = null)
    {
        var entry = new Dictionary<string, object>
        {
            ["event_id"] = eventId
        };

        if (weight.HasValue)
            entry["weight"] = weight.Value;

        if (conditions != null)
            entry["conditions"] = conditions;

        return entry;
    }

    private static Dictionary<string, object> Conditions(params (string Key, object Value)[] values)
    {
        var conditions = new Dictionary<string, object>();
        foreach (var (key, value) in values)
            conditions[key] = value;
        return conditions;
    }
}
