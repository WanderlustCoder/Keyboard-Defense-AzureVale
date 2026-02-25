using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.E2E;

public class CommandPipelineTests
{
    private const string EmptyInputError = "Enter a command. Type 'help' for options.";
    private const string TradeUsageError = "Usage: trade <amount> <resource> for <resource>";

    [Fact]
    public void BuildTower_CommandPipeline_ParsesIntentAndPlacesStructure()
    {
        LoadBuildingsData();
        var state = DefaultState.Create();
        PrepareBuildableTile(state, 5, 5);
        int buildIndex = SimMap.Idx(5, 5, state.MapW);
        int apBefore = state.Ap;
        var cost = BuildingsData.CostFor("tower");

        state.Resources["wood"] = 500;
        state.Resources["stone"] = 500;
        state.Resources["food"] = 500;
        var resourcesBefore = new Dictionary<string, int>(state.Resources);

        var (_, intent, newState, events) = ParseAndApply(state, "build tower 5 5");

        Assert.Equal("build", intent["kind"]);
        Assert.Equal("tower", intent["building"]);
        Assert.Equal(5, Assert.IsType<int>(intent["x"]));
        Assert.Equal(5, Assert.IsType<int>(intent["y"]));
        Assert.Equal(apBefore - 1, newState.Ap);
        Assert.Equal("tower", newState.Structures[buildIndex]);
        Assert.Equal(1, newState.StructureLevels[buildIndex]);
        Assert.Contains("Built tower at (5,5).", events);
        foreach (var (resource, amount) in cost)
            Assert.Equal(resourcesBefore[resource] - amount, newState.Resources[resource]);
    }

    [Fact]
    public void MoveNorth_Command_IsCurrentlyUnknownCommand()
    {
        var parsed = CommandParser.Parse("move north");

        Assert.False(Assert.IsType<bool>(parsed["ok"]));
        Assert.Equal("Unknown command: move", Assert.IsType<string>(parsed["error"]));
    }

    [Fact]
    public void CursorUp_CommandPipeline_ParsesIntentAndMovesCursor()
    {
        var state = DefaultState.Create();
        var start = state.CursorPos;
        int expectedY = Math.Max(0, start.Y - 1);

        var (_, intent, newState, events) = ParseAndApply(state, "cursor up");

        Assert.Equal("cursor_move", intent["kind"]);
        Assert.Equal(0, Assert.IsType<int>(intent["dx"]));
        Assert.Equal(-1, Assert.IsType<int>(intent["dy"]));
        Assert.Equal(1, Assert.IsType<int>(intent["steps"]));
        Assert.Equal(new GridPoint(start.X, expectedY), newState.CursorPos);
        Assert.Equal($"Cursor at ({start.X},{expectedY}).", Assert.Single(events));
    }

    [Fact]
    public void Explore_CommandPipeline_ParsesIntentAndDiscoversTile()
    {
        var state = DefaultState.Create();
        int discoveredBefore = state.Discovered.Count;
        int apBefore = state.Ap;
        int threatBefore = state.Threat;

        var (_, intent, newState, events) = ParseAndApply(state, "explore");

        Assert.Equal("explore", intent["kind"]);
        Assert.Equal(apBefore - 1, newState.Ap);
        Assert.Equal(discoveredBefore + 1, newState.Discovered.Count);
        Assert.Equal(threatBefore + 1, newState.Threat);
        Assert.Contains(events, e => e.StartsWith("Discovered tile (", StringComparison.Ordinal));
    }

    [Fact]
    public void Trade_CommandPipeline_ParsesIntentAndExchangesResources()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 20;
        state.Resources["stone"] = 0;

        var (_, intent, newState, events) = ParseAndApply(state, "trade 5 wood for stone");

        Assert.Equal("trade_execute", intent["kind"]);
        Assert.Equal("wood", Assert.IsType<string>(intent["from_resource"]));
        Assert.Equal("stone", Assert.IsType<string>(intent["to_resource"]));
        Assert.Equal(5, Assert.IsType<int>(intent["amount"]));
        Assert.Equal(15, newState.Resources["wood"]);
        Assert.Equal(5, newState.Resources["stone"]);
        Assert.Contains("Traded 5 wood for 5 stone.", events);
    }

    [Fact]
    public void Trade_LegacyWordOrder_ReturnsUsageError()
    {
        var parsed = CommandParser.Parse("trade wood stone 5");

        Assert.False(Assert.IsType<bool>(parsed["ok"]));
        Assert.Equal(TradeUsageError, Assert.IsType<string>(parsed["error"]));
    }

    [Fact]
    public void Help_CommandPipeline_ParsesIntentAndReturnsHelpText()
    {
        var state = DefaultState.Create();

        var (_, intent, _, events) = ParseAndApply(state, "help");

        Assert.Equal("help", intent["kind"]);
        Assert.Equal("Commands:", Assert.IsType<string>(events[0]));
        Assert.Contains("  help - list commands", events);
        Assert.Contains("  build <type> [x y] - place a building (day only)", events);
    }

    [Fact]
    public void InvalidCommand_ReturnsErrorMessageAndNoIntent()
    {
        var parsed = CommandParser.Parse("xyzzy");

        Assert.False(Assert.IsType<bool>(parsed["ok"]));
        Assert.Equal("Unknown command: xyzzy", Assert.IsType<string>(parsed["error"]));
        Assert.False(parsed.ContainsKey("intent"));
    }

    [Fact]
    public void EmptyInput_ReturnsPromptErrorAndDoesNotChangeState()
    {
        var state = DefaultState.Create();
        string snapshotBefore = Snapshot(state);

        var parsed = CommandParser.Parse("   ");

        Assert.False(Assert.IsType<bool>(parsed["ok"]));
        Assert.Equal(EmptyInputError, Assert.IsType<string>(parsed["error"]));
        Assert.Equal(snapshotBefore, Snapshot(state));
    }

    private static (Dictionary<string, object> Parsed, Dictionary<string, object> Intent, GameState State, List<string> Events) ParseAndApply(
        GameState state,
        string command)
    {
        var parsed = CommandParser.Parse(command);
        Assert.True((bool)parsed["ok"], $"Command '{command}' should parse successfully.");
        var intent = Assert.IsType<Dictionary<string, object>>(parsed["intent"]);
        var result = IntentApplier.Apply(state, intent);
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (parsed, intent, newState, events);
    }

    private static void PrepareBuildableTile(GameState state, int x, int y)
    {
        Assert.True(SimMap.InBounds(x, y, state.MapW, state.MapH));
        int index = SimMap.Idx(x, y, state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
    }

    private static string Snapshot(GameState state)
    {
        return string.Join(
            "|",
            state.Day,
            state.Phase,
            state.Ap,
            state.Hp,
            state.Threat,
            state.Gold,
            state.CursorPos.X,
            state.CursorPos.Y,
            state.PlayerPos.X,
            state.PlayerPos.Y,
            state.Discovered.Count,
            state.Structures.Count,
            state.Resources.GetValueOrDefault("wood", 0),
            state.Resources.GetValueOrDefault("stone", 0),
            state.Resources.GetValueOrDefault("food", 0));
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
