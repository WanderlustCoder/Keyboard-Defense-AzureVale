using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Enemy affix system for stat modifications.
/// Ported from sim/affixes.gd.
/// </summary>
public static class Affixes
{
    public static readonly Dictionary<string, AffixDef> Registry = new()
    {
        ["swift"] = new("Swift", 1, 0, 0, 20, 0, null),
        ["armored"] = new("Armored", 1, 0, 5, 0, 0, null),
        ["resilient"] = new("Resilient", 1, 20, 0, 0, 0, null),
        ["shielded"] = new("Shielded", 2, 0, 0, 0, 0, "first_hit_immune"),
        ["splitting"] = new("Splitting", 2, -10, 0, 0, 0, "split_on_death"),
        ["regenerating"] = new("Regenerating", 2, 0, 0, 0, 0, "regen"),
        ["enraged"] = new("Enraged", 3, 0, 0, 10, 50, null),
        ["vampiric"] = new("Vampiric", 3, 0, 0, 0, 0, "lifesteal"),
    };

    public static void ApplyAffix(Dictionary<string, object> enemy, string affixId)
    {
        if (!Registry.TryGetValue(affixId, out var def)) return;

        enemy["affix"] = affixId;

        if (def.HpBonus != 0)
        {
            int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
            int bonus = (int)(hp * def.HpBonus / 100.0);
            enemy["hp"] = hp + bonus;
            enemy["max_hp"] = Convert.ToInt32(enemy.GetValueOrDefault("max_hp", 0)) + bonus;
        }

        if (def.ArmorBonus != 0)
            enemy["armor"] = Convert.ToInt32(enemy.GetValueOrDefault("armor", 0)) + def.ArmorBonus;

        if (def.SpeedBonus != 0)
            enemy["speed"] = Convert.ToInt32(enemy.GetValueOrDefault("speed", 0)) + def.SpeedBonus;

        if (def.DamageBonus != 0)
            enemy["damage"] = Convert.ToInt32(enemy.GetValueOrDefault("damage", 0)) + def.DamageBonus;

        if (def.Special != null)
            enemy[$"affix_{def.Special}"] = true;
    }

    public static List<string> GetAvailableAffixes(int day)
    {
        return Registry
            .Where(kv =>
            {
                int tier = kv.Value.Tier;
                if (tier == 1) return true;
                if (tier == 2) return day >= 4;
                return day >= 7;
            })
            .Select(kv => kv.Key)
            .ToList();
    }

    public static string? RollAffix(GameState state, int day)
    {
        var available = GetAvailableAffixes(day);
        if (available.Count == 0) return null;

        // 30% chance for affix
        int roll = SimRng.RollRange(state, 1, 100);
        if (roll > 30) return null;

        int index = SimRng.RollRange(state, 0, available.Count - 1);
        return available[index];
    }
}

public record AffixDef(
    string Name,
    int Tier,
    int HpBonus,
    int ArmorBonus,
    int SpeedBonus,
    int DamageBonus,
    string? Special);
