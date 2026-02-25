using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class RegressionTests
{
    [Fact]
    public void Build_OnOccupiedTile_ReturnsError()
    {
        var state = DefaultState.Create();
        var pos = PrepareDiscoveredPassableTile(state);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "farm";
        state.StructureLevels[index] = 1;
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.Equal("farm", newState.Structures[index]);
        Assert.Contains("That tile is already occupied.", events);
    }

    [Fact]
    public void CursorMove_OutOfBoundsPositive_ClampsToMapEdge()
    {
        var state = DefaultState.Create();
        state.CursorPos = new GridPoint(state.MapW - 2, state.MapH - 2);

        var (newState, events, _) = Apply(state, "cursor_move", new()
        {
            ["dx"] = 1,
            ["dy"] = 1,
            ["steps"] = 99
        });

        var expected = new GridPoint(state.MapW - 1, state.MapH - 1);
        Assert.Equal(expected, newState.CursorPos);
        Assert.Contains($"Cursor at ({expected.X},{expected.Y}).", events);
    }

    [Fact]
    public void CursorMove_OutOfBoundsNegative_ClampsToMapOrigin()
    {
        var state = DefaultState.Create();
        state.CursorPos = new GridPoint(1, 1);

        var (newState, events, _) = Apply(state, "cursor_move", new()
        {
            ["dx"] = -1,
            ["dy"] = -1,
            ["steps"] = 99
        });

        Assert.Equal(new GridPoint(0, 0), newState.CursorPos);
        Assert.Contains("Cursor at (0,0).", events);
    }

    [Fact]
    public void TradeExecute_WithZeroGold_DoesNotCrash()
    {
        var state = DefaultState.Create();
        state.Gold = 0;
        state.Resources["wood"] = 5;
        state.Resources["stone"] = 1;

        var (newState, events, _) = Apply(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 3
        });

        Assert.Equal(0, newState.Gold);
        Assert.Equal(2, newState.Resources["wood"]);
        Assert.Equal(4, newState.Resources["stone"]);
        Assert.Contains("Traded 3 wood for 3 stone.", events);
    }

    [Fact]
    public void DefendInput_WithNoEnemies_DoesNotCrash()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 0;
        state.Enemies.Clear();
        int hpBefore = state.Hp;

        var (newState, events, result) = Apply(state, "defend_input", new()
        {
            ["text"] = "alpha"
        });
        var request = RequireRequest(result);

        Assert.Equal("day", newState.Phase);
        Assert.Equal(hpBefore, newState.Hp);
        Assert.Contains("No enemies yet; wait or defend after spawn.", events);
        Assert.Contains("Waited.", events);
        Assert.Contains("Dawn breaks.", events);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
    }

    [Fact]
    public void Wait_EndingNightWithNoTowers_DoesNotCrash()
    {
        var state = DefaultState.Create();
        state.Phase = "night";
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 2;
        state.Enemies.Clear();
        state.Structures.Clear();

        var (newState, events, result) = Apply(state, "wait");
        var request = RequireRequest(result);

        Assert.Equal("day", newState.Phase);
        Assert.Equal(newState.ApMax, newState.Ap);
        Assert.Empty(newState.Enemies);
        Assert.DoesNotContain(events, e => e.Contains("Auto-tower", StringComparison.Ordinal));
        Assert.Contains("Dawn breaks.", events);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
    }

    [Fact]
    public void Explore_WhenAllTilesDiscovered_IsNoOpForDiscovery()
    {
        var state = DefaultState.Create();
        DiscoverAllTiles(state);
        int discoveredBefore = state.Discovered.Count;
        int threatBefore = state.Threat;

        var (newState, events, _) = Apply(state, "explore");

        Assert.Equal(discoveredBefore, newState.Discovered.Count);
        Assert.Equal(threatBefore, newState.Threat);
        Assert.Contains("No new tiles to discover.", events);
    }

    [Fact]
    public void Crafting_WithExactResources_Succeeds()
    {
        var state = DefaultState.Create();
        state.Inventory.Clear();
        state.Inventory["iron_ingot"] = 2;
        state.Inventory["coal"] = 1;

        var result = Crafting.Craft(state, "steel_ingot");

        Assert.True(Convert.ToBoolean(result["success"]));
        Assert.Equal(0, state.Inventory["iron_ingot"]);
        Assert.Equal(0, state.Inventory["coal"]);
        Assert.Equal(1, state.Inventory["steel_ingot"]);
        Assert.Equal("Crafted Steel Ingot!", result["message"]);
        Assert.False(Crafting.CanCraft(state, "steel_ingot"));
    }

    [Fact]
    public void SaveLoad_WithEmptyEnemyList_PreservesState()
    {
        var state = DefaultState.Create();
        state.Day = 8;
        state.Phase = "night";
        state.Gold = 42;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 0;
        state.Enemies.Clear();

        string json = SaveManager.StateToJson(state);
        var (ok, loaded, error) = SaveManager.StateFromJson(json);

        Assert.True(ok, error);
        Assert.NotNull(loaded);
        Assert.Empty(loaded!.Enemies);
        Assert.Equal(8, loaded.Day);
        Assert.Equal("night", loaded.Phase);
        Assert.Equal(42, loaded.Gold);
        Assert.Equal(state.Discovered.Count, loaded.Discovered.Count);
    }

    [Fact]
    public void DayBoundary_PhaseTransitions_DayToNightToDay()
    {
        var state = DefaultState.Create();
        state.Day = 6;

        var (nightState, endEvents, endResult) = Apply(state, "end");
        Assert.Equal("night", nightState.Phase);
        Assert.Equal(6, nightState.Day);
        Assert.Contains(endEvents, e => e.StartsWith("Night falls.", StringComparison.Ordinal));
        Assert.Equal("night", RequireRequest(endResult)["reason"]?.ToString());

        nightState.NightSpawnRemaining = 0;
        nightState.NightWaveTotal = 0;
        nightState.Enemies.Clear();

        var (dayState, dawnEvents, dawnResult) = Apply(nightState, "wait");
        Assert.Equal("day", dayState.Phase);
        Assert.Equal(6, dayState.Day);
        Assert.Equal(dayState.ApMax, dayState.Ap);
        Assert.Contains("Dawn breaks.", dawnEvents);
        Assert.Equal("dawn", RequireRequest(dawnResult)["reason"]?.ToString());
    }

    [Fact]
    public void EndTurn_DoubleClick_DoesNotSkipDay()
    {
        var state = DefaultState.Create();
        state.Day = 9;

        var (afterFirstEnd, _, _) = Apply(state, "end");
        var (afterSecondEnd, events, result) = Apply(afterFirstEnd, "end");

        Assert.Equal("night", afterSecondEnd.Phase);
        Assert.Equal(9, afterSecondEnd.Day);
        Assert.Contains("That action is only available during the day.", events);
        Assert.False(result.ContainsKey("request"));
    }

    private static (GameState State, List<string> Events, Dictionary<string, object> Result) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events, result);
    }

    private static Dictionary<string, object> RequireRequest(Dictionary<string, object> result)
    {
        Assert.True(result.TryGetValue("request", out object? requestObj));
        return Assert.IsType<Dictionary<string, object>>(requestObj);
    }

    private static GridPoint PrepareDiscoveredPassableTile(GameState state)
    {
        var candidates = new[]
        {
            new GridPoint(state.BasePos.X + 1, state.BasePos.Y),
            new GridPoint(state.BasePos.X - 1, state.BasePos.Y),
            new GridPoint(state.BasePos.X, state.BasePos.Y + 1),
            new GridPoint(state.BasePos.X, state.BasePos.Y - 1),
        };

        foreach (var candidate in candidates)
        {
            if (!SimMap.InBounds(candidate.X, candidate.Y, state.MapW, state.MapH))
                continue;
            if (candidate == state.BasePos)
                continue;

            int index = SimMap.Idx(candidate.X, candidate.Y, state.MapW);
            state.Discovered.Add(index);
            state.Terrain[index] = SimMap.TerrainPlains;
            state.Structures.Remove(index);
            state.StructureLevels.Remove(index);
            return candidate;
        }

        throw new InvalidOperationException("Could not find a buildable tile near base.");
    }

    private static void DiscoverAllTiles(GameState state)
    {
        state.Discovered.Clear();
        for (int idx = 0; idx < state.MapW * state.MapH; idx++)
            state.Discovered.Add(idx);
    }
}
