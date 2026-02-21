using System.Collections.Generic;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SimBalanceCoreTests
{
    [Fact]
    public void EconomyConstants_AreExpectedValues()
    {
        Assert.Equal(10, SimBalance.StartingResources["wood"]);
        Assert.Equal(5, SimBalance.StartingResources["stone"]);
        Assert.Equal(5, SimBalance.StartingResources["food"]);
        Assert.Equal(0, SimBalance.StartingResources["gold"]);

        Assert.Equal(40, SimBalance.MidgameCapsDay5["wood"]);
        Assert.Equal(20, SimBalance.MidgameCapsDay5["stone"]);
        Assert.Equal(25, SimBalance.MidgameCapsDay5["food"]);

        Assert.Equal(50, SimBalance.MidgameCapsDay7["wood"]);
        Assert.Equal(35, SimBalance.MidgameCapsDay7["stone"]);
        Assert.Equal(35, SimBalance.MidgameCapsDay7["food"]);

        Assert.Equal(100, SimBalance.EndgameCaps["wood"]);
        Assert.Equal(75, SimBalance.EndgameCaps["stone"]);
        Assert.Equal(50, SimBalance.EndgameCaps["food"]);
        Assert.Equal(1000, SimBalance.EndgameCaps["gold"]);

        Assert.Equal(10, SimBalance.WorkerHireCost);
        Assert.Equal(5, SimBalance.MaxWorkersBase);
        Assert.Equal(2, SimBalance.MaxWorkersPerHouse);
    }

    [Fact]
    public void CombatConstants_AreExpectedValues()
    {
        Assert.Equal(2, SimBalance.EnemyHpBase);
        Assert.Equal(3, SimBalance.EnemyHpDayDivisor);
        Assert.Equal(4, SimBalance.EnemyHpThreatDivisor);

        Assert.Equal(10, SimBalance.BossHpBase);
        Assert.Equal(2, SimBalance.BossHpDayDivisor);
        Assert.Equal(3, SimBalance.BossHpThreatDivisor);

        Assert.Equal(3, SimBalance.WaveEnemyBaseCount);
        Assert.Equal(1, SimBalance.WaveEnemyPerDay);
        Assert.Equal(0.5, SimBalance.WaveEnemyPerThreat, 5);

        Assert.Equal(10, SimBalance.ThreatMax);
        Assert.Equal(1, SimBalance.TypingBaseDamage);
        Assert.Equal(0.1, SimBalance.TypingComboBonusMultiplier, 5);
    }

    [Fact]
    public void TowerConstants_AreExpectedValues()
    {
        Assert.Equal(1.25, SimBalance.TowerUpgradeDamageMult, 5);
        Assert.Equal(1.5, SimBalance.TowerUpgradeCostMult, 5);
        Assert.Equal(5, SimBalance.TowerMaxLevel);
        Assert.Equal(2, SimBalance.TowerMinDistanceFromBase);
    }

    [Fact]
    public void MaybeOverrideExploreReward_BeforeCatchupDay_ReturnsOriginalResource()
    {
        var state = DefaultState.Create();
        state.Day = 3;
        state.Resources["stone"] = 0;

        string resource = SimBalance.MaybeOverrideExploreReward(state, "wood");

        Assert.Equal("wood", resource);
    }

    [Fact]
    public void MaybeOverrideExploreReward_CatchupDayWithLowStone_ReturnsStone()
    {
        var state = DefaultState.Create();
        state.Day = 4;
        state.Resources["stone"] = 9;

        string resource = SimBalance.MaybeOverrideExploreReward(state, "food");

        Assert.Equal("stone", resource);
    }

    [Fact]
    public void MaybeOverrideExploreReward_CatchupDayWithStoneAtMinimum_KeepsOriginalResource()
    {
        var state = DefaultState.Create();
        state.Day = 4;
        state.Resources["stone"] = 10;

        string resource = SimBalance.MaybeOverrideExploreReward(state, "food");

        Assert.Equal("food", resource);
    }

    [Fact]
    public void MidgameFoodBonus_BeforeBonusDay_ReturnsZero()
    {
        var state = DefaultState.Create();
        state.Day = 3;
        state.Resources["food"] = 0;

        int bonus = SimBalance.MidgameFoodBonus(state);

        Assert.Equal(0, bonus);
    }

    [Fact]
    public void MidgameFoodBonus_BonusDayBelowThreshold_ReturnsBonusAmount()
    {
        var state = DefaultState.Create();
        state.Day = 4;
        state.Resources["food"] = 11;

        int bonus = SimBalance.MidgameFoodBonus(state);

        Assert.Equal(2, bonus);
    }

    [Fact]
    public void MidgameFoodBonus_BonusDayAtThreshold_ReturnsZero()
    {
        var state = DefaultState.Create();
        state.Day = 4;
        state.Resources["food"] = 12;

        int bonus = SimBalance.MidgameFoodBonus(state);

        Assert.Equal(0, bonus);
    }

    [Fact]
    public void CapsForDay_DayZero_ReturnsEmptyCaps()
    {
        var caps = SimBalance.CapsForDay(0);

        Assert.Empty(caps);
    }

    [Fact]
    public void CapsForDay_DayFiveAndSix_ReturnDayFiveCaps()
    {
        var dayFiveCaps = SimBalance.CapsForDay(5);
        var daySixCaps = SimBalance.CapsForDay(6);

        Assert.Equal(40, dayFiveCaps["wood"]);
        Assert.Equal(20, dayFiveCaps["stone"]);
        Assert.Equal(25, dayFiveCaps["food"]);

        Assert.Equal(dayFiveCaps["wood"], daySixCaps["wood"]);
        Assert.Equal(dayFiveCaps["stone"], daySixCaps["stone"]);
        Assert.Equal(dayFiveCaps["food"], daySixCaps["food"]);
    }

    [Fact]
    public void CapsForDay_DaySevenAndLater_ReturnDaySevenCaps()
    {
        var daySevenCaps = SimBalance.CapsForDay(7);
        var lateGameCaps = SimBalance.CapsForDay(50);

        Assert.Equal(50, daySevenCaps["wood"]);
        Assert.Equal(35, daySevenCaps["stone"]);
        Assert.Equal(35, daySevenCaps["food"]);

        Assert.Equal(daySevenCaps["wood"], lateGameCaps["wood"]);
        Assert.Equal(daySevenCaps["stone"], lateGameCaps["stone"]);
        Assert.Equal(daySevenCaps["food"], lateGameCaps["food"]);
    }

    [Fact]
    public void ApplyResourceCaps_BeforeMidgame_DoesNotTrimResources()
    {
        var state = DefaultState.Create();
        state.Day = 4;
        state.Resources["wood"] = 999;
        state.Resources["stone"] = 999;
        state.Resources["food"] = 999;

        var trimmed = SimBalance.ApplyResourceCaps(state);

        Assert.Empty(trimmed);
        Assert.Equal(999, state.Resources["wood"]);
        Assert.Equal(999, state.Resources["stone"]);
        Assert.Equal(999, state.Resources["food"]);
    }

    [Fact]
    public void ApplyResourceCaps_DayFive_TrimsOnlyResourcesAboveCap()
    {
        var state = DefaultState.Create();
        state.Day = 5;
        state.Resources["wood"] = 50;
        state.Resources["stone"] = 20;
        state.Resources["food"] = 30;
        state.Resources["gold"] = 500;

        var trimmed = SimBalance.ApplyResourceCaps(state);

        Assert.Equal(2, trimmed.Count);
        Assert.Equal(10, trimmed["wood"]);
        Assert.Equal(5, trimmed["food"]);
        Assert.False(trimmed.ContainsKey("stone"));

        Assert.Equal(40, state.Resources["wood"]);
        Assert.Equal(20, state.Resources["stone"]);
        Assert.Equal(25, state.Resources["food"]);
        Assert.Equal(500, state.Resources["gold"]);
    }

    [Fact]
    public void CalculateEnemyHp_DayZeroThreatZero_ReturnsBaseHp()
    {
        int hp = SimBalance.CalculateEnemyHp(0, 0);

        Assert.Equal(2, hp);
    }

    [Fact]
    public void CalculateEnemyHp_UsesDayAndThreatFormula()
    {
        int hp = SimBalance.CalculateEnemyHp(day: 30, threat: SimBalance.ThreatMax);

        Assert.Equal(14, hp);
    }

    [Fact]
    public void CalculateBossHp_UsesDayThreatAndBonusFormula()
    {
        int hp = SimBalance.CalculateBossHp(day: 9, threat: SimBalance.ThreatMax, hpBonus: 4);

        Assert.Equal(21, hp);
    }

    [Fact]
    public void CalculateWaveSize_UsesFormulaAndClampsToMinimumOne()
    {
        int normal = SimBalance.CalculateWaveSize(day: 4, threat: 6);
        int clamped = SimBalance.CalculateWaveSize(day: -10, threat: -10);

        Assert.Equal(10, normal);
        Assert.Equal(1, clamped);
    }

    [Fact]
    public void CalculateTypingDamage_AppliesThresholdBonusesAndComboMultiplier()
    {
        int damage = SimBalance.CalculateTypingDamage(
            baseDamage: 5,
            wpm: 60,
            accuracy: 0.95,
            combo: 20);

        Assert.Equal(8, damage);
    }

    [Fact]
    public void CalculateTypingDamage_ComboBoundaryAndMinimumClampBehaveAsExpected()
    {
        int comboNine = SimBalance.CalculateTypingDamage(baseDamage: 10, wpm: 0, accuracy: 0.0, combo: 9);
        int comboTen = SimBalance.CalculateTypingDamage(baseDamage: 10, wpm: 0, accuracy: 0.0, combo: 10);
        int clamped = SimBalance.CalculateTypingDamage(baseDamage: 0, wpm: 0, accuracy: 0.0, combo: 0);

        Assert.Equal(10, comboNine);
        Assert.Equal(11, comboTen);
        Assert.Equal(1, clamped);
    }

    [Fact]
    public void CalculateUpgradeCost_LevelTwo_ScalesAndFloorsEachResource()
    {
        var baseCost = new Dictionary<string, int>
        {
            ["wood"] = 10,
            ["stone"] = 3,
        };

        var cost = SimBalance.CalculateUpgradeCost(baseCost, currentLevel: 2);

        Assert.Equal(22, cost["wood"]);
        Assert.Equal(6, cost["stone"]);
    }

    [Fact]
    public void CalculateTowerDamage_LevelScaling_UsesLevelMinusOneExponent()
    {
        int levelOneDamage = SimBalance.CalculateTowerDamage(baseDamage: 10, level: 1);
        int levelFiveDamage = SimBalance.CalculateTowerDamage(baseDamage: 10, level: 5);

        Assert.Equal(10, levelOneDamage);
        Assert.Equal(24, levelFiveDamage);
    }

    [Fact]
    public void CheckMilestone_WhenBehindOnKnownMilestone_ReturnsAllIssues()
    {
        var (onTrack, issues) = SimBalance.CheckMilestone(day: 5, buildings: 4, towers: 1, gold: 49);

        Assert.False(onTrack);
        Assert.Equal(3, issues.Count);
        Assert.Contains("Buildings behind (4/5)", issues);
        Assert.Contains("Towers behind (1/2)", issues);
        Assert.Contains("Gold behind (49/50)", issues);
    }

    [Fact]
    public void CheckMilestone_WhenNoMilestoneForDay_ReturnsOnTrack()
    {
        var (onTrack, issues) = SimBalance.CheckMilestone(day: 2, buildings: 0, towers: 0, gold: 0);

        Assert.True(onTrack);
        Assert.Empty(issues);
    }

    [Fact]
    public void GetDifficultyFactorAndGoldReward_ScaleByDayFormula()
    {
        double dayZeroDifficulty = SimBalance.GetDifficultyFactor(0);
        double dayElevenDifficulty = SimBalance.GetDifficultyFactor(11);
        int dayZeroGold = SimBalance.CalculateGoldReward(baseGold: 100, day: 0);
        int dayTenGold = SimBalance.CalculateGoldReward(baseGold: 100, day: 10);

        Assert.Equal(0.9, dayZeroDifficulty, 5);
        Assert.Equal(2.0, dayElevenDifficulty, 5);
        Assert.Equal(100, dayZeroGold);
        Assert.Equal(150, dayTenGold);
    }
}
