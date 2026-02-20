using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Hero type definitions with passive abilities.
/// Ported from sim/hero_types.gd.
/// </summary>
public static class HeroTypes
{
    public static readonly Dictionary<string, HeroDef> Heroes = new()
    {
        ["commander"] = new("Commander", "Boosts tower damage and defense.",
            new() { ["tower_damage"] = 1.15, ["castle_armor"] = 2 }),
        ["scholar"] = new("Scholar", "Improves typing accuracy bonuses.",
            new() { ["accuracy_bonus"] = 1.2, ["xp_mult"] = 1.1 }),
        ["ranger"] = new("Ranger", "Increases exploration and loot.",
            new() { ["exploration_range"] = 2, ["loot_mult"] = 1.25 }),
        ["merchant"] = new("Merchant", "Better trade rates and gold income.",
            new() { ["trade_bonus"] = 0.3, ["gold_mult"] = 1.2 }),
        ["warrior"] = new("Warrior", "Direct combat bonuses.",
            new() { ["damage_mult"] = 1.3, ["crit_chance"] = 0.1 }),
    };

    public static HeroDef? GetHero(string heroId) => Heroes.GetValueOrDefault(heroId);

    public static bool IsValidHero(string heroId) => Heroes.ContainsKey(heroId);

    public static double GetHeroBonus(string? heroId, string bonusKey, double defaultValue = 0)
    {
        if (heroId == null || !Heroes.TryGetValue(heroId, out var hero)) return defaultValue;
        return hero.Bonuses.GetValueOrDefault(bonusKey, defaultValue);
    }

    public static string FormatHeroInfo(string heroId)
    {
        if (!Heroes.TryGetValue(heroId, out var hero)) return "Unknown hero.";
        var bonuses = new List<string>();
        foreach (var (key, value) in hero.Bonuses)
        {
            string formatted = key.Replace("_", " ");
            bonuses.Add(value > 1 ? $"{formatted}: x{value:F2}" : $"{formatted}: +{value}");
        }
        return $"{hero.Name}\n{hero.Description}\nBonuses: {string.Join(", ", bonuses)}";
    }
}

public record HeroDef(string Name, string Description, Dictionary<string, double> Bonuses);
