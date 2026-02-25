using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public sealed class PathfindingTests
{
    [Fact]
    public void FindPath_ShortestPathBetweenTwoPoints_ReturnsMinimalStepPath()
    {
        var state = CreateState("pathfinding-shortest", 5, 5);
        var start = new GridPoint(0, 0);
        var end = new GridPoint(4, 4);

        var path = FindPath(state, start, end);

        AssertPathStartsEndsAndMovesByOne(path, start, end);
        Assert.Equal(9, path.Count); // Manhattan distance (8) + start tile.
    }

    [Fact]
    public void FindPath_AvoidsWaterAndMountainTiles()
    {
        var state = CreateState("pathfinding-terrain", 5, 5);
        var start = new GridPoint(0, 2);
        var end = new GridPoint(4, 2);

        SetTerrain(state, new GridPoint(1, 2), SimMap.Water);
        SetTerrain(state, new GridPoint(2, 2), SimMap.Mountain);
        SetTerrain(state, new GridPoint(3, 2), SimMap.Water);

        var path = FindPath(state, start, end);

        AssertPathStartsEndsAndMovesByOne(path, start, end);
        Assert.Equal(7, path.Count);
        Assert.DoesNotContain(path, tile =>
        {
            string terrain = SimMap.GetTerrain(state, tile);
            return terrain == SimMap.Water || terrain == SimMap.Mountain;
        });
    }

    [Fact]
    public void FindPath_PrefersRoadCorridor_WhenRoadCostIsLowerThanPlains()
    {
        var state = CreateState("pathfinding-roads", 7, 3);
        var start = new GridPoint(0, 1);
        var end = new GridPoint(6, 1);

        for (int x = 0; x < state.MapW; x++)
            SetTerrain(state, new GridPoint(x, 0), SimMap.Road);

        var path = FindPath(state, start, end);

        AssertPathStartsEndsAndMovesByOne(path, start, end);
        int roadTiles = path.Count(tile => SimMap.GetTerrain(state, tile) == SimMap.Road);
        Assert.True(roadTiles >= 5, $"Expected road preference, but only {roadTiles} road tiles were used.");
    }

    [Fact]
    public void FindPath_NoPathBetweenDisconnectedRegions_ReturnsEmpty()
    {
        var state = CreateState("pathfinding-disconnected", 5, 5);
        var start = new GridPoint(0, 0);
        var end = new GridPoint(2, 2);

        SetTerrain(state, new GridPoint(1, 2), SimMap.Water);
        SetTerrain(state, new GridPoint(3, 2), SimMap.Water);
        SetTerrain(state, new GridPoint(2, 1), SimMap.Mountain);
        SetTerrain(state, new GridPoint(2, 3), SimMap.Mountain);

        var path = FindPath(state, start, end);

        Assert.Empty(path);
    }

    [Fact]
    public void FindPath_PathIncludesStartAndEnd()
    {
        var state = CreateState("pathfinding-endpoints", 3, 3);
        var start = new GridPoint(1, 1);
        var end = new GridPoint(1, 2);

        var path = FindPath(state, start, end);

        Assert.Equal(2, path.Count);
        Assert.Equal(start, path[0]);
        Assert.Equal(end, path[^1]);
    }

    [Fact]
    public void FindPath_EmptyMap_ReturnsEmpty()
    {
        var state = CreateState("pathfinding-empty-map", 0, 0);

        var path = FindPath(state, new GridPoint(0, 0), new GridPoint(0, 0));

        Assert.Empty(path);
    }

    [Fact]
    public void FindPath_StartEqualsEnd_ReturnsSingleTilePath()
    {
        var state = CreateState("pathfinding-start-equals-end", 4, 4);
        var point = new GridPoint(2, 2);

        var path = FindPath(state, point, point);

        Assert.Single(path);
        Assert.Equal(point, path[0]);
    }

    [Fact]
    public void FindPath_WithEnemyBlockedTiles_AvoidsEnemyPositions()
    {
        var state = CreateState("pathfinding-enemy-blocks", 5, 5);
        var start = new GridPoint(0, 2);
        var end = new GridPoint(4, 2);

        AddRoamingEnemy(state, new GridPoint(1, 2), 1);
        AddRoamingEnemy(state, new GridPoint(2, 2), 2);
        AddRoamingEnemy(state, new GridPoint(3, 2), 3);

        var path = FindPath(state, start, end, blockEnemies: true);

        AssertPathStartsEndsAndMovesByOne(path, start, end);
        var blockedTiles = GetEnemyBlockedTiles(state);
        Assert.DoesNotContain(path, blockedTiles.Contains);
    }

    [Fact]
    public void FindPath_StartOrEndBlocked_ReturnsEmpty()
    {
        var state = CreateState("pathfinding-blocked-endpoints", 4, 4);
        var start = new GridPoint(0, 0);
        var end = new GridPoint(3, 3);

        SetTerrain(state, start, SimMap.Mountain);
        Assert.Empty(FindPath(state, start, end));

        SetTerrain(state, start, SimMap.Plains);
        SetTerrain(state, end, SimMap.Water);
        Assert.Empty(FindPath(state, start, end));
    }

    private static GameState CreateState(string seed, int width, int height, string defaultTerrain = SimMap.Plains)
    {
        var state = DefaultState.Create(seed);

        state.MapW = width;
        state.MapH = height;
        state.BasePos = width > 0 && height > 0
            ? new GridPoint(width / 2, height / 2)
            : GridPoint.Zero;
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;

        state.Terrain.Clear();
        for (int i = 0; i < width * height; i++)
            state.Terrain.Add(defaultTerrain);

        state.Discovered.Clear();
        for (int i = 0; i < width * height; i++)
            state.Discovered.Add(i);

        state.Structures.Clear();
        state.StructureLevels.Clear();
        state.Enemies.Clear();
        state.RoamingEnemies.Clear();
        state.Npcs.Clear();
        state.ResourceNodes.Clear();

        return state;
    }

    private static void SetTerrain(GameState state, GridPoint pos, string terrain)
    {
        Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Terrain[index] = terrain;
    }

    private static void AddRoamingEnemy(GameState state, GridPoint pos, int id)
    {
        state.RoamingEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = id,
            ["kind"] = "scout",
            ["pos"] = pos,
        });
    }

    private static List<GridPoint> FindPath(GameState state, GridPoint start, GridPoint end, bool blockEnemies = false)
    {
        if (state.MapW <= 0 || state.MapH <= 0)
            return new();

        if (!SimMap.InBounds(start.X, start.Y, state.MapW, state.MapH) ||
            !SimMap.InBounds(end.X, end.Y, state.MapW, state.MapH))
        {
            return new();
        }

        if (start == end)
            return new List<GridPoint> { start };

        var enemyBlocked = blockEnemies ? GetEnemyBlockedTiles(state) : new HashSet<GridPoint>();
        if (!IsWalkable(state, start, start, end, enemyBlocked) ||
            !IsWalkable(state, end, start, end, enemyBlocked))
        {
            return new();
        }

        var frontier = new PriorityQueue<GridPoint, int>();
        var cameFrom = new Dictionary<GridPoint, GridPoint>();
        var costSoFar = new Dictionary<GridPoint, int> { [start] = 0 };
        frontier.Enqueue(start, 0);

        while (frontier.Count > 0)
        {
            GridPoint current = frontier.Dequeue();
            if (current == end)
                break;

            foreach (GridPoint next in SimMap.Neighbors4(current, state.MapW, state.MapH))
            {
                if (!IsWalkable(state, next, start, end, enemyBlocked))
                    continue;

                int newCost = costSoFar[current] + MovementCost(state, next);
                if (costSoFar.TryGetValue(next, out int knownCost) && newCost >= knownCost)
                    continue;

                costSoFar[next] = newCost;
                cameFrom[next] = current;
                int priority = newCost + Heuristic(next, end);
                frontier.Enqueue(next, priority);
            }
        }

        if (!cameFrom.ContainsKey(end))
            return new();

        return ReconstructPath(cameFrom, start, end);
    }

    private static List<GridPoint> ReconstructPath(
        Dictionary<GridPoint, GridPoint> cameFrom,
        GridPoint start,
        GridPoint end)
    {
        var path = new List<GridPoint> { end };
        GridPoint current = end;

        while (current != start)
        {
            current = cameFrom[current];
            path.Add(current);
        }

        path.Reverse();
        return path;
    }

    private static bool IsWalkable(
        GameState state,
        GridPoint pos,
        GridPoint start,
        GridPoint end,
        HashSet<GridPoint> enemyBlocked)
    {
        if (!SimMap.IsPassable(state, pos))
            return false;

        if (enemyBlocked.Contains(pos) && pos != start && pos != end)
            return false;

        string terrain = SimMap.GetTerrain(state, pos);
        return terrain != SimMap.Water && terrain != SimMap.Mountain;
    }

    private static int MovementCost(GameState state, GridPoint pos)
    {
        string terrain = SimMap.GetTerrain(state, pos);
        return terrain switch
        {
            SimMap.Road => 1,
            SimMap.Plains => 3,
            SimMap.Desert => 3,
            SimMap.Snow => 3,
            SimMap.Forest => 4,
            _ => 5,
        };
    }

    private static int Heuristic(GridPoint current, GridPoint end)
        => current.ManhattanDistance(end);

    private static HashSet<GridPoint> GetEnemyBlockedTiles(GameState state)
    {
        var blocked = new HashSet<GridPoint>();

        foreach (var enemy in state.Enemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint pos)
                blocked.Add(pos);
        }

        foreach (var enemy in state.RoamingEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is GridPoint pos)
                blocked.Add(pos);
        }

        return blocked;
    }

    private static void AssertPathStartsEndsAndMovesByOne(
        IReadOnlyList<GridPoint> path,
        GridPoint start,
        GridPoint end)
    {
        Assert.NotEmpty(path);
        Assert.Equal(start, path[0]);
        Assert.Equal(end, path[^1]);

        for (int i = 1; i < path.Count; i++)
            Assert.Equal(1, path[i - 1].ManhattanDistance(path[i]));
    }
}
