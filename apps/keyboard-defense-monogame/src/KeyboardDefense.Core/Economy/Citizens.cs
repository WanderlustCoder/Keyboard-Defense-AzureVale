using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Economy;

/// <summary>
/// Citizen identity system wrapping workers.
/// Ported from sim/citizens.gd.
/// </summary>
public static class Citizens
{
    private static readonly string[] FirstNames = {
        "Ada", "Bard", "Cleo", "Dane", "Elsa", "Finn", "Gwen", "Hugo",
        "Iris", "Jade", "Knox", "Luna", "Milo", "Nora", "Owen", "Peta"
    };

    private static readonly string[] LastNames = {
        "Stone", "Swift", "Forge", "Bloom", "Thorn", "Frost", "Spark", "Vale",
        "Ash", "Brook", "Clay", "Dale", "Elm", "Flint", "Glen", "Hart"
    };

    private static readonly string[] Professions = {
        "farmer", "woodcutter", "miner", "builder", "scholar", "merchant", "guard", "artisan"
    };

    public static Dictionary<string, object> CreateCitizen(GameState state)
    {
        string firstName = SimRng.Choose(state, FirstNames)?.ToString() ?? "Unknown";
        string lastName = SimRng.Choose(state, LastNames)?.ToString() ?? "Unknown";
        string profession = SimRng.Choose(state, Professions)?.ToString() ?? "farmer";

        return new Dictionary<string, object>
        {
            ["name"] = $"{firstName} {lastName}",
            ["profession"] = profession,
            ["morale"] = 75,
            ["skill_level"] = 1,
            ["skill_xp"] = 0,
            ["assigned_to"] = -1,
        };
    }

    public static double GetProductionBonus(Dictionary<string, object> citizen)
    {
        int morale = Convert.ToInt32(citizen.GetValueOrDefault("morale", 50));
        int skillLevel = Convert.ToInt32(citizen.GetValueOrDefault("skill_level", 1));
        double moraleBonus = morale >= 75 ? 0.1 : morale < 25 ? -0.1 : 0;
        double skillBonus = (skillLevel - 1) * 0.05;
        return 1.0 + moraleBonus + skillBonus;
    }

    public static void TickDaily(Dictionary<string, object> citizen)
    {
        // Gain XP
        int xp = Convert.ToInt32(citizen.GetValueOrDefault("skill_xp", 0)) + 1;
        int level = Convert.ToInt32(citizen.GetValueOrDefault("skill_level", 1));
        int xpNeeded = level * 5;
        if (xp >= xpNeeded && level < 5)
        {
            citizen["skill_level"] = level + 1;
            citizen["skill_xp"] = 0;
        }
        else
        {
            citizen["skill_xp"] = xp;
        }
    }

    public static List<Dictionary<string, object>> GetCitizens(GameState state) => state.Citizens;
    public static int GetCitizenCount(GameState state) => state.Citizens.Count;
}
