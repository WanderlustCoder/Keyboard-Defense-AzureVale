using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Enemy factory and stat scaling system.
/// Ported from sim/enemies.gd.
/// </summary>
public static class Enemies
{
    public static readonly Dictionary<string, EnemyKindDef> EnemyKinds = new()
    {
        ["scout"] = new() { Speed = 2, Armor = 0, HpBonus = 0, Glyph = "s" },
        ["raider"] = new() { Speed = 1, Armor = 0, HpBonus = 0, Glyph = "r" },
        ["armored"] = new() { Speed = 1, Armor = 2, HpBonus = 3, Glyph = "A" },
        ["swarm"] = new() { Speed = 2, Armor = 0, HpBonus = -1, Glyph = "w" },
        ["tank"] = new() { Speed = 0, Armor = 3, HpBonus = 5, Glyph = "T" },
        ["berserker"] = new() { Speed = 1, Armor = 0, HpBonus = 2, Glyph = "B" },
        ["phantom"] = new() { Speed = 2, Armor = 0, HpBonus = 0, Glyph = "P" },
        ["champion"] = new() { Speed = 1, Armor = 1, HpBonus = 4, Glyph = "C" },
        ["healer"] = new() { Speed = 1, Armor = 0, HpBonus = 1, Glyph = "H" },
        ["elite"] = new() { Speed = 1, Armor = 1, HpBonus = 3, Glyph = "E" },
    };

    public static readonly Dictionary<string, EnemyKindDef> BossKinds = new()
    {
        ["forest_guardian"] = new() { Speed = 0, Armor = 2, HpBonus = 10, Glyph = "G" },
        ["stone_golem"] = new() { Speed = 0, Armor = 5, HpBonus = 15, Glyph = "S" },
        ["fen_seer"] = new() { Speed = 1, Armor = 1, HpBonus = 8, Glyph = "F" },
        ["sunlord"] = new() { Speed = 1, Armor = 3, HpBonus = 20, Glyph = "L" },
    };

    public static Dictionary<string, object> MakeEnemy(GameState state, string kind, GridPoint pos, string word, int day)
    {
        var def = EnemyKinds.GetValueOrDefault(kind) ?? new EnemyKindDef();
        int baseHp = Balance.SimBalance.CalculateEnemyHp(day, state.Threat) + def.HpBonus;

        var enemy = new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = kind,
            ["pos_x"] = pos.X,
            ["pos_y"] = pos.Y,
            ["word"] = word,
            ["hp"] = baseHp,
            ["max_hp"] = baseHp,
            ["armor"] = def.Armor,
            ["speed"] = def.Speed,
            ["glyph"] = def.Glyph,
            ["alive"] = true,
            ["effects"] = new List<Dictionary<string, object>>(),
            ["affix"] = "",
        };
        return enemy;
    }

    public static Dictionary<string, object> MakeBoss(GameState state, string kind, GridPoint pos, string word, int day)
    {
        var def = BossKinds.GetValueOrDefault(kind) ?? new EnemyKindDef();
        int baseHp = Balance.SimBalance.CalculateBossHp(day, state.Threat, def.HpBonus);

        var enemy = new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = kind,
            ["pos_x"] = pos.X,
            ["pos_y"] = pos.Y,
            ["word"] = word,
            ["hp"] = baseHp,
            ["max_hp"] = baseHp,
            ["armor"] = def.Armor,
            ["speed"] = def.Speed,
            ["glyph"] = def.Glyph,
            ["alive"] = true,
            ["is_boss"] = true,
            ["effects"] = new List<Dictionary<string, object>>(),
            ["affix"] = "",
        };
        return enemy;
    }

    public static Dictionary<string, object> ApplyDamage(Dictionary<string, object> enemy, int damage)
    {
        int armor = Convert.ToInt32(enemy.GetValueOrDefault("armor", 0));
        int effectiveDamage = Math.Max(1, damage - armor);

        // Phantom evasion
        if (enemy.GetValueOrDefault("kind", "")?.ToString() == "phantom")
        {
            if (!enemy.ContainsKey("_phantom_evaded"))
            {
                enemy["_phantom_evaded"] = true;
                return enemy; // First hit evaded
            }
        }

        // Shield affix
        if (enemy.GetValueOrDefault("affix", "")?.ToString() == "shielded")
        {
            if (!enemy.ContainsKey("_shield_used"))
            {
                enemy["_shield_used"] = true;
                return enemy; // First hit absorbed
            }
        }

        // Ghostly affix: 50% damage reduction
        if (enemy.GetValueOrDefault("affix", "")?.ToString() == "ghostly")
        {
            effectiveDamage = Math.Max(1, effectiveDamage / 2);
        }

        int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
        hp -= effectiveDamage;
        enemy["hp"] = hp;
        if (hp <= 0) enemy["alive"] = false;
        return enemy;
    }

    public static Dictionary<string, object> NormalizeEnemy(Dictionary<string, object> enemy)
    {
        enemy.TryAdd("alive", true);
        enemy.TryAdd("effects", new List<Dictionary<string, object>>());
        enemy.TryAdd("affix", "");
        enemy.TryAdd("armor", 0);
        enemy.TryAdd("speed", 1);
        enemy.TryAdd("glyph", "?");
        return enemy;
    }

    public static void EnsureEnemyWords(GameState state)
    {
        foreach (var enemy in state.Enemies)
        {
            if (!enemy.ContainsKey("word") || string.IsNullOrEmpty(enemy["word"]?.ToString()))
            {
                enemy["word"] = "enemy";
            }
        }
    }

    public static Dictionary<string, object> Serialize(Dictionary<string, object> enemy)
    {
        var result = new Dictionary<string, object>(enemy);
        if (result.ContainsKey("effects") && result["effects"] is List<Dictionary<string, object>> effects)
        {
            var serialized = new List<Dictionary<string, object>>();
            foreach (var eff in effects)
                serialized.Add(new Dictionary<string, object>(eff));
            result["effects"] = serialized;
        }
        return result;
    }

    public static Dictionary<string, object> Deserialize(Dictionary<string, object> data)
    {
        return new Dictionary<string, object>(data);
    }
}

public class EnemyKindDef
{
    public int Speed { get; set; } = 1;
    public int Armor { get; set; }
    public int HpBonus { get; set; }
    public string Glyph { get; set; } = "?";
}
