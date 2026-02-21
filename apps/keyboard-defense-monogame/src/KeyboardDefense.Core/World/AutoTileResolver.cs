using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Calculates auto-tile bitmasks for terrain transitions.
/// Uses a 4-bit cardinal bitmask (N=1, E=2, S=4, W=8) where each bit
/// is set if the neighbor matches the current tile's terrain type.
/// A fully surrounded tile = 15, a corner tile = varies.
/// Also provides 8-bit bitmask (adds NE=16, SE=32, SW=64, NW=128) for
/// Wang tileset lookups when diagonal data is needed.
/// </summary>
public static class AutoTileResolver
{
    // Cardinal direction bit flags
    public const int North = 1;
    public const int East = 2;
    public const int South = 4;
    public const int West = 8;

    // Diagonal direction bit flags (for 8-bit Wang tilesets)
    public const int NorthEast = 16;
    public const int SouthEast = 32;
    public const int SouthWest = 64;
    public const int NorthWest = 128;

    /// <summary>
    /// Calculate a 4-bit cardinal bitmask for the tile at the given position.
    /// Each bit is set if the neighbor in that direction has the same terrain type.
    /// Out-of-bounds neighbors are treated as matching (seamless map edges).
    /// </summary>
    public static int GetCardinalMask(GameState state, GridPoint pos)
    {
        string terrain = SimMap.GetTerrain(state, pos);
        if (string.IsNullOrEmpty(terrain)) return 15; // unknown = fully surrounded

        int mask = 0;
        if (NeighborMatches(state, pos.X, pos.Y - 1, terrain)) mask |= North;
        if (NeighborMatches(state, pos.X + 1, pos.Y, terrain)) mask |= East;
        if (NeighborMatches(state, pos.X, pos.Y + 1, terrain)) mask |= South;
        if (NeighborMatches(state, pos.X - 1, pos.Y, terrain)) mask |= West;
        return mask;
    }

    /// <summary>
    /// Calculate an 8-bit bitmask including diagonals.
    /// Diagonal bits are only set if both adjacent cardinal neighbors also match
    /// (prevents corner artifacts when cardinals don't match).
    /// </summary>
    public static int GetFullMask(GameState state, GridPoint pos)
    {
        string terrain = SimMap.GetTerrain(state, pos);
        if (string.IsNullOrEmpty(terrain)) return 255;

        bool n = NeighborMatches(state, pos.X, pos.Y - 1, terrain);
        bool e = NeighborMatches(state, pos.X + 1, pos.Y, terrain);
        bool s = NeighborMatches(state, pos.X, pos.Y + 1, terrain);
        bool w = NeighborMatches(state, pos.X - 1, pos.Y, terrain);

        int mask = 0;
        if (n) mask |= North;
        if (e) mask |= East;
        if (s) mask |= South;
        if (w) mask |= West;

        // Diagonals only count if both adjacent cardinals match
        if (n && e && NeighborMatches(state, pos.X + 1, pos.Y - 1, terrain)) mask |= NorthEast;
        if (s && e && NeighborMatches(state, pos.X + 1, pos.Y + 1, terrain)) mask |= SouthEast;
        if (s && w && NeighborMatches(state, pos.X - 1, pos.Y + 1, terrain)) mask |= SouthWest;
        if (n && w && NeighborMatches(state, pos.X - 1, pos.Y - 1, terrain)) mask |= NorthWest;

        return mask;
    }

    /// <summary>
    /// Get the terrain type of a neighboring tile, or null if out of bounds.
    /// </summary>
    public static string? GetNeighborTerrain(GameState state, int x, int y)
    {
        if (!SimMap.InBounds(x, y, state.MapW, state.MapH)) return null;
        return SimMap.GetTerrain(state, new GridPoint(x, y));
    }

    /// <summary>
    /// Determine which edge transitions are needed for a tile.
    /// Returns an array of (direction, neighborTerrain) for each edge where
    /// the neighbor has a different terrain type.
    /// </summary>
    public static List<EdgeTransition> GetEdgeTransitions(GameState state, GridPoint pos)
    {
        string terrain = SimMap.GetTerrain(state, pos);
        var transitions = new List<EdgeTransition>();

        CheckEdge(state, pos.X, pos.Y - 1, terrain, North, transitions);
        CheckEdge(state, pos.X + 1, pos.Y, terrain, East, transitions);
        CheckEdge(state, pos.X, pos.Y + 1, terrain, South, transitions);
        CheckEdge(state, pos.X - 1, pos.Y, terrain, West, transitions);

        return transitions;
    }

    /// <summary>
    /// Map a 4-bit cardinal bitmask to a Wang tile index (0-15).
    /// This maps our NESW bitmask to the standard Wang 2-corner encoding.
    /// </summary>
    public static int CardinalMaskToWangIndex(int cardinalMask)
    {
        // Direct mapping: our 4-bit mask (NESW) maps 1:1 to Wang tile indices 0-15
        return cardinalMask & 0xF;
    }

    private static bool NeighborMatches(GameState state, int x, int y, string terrain)
    {
        // Out of bounds = treat as matching (seamless edges)
        if (!SimMap.InBounds(x, y, state.MapW, state.MapH)) return true;
        string neighborTerrain = SimMap.GetTerrain(state, new GridPoint(x, y));
        if (string.IsNullOrEmpty(neighborTerrain)) return true; // ungenerated = match
        return neighborTerrain == terrain;
    }

    private static void CheckEdge(GameState state, int x, int y, string terrain,
        int direction, List<EdgeTransition> transitions)
    {
        if (!SimMap.InBounds(x, y, state.MapW, state.MapH)) return;
        string neighbor = SimMap.GetTerrain(state, new GridPoint(x, y));
        if (string.IsNullOrEmpty(neighbor)) return;
        if (neighbor != terrain)
            transitions.Add(new EdgeTransition(direction, neighbor));
    }
}

/// <summary>Edge transition data: which direction and what terrain type is adjacent.</summary>
public record EdgeTransition(int Direction, string NeighborTerrain);
