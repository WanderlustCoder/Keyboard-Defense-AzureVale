using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for DamageTypes — fire consuming frozen, AoE edge cases,
/// chain damage falloff, dot stacking, and type interaction coverage.
/// </summary>
public class DamageTypesExtendedTests
{
    // =========================================================================
    // Fire consuming frozen — removes the effect
    // =========================================================================

    [Fact]
    public void Fire_VsFrozen_RemovesFrozenEffect()
    {
        var enemy = CreateEnemy(armor: 0, effects: FrozenEffects());

        DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        var effects = (List<Dictionary<string, object>>)enemy["effects"];
        Assert.DoesNotContain(effects, e => e.GetValueOrDefault("id")?.ToString() == "frozen");
    }

    [Fact]
    public void Fire_VsFrozen_LeavesOtherEffects()
    {
        var effects = new List<Dictionary<string, object>>
        {
            new() { ["id"] = "burning" },
            new() { ["id"] = "frozen" },
            new() { ["id"] = "poisoned" },
        };
        var enemy = CreateEnemy(armor: 0, effects: effects);

        DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        var remaining = (List<Dictionary<string, object>>)enemy["effects"];
        Assert.Equal(2, remaining.Count);
        Assert.Contains(remaining, e => e.GetValueOrDefault("id")?.ToString() == "burning");
        Assert.Contains(remaining, e => e.GetValueOrDefault("id")?.ToString() == "poisoned");
    }

    [Fact]
    public void Fire_WithoutFrozen_DoesNotRemoveEffects()
    {
        var effects = new List<Dictionary<string, object>>
        {
            new() { ["id"] = "burning" },
        };
        var enemy = CreateEnemy(armor: 0, effects: effects);

        DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        var remaining = (List<Dictionary<string, object>>)enemy["effects"];
        Assert.Single(remaining);
    }

    // =========================================================================
    // DamageType armor interactions — comprehensive
    // =========================================================================

    [Fact]
    public void Cold_UsesStandardArmorReduction()
    {
        var enemy = CreateEnemy(armor: 3);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Cold, enemy);
        Assert.Equal(7, damage); // 10 - 3
    }

    [Fact]
    public void Nature_UsesStandardArmorReduction()
    {
        var enemy = CreateEnemy(armor: 3);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Nature, enemy);
        Assert.Equal(7, damage);
    }

    [Fact]
    public void Siege_UsesStandardArmorReduction()
    {
        var enemy = CreateEnemy(armor: 3);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Siege, enemy);
        Assert.Equal(7, damage);
    }

    [Fact]
    public void Poison_OddArmor_FloorsDivision()
    {
        var enemy = CreateEnemy(armor: 5);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Poison, enemy);
        // 5/2 = 2 (integer division), so 10 - 2 = 8
        Assert.Equal(8, damage);
    }

    [Fact]
    public void Magical_ZeroArmor_ReturnsBaseDamage()
    {
        var enemy = CreateEnemy(armor: 0);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Magical, enemy);
        Assert.Equal(10, damage);
    }

    [Fact]
    public void Pure_ZeroArmor_ReturnsBaseDamage()
    {
        var enemy = CreateEnemy(armor: 0);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Pure, enemy);
        Assert.Equal(10, damage);
    }

    // =========================================================================
    // Holy vs affix — edge cases
    // =========================================================================

    [Fact]
    public void Holy_EmptyAffix_NoBonus()
    {
        var enemy = CreateEnemy(armor: 0, affix: "");
        int damage = DamageTypes.CalculateDamage(10, DamageType.Holy, enemy);
        Assert.Equal(10, damage);
    }

    [Fact]
    public void Holy_AnyAffix_Gets1Point5xBonus()
    {
        var enemy = CreateEnemy(armor: 0, affix: "any_affix");
        int damage = DamageTypes.CalculateDamage(10, DamageType.Holy, enemy);
        Assert.Equal(15, damage); // 10 * 1.5
    }

    [Fact]
    public void Holy_WithAffix_AppliesAfterArmorReduction()
    {
        var enemy = CreateEnemy(armor: 4, affix: "shielded");
        // Standard armor: 10 - 4 = 6, then Holy bonus: 6 * 1.5 = 9
        int damage = DamageTypes.CalculateDamage(10, DamageType.Holy, enemy);
        Assert.Equal(9, damage);
    }

    // =========================================================================
    // Lightning bonus
    // =========================================================================

    [Fact]
    public void Lightning_AlwaysGets1Point2xBonus()
    {
        var enemy = CreateEnemy(armor: 0);
        int damage = DamageTypes.CalculateDamage(10, DamageType.Lightning, enemy);
        Assert.Equal(12, damage); // 10 * 1.2
    }

    [Fact]
    public void Lightning_WithArmor_AppliesBonusAfterReduction()
    {
        var enemy = CreateEnemy(armor: 5);
        // Standard: 10 - 5 = 5, then 5 * 1.2 = 6
        int damage = DamageTypes.CalculateDamage(10, DamageType.Lightning, enemy);
        Assert.Equal(6, damage);
    }

    // =========================================================================
    // Minimum damage clamping
    // =========================================================================

    [Theory]
    [InlineData(DamageType.Physical)]
    [InlineData(DamageType.Cold)]
    [InlineData(DamageType.Siege)]
    [InlineData(DamageType.Nature)]
    public void StandardDamage_HighArmor_ClampsToOne(DamageType type)
    {
        var enemy = CreateEnemy(armor: 999);
        int damage = DamageTypes.CalculateDamage(1, type, enemy);
        Assert.Equal(1, damage);
    }

    [Fact]
    public void OneDamageBase_ZeroArmor_ReturnsOne()
    {
        var enemy = CreateEnemy(armor: 0);
        int damage = DamageTypes.CalculateDamage(1, DamageType.Physical, enemy);
        Assert.Equal(1, damage);
    }

    // =========================================================================
    // CalculateChainDamage — extended
    // =========================================================================

    [Fact]
    public void ChainDamage_CustomFalloff_AppliesCorrectly()
    {
        // 100 * 0.5^1 = 50
        Assert.Equal(50, DamageTypes.CalculateChainDamage(100, 1, 0.5));
    }

    [Fact]
    public void ChainDamage_FalloffOne_NeverDecreases()
    {
        Assert.Equal(100, DamageTypes.CalculateChainDamage(100, 5, 1.0));
    }

    [Fact]
    public void ChainDamage_JumpThree_DefaultFalloff()
    {
        // 100 * 0.8^3 = 51
        Assert.Equal(51, DamageTypes.CalculateChainDamage(100, 3));
    }

    [Fact]
    public void ChainDamage_SmallBase_ClampsToOne()
    {
        Assert.Equal(1, DamageTypes.CalculateChainDamage(2, 10));
    }

    // =========================================================================
    // CalculateAoeDamage — extended
    // =========================================================================

    [Fact]
    public void AoeDamage_DistanceOne_RadiusFour_AppliesFalloff()
    {
        int damage = DamageTypes.CalculateAoeDamage(100, 1, 4);
        // 1.0 - 1/5 = 0.8 → 100 * 0.8 = 80
        Assert.Equal(80, damage);
    }

    [Fact]
    public void AoeDamage_AtMaxRadius_AppliesMinFalloff()
    {
        int damage = DamageTypes.CalculateAoeDamage(100, 4, 4);
        // 1.0 - 4/5 = 0.2, but max(0.3, 0.2) = 0.3 → 100 * 0.3 = 30
        Assert.Equal(30, damage);
    }

    [Fact]
    public void AoeDamage_BeyondMaxRadius_ClampsFalloffToThirtyPercent()
    {
        int damage = DamageTypes.CalculateAoeDamage(100, 10, 4);
        // 1.0 - 10/5 = -1.0, but max(0.3, -1.0) = 0.3 → 100 * 0.3 = 30
        Assert.Equal(30, damage);
    }

    [Fact]
    public void AoeDamage_SmallBase_ClampsToOne()
    {
        Assert.Equal(1, DamageTypes.CalculateAoeDamage(2, 5, 2));
    }

    // =========================================================================
    // CalculateDotTickDamage — extended
    // =========================================================================

    [Fact]
    public void DotTickDamage_OneStack_ReturnsBase()
    {
        Assert.Equal(5, DamageTypes.CalculateDotTickDamage(5, 1));
    }

    [Fact]
    public void DotTickDamage_NegativeStacks_ClampsToOne()
    {
        // Math.Max(1, -1) = 1, so 5 * 1 = 5
        Assert.Equal(5, DamageTypes.CalculateDotTickDamage(5, -1));
    }

    [Fact]
    public void DotTickDamage_HighStacks_Multiplies()
    {
        Assert.Equal(50, DamageTypes.CalculateDotTickDamage(5, 10));
    }

    // =========================================================================
    // DamageTypeToString — unknown value
    // =========================================================================

    [Fact]
    public void DamageTypeToString_UnknownValue_ReturnsUnknown()
    {
        string result = DamageTypes.DamageTypeToString((DamageType)999);
        Assert.Equal("Unknown", result);
    }

    [Fact]
    public void DamageTypeToString_AllEnumValues_AreNonEmpty()
    {
        foreach (DamageType dt in Enum.GetValues<DamageType>())
        {
            string name = DamageTypes.DamageTypeToString(dt);
            Assert.False(string.IsNullOrEmpty(name));
        }
    }

    // =========================================================================
    // Effect missing — no crash
    // =========================================================================

    [Fact]
    public void Fire_EnemyWithNoEffectsKey_DoesNotCrash()
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = 0,
            ["affix"] = "",
        };
        int damage = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);
        Assert.Equal(10, damage);
    }

    [Fact]
    public void Fire_EnemyWithNullEffects_DoesNotCrash()
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = 0,
            ["affix"] = "",
            ["effects"] = null!,
        };
        int damage = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);
        Assert.Equal(10, damage);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

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
