using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Damage calculation engine with type interactions.
/// Ported from sim/damage_types.gd.
/// </summary>
public static class DamageTypes
{
    public static int CalculateDamage(int baseDamage, DamageType damageType, Dictionary<string, object> enemy)
    {
        int armor = Convert.ToInt32(enemy.GetValueOrDefault("armor", 0));
        int damage = baseDamage;

        // Type-specific armor interaction
        damage = damageType switch
        {
            DamageType.Magical => damage, // Ignores armor
            DamageType.Pure => damage, // Ignores everything
            DamageType.Poison => Math.Max(1, damage - armor / 2), // Half armor
            _ => Math.Max(1, damage - armor), // Standard armor reduction
        };

        // Type interaction bonuses
        string affix = enemy.GetValueOrDefault("affix", "")?.ToString() ?? "";
        damage = damageType switch
        {
            DamageType.Holy when affix != "" => (int)(damage * 1.5), // 1.5x vs affixed
            DamageType.Lightning => (int)(damage * 1.2), // Default lightning bonus
            DamageType.Fire when HasEffect(enemy, "frozen") => damage * 3, // 3x vs frozen
            _ => damage,
        };

        return Math.Max(1, damage);
    }

    public static int CalculateChainDamage(int baseDamage, int jumpIndex, double falloff = 0.8)
    {
        return Math.Max(1, (int)(baseDamage * Math.Pow(falloff, jumpIndex)));
    }

    public static int CalculateAoeDamage(int baseDamage, int distanceFromCenter, int maxRadius)
    {
        if (distanceFromCenter == 0) return baseDamage;
        double falloff = 1.0 - (double)distanceFromCenter / (maxRadius + 1);
        return Math.Max(1, (int)(baseDamage * Math.Max(0.3, falloff)));
    }

    public static int CalculateDotTickDamage(int baseDot, int stacks)
    {
        return baseDot * Math.Max(1, stacks);
    }

    public static string DamageTypeToString(DamageType type) => type switch
    {
        DamageType.Physical => "Physical",
        DamageType.Magical => "Magical",
        DamageType.Holy => "Holy",
        DamageType.Lightning => "Lightning",
        DamageType.Poison => "Poison",
        DamageType.Cold => "Cold",
        DamageType.Fire => "Fire",
        DamageType.Siege => "Siege",
        DamageType.Nature => "Nature",
        DamageType.Pure => "Pure",
        _ => "Unknown",
    };

    private static bool HasEffect(Dictionary<string, object> enemy, string effectId)
    {
        if (enemy.GetValueOrDefault("effects") is not List<Dictionary<string, object>> effects)
            return false;
        foreach (var eff in effects)
        {
            if (eff.GetValueOrDefault("id")?.ToString() == effectId)
                return true;
        }
        return false;
    }
}
