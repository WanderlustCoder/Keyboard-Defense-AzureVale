using System.Collections.Generic;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Parsed Wang tileset metadata. Each tileset is a 4x4 grid of 16 tiles
/// (16x16 pixels each, 64x64 total) representing all corner transition
/// combinations between a "lower" (base) and "upper" (transition) terrain.
///
/// Wang ID encoding: SE=1, SW=2, NE=4, NW=8 (bit set = "upper" corner).
/// wang_0 = all lower (base terrain), wang_15 = all upper (transition terrain).
/// </summary>
public class TilesetData
{
    public int TileWidth { get; set; } = 16;
    public int TileHeight { get; set; } = 16;
    public string LowerTerrain { get; set; } = "";
    public string UpperTerrain { get; set; } = "";

    /// <summary>Wang ID (0-15) → source rectangle (x, y, w, h) in the sprite sheet.</summary>
    private readonly Dictionary<int, TileRect> _wangRects = new();

    /// <summary>
    /// Register a Wang tile's position in the sprite sheet.
    /// </summary>
    public void SetTileRect(int wangId, int x, int y, int w, int h)
    {
        _wangRects[wangId] = new TileRect(x, y, w, h);
    }

    /// <summary>
    /// Get the source rectangle for a Wang tile index (0-15).
    /// Returns null if the wang ID is not registered.
    /// </summary>
    public TileRect? GetSourceRect(int wangId)
    {
        return _wangRects.TryGetValue(wangId, out var rect) ? rect : null;
    }

    /// <summary>
    /// Convert a 4-bit cardinal match mask (N=1,E=2,S=4,W=8, bit=1 if neighbor matches)
    /// to a corner-based Wang tile index (SE=1,SW=2,NE=4,NW=8, bit=1 if corner is "upper").
    ///
    /// A corner is "upper" (transition terrain) if either adjacent cardinal neighbor
    /// is different (bit=0 in cardinal mask). This creates smooth corner transitions.
    /// </summary>
    public static int CardinalMaskToCornerWang(int cardinalMask)
    {
        return CardinalToWangLookup[cardinalMask & 0xF];
    }

    // Pre-computed lookup: cardinal_mask → corner wang_id
    // Cardinal bits: N=1, E=2, S=4, W=8 (set if neighbor matches)
    // Corner bits: SE=1, SW=2, NE=4, NW=8 (set if corner is "upper"/transition)
    // Corner is upper if either adjacent cardinal is different (bit=0)
    private static readonly int[] CardinalToWangLookup = new int[16]
    {
        15, // 0: ---- (none match) → all corners upper
        15, // 1: N--- → SE,SW,NE,NW all have at least one different adjacent
        15, // 2: -E-- → all corners have at least one different adjacent
        11, // 3: NE-- → SE upper, SW upper, NW upper (only NE has both N+E matching)
        15, // 4: --S- → all corners have at least one different adjacent
        15, // 5: N-S- → E and W missing, all corners have a different adjacent
        14, // 6: -ES- → SW,NE,NW upper (SE has both S+E matching → lower)
        10, // 7: NES- → SW,NW upper (SE has S+E, NE has N+E → both lower)
        15, // 8: ---W → all corners have at least one different adjacent
         7, // 9: N--W → SE,SW,NE upper (NW has both N+W matching → lower)
        15, // 10: -E-W → N and S missing, all corners have a different adjacent
         3, // 11: NE-W → SE,SW upper (NE has N+E, NW has N+W → both lower)
        13, // 12: --SW → SE,NE,NW upper (SW has both S+W matching → lower)
         5, // 13: N-SW → SE,NE upper (NW has N+W, SW has S+W → both lower)
        12, // 14: -ESW → NE,NW upper (SE has S+E, SW has S+W → both lower)
         0, // 15: NESW (all match) → all corners lower (full base terrain)
    };

    /// <summary>Number of registered Wang tiles.</summary>
    public int Count => _wangRects.Count;
}

/// <summary>Source rectangle in a tileset sprite sheet.</summary>
public record TileRect(int X, int Y, int Width, int Height);
