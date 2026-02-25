using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class DamageCalculationTests
{
    [Fact]
    public void TypingDamage_WpmBelowThreshold_UsesBaseDamage()
    {
        var state = DefaultState.Create();

        int damage = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm: 45.0,
            accuracy: 0.80,
            combo: 0);

        Assert.Equal(1, damage);
        Assert.NotNull(state);
    }

    [Fact]
    public void TypingDamage_WpmAtThreshold_AddsBonusDamage()
    {
        var state = DefaultState.Create();

        int damage = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm: SimBalance.TypingWpmBonusThreshold,
            accuracy: 0.80,
            combo: 0);

        Assert.Equal(2, damage);
        Assert.NotNull(state);
    }

    [Fact]
    public void TypingDamage_HighWpm_DoesNotStackAdditionalWpmBonus()
    {
        var state = DefaultState.Create();

        int damage = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm: 140.0,
            accuracy: 0.80,
            combo: 0);

        Assert.Equal(2, damage);
        Assert.NotNull(state);
    }

    [Fact]
    public void TypingDamage_AccuracyBonus_OnlyAppliesAtThreshold()
    {
        var state = DefaultState.Create();

        int below = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm: 0.0,
            accuracy: 0.949,
            combo: 0);
        int atThreshold = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm: 0.0,
            accuracy: SimBalance.TypingAccuracyBonusThreshold,
            combo: 0);

        Assert.Equal(1, below);
        Assert.Equal(2, atThreshold);
        Assert.NotNull(state);
    }

    [Fact]
    public void TypingDamage_FromTypingMetrics_UsesComputedWpmAndAccuracy()
    {
        var state = DefaultState.Create();
        TypingMetrics.InitBattleMetrics(state);
        state.TypingMetrics["battle_chars_typed"] = 325;
        state.TypingMetrics["battle_errors"] = 16;
        state.TypingMetrics["battle_start_msec"] =
            Stopwatch.GetTimestamp() - (long)(55.0 * Stopwatch.Frequency);

        double wpm = TypingMetrics.GetWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        int damage = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm,
            accuracy,
            combo: 0);

        Assert.True(wpm > SimBalance.TypingWpmBonusThreshold, $"Expected WPM above threshold, got {wpm:F2}.");
        Assert.True(accuracy >= SimBalance.TypingAccuracyBonusThreshold, $"Expected accuracy at threshold, got {accuracy:F4}.");
        Assert.Equal(3, damage);
    }

    [Fact]
    public void TowerDamage_ScalesWithLevel()
    {
        var state = DefaultState.Create();

        int levelOne = SimBalance.CalculateTowerDamage(baseDamage: 8, level: 1);
        int levelTwo = SimBalance.CalculateTowerDamage(baseDamage: 8, level: 2);
        int levelThree = SimBalance.CalculateTowerDamage(baseDamage: 8, level: 3);

        Assert.Equal(8, levelOne);
        Assert.Equal(10, levelTwo);
        Assert.Equal(12, levelThree);
        Assert.NotNull(state);
    }

    [Fact]
    public void SynergyBonus_AdjacentCompatibleTowers_AddsDamage()
    {
        var state = DefaultState.Create();
        var towerPos = new GridPoint(10, 10);
        PlaceTower(state, towerPos, "fire");
        PlaceTower(state, new GridPoint(11, 10), "wind");

        var breakdown = CalculateDamagePipeline(
            state,
            towerPos,
            towerBaseDamage: 8,
            towerLevel: 2,
            wpm: 0.0,
            accuracy: 0.0,
            combo: 0,
            enemyArmor: 0);

        Assert.Equal(3, breakdown.SynergyDamage);
        Assert.Equal(14, breakdown.FinalDamage);
    }

    [Fact]
    public void CriticalHit_WhenRollWithinChance_MultipliesDamageBeforeArmor()
    {
        var state = DefaultState.Create();
        var towerPos = new GridPoint(8, 8);

        var breakdown = CalculateDamagePipeline(
            state,
            towerPos,
            towerBaseDamage: 8,
            towerLevel: 2,
            wpm: 60.0,
            accuracy: 0.95,
            combo: 0,
            enemyArmor: 4,
            critChance: 0.25,
            critMultiplier: 2.0,
            critRoll: 0.10);

        Assert.True(breakdown.IsCritical);
        Assert.Equal(13, breakdown.DamageBeforeCritical);
        Assert.Equal(26, breakdown.DamageAfterCritical);
        Assert.Equal(22, breakdown.FinalDamage);
    }

    [Fact]
    public void ArmorReduction_SubtractsFromCombinedDamage()
    {
        var state = DefaultState.Create();
        var towerPos = new GridPoint(7, 7);

        var breakdown = CalculateDamagePipeline(
            state,
            towerPos,
            towerBaseDamage: 8,
            towerLevel: 2,
            wpm: 60.0,
            accuracy: 0.95,
            combo: 0,
            enemyArmor: 5);

        Assert.False(breakdown.IsCritical);
        Assert.Equal(13, breakdown.DamageAfterCritical);
        Assert.Equal(8, breakdown.FinalDamage);
    }

    [Fact]
    public void TotalDamage_ComposesTypingTowerSynergyMinusArmor()
    {
        var state = DefaultState.Create();
        var towerPos = new GridPoint(12, 12);
        PlaceTower(state, towerPos, "fire");
        PlaceTower(state, new GridPoint(13, 12), "wind");

        var breakdown = CalculateDamagePipeline(
            state,
            towerPos,
            towerBaseDamage: 8,
            towerLevel: 2,
            wpm: 60.0,
            accuracy: 0.95,
            combo: 0,
            enemyArmor: 4);

        int expected = Math.Max(
            1,
            breakdown.TypingDamage + breakdown.TowerDamage + breakdown.SynergyDamage - breakdown.EnemyArmor);

        Assert.Equal(3, breakdown.TypingDamage);
        Assert.Equal(10, breakdown.TowerDamage);
        Assert.Equal(3, breakdown.SynergyDamage);
        Assert.Equal(12, breakdown.FinalDamage);
        Assert.Equal(expected, breakdown.FinalDamage);
    }

    [Fact]
    public void TotalDamage_NeverDropsBelowOne()
    {
        var state = DefaultState.Create();
        var towerPos = new GridPoint(4, 4);

        var breakdown = CalculateDamagePipeline(
            state,
            towerPos,
            towerBaseDamage: 2,
            towerLevel: 1,
            wpm: 30.0,
            accuracy: 0.50,
            combo: 0,
            enemyArmor: 100);

        Assert.Equal(1, breakdown.FinalDamage);
    }

    private static DamageBreakdown CalculateDamagePipeline(
        GameState state,
        GridPoint towerPos,
        int towerBaseDamage,
        int towerLevel,
        double wpm,
        double accuracy,
        int combo,
        int enemyArmor,
        double critChance = 0.0,
        double critMultiplier = 2.0,
        double critRoll = 1.0)
    {
        int typingDamage = SimBalance.CalculateTypingDamage(
            SimBalance.TypingBaseDamage,
            wpm,
            accuracy,
            combo);
        int towerDamage = SimBalance.CalculateTowerDamage(towerBaseDamage, towerLevel);

        var synergies = TowerSynergies.DetectSynergies(state);
        double synergyMultiplier = TowerSynergies.GetDamageMultiplier(synergies, towerPos);
        int synergyDamage = Math.Max(0, (int)(towerDamage * (synergyMultiplier - 1.0)));

        int damageBeforeCritical = typingDamage + towerDamage + synergyDamage;
        bool isCritical = critRoll <= critChance;
        int damageAfterCritical = isCritical
            ? Math.Max(1, (int)(damageBeforeCritical * critMultiplier))
            : damageBeforeCritical;

        int finalDamage = ApplyPhysicalArmorReduction(damageAfterCritical, enemyArmor);

        return new DamageBreakdown(
            TypingDamage: typingDamage,
            TowerDamage: towerDamage,
            SynergyDamage: synergyDamage,
            DamageBeforeCritical: damageBeforeCritical,
            DamageAfterCritical: damageAfterCritical,
            EnemyArmor: enemyArmor,
            FinalDamage: finalDamage,
            IsCritical: isCritical);
    }

    private static int ApplyPhysicalArmorReduction(int rawDamage, int enemyArmor)
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = enemyArmor,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>(),
        };

        return DamageTypes.CalculateDamage(rawDamage, DamageType.Physical, enemy);
    }

    private static void PlaceTower(GameState state, GridPoint pos, string towerType)
    {
        state.Structures[pos.ToIndex(state.MapW)] = towerType;
    }

    private readonly record struct DamageBreakdown(
        int TypingDamage,
        int TowerDamage,
        int SynergyDamage,
        int DamageBeforeCritical,
        int DamageAfterCritical,
        int EnemyArmor,
        int FinalDamage,
        bool IsCritical);
}
