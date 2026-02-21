using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class DamageTypesCoreTests
{
    [Fact]
    public void CalculateDamage_PhysicalSubtractsArmor()
    {
        var enemy = CreateEnemy(armor: 3);

        int result = DamageTypes.CalculateDamage(10, DamageType.Physical, enemy);

        Assert.Equal(7, result);
    }

    [Fact]
    public void CalculateDamage_PhysicalArmorExceedsDamage_ClampsToMinimumOne()
    {
        var enemy = CreateEnemy(armor: 50);

        int result = DamageTypes.CalculateDamage(10, DamageType.Physical, enemy);

        Assert.Equal(1, result);
    }

    [Fact]
    public void CalculateDamage_MagicalIgnoresArmor()
    {
        var enemy = CreateEnemy(armor: 999);

        int result = DamageTypes.CalculateDamage(10, DamageType.Magical, enemy);

        Assert.Equal(10, result);
    }

    [Fact]
    public void CalculateDamage_PureIgnoresArmor()
    {
        var enemy = CreateEnemy(armor: 999);

        int result = DamageTypes.CalculateDamage(10, DamageType.Pure, enemy);

        Assert.Equal(10, result);
    }

    [Fact]
    public void CalculateDamage_PoisonUsesHalfArmor()
    {
        var enemy = CreateEnemy(armor: 4);

        int result = DamageTypes.CalculateDamage(10, DamageType.Poison, enemy);

        Assert.Equal(8, result);
    }

    [Fact]
    public void CalculateDamage_PoisonArmorExceedsDamage_ClampsToMinimumOne()
    {
        var enemy = CreateEnemy(armor: 100);

        int result = DamageTypes.CalculateDamage(1, DamageType.Poison, enemy);

        Assert.Equal(1, result);
    }

    [Fact]
    public void CalculateDamage_HolyVsAffixedEnemy_AppliesOnePointFiveMultiplier()
    {
        var enemy = CreateEnemy(armor: 2, affix: "shielded");

        int result = DamageTypes.CalculateDamage(10, DamageType.Holy, enemy);

        Assert.Equal(12, result);
    }

    [Fact]
    public void CalculateDamage_HolyVsNonAffixedEnemy_HasNoBonus()
    {
        var enemy = CreateEnemy(armor: 2);

        int result = DamageTypes.CalculateDamage(10, DamageType.Holy, enemy);

        Assert.Equal(8, result);
    }

    [Fact]
    public void CalculateDamage_LightningAlwaysAppliesBonus()
    {
        var enemy = CreateEnemy(armor: 2);

        int result = DamageTypes.CalculateDamage(10, DamageType.Lightning, enemy);

        Assert.Equal(9, result);
    }

    [Fact]
    public void CalculateDamage_FireVsFrozenEnemy_AppliesTripleDamage()
    {
        var enemy = CreateEnemy(armor: 2, effects: FrozenEffects());

        int result = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        Assert.Equal(24, result);
    }

    [Fact]
    public void CalculateDamage_FireVsNonFrozenEnemy_HasNoBonus()
    {
        var enemy = CreateEnemy(armor: 2);

        int result = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        Assert.Equal(8, result);
    }

    [Fact]
    public void CalculateDamage_FireWithNonFrozenEffects_HasNoBonus()
    {
        var enemy = CreateEnemy(
            armor: 2,
            effects: new List<Dictionary<string, object>>
            {
                new() { ["id"] = "burning" }
            });

        int result = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        Assert.Equal(8, result);
    }

    [Fact]
    public void CalculateChainDamage_JumpZero_ReturnsBaseDamage()
    {
        int result = DamageTypes.CalculateChainDamage(100, 0);

        Assert.Equal(100, result);
    }

    [Fact]
    public void CalculateChainDamage_JumpOne_AppliesFalloff()
    {
        int result = DamageTypes.CalculateChainDamage(100, 1);

        Assert.Equal(80, result);
    }

    [Fact]
    public void CalculateChainDamage_JumpTwo_AppliesFalloffAgain()
    {
        int result = DamageTypes.CalculateChainDamage(100, 2);

        Assert.Equal(64, result);
    }

    [Fact]
    public void CalculateChainDamage_DeepJumps_ClampsToMinimumOne()
    {
        int result = DamageTypes.CalculateChainDamage(1, 100);

        Assert.Equal(1, result);
    }

    [Fact]
    public void CalculateAoeDamage_DistanceZero_ReturnsFullDamage()
    {
        int result = DamageTypes.CalculateAoeDamage(100, 0, 4);

        Assert.Equal(100, result);
    }

    [Fact]
    public void CalculateAoeDamage_GreaterDistanceDealsLessDamage()
    {
        int near = DamageTypes.CalculateAoeDamage(100, 1, 4);
        int far = DamageTypes.CalculateAoeDamage(100, 2, 4);

        Assert.True(near > far);
    }

    [Fact]
    public void CalculateAoeDamage_AtExtremeDistance_ClampsToMinimumOne()
    {
        int result = DamageTypes.CalculateAoeDamage(2, 10, 2);

        Assert.Equal(1, result);
    }

    [Fact]
    public void CalculateDotTickDamage_UsesStacksAndDefaultsToOne()
    {
        int stacked = DamageTypes.CalculateDotTickDamage(3, 2);
        int zeroStacks = DamageTypes.CalculateDotTickDamage(3, 0);

        Assert.Equal(6, stacked);
        Assert.Equal(3, zeroStacks);
    }

    [Fact]
    public void DamageTypeToString_ReturnsExpectedNameForAllDamageTypes()
    {
        var expected = new Dictionary<DamageType, string>
        {
            [DamageType.Physical] = "Physical",
            [DamageType.Magical] = "Magical",
            [DamageType.Holy] = "Holy",
            [DamageType.Lightning] = "Lightning",
            [DamageType.Poison] = "Poison",
            [DamageType.Cold] = "Cold",
            [DamageType.Fire] = "Fire",
            [DamageType.Siege] = "Siege",
            [DamageType.Nature] = "Nature",
            [DamageType.Pure] = "Pure",
        };

        foreach (var (damageType, name) in expected)
            Assert.Equal(name, DamageTypes.DamageTypeToString(damageType));
    }

    private static Dictionary<string, object> CreateEnemy(
        int armor = 0,
        string affix = "",
        List<Dictionary<string, object>>? effects = null)
    {
        return new Dictionary<string, object>
        {
            ["armor"] = armor,
            ["affix"] = affix,
            ["effects"] = effects ?? new List<Dictionary<string, object>>(),
        };
    }

    private static List<Dictionary<string, object>> FrozenEffects()
    {
        return new List<Dictionary<string, object>>
        {
            new() { ["id"] = "frozen" }
        };
    }
}
