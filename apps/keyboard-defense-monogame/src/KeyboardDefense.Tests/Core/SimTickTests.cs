using System;
using System.Collections.Generic;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SimTickTests
{
    private static readonly HashSet<string> NightPromptCatalog = new(StringComparer.Ordinal)
    {
        "bastion", "banner", "citadel", "ember", "forge",
        "lantern", "rune", "shield", "spear", "ward"
    };

    [Fact]
    public void AdvanceDay_IncrementsDayAndReturnsMutatedState()
    {
        var state = CreateState("advance_day_basics");
        state.Day = 2;

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Same(state, result["state"]);
        Assert.Equal(3, state.Day);
        Assert.Contains("Day advanced to 3.", events);
    }

    [Fact]
    public void AdvanceDay_WithNoProduction_ReportsNone()
    {
        var state = CreateState("advance_day_none");
        state.Structures.Clear();

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Contains("Production: none.", events);
    }

    [Fact]
    public void AdvanceDay_ProducesResourcesFromMatchingStructures()
    {
        var state = CreateState("advance_day_production");
        state.Structures[10] = "farm";
        state.Structures[11] = "farm";
        state.Structures[12] = "lumber";
        state.Structures[13] = "quarry";
        state.Structures[14] = "tower";

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Equal(2, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(2, state.Resources.GetValueOrDefault("stone", 0));
        Assert.Equal(4, state.Resources.GetValueOrDefault("food", 0));
        Assert.Contains("Production: +2 wood, 2 stone, 4 food.", events);
    }

    [Fact]
    public void AdvanceDay_MidgameFoodBonus_AppliesWhenEnteringDay4BelowThreshold()
    {
        var state = CreateState("advance_day_midgame_bonus");
        state.Day = 3;
        state.Resources["food"] = 0;

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Equal(4, state.Day);
        Assert.Equal(2, state.Resources.GetValueOrDefault("food", 0));
        Assert.Contains("Midgame supply: +2 food.", events);
    }

    [Fact]
    public void AdvanceDay_MidgameFoodBonus_DoesNotApplyWhenProductionMeetsThreshold()
    {
        var state = CreateState("advance_day_midgame_threshold");
        state.Day = 3;
        state.Resources["food"] = 10;
        state.Structures[5] = "farm";

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Equal(12, state.Resources.GetValueOrDefault("food", 0));
        Assert.DoesNotContain(events, e => e.StartsWith("Midgame supply:", StringComparison.Ordinal));
    }

    [Fact]
    public void AdvanceDay_WhenResourcesExceedCap_TrimsAndReportsStorageLimits()
    {
        var state = CreateState("advance_day_resource_caps");
        int cap = SimBalance.ResourceCap;
        state.Resources["wood"] = cap + 6;
        state.Resources["stone"] = cap + 3;
        state.Resources["food"] = cap;

        var result = SimTick.AdvanceDay(state);
        var events = Assert.IsType<List<string>>(result["events"]);

        Assert.Equal(cap, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(cap, state.Resources.GetValueOrDefault("stone", 0));
        Assert.Equal(cap, state.Resources.GetValueOrDefault("food", 0));
        Assert.Contains("Storage limits: -wood 6, stone 3.", events);
    }

    [Fact]
    public void ComputeNightWaveTotal_UsesConfiguredBaseForEarlyDays()
    {
        var state = CreateState("compute_wave_configured");
        state.Day = 5;
        state.Threat = 3;

        int total = SimTick.ComputeNightWaveTotal(state, defense: 1);

        Assert.Equal(7, total);
    }

    [Fact]
    public void ComputeNightWaveTotal_UsesFallbackBaseForLaterDays()
    {
        var state = CreateState("compute_wave_fallback");
        state.Day = 12;
        state.Threat = 4;

        int total = SimTick.ComputeNightWaveTotal(state, defense: 2);

        Assert.Equal(10, total);
    }

    [Fact]
    public void ComputeNightWaveTotal_IsClampedToAtLeastOne()
    {
        var state = CreateState("compute_wave_floor");
        state.Day = 1;
        state.Threat = 0;

        int total = SimTick.ComputeNightWaveTotal(state, defense: 100);

        Assert.Equal(1, total);
    }

    [Fact]
    public void BuildNightPrompt_IsSeedDeterministic_AndUsesPromptCatalog()
    {
        var stateA = CreateState("night_prompt_seed");
        var stateB = CreateState("night_prompt_seed");
        long rngBefore = stateA.RngState;

        string promptA = SimTick.BuildNightPrompt(stateA);
        string promptB = SimTick.BuildNightPrompt(stateB);

        Assert.Equal(promptA, promptB);
        Assert.False(string.IsNullOrWhiteSpace(promptA));
        Assert.Contains(promptA, NightPromptCatalog);
        Assert.NotEqual(rngBefore, stateA.RngState);
    }

    private static GameState CreateState(string seed)
    {
        var state = new GameState();
        state.Structures.Clear();
        SimRng.SeedState(state, seed);
        return state;
    }
}
