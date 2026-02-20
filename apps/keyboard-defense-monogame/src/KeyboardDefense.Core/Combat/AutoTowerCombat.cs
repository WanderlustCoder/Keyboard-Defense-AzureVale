using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Auto-defending tower combat processing.
/// Ported from sim/auto_tower_combat.gd.
/// </summary>
public static class AutoTowerCombat
{
    public static List<Dictionary<string, object>> ProcessAutoTowers(GameState state, double delta)
    {
        var events = new List<Dictionary<string, object>>();

        foreach (var (index, structureType) in state.Structures)
        {
            var towerDef = AutoTowerTypes.GetTower(structureType);
            if (towerDef == null) continue;
            if (towerDef.AttackSpeed <= 0 && towerDef.Targeting != AutoTowerTypes.AutoTargetMode.Contact)
                continue;

            // Update cooldown
            var cooldowns = state.TowerCooldowns;
            int currentCd = cooldowns.GetValueOrDefault(index, 0);
            if (currentCd > 0)
            {
                cooldowns[index] = Math.Max(0, currentCd - (int)(delta * 1000));
                continue;
            }

            // Find targets
            var targets = AutoTargeting.PickTargets(state, index, towerDef.Targeting, towerDef.Range);
            if (targets.Count == 0) continue;

            // Apply damage
            int baseDamage = towerDef.Damage;
            foreach (var target in targets)
            {
                int hp = Convert.ToInt32(target.GetValueOrDefault("hp", 0));
                hp -= baseDamage;
                target["hp"] = hp;

                events.Add(new Dictionary<string, object>
                {
                    ["type"] = "auto_tower_attack",
                    ["tower_index"] = index,
                    ["tower_type"] = structureType,
                    ["target_id"] = target.GetValueOrDefault("id", 0),
                    ["damage"] = baseDamage,
                    ["killed"] = hp <= 0
                });
            }

            // Set cooldown
            if (towerDef.AttackSpeed > 0)
            {
                int cdMs = (int)(1000.0 / towerDef.AttackSpeed);
                cooldowns[index] = cdMs;
            }
        }

        return events;
    }
}
