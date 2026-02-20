using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Enemy ability definitions and processing.
/// Ported from sim/enemy_abilities.gd.
/// </summary>
public static class EnemyAbilities
{
    public enum AbilityType { Passive, Trigger, Cooldown, Death }
    public enum TriggerEvent { OnSpawn, OnDamage, OnLowHp, OnAllyDeath, OnAttack, OnDeath }

    public static readonly Dictionary<string, AbilityDef> Abilities = new()
    {
        ["fortified"] = new("Fortified", AbilityType.Passive,
            "Reduces physical damage taken.", null, null),
        ["enrage"] = new("Enrage", AbilityType.Trigger,
            "Gains damage when below 50% HP.", TriggerEvent.OnLowHp, null),
        ["ghostly"] = new("Ghostly", AbilityType.Passive,
            "Takes reduced damage from physical attacks.", null, null),
        ["heal_aura"] = new("Heal Aura", AbilityType.Passive,
            "Heals nearby allies each tick.", null, null),
        ["taunt"] = new("Taunt", AbilityType.Passive,
            "Forces towers to target this enemy.", null, null),
        ["rally"] = new("Rally", AbilityType.Cooldown,
            "Boosts nearby allies' speed.", null, 5.0),
        ["spell_shield"] = new("Spell Shield", AbilityType.Passive,
            "Blocks the first magical hit.", null, null),
        ["blood_frenzy"] = new("Blood Frenzy", AbilityType.Trigger,
            "Gains speed when ally dies.", TriggerEvent.OnAllyDeath, null),
        ["summon_spawn"] = new("Summon", AbilityType.Death,
            "Spawns smaller enemies on death.", TriggerEvent.OnDeath, null),
        ["void_armor"] = new("Void Armor", AbilityType.Passive,
            "Absorbs first N damage instances.", null, null),
        ["regeneration"] = new("Regeneration", AbilityType.Passive,
            "Recovers HP over time.", null, null),
    };

    public static AbilityDef? GetAbility(string abilityId) => Abilities.GetValueOrDefault(abilityId);

    public static bool HasPassive(Dictionary<string, object> enemy, string abilityId)
    {
        if (enemy.GetValueOrDefault("abilities") is not List<object> abilities)
            return false;
        foreach (var a in abilities)
        {
            if (a?.ToString() == abilityId)
            {
                var def = GetAbility(abilityId);
                if (def?.Type == AbilityType.Passive) return true;
            }
        }
        return false;
    }

    public static int GetEffectiveArmor(Dictionary<string, object> enemy)
    {
        int armor = Convert.ToInt32(enemy.GetValueOrDefault("armor", 0));
        if (HasPassive(enemy, "fortified"))
            armor += 3;
        return armor;
    }

    public static int GetEffectiveSpeed(Dictionary<string, object> enemy)
    {
        int speed = Convert.ToInt32(enemy.GetValueOrDefault("speed", 0));
        bool enraged = enemy.GetValueOrDefault("enraged") is true;
        if (enraged) speed = (int)(speed * 1.5);
        return speed;
    }

    public static void HandleTrigger(Dictionary<string, object> enemy, TriggerEvent trigger)
    {
        if (enemy.GetValueOrDefault("abilities") is not List<object> abilities) return;

        foreach (var a in abilities)
        {
            string abilityId = a?.ToString() ?? "";
            var def = GetAbility(abilityId);
            if (def == null || def.Trigger != trigger) continue;

            switch (abilityId)
            {
                case "enrage":
                    int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
                    int maxHp = Convert.ToInt32(enemy.GetValueOrDefault("max_hp", 1));
                    if (hp <= maxHp / 2)
                        enemy["enraged"] = true;
                    break;
                case "blood_frenzy":
                    int currentSpeed = Convert.ToInt32(enemy.GetValueOrDefault("speed", 0));
                    enemy["speed"] = currentSpeed + 10;
                    break;
            }
        }
    }
}

public record AbilityDef(
    string Name,
    EnemyAbilities.AbilityType Type,
    string Description,
    EnemyAbilities.TriggerEvent? Trigger,
    double? Cooldown);
