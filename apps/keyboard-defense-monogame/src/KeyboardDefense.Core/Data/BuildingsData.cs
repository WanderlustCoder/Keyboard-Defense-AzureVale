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

    public static bool IsValid(string buildingType) => ValidTypes.Contains(buildingType);

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

    public static BuildingDef? GetBuilding(string id)
    {
        _cache ??= new();
        return _cache.GetValueOrDefault(id);
    }

    public static Dictionary<string, int> CostFor(string buildingType)
    {
        var def = GetBuilding(buildingType);
        return def?.Cost ?? new Dictionary<string, int>();
    }

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

public class BuildingDef
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public Dictionary<string, int> Cost { get; set; } = new();
    public Dictionary<string, int> Production { get; set; } = new();
    public int Defense { get; set; }
    public int WorkerSlots { get; set; }
    public string Category { get; set; } = "";
    public int Tier { get; set; }
}
