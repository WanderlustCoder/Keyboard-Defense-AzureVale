using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Stress;

public class PerformanceTests
{
    [Fact]
    public void DefaultState_Create_CompletesUnderHundredMilliseconds()
    {
        _ = DefaultState.Create("perf_default_state_warmup");

        var stopwatch = Stopwatch.StartNew();
        var state = DefaultState.Create("perf_default_state");
        stopwatch.Stop();

        Assert.Equal(32, state.MapW);
        Assert.Equal(32, state.MapH);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(100),
            $"DefaultState.Create exceeded 100ms: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void DefaultState_CreateWithStartingTowers_CompletesUnderHundredMilliseconds()
    {
        _ = DefaultState.Create("perf_default_state_towers_warmup", placeStartingTowers: true);

        var stopwatch = Stopwatch.StartNew();
        var state = DefaultState.Create("perf_default_state_towers", placeStartingTowers: true);
        stopwatch.Stop();

        Assert.True(state.Structures.Count >= 2);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(100),
            $"DefaultState.Create (starting towers) exceeded 100ms: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void SimTick_AdvanceDay_OneHundredConsecutiveDays_CompletesUnderTwoSeconds()
    {
        var warmupState = DefaultState.Create("perf_simtick_warmup");
        _ = SimTick.AdvanceDay(warmupState);

        var state = DefaultState.Create("perf_simtick");
        int startDay = state.Day;

        var stopwatch = Stopwatch.StartNew();
        for (int i = 0; i < 100; i++)
            _ = SimTick.AdvanceDay(state);
        stopwatch.Stop();

        Assert.Equal(startDay + 100, state.Day);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromSeconds(2),
            $"100 consecutive SimTick.AdvanceDay calls exceeded 2s: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void SimMap_ComputeDistToBase_OnThirtyTwoByThirtyTwoMap_CompletesUnderFiftyMilliseconds()
    {
        var warmupState = DefaultState.Create("perf_pathfinding_warmup");
        _ = SimMap.ComputeDistToBase(warmupState);

        var state = DefaultState.Create("perf_pathfinding");

        var stopwatch = Stopwatch.StartNew();
        int[] distances = SimMap.ComputeDistToBase(state);
        stopwatch.Stop();

        int baseIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        Assert.Equal(32 * 32, distances.Length);
        Assert.Equal(0, distances[baseIndex]);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(50),
            $"SimMap pathfinding (ComputeDistToBase) exceeded 50ms: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void SimMap_PathOpenToBase_OnThirtyTwoByThirtyTwoMap_CompletesUnderFiftyMilliseconds()
    {
        var state = DefaultState.Create("perf_pathopen_setup");
        FillMapWithPassableTerrain(state);

        _ = SimMap.PathOpenToBase(state);

        var stopwatch = Stopwatch.StartNew();
        bool isPathOpen = SimMap.PathOpenToBase(state);
        stopwatch.Stop();

        Assert.True(isPathOpen);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(50),
            $"SimMap.PathOpenToBase exceeded 50ms: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void SimRng_RollRange_TenMillionRolls_CompletesUnderOneSecond()
    {
        var state = DefaultState.Create("perf_rng");
        for (int i = 0; i < 10_000; i++)
            _ = SimRng.RollRange(state, 0, 100);

        long checksum = 0;
        const int rollCount = 10_000_000;

        var stopwatch = Stopwatch.StartNew();
        for (int i = 0; i < rollCount; i++)
            checksum += SimRng.RollRange(state, 0, 100);
        stopwatch.Stop();

        Assert.True(checksum > 0);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromSeconds(1),
            $"SimRng 10M rolls exceeded 1s: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void SaveManager_StateToJson_WithHundredEnemies_CompletesUnderFiveHundredMilliseconds()
    {
        var state = DefaultState.Create("perf_serialize");
        PopulateWaveEnemies(state, 100);

        _ = SaveManager.StateToJson(DefaultState.Create("perf_serialize_warmup"));

        var stopwatch = Stopwatch.StartNew();
        string json = SaveManager.StateToJson(state);
        stopwatch.Stop();

        Assert.False(string.IsNullOrWhiteSpace(json));
        Assert.Contains("\"enemies\"", json, StringComparison.Ordinal);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(500),
            $"GameState serialization with 100 enemies exceeded 500ms: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    [Fact]
    public void WorldEntities_GetEntitiesNear_WithFiftyEntitiesInRange_CompletesUnderTenMilliseconds()
    {
        var state = DefaultState.Create("perf_entities_lookup");
        SeedEntitiesNearPlayer(state, count: 50, radius: 6);

        _ = WorldEntities.GetEntitiesNear(state, state.PlayerPos, radius: 6);

        var stopwatch = Stopwatch.StartNew();
        var entities = WorldEntities.GetEntitiesNear(state, state.PlayerPos, radius: 6);
        stopwatch.Stop();

        Assert.Equal(50, entities.Count);
        Assert.True(
            stopwatch.Elapsed < TimeSpan.FromMilliseconds(10),
            $"WorldEntities lookup for 50 nearby entities exceeded 10ms: {stopwatch.Elapsed.TotalMilliseconds:F2}ms.");
    }

    private static void PopulateWaveEnemies(GameState state, int count)
    {
        state.Enemies.Clear();
        for (int i = 0; i < count; i++)
        {
            state.Enemies.Add(new Dictionary<string, object>
            {
                ["id"] = i + 1,
                ["kind"] = "raider",
                ["word"] = $"enemy_{i:D3}",
                ["hp"] = 10,
                ["max_hp"] = 10,
                ["damage"] = 2,
                ["speed"] = 1,
                ["dist"] = 8,
                ["gold"] = 1,
            });
        }

        state.NightWaveTotal = count;
        state.NightSpawnRemaining = count;
    }

    private static void FillMapWithPassableTerrain(GameState state)
    {
        state.Structures.Clear();
        state.Terrain.Clear();
        int totalTiles = state.MapW * state.MapH;
        for (int i = 0; i < totalTiles; i++)
            state.Terrain.Add(SimMap.TerrainPlains);
    }

    private static void SeedEntitiesNearPlayer(GameState state, int count, int radius)
    {
        state.RoamingEnemies.Clear();
        state.Npcs.Clear();
        state.ResourceNodes.Clear();

        var positions = CollectPositionsAround(state, state.PlayerPos, radius, count);
        Assert.Equal(count, positions.Count);

        for (int i = 0; i < count; i++)
        {
            GridPoint pos = positions[i];
            if (i < 20)
            {
                state.RoamingEnemies.Add(new Dictionary<string, object>
                {
                    ["id"] = 1000 + i,
                    ["kind"] = "scout",
                    ["pos"] = pos,
                    ["hp"] = 3,
                    ["tier"] = 0,
                });
            }
            else if (i < 40)
            {
                state.Npcs.Add(new Dictionary<string, object>
                {
                    ["type"] = "merchant",
                    ["name"] = $"npc_{i:D2}",
                    ["pos"] = pos,
                });
            }
            else
            {
                int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
                state.ResourceNodes[index] = new Dictionary<string, object>
                {
                    ["type"] = "wood_grove",
                    ["pos"] = pos,
                    ["cooldown"] = 0,
                };
            }
        }
    }

    private static List<GridPoint> CollectPositionsAround(GameState state, GridPoint center, int radius, int targetCount)
    {
        var positions = new List<GridPoint>(targetCount);

        for (int dy = -radius; dy <= radius && positions.Count < targetCount; dy++)
        {
            for (int dx = -radius; dx <= radius && positions.Count < targetCount; dx++)
            {
                if (dx == 0 && dy == 0)
                    continue;

                int x = center.X + dx;
                int y = center.Y + dy;
                if (!SimMap.InBounds(x, y, state.MapW, state.MapH))
                    continue;
                if (Math.Abs(dx) + Math.Abs(dy) > radius)
                    continue;

                positions.Add(new GridPoint(x, y));
            }
        }

        return positions;
    }
}
