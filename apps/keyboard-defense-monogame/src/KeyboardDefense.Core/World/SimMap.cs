using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Map operations, pathfinding, and zone system.
/// Ported from sim/map.gd.
/// </summary>
public static class SimMap
{
    public const string Plains = "plains";
    public const string Forest = "forest";
    public const string Mountain = "mountain";
    public const string Water = "water";
    public const string Desert = "desert";
    public const string Snow = "snow";
    public const string Road = "road";

    public const string ZoneSafe = "safe";
    public const string ZoneFrontier = "frontier";
    public const string ZoneWilderness = "wilderness";
    public const string ZoneDepths = "depths";

    public const int ZoneSafeRadius = 4;
    public const int ZoneFrontierRadius = 8;
    public const int ZoneWildernessRadius = 14;

    public static readonly Dictionary<string, ZoneData> ZoneDataMap = new()
    {
        [ZoneSafe] = new("Safe Zone", "Enemies are weak and resources are common.", 0.5, 0.8, 1, 1.0),
        [ZoneFrontier] = new("Frontier", "Moderate challenge with better rewards.", 1.0, 1.0, 2, 1.25),
        [ZoneWilderness] = new("Wilderness", "Strong enemies guard valuable treasures.", 1.5, 1.5, 3, 1.5),
        [ZoneDepths] = new("The Depths", "Only the bravest venture here.", 2.0, 2.0, 4, 2.0),
    };

    /// <summary>
    /// Converts grid coordinates to the flattened tile index used by map-backed collections.
    /// </summary>
    public static int Idx(int x, int y, int w) => y * w + x;
    /// <summary>
    /// Converts a flattened tile index back into grid coordinates.
    /// </summary>
    public static GridPoint PosFromIndex(int index, int w) => new(index % w, index / w);
    /// <summary>
    /// Returns whether a coordinate lies within the map dimensions.
    /// </summary>
    public static bool InBounds(int x, int y, int w, int h) => x >= 0 && y >= 0 && x < w && y < h;

    /// <summary>
    /// Enumerates orthogonal neighboring tiles that are inside the map bounds.
    /// </summary>
    public static List<GridPoint> Neighbors4(GridPoint pos, int w, int h)
    {
        var results = new List<GridPoint>();
        GridPoint[] offsets = { new(1, 0), new(-1, 0), new(0, 1), new(0, -1) };
        foreach (var offset in offsets)
        {
            int nx = pos.X + offset.X;
            int ny = pos.Y + offset.Y;
            if (InBounds(nx, ny, w, h))
                results.Add(new GridPoint(nx, ny));
        }
        return results;
    }

    /// <summary>
    /// Returns the terrain type at the given map position, or an empty string when unavailable.
    /// </summary>
    public static string GetTerrain(GameState state, GridPoint pos)
    {
        if (!InBounds(pos.X, pos.Y, state.MapW, state.MapH)) return "";
        EnsureTerrainSize(state);
        int index = Idx(pos.X, pos.Y, state.MapW);
        if (index < 0 || index >= state.Terrain.Count) return "";
        return state.Terrain[index];
    }

    /// <summary>
    /// Determines whether a tile can host a new structure based on discovery, occupancy, and terrain rules.
    /// </summary>
    public static bool IsBuildable(GameState state, GridPoint pos)
    {
        if (!InBounds(pos.X, pos.Y, state.MapW, state.MapH)) return false;
        if (pos == state.BasePos) return false;
        int index = Idx(pos.X, pos.Y, state.MapW);
        if (!state.Discovered.Contains(index)) return false;
        if (state.Structures.ContainsKey(index)) return false;
        string terrain = GetTerrain(state, pos);
        return terrain != Water && terrain != Mountain;
    }

    /// <summary>
    /// Determines whether movement can traverse a tile, accounting for blocking structures and terrain.
    /// </summary>
    public static bool IsPassable(GameState state, GridPoint pos)
    {
        if (!InBounds(pos.X, pos.Y, state.MapW, state.MapH)) return false;
        int index = Idx(pos.X, pos.Y, state.MapW);
        if (state.Structures.TryGetValue(index, out var building))
        {
            if (building == "wall" || building == "tower") return false;
        }
        string terrain = GetTerrain(state, pos);
        if (terrain == "") terrain = Plains;
        return terrain != Water;
    }

    /// <summary>
    /// Computes the zone identifier for a tile based on scaled distance bands from the castle.
    /// </summary>
    public static string GetZoneAt(GameState state, GridPoint pos)
    {
        int dist = ChebyshevDistanceToCastle(state, pos);

        // Scale zone radii proportionally to map size (base constants tuned for 32x32)
        float scale = MathF.Sqrt((float)(state.MapW * state.MapH) / 1024f);
        if (scale < 1f) scale = 1f;

        if (dist <= (int)(ZoneSafeRadius * scale)) return ZoneSafe;
        if (dist <= (int)(ZoneFrontierRadius * scale)) return ZoneFrontier;
        if (dist <= (int)(ZoneWildernessRadius * scale)) return ZoneWilderness;
        return ZoneDepths;
    }

    /// <summary>
    /// Computes Manhattan distance from a tile to the castle position.
    /// </summary>
    public static int DistanceToCastle(GameState state, GridPoint pos)
        => Math.Abs(pos.X - state.BasePos.X) + Math.Abs(pos.Y - state.BasePos.Y);

    /// <summary>
    /// Computes Chebyshev distance from a tile to the castle position.
    /// </summary>
    public static int ChebyshevDistanceToCastle(GameState state, GridPoint pos)
        => Math.Max(Math.Abs(pos.X - state.BasePos.X), Math.Abs(pos.Y - state.BasePos.Y));

    /// <summary>
    /// Resolves zone metadata for a zone identifier, defaulting to safe-zone values when unknown.
    /// </summary>
    public static ZoneData GetZoneData(string zoneId)
        => ZoneDataMap.GetValueOrDefault(zoneId, ZoneDataMap[ZoneSafe]);

    /// <summary>
    /// Returns the display name for a zone identifier.
    /// </summary>
    public static string GetZoneName(string zoneId) => GetZoneData(zoneId).Name;

    /// <summary>
    /// Returns the threat-scaling multiplier for entities in the given zone.
    /// </summary>
    public static double GetZoneThreatMultiplier(string zoneId) => GetZoneData(zoneId).ThreatMultiplier;
    /// <summary>
    /// Returns the loot-scaling multiplier for rewards found in the given zone.
    /// </summary>
    public static double GetZoneLootMultiplier(string zoneId) => GetZoneData(zoneId).LootMultiplier;
    /// <summary>
    /// Returns the highest enemy tier expected in the given zone.
    /// </summary>
    public static int GetZoneEnemyTierMax(string zoneId) => GetZoneData(zoneId).EnemyTierMax;

    // Terrain constant aliases for cross-file compatibility
    public const string TerrainPlains = Plains;
    public const string TerrainForest = Forest;
    public const string TerrainMountain = Mountain;
    public const string TerrainWater = Water;
    public const string TerrainDesert = Desert;
    public const string TerrainSnow = Snow;
    public const string TerrainRoad = Road;

    /// <summary>
    /// Returns the ordered set of all world zone identifiers used by map and world-generation systems.
    /// </summary>
    public static string[] GetAllZones() => new[] { ZoneSafe, ZoneFrontier, ZoneWilderness, ZoneDepths };

    /// <summary>
    /// Resets biome-generation state for compatibility with legacy call sites; no state is currently retained.
    /// </summary>
    public static void ResetBiomeGenerator() { /* No-op: stateless in C# port */ }

    /// <summary>
    /// Lazily generates terrain content for a tile if it has not been assigned yet.
    /// </summary>
    public static void EnsureTileGenerated(GameState state, GridPoint pos)
    {
        if (!InBounds(pos.X, pos.Y, state.MapW, state.MapH)) return;
        EnsureTerrainSize(state);
        int index = Idx(pos.X, pos.Y, state.MapW);
        if (string.IsNullOrEmpty(state.Terrain[index]))
            state.Terrain[index] = RollTerrain(state, pos.X, pos.Y);
    }

    /// <summary>
    /// Checks whether at least one map edge tile has a passable route to the castle.
    /// </summary>
    public static bool PathOpenToBase(GameState state)
    {
        var dist = ComputeDistToBase(state);
        // Check if any edge tile can reach the base
        for (int x = 0; x < state.MapW; x++)
        {
            if (dist[Idx(x, 0, state.MapW)] >= 0) return true;
            if (dist[Idx(x, state.MapH - 1, state.MapW)] >= 0) return true;
        }
        for (int y = 0; y < state.MapH; y++)
        {
            if (dist[Idx(0, y, state.MapW)] >= 0) return true;
            if (dist[Idx(state.MapW - 1, y, state.MapW)] >= 0) return true;
        }
        return false;
    }

    /// <summary>
    /// Picks a random edge coordinate as an enemy spawn origin for wave and roaming systems.
    /// </summary>
    public static GridPoint GetSpawnPos(GameState state)
    {
        // Pick a random edge tile
        int edge = SimRng.RollRange(state, 0, 3);
        return edge switch
        {
            0 => new GridPoint(SimRng.RollRange(state, 0, state.MapW - 1), 0),
            1 => new GridPoint(SimRng.RollRange(state, 0, state.MapW - 1), state.MapH - 1),
            2 => new GridPoint(0, SimRng.RollRange(state, 0, state.MapH - 1)),
            _ => new GridPoint(state.MapW - 1, SimRng.RollRange(state, 0, state.MapH - 1)),
        };
    }

    /// <summary>
    /// Returns the discovered-map coverage ratio in the range from 0 to 1.
    /// </summary>
    public static double GetTotalExploration(GameState state)
    {
        int discovered = state.Discovered.Count;
        int total = state.MapW * state.MapH;
        return total > 0 ? (double)discovered / total : 0;
    }

    /// <summary>
    /// Fills all uninitialized terrain tiles for the current map dimensions.
    /// </summary>
    public static void GenerateTerrain(GameState state)
    {
        EnsureTerrainSize(state);
        for (int y = 0; y < state.MapH; y++)
        {
            for (int x = 0; x < state.MapW; x++)
            {
                int index = Idx(x, y, state.MapW);
                if (state.Terrain[index] == "")
                    state.Terrain[index] = RollTerrain(state, x, y);
            }
        }
    }

    /// <summary>
    /// Computes breadth-first path distances from every passable tile to the castle tile.
    /// </summary>
    public static int[] ComputeDistToBase(GameState state)
    {
        EnsureTerrainSize(state);
        int total = state.MapW * state.MapH;
        var dist = new int[total];
        Array.Fill(dist, -1);

        int baseIndex = Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        dist[baseIndex] = 0;
        var queue = new Queue<GridPoint>();
        queue.Enqueue(state.BasePos);

        while (queue.Count > 0)
        {
            var current = queue.Dequeue();
            int currentIndex = Idx(current.X, current.Y, state.MapW);
            int currentDist = dist[currentIndex];

            foreach (var neighbor in Neighbors4(current, state.MapW, state.MapH))
            {
                int ni = Idx(neighbor.X, neighbor.Y, state.MapW);
                if (dist[ni] >= 0) continue;
                if (!IsPassable(state, neighbor) && neighbor != state.BasePos) continue;
                dist[ni] = currentDist + 1;
                queue.Enqueue(neighbor);
            }
        }
        return dist;
    }

    private static void EnsureTerrainSize(GameState state)
    {
        int total = state.MapW * state.MapH;
        if (state.Terrain.Count == total) return;
        state.Terrain.Clear();
        for (int i = 0; i < total; i++)
            state.Terrain.Add("");
    }

    private static string RollTerrain(GameState state, int x, int y)
    {
        // Simplified noise-free terrain generation using RNG
        int roll = SimRng.RollRange(state, 1, 100);

        // Guarantee land near castle
        var bp = state.BasePos;
        double dist = Math.Sqrt(Math.Pow(x - bp.X, 2) + Math.Pow(y - bp.Y, 2));
        if (dist <= 3) return roll <= 30 ? Forest : Plains;

        // Desert appears in hot quadrants (south-east), snow in cold quadrants (north-west)
        bool southEast = x > bp.X + 3 && y > bp.Y + 3;
        bool northWest = x < bp.X - 3 && y < bp.Y - 3;

        if (dist > 8 && southEast)
        {
            // Desert zone: far south-east
            if (roll <= 40) return Desert;
            if (roll <= 55) return Plains;
            if (roll <= 75) return Mountain;
            if (roll <= 90) return Forest;
            return Water;
        }

        if (dist > 8 && northWest)
        {
            // Snow zone: far north-west
            if (roll <= 40) return Snow;
            if (roll <= 55) return Mountain;
            if (roll <= 75) return Forest;
            if (roll <= 90) return Plains;
            return Water;
        }

        if (roll <= 45) return Plains;
        if (roll <= 75) return Forest;
        if (roll <= 90) return Mountain;
        return Water;
    }
}

/// <summary>
/// Immutable zone metadata used to drive difficulty, rewards, and descriptive world map presentation.
/// </summary>
public record ZoneData(string Name, string Description, double ThreatMultiplier, double LootMultiplier, int EnemyTierMax, double ResourceQuality);
