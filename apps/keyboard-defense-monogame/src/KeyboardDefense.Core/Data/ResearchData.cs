using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Tech tree research system.
/// Ported from sim/research.gd.
/// </summary>
public static class ResearchData
{
    public static readonly Dictionary<string, ResearchDef> Registry = new()
    {
        ["improved_walls"] = new("Improved Walls", "defense", 50, 3, null,
            new() { ["wall_hp"] = 2.0 }),
        ["arrow_mastery"] = new("Arrow Mastery", "combat", 80, 4, null,
            new() { ["arrow_damage"] = 1.25 }),
        ["resource_efficiency"] = new("Resource Efficiency", "economy", 60, 3, null,
            new() { ["production_bonus"] = 0.15 }),
        ["advanced_towers"] = new("Advanced Towers", "combat", 120, 5, "arrow_mastery",
            new() { ["unlock_advanced"] = 1.0 }),
        ["fortification"] = new("Fortification", "defense", 100, 4, "improved_walls",
            new() { ["castle_armor"] = 3.0 }),
        ["trade_routes"] = new("Trade Routes", "economy", 80, 3, "resource_efficiency",
            new() { ["trade_bonus"] = 0.2 }),
        ["typing_mastery"] = new("Typing Mastery", "typing", 90, 4, null,
            new() { ["combo_bonus"] = 0.1 }),
        ["legendary_weapons"] = new("Legendary Weapons", "combat", 200, 7, "advanced_towers",
            new() { ["unlock_legendary"] = 1.0 }),
    };

    public static ResearchDef? GetResearch(string id) => Registry.GetValueOrDefault(id);

    public static bool StartResearch(GameState state, string researchId)
    {
        if (!Registry.TryGetValue(researchId, out var def)) return false;
        if (state.CompletedResearch.Contains(researchId)) return false;
        if (!string.IsNullOrEmpty(state.ActiveResearch)) return false;
        if (def.Prerequisite != null && !state.CompletedResearch.Contains(def.Prerequisite)) return false;
        if (state.Gold < def.GoldCost) return false;

        state.Gold -= def.GoldCost;
        state.ActiveResearch = researchId;
        state.ResearchProgress = 0;
        return true;
    }

    public static bool AdvanceResearch(GameState state)
    {
        if (string.IsNullOrEmpty(state.ActiveResearch)) return false;
        if (!Registry.TryGetValue(state.ActiveResearch, out var def)) return false;

        state.ResearchProgress++;
        if (state.ResearchProgress >= def.WavesRequired)
        {
            state.CompletedResearch.Add(state.ActiveResearch);
            state.ActiveResearch = "";
            state.ResearchProgress = 0;
            return true; // Research completed
        }
        return false;
    }

    public static List<string> GetAvailableResearch(GameState state)
    {
        return Registry.Keys
            .Where(id => !state.CompletedResearch.Contains(id)
                && id != state.ActiveResearch
                && (Registry[id].Prerequisite == null || state.CompletedResearch.Contains(Registry[id].Prerequisite!)))
            .ToList();
    }

    public static Dictionary<string, double> GetTotalEffects(GameState state)
    {
        var totals = new Dictionary<string, double>();
        foreach (var id in state.CompletedResearch)
        {
            if (!Registry.TryGetValue(id, out var def)) continue;
            foreach (var (key, value) in def.Effects)
                totals[key] = totals.GetValueOrDefault(key, 0) + value;
        }
        return totals;
    }
}

public record ResearchDef(string Name, string Category, int GoldCost, int WavesRequired,
    string? Prerequisite, Dictionary<string, double> Effects);
