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
    public static readonly Dictionary<string, DetectedSynergyDef> ExtraSynergies = new()
    {
        ["fire_ice"] = new("Fire & Ice", new[] { "frost", "fire" }, 2, 1.2),
        ["arrow_rain"] = new("Arrow Rain", new[] { "arrow", "arrow", "arrow" }, 3, 1.3),
        ["arcane_support"] = new("Arcane Support", new[] { "arcane", "support" }, 2, 1.25),
        ["holy_purification"] = new("Holy Purification", new[] { "holy", "purifier" }, 2, 1.35),
        ["chain_reaction"] = new("Chain Reaction", new[] { "tesla", "tesla" }, 2, 1.2),
        ["kill_box"] = new("Kill Box", new[] { "cannon", "frost" }, 2, 1.4),
        ["legion"] = new("Legion", new[] { "summoner", "summoner" }, 2, 1.2),
        ["titan_slayer"] = new("Titan Slayer", new[] { "siege", "holy" }, 2, 1.3),
    };

    public static List<string> DetectActiveSynergies(GameState state)
    {
        var towerTypes = state.Structures.Values.ToList();
        var active = new List<string>();

        foreach (var (synergyId, def) in ExtraSynergies)
        {
            var remaining = new List<string>(towerTypes);
            bool allFound = true;
            foreach (var required in def.RequiredTypes)
            {
                if (remaining.Remove(required)) continue;
                allFound = false;
                break;
            }
            if (allFound) active.Add(synergyId);
        }
        return active;
    }

    public static double GetSynergyDamageMultiplier(List<string> activeSynergies)
    {
        double mult = 1.0;
        foreach (var id in activeSynergies)
        {
            if (ExtraSynergies.TryGetValue(id, out var def))
                mult *= def.DamageMultiplier;
        }
        return mult;
    }
}

public record DetectedSynergyDef(string Name, string[] RequiredTypes, int MinCount, double DamageMultiplier);
