using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public sealed class IntentApplierNavigationTests : IDisposable
{
    public IntentApplierNavigationTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    [Fact]
    public void Apply_Cursor_InBounds_MovesCursorAndAddsEvent()
    {
        var state = CreateState("nav_cursor_in_bounds");
        var target = new GridPoint(state.BasePos.X + 2, state.BasePos.Y + 1);

        var (newState, events, _) = Apply(state, "cursor", new()
        {
            ["x"] = target.X,
            ["y"] = target.Y,
        });

        Assert.Equal(target, newState.CursorPos);
        Assert.Equal($"Cursor moved to ({target.X},{target.Y}).", Assert.Single(events));
    }

    [Fact]
    public void Apply_Cursor_OutOfBounds_DoesNotMoveCursorAndAddsError()
    {
        var state = CreateState("nav_cursor_oob");
        GridPoint start = state.CursorPos;

        var (newState, events, _) = Apply(state, "cursor", new()
        {
            ["x"] = -1,
            ["y"] = 0,
        });

        Assert.Equal(start, newState.CursorPos);
        Assert.Equal("Cursor position out of bounds.", Assert.Single(events));
    }

    [Fact]
    public void Apply_CursorMove_AppliesDeltaAndStepCount()
    {
        var state = CreateState("nav_cursor_move_steps");
        var start = new GridPoint(10, 10);
        state.CursorPos = start;

        var (newState, events, _) = Apply(state, "cursor_move", new()
        {
            ["dx"] = -1,
            ["dy"] = 1,
            ["steps"] = 3,
        });

        var expected = new GridPoint(7, 13);
        Assert.Equal(expected, newState.CursorPos);
        Assert.Equal($"Cursor at ({expected.X},{expected.Y}).", Assert.Single(events));
    }

    [Fact]
    public void Apply_CursorMove_ClampsToMapBounds()
    {
        var state = CreateState("nav_cursor_move_clamp");
        state.CursorPos = new GridPoint(0, 0);

        var (newState, events, _) = Apply(state, "cursor_move", new()
        {
            ["dx"] = -1,
            ["dy"] = -1,
            ["steps"] = 99,
        });

        Assert.Equal(new GridPoint(0, 0), newState.CursorPos);
        Assert.Equal("Cursor at (0,0).", Assert.Single(events));
    }

    [Fact]
    public void Apply_Inspect_OnUndiscoveredTile_ReportsNotDiscovered()
    {
        var state = CreateState("nav_inspect_undiscovered");
        var tile = FindUndiscoveredTile(state);

        var (_, events, _) = Apply(state, "inspect", new()
        {
            ["x"] = tile.X,
            ["y"] = tile.Y,
        });

        Assert.Equal($"Tile ({tile.X},{tile.Y}) is not discovered.", Assert.Single(events));
    }

    [Fact]
    public void Apply_Inspect_OnDiscoveredTileWithStructure_ReportsTerrainAndStructure()
    {
        var state = CreateState("nav_inspect_discovered");
        var tile = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int index = SimMap.Idx(tile.X, tile.Y, state.MapW);
        state.Discovered.Add(index);
        state.Terrain[index] = SimMap.TerrainForest;
        state.Structures[index] = "farm";
        state.StructureLevels[index] = 2;

        var (_, events, _) = Apply(state, "inspect", new()
        {
            ["x"] = tile.X,
            ["y"] = tile.Y,
        });

        Assert.Equal(2, events.Count);
        Assert.Equal($"Tile ({tile.X},{tile.Y}): {SimMap.TerrainForest}", events[0]);
        Assert.Equal("  Structure: farm (level 2)", events[1]);
    }

    [Fact]
    public void Apply_InspectTile_UsesCursorAndIncludesStructure()
    {
        var state = CreateState("nav_inspect_tile");
        state.CursorPos = state.BasePos;
        int index = SimMap.Idx(state.CursorPos.X, state.CursorPos.Y, state.MapW);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures[index] = "market";

        var (_, events, _) = Apply(state, "inspect_tile");

        Assert.Equal(2, events.Count);
        Assert.Equal($"You see: {SimMap.TerrainPlains} at ({state.CursorPos.X},{state.CursorPos.Y}).", events[0]);
        Assert.Equal("  Structure: market", events[1]);
    }

    [Fact]
    public void Apply_Map_ReportsDimensionsDiscoveryStructureCountAndCursor()
    {
        var state = CreateState("nav_map_summary");
        state.CursorPos = new GridPoint(state.BasePos.X + 2, state.BasePos.Y);

        int structureA = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);
        int structureB = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        state.Structures[structureA] = "farm";
        state.Structures[structureB] = "tower";

        var (_, events, _) = Apply(state, "map");

        Assert.Equal(3, events.Count);
        Assert.Equal(
            $"Map: {state.MapW}x{state.MapH} ({state.Discovered.Count}/{state.MapW * state.MapH} tiles discovered)",
            events[0]);
        Assert.Equal($"  Structures: {state.Structures.Count} | Base: ({state.BasePos.X},{state.BasePos.Y})", events[1]);
        Assert.Equal($"  Cursor: ({state.CursorPos.X},{state.CursorPos.Y})", events[2]);
    }

    [Fact]
    public void Apply_ZoneCommands_ReportExpectedMessages()
    {
        var state = CreateState("nav_zone_commands");

        var (_, zoneShowEvents, _) = Apply(state, "zone_show");
        var (_, zoneSummaryEvents, _) = Apply(state, "zone_summary");

        Assert.Equal("Zone view: showing map regions.", Assert.Single(zoneShowEvents));
        Assert.Equal(
            $"Zone summary: {state.Discovered.Count} tiles discovered across the kingdom.",
            Assert.Single(zoneSummaryEvents));
    }

    [Fact]
    public void Apply_MovePlayer_EnforcesBoundsAndPassabilityAndMovesOnValidTile()
    {
        var boundsState = CreateState("nav_move_bounds");
        boundsState.PlayerPos = new GridPoint(0, 0);
        boundsState.CursorPos = boundsState.PlayerPos;
        int edgeIndex = SimMap.Idx(0, 0, boundsState.MapW);
        boundsState.Terrain[edgeIndex] = SimMap.TerrainPlains;
        boundsState.Discovered.Add(edgeIndex);

        var (afterBounds, boundsEvents, _) = Apply(boundsState, "move_player", new()
        {
            ["dx"] = -1,
            ["dy"] = 0,
        });

        Assert.Equal(new GridPoint(0, 0), afterBounds.PlayerPos);
        Assert.Equal(new GridPoint(0, 0), afterBounds.CursorPos);
        Assert.Equal("left", afterBounds.PlayerFacing);
        Assert.Contains("You can't go that way.", boundsEvents);

        var blockedState = CreateState("nav_move_blocked");
        blockedState.PlayerPos = blockedState.BasePos;
        blockedState.CursorPos = blockedState.BasePos;
        var blockedPos = new GridPoint(blockedState.PlayerPos.X + 1, blockedState.PlayerPos.Y);
        int blockedIndex = SimMap.Idx(blockedPos.X, blockedPos.Y, blockedState.MapW);
        blockedState.Terrain[blockedIndex] = SimMap.TerrainPlains;
        blockedState.Structures[blockedIndex] = "tower";
        blockedState.Discovered.Add(blockedIndex);

        var (afterBlocked, blockedEvents, _) = Apply(blockedState, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0,
        });

        Assert.Equal(blockedState.BasePos, afterBlocked.PlayerPos);
        Assert.Equal("right", afterBlocked.PlayerFacing);
        Assert.Contains("Blocked by plains.", blockedEvents);
        int[] distToBase = SimMap.ComputeDistToBase(afterBlocked);
        Assert.Equal(-1, distToBase[blockedIndex]);

        var moveState = CreateState("nav_move_success");
        var start = new GridPoint(Math.Min(moveState.MapW - 3, moveState.BasePos.X + 10), moveState.BasePos.Y);
        moveState.PlayerPos = start;
        moveState.CursorPos = start;
        int startIndex = SimMap.Idx(start.X, start.Y, moveState.MapW);
        moveState.Terrain[startIndex] = SimMap.TerrainPlains;
        moveState.Discovered.Add(startIndex);

        var target = new GridPoint(start.X + 1, start.Y);
        int targetIndex = SimMap.Idx(target.X, target.Y, moveState.MapW);
        moveState.Terrain[targetIndex] = SimMap.TerrainPlains;
        moveState.Structures.Remove(targetIndex);
        int discoveredBefore = moveState.Discovered.Count;

        var (movedState, moveEvents, _) = Apply(moveState, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0,
        });

        Assert.Equal(target, movedState.PlayerPos);
        Assert.Equal(target, movedState.CursorPos);
        Assert.Contains(targetIndex, movedState.Discovered);
        Assert.True(movedState.Discovered.Count > discoveredBefore);
        Assert.Empty(moveEvents);
    }

    private static GameState CreateState(string seed)
    {
        return DefaultState.Create(seed);
    }

    private static GridPoint FindUndiscoveredTile(GameState state)
    {
        for (int y = 0; y < state.MapH; y++)
        {
            for (int x = 0; x < state.MapW; x++)
            {
                int index = SimMap.Idx(x, y, state.MapW);
                if (!state.Discovered.Contains(index))
                    return new GridPoint(x, y);
            }
        }

        throw new InvalidOperationException("Expected at least one undiscovered tile.");
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
}
