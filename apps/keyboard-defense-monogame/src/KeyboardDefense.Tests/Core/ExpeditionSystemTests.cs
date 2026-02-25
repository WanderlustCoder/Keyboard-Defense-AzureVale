using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ExpeditionSystemTests
{
    [Fact]
    public void StartExpedition_ValidRequest_AddsActiveExpeditionWithDefinitionDuration()
    {
        var state = CreateState();

        var result = Expeditions.StartExpedition(state, "forest", 2);
        var expedition = Assert.Single(state.ActiveExpeditions);

        Assert.True(Convert.ToBoolean(result["ok"]));
        Assert.Equal(1, Convert.ToInt32(result["expedition_id"]));
        Assert.Equal("forest", expedition["type"]);
        Assert.Equal(2, Convert.ToInt32(expedition["workers"]));
        Assert.Equal(Expeditions.Types["forest"].Duration, Convert.ToInt32(expedition["duration"]));
        Assert.Equal(0, Convert.ToInt32(expedition["progress"]));
    }

    [Fact]
    public void TickExpeditions_TracksProgressAcrossDurationUntilCompletion()
    {
        var state = CreateState();
        Expeditions.StartExpedition(state, "mine", 1);

        Assert.Empty(Expeditions.TickExpeditions(state));
        Assert.Equal(1, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));

        Assert.Empty(Expeditions.TickExpeditions(state));
        Assert.Equal(2, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));

        Assert.Empty(Expeditions.TickExpeditions(state));
        Assert.Equal(3, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));

        var completionEvents = Expeditions.TickExpeditions(state);
        Assert.Single(completionEvents);
        Assert.Empty(state.ActiveExpeditions);
    }

    [Fact]
    public void TickExpeditions_RewardCalculation_UsesBaseYieldTimesWorkerCount()
    {
        var state = CreateState();
        Expeditions.StartExpedition(state, "forest", 3);
        state.ActiveExpeditions[0]["progress"] = Expeditions.Types["forest"].Duration - 1;

        Expeditions.TickExpeditions(state);

        int expectedYield = Expeditions.Types["forest"].BaseYield * 3;
        Assert.Equal(expectedYield, state.Resources["wood"]);
    }

    [Fact]
    public void TickExpeditions_OnCompletion_ReturnsExpectedCompletionEvent()
    {
        var state = CreateState();
        Expeditions.StartExpedition(state, "forage", 1);
        state.ActiveExpeditions[0]["progress"] = Expeditions.Types["forage"].Duration - 1;

        var completionEvents = Expeditions.TickExpeditions(state);
        var completionEvent = Assert.Single(completionEvents);

        Assert.Equal("expedition_complete", completionEvent["type"]);
        Assert.Equal("food", completionEvent["resource"]);
        Assert.Equal(Expeditions.Types["forage"].BaseYield, Convert.ToInt32(completionEvent["amount"]));
    }

    [Fact]
    public void TickExpeditions_OnCompletion_RemovesExpeditionFromActiveList()
    {
        var state = CreateState();
        Expeditions.StartExpedition(state, "forest", 1);
        state.ActiveExpeditions[0]["progress"] = Expeditions.Types["forest"].Duration - 1;

        Expeditions.TickExpeditions(state);

        Assert.Empty(state.ActiveExpeditions);
        Assert.Equal(0, Expeditions.GetActiveExpeditionCount(state));
    }

    [Fact]
    public void TickExpeditions_MultipleConcurrentExpeditions_TickAndCompleteIndependently()
    {
        var state = CreateState();
        var forestStart = Expeditions.StartExpedition(state, "forest", 1);
        var forageStart = Expeditions.StartExpedition(state, "forage", 2);
        int forestId = Convert.ToInt32(forestStart["expedition_id"]);
        int forageId = Convert.ToInt32(forageStart["expedition_id"]);

        var forest = FindExpeditionById(state, forestId);
        var forage = FindExpeditionById(state, forageId);
        forest["progress"] = Expeditions.Types["forest"].Duration - 2;
        forage["progress"] = Expeditions.Types["forage"].Duration - 1;

        var events = Expeditions.TickExpeditions(state);

        var completionEvent = Assert.Single(events);
        Assert.Equal("food", completionEvent["resource"]);
        Assert.Single(state.ActiveExpeditions);
        Assert.Equal(forestId, Convert.ToInt32(state.ActiveExpeditions[0]["id"]));
        Assert.Equal(Expeditions.Types["forest"].Duration - 1, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));
        Assert.Equal(Expeditions.Types["forage"].BaseYield * 2, state.Resources["food"]);
        Assert.Equal(0, state.Resources["wood"]);
    }

    [Fact]
    public void ExpeditionWithHero_AssignedHero_DoesNotBlockCompletionOrRewards()
    {
        var state = CreateState();
        state.HeroId = "ranger";
        Expeditions.StartExpedition(state, "treasure", 2);
        state.ActiveExpeditions[0]["progress"] = Expeditions.Types["treasure"].Duration - 1;

        var events = Expeditions.TickExpeditions(state);

        Assert.Equal("ranger", state.HeroId);
        Assert.Single(events);
        Assert.Equal("gold", events[0]["resource"]);
        Assert.Equal(Expeditions.Types["treasure"].BaseYield * 2, state.Resources["gold"]);
    }

    [Fact]
    public void StartExpedition_UnknownType_ReturnsErrorWithoutMutatingState()
    {
        var state = CreateState();
        int nextIdBefore = state.ExpeditionNextId;
        int activeBefore = state.ActiveExpeditions.Count;

        var result = Expeditions.StartExpedition(state, "unknown", 1);

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("Unknown expedition type.", result["error"]);
        Assert.Equal(nextIdBefore, state.ExpeditionNextId);
        Assert.Equal(activeBefore, state.ActiveExpeditions.Count);
    }

    [Fact]
    public void StartExpedition_ZeroWorkers_ReturnsErrorWithoutMutatingState()
    {
        var state = CreateState();
        int nextIdBefore = state.ExpeditionNextId;
        int activeBefore = state.ActiveExpeditions.Count;

        var result = Expeditions.StartExpedition(state, "forest", 0);

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("Need at least 1 worker.", result["error"]);
        Assert.Equal(nextIdBefore, state.ExpeditionNextId);
        Assert.Equal(activeBefore, state.ActiveExpeditions.Count);
    }

    [Fact]
    public void StartExpedition_NegativeWorkers_ReturnsErrorWithoutMutatingState()
    {
        var state = CreateState();
        int nextIdBefore = state.ExpeditionNextId;
        int activeBefore = state.ActiveExpeditions.Count;

        var result = Expeditions.StartExpedition(state, "forest", -2);

        Assert.False(Convert.ToBoolean(result["ok"]));
        Assert.Equal("Need at least 1 worker.", result["error"]);
        Assert.Equal(nextIdBefore, state.ExpeditionNextId);
        Assert.Equal(activeBefore, state.ActiveExpeditions.Count);
    }

    [Fact]
    public void TickExpeditions_UnknownTypeEntry_ExpiresWithoutRewardsOrCompletionEvent()
    {
        var state = CreateState();
        state.ActiveExpeditions.Add(new Dictionary<string, object>
        {
            ["id"] = 999,
            ["type"] = "unknown_type",
            ["workers"] = 3,
            ["phase"] = "traveling",
            ["progress"] = 0,
            ["duration"] = 1,
            ["started_day"] = state.Day
        });

        var completionEvents = Expeditions.TickExpeditions(state);

        Assert.Empty(completionEvents);
        Assert.Empty(state.ActiveExpeditions);
        Assert.Equal(0, state.Resources.GetValueOrDefault("wood", 0));
        Assert.Equal(0, state.Resources.GetValueOrDefault("stone", 0));
        Assert.Equal(0, state.Resources.GetValueOrDefault("food", 0));
        Assert.Equal(0, state.Resources.GetValueOrDefault("gold", 0));
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create(seed: "expedition_system_tests");
        state.ActiveExpeditions.Clear();
        state.ExpeditionNextId = 1;
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;
        state.Resources["gold"] = 0;
        return state;
    }

    private static Dictionary<string, object> FindExpeditionById(GameState state, int id)
    {
        return state.ActiveExpeditions.Single(expedition =>
            Convert.ToInt32(expedition.GetValueOrDefault("id", -1)) == id);
    }
}
