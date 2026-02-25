using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class MapGenerationTests
{
    private static readonly HashSet<string> ProceduralTerrainTypes = new()
    {
        SimMap.Plains,
        SimMap.Forest,
        SimMap.Mountain,
        SimMap.Water,
        SimMap.Desert,
        SimMap.Snow,
    };

    [Fact]
    public void GeneratedMap_HasExpectedDimensionsAndTileCount()
    {
        var state = CreateProceduralState("map-dimensions-01");

        Assert.Equal(32, state.MapW);
        Assert.Equal(32, state.MapH);
        Assert.Equal(state.MapW * state.MapH, state.Terrain.Count);
        Assert.DoesNotContain(state.Terrain, string.IsNullOrEmpty);
    }

    [Fact]
    public void GeneratedMap_ContainsOnlyKnownProceduralTerrainTypes()
    {
        var state = CreateProceduralState("known-terrain-types-01");

        foreach (string terrain in state.Terrain)
            Assert.Contains(terrain, ProceduralTerrainTypes);
    }

    [Fact]
    public void BasePosition_IsAlwaysOnPassableValidTerrain()
    {
        string[] seeds = { "base-valid-a", "base-valid-b", "base-valid-c", "base-valid-d", "base-valid-e" };
        foreach (string seed in seeds)
        {
            var state = CreateProceduralState(seed);
            string baseTerrain = SimMap.GetTerrain(state, state.BasePos);

            Assert.Contains(baseTerrain, ProceduralTerrainTypes);
            Assert.NotEqual(SimMap.Water, baseTerrain);
            Assert.True(SimMap.IsPassable(state, state.BasePos));
        }
    }

    [Fact]
    public void TerrainVariety_ContainsAllBiomeTerrainTypesIn32x32Map()
    {
        var state = CreateProceduralState("terrain-variety-01");
        var terrainSet = state.Terrain.ToHashSet();

        Assert.Equal(32, state.MapW);
        Assert.Equal(32, state.MapH);

        foreach (string terrainType in ProceduralTerrainTypes)
            Assert.Contains(terrainType, terrainSet);
    }

    [Fact]
    public void FloodFillFromBase_ReachesMoreThanEightyPercent()
    {
        string[] seeds = { "reachability-seed-a", "reachability-seed-b", "reachability-seed-c" };
        foreach (string seed in seeds)
        {
            var state = CreateProceduralState(seed);
            double reachableRatio = ComputeReachableRatio(state);

            Assert.True(
                reachableRatio > 0.80,
                $"Expected >80% reachability from base for seed '{seed}', got {reachableRatio:P2}.");
        }
    }

    [Fact]
    public void DifferentSeeds_ProduceDifferentMaps()
    {
        var first = CreateProceduralState("different-seed-a");
        var second = CreateProceduralState("different-seed-b");

        int differingTiles = first.Terrain
            .Zip(second.Terrain, (left, right) => left == right ? 0 : 1)
            .Sum();

        Assert.True(
            differingTiles > first.Terrain.Count * 0.05,
            $"Expected different seeds to produce distinct maps; differing tiles={differingTiles}.");
    }

    [Fact]
    public void SameSeed_ProducesSameMap()
    {
        var first = CreateProceduralState("deterministic-seed-01");
        var second = CreateProceduralState("deterministic-seed-01");

        Assert.Equal(first.MapW, second.MapW);
        Assert.Equal(first.MapH, second.MapH);
        Assert.Equal(first.BasePos, second.BasePos);
        Assert.Equal(first.Terrain, second.Terrain);
    }

    [Fact]
    public void SameSeed_ProducesSameReachabilityField()
    {
        var first = CreateProceduralState("deterministic-distance-seed");
        var second = CreateProceduralState("deterministic-distance-seed");

        Assert.Equal(SimMap.ComputeDistToBase(first), SimMap.ComputeDistToBase(second));
    }

    [Fact]
    public void SpecWorld_RoadsConnectToAtLeastOneSettlementOrPoi()
    {
        var state = CreateSpecState("spec-road-connectivity-01");
        var roadTiles = GetRoadTileIndexes(state);
        var anchors = GetSettlementOrPoiPositions(state);
        var roadComponents = BuildRoadComponents(state, roadTiles);

        Assert.NotEmpty(roadTiles);
        Assert.NotEmpty(anchors);
        Assert.NotEmpty(roadComponents);

        foreach (var component in roadComponents)
        {
            Assert.True(
                ComponentTouchesAnchor(state, component, anchors, maxManhattanDistance: 3),
                $"Found a disconnected road component of {component.Count} tiles.");
        }
    }

    private static GameState CreateProceduralState(string seed)
        => DefaultState.Create(seed, placeStartingTowers: false, useWorldSpec: false);

    private static GameState CreateSpecState(string seed)
        => DefaultState.Create(seed, placeStartingTowers: false, useWorldSpec: true);

    private static double ComputeReachableRatio(GameState state)
    {
        int reachableTiles = SimMap.ComputeDistToBase(state).Count(distance => distance >= 0);
        int totalTiles = state.MapW * state.MapH;
        return totalTiles == 0 ? 0 : reachableTiles / (double)totalTiles;
    }

    private static HashSet<int> GetRoadTileIndexes(GameState state)
    {
        var roadTiles = new HashSet<int>();
        for (int i = 0; i < state.Terrain.Count; i++)
        {
            if (state.Terrain[i] == SimMap.Road)
                roadTiles.Add(i);
        }
        return roadTiles;
    }

    private static List<GridPoint> GetPoiPositions(GameState state)
    {
        var positions = new List<GridPoint>();
        foreach (var poiState in state.ActivePois.Values)
        {
            if (poiState.TryGetValue("pos", out object? rawPos) && rawPos is GridPoint gridPoint)
                positions.Add(gridPoint);
        }
        return positions;
    }

    private static List<GridPoint> GetSettlementOrPoiPositions(GameState state)
    {
        var positions = GetPoiPositions(state);
        foreach (var (index, structureType) in state.Structures)
        {
            if (string.IsNullOrWhiteSpace(structureType))
                continue;

            if (!structureType.Contains("settlement", StringComparison.OrdinalIgnoreCase) &&
                !structureType.Contains("village", StringComparison.OrdinalIgnoreCase) &&
                !structureType.Contains("outpost", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            positions.Add(SimMap.PosFromIndex(index, state.MapW));
        }

        return positions;
    }

    private static List<HashSet<int>> BuildRoadComponents(GameState state, HashSet<int> roadTiles)
    {
        var components = new List<HashSet<int>>();
        var visited = new HashSet<int>();

        foreach (int start in roadTiles)
        {
            if (!visited.Add(start))
                continue;

            var component = new HashSet<int> { start };
            var frontier = new Queue<int>();
            frontier.Enqueue(start);

            while (frontier.Count > 0)
            {
                int current = frontier.Dequeue();
                GridPoint pos = SimMap.PosFromIndex(current, state.MapW);

                foreach (var neighbor in SimMap.Neighbors4(pos, state.MapW, state.MapH))
                {
                    int next = SimMap.Idx(neighbor.X, neighbor.Y, state.MapW);
                    if (!roadTiles.Contains(next) || !visited.Add(next))
                        continue;

                    component.Add(next);
                    frontier.Enqueue(next);
                }
            }

            components.Add(component);
        }

        return components;
    }

    private static bool ComponentTouchesAnchor(
        GameState state,
        HashSet<int> roadComponent,
        IReadOnlyList<GridPoint> anchorPositions,
        int maxManhattanDistance)
    {
        foreach (var anchor in anchorPositions)
        {
            for (int dy = -maxManhattanDistance; dy <= maxManhattanDistance; dy++)
            {
                int dxLimit = maxManhattanDistance - Math.Abs(dy);
                for (int dx = -dxLimit; dx <= dxLimit; dx++)
                {
                    int x = anchor.X + dx;
                    int y = anchor.Y + dy;
                    if (!SimMap.InBounds(x, y, state.MapW, state.MapH))
                        continue;

                    int index = SimMap.Idx(x, y, state.MapW);
                    if (roadComponent.Contains(index))
                        return true;
                }
            }
        }

        return false;
    }
}
