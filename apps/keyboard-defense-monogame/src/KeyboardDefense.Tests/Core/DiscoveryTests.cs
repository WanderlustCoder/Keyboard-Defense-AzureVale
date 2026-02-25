using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public sealed class DiscoveryTests : IDisposable
{
    public DiscoveryTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    [Fact]
    public void Create_InitialDiscoveryRadiusAroundBase_IsSquareRadiusFive()
    {
        var state = CreateState("discovery_initial_radius");

        var expected = new HashSet<int>();
        for (int dy = -5; dy <= 5; dy++)
        {
            for (int dx = -5; dx <= 5; dx++)
            {
                int x = state.BasePos.X + dx;
                int y = state.BasePos.Y + dy;
                if (SimMap.InBounds(x, y, state.MapW, state.MapH))
                    expected.Add(SimMap.Idx(x, y, state.MapW));
            }
        }

        Assert.Equal(expected.Count, state.Discovered.Count);
        Assert.True(state.Discovered.SetEquals(expected));
    }

    [Fact]
    public void FogFrontier_ForStartingDiscovery_HasExpectedOrthogonalEdgeShape()
    {
        var state = CreateState("discovery_fog_start_shape");

        HashSet<int> frontier = ComputeFogFrontier(state);

        Assert.Equal(44, frontier.Count);
        Assert.Contains(SimMap.Idx(state.BasePos.X - 6, state.BasePos.Y, state.MapW), frontier);
        Assert.Contains(SimMap.Idx(state.BasePos.X + 6, state.BasePos.Y, state.MapW), frontier);
        Assert.Contains(SimMap.Idx(state.BasePos.X, state.BasePos.Y - 6, state.MapW), frontier);
        Assert.Contains(SimMap.Idx(state.BasePos.X, state.BasePos.Y + 6, state.MapW), frontier);

        // Diagonal corner outside the square should not be in an orthogonal frontier.
        int diagonalOutside = SimMap.Idx(state.BasePos.X + 6, state.BasePos.Y + 6, state.MapW);
        Assert.DoesNotContain(diagonalOutside, frontier);
    }

    [Fact]
    public void Explore_ExpandsDiscoveryByOneTile_AndIncreasesThreat()
    {
        var state = CreateState("discovery_explore_expands");
        state.Ap = 10;
        int threatBefore = state.Threat;
        var discoveredBefore = new HashSet<int>(state.Discovered);

        var (afterExplore, events) = Apply(state, "explore");

        int newTile = Assert.Single(afterExplore.Discovered.Except(discoveredBefore));
        Assert.Contains(newTile, afterExplore.Discovered);
        Assert.Equal(discoveredBefore.Count + 1, afterExplore.Discovered.Count);
        Assert.Equal(threatBefore + 1, afterExplore.Threat);
        Assert.Contains(events, e => e.Contains("Discovered tile", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Explore_SelectsTileFromCurrentFogFrontier()
    {
        var state = CreateState("discovery_explore_frontier_pick");
        state.Ap = 10;

        var discoveredBefore = new HashSet<int>(state.Discovered);
        var frontierBefore = ComputeFogFrontier(state);

        var (afterExplore, _) = Apply(state, "explore");
        int newTile = Assert.Single(afterExplore.Discovered.Except(discoveredBefore));

        Assert.Contains(newTile, frontierBefore);
    }

    [Fact]
    public void MovePlayer_RevealsTilesWithinDiscoveryRadiusAroundDestination()
    {
        var state = CreateState("discovery_move_reveal_radius");

        var start = new GridPoint(state.BasePos.X + 10, state.BasePos.Y);
        var destination = new GridPoint(start.X + 1, start.Y);
        Assert.True(SimMap.InBounds(destination.X, destination.Y, state.MapW, state.MapH));

        int startIdx = SimMap.Idx(start.X, start.Y, state.MapW);
        int destinationIdx = SimMap.Idx(destination.X, destination.Y, state.MapW);
        state.Terrain[startIdx] = SimMap.TerrainPlains;
        state.Terrain[destinationIdx] = SimMap.TerrainPlains;
        state.Structures.Remove(destinationIdx);
        state.PlayerPos = start;
        state.CursorPos = start;

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0,
        });

        Assert.Equal(destination, afterMove.PlayerPos);
        Assert.Equal(destination, afterMove.CursorPos);

        int discoverRadius = 3 + TypingProficiency.GetDiscoveryRadiusBonus(TypingProficiency.GetTier());
        for (int dy = -discoverRadius; dy <= discoverRadius; dy++)
        {
            for (int dx = -discoverRadius; dx <= discoverRadius; dx++)
            {
                int x = destination.X + dx;
                int y = destination.Y + dy;
                if (!SimMap.InBounds(x, y, afterMove.MapW, afterMove.MapH))
                    continue;

                int idx = SimMap.Idx(x, y, afterMove.MapW);
                Assert.Contains(idx, afterMove.Discovered);
            }
        }
    }

    [Fact]
    public void Discovery_PersistsAcrossDayNightAndDawnTransitions()
    {
        var state = CreateState("discovery_persists_day_night");
        state.Ap = 10;
        var (afterExplore, _) = Apply(state, "explore");
        var discoveredSnapshot = new HashSet<int>(afterExplore.Discovered);

        var (nightState, _) = Apply(afterExplore, "end");
        Assert.Equal("night", nightState.Phase);
        Assert.True(nightState.Discovered.SetEquals(discoveredSnapshot));

        nightState.NightSpawnRemaining = 0;
        nightState.NightWaveTotal = 0;
        nightState.Enemies.Clear();

        var (dawnState, events) = Apply(nightState, "wait");

        Assert.Equal("day", dawnState.Phase);
        Assert.True(dawnState.Discovered.SetEquals(discoveredSnapshot));
        Assert.Contains(events, e => e.Contains("Dawn breaks", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Build_OnUndiscoveredTile_IsBlocked()
    {
        var state = CreateState("discovery_build_blocked");
        var tile = FindUndiscoveredTile(state);
        int tileIndex = SimMap.Idx(tile.X, tile.Y, state.MapW);
        state.Terrain[tileIndex] = SimMap.TerrainPlains;
        state.Resources["wood"] = 999;
        state.Resources["stone"] = 999;
        int apBefore = state.Ap;

        var (afterBuild, events) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = tile.X,
            ["y"] = tile.Y,
        });

        Assert.Equal(apBefore, afterBuild.Ap);
        Assert.DoesNotContain(tileIndex, afterBuild.Structures.Keys);
        Assert.Contains(events, e => e.Contains("not discovered", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Build_OnDiscoveredTile_AllowsPlacement()
    {
        var state = CreateState("discovery_build_allowed");
        var tile = FindUndiscoveredTile(state);
        int tileIndex = SimMap.Idx(tile.X, tile.Y, state.MapW);
        state.Terrain[tileIndex] = SimMap.TerrainPlains;
        state.Discovered.Add(tileIndex);
        state.Resources["wood"] = 999;
        state.Resources["stone"] = 999;
        int apBefore = state.Ap;

        var (afterBuild, events) = Apply(state, "build", new()
        {
            ["building"] = "tower",
            ["x"] = tile.X,
            ["y"] = tile.Y,
        });

        Assert.Equal(apBefore - 1, afterBuild.Ap);
        Assert.Equal("tower", afterBuild.Structures[tileIndex]);
        Assert.Contains(events, e => e.Contains("Built tower", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Discovery_RevealsUndiscoveredNpcTileWhenEnteringItsArea()
    {
        var state = CreateState("discovery_reveals_npc_tile");
        var npcPos = FindUndiscoveredNpcPos(state);
        int npcIndex = SimMap.Idx(npcPos.X, npcPos.Y, state.MapW);
        Assert.DoesNotContain(npcIndex, state.Discovered);

        state.PlayerPos = npcPos;
        state.CursorPos = npcPos;

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 0,
            ["dy"] = 0,
        });

        Assert.Contains(npcIndex, afterMove.Discovered);
    }

    [Fact]
    public void Discovery_RevealsUndiscoveredResourceNodeTileWhenEnteringItsArea()
    {
        var state = CreateState("discovery_reveals_resource_tile");
        var resourcePos = FindUndiscoveredResourceNodePos(state);
        int resourceIndex = SimMap.Idx(resourcePos.X, resourcePos.Y, state.MapW);
        Assert.DoesNotContain(resourceIndex, state.Discovered);

        state.PlayerPos = resourcePos;
        state.CursorPos = resourcePos;

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 0,
            ["dy"] = 0,
        });

        Assert.Contains(resourceIndex, afterMove.Discovered);
    }

    private static GameState CreateState(string seed)
    {
        return DefaultState.Create(seed, placeStartingTowers: false, useWorldSpec: false);
    }

    private static (GameState State, List<string> Events) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }

    private static GridPoint FindUndiscoveredTile(GameState state)
    {
        for (int y = 0; y < state.MapH; y++)
        {
            for (int x = 0; x < state.MapW; x++)
            {
                int idx = SimMap.Idx(x, y, state.MapW);
                if (!state.Discovered.Contains(idx) && !(x == state.BasePos.X && y == state.BasePos.Y))
                    return new GridPoint(x, y);
            }
        }

        throw new InvalidOperationException("Expected at least one undiscovered tile.");
    }

    private static GridPoint FindUndiscoveredNpcPos(GameState state)
    {
        foreach (var npc in state.Npcs)
        {
            if (npc.GetValueOrDefault("pos") is not GridPoint pos)
                continue;

            int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);
            if (!state.Discovered.Contains(idx))
                return pos;
        }

        throw new InvalidOperationException("Expected at least one NPC outside discovered area.");
    }

    private static GridPoint FindUndiscoveredResourceNodePos(GameState state)
    {
        foreach (var (idx, node) in state.ResourceNodes)
        {
            if (node.GetValueOrDefault("pos") is not GridPoint pos)
                continue;

            if (!state.Discovered.Contains(idx))
                return pos;
        }

        throw new InvalidOperationException("Expected at least one resource node outside discovered area.");
    }

    private static HashSet<int> ComputeFogFrontier(GameState state)
    {
        var frontier = new HashSet<int>();
        foreach (int discoveredIdx in state.Discovered)
        {
            var discoveredPos = GridPoint.FromIndex(discoveredIdx, state.MapW);
            foreach (var neighbor in SimMap.Neighbors4(discoveredPos, state.MapW, state.MapH))
            {
                int neighborIdx = SimMap.Idx(neighbor.X, neighbor.Y, state.MapW);
                if (!state.Discovered.Contains(neighborIdx))
                    frontier.Add(neighborIdx);
            }
        }

        return frontier;
    }
}
