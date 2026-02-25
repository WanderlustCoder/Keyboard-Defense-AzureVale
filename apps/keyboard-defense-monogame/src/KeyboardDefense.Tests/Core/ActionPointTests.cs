using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ActionPointTests
{
    [Fact]
    public void DayStart_GrantsInitialApFromApMax()
    {
        GameState state = DefaultState.Create();

        Assert.Equal("day", state.Phase);
        Assert.True(state.ApMax > 0);
        Assert.Equal(state.ApMax, state.Ap);
    }

    [Fact]
    public void Explore_ConsumesOneAp()
    {
        GameState state = DefaultState.Create();
        int apBefore = state.Ap;

        var (newState, _, _) = Apply(state, "explore");

        Assert.Equal(apBefore - 1, newState.Ap);
    }

    [Fact]
    public void Build_ConsumesOneAp_WhenSuccessful()
    {
        LoadBuildingsData();
        GameState state = DefaultState.Create();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        int apBefore = state.Ap;
        foreach (string resource in GameState.ResourceKeys)
            state.Resources[resource] = 999;

        var (newState, _, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(apBefore - 1, newState.Ap);
        Assert.Equal("tower", newState.Structures[index]);
    }

    [Fact]
    public void Trade_DoesNotConsumeAp()
    {
        GameState state = DefaultState.Create();
        state.Ap = 2;
        state.Resources["wood"] = 10;
        state.Resources["stone"] = 0;
        int apBefore = state.Ap;

        var (newState, _, _) = Apply(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 4
        });

        Assert.Equal(apBefore, newState.Ap);
    }

    [Fact]
    public void Move_DoesNotConsumeAp()
    {
        GameState state = DefaultState.Create();
        state.Ap = 2;
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        var target = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        state.Structures.Remove(targetIndex);
        state.Terrain[targetIndex] = SimMap.TerrainPlains;
        int apBefore = state.Ap;

        var (newState, _, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0
        });

        Assert.Equal(apBefore, newState.Ap);
        Assert.Equal(target, newState.PlayerPos);
    }

    [Fact]
    public void DayAction_WithInsufficientAp_IsRejected()
    {
        GameState state = DefaultState.Create();
        state.Ap = 0;
        int discoveredBefore = state.Discovered.Count;

        var (newState, events, _) = Apply(state, "explore");

        Assert.Equal(0, newState.Ap);
        Assert.Equal(discoveredBefore, newState.Discovered.Count);
        Assert.Contains("No action points remaining. Type 'end' to start the night.", events);
    }

    [Fact]
    public void Ap_ResetsOnDayTransitionAtDawn()
    {
        GameState state = DefaultState.Create();
        state.ApMax = 5;
        state.Ap = 1;

        var (nightState, _, _) = Apply(state, "end");
        nightState.NightSpawnRemaining = 0;
        nightState.NightWaveTotal = 0;
        nightState.Enemies.Clear();

        var (dayState, events, _) = Apply(nightState, "wait");

        Assert.Equal("day", dayState.Phase);
        Assert.Equal(dayState.ApMax, dayState.Ap);
        Assert.Equal(5, dayState.Ap);
        Assert.Contains("Dawn breaks.", events);
    }

    [Fact]
    public void RestIntent_DoesNotConsumeAp()
    {
        GameState state = DefaultState.Create();
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "rest");

        Assert.Equal(apBefore, newState.Ap);
        Assert.Equal("Unknown intent: rest", Assert.Single(events));
    }

    [Fact]
    public void Status_DisplaysCurrentAp()
    {
        GameState state = DefaultState.Create();
        state.Ap = 2;

        var (_, events, _) = Apply(state, "status");

        string status = Assert.Single(events);
        Assert.Contains("AP: 2", status, StringComparison.Ordinal);
    }

    [Fact]
    public void MultipleActions_DrainApSequentially()
    {
        GameState state = DefaultState.Create();
        state.Ap = 3;

        var (afterFirstExplore, _, _) = Apply(state, "explore");
        var (afterSecondExplore, _, _) = Apply(afterFirstExplore, "explore");
        var (afterThirdExplore, _, _) = Apply(afterSecondExplore, "explore");
        var (afterFourthExplore, events, _) = Apply(afterThirdExplore, "explore");

        Assert.Equal(2, afterFirstExplore.Ap);
        Assert.Equal(1, afterSecondExplore.Ap);
        Assert.Equal(0, afterThirdExplore.Ap);
        Assert.Equal(0, afterFourthExplore.Ap);
        Assert.Contains("No action points remaining. Type 'end' to start the night.", events);
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
