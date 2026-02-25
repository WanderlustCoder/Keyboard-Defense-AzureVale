using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Additional tower synergy detection beyond TowerSynergies.
/// Ported from sim/synergy_detector.gd.
/// </summary>
public static class SynergyDetector
{
    private static readonly IReadOnlyList<SynergyDef> SynergyDefs =
    [
        new("fire_ice", "Fire & Ice", ["frost", "fire"], 2, 1.2),
        new("arrow_rain", "Arrow Rain", ["arrow", "arrow", "arrow"], 3, 1.3),
        new("arcane_support", "Arcane Support", ["arcane", "support"], 2, 1.25),
        new("holy_purification", "Holy Purification", ["holy", "purifier"], 2, 1.35),
        new("chain_reaction", "Chain Reaction", ["tesla", "tesla"], 2, 1.2),
        new("kill_box", "Kill Box", ["cannon", "frost"], 2, 1.4),
        new("legion", "Legion", ["summoner", "summoner"], 2, 1.2),
        new("titan_slayer", "Titan Slayer", ["siege", "holy"], 2, 1.3),
    ];

    private static readonly Dictionary<string, SynergyDef> SynergyDefsById =
        SynergyDefs.ToDictionary(def => def.Id);

    /// <summary>
    /// Exposes the additional synergy definitions keyed by synergy id for runtime lookups.
    /// </summary>
    public static readonly Dictionary<string, DetectedSynergyDef> ExtraSynergies =
        SynergyDefs.ToDictionary(def => def.Id, def => def.ToDetectedDef());

    /// <summary>
    /// Detects which extra synergies are active by finding connected tower-type matches on the grid.
    /// </summary>
    public static List<string> DetectActiveSynergies(GameState state)
    {
        var towerPlacements = state.Structures
            .Select(entry => new TowerPlacement(
                entry.Key,
                entry.Value,
                GridPoint.FromIndex(entry.Key, state.MapW)))
            .ToList();
        var active = new List<string>();

        foreach (var synergy in SynergyDefs)
        {
            if (HasConnectedMatch(towerPlacements, synergy))
                active.Add(synergy.Id);
        }

        return active;
    }

    /// <summary>
    /// Computes the combined damage multiplier by multiplying each active synergy multiplier.
    /// </summary>
    public static double GetSynergyDamageMultiplier(List<string> activeSynergies)
    {
        double mult = 1.0;
        foreach (var id in activeSynergies)
        {
            if (SynergyDefsById.TryGetValue(id, out var synergy))
                mult *= synergy.DamageMultiplier;
        }

        return mult;
    }

    private static bool HasConnectedMatch(List<TowerPlacement> towers, SynergyDef synergy)
    {
        if (towers.Count < synergy.MinCount)
            return false;

        var requiredTypes = synergy.RequiredTypes;
        if (requiredTypes.Length == 0)
            return false;

        var selected = new List<TowerPlacement>(requiredTypes.Length);
        var usedTowerIndices = new HashSet<int>();
        return TryMatchRequirements(0, requiredTypes, towers, selected, usedTowerIndices);
    }

    private static bool TryMatchRequirements(
        int requiredIndex,
        string[] requiredTypes,
        List<TowerPlacement> towers,
        List<TowerPlacement> selected,
        HashSet<int> usedTowerIndices)
    {
        if (requiredIndex >= requiredTypes.Length)
            return true;

        string requiredType = requiredTypes[requiredIndex];
        foreach (var tower in towers)
        {
            if (tower.Type != requiredType || usedTowerIndices.Contains(tower.Index))
                continue;

            if (selected.Count > 0 && !selected.Any(existing => AreAdjacent(existing.Pos, tower.Pos)))
                continue;

            selected.Add(tower);
            usedTowerIndices.Add(tower.Index);

            if (TryMatchRequirements(requiredIndex + 1, requiredTypes, towers, selected, usedTowerIndices))
                return true;

            usedTowerIndices.Remove(tower.Index);
            selected.RemoveAt(selected.Count - 1);
        }

        return false;
    }

    private static bool AreAdjacent(GridPoint a, GridPoint b)
        => Math.Abs(a.X - b.X) + Math.Abs(a.Y - b.Y) == 1;

    private readonly record struct SynergyDef(
        string Id,
        string Name,
        string[] RequiredTypes,
        int MinCount,
        double DamageMultiplier)
    {
        /// <summary>
        /// Converts the internal synergy definition into the public detected-synergy payload shape.
        /// </summary>
        public DetectedSynergyDef ToDetectedDef()
            => new(Name, RequiredTypes, MinCount, DamageMultiplier);
    }

    private readonly record struct TowerPlacement(int Index, string Type, GridPoint Pos);
}

/// <summary>
/// Represents a detected synergy contract with display name, required tower types, and damage bonus.
/// </summary>
public record DetectedSynergyDef(string Name, string[] RequiredTypes, int MinCount, double DamageMultiplier);
