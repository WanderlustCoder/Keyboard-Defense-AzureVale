using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.State;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Diplomatic relations and faction management.
/// Ported from sim/factions.gd.
/// </summary>
public static class FactionsData
{
    // Relation thresholds
    public const int RelationHostile = -50;
    public const int RelationUnfriendly = -20;
    public const int RelationNeutral = 20;
    public const int RelationFriendly = 50;
    public const int RelationAllied = 80;

    // Relation change amounts
    public const int RelationChangeTrade = 10;
    public const int RelationChangeTribute = 15;
    public const int RelationChangeAlliance = 25;
    public const int RelationChangeBrokenPact = -30;

    private static Dictionary<string, FactionDef>? _cache;

    public static void LoadData(string dataDir)
    {
        var path = Path.Combine(dataDir, "factions.json");
        _cache = new Dictionary<string, FactionDef>();
        if (!File.Exists(path)) return;
        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);
        var factions = root["factions"] as JObject;
        if (factions == null) return;
        foreach (var prop in factions.Properties())
        {
            var data = prop.Value as JObject;
            if (data == null) continue;
            _cache[prop.Name] = new FactionDef
            {
                Id = prop.Name,
                Name = data.Value<string>("name") ?? prop.Name,
                Personality = data.Value<string>("personality") ?? "neutral",
                BaseRelation = data.Value<int>("base_relation"),
            };
        }
    }

    public static IReadOnlyList<string> GetFactionIds()
    {
        _cache ??= new();
        return new List<string>(_cache.Keys);
    }

    public static FactionDef? GetFaction(string id)
    {
        _cache ??= new();
        return _cache.GetValueOrDefault(id);
    }

    public static string GetFactionName(string id) => GetFaction(id)?.Name ?? id;

    public static int GetRelation(GameState state, string factionId)
        => state.FactionRelations.GetValueOrDefault(factionId, 0);

    public static void SetRelation(GameState state, string factionId, int value)
        => state.FactionRelations[factionId] = Math.Clamp(value, -100, 100);

    public static void ChangeRelation(GameState state, string factionId, int delta)
    {
        int current = GetRelation(state, factionId);
        SetRelation(state, factionId, current + delta);
    }

    public static string GetRelationStatus(int relation)
    {
        if (relation <= RelationHostile) return "hostile";
        if (relation <= RelationUnfriendly) return "unfriendly";
        if (relation <= RelationNeutral) return "neutral";
        if (relation <= RelationFriendly) return "friendly";
        return "allied";
    }

    public static bool IsHostile(GameState state, string factionId)
        => GetRelation(state, factionId) <= RelationHostile;

    public static bool IsAllied(GameState state, string factionId)
        => GetRelation(state, factionId) >= RelationAllied;

    public static void InitFactionState(GameState state)
    {
        _cache ??= new();
        foreach (var (id, def) in _cache)
        {
            state.FactionRelations[id] = def.BaseRelation;
        }
    }

    public static void ApplyDailyDecay(GameState state)
    {
        _cache ??= new();
        foreach (var (id, def) in _cache)
        {
            int current = GetRelation(state, id);
            int target = def.BaseRelation;
            if (current > target) ChangeRelation(state, id, -1);
            else if (current < target) ChangeRelation(state, id, 1);
        }
    }
}

public class FactionDef
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Personality { get; set; } = "neutral";
    public int BaseRelation { get; set; }
}
