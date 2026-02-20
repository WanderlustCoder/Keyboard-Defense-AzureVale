using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Applies event choice effects to game state.
/// Ported from sim/event_effects.gd.
/// </summary>
public static class EventEffects
{
    public static string ApplyEffect(GameState state, Dictionary<string, object> effect)
    {
        string type = effect.GetValueOrDefault("type", "").ToString() ?? "";
        return type switch
        {
            "resource_add" => ApplyResourceAdd(state, effect),
            "gold_add" => ApplyGoldAdd(state, effect),
            "damage_castle" => ApplyDamageCastle(state, effect),
            "heal_castle" => ApplyHealCastle(state, effect),
            "ap_add" => ApplyApAdd(state, effect),
            "threat_add" => ApplyThreatAdd(state, effect),
            "buff_apply" => ApplyBuff(state, effect),
            "set_flag" => ApplySetFlag(state, effect),
            "clear_flag" => ApplyClearFlag(state, effect),
            _ => ""
        };
    }

    private static string ApplyResourceAdd(GameState state, Dictionary<string, object> effect)
    {
        string resource = effect.GetValueOrDefault("resource", "").ToString() ?? "";
        int amount = Convert.ToInt32(effect.GetValueOrDefault("amount", 0));
        if (string.IsNullOrEmpty(resource) || amount == 0) return "";
        state.Resources[resource] = state.Resources.GetValueOrDefault(resource, 0) + amount;
        return amount > 0 ? $"+{amount} {resource}" : $"{amount} {resource}";
    }

    private static string ApplyGoldAdd(GameState state, Dictionary<string, object> effect)
    {
        int amount = Convert.ToInt32(effect.GetValueOrDefault("amount", 0));
        state.Gold += amount;
        return amount > 0 ? $"+{amount} gold" : $"{amount} gold";
    }

    private static string ApplyDamageCastle(GameState state, Dictionary<string, object> effect)
    {
        int amount = Convert.ToInt32(effect.GetValueOrDefault("amount", 0));
        state.Hp = Math.Max(0, state.Hp - amount);
        return $"Castle took {amount} damage! ({state.Hp} HP remaining)";
    }

    private static string ApplyHealCastle(GameState state, Dictionary<string, object> effect)
    {
        int amount = Convert.ToInt32(effect.GetValueOrDefault("amount", 0));
        int oldHp = state.Hp;
        state.Hp = Math.Min(10, state.Hp + amount);
        int healed = state.Hp - oldHp;
        return healed > 0 ? $"Castle healed {healed} HP ({state.Hp} HP)" : "";
    }

    private static string ApplyApAdd(GameState state, Dictionary<string, object> effect)
    {
        int amount = Convert.ToInt32(effect.GetValueOrDefault("amount", 0));
        state.Ap = Math.Min(state.ApMax, state.Ap + amount);
        return amount > 0 ? $"+{amount} AP" : $"{amount} AP";
    }

    private static string ApplyThreatAdd(GameState state, Dictionary<string, object> effect)
    {
        int amount = Convert.ToInt32(effect.GetValueOrDefault("amount", 0));
        state.Threat = Math.Max(0, state.Threat + amount);
        return amount > 0 ? $"Threat increased by {amount}" : $"Threat decreased by {-amount}";
    }

    private static string ApplyBuff(GameState state, Dictionary<string, object> effect)
    {
        string buffId = effect.GetValueOrDefault("buff_id", "").ToString() ?? "";
        int duration = Convert.ToInt32(effect.GetValueOrDefault("duration", 3));
        if (string.IsNullOrEmpty(buffId)) return "";
        Buffs.AddBuff(state, buffId, duration);
        return $"Gained buff: {buffId} ({duration} days)";
    }

    private static string ApplySetFlag(GameState state, Dictionary<string, object> effect)
    {
        string flag = effect.GetValueOrDefault("flag", "").ToString() ?? "";
        if (string.IsNullOrEmpty(flag)) return "";
        state.EventFlags[flag] = true;
        return "";
    }

    private static string ApplyClearFlag(GameState state, Dictionary<string, object> effect)
    {
        string flag = effect.GetValueOrDefault("flag", "").ToString() ?? "";
        if (string.IsNullOrEmpty(flag)) return "";
        state.EventFlags.Remove(flag);
        return "";
    }
}
