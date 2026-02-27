using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for SimBalance — AddGold clamping, calculation edge cases,
/// milestone boundary coverage, and resource cap interactions.
/// </summary>
public class SimBalanceExtendedTests
{
    // =========================================================================
    // AddGold — clamping
    // =========================================================================

    [Fact]
    public void AddGold_NormalAmount_AddsDirectly()
    {
        var state = new GameState();
        SimBalance.AddGold(state, 100);
        Assert.Equal(100, state.Gold);
    }

    [Fact]
    public void AddGold_ExceedsCap_ClampsToGoldCap()
    {
        var state = new GameState();
        SimBalance.AddGold(state, SimBalance.GoldCap + 100);
        Assert.Equal(SimBalance.GoldCap, state.Gold);
    }

    [Fact]
    public void AddGold_MultipleAdditions_ClampsToGoldCap()
    {
        var state = new GameState();
        SimBalance.AddGold(state, 500_000);
        SimBalance.AddGold(state, 500_000);
        Assert.Equal(SimBalance.GoldCap, state.Gold);
    }

    [Fact]
    public void AddGold_ZeroAmount_DoesNotChangeGold()
    {
        var state = new GameState();
        state.Gold = 42;
        SimBalance.AddGold(state, 0);
        Assert.Equal(42, state.Gold);
    }

    [Fact]
    public void GoldCap_Is999999()
    {
        Assert.Equal(999_999, SimBalance.GoldCap);
    }

    // =========================================================================
    // CalculateEnemyHp — edge cases
    // =========================================================================

    [Theory]
    [InlineData(0, 0, 2)]    // base only
    [InlineData(3, 0, 3)]    // day=3 adds 1
    [InlineData(0, 4, 3)]    // threat=4 adds 1
    [InlineData(6, 8, 6)]    // day/3=2 + threat/4=2 + base=2
    public void CalculateEnemyHp_VariousInputs(int day, int threat, int expected)
    {
        Assert.Equal(expected, SimBalance.CalculateEnemyHp(day, threat));
    }

    [Fact]
    public void CalculateEnemyHp_MaxThreat_IsHigherThanBaseline()
    {
        int baseline = SimBalance.CalculateEnemyHp(1, 0);
        int maxThreat = SimBalance.CalculateEnemyHp(1, SimBalance.ThreatMax);
        Assert.True(maxThreat > baseline);
    }

    // =========================================================================
    // CalculateBossHp — edge cases
    // =========================================================================

    [Fact]
    public void CalculateBossHp_ZeroBonus_UsesBaseFormula()
    {
        int hp = SimBalance.CalculateBossHp(0, 0, 0);
        Assert.Equal(10, hp); // BossHpBase
    }

    [Fact]
    public void CalculateBossHp_WithBonus_AddsDirectly()
    {
        int withBonus = SimBalance.CalculateBossHp(0, 0, 5);
        int without = SimBalance.CalculateBossHp(0, 0, 0);
        Assert.Equal(5, withBonus - without);
    }

    [Fact]
    public void CalculateBossHp_AlwaysHigherThanEnemyHp()
    {
        for (int day = 0; day <= 20; day++)
        {
            for (int threat = 0; threat <= SimBalance.ThreatMax; threat++)
            {
                int bossHp = SimBalance.CalculateBossHp(day, threat);
                int enemyHp = SimBalance.CalculateEnemyHp(day, threat);
                Assert.True(bossHp > enemyHp,
                    $"Boss HP ({bossHp}) should exceed enemy HP ({enemyHp}) at day={day}, threat={threat}");
            }
        }
    }

    // =========================================================================
    // CalculateWaveSize — edge cases
    // =========================================================================

    [Fact]
    public void CalculateWaveSize_DayZeroThreatZero_ReturnsBaseCount()
    {
        int size = SimBalance.CalculateWaveSize(0, 0);
        Assert.Equal(SimBalance.WaveEnemyBaseCount, size);
    }

    [Fact]
    public void CalculateWaveSize_NegativeInputs_ClampsToOne()
    {
        int size = SimBalance.CalculateWaveSize(-100, -100);
        Assert.Equal(1, size);
    }

    [Fact]
    public void CalculateWaveSize_HighDay_IncreasesProperly()
    {
        int dayOne = SimBalance.CalculateWaveSize(1, 0);
        int dayTen = SimBalance.CalculateWaveSize(10, 0);
        Assert.Equal(9, dayTen - dayOne); // 9 * WaveEnemyPerDay
    }

    [Fact]
    public void CalculateWaveSize_ThreatContributes()
    {
        int noThreat = SimBalance.CalculateWaveSize(5, 0);
        int fullThreat = SimBalance.CalculateWaveSize(5, 10);
        Assert.True(fullThreat > noThreat);
        Assert.Equal(5, fullThreat - noThreat); // 10 * 0.5
    }

    // =========================================================================
    // CalculateTypingDamage — edge cases
    // =========================================================================

    [Fact]
    public void CalculateTypingDamage_ZeroBaseDamage_ClampsToOne()
    {
        int damage = SimBalance.CalculateTypingDamage(0, 0, 0, 0);
        Assert.Equal(1, damage);
    }

    [Fact]
    public void CalculateTypingDamage_BothBonuses_AddTwo()
    {
        // WPM >= 60 AND accuracy >= 0.95 → base + 2
        int damage = SimBalance.CalculateTypingDamage(1, 60, 0.95, 0);
        Assert.Equal(3, damage); // 1 + 1 + 1
    }

    [Fact]
    public void CalculateTypingDamage_ComboAtTen_AppliesOnePointOne()
    {
        int damage = SimBalance.CalculateTypingDamage(10, 0, 0, 10);
        // 10 * (1.0 + 0.1) = 11
        Assert.Equal(11, damage);
    }

    [Fact]
    public void CalculateTypingDamage_ComboAtNine_NoBonus()
    {
        int damage = SimBalance.CalculateTypingDamage(10, 0, 0, 9);
        // 9/10 = 0, so multiplier = 1.0
        Assert.Equal(10, damage);
    }

    [Fact]
    public void CalculateTypingDamage_HighCombo_ScalesLinearly()
    {
        int combo50 = SimBalance.CalculateTypingDamage(10, 0, 0, 50);
        // 10 * (1.0 + 5*0.1) = 10 * 1.5 = 15
        Assert.Equal(15, combo50);
    }

    [Fact]
    public void CalculateTypingDamage_WpmJustBelowThreshold_NoBonusDamage()
    {
        int damage = SimBalance.CalculateTypingDamage(5, 59, 0.5, 0);
        Assert.Equal(5, damage);
    }

    [Fact]
    public void CalculateTypingDamage_AccuracyJustBelowThreshold_NoBonusDamage()
    {
        int damage = SimBalance.CalculateTypingDamage(5, 30, 0.949, 0);
        Assert.Equal(5, damage);
    }

    // =========================================================================
    // CalculateUpgradeCost — edge cases
    // =========================================================================

    [Fact]
    public void CalculateUpgradeCost_LevelZero_ReturnsBaseCost()
    {
        var baseCost = new Dictionary<string, int> { ["wood"] = 10 };
        var cost = SimBalance.CalculateUpgradeCost(baseCost, 0);
        Assert.Equal(10, cost["wood"]); // 1.5^0 = 1
    }

    [Fact]
    public void CalculateUpgradeCost_LevelOne_Scales()
    {
        var baseCost = new Dictionary<string, int> { ["wood"] = 10 };
        var cost = SimBalance.CalculateUpgradeCost(baseCost, 1);
        Assert.Equal(15, cost["wood"]); // 10 * 1.5 = 15
    }

    [Fact]
    public void CalculateUpgradeCost_MultipleResources_ScalesAll()
    {
        var baseCost = new Dictionary<string, int> { ["wood"] = 10, ["stone"] = 20, ["gold"] = 5 };
        var cost = SimBalance.CalculateUpgradeCost(baseCost, 1);
        Assert.Equal(15, cost["wood"]);
        Assert.Equal(30, cost["stone"]);
        Assert.Equal(7, cost["gold"]); // (int)(5 * 1.5) = 7
    }

    [Fact]
    public void CalculateUpgradeCost_EmptyBaseCost_ReturnsEmpty()
    {
        var cost = SimBalance.CalculateUpgradeCost(new Dictionary<string, int>(), 3);
        Assert.Empty(cost);
    }

    // =========================================================================
    // CalculateTowerDamage — edge cases
    // =========================================================================

    [Fact]
    public void CalculateTowerDamage_LevelOne_ReturnsBaseDamage()
    {
        Assert.Equal(10, SimBalance.CalculateTowerDamage(10, 1));
    }

    [Fact]
    public void CalculateTowerDamage_LevelTwo_Multiplies()
    {
        // 10 * 1.25^1 = 12 (truncated)
        Assert.Equal(12, SimBalance.CalculateTowerDamage(10, 2));
    }

    [Fact]
    public void CalculateTowerDamage_MaxLevel_ExceedsDouble()
    {
        int maxLevelDmg = SimBalance.CalculateTowerDamage(10, SimBalance.TowerMaxLevel);
        Assert.True(maxLevelDmg > 20);
    }

    // =========================================================================
    // MaybeOverrideExploreReward — additional edge cases
    // =========================================================================

    [Fact]
    public void MaybeOverrideExploreReward_StoneAlreadyAboveMin_KeepsOriginal()
    {
        var state = DefaultState.Create();
        state.Day = 10;
        state.Resources["stone"] = 20;
        Assert.Equal("wood", SimBalance.MaybeOverrideExploreReward(state, "wood"));
    }

    [Fact]
    public void MaybeOverrideExploreReward_StoneIsRequestedButLow_ReturnsStone()
    {
        var state = DefaultState.Create();
        state.Day = 5;
        state.Resources["stone"] = 5;
        // Even if original reward was stone, the override still returns stone
        Assert.Equal("stone", SimBalance.MaybeOverrideExploreReward(state, "stone"));
    }

    // =========================================================================
    // MidgameFoodBonus — additional edge cases
    // =========================================================================

    [Fact]
    public void MidgameFoodBonus_FoodAtZero_ReturnsBonus()
    {
        var state = DefaultState.Create();
        state.Day = 10;
        state.Resources["food"] = 0;
        Assert.Equal(SimBalance.MidgameFoodBonusAmount, SimBalance.MidgameFoodBonus(state));
    }

    [Fact]
    public void MidgameFoodBonus_FoodJustBelowThreshold_ReturnsBonus()
    {
        var state = DefaultState.Create();
        state.Day = 4;
        state.Resources["food"] = 11;
        Assert.Equal(SimBalance.MidgameFoodBonusAmount, SimBalance.MidgameFoodBonus(state));
    }

    // =========================================================================
    // CapsForDay — boundary
    // =========================================================================

    [Theory]
    [InlineData(0, false)]
    [InlineData(1, false)]
    [InlineData(4, false)]
    [InlineData(5, true)]
    [InlineData(6, true)]
    [InlineData(7, true)]
    [InlineData(100, true)]
    public void CapsForDay_HasCaps_AfterDay5(int day, bool hasCaps)
    {
        var caps = SimBalance.CapsForDay(day);
        Assert.Equal(hasCaps, caps.Count > 0);
    }

    // =========================================================================
    // ApplyResourceCaps — additional edge cases
    // =========================================================================

    [Fact]
    public void ApplyResourceCaps_ResourcesExactlyAtCap_NoTrim()
    {
        var state = DefaultState.Create();
        state.Day = 5;
        state.Resources["wood"] = 40;
        state.Resources["stone"] = 20;
        state.Resources["food"] = 25;

        var trimmed = SimBalance.ApplyResourceCaps(state);

        Assert.Empty(trimmed);
        Assert.Equal(40, state.Resources["wood"]);
        Assert.Equal(20, state.Resources["stone"]);
        Assert.Equal(25, state.Resources["food"]);
    }

    [Fact]
    public void ApplyResourceCaps_ResourcesJustAboveCap_TrimsByOne()
    {
        var state = DefaultState.Create();
        state.Day = 7;
        state.Resources["wood"] = 51;

        var trimmed = SimBalance.ApplyResourceCaps(state);

        Assert.Equal(1, trimmed["wood"]);
        Assert.Equal(50, state.Resources["wood"]);
    }

    // =========================================================================
    // CheckMilestone — all milestone days
    // =========================================================================

    [Theory]
    [InlineData(1)]
    [InlineData(3)]
    [InlineData(5)]
    [InlineData(7)]
    [InlineData(10)]
    [InlineData(15)]
    [InlineData(20)]
    public void CheckMilestone_AllMilestoneDays_HaveExpectedRequirements(int day)
    {
        Assert.True(SimBalance.ProgressionMilestones.ContainsKey(day));
    }

    [Fact]
    public void CheckMilestone_Day20_HasHighestTargets()
    {
        var m = SimBalance.ProgressionMilestones[20];
        Assert.Equal(20, m.Buildings);
        Assert.Equal(10, m.Towers);
        Assert.Equal(750, m.Gold);
    }

    [Fact]
    public void CheckMilestone_ExactlyMeetingTargets_IsOnTrack()
    {
        var m = SimBalance.ProgressionMilestones[5];
        var (onTrack, issues) = SimBalance.CheckMilestone(5, m.Buildings, m.Towers, m.Gold);
        Assert.True(onTrack);
        Assert.Empty(issues);
    }

    [Fact]
    public void CheckMilestone_ExceedingTargets_IsOnTrack()
    {
        var (onTrack, issues) = SimBalance.CheckMilestone(1, 100, 100, 10000);
        Assert.True(onTrack);
        Assert.Empty(issues);
    }

    // =========================================================================
    // GetDifficultyFactor — various days
    // =========================================================================

    [Theory]
    [InlineData(1, 1.0)]
    [InlineData(11, 2.0)]
    [InlineData(21, 3.0)]
    public void GetDifficultyFactor_ScalesLinearly(int day, double expected)
    {
        Assert.Equal(expected, SimBalance.GetDifficultyFactor(day), 5);
    }

    [Fact]
    public void GetDifficultyFactor_AlwaysPositive()
    {
        for (int day = 0; day <= 100; day++)
        {
            Assert.True(SimBalance.GetDifficultyFactor(day) > 0);
        }
    }

    // =========================================================================
    // CalculateGoldReward — various days
    // =========================================================================

    [Fact]
    public void CalculateGoldReward_DayZero_ReturnsBase()
    {
        Assert.Equal(100, SimBalance.CalculateGoldReward(100, 0));
    }

    [Fact]
    public void CalculateGoldReward_Day20_Scales()
    {
        int reward = SimBalance.CalculateGoldReward(100, 20);
        // 100 * (1.0 + 20*0.05) = 100 * 2.0 = 200
        Assert.Equal(200, reward);
    }

    [Fact]
    public void CalculateGoldReward_ZeroBase_ReturnsZero()
    {
        Assert.Equal(0, SimBalance.CalculateGoldReward(0, 10));
    }

    // =========================================================================
    // Victory constants
    // =========================================================================

    [Fact]
    public void VictoryConstants_AreExpected()
    {
        Assert.Equal(10000, SimBalance.VictoryGoldTarget);
        Assert.Equal(50, SimBalance.VictorySurvivalWaves);
    }

    // =========================================================================
    // ResourceCap
    // =========================================================================

    [Fact]
    public void ResourceCap_Is999()
    {
        Assert.Equal(999, SimBalance.ResourceCap);
    }
}
