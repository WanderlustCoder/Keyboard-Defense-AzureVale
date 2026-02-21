using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ExpeditionsCoreTests
{
    [Fact]
    public void Types_HasFourEntries()
    {
        Assert.Equal(4, Expeditions.Types.Count);
    }

    [Fact]
    public void Types_ContainsExpectedDefinitions()
    {
        var expected = ExpectedDefinitions();

        foreach (var (typeId, expectedDef) in expected)
        {
            Assert.True(Expeditions.Types.ContainsKey(typeId));
            Assert.Equal(expectedDef, Expeditions.Types[typeId]);
        }
    }

    [Fact]
    public void StartExpedition_ValidType_ReturnsSuccessAndStoresExpectedFields()
    {
        var state = CreateIsolatedState();
        state.Day = 12;

        var result = Expeditions.StartExpedition(state, "forest", 2);

        Assert.True((bool)result["ok"]);
        Assert.Equal(1, Convert.ToInt32(result["expedition_id"]));
        Assert.Single(state.ActiveExpeditions);

        var expedition = state.ActiveExpeditions[0];
        Assert.Equal(1, Convert.ToInt32(expedition["id"]));
        Assert.Equal("forest", expedition["type"]);
        Assert.Equal(2, Convert.ToInt32(expedition["workers"]));
        Assert.Equal("traveling", expedition["phase"]);
        Assert.Equal(0, Convert.ToInt32(expedition["progress"]));
        Assert.Equal(3, Convert.ToInt32(expedition["duration"]));
        Assert.Equal(12, Convert.ToInt32(expedition["started_day"]));
    }

    [Fact]
    public void StartExpedition_ValidType_ReturnsExpectedMessage()
    {
        var state = CreateIsolatedState();

        var result = Expeditions.StartExpedition(state, "mine", 3);

        Assert.True((bool)result["ok"]);
        Assert.Equal("Started Mining Expedition with 3 workers.", result["message"]);
    }

    [Fact]
    public void StartExpedition_IncrementsExpeditionNextId()
    {
        var state = CreateIsolatedState();
        state.ExpeditionNextId = 10;

        var result = Expeditions.StartExpedition(state, "forage", 1);

        Assert.True((bool)result["ok"]);
        Assert.Equal(10, Convert.ToInt32(result["expedition_id"]));
        Assert.Equal(11, state.ExpeditionNextId);
    }

    [Fact]
    public void StartExpedition_UnknownType_ReturnsErrorAndDoesNotMutateState()
    {
        var state = CreateIsolatedState();
        state.ExpeditionNextId = 4;

        var result = Expeditions.StartExpedition(state, "unknown_type", 1);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Unknown expedition type.", result["error"]);
        Assert.Empty(state.ActiveExpeditions);
        Assert.Equal(4, state.ExpeditionNextId);
    }

    [Fact]
    public void StartExpedition_WorkerCountZero_ReturnsErrorAndDoesNotMutateState()
    {
        var state = CreateIsolatedState();
        state.ExpeditionNextId = 2;

        var result = Expeditions.StartExpedition(state, "forest", 0);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Need at least 1 worker.", result["error"]);
        Assert.Empty(state.ActiveExpeditions);
        Assert.Equal(2, state.ExpeditionNextId);
    }

    [Fact]
    public void StartExpedition_NegativeWorkers_ReturnsErrorAndDoesNotMutateState()
    {
        var state = CreateIsolatedState();
        state.ExpeditionNextId = 2;

        var result = Expeditions.StartExpedition(state, "forest", -3);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Need at least 1 worker.", result["error"]);
        Assert.Empty(state.ActiveExpeditions);
        Assert.Equal(2, state.ExpeditionNextId);
    }

    [Fact]
    public void TickExpeditions_IncrementsProgressByOne()
    {
        var state = CreateIsolatedState();
        Expeditions.StartExpedition(state, "forest", 1);

        var events = Expeditions.TickExpeditions(state);

        Assert.Empty(events);
        Assert.Single(state.ActiveExpeditions);
        Assert.Equal(1, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));
    }

    [Fact]
    public void TickExpeditions_NotYetComplete_StaysActiveAndReturnsNoEvents()
    {
        var state = CreateIsolatedState();
        Expeditions.StartExpedition(state, "mine", 1);

        var events = Expeditions.TickExpeditions(state);

        Assert.Empty(events);
        Assert.Single(state.ActiveExpeditions);
        Assert.Equal(1, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));
        Assert.Equal(0, state.Resources["stone"]);
    }

    [Fact]
    public void TickExpeditions_ReachesDuration_CompletesRemovesAndAddsResources()
    {
        var state = CreateIsolatedState();
        Expeditions.StartExpedition(state, "forest", 1);
        state.ActiveExpeditions[0]["progress"] = 2;

        var events = Expeditions.TickExpeditions(state);

        Assert.Single(events);
        Assert.Empty(state.ActiveExpeditions);
        Assert.Equal(8, state.Resources["wood"]);
    }

    [Fact]
    public void TickExpeditions_YieldIsBaseYieldTimesWorkers()
    {
        var state = CreateIsolatedState();
        Expeditions.StartExpedition(state, "forest", 2);
        state.ActiveExpeditions[0]["progress"] = 2;

        Expeditions.TickExpeditions(state);

        Assert.Equal(16, state.Resources["wood"]);
    }

    [Fact]
    public void TickExpeditions_MultipleExpeditions_TickIndependently()
    {
        var state = CreateIsolatedState();
        var forest = Expeditions.StartExpedition(state, "forest", 1);
        var mine = Expeditions.StartExpedition(state, "mine", 2);
        int forestId = Convert.ToInt32(forest["expedition_id"]);
        int mineId = Convert.ToInt32(mine["expedition_id"]);

        FindExpeditionById(state, forestId)["progress"] = 0;
        FindExpeditionById(state, mineId)["progress"] = 2;

        var events = Expeditions.TickExpeditions(state);

        Assert.Empty(events);
        Assert.Equal(2, state.ActiveExpeditions.Count);
        Assert.Equal(1, Convert.ToInt32(FindExpeditionById(state, forestId)["progress"]));
        Assert.Equal(3, Convert.ToInt32(FindExpeditionById(state, mineId)["progress"]));
    }

    [Fact]
    public void TickExpeditions_MixedCompletion_RemovesOnlyCompletedExpeditions()
    {
        var state = CreateIsolatedState();
        var forest = Expeditions.StartExpedition(state, "forest", 1);
        var mine = Expeditions.StartExpedition(state, "mine", 1);
        int forestId = Convert.ToInt32(forest["expedition_id"]);
        int mineId = Convert.ToInt32(mine["expedition_id"]);

        FindExpeditionById(state, forestId)["progress"] = 2;
        FindExpeditionById(state, mineId)["progress"] = 1;

        var events = Expeditions.TickExpeditions(state);

        Assert.Single(events);
        Assert.Single(state.ActiveExpeditions);
        Assert.Equal(mineId, Convert.ToInt32(state.ActiveExpeditions[0]["id"]));
        Assert.Equal(2, Convert.ToInt32(state.ActiveExpeditions[0]["progress"]));
        Assert.Equal(8, state.Resources["wood"]);
        Assert.Equal(0, state.Resources["stone"]);
    }

    [Fact]
    public void TickExpeditions_CompletedEventContainsTypeResourceAndAmount()
    {
        var state = CreateIsolatedState();
        Expeditions.StartExpedition(state, "forage", 1);
        state.ActiveExpeditions[0]["progress"] = 1;

        var events = Expeditions.TickExpeditions(state);

        Assert.Single(events);
        var completedEvent = events[0];
        Assert.Equal("expedition_complete", completedEvent["type"]);
        Assert.Equal("food", completedEvent["resource"]);
        Assert.Equal(10, Convert.ToInt32(completedEvent["amount"]));
    }

    [Fact]
    public void TickExpeditions_CompletionAddsToExistingResourceAmount()
    {
        var state = CreateIsolatedState();
        state.Resources["wood"] = 5;
        Expeditions.StartExpedition(state, "forest", 1);
        state.ActiveExpeditions[0]["progress"] = 2;

        Expeditions.TickExpeditions(state);

        Assert.Equal(13, state.Resources["wood"]);
    }

    [Fact]
    public void GetActiveExpeditionCount_InitiallyZero()
    {
        var state = CreateIsolatedState();

        int count = Expeditions.GetActiveExpeditionCount(state);

        Assert.Equal(0, count);
    }

    [Fact]
    public void GetActiveExpeditionCount_IncreasesAfterStartingExpeditions()
    {
        var state = CreateIsolatedState();
        Expeditions.StartExpedition(state, "forest", 1);
        Expeditions.StartExpedition(state, "mine", 1);

        int count = Expeditions.GetActiveExpeditionCount(state);

        Assert.Equal(2, count);
    }

    [Fact]
    public void StartExpedition_MultipleStartsCreateUniqueIds()
    {
        var state = CreateIsolatedState();

        var first = Expeditions.StartExpedition(state, "forest", 1);
        var second = Expeditions.StartExpedition(state, "forage", 1);
        var third = Expeditions.StartExpedition(state, "treasure", 1);

        int id1 = Convert.ToInt32(first["expedition_id"]);
        int id2 = Convert.ToInt32(second["expedition_id"]);
        int id3 = Convert.ToInt32(third["expedition_id"]);

        var ids = new HashSet<int> { id1, id2, id3 };
        Assert.Equal(3, ids.Count);
        Assert.Equal(4, state.ExpeditionNextId);
    }

    private static Dictionary<string, ExpeditionDef> ExpectedDefinitions() =>
        new()
        {
            ["forest"] = new("Forest Expedition", "wood", 8, 3, 0.1),
            ["mine"] = new("Mining Expedition", "stone", 6, 4, 0.15),
            ["forage"] = new("Foraging Trip", "food", 10, 2, 0.05),
            ["treasure"] = new("Treasure Hunt", "gold", 3, 5, 0.25),
        };

    private static GameState CreateIsolatedState()
    {
        var state = DefaultState.Create(seed: "expeditions_tests");
        state.ActiveExpeditions.Clear();
        state.ExpeditionNextId = 1;
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;
        state.Resources.Remove("gold");
        return state;
    }

    private static Dictionary<string, object> FindExpeditionById(GameState state, int id)
    {
        foreach (var expedition in state.ActiveExpeditions)
        {
            if (Convert.ToInt32(expedition.GetValueOrDefault("id", -1)) == id)
                return expedition;
        }

        throw new InvalidOperationException($"Expedition with id {id} not found.");
    }
}
