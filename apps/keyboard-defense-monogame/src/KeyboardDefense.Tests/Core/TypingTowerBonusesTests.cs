using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingTowerBonusesCoreTests
{
    [Fact]
    public void Constants_HaveExpectedValues()
    {
        Assert.Equal(100.0, TypingTowerBonuses.WordsmithWpmScale);
        Assert.Equal(2.0, TypingTowerBonuses.WordsmithAccuracyPower);
        Assert.Equal(1.5, TypingTowerBonuses.ArcaneMaxAccuracyBonus);
        Assert.Equal(0.05, TypingTowerBonuses.LetterSpiritPerLetter);
        Assert.Equal(1.30, TypingTowerBonuses.LetterSpiritMaxBonus);
        Assert.Equal(0.5, TypingTowerBonuses.MinAccuracyForBonus);
    }

    [Fact]
    public void GetChainBonus_NonTeslaTower_ReturnsZero()
    {
        var state = CreateState();
        SetCombo(state, 60);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Magic);

        Assert.Equal(0, chain);
    }

    [Fact]
    public void GetChainBonus_TeslaComboBelowTen_ReturnsZero()
    {
        var state = CreateState();
        SetCombo(state, 9);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Tesla);

        Assert.Equal(0, chain);
    }

    [Fact]
    public void GetChainBonus_TeslaComboAtTen_ReturnsOne()
    {
        var state = CreateState();
        SetCombo(state, 10);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Tesla);

        Assert.Equal(1, chain);
    }

    [Fact]
    public void GetChainBonus_TeslaComboAtNineteen_ReturnsOne()
    {
        var state = CreateState();
        SetCombo(state, 19);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Tesla);

        Assert.Equal(1, chain);
    }

    [Fact]
    public void GetChainBonus_TeslaComboAtTwenty_ReturnsTwo()
    {
        var state = CreateState();
        SetCombo(state, 20);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Tesla);

        Assert.Equal(2, chain);
    }

    [Fact]
    public void GetChainBonus_TeslaComboAtFortyNine_ReturnsTwo()
    {
        var state = CreateState();
        SetCombo(state, 49);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Tesla);

        Assert.Equal(2, chain);
    }

    [Fact]
    public void GetChainBonus_TeslaComboAtFifty_ReturnsThree()
    {
        var state = CreateState();
        SetCombo(state, 50);

        int chain = TypingTowerBonuses.GetChainBonus(state, TowerTypes.Tesla);

        Assert.Equal(3, chain);
    }

    [Fact]
    public void GetAttackSpeedMultiplier_BattleUnderOneSecond_ReturnsMinimumClamp()
    {
        var state = CreateState();
        SetTypingWindow(state, charsTyped: 2000, secondsElapsed: 0.5);

        double speedMult = TypingTowerBonuses.GetAttackSpeedMultiplier(state, TowerTypes.Wordsmith);

        Assert.Equal(1.0, speedMult, 5);
    }

    [Fact]
    public void GetAttackSpeedMultiplier_WpmAroundOneHundred_ReturnsOnePointFive()
    {
        var state = CreateState();
        SetTypingWindow(state, charsTyped: 500, secondsElapsed: 60.0);

        double speedMult = TypingTowerBonuses.GetAttackSpeedMultiplier(state, TowerTypes.Arcane);

        Assert.InRange(speedMult, 1.49, 1.51);
    }

    [Fact]
    public void GetAttackSpeedMultiplier_HighWpm_ClampsAtTwo()
    {
        var state = CreateState();
        SetTypingWindow(state, charsTyped: 1500, secondsElapsed: 60.0);

        double speedMult = TypingTowerBonuses.GetAttackSpeedMultiplier(state, TowerTypes.Tesla);

        Assert.Equal(2.0, speedMult, 5);
    }

    [Fact]
    public void GetAttackSpeedMultiplier_UnknownTower_StillUsesWpmScaling()
    {
        var state = CreateState();
        SetTypingWindow(state, charsTyped: 250, secondsElapsed: 60.0);

        double speedMult = TypingTowerBonuses.GetAttackSpeedMultiplier(state, "unknown_tower");

        Assert.InRange(speedMult, 1.24, 1.26);
    }

    [Fact]
    public void GetLetterShrineMode_UniqueCountAtTwenty_ReturnsEpsilon()
    {
        var state = CreateState();
        state.TypingMetrics["unique_letters_window"] = CreateUniqueLetters(20);
        SetCombo(state, 0);

        string mode = TypingTowerBonuses.GetLetterShrineMode(state);

        Assert.Equal("epsilon", mode);
    }

    [Fact]
    public void GetLetterShrineMode_UniqueBelowTwentyAndComboAtThirty_ReturnsOmega()
    {
        var state = CreateState();
        state.TypingMetrics["unique_letters_window"] = CreateUniqueLetters(19);
        SetCombo(state, 30);

        string mode = TypingTowerBonuses.GetLetterShrineMode(state);

        Assert.Equal("omega", mode);
    }

    [Fact]
    public void GetLetterShrineMode_UniqueBelowTwentyAndComboBelowThirty_ReturnsAlpha()
    {
        var state = CreateState();
        state.TypingMetrics["unique_letters_window"] = CreateUniqueLetters(19);
        SetCombo(state, 29);

        string mode = TypingTowerBonuses.GetLetterShrineMode(state);

        Assert.Equal("alpha", mode);
    }

    [Fact]
    public void GetLetterShrineMode_UniqueThresholdTakesPriorityOverComboThreshold()
    {
        var state = CreateState();
        state.TypingMetrics["unique_letters_window"] = CreateUniqueLetters(20);
        SetCombo(state, 100);

        string mode = TypingTowerBonuses.GetLetterShrineMode(state);

        Assert.Equal("epsilon", mode);
    }

    [Fact]
    public void GetTowerDamageMultiplier_DefaultTowerNoCombo_ReturnsOne()
    {
        var state = CreateState();
        SetCombo(state, 0);

        double multiplier = TypingTowerBonuses.GetTowerDamageMultiplier(state, "unknown_tower");

        Assert.Equal(1.0, multiplier, 5);
    }

    [Fact]
    public void GetTowerDamageMultiplier_DefaultTowerComboThree_UsesComboMultiplier()
    {
        var state = CreateState();
        SetCombo(state, 3);

        double multiplier = TypingTowerBonuses.GetTowerDamageMultiplier(state, "unknown_tower");

        Assert.Equal(1.1, multiplier, 5);
    }

    [Fact]
    public void GetTowerDamageMultiplier_DefaultTowerComboTen_UsesComboMultiplier()
    {
        var state = CreateState();
        SetCombo(state, 10);

        double multiplier = TypingTowerBonuses.GetTowerDamageMultiplier(state, "unknown_tower");

        Assert.Equal(1.5, multiplier, 5);
    }

    [Fact]
    public void GetTowerDamageMultiplier_DefaultTowerComboFifty_UsesComboMultiplier()
    {
        var state = CreateState();
        SetCombo(state, 50);

        double multiplier = TypingTowerBonuses.GetTowerDamageMultiplier(state, "unknown_tower");

        Assert.Equal(2.5, multiplier, 5);
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create();
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static void SetCombo(GameState state, int combo)
    {
        state.TypingMetrics["perfect_word_streak"] = combo;
    }

    private static void SetTypingWindow(GameState state, int charsTyped, double secondsElapsed)
    {
        state.TypingMetrics["battle_chars_typed"] = charsTyped;
        state.TypingMetrics["battle_start_msec"] =
            Stopwatch.GetTimestamp() - (long)(secondsElapsed * Stopwatch.Frequency);
    }

    private static Dictionary<string, object> CreateUniqueLetters(int count)
    {
        var letters = new Dictionary<string, object>(count);
        for (int i = 0; i < count; i++)
            letters[$"k{i}"] = 1;
        return letters;
    }
}
