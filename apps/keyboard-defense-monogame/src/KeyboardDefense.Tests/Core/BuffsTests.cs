using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class BuffsCoreTests
{
    [Fact]
    public void AddBuff_AddsEntryWithDurationAndEffects()
    {
        var state = DefaultState.Create();

        Buffs.AddBuff(state, "fortune", 3, new Dictionary<string, double>
        {
            ["gold_multiplier"] = 1.25,
            ["ap_bonus"] = 2.0,
        });

        Assert.Single(state.ActiveBuffs);
        var buff = state.ActiveBuffs[0];
        Assert.Equal("fortune", buff["buff_id"]);
        Assert.Equal(3, Convert.ToInt32(buff["remaining_days"]));
        Assert.Equal(1.25, Convert.ToDouble(buff["gold_multiplier"]), 5);
        Assert.Equal(2.0, Convert.ToDouble(buff["ap_bonus"]), 5);
    }

    [Fact]
    public void AddBuff_SameId_ReplacesExistingBuff()
    {
        var state = DefaultState.Create();

        Buffs.AddBuff(state, "focus", 2, new Dictionary<string, double>
        {
            ["accuracy_bonus"] = 0.1,
        });
        Buffs.AddBuff(state, "focus", 5, new Dictionary<string, double>
        {
            ["damage_multiplier"] = 0.5,
        });

        var matching = state.ActiveBuffs
            .Where(b => b.GetValueOrDefault("buff_id")?.ToString() == "focus")
            .ToList();

        Assert.Single(matching);
        var buff = matching[0];
        Assert.Equal(5, Convert.ToInt32(buff["remaining_days"]));
        Assert.Equal(0.5, Convert.ToDouble(buff["damage_multiplier"]), 5);
        Assert.False(buff.ContainsKey("accuracy_bonus"));
    }

    [Fact]
    public void HasBuff_WhenPresent_ReturnsTrue()
    {
        var state = DefaultState.Create();

        Buffs.AddBuff(state, "shielded", 2);

        Assert.True(Buffs.HasBuff(state, "shielded"));
    }

    [Fact]
    public void HasBuff_WhenMissing_ReturnsFalse()
    {
        var state = DefaultState.Create();

        Assert.False(Buffs.HasBuff(state, "missing"));
    }

    [Fact]
    public void GetBuffRemainingDays_WhenPresent_ReturnsDuration()
    {
        var state = DefaultState.Create();

        Buffs.AddBuff(state, "ward", 4);

        Assert.Equal(4, Buffs.GetBuffRemainingDays(state, "ward"));
    }

    [Fact]
    public void GetBuffRemainingDays_WhenMissing_ReturnsZero()
    {
        var state = DefaultState.Create();

        Assert.Equal(0, Buffs.GetBuffRemainingDays(state, "missing"));
    }

    [Fact]
    public void ExpireBuffs_RemovesExpiredAndDecrementsRemaining()
    {
        var state = DefaultState.Create();

        Buffs.AddBuff(state, "one_day", 1);
        Buffs.AddBuff(state, "three_day", 3);

        var expired = Buffs.ExpireBuffs(state);

        Assert.Single(expired);
        Assert.Contains("one_day", expired);
        Assert.False(Buffs.HasBuff(state, "one_day"));
        Assert.True(Buffs.HasBuff(state, "three_day"));
        Assert.Equal(2, Buffs.GetBuffRemainingDays(state, "three_day"));
    }

    [Fact]
    public void ApplyDawnEffects_ApBonus_IncreasesApAndAddsMessage()
    {
        var state = DefaultState.Create();
        state.Ap = 1;
        state.ApMax = 5;
        Buffs.AddBuff(state, "energized", 2, new Dictionary<string, double>
        {
            ["ap_bonus"] = 2.0,
        });

        var messages = Buffs.ApplyDawnEffects(state);

        Assert.Equal(3, state.Ap);
        Assert.Equal(1, Buffs.GetBuffRemainingDays(state, "energized"));
        Assert.Contains("Buff: +2 AP from Energized", messages);
    }

    [Fact]
    public void ApplyDawnEffects_HpRegen_HealsAndAddsMessageWhenBelowTen()
    {
        var state = DefaultState.Create();
        state.Hp = 6;
        Buffs.AddBuff(state, "regen", 2, new Dictionary<string, double>
        {
            ["hp_regen"] = 3.0,
        });

        var messages = Buffs.ApplyDawnEffects(state);

        Assert.Equal(9, state.Hp);
        Assert.Equal(1, Buffs.GetBuffRemainingDays(state, "regen"));
        Assert.Contains("Buff: +3 HP from Regeneration", messages);
    }

    [Fact]
    public void ApplyDawnEffects_ExpiringBuff_AddsExpiredMessage()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "temporary", 1);

        var messages = Buffs.ApplyDawnEffects(state);

        Assert.False(Buffs.HasBuff(state, "temporary"));
        Assert.Contains("Buff expired: temporary", messages);
    }

    [Fact]
    public void ApplyDawnEffects_ApBonus_CapsAtApMax()
    {
        var state = DefaultState.Create();
        state.Ap = 4;
        state.ApMax = 5;
        Buffs.AddBuff(state, "energized", 2, new Dictionary<string, double>
        {
            ["ap_bonus"] = 10.0,
        });

        var messages = Buffs.ApplyDawnEffects(state);

        Assert.Equal(5, state.Ap);
        Assert.Contains("Buff: +10 AP from Energized", messages);
    }

    [Fact]
    public void ApplyDawnEffects_HpRegen_CapsAtTen()
    {
        var state = DefaultState.Create();
        state.Hp = 9;
        Buffs.AddBuff(state, "regen", 2, new Dictionary<string, double>
        {
            ["hp_regen"] = 5.0,
        });

        var messages = Buffs.ApplyDawnEffects(state);

        Assert.Equal(10, state.Hp);
        Assert.Contains("Buff: +1 HP from Regeneration", messages);
    }

    [Fact]
    public void EffectGetters_NoBuffs_ReturnZero()
    {
        var state = DefaultState.Create();

        Assert.Equal(0.0, Buffs.GetResourceMultiplier(state), 5);
        Assert.Equal(0.0, Buffs.GetThreatMultiplier(state), 5);
        Assert.Equal(0.0, Buffs.GetDamageMultiplier(state), 5);
        Assert.Equal(0.0, Buffs.GetGoldMultiplier(state), 5);
        Assert.Equal(0.0, Buffs.GetExploreRewardMultiplier(state), 5);
        Assert.Equal(0.0, Buffs.GetAccuracyBonus(state), 5);
        Assert.Equal(0.0, Buffs.GetEnemySpeedMultiplier(state), 5);
        Assert.Equal(0, Buffs.GetDamageReduction(state));
        Assert.Equal(0, Buffs.GetApBonus(state));
        Assert.Equal(0, Buffs.GetHpRegen(state));
    }

    [Fact]
    public void GetResourceMultiplier_OneBuff_ReturnsBuffEffect()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "harvest", 3, new Dictionary<string, double>
        {
            ["resource_multiplier"] = 0.4,
        });

        Assert.Equal(0.4, Buffs.GetResourceMultiplier(state), 5);
    }

    [Fact]
    public void GetThreatMultiplier_TwoBuffs_SumsEffects()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "panic", 3, new Dictionary<string, double>
        {
            ["threat_multiplier"] = 0.15,
        });
        Buffs.AddBuff(state, "calm", 3, new Dictionary<string, double>
        {
            ["threat_multiplier"] = -0.05,
        });

        Assert.Equal(0.1, Buffs.GetThreatMultiplier(state), 5);
    }

    [Fact]
    public void GetDamageMultiplier_TwoBuffs_SumsEffects()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "rage", 3, new Dictionary<string, double>
        {
            ["damage_multiplier"] = 0.5,
        });
        Buffs.AddBuff(state, "blessing", 3, new Dictionary<string, double>
        {
            ["damage_multiplier"] = 1.25,
        });

        Assert.Equal(1.75, Buffs.GetDamageMultiplier(state), 5);
    }

    [Fact]
    public void GetGoldMultiplier_TwoBuffs_SumsEffects()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "merchant", 3, new Dictionary<string, double>
        {
            ["gold_multiplier"] = 0.2,
        });
        Buffs.AddBuff(state, "luck", 3, new Dictionary<string, double>
        {
            ["gold_multiplier"] = 0.3,
        });

        Assert.Equal(0.5, Buffs.GetGoldMultiplier(state), 5);
    }

    [Fact]
    public void GetExploreRewardMultiplier_TwoBuffs_SumsEffects()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "scout", 3, new Dictionary<string, double>
        {
            ["explore_reward_multiplier"] = 0.1,
        });
        Buffs.AddBuff(state, "cartographer", 3, new Dictionary<string, double>
        {
            ["explore_reward_multiplier"] = 0.15,
        });

        Assert.Equal(0.25, Buffs.GetExploreRewardMultiplier(state), 5);
    }

    [Fact]
    public void GetAccuracyBonus_TwoBuffs_SumsEffects()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "focus", 3, new Dictionary<string, double>
        {
            ["accuracy_bonus"] = 0.05,
        });
        Buffs.AddBuff(state, "steady_hands", 3, new Dictionary<string, double>
        {
            ["accuracy_bonus"] = 0.07,
        });

        Assert.Equal(0.12, Buffs.GetAccuracyBonus(state), 5);
    }

    [Fact]
    public void GetEnemySpeedMultiplier_TwoBuffs_SumsEffects()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "slow_field", 3, new Dictionary<string, double>
        {
            ["enemy_speed_multiplier"] = -0.2,
        });
        Buffs.AddBuff(state, "haste_enemies", 3, new Dictionary<string, double>
        {
            ["enemy_speed_multiplier"] = 0.05,
        });

        Assert.Equal(-0.15, Buffs.GetEnemySpeedMultiplier(state), 5);
    }

    [Fact]
    public void GetDamageReduction_TwoBuffs_SumsAndCastsToInt()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "guard", 3, new Dictionary<string, double>
        {
            ["damage_reduction"] = 1.9,
        });
        Buffs.AddBuff(state, "fortify", 3, new Dictionary<string, double>
        {
            ["damage_reduction"] = 2.2,
        });

        Assert.Equal(4, Buffs.GetDamageReduction(state));
    }

    [Fact]
    public void GetApBonusAndHpRegen_TwoBuffs_SumAndCastToInt()
    {
        var state = DefaultState.Create();
        Buffs.AddBuff(state, "energized", 3, new Dictionary<string, double>
        {
            ["ap_bonus"] = 2.4,
            ["hp_regen"] = 3.1,
        });
        Buffs.AddBuff(state, "rested", 3, new Dictionary<string, double>
        {
            ["ap_bonus"] = 1.8,
            ["hp_regen"] = 0.9,
        });

        Assert.Equal(4, Buffs.GetApBonus(state));
        Assert.Equal(4, Buffs.GetHpRegen(state));
    }
}
