using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Building definitions and production logic.
/// Ported from sim/buildings.gd.
/// </summary>
public static class BuildingsData
{
    private static Dictionary<string, BuildingDef>? _cache;
    private static readonly HashSet<string> ValidTypes = new()
    {
        "farm", "lumber", "quarry", "wall", "tower", "market",
        "barracks", "temple", "workshop",
        "auto_sentry", "auto_spark", "auto_thorns",
        "auto_ballista", "auto_tesla", "auto_bramble", "auto_flame",
        "auto_cannon", "auto_storm", "auto_fortress", "auto_inferno",
        "auto_arcane", "auto_doom"
    };

    /// <summary>
    /// Determines whether a building type is part of the known, valid building ID set.
    /// </summary>
    /// <param name="buildingType">Building type identifier to validate.</param>
    /// <returns><c>true</c> when the type is recognized; otherwise, <c>false</c>.</returns>
    public static bool IsValid(string buildingType) => ValidTypes.Contains(buildingType);

    /// <summary>
    /// Loads building definitions from <c>buildings.json</c> in the provided data directory into cache.
    /// </summary>
    /// <param name="dataDir">Root data directory containing building definition files.</param>
    public static void LoadData(string dataDir)
    {
        var path = Path.Combine(dataDir, "buildings.json");
        _cache = new Dictionary<string, BuildingDef>();
        if (!File.Exists(path)) return;
        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);
        var buildings = root["buildings"] as JObject;
        if (buildings == null) return;
        foreach (var prop in buildings.Properties())
        {
            var data = prop.Value as JObject;
            if (data == null) continue;
            _cache[prop.Name] = new BuildingDef
            {
                Id = prop.Name,
                Name = data.Value<string>("label") ?? data.Value<string>("name") ?? prop.Name,
                Description = data.Value<string>("description") ?? "",
                Cost = ParseResourceDict(data["cost"]),
                Production = ParseResourceDict(data["production"]),
                Defense = data.Value<int>("defense"),
                WorkerSlots = data.Value<int>("worker_slots"),
                Category = data.Value<string>("category") ?? "",
                Tier = data.Value<int>("tier"),
            };
        }
    }

    /// <summary>
    /// Gets a cached building definition by ID.
    /// </summary>
    /// <param name="id">Building definition identifier.</param>
    /// <returns>The building definition when found; otherwise, <c>null</c>.</returns>
    public static BuildingDef? GetBuilding(string id)
    {
        _cache ??= new();
        return _cache.GetValueOrDefault(id);
    }

    /// <summary>
    /// Returns the resource cost table for a building type.
    /// </summary>
    /// <param name="buildingType">Building type identifier.</param>
    /// <returns>The cost mapping for the building, or an empty mapping when unknown.</returns>
    public static Dictionary<string, int> CostFor(string buildingType)
    {
        var def = GetBuilding(buildingType);
        return def?.Cost ?? new Dictionary<string, int>();
    }

    /// <summary>
    /// Sums defense contribution from placed structures in the current game state.
    /// </summary>
    /// <param name="state">Game state containing placed structure instances.</param>
    /// <returns>Total defense score contributed by all known structures.</returns>
    public static int TotalDefense(State.GameState state)
    {
        int total = 0;
        foreach (var (_, buildingType) in state.Structures)
        {
            var def = GetBuilding(buildingType);
            if (def != null) total += def.Defense;
        }
        return total;
    }

    /// <summary>
    /// Computes total per-day resource production from owned buildings and their counts.
    /// </summary>
    /// <param name="state">Game state containing building ownership counts.</param>
    /// <returns>A resource-to-amount mapping for one day of production.</returns>
    public static Dictionary<string, int> DailyProduction(State.GameState state)
    {
        var output = new Dictionary<string, int>();
        foreach (var key in State.GameState.ResourceKeys)
            output[key] = 0;

        foreach (var (buildingType, count) in state.Buildings)
        {
            if (count <= 0) continue;
            var def = GetBuilding(buildingType);
            if (def == null) continue;
            foreach (var (resource, amount) in def.Production)
            {
                output[resource] = output.GetValueOrDefault(resource, 0) + amount * count;
            }
        }
        return output;
    }

    private static Dictionary<string, int> ParseResourceDict(JToken? token)
    {
        var result = new Dictionary<string, int>();
        if (token is JObject obj)
        {
            foreach (var prop in obj.Properties())
                result[prop.Name] = prop.Value.Value<int>();
        }
        return result;
    }
}

/// <summary>
/// Immutable-style data contract describing a building entry loaded from building data files.
/// </summary>
public class BuildingDef
{
    /// <summary>
    /// Stable building identifier used by save data and runtime lookups.
    /// </summary>
    public string Id { get; set; } = "";

    /// <summary>
    /// Player-facing building display name.
    /// </summary>
    public string Name { get; set; } = "";

    /// <summary>
    /// Descriptive text shown in UI tooltips and details panels.
    /// </summary>
    public string Description { get; set; } = "";

    /// <summary>
    /// Resource costs required to construct one instance of the building.
    /// </summary>
    public Dictionary<string, int> Cost { get; set; } = new();

    /// <summary>
    /// Resource outputs generated per day by one instance of the building.
    /// </summary>
    public Dictionary<string, int> Production { get; set; } = new();

    /// <summary>
    /// Defensive value contributed by one instance of the building.
    /// </summary>
    public int Defense { get; set; }

    /// <summary>
    /// Number of worker slots provided by one instance of the building.
    /// </summary>
    public int WorkerSlots { get; set; }

    /// <summary>
    /// Content category tag used for grouping and progression logic.
    /// </summary>
    public string Category { get; set; } = "";

    /// <summary>
    /// Progression tier for gating or sorting building availability.
    /// </summary>
    public int Tier { get; set; }
}
