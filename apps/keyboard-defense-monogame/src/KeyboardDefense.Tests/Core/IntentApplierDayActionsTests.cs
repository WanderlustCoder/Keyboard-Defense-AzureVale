using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class IntentApplierDayActionsTests
{
    [Fact]
    public void Apply_Explore_DiscoversTileAndIncreasesThreat()
    {
        var state = CreateState();
        state.Ap = 2;
        int discoveredBefore = state.Discovered.Count;
        int threatBefore = state.Threat;

        var (newState, events, _) = Apply(state, "explore");

        Assert.Equal(1, newState.Ap);
        Assert.Equal(discoveredBefore + 1, newState.Discovered.Count);
        Assert.Equal(threatBefore + 1, newState.Threat);
        Assert.Contains(events, e => e.StartsWith("Discovered tile (", StringComparison.Ordinal));
        Assert.Contains(events, e => e.StartsWith("Day ", StringComparison.Ordinal));
    }

    [Fact]
    public void Apply_Explore_WithNoAp_ReturnsNoActionPointsMessage()
    {
        var state = CreateState();
        state.Ap = 0;
        int discoveredBefore = state.Discovered.Count;
        int threatBefore = state.Threat;

        var (newState, events, _) = Apply(state, "explore");

        Assert.Equal(0, newState.Ap);
        Assert.Equal(discoveredBefore, newState.Discovered.Count);
        Assert.Equal(threatBefore, newState.Threat);
        Assert.Contains("No action points remaining. Type 'end' to start the night.", events);
    }

    [Fact]
    public void Apply_Build_OnUndiscoveredTile_RejectsWithoutConsumingAp()
    {
        var state = CreateState();
        int x = 0;
        int y = 0;
        int index = SimMap.Idx(x, y, state.MapW);
        state.Discovered.Remove(index);
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = x,
            ["y"] = y
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.False(newState.Structures.ContainsKey(index));
        Assert.Contains("That tile is not discovered yet.", events);
    }

    [Fact]
    public void Apply_Build_OnWater_RejectsWithoutConsumingAp()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Terrain[index] = SimMap.TerrainWater;
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.False(newState.Structures.ContainsKey(index));
        Assert.Contains("Cannot build on water.", events);
    }

    [Fact]
    public void Apply_Build_WithResources_PlacesStructureAndConsumesCost()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        int apBefore = state.Ap;
        int buildingCountBefore = state.Buildings.GetValueOrDefault("tower", 0);
        var cost = BuildingsData.CostFor("tower");

        state.Resources["wood"] = 200;
        state.Resources["stone"] = 200;

        var resourcesBefore = new Dictionary<string, int>(state.Resources);

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(apBefore - 1, newState.Ap);
        Assert.Equal("tower", newState.Structures[index]);
        Assert.Equal(1, newState.StructureLevels[index]);
        Assert.Equal(buildingCountBefore + 1, newState.Buildings["tower"]);
        foreach (var (resource, amount) in cost)
            Assert.Equal(resourcesBefore[resource] - amount, newState.Resources[resource]);
        Assert.Contains($"Built tower at ({pos.X},{pos.Y}).", events);
    }

    [Fact]
    public void Apply_TradeExecute_ValidTrade_UpdatesResources()
    {
        var state = CreateState();
        state.Resources["wood"] = 10;
        state.Resources["stone"] = 0;

        var (newState, events, _) = Apply(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 4
        });

        Assert.Equal(6, newState.Resources["wood"]);
        Assert.Equal(4, newState.Resources["stone"]);
        Assert.Contains("Traded 4 wood for 4 stone.", events);
    }

    [Fact]
    public void Apply_TradeExecute_InsufficientResource_ReturnsErrorAndNoStateChange()
    {
        var state = CreateState();
        state.Resources["wood"] = 2;
        state.Resources["stone"] = 3;

        var (newState, events, _) = Apply(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 5
        });

        Assert.Equal(2, newState.Resources["wood"]);
        Assert.Equal(3, newState.Resources["stone"]);
        Assert.Contains("Not enough wood (have 2, need 5).", events);
    }

    [Fact]
    public void Apply_CraftIntent_IsCurrentlyUnknown()
    {
        var state = CreateState();
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "craft", new()
        {
            ["recipe_id"] = "iron_ingot"
        });

        Assert.Single(events);
        Assert.Equal("Unknown intent: craft", events[0]);
        Assert.Equal(apBefore, newState.Ap);
    }

    [Fact]
    public void Apply_MovePlayer_OutOfBounds_UpdatesFacingAndKeepsPosition()
    {
        var state = CreateState();
        state.PlayerPos = new GridPoint(0, 0);
        state.CursorPos = state.PlayerPos;
        state.PlayerFacing = "down";

        var (newState, events, _) = Apply(state, "move_player", new()
        {
            ["dx"] = -1,
            ["dy"] = 0
        });

        Assert.Equal(new GridPoint(0, 0), newState.PlayerPos);
        Assert.Equal(new GridPoint(0, 0), newState.CursorPos);
        Assert.Equal("left", newState.PlayerFacing);
        Assert.Contains("You can't go that way.", events);
    }

    [Fact]
    public void Apply_MovePlayer_PassableTile_MovesAndSyncsCursor()
    {
        var state = CreateState();
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        var target = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        state.Structures.Remove(targetIndex);
        state.Terrain[targetIndex] = SimMap.TerrainPlains;

        var (newState, events, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0
        });

        Assert.Equal(target, newState.PlayerPos);
        Assert.Equal(target, newState.CursorPos);
        Assert.Equal("right", newState.PlayerFacing);
        Assert.Contains(targetIndex, newState.Discovered);
        Assert.Empty(events);
    }

    [Fact]
    public void Apply_End_AsRestTransition_SetsNightStateAndAutosaveRequest()
    {
        var state = CreateState();
        state.Phase = "day";
        state.Ap = 2;

        var (newState, events, result) = Apply(state, "end");
        var request = RequireRequest(result);

        Assert.Equal("night", newState.Phase);
        Assert.Equal(0, newState.Ap);
        Assert.True(newState.NightWaveTotal >= 1);
        Assert.Equal(newState.NightWaveTotal, newState.NightSpawnRemaining);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("night", request["reason"]?.ToString());
        Assert.Contains(events, e => e.StartsWith("Night falls. Enemy wave:", StringComparison.Ordinal));
    }

    [Fact]
    public void Apply_RestIntent_IsCurrentlyUnknown()
    {
        var state = CreateState();
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "rest");

        Assert.Single(events);
        Assert.Equal("Unknown intent: rest", events[0]);
        Assert.Equal(apBefore, newState.Ap);
    }

    private static GameState CreateState() => DefaultState.Create();

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

    private static GridPoint PrepareBuildableTile(GameState state, int dx, int dy)
    {
        var pos = new GridPoint(state.BasePos.X + dx, state.BasePos.Y + dy);
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
        return pos;
    }

    private static void LoadBuildingsData()
    {
        BuildingsData.LoadData(ResolveDataDirectory());
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "buildings.json")))
                return candidate;

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir)
                break;
            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/buildings.json from test base directory.");
    }
}
