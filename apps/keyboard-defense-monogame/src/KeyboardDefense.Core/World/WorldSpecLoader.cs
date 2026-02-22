using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.State;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Loads a world_spec JSON and populates GameState terrain from elevation/biome data.
/// Replicates the same coastline→biome→road pipeline as generate_world_preview.ps1.
/// </summary>
public static class WorldSpecLoader
{
    public static bool PopulateFromSpec(GameState state, string specPath)
    {
        if (!File.Exists(specPath)) return false;

        var root = JObject.Parse(File.ReadAllText(specPath));
        int mapW = root["world"]!["width"]!.ToObject<int>();
        int mapH = root["world"]!["height"]!.ToObject<int>();

        state.MapW = mapW;
        state.MapH = mapH;

        // Build elevation grid (mapW+1 x mapH+1 vertices for mapW x mapH tiles)
        int gw = mapW + 1, gh = mapH + 1;
        var levels = new int[gw, gh];
        var swamp = new int[gw, gh];
        var mount = new int[gw, gh];
        var road = new int[gw, gh];

        // --- Coastline from control points + bands ---
        var coast = root["coast"]!;
        var bands = coast["bands"]!;
        double bandMeadow = bands["meadow_to_beach"]!.ToObject<double>();
        double bandBeach = bands["beach_to_shallow"]!.ToObject<double>();
        double bandDeep = bands["shallow_to_deep"]!.ToObject<double>();

        var controlPoints = new List<(int y, double x)>();
        foreach (var cp in coast["control_points"]!)
            controlPoints.Add((cp["y"]!.ToObject<int>(), cp["x"]!.ToObject<double>()));

        for (int y = 0; y < gh; y++)
        {
            double coastX = InterpolateCoastX(y, controlPoints);
            for (int x = 0; x < gw; x++)
            {
                if (x <= coastX - bandMeadow)
                    levels[x, y] = 3; // meadow
                else if (x <= coastX - bandBeach)
                    levels[x, y] = 2; // beach
                else if (x <= coastX + bandDeep)
                    levels[x, y] = 1; // shallow
                else
                    levels[x, y] = 0; // deep
            }
        }

        // Apply bay circles
        if (coast["bays_shallow"] is JArray baysShallow)
            foreach (var b in baysShallow)
                PaintLowerLevel(levels, gw, gh, b["x"]!.ToObject<double>(), b["y"]!.ToObject<double>(), b["r"]!.ToObject<double>(), 1);

        if (coast["bays_deep"] is JArray baysDeep)
            foreach (var b in baysDeep)
                PaintLowerLevel(levels, gw, gh, b["x"]!.ToObject<double>(), b["y"]!.ToObject<double>(), b["r"]!.ToObject<double>(), 0);

        // Water edge smoothing
        for (int y = 1; y < mapH; y++)
            for (int x = 1; x < mapW; x++)
            {
                if (levels[x, y] < 3) continue;
                if (levels[x - 1, y] <= 1 || levels[x + 1, y] <= 1 ||
                    levels[x, y - 1] <= 1 || levels[x, y + 1] <= 1)
                    levels[x, y] = 2;
            }

        // --- Biome circles ---
        var biomes = root["biomes"];
        if (biomes?["swamp"] is JObject sw)
        {
            foreach (var c in sw["outer"]!) PaintBiome(swamp, levels, gw, gh, c, 1);
            foreach (var c in sw["core"]!) PaintBiome(swamp, levels, gw, gh, c, 2);
            if (sw["cut"] is JArray cuts)
                foreach (var c in cuts) CarveBiome(swamp, gw, gh, c);
        }
        if (biomes?["mountain"] is JObject mt)
        {
            foreach (var c in mt["outer"]!) PaintBiome(mount, levels, gw, gh, c, 1);
            foreach (var c in mt["core"]!) PaintBiome(mount, levels, gw, gh, c, 2);
            if (mt["cut"] is JArray cuts)
                foreach (var c in cuts) CarveBiome(mount, gw, gh, c);
        }

        // --- Roads from corridor chains ---
        var poi = GetPoiPositionsFromRoot(root);
        var roads = root["roads"];
        if (roads?["corridors"] is JArray corridors)
        {
            foreach (var corr in corridors)
            {
                double radius = corr["radius"]?.ToObject<double>() ?? 1.0;
                var points = new List<(double x, double y)>();
                foreach (var p in corr["points"]!)
                {
                    string name = p.ToString();
                    if (poi.TryGetValue(name, out var gp))
                        points.Add((gp.X, gp.Y));
                }
                if (points.Count < 2) continue;

                // Stamp road circles along segments
                for (int i = 0; i < points.Count - 1; i++)
                    StampRoadSegment(road, gw, gh, points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, radius);
            }
        }

        // --- Fill terrain list ---
        state.Terrain.Clear();
        for (int y = 0; y < mapH; y++)
            for (int x = 0; x < mapW; x++)
            {
                // Sample the 4 corners of this tile cell
                int minLevel = Math.Min(Math.Min(levels[x, y], levels[x + 1, y]),
                                        Math.Min(levels[x, y + 1], levels[x + 1, y + 1]));
                int maxSwamp = Math.Max(Math.Max(swamp[x, y], swamp[x + 1, y]),
                                        Math.Max(swamp[x, y + 1], swamp[x + 1, y + 1]));
                int maxMount = Math.Max(Math.Max(mount[x, y], mount[x + 1, y]),
                                        Math.Max(mount[x, y + 1], mount[x + 1, y + 1]));
                bool isRoad = road[x, y] == 1 || road[x + 1, y] == 1 ||
                              road[x, y + 1] == 1 || road[x + 1, y + 1] == 1;

                string terrain = MapToTerrain(minLevel, maxSwamp, maxMount, isRoad);
                state.Terrain.Add(terrain);
            }

        return true;
    }

    public static Dictionary<string, GridPoint> GetPoiPositions(string specPath)
    {
        if (!File.Exists(specPath)) return new();
        var root = JObject.Parse(File.ReadAllText(specPath));
        return GetPoiPositionsFromRoot(root);
    }

    private static Dictionary<string, GridPoint> GetPoiPositionsFromRoot(JObject root)
    {
        var result = new Dictionary<string, GridPoint>();
        var targets = root["poi"]?["targets"];
        if (targets == null) return result;

        foreach (var prop in ((JObject)targets).Properties())
            result[prop.Name] = new GridPoint(
                prop.Value["x"]!.ToObject<int>(),
                prop.Value["y"]!.ToObject<int>());

        return result;
    }

    private static string MapToTerrain(int minLevel, int maxSwamp, int maxMount, bool isRoad)
    {
        if (minLevel <= 1) return SimMap.Water;
        if (minLevel == 2) return SimMap.Desert; // beach
        // level 3 = meadow
        if (maxMount >= 1) return SimMap.Mountain;
        if (maxSwamp >= 1) return SimMap.Forest; // swamp
        return SimMap.Plains;
    }

    private static double InterpolateCoastX(int y, List<(int y, double x)> points)
    {
        for (int i = 0; i < points.Count - 1; i++)
        {
            if (y >= points[i].y && y <= points[i + 1].y)
            {
                double t = points[i + 1].y == points[i].y ? 0 :
                    (y - points[i].y) / (double)(points[i + 1].y - points[i].y);
                return points[i].x + (points[i + 1].x - points[i].x) * t;
            }
        }
        return points[^1].x;
    }

    private static void PaintLowerLevel(int[,] levels, int w, int h, double cx, double cy, double r, int target)
    {
        int minX = Math.Max(0, (int)Math.Floor(cx - r));
        int maxX = Math.Min(w - 1, (int)Math.Ceiling(cx + r));
        int minY = Math.Max(0, (int)Math.Floor(cy - r));
        int maxY = Math.Min(h - 1, (int)Math.Ceiling(cy + r));
        double r2 = r * r;
        for (int y = minY; y <= maxY; y++)
            for (int x = minX; x <= maxX; x++)
                if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2)
                    levels[x, y] = target == 0 ? 0 : Math.Min(levels[x, y], target);
    }

    private static void PaintBiome(int[,] biome, int[,] levels, int w, int h, JToken c, int value)
    {
        double cx = c["x"]!.ToObject<double>(), cy = c["y"]!.ToObject<double>(), r = c["r"]!.ToObject<double>();
        int minX = Math.Max(0, (int)Math.Floor(cx - r));
        int maxX = Math.Min(w - 1, (int)Math.Ceiling(cx + r));
        int minY = Math.Max(0, (int)Math.Floor(cy - r));
        int maxY = Math.Min(h - 1, (int)Math.Ceiling(cy + r));
        double r2 = r * r;
        for (int y = minY; y <= maxY; y++)
            for (int x = minX; x <= maxX; x++)
            {
                if (levels[x, y] < 2) continue;
                if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2)
                    biome[x, y] = value;
            }
    }

    private static void CarveBiome(int[,] biome, int w, int h, JToken c)
    {
        double cx = c["x"]!.ToObject<double>(), cy = c["y"]!.ToObject<double>(), r = c["r"]!.ToObject<double>();
        int minX = Math.Max(0, (int)Math.Floor(cx - r));
        int maxX = Math.Min(w - 1, (int)Math.Ceiling(cx + r));
        int minY = Math.Max(0, (int)Math.Floor(cy - r));
        int maxY = Math.Min(h - 1, (int)Math.Ceiling(cy + r));
        double r2 = r * r;
        for (int y = minY; y <= maxY; y++)
            for (int x = minX; x <= maxX; x++)
                if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2)
                    biome[x, y] = 0;
    }

    private static void StampRoadSegment(int[,] road, int w, int h, double x1, double y1, double x2, double y2, double radius)
    {
        double dx = x2 - x1, dy = y2 - y1;
        double dist = Math.Sqrt(dx * dx + dy * dy);
        int steps = Math.Max(2, (int)Math.Ceiling(dist / 0.5));
        double r2 = radius * radius;
        for (int i = 0; i <= steps; i++)
        {
            double t = i / (double)steps;
            double cx = x1 + dx * t, cy = y1 + dy * t;
            int minX = Math.Max(0, (int)Math.Floor(cx - radius));
            int maxX = Math.Min(w - 1, (int)Math.Ceiling(cx + radius));
            int minY = Math.Max(0, (int)Math.Floor(cy - radius));
            int maxY = Math.Min(h - 1, (int)Math.Ceiling(cy + radius));
            for (int y = minY; y <= maxY; y++)
                for (int x = minX; x <= maxX; x++)
                    if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2)
                        road[x, y] = 1;
        }
    }
}
