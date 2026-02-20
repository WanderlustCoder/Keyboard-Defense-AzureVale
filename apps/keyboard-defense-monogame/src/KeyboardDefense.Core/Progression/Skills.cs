using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Skill tree system with passive bonuses.
/// Ported from sim/skills.gd.
/// </summary>
public static class Skills
{
    public static readonly Dictionary<string, SkillDef> Registry = new()
    {
        ["quick_fingers"] = new("Quick Fingers", "Increases typing damage by 10%.",
            "combat", 1, new() { ["damage_mult"] = 1.1 }, null),
        ["iron_walls"] = new("Iron Walls", "Increases castle HP by 20%.",
            "defense", 1, new() { ["hp_mult"] = 1.2 }, null),
        ["efficient_harvest"] = new("Efficient Harvest", "Increases resource production by 15%.",
            "economy", 1, new() { ["production_mult"] = 1.15 }, null),
        ["critical_strike"] = new("Critical Strike", "5% chance for double damage.",
            "combat", 2, new() { ["crit_chance"] = 0.05, ["crit_mult"] = 2.0 }, "quick_fingers"),
        ["fortified_walls"] = new("Fortified Walls", "Towers get +2 armor.",
            "defense", 2, new() { ["tower_armor"] = 2 }, "iron_walls"),
        ["trade_mastery"] = new("Trade Mastery", "Better exchange rates.",
            "economy", 2, new() { ["trade_bonus"] = 0.2 }, "efficient_harvest"),
        ["word_mastery"] = new("Word Mastery", "Longer words deal 25% more damage.",
            "combat", 3, new() { ["long_word_bonus"] = 0.25 }, "critical_strike"),
    };

    public static SkillDef? GetSkill(string skillId) => Registry.GetValueOrDefault(skillId);

    public static bool CanUnlock(GameState state, string skillId)
    {
        if (!Registry.TryGetValue(skillId, out var skill)) return false;
        if (state.UnlockedSkills.Contains(skillId)) return false;
        if (skill.Prerequisite != null && !state.UnlockedSkills.Contains(skill.Prerequisite))
            return false;
        return state.SkillPoints >= skill.Tier;
    }

    public static Dictionary<string, object> UnlockSkill(GameState state, string skillId)
    {
        if (!CanUnlock(state, skillId))
            return new() { ["ok"] = false, ["error"] = "Cannot unlock skill." };

        var skill = Registry[skillId];
        state.SkillPoints -= skill.Tier;
        state.UnlockedSkills.Add(skillId);

        return new()
        {
            ["ok"] = true,
            ["message"] = $"Unlocked {skill.Name}!",
        };
    }

    public static double GetBonusValue(GameState state, string bonusKey, double defaultValue = 0)
    {
        double total = defaultValue;
        foreach (string skillId in state.UnlockedSkills)
        {
            if (!Registry.TryGetValue(skillId, out var skill)) continue;
            if (skill.Bonuses.TryGetValue(bonusKey, out double val))
            {
                if (bonusKey.EndsWith("_mult"))
                    total *= val;
                else
                    total += val;
            }
        }
        return total;
    }

    public static List<string> GetAvailableSkills(GameState state)
    {
        return Registry.Keys.Where(id => CanUnlock(state, id)).ToList();
    }
}

public record SkillDef(string Name, string Description, string Category, int Tier,
    Dictionary<string, double> Bonuses, string? Prerequisite);
