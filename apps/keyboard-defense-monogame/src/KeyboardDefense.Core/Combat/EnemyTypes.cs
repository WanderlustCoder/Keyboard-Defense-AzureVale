using System;
using System.Collections.Generic;
using System.Linq;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Enemy type definitions and registry.
/// Ported from sim/enemy_types.gd.
/// </summary>
public static class EnemyTypes
{
    public enum Tier { Minion = 1, Standard = 2, Elite = 3, Boss = 4 }
    public enum Category { Basic, Fast, Armored, Magic, Support, Siege }
    public enum Region { Evergrove, Stonepass, Mistfen, Sunfields }

    public static readonly Dictionary<string, EnemyTypeDef> Registry = new()
    {
        // Tier 1
        ["raider"] = new("Raider", Tier.Minion, Category.Basic, 20, 0, 40, 1, 5,
            Array.Empty<string>()),
        ["scout"] = new("Scout", Tier.Minion, Category.Fast, 12, 0, 70, 1, 3,
            Array.Empty<string>()),
        ["swarm"] = new("Swarm", Tier.Minion, Category.Basic, 8, 0, 50, 1, 2,
            Array.Empty<string>()),

        // Tier 2
        ["armored"] = new("Armored", Tier.Standard, Category.Armored, 40, 5, 30, 2, 8,
            new[] { "fortified" }),
        ["berserker"] = new("Berserker", Tier.Standard, Category.Basic, 30, 0, 55, 3, 7,
            new[] { "enrage" }),
        ["phantom"] = new("Phantom", Tier.Standard, Category.Magic, 25, 0, 45, 2, 6,
            new[] { "ghostly" }),
        ["healer"] = new("Healer", Tier.Standard, Category.Support, 20, 0, 35, 1, 6,
            new[] { "heal_aura" }),

        // Tier 3
        ["tank"] = new("Tank", Tier.Elite, Category.Armored, 80, 10, 20, 3, 12,
            new[] { "fortified", "taunt" }),
        ["champion"] = new("Champion", Tier.Elite, Category.Basic, 60, 5, 40, 4, 15,
            new[] { "enrage", "rally" }),
        ["elite"] = new("Elite", Tier.Elite, Category.Magic, 50, 3, 50, 3, 12,
            new[] { "ghostly", "spell_shield" }),

        // Tier 4 (bosses handled separately)
        ["warlord"] = new("Warlord", Tier.Boss, Category.Siege, 200, 15, 25, 5, 30,
            new[] { "fortified", "rally", "enrage" }),
    };

    public static EnemyTypeDef? Get(string kind) => Registry.GetValueOrDefault(kind);

    public static List<string> GetByTier(Tier tier)
        => Registry.Where(kv => kv.Value.Tier == tier).Select(kv => kv.Key).ToList();

    public static List<string> GetByCategory(Category category)
        => Registry.Where(kv => kv.Value.Category == category).Select(kv => kv.Key).ToList();

    public static bool HasAbility(string kind, string ability)
    {
        var def = Get(kind);
        return def?.Abilities.Contains(ability) ?? false;
    }
}

public record EnemyTypeDef(
    string Name,
    EnemyTypes.Tier Tier,
    EnemyTypes.Category Category,
    int Hp,
    int Armor,
    int Speed,
    int Damage,
    int Gold,
    string[] Abilities);
