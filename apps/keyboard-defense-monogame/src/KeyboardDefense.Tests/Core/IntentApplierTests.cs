using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class IntentApplierTests
{
    [Fact]
    public void Apply_HelpIntent_ReturnsCanonicalHelpLines()
    {
        var state = CreateState();

        var (_, events, _) = Apply(state, "help");

        Assert.Equal(SimIntents.HelpLines(), events);
    }

    [Fact]
    public void Apply_StatusIntent_ReturnsFormattedStatusLine()
    {
        var state = CreateState();
        state.Day = 4;
        state.Phase = "night";
        state.Hp = 7;
        state.Ap = 1;
        state.Gold = 22;
        state.Threat = 3;

        var (_, events, _) = Apply(state, "status");

        Assert.Single(events);
        Assert.Equal("Day 4 | Phase: night | HP: 7 | AP: 1 | Gold: 22 | Threat: 3", events[0]);
    }

    [Fact]
    public void Apply_UnknownUiIntent_UsesUiPassThroughMessage()
    {
        var state = CreateState();

        var (_, events, _) = Apply(state, "ui_toggle_panel");

        Assert.Single(events);
        Assert.Equal("UI action: ui_toggle_panel", events[0]);
    }

    [Fact]
    public void Apply_UnknownIntent_UsesUnknownIntentMessage()
    {
        var state = CreateState();

        var (_, events, _) = Apply(state, "unexpected_kind");

        Assert.Single(events);
        Assert.Equal("Unknown intent: unexpected_kind", events[0]);
    }

    [Fact]
    public void Apply_EndDuringDay_TransitionsToNightAndRequestsAutosave()
    {
        var state = CreateState();
        state.Phase = "day";

        var (newState, events, result) = Apply(state, "end");
        var request = RequireRequest(result);

        Assert.Equal("night", newState.Phase);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("night", request["reason"]?.ToString());
        Assert.Contains(events, e => e.Contains("Night falls.", StringComparison.Ordinal));
    }

    [Fact]
    public void Apply_EndDuringNight_RejectsAndDoesNotRequestAutosave()
    {
        var state = CreateState();
        state.Phase = "night";

        var (newState, events, result) = Apply(state, "end");

        Assert.Equal("night", newState.Phase);
        Assert.Contains("That action is only available during the day.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void Apply_WaitDuringDay_RejectsAction()
    {
        var state = CreateState();
        state.Phase = "day";

        var (_, events, result) = Apply(state, "wait");

        Assert.Contains("Wait is only available at night.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void Apply_WaitAtNightWithNoSpawns_RoutesToDayAndRequestsAutosave()
    {
        var state = CreateState();
        state.Phase = "night";
        state.Ap = 0;
        state.Threat = 3;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 0;
        state.Enemies.Clear();

        var (newState, events, result) = Apply(state, "wait");
        var request = RequireRequest(result);

        Assert.Equal("day", newState.Phase);
        Assert.Equal(newState.ApMax, newState.Ap);
        Assert.Equal(2, newState.Threat);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
        Assert.Contains("Dawn breaks.", events);
    }

    [Fact]
    public void Apply_DefendInputDuringDay_RejectsAction()
    {
        var state = CreateState();
        state.Phase = "day";

        var (_, events, result) = Apply(state, "defend_input", new() { ["text"] = "alpha" });

        Assert.Contains("No threats to defend right now.", events);
        Assert.False(result.ContainsKey("request"));
    }

    [Fact]
    public void Apply_DefendInputAtNightWithMatchingWord_DefeatsEnemyAndRequestsAutosaveAtDawn()
    {
        var state = CreateState();
        state.Phase = "night";
        state.Gold = 10;
        state.NightSpawnRemaining = 0;
        state.NightWaveTotal = 1;
        state.Enemies.Clear();
        state.Enemies.Add(new Dictionary<string, object>
        {
            ["word"] = "alpha",
            ["hp"] = 1,
            ["gold"] = 3,
            ["dist"] = 5,
            ["damage"] = 1,
            ["kind"] = "raider"
        });

        var (newState, events, result) = Apply(state, "defend_input", new() { ["text"] = "alpha" });
        var request = RequireRequest(result);

        Assert.Equal("day", newState.Phase);
        Assert.Empty(newState.Enemies);
        Assert.Equal(13, newState.Gold);
        Assert.Equal(1, newState.EnemiesDefeated);
        Assert.Equal("autosave", request["kind"]?.ToString());
        Assert.Equal("dawn", request["reason"]?.ToString());
        Assert.Contains(events, e => e.Contains("Typed 'alpha'", StringComparison.Ordinal));
        Assert.Contains("Dawn breaks.", events);
    }

    [Fact]
    public void Apply_MovePlayerOutOfBounds_UpdatesFacingButKeepsPosition()
    {
        var state = CreateState();
        state.PlayerPos = new GridPoint(0, 0);
        state.CursorPos = state.PlayerPos;
        state.PlayerFacing = "down";

        var (newState, events, _) = Apply(state, "move_player", new() { ["dx"] = -1, ["dy"] = 0 });

        Assert.Equal(new GridPoint(0, 0), newState.PlayerPos);
        Assert.Equal(new GridPoint(0, 0), newState.CursorPos);
        Assert.Equal("left", newState.PlayerFacing);
        Assert.Contains("You can't go that way.", events);
    }

    [Fact]
    public void Apply_MovePlayerBlockedByWater_DoesNotMoveAndReportsBlock()
    {
        var state = CreateState();
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        var blockedPos = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        int blockedIndex = SimMap.Idx(blockedPos.X, blockedPos.Y, state.MapW);
        state.Terrain[blockedIndex] = SimMap.TerrainWater;
        state.Discovered.Add(blockedIndex);

        var (newState, events, _) = Apply(state, "move_player", new() { ["dx"] = 1, ["dy"] = 0 });

        Assert.Equal(state.BasePos, newState.PlayerPos);
        Assert.Equal("right", newState.PlayerFacing);
        Assert.Contains("Blocked by water.", events);
    }

    [Fact]
    public void Apply_MovePlayerToPassableTile_UpdatesPlayerAndCursor()
    {
        var state = CreateState();
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        var target = new GridPoint(state.PlayerPos.X + 1, state.PlayerPos.Y);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        state.Terrain[targetIndex] = SimMap.TerrainPlains;
        state.Structures.Remove(targetIndex);

        var (newState, _, _) = Apply(state, "move_player", new() { ["dx"] = 1, ["dy"] = 0 });

        Assert.Equal(target, newState.PlayerPos);
        Assert.Equal(target, newState.CursorPos);
        Assert.Contains(targetIndex, newState.Discovered);
    }

    [Fact]
    public void Apply_BuildDuringNight_RejectsAction()
    {
        var state = CreateState();
        state.Phase = "night";
        var pos = PrepareBuildableTile(state, 1, 0);
        int beforeAp = state.Ap;

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Contains("That action is only available during the day.", events);
        Assert.Equal(beforeAp, newState.Ap);
    }

    [Fact]
    public void Apply_BuildOutOfBounds_RejectsAction()
    {
        var state = CreateState();

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = -1,
            ["y"] = -1
        });

        Assert.Contains("Build location out of bounds.", events);
        Assert.Empty(newState.Structures);
    }

    [Fact]
    public void Apply_BuildInsufficientResources_RejectsAction()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        int apBefore = state.Ap;
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Contains("Not enough resources to build tower.", events);
        Assert.False(newState.Structures.ContainsKey(index));
        Assert.Equal(apBefore, newState.Ap);
    }

    [Fact]
    public void Apply_BuildOnValidTile_PlacesStructureAndConsumesAp()
    {
        LoadBuildingsData();
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Resources["wood"] = 100;
        state.Resources["stone"] = 100;
        int apBefore = state.Ap;
        int woodBefore = state.Resources["wood"];
        int stoneBefore = state.Resources["stone"];
        int towerCountBefore = state.Buildings.GetValueOrDefault("tower", 0);

        var (newState, events, _) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(apBefore - 1, newState.Ap);
        Assert.Equal("tower", newState.Structures[index]);
        Assert.Equal(1, newState.StructureLevels[index]);
        Assert.Equal(towerCountBefore + 1, newState.Buildings["tower"]);
        Assert.True(newState.Resources["wood"] < woodBefore);
        Assert.True(newState.Resources["stone"] < stoneBefore);
        Assert.Contains($"Built tower at ({pos.X},{pos.Y}).", events);
    }

    [Fact]
    public void Apply_UpgradeWithoutStructure_RejectsAction()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);

        var (_, events, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Contains("No structure at that location to upgrade.", events);
    }

    [Fact]
    public void Apply_UpgradeWithInsufficientGold_RejectsAction()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 2;
        state.Gold = 9; // level 2 costs 10
        int apBefore = state.Ap;

        var (newState, events, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(2, newState.StructureLevels[index]);
        Assert.Equal(apBefore, newState.Ap);
        Assert.Contains("Need 10 gold to upgrade (have 9).", events);
    }

    [Fact]
    public void Apply_UpgradeWithStructureAndGold_IncrementsLevelAndConsumesApAndGold()
    {
        var state = CreateState();
        var pos = PrepareBuildableTile(state, 1, 0);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Structures[index] = "tower";
        state.StructureLevels[index] = 2;
        state.Gold = 15; // level 2 costs 10
        state.Ap = 3;

        var (newState, events, _) = Apply(state, "upgrade", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(3, newState.StructureLevels[index]);
        Assert.Equal(5, newState.Gold);
        Assert.Equal(2, newState.Ap);
        Assert.Contains("Upgraded tower to level 3 for 10 gold.", events);
    }

    private static GameState CreateState()
    {
        return DefaultState.Create("intent_applier_tests");
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
