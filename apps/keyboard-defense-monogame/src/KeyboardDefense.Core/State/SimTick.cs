using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Balance;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Day advancement and night wave computation.
/// Ported from sim/tick.gd.
/// </summary>
public static class SimTick
{
    private static readonly Dictionary<int, int> NightWaveBaseByDay = new()
    {
        [1] = 2, [2] = 3, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7
    };

    private static readonly string[] NightPrompts =
    {
        "bastion", "banner", "citadel", "ember", "forge",
        "lantern", "rune", "shield", "spear", "ward"
    };

    public static Dictionary<string, object> AdvanceDay(GameState state)
    {
        state.Day++;
        var events = new List<string> { $"Day advanced to {state.Day}." };
        var summary = new List<string>();

        // Calculate production from buildings
        foreach (string key in GameState.ResourceKeys)
        {
            int produced = CalculateProduction(state, key);
            if (produced > 0)
            {
                state.Resources[key] = state.Resources.GetValueOrDefault(key, 0) + produced;
                summary.Add($"{produced} {key}");
            }
        }

        if (summary.Count == 0)
            events.Add("Production: none.");
        else
            events.Add($"Production: +{string.Join(", ", summary)}.");

        // Midgame food bonus
        int bonusFood = SimBalance.MidgameFoodBonus(state);
        if (bonusFood > 0)
        {
            state.Resources["food"] = state.Resources.GetValueOrDefault("food", 0) + bonusFood;
            events.Add($"Midgame supply: +{bonusFood} food.");
        }

        // Apply resource caps
        ApplyResourceCaps(state, events);

        return new Dictionary<string, object>
        {
            ["state"] = state,
            ["events"] = events
        };
    }

    public static string BuildNightPrompt(GameState state)
    {
        var prompt = SimRng.Choose(state, NightPrompts);
        return prompt?.ToString() ?? "";
    }

    public static int ComputeNightWaveTotal(GameState state, int defense)
    {
        int baseWaves = NightWaveBaseByDay.GetValueOrDefault(state.Day, 2 + state.Day / 2);
        int raw = baseWaves + state.Threat - defense;
        return Math.Max(1, raw);
    }

    private static int CalculateProduction(GameState state, string resource)
    {
        int total = 0;
        foreach (var (_, buildingType) in state.Structures)
        {
            // Simple production mapping
            if (resource == "food" && buildingType == "farm") total += 2;
            if (resource == "wood" && buildingType == "lumber") total += 2;
            if (resource == "stone" && buildingType == "quarry") total += 2;
        }
        return total;
    }

    private static void ApplyResourceCaps(GameState state, List<string> events)
    {
        var trimmed = new List<string>();
        foreach (string key in GameState.ResourceKeys)
        {
            int cap = SimBalance.ResourceCap;
            int current = state.Resources.GetValueOrDefault(key, 0);
            if (current > cap)
            {
                int excess = current - cap;
                state.Resources[key] = cap;
                trimmed.Add($"{key} {excess}");
            }
        }
        if (trimmed.Count > 0)
            events.Add($"Storage limits: -{string.Join(", ", trimmed)}.");
    }
}
