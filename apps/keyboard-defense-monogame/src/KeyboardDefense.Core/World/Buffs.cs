using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Buff system with effect calculations and dawn processing.
/// Ported from sim/buffs.gd.
/// </summary>
public static class Buffs
{
    public static double GetResourceMultiplier(GameState state) => SumBuffEffect(state, "resource_multiplier");
    public static double GetThreatMultiplier(GameState state) => SumBuffEffect(state, "threat_multiplier");
    public static double GetDamageMultiplier(GameState state) => SumBuffEffect(state, "damage_multiplier");
    public static double GetGoldMultiplier(GameState state) => SumBuffEffect(state, "gold_multiplier");
    public static double GetExploreRewardMultiplier(GameState state) => SumBuffEffect(state, "explore_reward_multiplier");
    public static double GetAccuracyBonus(GameState state) => SumBuffEffect(state, "accuracy_bonus");
    public static double GetEnemySpeedMultiplier(GameState state) => SumBuffEffect(state, "enemy_speed_multiplier");

    public static int GetDamageReduction(GameState state) => (int)SumBuffEffect(state, "damage_reduction");
    public static int GetApBonus(GameState state) => (int)SumBuffEffect(state, "ap_bonus");
    public static int GetHpRegen(GameState state) => (int)SumBuffEffect(state, "hp_regen");

    public static bool HasBuff(GameState state, string buffId)
    {
        return state.ActiveBuffs.Any(b => b.GetValueOrDefault("buff_id")?.ToString() == buffId);
    }

    public static int GetBuffRemainingDays(GameState state, string buffId)
    {
        var buff = state.ActiveBuffs.FirstOrDefault(b => b.GetValueOrDefault("buff_id")?.ToString() == buffId);
        if (buff == null) return 0;
        return Convert.ToInt32(buff.GetValueOrDefault("remaining_days", 0));
    }

    public static List<string> ApplyDawnEffects(GameState state)
    {
        var messages = new List<string>();

        int apBonus = GetApBonus(state);
        if (apBonus > 0)
        {
            state.Ap = Math.Min(state.Ap + apBonus, state.ApMax);
            messages.Add($"Buff: +{apBonus} AP from Energized");
        }

        int hpRegen = GetHpRegen(state);
        if (hpRegen > 0 && state.Hp < 10)
        {
            int oldHp = state.Hp;
            state.Hp = Math.Min(state.Hp + hpRegen, 10);
            int healed = state.Hp - oldHp;
            if (healed > 0)
                messages.Add($"Buff: +{healed} HP from Regeneration");
        }

        var expired = ExpireBuffs(state);
        foreach (var buffId in expired)
            messages.Add($"Buff expired: {buffId}");

        return messages;
    }

    public static List<string> ExpireBuffs(GameState state)
    {
        var expired = new List<string>();
        for (int i = state.ActiveBuffs.Count - 1; i >= 0; i--)
        {
            var buff = state.ActiveBuffs[i];
            int remaining = Convert.ToInt32(buff.GetValueOrDefault("remaining_days", 0));
            remaining--;
            if (remaining <= 0)
            {
                expired.Add(buff.GetValueOrDefault("buff_id")?.ToString() ?? "");
                state.ActiveBuffs.RemoveAt(i);
            }
            else
            {
                buff["remaining_days"] = remaining;
            }
        }
        return expired;
    }

    public static void AddBuff(GameState state, string buffId, int durationDays, Dictionary<string, double>? effects = null)
    {
        // Remove existing buff of same type
        state.ActiveBuffs.RemoveAll(b => b.GetValueOrDefault("buff_id")?.ToString() == buffId);
        var buff = new Dictionary<string, object>
        {
            ["buff_id"] = buffId,
            ["remaining_days"] = durationDays,
        };
        if (effects != null)
        {
            foreach (var (key, value) in effects)
                buff[key] = value;
        }
        state.ActiveBuffs.Add(buff);
    }

    private static double SumBuffEffect(GameState state, string effectKey)
    {
        double total = 0;
        foreach (var buff in state.ActiveBuffs)
            total += Convert.ToDouble(buff.GetValueOrDefault(effectKey, 0.0));
        return total;
    }
}
