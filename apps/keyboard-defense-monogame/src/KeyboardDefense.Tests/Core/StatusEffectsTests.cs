using System;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class StatusEffectsCoreTests
{
    [Fact]
    public void Effects_HasExactlyNineEntries()
    {
        Assert.Equal(9, StatusEffects.Effects.Count);
    }

    [Fact]
    public void Effects_AllEntriesUseDebuffCategory()
    {
        foreach (var (_, effect) in StatusEffects.Effects)
        {
            Assert.Equal(StatusEffects.CategoryDebuff, effect.Category);
        }
    }

    [Fact]
    public void GetEffect_KnownEffects_ReturnsRegisteredDefinition()
    {
        var knownIds = new[]
        {
            "slow",
            "frozen",
            "rooted",
            "burning",
            "poisoned",
            "bleeding",
            "corrupting",
            "armor_broken",
            "exposed",
        };

        foreach (var id in knownIds)
        {
            var effect = StatusEffects.GetEffect(id);
            Assert.NotNull(effect);
            Assert.Same(StatusEffects.Effects[id], effect);
        }
    }

    [Fact]
    public void GetEffect_UnknownId_ReturnsNull()
    {
        var effect = StatusEffects.GetEffect("not_a_real_effect");
        Assert.Null(effect);
    }

    [Fact]
    public void GetEffectName_KnownEffects_ReturnDisplayNames()
    {
        foreach (var (id, def) in StatusEffects.Effects)
        {
            Assert.Equal(def.Name, StatusEffects.GetEffectName(id));
        }
    }

    [Fact]
    public void GetEffectName_UnknownId_ReturnsInputId()
    {
        const string unknownId = "mystery_effect";
        Assert.Equal(
            0,
            string.Compare(
                unknownId,
                StatusEffects.GetEffectName(unknownId),
                StringComparison.Ordinal));
    }

    [Fact]
    public void Slow_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("slow"));

        Assert.Equal("Slowed", effect.Name);
        Assert.Equal(3.0f, effect.Duration, 3);
        Assert.Equal(-0.3f, effect.SpeedMod, 3);
        Assert.Equal(3, effect.MaxStacks);
        Assert.False(effect.Immobilized);
    }

    [Fact]
    public void Frozen_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("frozen"));

        Assert.Equal("Frozen", effect.Name);
        Assert.Equal(1.5f, effect.Duration, 3);
        Assert.True(effect.Immobilized);
    }

    [Fact]
    public void Rooted_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("rooted"));

        Assert.Equal("Rooted", effect.Name);
        Assert.Equal(2.0f, effect.Duration, 3);
        Assert.True(effect.Immobilized);
    }

    [Fact]
    public void Burning_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("burning"));

        Assert.Equal("Burning", effect.Name);
        Assert.Equal(3, effect.DotDamage);
        Assert.Equal(5, effect.MaxStacks);
    }

    [Fact]
    public void Poisoned_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("poisoned"));

        Assert.Equal("Poisoned", effect.Name);
        Assert.Equal(8.0f, effect.Duration, 3);
        Assert.Equal(2, effect.DotDamage);
        Assert.Equal(10, effect.MaxStacks);
    }

    [Fact]
    public void Bleeding_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("bleeding"));

        Assert.Equal("Bleeding", effect.Name);
        Assert.Equal(4, effect.DotDamage);
        Assert.Equal(3, effect.MaxStacks);
    }

    [Fact]
    public void Corrupting_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("corrupting"));

        Assert.Equal("Corrupting", effect.Name);
        Assert.Equal(5, effect.DotDamage);
        Assert.Equal(1, effect.MaxStacks);
    }

    [Fact]
    public void ArmorBroken_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("armor_broken"));

        Assert.Equal("Armor Broken", effect.Name);
        Assert.Equal(-0.5f, effect.ArmorMod, 3);
    }

    [Fact]
    public void Exposed_HasExpectedStats()
    {
        var effect = Assert.IsType<StatusEffectDef>(StatusEffects.GetEffect("exposed"));

        Assert.Equal("Exposed", effect.Name);
        Assert.Equal(0.25f, effect.DamageTakenMod, 3);
    }

    [Fact]
    public void CategoryDebuffConstant_HasExpectedValue()
    {
        Assert.Equal("debuff", StatusEffects.CategoryDebuff);
    }

    [Fact]
    public void CategoryBuffConstant_HasExpectedValue()
    {
        Assert.Equal("buff", StatusEffects.CategoryBuff);
    }

    [Fact]
    public void StatusEffectDef_DefaultValues_AreExpected()
    {
        var def = new StatusEffectDef();

        Assert.Equal(string.Empty, def.Name);
        Assert.Equal("debuff", def.Category);
        Assert.Equal(0.0f, def.Duration, 3);
        Assert.Equal(0.0f, def.SpeedMod, 3);
        Assert.Equal(0.0f, def.ArmorMod, 3);
        Assert.Equal(0.0f, def.DamageTakenMod, 3);
        Assert.Equal(0, def.DotDamage);
        Assert.Equal(1, def.MaxStacks);
        Assert.False(def.Immobilized);
    }
}
