using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class AutoTileResolverTests
{
    private static GameState Create3x3(string[,] terrainGrid)
    {
        // Creates a 3x3 map with the given terrain layout
        var state = new GameState { MapW = 3, MapH = 3 };
        state.Terrain.Clear();
        for (int y = 0; y < 3; y++)
            for (int x = 0; x < 3; x++)
                state.Terrain.Add(terrainGrid[y, x]);
        state.BasePos = new GridPoint(1, 1);
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        return state;
    }

    private static GameState CreateUniform(string terrain)
    {
        return Create3x3(new string[,]
        {
            { terrain, terrain, terrain },
            { terrain, terrain, terrain },
            { terrain, terrain, terrain },
        });
    }

    // --- Cardinal Mask Tests ---

    [Fact]
    public void CardinalMask_UniformTerrain_Returns15()
    {
        var state = CreateUniform("plains");
        int mask = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        Assert.Equal(15, mask); // All 4 neighbors match
    }

    [Fact]
    public void CardinalMask_CornerTile_EdgesTreatedAsMatch()
    {
        var state = CreateUniform("plains");
        // Top-left corner: N and W are out of bounds = treated as matching
        int mask = AutoTileResolver.GetCardinalMask(state, new GridPoint(0, 0));
        Assert.Equal(15, mask);
    }

    [Fact]
    public void CardinalMask_DifferentNorth_NorthBitClear()
    {
        var state = Create3x3(new string[,]
        {
            { "plains", "water", "plains" },
            { "plains", "plains", "plains" },
            { "plains", "plains", "plains" },
        });
        int mask = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        // North is water, so North bit (1) is clear
        Assert.Equal(AutoTileResolver.East | AutoTileResolver.South | AutoTileResolver.West, mask);
        Assert.Equal(14, mask);
    }

    [Fact]
    public void CardinalMask_DifferentEast_EastBitClear()
    {
        var state = Create3x3(new string[,]
        {
            { "forest", "forest", "forest" },
            { "forest", "forest", "mountain" },
            { "forest", "forest", "forest" },
        });
        int mask = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        Assert.Equal(AutoTileResolver.North | AutoTileResolver.South | AutoTileResolver.West, mask);
        Assert.Equal(13, mask);
    }

    [Fact]
    public void CardinalMask_AllDifferent_Returns0()
    {
        var state = Create3x3(new string[,]
        {
            { "water", "water", "water" },
            { "mountain", "plains", "forest" },
            { "water", "mountain", "water" },
        });
        int mask = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        Assert.Equal(0, mask); // No neighbors match "plains"
    }

    [Fact]
    public void CardinalMask_OnlySouthMatches()
    {
        var state = Create3x3(new string[,]
        {
            { "water", "forest", "water" },
            { "mountain", "plains", "water" },
            { "water", "plains", "water" },
        });
        int mask = AutoTileResolver.GetCardinalMask(state, new GridPoint(1, 1));
        Assert.Equal(AutoTileResolver.South, mask);
        Assert.Equal(4, mask);
    }

    // --- Full Mask Tests ---

    [Fact]
    public void FullMask_UniformTerrain_Returns255()
    {
        var state = CreateUniform("forest");
        int mask = AutoTileResolver.GetFullMask(state, new GridPoint(1, 1));
        Assert.Equal(255, mask); // All 8 neighbors match
    }

    [Fact]
    public void FullMask_DiagonalOnlyDifferent_DiagonalBitClear()
    {
        // NE corner is different but N and E both match => NE bit should be clear
        var state = Create3x3(new string[,]
        {
            { "plains", "plains", "water" },
            { "plains", "plains", "plains" },
            { "plains", "plains", "plains" },
        });
        int mask = AutoTileResolver.GetFullMask(state, new GridPoint(1, 1));
        // NE is water while N and E are plains. N matches, E matches, but NE doesn't.
        int expected = AutoTileResolver.North | AutoTileResolver.East
            | AutoTileResolver.South | AutoTileResolver.West
            | AutoTileResolver.SouthEast | AutoTileResolver.SouthWest | AutoTileResolver.NorthWest;
        Assert.Equal(expected, mask);
    }

    [Fact]
    public void FullMask_CardinalMismatch_BlocksDiagonal()
    {
        // If North is different, NE and NW diagonals should NOT be set
        // even if diagonal tiles match
        var state = Create3x3(new string[,]
        {
            { "plains", "water", "plains" },
            { "plains", "plains", "plains" },
            { "plains", "plains", "plains" },
        });
        int mask = AutoTileResolver.GetFullMask(state, new GridPoint(1, 1));
        // North is water (mismatch). NE and NW blocked because N is mismatched.
        Assert.Equal(0, mask & AutoTileResolver.NorthEast);
        Assert.Equal(0, mask & AutoTileResolver.NorthWest);
        // South, SE, SW should all be set
        Assert.NotEqual(0, mask & AutoTileResolver.South);
        Assert.NotEqual(0, mask & AutoTileResolver.SouthEast);
        Assert.NotEqual(0, mask & AutoTileResolver.SouthWest);
    }

    // --- Edge Transition Tests ---

    [Fact]
    public void EdgeTransitions_UniformTerrain_ReturnsEmpty()
    {
        var state = CreateUniform("plains");
        var transitions = AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1));
        Assert.Empty(transitions);
    }

    [Fact]
    public void EdgeTransitions_WaterToNorth_ReturnsOneTransition()
    {
        var state = Create3x3(new string[,]
        {
            { "plains", "water", "plains" },
            { "plains", "plains", "plains" },
            { "plains", "plains", "plains" },
        });
        var transitions = AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1));
        Assert.Single(transitions);
        Assert.Equal(AutoTileResolver.North, transitions[0].Direction);
        Assert.Equal("water", transitions[0].NeighborTerrain);
    }

    [Fact]
    public void EdgeTransitions_DifferentOnAllSides_ReturnsFour()
    {
        var state = Create3x3(new string[,]
        {
            { "water", "water", "water" },
            { "mountain", "plains", "forest" },
            { "water", "mountain", "water" },
        });
        var transitions = AutoTileResolver.GetEdgeTransitions(state, new GridPoint(1, 1));
        Assert.Equal(4, transitions.Count);
    }

    [Fact]
    public void EdgeTransitions_AtMapEdge_IgnoresOutOfBounds()
    {
        var state = CreateUniform("plains");
        state.Terrain[1] = "water"; // (1,0) = top center, neighbor above (0,0) is plains
        // Tile at (0,0): N and W are out of bounds (no transition), E=(1,0)=water, S=(0,1)=plains
        var transitions = AutoTileResolver.GetEdgeTransitions(state, new GridPoint(0, 0));
        Assert.Single(transitions);
        Assert.Equal(AutoTileResolver.East, transitions[0].Direction);
    }

    // --- Wang Index Tests ---

    [Fact]
    public void CardinalMaskToWangIndex_MapsDirectly()
    {
        Assert.Equal(0, AutoTileResolver.CardinalMaskToWangIndex(0));
        Assert.Equal(15, AutoTileResolver.CardinalMaskToWangIndex(15));
        Assert.Equal(5, AutoTileResolver.CardinalMaskToWangIndex(5));
    }

    // --- Neighbor Terrain ---

    [Fact]
    public void GetNeighborTerrain_InBounds_ReturnsTerrain()
    {
        var state = CreateUniform("forest");
        state.Terrain[0] = "water"; // (0,0) = water
        string? t = AutoTileResolver.GetNeighborTerrain(state, 0, 0);
        Assert.Equal("water", t);
    }

    [Fact]
    public void GetNeighborTerrain_OutOfBounds_ReturnsNull()
    {
        var state = CreateUniform("plains");
        string? t = AutoTileResolver.GetNeighborTerrain(state, -1, 0);
        Assert.Null(t);
    }
}
