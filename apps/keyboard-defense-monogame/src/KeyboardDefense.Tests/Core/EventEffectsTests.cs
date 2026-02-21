using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class EventEffectsTests
{
    [Fact]
    public void ApplyEffect_ResourceAddPositive_AddsResourceAndReturnsPlusMessage()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 2;

        string message = EventEffects.ApplyEffect(state, Effect("resource_add", ("resource", "wood"), ("amount", 3)));

        Assert.Equal(5, state.Resources["wood"]);
        Assert.Equal("+3 wood", message);
    }

    [Fact]
    public void ApplyEffect_ResourceAddNegative_SubtractsResourceAndReturnsNegativeMessage()
    {
        var state = DefaultState.Create();
        state.Resources["stone"] = 6;

        string message = EventEffects.ApplyEffect(state, Effect("resource_add", ("resource", "stone"), ("amount", -2)));

        Assert.Equal(4, state.Resources["stone"]);
        Assert.Equal("-2 stone", message);
    }

    [Fact]
    public void ApplyEffect_ResourceAddEmptyResource_ReturnsEmptyAndDoesNotChangeResources()
    {
        var state = DefaultState.Create();
        int beforeCount = state.Resources.Count;
        int beforeWood = state.Resources.GetValueOrDefault("wood", 0);

        string message = EventEffects.ApplyEffect(state, Effect("resource_add", ("resource", ""), ("amount", 5)));

        Assert.Equal("", message);
        Assert.Equal(beforeCount, state.Resources.Count);
        Assert.Equal(beforeWood, state.Resources.GetValueOrDefault("wood", 0));
    }

    [Fact]
    public void ApplyEffect_ResourceAddZeroAmount_ReturnsEmptyAndDoesNotChangeResource()
    {
        var state = DefaultState.Create();
        state.Resources["food"] = 4;

        string message = EventEffects.ApplyEffect(state, Effect("resource_add", ("resource", "food"), ("amount", 0)));

        Assert.Equal("", message);
        Assert.Equal(4, state.Resources["food"]);
    }

    [Fact]
    public void ApplyEffect_GoldAddPositive_AddsGoldAndReturnsPlusMessage()
    {
        var state = DefaultState.Create();
        state.Gold = 10;

        string message = EventEffects.ApplyEffect(state, Effect("gold_add", ("amount", 7)));

        Assert.Equal(17, state.Gold);
        Assert.Equal("+7 gold", message);
    }

    [Fact]
    public void ApplyEffect_GoldAddNegative_SubtractsGoldAndReturnsNegativeMessage()
    {
        var state = DefaultState.Create();
        state.Gold = 10;

        string message = EventEffects.ApplyEffect(state, Effect("gold_add", ("amount", -4)));

        Assert.Equal(6, state.Gold);
        Assert.Equal("-4 gold", message);
    }

    [Fact]
    public void ApplyEffect_DamageCastle_ReducesHpAndReturnsDamageMessage()
    {
        var state = DefaultState.Create();
        state.Hp = 10;

        string message = EventEffects.ApplyEffect(state, Effect("damage_castle", ("amount", 3)));

        Assert.Equal(7, state.Hp);
        Assert.Equal("Castle took 3 damage! (7 HP remaining)", message);
    }

    [Fact]
    public void ApplyEffect_DamageCastle_FloorsHpAtZero()
    {
        var state = DefaultState.Create();
        state.Hp = 2;

        string message = EventEffects.ApplyEffect(state, Effect("damage_castle", ("amount", 10)));

        Assert.Equal(0, state.Hp);
        Assert.Equal("Castle took 10 damage! (0 HP remaining)", message);
    }

    [Fact]
    public void ApplyEffect_HealCastle_IncreasesHpAndReturnsHealMessage()
    {
        var state = DefaultState.Create();
        state.Hp = 4;

        string message = EventEffects.ApplyEffect(state, Effect("heal_castle", ("amount", 3)));

        Assert.Equal(7, state.Hp);
        Assert.Equal("Castle healed 3 HP (7 HP)", message);
    }

    [Fact]
    public void ApplyEffect_HealCastle_CapsAtTenAndReportsActualHealedAmount()
    {
        var state = DefaultState.Create();
        state.Hp = 9;

        string message = EventEffects.ApplyEffect(state, Effect("heal_castle", ("amount", 5)));

        Assert.Equal(10, state.Hp);
        Assert.Equal("Castle healed 1 HP (10 HP)", message);
    }

    [Fact]
    public void ApplyEffect_HealCastle_WhenAlreadyMax_ReturnsEmpty()
    {
        var state = DefaultState.Create();
        state.Hp = 10;

        string message = EventEffects.ApplyEffect(state, Effect("heal_castle", ("amount", 2)));

        Assert.Equal(10, state.Hp);
        Assert.Equal("", message);
    }

    [Fact]
    public void ApplyEffect_ApAdd_IncreasesApAndReturnsPlusMessage()
    {
        var state = DefaultState.Create();
        state.Ap = 1;
        state.ApMax = 5;

        string message = EventEffects.ApplyEffect(state, Effect("ap_add", ("amount", 2)));

        Assert.Equal(3, state.Ap);
        Assert.Equal("+2 AP", message);
    }

    [Fact]
    public void ApplyEffect_ApAdd_CapsAtApMax()
    {
        var state = DefaultState.Create();
        state.Ap = 4;
        state.ApMax = 5;

        string message = EventEffects.ApplyEffect(state, Effect("ap_add", ("amount", 6)));

        Assert.Equal(5, state.Ap);
        Assert.Equal("+6 AP", message);
    }

    [Fact]
    public void ApplyEffect_ThreatAddPositive_IncreasesThreatAndReturnsIncreaseMessage()
    {
        var state = DefaultState.Create();
        state.Threat = 2;

        string message = EventEffects.ApplyEffect(state, Effect("threat_add", ("amount", 4)));

        Assert.Equal(6, state.Threat);
        Assert.Equal("Threat increased by 4", message);
    }

    [Fact]
    public void ApplyEffect_ThreatAddNegative_DecreasesThreatAndFloorsAtZero()
    {
        var state = DefaultState.Create();
        state.Threat = 2;

        string message = EventEffects.ApplyEffect(state, Effect("threat_add", ("amount", -5)));

        Assert.Equal(0, state.Threat);
        Assert.Equal("Threat decreased by 5", message);
    }

    [Fact]
    public void ApplyEffect_BuffApply_WithDuration_AddsBuffAndReturnsMessage()
    {
        var state = DefaultState.Create();

        string message = EventEffects.ApplyEffect(state, Effect("buff_apply", ("buff_id", "regen"), ("duration", 5)));

        Assert.True(Buffs.HasBuff(state, "regen"));
        Assert.Equal(5, Buffs.GetBuffRemainingDays(state, "regen"));
        Assert.Equal("Gained buff: regen (5 days)", message);
    }

    [Fact]
    public void ApplyEffect_BuffApply_UsesDefaultDurationOfThreeWhenMissing()
    {
        var state = DefaultState.Create();

        string message = EventEffects.ApplyEffect(state, Effect("buff_apply", ("buff_id", "energized")));

        Assert.True(Buffs.HasBuff(state, "energized"));
        Assert.Equal(3, Buffs.GetBuffRemainingDays(state, "energized"));
        Assert.Equal("Gained buff: energized (3 days)", message);
    }

    [Fact]
    public void ApplyEffect_SetFlag_SetsFlagTrueAndReturnsEmpty()
    {
        var state = DefaultState.Create();

        string message = EventEffects.ApplyEffect(state, Effect("set_flag", ("flag", "met_merchant")));

        Assert.Equal("", message);
        Assert.True(state.EventFlags.ContainsKey("met_merchant"));
        Assert.True((bool)state.EventFlags["met_merchant"]);
    }

    [Fact]
    public void ApplyEffect_SetFlag_EmptyFlag_ReturnsEmptyAndDoesNotChangeFlags()
    {
        var state = DefaultState.Create();
        int beforeCount = state.EventFlags.Count;

        string message = EventEffects.ApplyEffect(state, Effect("set_flag", ("flag", "")));

        Assert.Equal("", message);
        Assert.Equal(beforeCount, state.EventFlags.Count);
    }

    [Fact]
    public void ApplyEffect_ClearFlag_RemovesExistingFlagAndReturnsEmpty()
    {
        var state = DefaultState.Create();
        state.EventFlags["mysterious_rune"] = true;

        string message = EventEffects.ApplyEffect(state, Effect("clear_flag", ("flag", "mysterious_rune")));

        Assert.Equal("", message);
        Assert.False(state.EventFlags.ContainsKey("mysterious_rune"));
    }

    [Fact]
    public void ApplyEffect_ClearFlag_EmptyFlag_ReturnsEmptyAndDoesNotChangeFlags()
    {
        var state = DefaultState.Create();
        state.EventFlags["kept_flag"] = true;
        int beforeCount = state.EventFlags.Count;

        string message = EventEffects.ApplyEffect(state, Effect("clear_flag", ("flag", "")));

        Assert.Equal("", message);
        Assert.Equal(beforeCount, state.EventFlags.Count);
        Assert.True(state.EventFlags.ContainsKey("kept_flag"));
    }

    [Fact]
    public void ApplyEffect_UnknownType_ReturnsEmptyAndDoesNotMutateTrackedFields()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 8;
        state.Gold = 14;
        state.Hp = 6;
        state.Ap = 2;
        state.Threat = 3;

        string message = EventEffects.ApplyEffect(state, Effect("not_a_real_effect", ("amount", 99)));

        Assert.Equal("", message);
        Assert.Equal(8, state.Resources["wood"]);
        Assert.Equal(14, state.Gold);
        Assert.Equal(6, state.Hp);
        Assert.Equal(2, state.Ap);
        Assert.Equal(3, state.Threat);
    }

    private static Dictionary<string, object> Effect(string type, params (string Key, object Value)[] entries)
    {
        var effect = new Dictionary<string, object>
        {
            ["type"] = type,
        };

        foreach (var (key, value) in entries)
            effect[key] = value;

        return effect;
    }
}
