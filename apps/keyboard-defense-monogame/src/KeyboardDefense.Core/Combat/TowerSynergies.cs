using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Tower synergy detection and bonus calculation.
/// Ported from sim/tower_synergies.gd.
/// </summary>
public static class TowerSynergies
{
    public static readonly Dictionary<string, SynergyDef> Synergies = new()
    {
        ["fire_wind"] = new("Inferno Gale", new[] { "fire", "wind" }, "pair",
            new Dictionary<string, double> { ["damage_mult"] = 1.3, ["burn_duration"] = 1.5 }),
        ["ice_lightning"] = new("Shatter Storm", new[] { "ice", "lightning" }, "pair",
            new Dictionary<string, double> { ["damage_mult"] = 1.25, ["stun_chance"] = 0.15 }),
        ["holy_nature"] = new("Sacred Grove", new[] { "holy", "nature" }, "pair",
            new Dictionary<string, double> { ["heal_bonus"] = 1.2, ["damage_mult"] = 1.15 }),
        ["arcane_cluster"] = new("Arcane Nexus", new[] { "arcane", "arcane", "arcane" }, "cluster",
            new Dictionary<string, double> { ["damage_mult"] = 1.5, ["range_bonus"] = 1.2 }),
        ["siege_support"] = new("Fortified Battery", new[] { "siege", "support" }, "supported",
            new Dictionary<string, double> { ["damage_mult"] = 1.4, ["attack_speed"] = 1.2 }),
        ["poison_fire"] = new("Toxic Inferno", new[] { "poison", "fire" }, "pair",
            new Dictionary<string, double> { ["dot_mult"] = 2.0 }),
        ["legion"] = new("Legion's Might", new[] { "summoner", "summoner" }, "pair",
            new Dictionary<string, double> { ["summon_bonus"] = 1, ["damage_mult"] = 1.2 }),
    };

    public static List<ActiveSynergy> DetectSynergies(GameState state)
    {
        var active = new List<ActiveSynergy>();
        var structures = state.Structures;

        foreach (var (synergyId, def) in Synergies)
        {
            switch (def.Pattern)
            {
                case "pair":
                    DetectPairSynergies(state, synergyId, def, structures, active);
                    break;
                case "cluster":
                    DetectClusterSynergies(state, synergyId, def, structures, active);
                    break;
                case "supported":
                    DetectSupportedSynergies(state, synergyId, def, structures, active);
                    break;
            }
        }
        return active;
    }

    public static double GetDamageMultiplier(List<ActiveSynergy> synergies, GridPoint towerPos)
    {
        double mult = 1.0;
        foreach (var synergy in synergies)
        {
            if (synergy.AffectedPositions.Contains(towerPos))
            {
                mult *= synergy.Bonuses.GetValueOrDefault("damage_mult", 1.0);
            }
        }
        return mult;
    }

    private static void DetectPairSynergies(
        GameState state, string synergyId, SynergyDef def,
        Dictionary<int, string> structures, List<ActiveSynergy> active)
    {
        foreach (var (indexA, typeA) in structures)
        {
            string categoryA = GetTowerCategory(typeA);
            if (categoryA != def.RequiredTypes[0]) continue;

            var posA = GridPoint.FromIndex(indexA, state.MapW);
            foreach (var neighbor in GetNeighbors4(posA, state.MapW, state.MapH))
            {
                int ni = neighbor.ToIndex(state.MapW);
                if (!structures.TryGetValue(ni, out var typeB)) continue;
                string categoryB = GetTowerCategory(typeB);
                if (categoryB != def.RequiredTypes[1]) continue;

                active.Add(new ActiveSynergy
                {
                    SynergyId = synergyId,
                    Name = def.Name,
                    Bonuses = def.Bonuses,
                    AffectedPositions = new HashSet<GridPoint> { posA, neighbor }
                });
            }
        }
    }

    private static void DetectClusterSynergies(
        GameState state, string synergyId, SynergyDef def,
        Dictionary<int, string> structures, List<ActiveSynergy> active)
    {
        string requiredType = def.RequiredTypes[0];
        int requiredCount = def.RequiredTypes.Length;

        foreach (var (index, type) in structures)
        {
            if (GetTowerCategory(type) != requiredType) continue;
            var pos = GridPoint.FromIndex(index, state.MapW);
            var cluster = new HashSet<GridPoint> { pos };

            foreach (var neighbor in GetNeighbors4(pos, state.MapW, state.MapH))
            {
                int ni = neighbor.ToIndex(state.MapW);
                if (structures.TryGetValue(ni, out var nType) && GetTowerCategory(nType) == requiredType)
                    cluster.Add(neighbor);
            }

            if (cluster.Count >= requiredCount)
            {
                active.Add(new ActiveSynergy
                {
                    SynergyId = synergyId,
                    Name = def.Name,
                    Bonuses = def.Bonuses,
                    AffectedPositions = cluster
                });
            }
        }
    }

    private static void DetectSupportedSynergies(
        GameState state, string synergyId, SynergyDef def,
        Dictionary<int, string> structures, List<ActiveSynergy> active)
    {
        foreach (var (index, type) in structures)
        {
            if (GetTowerCategory(type) != def.RequiredTypes[0]) continue;
            var pos = GridPoint.FromIndex(index, state.MapW);

            foreach (var neighbor in GetNeighbors4(pos, state.MapW, state.MapH))
            {
                int ni = neighbor.ToIndex(state.MapW);
                if (!structures.TryGetValue(ni, out var nType)) continue;
                if (GetTowerCategory(nType) != def.RequiredTypes[1]) continue;

                active.Add(new ActiveSynergy
                {
                    SynergyId = synergyId,
                    Name = def.Name,
                    Bonuses = def.Bonuses,
                    AffectedPositions = new HashSet<GridPoint> { pos, neighbor }
                });
            }
        }
    }

    private static string GetTowerCategory(string towerType)
    {
        if (TowerTypes.TowerStats.TryGetValue(towerType, out var def))
            return def.Category.ToString().ToLowerInvariant();
        return towerType;
    }

    private static List<GridPoint> GetNeighbors4(GridPoint pos, int w, int h)
    {
        var results = new List<GridPoint>();
        GridPoint[] offsets = { new(1, 0), new(-1, 0), new(0, 1), new(0, -1) };
        foreach (var offset in offsets)
        {
            var neighbor = pos + offset;
            if (neighbor.X >= 0 && neighbor.Y >= 0 && neighbor.X < w && neighbor.Y < h)
                results.Add(neighbor);
        }
        return results;
    }
}

public record SynergyDef(string Name, string[] RequiredTypes, string Pattern, Dictionary<string, double> Bonuses);

public class ActiveSynergy
{
    public string SynergyId { get; set; } = "";
    public string Name { get; set; } = "";
    public Dictionary<string, double> Bonuses { get; set; } = new();
    public HashSet<GridPoint> AffectedPositions { get; set; } = new();
}
