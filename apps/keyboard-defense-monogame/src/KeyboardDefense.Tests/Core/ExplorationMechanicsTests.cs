using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public sealed class ExplorationMechanicsTests : IDisposable
{
    public ExplorationMechanicsTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    [Fact]
    public void Explore_ActionCostsAp()
    {
        var state = CreateState("exploration_action_costs_ap");
        state.Ap = 2;
        int apBefore = state.Ap;

        var (afterExplore, events) = Apply(state, "explore");

        Assert.Equal(apBefore - 1, afterExplore.Ap);
        Assert.Contains(events, e => e.StartsWith("Discovered tile (", StringComparison.Ordinal));
    }

    [Fact]
    public void MovePlayer_ExplorationRevealsTilesInRadiusAroundDestination()
    {
        var state = CreateState("exploration_reveals_radius");
        var start = new GridPoint(state.BasePos.X + 10, state.BasePos.Y);
        var destination = new GridPoint(start.X + 1, start.Y);
        Assert.True(SimMap.InBounds(destination.X, destination.Y, state.MapW, state.MapH));

        PreparePassableTile(state, start);
        PreparePassableTile(state, destination);
        state.PlayerPos = start;
        state.CursorPos = start;

        var discoveredBefore = new HashSet<int>(state.Discovered);

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0,
        });

        Assert.Equal(destination, afterMove.PlayerPos);
        Assert.True(afterMove.Discovered.Count > discoveredBefore.Count);

        int discoverRadius = 3 + TypingProficiency.GetDiscoveryRadiusBonus(TypingProficiency.GetTier());
        for (int dy = -discoverRadius; dy <= discoverRadius; dy++)
        {
            for (int dx = -discoverRadius; dx <= discoverRadius; dx++)
            {
                int x = destination.X + dx;
                int y = destination.Y + dy;
                if (!SimMap.InBounds(x, y, afterMove.MapW, afterMove.MapH))
                    continue;

                int index = SimMap.Idx(x, y, afterMove.MapW);
                Assert.Contains(index, afterMove.Discovered);
            }
        }
    }

    [Fact]
    public void MovePlayer_AlreadyExploredArea_DoesNotCostAp()
    {
        var state = CreateState("exploration_known_tiles_no_ap");
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        state.Ap = 2;

        int discoveredBefore = state.Discovered.Count;
        int apBefore = state.Ap;
        int knownTile = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);
        Assert.Contains(knownTile, state.Discovered);

        var (afterMove, events) = Apply(state, "move_player", new()
        {
            ["dx"] = 1,
            ["dy"] = 0,
        });

        Assert.Equal(apBefore, afterMove.Ap);
        Assert.Equal(discoveredBefore, afterMove.Discovered.Count);
        Assert.Empty(events);
    }

    [Fact]
    public void MovePlayer_ExplorationAtMapEdge_StaysInBoundsAndRevealsOnlyValidTiles()
    {
        var state = CreateState("exploration_edge_bounds");
        var start = new GridPoint(1, 0);
        var edge = new GridPoint(0, 0);

        PreparePassableTile(state, start);
        PreparePassableTile(state, edge);
        state.PlayerPos = start;
        state.CursorPos = start;

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = -1,
            ["dy"] = 0,
        });

        Assert.Equal(edge, afterMove.PlayerPos);

        int discoverRadius = 3 + TypingProficiency.GetDiscoveryRadiusBonus(TypingProficiency.GetTier());
        for (int dy = -discoverRadius; dy <= discoverRadius; dy++)
        {
            for (int dx = -discoverRadius; dx <= discoverRadius; dx++)
            {
                int x = edge.X + dx;
                int y = edge.Y + dy;
                if (!SimMap.InBounds(x, y, afterMove.MapW, afterMove.MapH))
                    continue;

                int index = SimMap.Idx(x, y, afterMove.MapW);
                Assert.Contains(index, afterMove.Discovered);
            }
        }

        int maxIndex = afterMove.MapW * afterMove.MapH - 1;
        Assert.All(afterMove.Discovered, idx => Assert.InRange(idx, 0, maxIndex));
    }

    [Fact]
    public void MovePlayer_ExplorationRevealsResourceNodeTileWhenItBecomesVisible()
    {
        var state = CreateState("exploration_reveals_resource_node");
        var target = FindUndiscoveredTile(state);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        Assert.DoesNotContain(targetIndex, state.Discovered);

        state.ResourceNodes[targetIndex] = new Dictionary<string, object>
        {
            ["type"] = "wood_grove",
            ["pos"] = target,
            ["zone"] = SimMap.ZoneWilderness,
            ["cooldown"] = 0,
        };

        PreparePassableTile(state, target);
        state.PlayerPos = target;
        state.CursorPos = target;

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 0,
            ["dy"] = 0,
        });

        Assert.Contains(targetIndex, afterMove.Discovered);
        Assert.True(afterMove.ResourceNodes.ContainsKey(targetIndex));
    }

    [Fact]
    public void MovePlayer_ExplorationRevealsNpcTileWhenItBecomesVisible()
    {
        var state = CreateState("exploration_reveals_npc");
        var target = FindUndiscoveredTile(state);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);
        Assert.DoesNotContain(targetIndex, state.Discovered);

        state.Npcs.Add(new Dictionary<string, object>
        {
            ["type"] = "merchant",
            ["pos"] = target,
            ["name"] = "Scout Merchant",
            ["quest_available"] = false,
            ["facing"] = "south",
        });

        PreparePassableTile(state, target);
        state.PlayerPos = target;
        state.CursorPos = target;

        var (afterMove, _) = Apply(state, "move_player", new()
        {
            ["dx"] = 0,
            ["dy"] = 0,
        });

        Assert.Contains(targetIndex, afterMove.Discovered);
    }

    [Fact]
    public void TotalExplorationPercentage_TracksDiscoveredTileRatio()
    {
        var state = CreateState("exploration_percentage_ratio");
        state.Ap = 3;

        int totalTiles = state.MapW * state.MapH;
        int discoveredBefore = state.Discovered.Count;
        double before = SimMap.GetTotalExploration(state);

        var (afterExplore, _) = Apply(state, "explore");
        double after = SimMap.GetTotalExploration(afterExplore);

        Assert.Equal((double)discoveredBefore / totalTiles, before, 8);
        Assert.Equal((double)(discoveredBefore + 1) / totalTiles, after, 8);
        Assert.Equal((double)afterExplore.Discovered.Count / totalTiles, after, 8);
    }

    [Fact]
    public void Explore_ActionIsBlockedDuringNightPhase()
    {
        var state = CreateState("exploration_blocked_night");
        state.Phase = "night";
        state.Ap = 2;
        int discoveredBefore = state.Discovered.Count;
        int threatBefore = state.Threat;

        var (afterExplore, events) = Apply(state, "explore");

        Assert.Equal(2, afterExplore.Ap);
        Assert.Equal(discoveredBefore, afterExplore.Discovered.Count);
        Assert.Equal(threatBefore, afterExplore.Threat);
        Assert.Equal("That action is only available during the day.", Assert.Single(events));
    }

    private static GameState CreateState(string seed)
    {
        return DefaultState.Create(seed);
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
                int index = SimMap.Idx(x, y, state.MapW);
                if (!state.Discovered.Contains(index))
                    return new GridPoint(x, y);
            }
        }

        throw new InvalidOperationException("Expected at least one undiscovered tile.");
    }

    private static void PreparePassableTile(GameState state, GridPoint pos)
    {
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Terrain[index] = SimMap.TerrainPlains;
        state.Structures.Remove(index);
        state.StructureLevels.Remove(index);
    }
}
