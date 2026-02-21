using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Tests for decoration placement determinism, UI panel existence,
/// GridRenderer logic paths, and system integration.
/// </summary>
public class DecorationPlacementTests
{
    // Reproduce the decoration hash logic from GridRenderer
    private static (int chance, int variant) GetDecoHash(int x, int y)
    {
        int hash = (x * 7919 + y * 7907) & 0x7FFFFFFF;
        int chance = hash % 100;
        int variant = hash / 100 % 4;
        return (chance, variant);
    }

    [Fact]
    public void DecorationHash_Deterministic_SameInputSameOutput()
    {
        var (c1, v1) = GetDecoHash(10, 20);
        var (c2, v2) = GetDecoHash(10, 20);
        Assert.Equal(c1, c2);
        Assert.Equal(v1, v2);
    }

    [Fact]
    public void DecorationHash_DifferentPositions_DifferentOutput()
    {
        var (c1, _) = GetDecoHash(0, 0);
        var (c2, _) = GetDecoHash(1, 0);
        var (c3, _) = GetDecoHash(0, 1);
        // Very unlikely all 3 are the same
        Assert.False(c1 == c2 && c2 == c3, "Different positions should produce different hashes");
    }

    [Fact]
    public void DecorationHash_ChanceRange_0To99()
    {
        for (int x = 0; x < 20; x++)
            for (int y = 0; y < 20; y++)
            {
                var (chance, _) = GetDecoHash(x, y);
                Assert.InRange(chance, 0, 99);
            }
    }

    [Fact]
    public void DecorationHash_VariantRange_0To3()
    {
        for (int x = 0; x < 20; x++)
            for (int y = 0; y < 20; y++)
            {
                var (_, variant) = GetDecoHash(x, y);
                Assert.InRange(variant, 0, 3);
            }
    }

    [Fact]
    public void DecorationHash_NegativeCoords_DoesNotCrash()
    {
        var (chance, variant) = GetDecoHash(-5, -10);
        Assert.InRange(chance, 0, 99);
        Assert.InRange(variant, 0, 3);
    }

    [Fact]
    public void DecorationHash_LargeCoords_DoesNotOverflow()
    {
        var (chance, variant) = GetDecoHash(10000, 10000);
        Assert.InRange(chance, 0, 99);
        Assert.InRange(variant, 0, 3);
    }

    [Fact]
    public void ForestDecoration_SomePositionsGetDecorations()
    {
        int decoCount = 0;
        for (int x = 0; x < 50; x++)
            for (int y = 0; y < 50; y++)
            {
                var (chance, _) = GetDecoHash(x, y);
                if (chance < 30) decoCount++; // forest threshold
            }
        Assert.True(decoCount > 0, "Some forest tiles should have decorations");
        Assert.True(decoCount < 2500, "Not all tiles should have decorations");
    }

    [Fact]
    public void PlainsDecoration_LowerChanceThanForest()
    {
        int forestCount = 0, plainsCount = 0;
        for (int x = 0; x < 100; x++)
            for (int y = 0; y < 100; y++)
            {
                var (chance, _) = GetDecoHash(x, y);
                if (chance < 30) forestCount++;  // forest threshold
                if (chance < 15) plainsCount++;  // plains threshold
            }
        Assert.True(plainsCount < forestCount, "Plains should have fewer decorations than forest");
    }

    [Fact]
    public void VariantDistribution_RoughlyUniform()
    {
        int[] counts = new int[4];
        for (int x = 0; x < 100; x++)
            for (int y = 0; y < 100; y++)
            {
                var (_, variant) = GetDecoHash(x, y);
                counts[variant]++;
            }
        // Each variant should get roughly 25% of 10000 samples
        foreach (int c in counts)
            Assert.InRange(c, 1500, 3500);
    }
}

public class UiPanelExistenceTests
{
    [Fact]
    public void DailyChallengesPanel_CanInstantiate()
    {
        // DailyChallengesPanel is a Myra UI component — test that the
        // underlying data model works correctly
        var challenges = DailyChallenges.GetTodaysChallenges(1);
        Assert.Equal(3, challenges.Count);
        foreach (var c in challenges)
        {
            Assert.NotEmpty(c.Id);
            Assert.NotEmpty(c.Name);
            Assert.NotEmpty(c.Description);
            Assert.True(c.Reward > 0);
            Assert.True(c.Target > 0);
        }
    }

    [Fact]
    public void QuestRegistry_AllQuestsHaveValidConditions()
    {
        foreach (var (id, def) in Quests.Registry)
        {
            Assert.NotEmpty(id);
            Assert.NotEmpty(def.Name);
            Assert.NotEmpty(def.Description);
            Assert.NotNull(def.Condition);
            Assert.True(def.Condition.Value > 0, $"Quest {id} has invalid target value");
        }
    }

    [Fact]
    public void QuestRegistry_AllQuestsHaveRewards()
    {
        foreach (var (id, def) in Quests.Registry)
        {
            Assert.NotNull(def.Rewards);
            Assert.True(def.Rewards.Count > 0, $"Quest {id} has no rewards");
        }
    }

    [Fact]
    public void DailyChallenges_ChallengePool_AllHaveUniqueIds()
    {
        var ids = new HashSet<string>();
        foreach (var challenge in DailyChallenges.ChallengePool)
        {
            Assert.True(ids.Add(challenge.Id), $"Duplicate challenge ID: {challenge.Id}");
        }
    }

    [Fact]
    public void DailyChallenges_ChallengePool_AllHavePositiveTargets()
    {
        foreach (var challenge in DailyChallenges.ChallengePool)
        {
            Assert.True(challenge.Target > 0, $"Challenge {challenge.Id} has non-positive target");
            Assert.True(challenge.Reward > 0, $"Challenge {challenge.Id} has non-positive reward");
        }
    }

    [Fact]
    public void DailyChallenges_ChallengePool_CoversAllTypes()
    {
        var types = new HashSet<ChallengeType>();
        foreach (var c in DailyChallenges.ChallengePool)
            types.Add(c.Type);

        Assert.Contains(ChallengeType.DefeatEnemies, types);
        Assert.Contains(ChallengeType.TypeWords, types);
        Assert.Contains(ChallengeType.PerfectAccuracy, types);
        Assert.Contains(ChallengeType.ComboStreak, types);
        Assert.Contains(ChallengeType.SurviveDays, types);
        Assert.Contains(ChallengeType.SpeedRun, types);
        Assert.Contains(ChallengeType.NoDamage, types);
    }

    [Fact]
    public void DailyChallenges_LegacyTemplates_HasMinimum10()
    {
        Assert.True(DailyChallenges.Templates.Count >= 10,
            $"Expected at least 10 legacy templates, got {DailyChallenges.Templates.Count}");
    }

    [Fact]
    public void DailyChallenges_GetChallengeForDay_Deterministic()
    {
        string a = DailyChallenges.GetChallengeForDay(5);
        string b = DailyChallenges.GetChallengeForDay(5);
        Assert.Equal(a, b);
    }

    [Fact]
    public void DailyChallenges_GetChallengeForDay_CyclesThroughAll()
    {
        var seen = new HashSet<string>();
        for (int d = 0; d < DailyChallenges.Templates.Count; d++)
            seen.Add(DailyChallenges.GetChallengeForDay(d));
        Assert.Equal(DailyChallenges.Templates.Count, seen.Count);
    }

    [Fact]
    public void DailyChallenges_CalculateStreakBonus_Tiers()
    {
        Assert.Equal(0, DailyChallenges.CalculateStreakBonus(0));
        Assert.Equal(1, DailyChallenges.CalculateStreakBonus(1));
        Assert.Equal(2, DailyChallenges.CalculateStreakBonus(3));
        Assert.Equal(3, DailyChallenges.CalculateStreakBonus(7));
        Assert.Equal(3, DailyChallenges.CalculateStreakBonus(30));
    }

    [Fact]
    public void DailyChallenges_GetTodayKey_ReturnsDateString()
    {
        string key = DailyChallenges.GetTodayKey();
        Assert.Matches(@"\d{4}-\d{2}-\d{2}", key);
    }
}

public class SimMapTerrainTests
{
    [Theory]
    [InlineData(SimMap.TerrainPlains)]
    [InlineData(SimMap.TerrainForest)]
    [InlineData(SimMap.TerrainMountain)]
    [InlineData(SimMap.TerrainWater)]
    [InlineData(SimMap.TerrainDesert)]
    [InlineData(SimMap.TerrainSnow)]
    public void TerrainConstants_NotEmpty(string terrain)
    {
        Assert.NotEmpty(terrain);
    }

    [Fact]
    public void GetTerrain_ValidPosition_ReturnsTerrain()
    {
        var state = DefaultState.Create("terrain_test", true);
        SimMap.GenerateTerrain(state);

        string terrain = SimMap.GetTerrain(state, state.BasePos);
        Assert.NotEmpty(terrain);
    }

    [Fact]
    public void GetZoneAt_BasePos_ReturnsSafe()
    {
        var state = DefaultState.Create("zone_test", true);
        SimMap.GenerateTerrain(state);

        string zone = SimMap.GetZoneAt(state, state.BasePos);
        Assert.Equal("safe", zone);
    }

    [Fact]
    public void GetZoneName_ReturnsNonEmpty()
    {
        Assert.NotEmpty(SimMap.GetZoneName("safe"));
        Assert.NotEmpty(SimMap.GetZoneName("frontier"));
        Assert.NotEmpty(SimMap.GetZoneName("wilderness"));
        Assert.NotEmpty(SimMap.GetZoneName("depths"));
    }

    [Fact]
    public void InBounds_ValidPosition_True()
    {
        Assert.True(SimMap.InBounds(5, 5, 50, 50));
    }

    [Fact]
    public void InBounds_NegativePosition_False()
    {
        Assert.False(SimMap.InBounds(-1, 0, 50, 50));
        Assert.False(SimMap.InBounds(0, -1, 50, 50));
    }

    [Fact]
    public void InBounds_OutOfRange_False()
    {
        Assert.False(SimMap.InBounds(50, 0, 50, 50));
        Assert.False(SimMap.InBounds(0, 50, 50, 50));
    }

    [Fact]
    public void GenerateTerrain_SetsTerrainForAllTiles()
    {
        var state = DefaultState.Create("pop_test", true);
        SimMap.GenerateTerrain(state);

        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
        foreach (string t in state.Terrain)
            Assert.NotEmpty(t);
    }

    [Fact]
    public void GenerateTerrain_HasMultipleTerrainTypes()
    {
        var state = DefaultState.Create("variety_test", true);
        SimMap.GenerateTerrain(state);

        var types = new HashSet<string>(state.Terrain);
        Assert.True(types.Count >= 3, $"Expected at least 3 terrain types, got {types.Count}");
    }

    [Fact]
    public void GenerateTerrain_DesertAndSnow_PresentInLargeMap()
    {
        var state = DefaultState.Create("biome_test", true);
        SimMap.GenerateTerrain(state);

        var types = new HashSet<string>(state.Terrain);
        // Desert and snow should appear in a sufficiently large map
        // (map is 50x50 with distance-based biome placement)
        Assert.Contains(SimMap.TerrainDesert, types);
        Assert.Contains(SimMap.TerrainSnow, types);
    }
}

public class GridPointExtendedTests
{
    [Fact]
    public void FromIndex_RoundTrips()
    {
        int mapW = 50;
        var point = new GridPoint(7, 13);
        int index = point.Y * mapW + point.X;
        var roundTrip = GridPoint.FromIndex(index, mapW);
        Assert.Equal(point, roundTrip);
    }

    [Fact]
    public void ManhattanDistance_SamePoint_Zero()
    {
        var a = new GridPoint(5, 5);
        Assert.Equal(0, a.ManhattanDistance(a));
    }

    [Fact]
    public void ManhattanDistance_AdjacentPoint_One()
    {
        var a = new GridPoint(5, 5);
        var b = new GridPoint(6, 5);
        Assert.Equal(1, a.ManhattanDistance(b));
    }

    [Fact]
    public void ManhattanDistance_Diagonal_Two()
    {
        var a = new GridPoint(5, 5);
        var b = new GridPoint(6, 6);
        Assert.Equal(2, a.ManhattanDistance(b));
    }

    [Fact]
    public void ManhattanDistance_Symmetric()
    {
        var a = new GridPoint(3, 7);
        var b = new GridPoint(10, 2);
        Assert.Equal(a.ManhattanDistance(b), b.ManhattanDistance(a));
    }

    [Fact]
    public void FromIndex_ZeroIndex_IsOrigin()
    {
        var point = GridPoint.FromIndex(0, 50);
        Assert.Equal(0, point.X);
        Assert.Equal(0, point.Y);
    }

    [Fact]
    public void FromIndex_LastIndex_IsBottomRight()
    {
        var point = GridPoint.FromIndex(49 * 50 + 49, 50);
        Assert.Equal(49, point.X);
        Assert.Equal(49, point.Y);
    }
}
