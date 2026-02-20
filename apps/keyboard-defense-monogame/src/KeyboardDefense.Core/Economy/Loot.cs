using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Economy;

/// <summary>
/// Combat loot generation with quality tiers.
/// Ported from sim/loot.gd.
/// </summary>
public static class Loot
{
    public static readonly string[] QualityTiers = { "poor", "normal", "good", "great", "perfect" };

    public static string GetQualityTier(double accuracy)
    {
        if (accuracy >= 1.0) return "perfect";
        if (accuracy >= 0.9) return "great";
        if (accuracy >= 0.75) return "good";
        if (accuracy >= 0.5) return "normal";
        return "poor";
    }

    public static double GetQualityMultiplier(string quality) => quality switch
    {
        "perfect" => 2.0,
        "great" => 1.5,
        "good" => 1.2,
        "normal" => 1.0,
        "poor" => 0.5,
        _ => 1.0,
    };

    public static Dictionary<string, object> GenerateLoot(GameState state, string enemyKind, double accuracy)
    {
        string quality = GetQualityTier(accuracy);
        double multiplier = GetQualityMultiplier(quality);

        int baseGold = GetBaseGold(enemyKind);
        int gold = Math.Max(1, (int)(baseGold * multiplier));

        var loot = new Dictionary<string, object>
        {
            ["gold"] = gold,
            ["quality"] = quality,
            ["multiplier"] = multiplier,
        };

        // Chance for material drop
        int dropRoll = SimRng.RollRange(state, 1, 100);
        int dropChance = quality == "perfect" ? 50 : quality == "great" ? 30 : 15;
        if (dropRoll <= dropChance)
        {
            string material = RollMaterialDrop(state, enemyKind);
            loot["material"] = material;
            loot["material_count"] = 1;
        }

        return loot;
    }

    public static void CollectLoot(GameState state, Dictionary<string, object> loot)
    {
        int gold = Convert.ToInt32(loot.GetValueOrDefault("gold", 0));
        state.Gold += gold;

        if (loot.TryGetValue("material", out var material) && material is string mat)
        {
            int count = Convert.ToInt32(loot.GetValueOrDefault("material_count", 1));
            int current = 0;
            if (state.Inventory.TryGetValue(mat, out var val))
                current = Convert.ToInt32(val);
            state.Inventory[mat] = current + count;
        }
    }

    private static int GetBaseGold(string enemyKind) => enemyKind switch
    {
        "scout" => 3,
        "raider" => 5,
        "armored" => 8,
        "berserker" => 7,
        "phantom" => 6,
        "healer" => 6,
        "tank" => 12,
        "champion" => 15,
        "elite" => 12,
        "warlord" => 30,
        _ => 5,
    };

    private static string RollMaterialDrop(GameState state, string enemyKind)
    {
        string[] materials = enemyKind switch
        {
            "armored" or "tank" => new[] { "iron_ore", "iron_ore", "coal" },
            "phantom" or "elite" => new[] { "crystal", "fire_essence" },
            "healer" => new[] { "herb", "herb", "water" },
            _ => new[] { "iron_ore", "herb", "wood" },
        };
        int index = SimRng.RollRange(state, 0, materials.Length - 1);
        return materials[index];
    }
}
