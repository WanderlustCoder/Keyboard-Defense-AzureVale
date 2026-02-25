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
    /// <summary>
    /// Relation score at or below which a faction is considered hostile.
    /// </summary>
    public const int RelationHostile = -50;

    /// <summary>
    /// Relation score at or below which a faction is considered unfriendly.
    /// </summary>
    public const int RelationUnfriendly = -20;

    /// <summary>
    /// Relation score at or below which a faction is considered neutral.
    /// </summary>
    public const int RelationNeutral = 20;

    /// <summary>
    /// Relation score at or below which a faction is considered friendly.
    /// </summary>
    public const int RelationFriendly = 50;

    /// <summary>
    /// Relation score at or above which a faction is considered allied.
    /// </summary>
    public const int RelationAllied = 80;

    // Relation change amounts
    /// <summary>
    /// Standard relation increase granted by a successful trade action.
    /// </summary>
    public const int RelationChangeTrade = 10;

    /// <summary>
    /// Standard relation increase granted by tribute or aid actions.
    /// </summary>
    public const int RelationChangeTribute = 15;

    /// <summary>
    /// Standard relation increase granted by formal alliance actions.
    /// </summary>
    public const int RelationChangeAlliance = 25;

    /// <summary>
    /// Relation penalty applied when a pact is broken.
    /// </summary>
    public const int RelationChangeBrokenPact = -30;

    private static Dictionary<string, FactionDef>? _cache;

    /// <summary>
    /// Loads faction definitions from <c>factions.json</c> in the supplied data directory.
    /// </summary>
    /// <param name="dataDir">Root data directory containing faction definition files.</param>
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

    /// <summary>
    /// Returns the list of faction IDs currently available in the loaded cache.
    /// </summary>
    /// <returns>Faction identifiers in cache order.</returns>
    public static IReadOnlyList<string> GetFactionIds()
    {
        _cache ??= new();
        return new List<string>(_cache.Keys);
    }

    /// <summary>
    /// Gets a faction definition by ID.
    /// </summary>
    /// <param name="id">Faction identifier.</param>
    /// <returns>The faction definition when found; otherwise, <c>null</c>.</returns>
    public static FactionDef? GetFaction(string id)
    {
        _cache ??= new();
        return _cache.GetValueOrDefault(id);
    }

    /// <summary>
    /// Resolves a faction display name, falling back to the ID when not found.
    /// </summary>
    /// <param name="id">Faction identifier.</param>
    /// <returns>Faction name when known; otherwise the original identifier.</returns>
    public static string GetFactionName(string id) => GetFaction(id)?.Name ?? id;

    /// <summary>
    /// Gets the current relation score for a faction from save state.
    /// </summary>
    /// <param name="state">Game state containing faction relation values.</param>
    /// <param name="factionId">Faction identifier.</param>
    /// <returns>Current relation score, or <c>0</c> when missing.</returns>
    public static int GetRelation(GameState state, string factionId)
        => state.FactionRelations.GetValueOrDefault(factionId, 0);

    /// <summary>
    /// Sets a faction relation score, clamped to the inclusive range <c>-100</c> to <c>100</c>.
    /// </summary>
    /// <param name="state">Game state containing faction relation values.</param>
    /// <param name="factionId">Faction identifier.</param>
    /// <param name="value">Target relation score before clamping.</param>
    public static void SetRelation(GameState state, string factionId, int value)
        => state.FactionRelations[factionId] = Math.Clamp(value, -100, 100);

    /// <summary>
    /// Applies a delta to a faction relation score and writes the clamped result.
    /// </summary>
    /// <param name="state">Game state containing faction relation values.</param>
    /// <param name="factionId">Faction identifier.</param>
    /// <param name="delta">Signed amount to add to the current relation score.</param>
    public static void ChangeRelation(GameState state, string factionId, int delta)
    {
        int current = GetRelation(state, factionId);
        SetRelation(state, factionId, current + delta);
    }

    /// <summary>
    /// Converts a numeric relation score into a status bucket string.
    /// </summary>
    /// <param name="relation">Relation score to classify.</param>
    /// <returns>One of <c>hostile</c>, <c>unfriendly</c>, <c>neutral</c>, <c>friendly</c>, or <c>allied</c>.</returns>
    public static string GetRelationStatus(int relation)
    {
        if (relation <= RelationHostile) return "hostile";
        if (relation <= RelationUnfriendly) return "unfriendly";
        if (relation <= RelationNeutral) return "neutral";
        if (relation <= RelationFriendly) return "friendly";
        return "allied";
    }

    /// <summary>
    /// Determines whether the specified faction is currently hostile to the player.
    /// </summary>
    /// <param name="state">Game state containing faction relation values.</param>
    /// <param name="factionId">Faction identifier.</param>
    /// <returns><c>true</c> when relation is hostile; otherwise, <c>false</c>.</returns>
    public static bool IsHostile(GameState state, string factionId)
        => GetRelation(state, factionId) <= RelationHostile;

    /// <summary>
    /// Determines whether the specified faction is currently allied with the player.
    /// </summary>
    /// <param name="state">Game state containing faction relation values.</param>
    /// <param name="factionId">Faction identifier.</param>
    /// <returns><c>true</c> when relation is allied; otherwise, <c>false</c>.</returns>
    public static bool IsAllied(GameState state, string factionId)
        => GetRelation(state, factionId) >= RelationAllied;

    /// <summary>
    /// Initializes relation entries in state using each faction's configured base relation.
    /// </summary>
    /// <param name="state">Game state to initialize.</param>
    public static void InitFactionState(GameState state)
    {
        _cache ??= new();
        foreach (var (id, def) in _cache)
        {
            state.FactionRelations[id] = def.BaseRelation;
        }
    }

    /// <summary>
    /// Moves each faction relation one point per day toward its configured base relation.
    /// </summary>
    /// <param name="state">Game state containing relation values to decay.</param>
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

/// <summary>
/// Data contract describing a faction definition loaded from faction data files.
/// </summary>
public class FactionDef
{
    /// <summary>
    /// Stable faction identifier used by save data and relation maps.
    /// </summary>
    public string Id { get; set; } = "";

    /// <summary>
    /// Player-facing faction display name.
    /// </summary>
    public string Name { get; set; } = "";

    /// <summary>
    /// Personality tag used by diplomacy and behavior systems.
    /// </summary>
    public string Personality { get; set; } = "neutral";

    /// <summary>
    /// Baseline relation score used for initialization and decay target.
    /// </summary>
    public int BaseRelation { get; set; }
}
