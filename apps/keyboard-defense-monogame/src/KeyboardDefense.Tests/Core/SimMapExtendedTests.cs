using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for SimMap — terrain constants, zone boundary edge cases,
/// Idx/PosFromIndex round-trips, Neighbors4 corners/edges, IsBuildable/IsPassable
/// terrain type coverage, distance calculations, and zone data accessors.
/// </summary>
public class SimMapExtendedTests
{
    // =========================================================================
    // Terrain constants
    // =========================================================================

    [Fact]
    public void TerrainConstants_AreExpected()
    {
        Assert.Equal("plains", SimMap.Plains);
        Assert.Equal("forest", SimMap.Forest);
        Assert.Equal("mountain", SimMap.Mountain);
        Assert.Equal("water", SimMap.Water);
        Assert.Equal("desert", SimMap.Desert);
        Assert.Equal("snow", SimMap.Snow);
        Assert.Equal("road", SimMap.Road);
    }

    [Fact]
    public void TerrainAliases_MatchConstants()
    {
        Assert.Equal(SimMap.Plains, SimMap.TerrainPlains);
        Assert.Equal(SimMap.Forest, SimMap.TerrainForest);
        Assert.Equal(SimMap.Mountain, SimMap.TerrainMountain);
        Assert.Equal(SimMap.Water, SimMap.TerrainWater);
        Assert.Equal(SimMap.Desert, SimMap.TerrainDesert);
        Assert.Equal(SimMap.Snow, SimMap.TerrainSnow);
        Assert.Equal(SimMap.Road, SimMap.TerrainRoad);
    }

    // =========================================================================
    // Zone constants
    // =========================================================================

    [Fact]
    public void ZoneConstants_AreExpected()
    {
        Assert.Equal("safe", SimMap.ZoneSafe);
        Assert.Equal("frontier", SimMap.ZoneFrontier);
        Assert.Equal("wilderness", SimMap.ZoneWilderness);
        Assert.Equal("depths", SimMap.ZoneDepths);
    }

    [Fact]
    public void ZoneRadii_FormAscendingOrder()
    {
        Assert.True(SimMap.ZoneSafeRadius < SimMap.ZoneFrontierRadius);
        Assert.True(SimMap.ZoneFrontierRadius < SimMap.ZoneWildernessRadius);
    }

    // =========================================================================
    // Idx / PosFromIndex — round-trips
    // =========================================================================

    [Theory]
    [InlineData(0, 0, 10, 0)]
    [InlineData(9, 0, 10, 9)]
    [InlineData(0, 1, 10, 10)]
    [InlineData(5, 3, 10, 35)]
    [InlineData(0, 0, 1, 0)]
    public void Idx_ReturnsExpectedIndex(int x, int y, int w, int expected)
    {
        Assert.Equal(expected, SimMap.Idx(x, y, w));
    }

    [Theory]
    [InlineData(0, 10, 0, 0)]
    [InlineData(9, 10, 9, 0)]
    [InlineData(10, 10, 0, 1)]
    [InlineData(35, 10, 5, 3)]
    public void PosFromIndex_ReturnsExpectedCoord(int index, int w, int expectedX, int expectedY)
    {
        var pos = SimMap.PosFromIndex(index, w);
        Assert.Equal(expectedX, pos.X);
        Assert.Equal(expectedY, pos.Y);
    }

    [Fact]
    public void Idx_PosFromIndex_RoundTrip_AllPositions()
    {
        int w = 7, h = 5;
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                int idx = SimMap.Idx(x, y, w);
                var pos = SimMap.PosFromIndex(idx, w);
                Assert.Equal(x, pos.X);
                Assert.Equal(y, pos.Y);
            }
        }
    }

    // =========================================================================
    // InBounds — comprehensive
    // =========================================================================

    [Theory]
    [InlineData(0, 0, true)]
    [InlineData(4, 4, true)]
    [InlineData(-1, 0, false)]
    [InlineData(0, -1, false)]
    [InlineData(5, 0, false)]
    [InlineData(0, 5, false)]
    [InlineData(5, 5, false)]
    [InlineData(-1, -1, false)]
    public void InBounds_5x5_ReturnsExpected(int x, int y, bool expected)
    {
        Assert.Equal(expected, SimMap.InBounds(x, y, 5, 5));
    }

    [Fact]
    public void InBounds_ZeroDimension_AlwaysFalse()
    {
        Assert.False(SimMap.InBounds(0, 0, 0, 0));
        Assert.False(SimMap.InBounds(0, 0, 0, 5));
        Assert.False(SimMap.InBounds(0, 0, 5, 0));
    }

    // =========================================================================
    // Neighbors4 — edges and corners
    // =========================================================================

    [Fact]
    public void Neighbors4_TopLeftCorner_ReturnsTwoNeighbors()
    {
        var neighbors = SimMap.Neighbors4(new GridPoint(0, 0), 5, 5);
        Assert.Equal(2, neighbors.Count);
        Assert.Contains(new GridPoint(1, 0), neighbors);
        Assert.Contains(new GridPoint(0, 1), neighbors);
    }

    [Fact]
    public void Neighbors4_TopRightCorner_ReturnsTwoNeighbors()
    {
        var neighbors = SimMap.Neighbors4(new GridPoint(4, 0), 5, 5);
        Assert.Equal(2, neighbors.Count);
        Assert.Contains(new GridPoint(3, 0), neighbors);
        Assert.Contains(new GridPoint(4, 1), neighbors);
    }

    [Fact]
    public void Neighbors4_BottomLeftCorner_ReturnsTwoNeighbors()
    {
        var neighbors = SimMap.Neighbors4(new GridPoint(0, 4), 5, 5);
        Assert.Equal(2, neighbors.Count);
        Assert.Contains(new GridPoint(1, 4), neighbors);
        Assert.Contains(new GridPoint(0, 3), neighbors);
    }

    [Fact]
    public void Neighbors4_BottomRightCorner_ReturnsTwoNeighbors()
    {
        var neighbors = SimMap.Neighbors4(new GridPoint(4, 4), 5, 5);
        Assert.Equal(2, neighbors.Count);
        Assert.Contains(new GridPoint(3, 4), neighbors);
        Assert.Contains(new GridPoint(4, 3), neighbors);
    }

    [Fact]
    public void Neighbors4_EdgeTile_ReturnsThreeNeighbors()
    {
        var neighbors = SimMap.Neighbors4(new GridPoint(2, 0), 5, 5);
        Assert.Equal(3, neighbors.Count);
    }

    [Fact]
    public void Neighbors4_CenterTile_ReturnsFourNeighbors()
    {
        var neighbors = SimMap.Neighbors4(new GridPoint(2, 2), 5, 5);
        Assert.Equal(4, neighbors.Count);
    }

    // =========================================================================
    // IsBuildable — terrain type coverage
    // =========================================================================

    [Theory]
    [InlineData("plains", true)]
    [InlineData("forest", true)]
    [InlineData("desert", true)]
    [InlineData("snow", true)]
    [InlineData("road", true)]
    [InlineData("water", false)]
    [InlineData("mountain", false)]
    public void IsBuildable_TerrainType_ReturnsExpected(string terrain, bool expected)
    {
        var state = CreateState(5, 5);
        FillTerrain(state, terrain);
        var target = new GridPoint(1, 1);
        int idx = SimMap.Idx(target.X, target.Y, state.MapW);
        state.Discovered.Add(idx);

        Assert.Equal(expected, SimMap.IsBuildable(state, target));
    }

    [Fact]
    public void IsBuildable_BasePos_ReturnsFalse()
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Plains);
        int baseIdx = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        state.Discovered.Add(baseIdx);

        Assert.False(SimMap.IsBuildable(state, state.BasePos));
    }

    [Fact]
    public void IsBuildable_OutOfBounds_ReturnsFalse()
    {
        var state = CreateState(5, 5);
        Assert.False(SimMap.IsBuildable(state, new GridPoint(-1, -1)));
        Assert.False(SimMap.IsBuildable(state, new GridPoint(5, 5)));
    }

    // =========================================================================
    // IsPassable — terrain and structure coverage
    // =========================================================================

    [Theory]
    [InlineData("plains", true)]
    [InlineData("forest", true)]
    [InlineData("desert", true)]
    [InlineData("snow", true)]
    [InlineData("road", true)]
    [InlineData("mountain", true)]  // mountain is passable
    [InlineData("water", false)]
    public void IsPassable_TerrainType_ReturnsExpected(string terrain, bool expected)
    {
        var state = CreateState(5, 5);
        FillTerrain(state, terrain);

        Assert.Equal(expected, SimMap.IsPassable(state, new GridPoint(1, 1)));
    }

    [Theory]
    [InlineData("farm", true)]
    [InlineData("market", true)]
    [InlineData("barracks", true)]
    [InlineData("wall", false)]
    [InlineData("tower", false)]
    public void IsPassable_StructureType_ReturnsExpected(string structure, bool expected)
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Plains);
        var target = new GridPoint(1, 1);
        state.Structures[SimMap.Idx(target.X, target.Y, state.MapW)] = structure;

        Assert.Equal(expected, SimMap.IsPassable(state, target));
    }

    // =========================================================================
    // GetTerrain — edge cases
    // =========================================================================

    [Fact]
    public void GetTerrain_OutOfBounds_ReturnsEmpty()
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Plains);

        Assert.Equal("", SimMap.GetTerrain(state, new GridPoint(-1, 0)));
        Assert.Equal("", SimMap.GetTerrain(state, new GridPoint(5, 0)));
    }

    [Fact]
    public void GetTerrain_ValidPosition_ReturnsTerrain()
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Forest);

        Assert.Equal(SimMap.Forest, SimMap.GetTerrain(state, new GridPoint(2, 2)));
    }

    // =========================================================================
    // Distance functions
    // =========================================================================

    [Fact]
    public void DistanceToCastle_AtBase_ReturnsZero()
    {
        var state = CreateState(10, 10);
        Assert.Equal(0, SimMap.DistanceToCastle(state, state.BasePos));
    }

    [Fact]
    public void DistanceToCastle_Manhattan_ReturnsCorrect()
    {
        var state = CreateState(10, 10);
        // Base is at (5, 5)
        var pos = new GridPoint(8, 3);
        Assert.Equal(5, SimMap.DistanceToCastle(state, pos)); // |8-5| + |3-5| = 3+2
    }

    [Fact]
    public void ChebyshevDistanceToCastle_AtBase_ReturnsZero()
    {
        var state = CreateState(10, 10);
        Assert.Equal(0, SimMap.ChebyshevDistanceToCastle(state, state.BasePos));
    }

    [Fact]
    public void ChebyshevDistanceToCastle_Diagonal_ReturnsMax()
    {
        var state = CreateState(10, 10);
        var pos = new GridPoint(state.BasePos.X + 3, state.BasePos.Y + 4);
        Assert.Equal(4, SimMap.ChebyshevDistanceToCastle(state, pos)); // max(3, 4)
    }

    // =========================================================================
    // Zone data
    // =========================================================================

    [Fact]
    public void ZoneDataMap_HasFourEntries()
    {
        Assert.Equal(4, SimMap.ZoneDataMap.Count);
    }

    [Theory]
    [InlineData("safe", "Safe Zone", 0.5, 0.8, 1)]
    [InlineData("frontier", "Frontier", 1.0, 1.0, 2)]
    [InlineData("wilderness", "Wilderness", 1.5, 1.5, 3)]
    [InlineData("depths", "The Depths", 2.0, 2.0, 4)]
    public void ZoneDataMap_HasExpectedValues(
        string zoneId, string name, double threat, double loot, int tierMax)
    {
        var data = SimMap.ZoneDataMap[zoneId];
        Assert.Equal(name, data.Name);
        Assert.Equal(threat, data.ThreatMultiplier, 3);
        Assert.Equal(loot, data.LootMultiplier, 3);
        Assert.Equal(tierMax, data.EnemyTierMax);
    }

    [Fact]
    public void GetZoneData_UnknownZone_ReturnsSafe()
    {
        var unknown = SimMap.GetZoneData("nonexistent");
        var safe = SimMap.GetZoneData(SimMap.ZoneSafe);
        Assert.Equal(safe, unknown);
    }

    [Fact]
    public void GetZoneName_AllZones_NonEmpty()
    {
        foreach (var zoneId in SimMap.GetAllZones())
        {
            Assert.False(string.IsNullOrEmpty(SimMap.GetZoneName(zoneId)));
        }
    }

    [Fact]
    public void GetZoneThreatMultiplier_IncreasesByZone()
    {
        var zones = SimMap.GetAllZones();
        for (int i = 1; i < zones.Length; i++)
        {
            Assert.True(
                SimMap.GetZoneThreatMultiplier(zones[i]) > SimMap.GetZoneThreatMultiplier(zones[i - 1]),
                $"Zone {zones[i]} threat should exceed {zones[i - 1]}");
        }
    }

    [Fact]
    public void GetZoneLootMultiplier_IncreasesByZone()
    {
        var zones = SimMap.GetAllZones();
        for (int i = 1; i < zones.Length; i++)
        {
            Assert.True(
                SimMap.GetZoneLootMultiplier(zones[i]) > SimMap.GetZoneLootMultiplier(zones[i - 1]),
                $"Zone {zones[i]} loot should exceed {zones[i - 1]}");
        }
    }

    [Fact]
    public void GetZoneEnemyTierMax_IncreasesByZone()
    {
        var zones = SimMap.GetAllZones();
        for (int i = 1; i < zones.Length; i++)
        {
            Assert.True(
                SimMap.GetZoneEnemyTierMax(zones[i]) > SimMap.GetZoneEnemyTierMax(zones[i - 1]),
                $"Zone {zones[i]} tier max should exceed {zones[i - 1]}");
        }
    }

    // =========================================================================
    // GetAllZones
    // =========================================================================

    [Fact]
    public void GetAllZones_ReturnsFourZonesInOrder()
    {
        var zones = SimMap.GetAllZones();
        Assert.Equal(4, zones.Length);
        Assert.Equal(SimMap.ZoneSafe, zones[0]);
        Assert.Equal(SimMap.ZoneFrontier, zones[1]);
        Assert.Equal(SimMap.ZoneWilderness, zones[2]);
        Assert.Equal(SimMap.ZoneDepths, zones[3]);
    }

    // =========================================================================
    // GetZoneAt — base is always safe
    // =========================================================================

    [Fact]
    public void GetZoneAt_AtBase_IsSafe()
    {
        var state = CreateState(32, 32);
        FillTerrain(state, SimMap.Plains);
        Assert.Equal(SimMap.ZoneSafe, SimMap.GetZoneAt(state, state.BasePos));
    }

    [Fact]
    public void GetZoneAt_FarCorner_IsDepths()
    {
        var state = CreateState(32, 32);
        FillTerrain(state, SimMap.Plains);
        Assert.Equal(SimMap.ZoneDepths, SimMap.GetZoneAt(state, new GridPoint(0, 0)));
    }

    // =========================================================================
    // GetTotalExploration — edge cases
    // =========================================================================

    [Fact]
    public void GetTotalExploration_FullyDiscovered_ReturnsOne()
    {
        var state = CreateState(4, 4);
        state.Discovered.Clear();
        for (int i = 0; i < 16; i++)
            state.Discovered.Add(i);

        Assert.Equal(1.0, SimMap.GetTotalExploration(state), 3);
    }

    [Fact]
    public void GetTotalExploration_NoneDiscovered_ReturnsZero()
    {
        var state = CreateState(4, 4);
        state.Discovered.Clear();

        Assert.Equal(0.0, SimMap.GetTotalExploration(state), 3);
    }

    // =========================================================================
    // ResetBiomeGenerator — no-op, no crash
    // =========================================================================

    [Fact]
    public void ResetBiomeGenerator_DoesNotThrow()
    {
        SimMap.ResetBiomeGenerator(); // should be safe no-op
    }

    // =========================================================================
    // ZoneData record
    // =========================================================================

    [Fact]
    public void ZoneData_IsRecord_WithExpectedFields()
    {
        var data = new ZoneData("Test", "Desc", 1.5, 2.0, 3, 1.25);
        Assert.Equal("Test", data.Name);
        Assert.Equal("Desc", data.Description);
        Assert.Equal(1.5, data.ThreatMultiplier);
        Assert.Equal(2.0, data.LootMultiplier);
        Assert.Equal(3, data.EnemyTierMax);
        Assert.Equal(1.25, data.ResourceQuality);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateState(int w, int h)
    {
        var state = new GameState
        {
            MapW = w,
            MapH = h,
        };
        state.BasePos = w > 0 && h > 0 ? new GridPoint(w / 2, h / 2) : GridPoint.Zero;
        state.PlayerPos = state.BasePos;
        state.Terrain.Clear();
        for (int i = 0; i < w * h; i++)
            state.Terrain.Add("");
        state.Discovered.Clear();
        if (w > 0 && h > 0)
            state.Discovered.Add(SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW));
        state.Structures.Clear();
        return state;
    }

    private static void FillTerrain(GameState state, string terrain)
    {
        state.Terrain.Clear();
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add(terrain);
    }
}
