using KeyboardDefense.Core;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class SimMapTests
{
    private static GameState CreateState(int width = 8, int height = 8, string seed = "simmap-tests")
    {
        var state = new GameState
        {
            MapW = width,
            MapH = height,
        };

        state.BasePos = width > 0 && height > 0 ? new GridPoint(width / 2, height / 2) : GridPoint.Zero;
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;

        state.Terrain.Clear();
        for (int i = 0; i < width * height; i++)
            state.Terrain.Add("");

        state.Discovered.Clear();
        if (width > 0 && height > 0)
            state.Discovered.Add(SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW));

        state.Structures.Clear();
        SimRng.SeedState(state, seed);
        return state;
    }

    private static void FillTerrain(GameState state, string terrain)
    {
        state.Terrain.Clear();
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add(terrain);
    }

    [Fact]
    public void IdxAndPosFromIndex_RoundTripCoordinates()
    {
        int index = SimMap.Idx(3, 4, 10);
        var pos = SimMap.PosFromIndex(index, 10);

        Assert.Equal(43, index);
        Assert.Equal(new GridPoint(3, 4), pos);
    }

    [Fact]
    public void InBounds_ReturnsExpectedForEdgesAndOutOfRange()
    {
        Assert.True(SimMap.InBounds(0, 0, 10, 5));
        Assert.True(SimMap.InBounds(9, 4, 10, 5));

        Assert.False(SimMap.InBounds(-1, 0, 10, 5));
        Assert.False(SimMap.InBounds(0, -1, 10, 5));
        Assert.False(SimMap.InBounds(10, 0, 10, 5));
        Assert.False(SimMap.InBounds(0, 5, 10, 5));
    }

    [Fact]
    public void Neighbors4_ReturnsOnlyOrthogonalInBoundsNeighbors()
    {
        var centerNeighbors = SimMap.Neighbors4(new GridPoint(2, 2), 5, 5);
        Assert.Equal(4, centerNeighbors.Count);
        Assert.Contains(new GridPoint(3, 2), centerNeighbors);
        Assert.Contains(new GridPoint(1, 2), centerNeighbors);
        Assert.Contains(new GridPoint(2, 3), centerNeighbors);
        Assert.Contains(new GridPoint(2, 1), centerNeighbors);

        var cornerNeighbors = SimMap.Neighbors4(new GridPoint(0, 0), 5, 5);
        Assert.Equal(2, cornerNeighbors.Count);
        Assert.Contains(new GridPoint(1, 0), cornerNeighbors);
        Assert.Contains(new GridPoint(0, 1), cornerNeighbors);
    }

    [Fact]
    public void GetTerrain_ResizesTerrainStorageAndHandlesOutOfBounds()
    {
        var state = CreateState(4, 3);
        state.Terrain.Clear();
        state.Terrain.Add(SimMap.Forest); // intentionally wrong size

        string inBounds = SimMap.GetTerrain(state, new GridPoint(1, 1));
        Assert.Equal("", inBounds);
        Assert.Equal(12, state.Terrain.Count);

        int index = SimMap.Idx(1, 1, state.MapW);
        state.Terrain[index] = SimMap.Forest;
        Assert.Equal(SimMap.Forest, SimMap.GetTerrain(state, new GridPoint(1, 1)));
        Assert.Equal("", SimMap.GetTerrain(state, new GridPoint(-1, 1)));
    }

    [Fact]
    public void IsBuildable_RequiresDiscoveredLandWithoutStructures()
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Plains);
        var target = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);

        Assert.False(SimMap.IsBuildable(state, target)); // not discovered

        state.Discovered.Add(targetIndex);
        Assert.True(SimMap.IsBuildable(state, target));

        state.Structures[targetIndex] = "farm";
        Assert.False(SimMap.IsBuildable(state, target));

        state.Structures.Remove(targetIndex);
        state.Terrain[targetIndex] = SimMap.Water;
        Assert.False(SimMap.IsBuildable(state, target));

        Assert.False(SimMap.IsBuildable(state, state.BasePos));
        Assert.False(SimMap.IsBuildable(state, new GridPoint(-1, 0)));
    }

    [Fact]
    public void IsPassable_BlocksWaterWallsTowersAndOutOfBounds()
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Plains);
        var target = new GridPoint(1, 1);
        int targetIndex = SimMap.Idx(target.X, target.Y, state.MapW);

        Assert.True(SimMap.IsPassable(state, target));

        state.Structures[targetIndex] = "farm";
        Assert.True(SimMap.IsPassable(state, target));

        state.Structures[targetIndex] = "wall";
        Assert.False(SimMap.IsPassable(state, target));

        state.Structures[targetIndex] = "tower";
        Assert.False(SimMap.IsPassable(state, target));

        state.Structures.Remove(targetIndex);
        state.Terrain[targetIndex] = SimMap.Water;
        Assert.False(SimMap.IsPassable(state, target));

        Assert.False(SimMap.IsPassable(state, new GridPoint(-1, 1)));
    }

    [Fact]
    public void DistanceAndZoneAt_ReturnExpectedValues()
    {
        var state = CreateState(32, 32);
        FillTerrain(state, SimMap.Plains);

        var pos = new GridPoint(state.BasePos.X + 3, state.BasePos.Y + 4);
        Assert.Equal(7, SimMap.DistanceToCastle(state, pos));
        Assert.Equal(4, SimMap.ChebyshevDistanceToCastle(state, pos));

        Assert.Equal(SimMap.ZoneSafe, SimMap.GetZoneAt(state, state.BasePos));
        Assert.Equal(SimMap.ZoneFrontier, SimMap.GetZoneAt(state, new GridPoint(state.BasePos.X + 6, state.BasePos.Y)));
        Assert.Equal(SimMap.ZoneWilderness, SimMap.GetZoneAt(state, new GridPoint(state.BasePos.X + 10, state.BasePos.Y)));
        Assert.Equal(SimMap.ZoneDepths, SimMap.GetZoneAt(state, new GridPoint(state.BasePos.X + 15, state.BasePos.Y)));
    }

    [Fact]
    public void ZoneDataAccessors_ReturnConfiguredValuesAndFallback()
    {
        var safe = SimMap.GetZoneData(SimMap.ZoneSafe);
        var unknown = SimMap.GetZoneData("unknown-zone");

        Assert.Equal("Safe Zone", safe.Name);
        Assert.Equal(safe, unknown);
        Assert.Equal("Frontier", SimMap.GetZoneName(SimMap.ZoneFrontier));
        Assert.Equal(1.5, SimMap.GetZoneThreatMultiplier(SimMap.ZoneWilderness), 3);
        Assert.Equal(2.0, SimMap.GetZoneLootMultiplier(SimMap.ZoneDepths), 3);
        Assert.Equal(2, SimMap.GetZoneEnemyTierMax(SimMap.ZoneFrontier));

        var zones = SimMap.GetAllZones();
        Assert.Equal(new[] { SimMap.ZoneSafe, SimMap.ZoneFrontier, SimMap.ZoneWilderness, SimMap.ZoneDepths }, zones);
    }

    [Fact]
    public void EnsureTileGenerated_FillsEmptyTilesAndPreservesExistingValues()
    {
        var state = CreateState(10, 10);
        FillTerrain(state, "");
        SimMap.ResetBiomeGenerator(); // no-op, but should remain safe to call

        var generatedPos = new GridPoint(0, 0);
        int generatedIndex = SimMap.Idx(generatedPos.X, generatedPos.Y, state.MapW);
        SimMap.EnsureTileGenerated(state, generatedPos);

        string generatedTerrain = state.Terrain[generatedIndex];
        Assert.Contains(
            generatedTerrain,
            new[] { SimMap.Plains, SimMap.Forest, SimMap.Mountain, SimMap.Water, SimMap.Desert, SimMap.Snow });

        var existingPos = new GridPoint(1, 1);
        int existingIndex = SimMap.Idx(existingPos.X, existingPos.Y, state.MapW);
        state.Terrain[existingIndex] = SimMap.Road;
        SimMap.EnsureTileGenerated(state, existingPos);
        Assert.Equal(SimMap.Road, state.Terrain[existingIndex]);

        int beforeCount = state.Terrain.Count;
        SimMap.EnsureTileGenerated(state, new GridPoint(-1, -1));
        Assert.Equal(beforeCount, state.Terrain.Count);
    }

    [Fact]
    public void GenerateTerrain_FillsEmptyTilesPreservesPresetTilesAndKeepsBaseAreaLand()
    {
        var state = CreateState(16, 16);
        FillTerrain(state, "");
        int presetIndex = SimMap.Idx(0, 0, state.MapW);
        state.Terrain[presetIndex] = SimMap.Road;

        SimMap.GenerateTerrain(state);

        Assert.DoesNotContain(state.Terrain, t => string.IsNullOrEmpty(t));
        Assert.Equal(SimMap.Road, state.Terrain[presetIndex]);

        for (int y = 0; y < state.MapH; y++)
        {
            for (int x = 0; x < state.MapW; x++)
            {
                var tilePos = new GridPoint(x, y);
                if (tilePos.EuclideanDistance(state.BasePos) > 3.0)
                    continue;

                string terrain = SimMap.GetTerrain(state, tilePos);
                Assert.True(terrain == SimMap.Plains || terrain == SimMap.Forest,
                    $"Expected land near base at {tilePos}, got '{terrain}'.");
            }
        }
    }

    [Fact]
    public void ComputeDistToBase_UsesPassabilityRules()
    {
        var state = CreateState(5, 5);
        FillTerrain(state, SimMap.Plains);

        var waterPos = new GridPoint(state.BasePos.X, state.BasePos.Y - 1);
        int waterIndex = SimMap.Idx(waterPos.X, waterPos.Y, state.MapW);
        state.Terrain[waterIndex] = SimMap.Water;

        var wallPos = new GridPoint(state.BasePos.X + 1, state.BasePos.Y);
        int wallIndex = SimMap.Idx(wallPos.X, wallPos.Y, state.MapW);
        state.Structures[wallIndex] = "wall";

        int[] dist = SimMap.ComputeDistToBase(state);
        int baseIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);

        Assert.Equal(0, dist[baseIndex]);
        Assert.Equal(-1, dist[waterIndex]);
        Assert.Equal(-1, dist[wallIndex]);
        Assert.Equal(2, dist[SimMap.Idx(0, state.BasePos.Y, state.MapW)]);
        Assert.Equal(4, dist[SimMap.Idx(state.MapW - 1, state.BasePos.Y, state.MapW)]);
    }

    [Fact]
    public void PathOpenToBase_ReflectsWhetherAnEdgeCanReachBase()
    {
        var enclosed = CreateState(5, 5, "path-closed");
        FillTerrain(enclosed, SimMap.Plains);
        foreach (var neighbor in new[]
        {
            new GridPoint(enclosed.BasePos.X + 1, enclosed.BasePos.Y),
            new GridPoint(enclosed.BasePos.X - 1, enclosed.BasePos.Y),
            new GridPoint(enclosed.BasePos.X, enclosed.BasePos.Y + 1),
            new GridPoint(enclosed.BasePos.X, enclosed.BasePos.Y - 1),
        })
        {
            enclosed.Terrain[SimMap.Idx(neighbor.X, neighbor.Y, enclosed.MapW)] = SimMap.Water;
        }
        Assert.False(SimMap.PathOpenToBase(enclosed));

        var reachable = CreateState(5, 5, "path-open");
        FillTerrain(reachable, SimMap.Plains);
        reachable.Terrain[SimMap.Idx(reachable.BasePos.X + 1, reachable.BasePos.Y, reachable.MapW)] = SimMap.Water;
        reachable.Terrain[SimMap.Idx(reachable.BasePos.X - 1, reachable.BasePos.Y, reachable.MapW)] = SimMap.Water;
        reachable.Terrain[SimMap.Idx(reachable.BasePos.X, reachable.BasePos.Y + 1, reachable.MapW)] = SimMap.Water;
        Assert.True(SimMap.PathOpenToBase(reachable));
    }

    [Fact]
    public void GetSpawnPos_AlwaysReturnsInBoundsEdgeTiles()
    {
        var state = CreateState(7, 9, "spawn-seed");

        for (int i = 0; i < 200; i++)
        {
            var spawn = SimMap.GetSpawnPos(state);
            Assert.True(SimMap.InBounds(spawn.X, spawn.Y, state.MapW, state.MapH));
            Assert.True(
                spawn.X == 0 || spawn.Y == 0 || spawn.X == state.MapW - 1 || spawn.Y == state.MapH - 1,
                $"Spawn position {spawn} was not on the map edge.");
        }
    }

    [Fact]
    public void GetTotalExploration_ReturnsCorrectRatioIncludingEmptyMap()
    {
        var state = CreateState(4, 4);
        state.Discovered.Clear();
        state.Discovered.Add(SimMap.Idx(0, 0, state.MapW));
        state.Discovered.Add(SimMap.Idx(1, 0, state.MapW));
        state.Discovered.Add(SimMap.Idx(0, 1, state.MapW));
        state.Discovered.Add(SimMap.Idx(1, 1, state.MapW));

        Assert.Equal(0.25, SimMap.GetTotalExploration(state), 3);

        var emptyMap = CreateState(0, 0);
        emptyMap.Discovered.Clear();
        Assert.Equal(0.0, SimMap.GetTotalExploration(emptyMap), 3);
    }
}
