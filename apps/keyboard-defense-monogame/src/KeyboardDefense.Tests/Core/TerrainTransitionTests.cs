using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class TerrainTransitionTests
{
    private const int WangSe = 1;
    private const int WangSw = 2;
    private const int WangNe = 4;
    private const int WangNw = 8;

    [Fact]
    public void EdgeTransitions_SingleBoundary_DetectsDirectionAndBiome()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Plains, SimMap.Plains, SimMap.Forest },
            { SimMap.Plains, SimMap.Plains, SimMap.Forest },
            { SimMap.Plains, SimMap.Plains, SimMap.Forest },
        });

        EdgeTransition transition = Assert.Single(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1)));
        Assert.Equal(AutoTileResolver.East, transition.Direction);
        Assert.Equal(SimMap.Forest, transition.NeighborTerrain);
    }

    [Fact]
    public void EdgeTransitions_MultipleAdjacentBiomes_TracksPerDirection()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Road, SimMap.Forest, SimMap.Road },
            { SimMap.Snow, SimMap.Plains, SimMap.Desert },
            { SimMap.Road, SimMap.Mountain, SimMap.Road },
        });

        Dictionary<int, string> byDirection = ToDirectionMap(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1)));
        Assert.Equal(4, byDirection.Count);
        Assert.Equal(SimMap.Forest, byDirection[AutoTileResolver.North]);
        Assert.Equal(SimMap.Desert, byDirection[AutoTileResolver.East]);
        Assert.Equal(SimMap.Mountain, byDirection[AutoTileResolver.South]);
        Assert.Equal(SimMap.Snow, byDirection[AutoTileResolver.West]);
    }

    [Fact]
    public void EdgeTransitions_MapBorder_IgnoresOutOfBoundsNeighbors()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Plains, SimMap.Forest },
            { SimMap.Plains, SimMap.Plains },
        });

        EdgeTransition transition = Assert.Single(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(0, 0)));
        Assert.Equal(AutoTileResolver.East, transition.Direction);
        Assert.Equal(SimMap.Forest, transition.NeighborTerrain);
    }

    [Fact]
    public void CornerTransition_NorthEastConnected_OnlyNeCornerIsLower()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Road, SimMap.Plains, SimMap.Plains },
            { SimMap.Snow, SimMap.Plains, SimMap.Plains },
            { SimMap.Road, SimMap.Desert, SimMap.Road },
        });

        int cardinal = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        Assert.Equal(AutoTileResolver.North | AutoTileResolver.East, cardinal);

        int wang = TilesetData.CardinalMaskToCornerWang(cardinal);
        Assert.Equal(11, wang);
        Assert.True(IsCornerUpper(wang, WangSe));
        Assert.True(IsCornerUpper(wang, WangSw));
        Assert.False(IsCornerUpper(wang, WangNe));
        Assert.True(IsCornerUpper(wang, WangNw));
    }

    [Fact]
    public void CornerTransition_AllCardinalsMatch_ResolvesToWang0()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Forest, SimMap.Forest, SimMap.Forest },
            { SimMap.Forest, SimMap.Forest, SimMap.Forest },
            { SimMap.Forest, SimMap.Forest, SimMap.Forest },
        });

        int cardinal = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        int wang = TilesetData.CardinalMaskToCornerWang(cardinal);

        Assert.Equal(15, cardinal);
        Assert.Equal(0, wang);
    }

    [Fact]
    public void CornerTransition_NoCardinalsMatch_ResolvesToWang15()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Road, SimMap.Forest, SimMap.Road },
            { SimMap.Snow, SimMap.Plains, SimMap.Desert },
            { SimMap.Road, SimMap.Mountain, SimMap.Road },
        });

        int cardinal = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        int wang = TilesetData.CardinalMaskToCornerWang(cardinal);

        Assert.Equal(0, cardinal);
        Assert.Equal(15, wang);
    }

    [Fact]
    public void AllSixteenCardinalConfigurations_ProduceValidResolvableWangIndices()
    {
        var tileset = new TilesetData();
        for (int id = 0; id < 16; id++)
        {
            tileset.SetTileRect(id, (id % 4) * 16, (id / 4) * 16, 16, 16);
        }

        for (int cardinal = 0; cardinal < 16; cardinal++)
        {
            int edgeWang = AutoTileResolver.CardinalMaskToWangIndex(cardinal);
            int cornerWang = TilesetData.CardinalMaskToCornerWang(cardinal);

            Assert.Equal(cardinal, edgeWang);
            Assert.InRange(edgeWang, 0, 15);
            Assert.InRange(cornerWang, 0, 15);
            Assert.NotNull(tileset.GetSourceRect(edgeWang));
            Assert.NotNull(tileset.GetSourceRect(cornerWang));
        }
    }

    [Fact]
    public void TransitionSymmetry_HorizontalBoundary_AtoBMatchesBtoAReversed()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Plains, SimMap.Plains, SimMap.Forest },
            { SimMap.Plains, SimMap.Plains, SimMap.Forest },
            { SimMap.Plains, SimMap.Plains, SimMap.Forest },
        });

        EdgeTransition plainsToForest = Assert.Single(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1)));
        EdgeTransition forestToPlains = Assert.Single(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(2, 1)));

        Assert.Equal(SimMap.Forest, plainsToForest.NeighborTerrain);
        Assert.Equal(SimMap.Plains, forestToPlains.NeighborTerrain);
        Assert.Equal(OppositeDirection(plainsToForest.Direction), forestToPlains.Direction);
    }

    [Fact]
    public void TransitionSymmetry_VerticalBoundary_AtoBMatchesBtoAReversed()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Plains, SimMap.Plains, SimMap.Plains },
            { SimMap.Plains, SimMap.Plains, SimMap.Plains },
            { SimMap.Desert, SimMap.Desert, SimMap.Desert },
        });

        EdgeTransition plainsToDesert = Assert.Single(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1)));
        EdgeTransition desertToPlains = Assert.Single(AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 2)));

        Assert.Equal(SimMap.Desert, plainsToDesert.NeighborTerrain);
        Assert.Equal(SimMap.Plains, desertToPlains.NeighborTerrain);
        Assert.Equal(OppositeDirection(plainsToDesert.Direction), desertToPlains.Direction);
    }

    [Fact]
    public void ComplexIntersection_FourBiomesAroundCenter_ProducesExpectedTransitions()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Plains, SimMap.Plains, SimMap.Plains, SimMap.Plains, SimMap.Plains },
            { SimMap.Plains, SimMap.Desert, SimMap.Forest, SimMap.Water, SimMap.Plains },
            { SimMap.Plains, SimMap.Snow, SimMap.Plains, SimMap.Desert, SimMap.Plains },
            { SimMap.Plains, SimMap.Forest, SimMap.Mountain, SimMap.Road, SimMap.Plains },
            { SimMap.Plains, SimMap.Plains, SimMap.Plains, SimMap.Plains, SimMap.Plains },
        });

        var center = new GridPoint(2, 2);
        Dictionary<int, string> byDirection = ToDirectionMap(AutoTileResolver.GetEdgeTransitions(state, center));

        Assert.Equal(0, AutoTileResolver.GetCardinalMask(state, center));
        Assert.Equal(4, byDirection.Count);
        Assert.Equal(SimMap.Forest, byDirection[AutoTileResolver.North]);
        Assert.Equal(SimMap.Desert, byDirection[AutoTileResolver.East]);
        Assert.Equal(SimMap.Mountain, byDirection[AutoTileResolver.South]);
        Assert.Equal(SimMap.Snow, byDirection[AutoTileResolver.West]);
    }

    [Fact]
    public void ComplexIntersection_DiagonalMatchesDoNotLeakWithoutCardinalSupport()
    {
        var state = CreateState(new string[,]
        {
            { SimMap.Plains, SimMap.Forest, SimMap.Plains },
            { SimMap.Desert, SimMap.Plains, SimMap.Water },
            { SimMap.Plains, SimMap.Mountain, SimMap.Plains },
        });

        var center = new GridPoint(1, 1);
        int cardinal = AutoTileResolver.GetCardinalMask(state, center);
        int fullMask = AutoTileResolver.GetFullMask(state, center);
        int wang = TilesetData.CardinalMaskToCornerWang(cardinal);

        Assert.Equal(0, cardinal);
        Assert.Equal(0, fullMask);
        Assert.Equal(15, wang);
    }

    private static GameState CreateState(string[,] terrain)
    {
        int height = terrain.GetLength(0);
        int width = terrain.GetLength(1);

        var state = new GameState
        {
            MapW = width,
            MapH = height,
        };

        state.Terrain.Clear();
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                state.Terrain.Add(terrain[y, x]);
            }
        }

        state.BasePos = new GridPoint(width / 2, height / 2);
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;

        return state;
    }

    private static Dictionary<int, string> ToDirectionMap(IEnumerable<EdgeTransition> transitions)
    {
        return transitions.ToDictionary(t => t.Direction, t => t.NeighborTerrain);
    }

    private static bool IsCornerUpper(int wangId, int cornerBit)
    {
        return (wangId & cornerBit) != 0;
    }

    private static int OppositeDirection(int direction)
    {
        return direction switch
        {
            AutoTileResolver.North => AutoTileResolver.South,
            AutoTileResolver.East => AutoTileResolver.West,
            AutoTileResolver.South => AutoTileResolver.North,
            AutoTileResolver.West => AutoTileResolver.East,
            _ => throw new ArgumentOutOfRangeException(nameof(direction), direction, "Unknown transition direction."),
        };
    }
}
