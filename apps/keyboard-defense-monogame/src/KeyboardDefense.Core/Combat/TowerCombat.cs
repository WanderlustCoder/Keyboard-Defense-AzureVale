using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Tower attack dispatching and damage application.
/// Ported from sim/tower_combat.gd.
/// </summary>
public static class TowerCombat
{
    public static List<string> ProcessTowerAttacks(
        GameState state,
        List<Dictionary<string, object>> towers,
        List<Dictionary<string, object>> enemies)
    {
        var events = new List<string>();
        foreach (var tower in towers)
        {
            string category = tower.GetValueOrDefault("category")?.ToString() ?? "single";
            switch (category)
            {
                case "single":
                    ProcessSingleAttack(state, tower, enemies, events);
                    break;
                case "multi":
                    ProcessMultiAttack(state, tower, enemies, events);
                    break;
                case "aoe":
                    ProcessAoeAttack(state, tower, enemies, events);
                    break;
                case "chain":
                    ProcessChainAttack(state, tower, enemies, events);
                    break;
                case "support":
                    break; // Support towers buff others
                case "summoner":
                    break; // Handled by summoned units
                default:
                    ProcessSingleAttack(state, tower, enemies, events);
                    break;
            }
        }
        return events;
    }

    public static void ProcessSingleAttack(
        GameState state,
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies,
        List<string> events)
    {
        var target = Targeting.FindTarget(state, tower, enemies);
        if (target == null) return;

        int damage = Convert.ToInt32(tower.GetValueOrDefault("damage", 0));
        var dmgType = ParseDamageType(tower.GetValueOrDefault("damage_type")?.ToString());
        int finalDamage = DamageTypes.CalculateDamage(damage, dmgType, target);

        Enemies.ApplyDamage(target, finalDamage);
        string towerName = tower.GetValueOrDefault("name")?.ToString() ?? "Tower";
        string enemyWord = target.GetValueOrDefault("word")?.ToString() ?? "enemy";
        events.Add($"{towerName} hits {enemyWord} for {finalDamage}.");
    }

    public static void ProcessMultiAttack(
        GameState state,
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies,
        List<string> events)
    {
        int count = Convert.ToInt32(tower.GetValueOrDefault("multi_count", 2));
        var targets = Targeting.FindMultiTargets(state, tower, enemies, count);
        int damage = Convert.ToInt32(tower.GetValueOrDefault("damage", 0));
        var dmgType = ParseDamageType(tower.GetValueOrDefault("damage_type")?.ToString());
        string towerName = tower.GetValueOrDefault("name")?.ToString() ?? "Tower";

        foreach (var target in targets)
        {
            int finalDamage = DamageTypes.CalculateDamage(damage, dmgType, target);
            Enemies.ApplyDamage(target, finalDamage);
        }

        if (targets.Count > 0)
            events.Add($"{towerName} hits {targets.Count} targets.");
    }

    public static void ProcessAoeAttack(
        GameState state,
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies,
        List<string> events)
    {
        var center = Targeting.FindTarget(state, tower, enemies);
        if (center == null) return;

        int radius = Convert.ToInt32(tower.GetValueOrDefault("aoe_radius", 2));
        var targets = Targeting.FindAoeTargets(center, enemies, radius);
        int damage = Convert.ToInt32(tower.GetValueOrDefault("damage", 0));
        var dmgType = ParseDamageType(tower.GetValueOrDefault("damage_type")?.ToString());
        string towerName = tower.GetValueOrDefault("name")?.ToString() ?? "Tower";

        foreach (var target in targets)
        {
            int dist = Targeting.ManhattanDistance(center, target);
            int aoeDamage = DamageTypes.CalculateAoeDamage(damage, dist, radius);
            int finalDamage = DamageTypes.CalculateDamage(aoeDamage, dmgType, target);
            Enemies.ApplyDamage(target, finalDamage);
        }

        if (targets.Count > 0)
            events.Add($"{towerName} blasts {targets.Count} enemies.");
    }

    public static void ProcessChainAttack(
        GameState state,
        Dictionary<string, object> tower,
        List<Dictionary<string, object>> enemies,
        List<string> events)
    {
        var first = Targeting.FindTarget(state, tower, enemies);
        if (first == null) return;

        int maxJumps = Convert.ToInt32(tower.GetValueOrDefault("chain_jumps", 3));
        int jumpRange = Convert.ToInt32(tower.GetValueOrDefault("chain_range", 3));
        var chain = Targeting.FindChainTargets(first, enemies, maxJumps, jumpRange);
        int damage = Convert.ToInt32(tower.GetValueOrDefault("damage", 0));
        var dmgType = ParseDamageType(tower.GetValueOrDefault("damage_type")?.ToString());
        string towerName = tower.GetValueOrDefault("name")?.ToString() ?? "Tower";

        for (int i = 0; i < chain.Count; i++)
        {
            int chainDamage = DamageTypes.CalculateChainDamage(damage, i);
            int finalDamage = DamageTypes.CalculateDamage(chainDamage, dmgType, chain[i]);
            Enemies.ApplyDamage(chain[i], finalDamage);
        }

        if (chain.Count > 0)
            events.Add($"{towerName} chains through {chain.Count} enemies.");
    }

    public static DamageType ParseDamageType(string? typeName)
    {
        return typeName?.ToLowerInvariant() switch
        {
            "physical" => DamageType.Physical,
            "magical" => DamageType.Magical,
            "holy" => DamageType.Holy,
            "lightning" => DamageType.Lightning,
            "poison" => DamageType.Poison,
            "cold" => DamageType.Cold,
            "fire" => DamageType.Fire,
            "siege" => DamageType.Siege,
            "nature" => DamageType.Nature,
            "pure" => DamageType.Pure,
            _ => DamageType.Physical,
        };
    }
}
