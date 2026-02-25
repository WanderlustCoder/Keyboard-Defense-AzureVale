using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Stress;

public class WorldSimStressTests
{
    [Fact]
    public void Tick_ThousandSteps_WithAutoDefense_DoesNotThrowAndKeepsStateValid()
    {
        var state = CreateStressState(
            seed: "stress_1000_stability",
            mapW: 72,
            mapH: 72,
            roamingEnemyCount: 96,
            npcCount: 48,
            resourceNodeCount: 120);

        var ex = Record.Exception(() => SimulateTicks(state, tickCount: 1000, autoTriggerWaves: true));

        Assert.Null(ex);
        Assert.InRange(state.TimeOfDay, 0f, 1f);
        Assert.InRange(state.ThreatLevel, 0f, 1f);
        Assert.True(state.Day >= 1);
        Assert.True(state.WavesSurvived >= 1);
        Assert.True(state.Hp > 0);
    }

    [Fact]
    public void Tick_ThousandSteps_CompletesUnderTwoSeconds()
    {
        var state = CreateStressState(
            seed: "stress_perf",
            mapW: 64,
            mapH: 64,
            roamingEnemyCount: 80,
            npcCount: 40,
            resourceNodeCount: 80);

        state.ThreatLevel = 0f;
        state.WaveCooldown = 10_000f;

        var sw = Stopwatch.StartNew();
        var ex = Record.Exception(() => WorldTick.Tick(state, 1000.0));
        sw.Stop();

        Assert.Null(ex);
        Assert.True(sw.Elapsed < TimeSpan.FromSeconds(2),
            $"Expected 1000 world ticks in < 2s, actual: {sw.Elapsed.TotalMilliseconds:F1} ms.");
        Assert.InRange(state.TimeOfDay, 0f, 1f);
    }

    [Fact]
    public void Tick_LargeMapAndDenseEntities_RunsForExtendedSimulationWithoutCorruption()
    {
        var state = CreateStressState(
            seed: "stress_large_dense",
            mapW: 160,
            mapH: 160,
            roamingEnemyCount: 420,
            npcCount: 320,
            resourceNodeCount: 1_200);

        var ex = Record.Exception(() => WorldTick.Tick(state, 250.0));

        Assert.Null(ex);
        Assert.Equal(160, state.MapW);
        Assert.Equal(160, state.MapH);
        Assert.True(state.RoamingEnemies.Count > 0);
        Assert.True(state.Npcs.Count > 0);
        Assert.True(state.ResourceNodes.Count > 0);

        foreach (var enemy in state.RoamingEnemies)
        {
            var pos = Assert.IsType<GridPoint>(enemy["pos"]);
            Assert.True(SimMap.InBounds(pos.X, pos.Y, state.MapW, state.MapH));
        }
    }

    [Fact]
    public void DayNightCycle_RepeatedWaveCompletions_DoNotCorruptState()
    {
        var state = CreateStressState(
            seed: "stress_day_night_cycles",
            mapW: 64,
            mapH: 64,
            roamingEnemyCount: 0,
            npcCount: 0,
            resourceNodeCount: 0);

        int cycles = 30;
        int dayBefore = state.Day;

        for (int i = 0; i < cycles; i++)
        {
            state.ActivityMode = "exploration";
            state.ThreatLevel = 1.0f;
            state.WaveCooldown = 0f;

            WorldTick.Tick(state, WorldTick.WorldTickInterval);
            Assert.Equal("wave_assault", state.ActivityMode);
            Assert.Equal("night", state.Phase);

            state.Enemies.Clear();
            state.NightSpawnRemaining = 0;

            WorldTick.Tick(state, WorldTick.WorldTickInterval);

            Assert.Equal("exploration", state.ActivityMode);
            Assert.Equal("day", state.Phase);
            Assert.Equal(state.ApMax, state.Ap);
            Assert.True(state.WaveCooldown > 0f);
        }

        Assert.Equal(dayBefore + cycles, state.Day);
        Assert.Equal(cycles, state.WavesSurvived);
        Assert.InRange(state.TimeOfDay, 0f, 1f);
    }

    [Fact]
    public void ExtendedPlay_ResourceValuesStayWithinReasonableBounds()
    {
        var state = CreateStressState(
            seed: "stress_resource_bounds",
            mapW: 72,
            mapH: 72,
            roamingEnemyCount: 0,
            npcCount: 0,
            resourceNodeCount: 0);

        SimulateTicks(state, tickCount: 1000, autoTriggerWaves: true);

        Assert.True(state.WavesSurvived >= 10);
        Assert.InRange(state.Resources.GetValueOrDefault("wood", 0), 0, 20_000);
        Assert.InRange(state.Resources.GetValueOrDefault("stone", 0), 0, 20_000);
        Assert.InRange(state.Resources.GetValueOrDefault("food", 0), 0, 20_000);
        Assert.InRange(state.Gold, 0, 100_000);
    }

    [Fact]
    public void Exploration_OverManyTicks_CoversMostOfMap()
    {
        var state = CreateStressState(
            seed: "stress_exploration_coverage",
            mapW: 40,
            mapH: 40,
            roamingEnemyCount: 0,
            npcCount: 0,
            resourceNodeCount: 0,
            discoverAll: false);

        int discoveredBefore = state.Discovered.Count;

        int minX = 1;
        int maxX = state.MapW - 2;
        int minY = 1;
        int maxY = state.MapH - 2;
        int x = minX;
        int y = minY;
        int dir = 1;

        for (int i = 0; i < 1000; i++)
        {
            var pos = new GridPoint(x, y);
            state.PlayerPos = pos;
            state.CursorPos = pos;
            DiscoverAround(state, pos, radius: 3);
            WorldTick.Tick(state, WorldTick.WorldTickInterval);

            x += dir;
            if (x > maxX || x < minX)
            {
                x = Math.Clamp(x, minX, maxX);
                if (y < maxY)
                    y++;
                dir *= -1;
            }
        }

        double explored = SimMap.GetTotalExploration(state);
        Assert.True(state.Discovered.Count > discoveredBefore);
        Assert.True(explored >= 0.75, $"Expected >=75% exploration, got {explored:P1}.");
    }

    [Fact]
    public void DayNightCycle_AfterThousandTicks_TimeOfDayRemainsNormalized()
    {
        var state = CreateStressState(
            seed: "stress_time_wrap",
            mapW: 32,
            mapH: 32,
            roamingEnemyCount: 0,
            npcCount: 0,
            resourceNodeCount: 0);

        state.ActivityMode = "idle";
        float startTime = state.TimeOfDay;

        WorldTick.Tick(state, 1000.0);

        Assert.InRange(state.TimeOfDay, 0f, 1f);
        Assert.InRange(state.WorldTickAccum, 0f, 1f);
        Assert.InRange(Math.Abs(state.TimeOfDay - startTime), 0f, 0.001f);
    }

    private static void SimulateTicks(GameState state, int tickCount, bool autoTriggerWaves)
    {
        for (int i = 0; i < tickCount; i++)
        {
            if (autoTriggerWaves &&
                state.ActivityMode == "exploration" &&
                state.WaveCooldown <= 0f)
            {
                state.ThreatLevel = 1.0f;
            }

            WorldTick.Tick(state, WorldTick.WorldTickInterval);

            if (state.ActivityMode == "wave_assault")
                state.Enemies.Clear();
        }
    }

    private static GameState CreateStressState(
        string seed,
        int mapW,
        int mapH,
        int roamingEnemyCount,
        int npcCount,
        int resourceNodeCount,
        bool discoverAll = true)
    {
        var state = new GameState
        {
            Day = 3,
            MapW = mapW,
            MapH = mapH,
            BasePos = new GridPoint(mapW / 2, mapH / 2),
            PlayerPos = new GridPoint(mapW / 2, mapH / 2),
            CursorPos = new GridPoint(mapW / 2, mapH / 2),
            ActivityMode = "exploration",
            Phase = "day",
            ThreatLevel = 0.15f,
            TimeOfDay = 0.25f,
            WorldTickAccum = 0f,
            WaveCooldown = 0f,
            LessonId = "full_alpha",
        };

        SimRng.SeedState(state, seed);

        state.Terrain.Clear();
        for (int i = 0; i < mapW * mapH; i++)
            state.Terrain.Add(SimMap.Plains);

        state.Discovered.Clear();
        if (discoverAll)
        {
            for (int i = 0; i < mapW * mapH; i++)
                state.Discovered.Add(i);
        }
        else
        {
            DiscoverAround(state, state.BasePos, radius: 2);
        }

        state.RoamingEnemies.Clear();
        state.Npcs.Clear();
        state.ResourceNodes.Clear();
        state.Enemies.Clear();
        state.EncounterEnemies.Clear();
        state.ActivePois.Clear();

        PopulateRoamingEnemies(state, roamingEnemyCount);
        PopulateNpcs(state, npcCount);
        PopulateResourceNodes(state, resourceNodeCount);

        return state;
    }

    private static void PopulateRoamingEnemies(GameState state, int count)
    {
        int minDistance = Math.Max(8, Math.Min(state.MapW, state.MapH) / 4);
        for (int i = 0; i < count; i++)
        {
            var pos = PositionFarFromBase(state, i, minDistance);
            int tier = i % 4;

            state.RoamingEnemies.Add(new Dictionary<string, object>
            {
                ["id"] = state.EnemyNextId++,
                ["kind"] = tier switch
                {
                    0 => "scout",
                    1 => "raider",
                    2 => "armored",
                    _ => "berserker",
                },
                ["pos"] = pos,
                ["hp"] = 3 + tier * 2,
                ["tier"] = tier,
                ["damage"] = 1 + tier,
                ["speed"] = 1,
                ["zone"] = SimMap.GetZoneAt(state, pos),
                ["patrol_origin"] = pos,
            });
        }
    }

    private static void PopulateNpcs(GameState state, int count)
    {
        int minDistance = Math.Max(8, Math.Min(state.MapW, state.MapH) / 4);
        for (int i = 0; i < count; i++)
        {
            var pos = PositionFarFromBase(state, i + 5_000, minDistance);
            string type = (i % 3) switch
            {
                0 => "trainer",
                1 => "merchant",
                _ => "quest_giver",
            };

            state.Npcs.Add(new Dictionary<string, object>
            {
                ["type"] = type,
                ["name"] = $"npc_{i}",
                ["pos"] = pos,
            });
        }
    }

    private static void PopulateResourceNodes(GameState state, int count)
    {
        int minDistance = Math.Max(8, Math.Min(state.MapW, state.MapH) / 5);
        int attempts = 0;
        int i = 0;

        while (state.ResourceNodes.Count < count && attempts < count * 6)
        {
            var pos = PositionFarFromBase(state, i + 10_000, minDistance);
            int idx = SimMap.Idx(pos.X, pos.Y, state.MapW);

            if (!state.ResourceNodes.ContainsKey(idx))
            {
                state.ResourceNodes[idx] = new Dictionary<string, object>
                {
                    ["type"] = (i % 4) switch
                    {
                        0 => "wood_grove",
                        1 => "stone_quarry",
                        2 => "food_garden",
                        _ => "gold_vein",
                    },
                    ["pos"] = pos,
                    ["zone"] = SimMap.GetZoneAt(state, pos),
                    ["cooldown"] = 0,
                };
            }

            i++;
            attempts++;
        }
    }

    private static GridPoint PositionFarFromBase(GameState state, int seedIndex, int minDistance)
    {
        int x = Math.Abs((seedIndex * 37 + 11) % state.MapW);
        int y = Math.Abs((seedIndex * 53 + 17) % state.MapH);
        var pos = new GridPoint(x, y);

        for (int i = 0; i < 12 && ManhattanDistance(pos, state.BasePos) < minDistance; i++)
        {
            x = (x + (state.MapW / 3) + i + 1) % state.MapW;
            y = (y + (state.MapH / 3) + i + 1) % state.MapH;
            pos = new GridPoint(x, y);
        }

        return pos;
    }

    private static void DiscoverAround(GameState state, GridPoint center, int radius)
    {
        for (int dy = -radius; dy <= radius; dy++)
        {
            for (int dx = -radius; dx <= radius; dx++)
            {
                int x = center.X + dx;
                int y = center.Y + dy;
                if (!SimMap.InBounds(x, y, state.MapW, state.MapH))
                    continue;

                state.Discovered.Add(SimMap.Idx(x, y, state.MapW));
            }
        }
    }

    private static int ManhattanDistance(GridPoint a, GridPoint b)
        => Math.Abs(a.X - b.X) + Math.Abs(a.Y - b.Y);
}
