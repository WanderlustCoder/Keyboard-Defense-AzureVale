using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingMetricsTests
{
    private static GameState CreateInitializedState()
    {
        var state = new GameState();
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static void SetBattleStartSecondsAgo(GameState state, double secondsAgo)
    {
        long ticksAgo = (long)(secondsAgo * Stopwatch.Frequency);
        state.TypingMetrics["battle_start_msec"] = Stopwatch.GetTimestamp() - ticksAgo;
    }

    [Fact]
    public void InitBattleMetrics_SetsExpectedDefaults()
    {
        var state = new GameState();

        TypingMetrics.InitBattleMetrics(state);

        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["battle_chars_typed"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
        Assert.True(Convert.ToInt64(state.TypingMetrics["battle_start_msec"]) > 0);
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["battle_errors"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["perfect_word_streak"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["current_word_errors"]));
        Assert.IsType<List<object>>(state.TypingMetrics["rolling_window_chars"]);
        Assert.IsType<Dictionary<string, object>>(state.TypingMetrics["unique_letters_window"]);
    }

    [Fact]
    public void RecordCharTyped_TracksCharsRollingWindowAndUniqueLetters()
    {
        var state = CreateInitializedState();

        TypingMetrics.RecordCharTyped(state, 'A');
        TypingMetrics.RecordCharTyped(state, 'a');
        TypingMetrics.RecordCharTyped(state, 'b');

        Assert.Equal(3, TypingMetrics.GetCharsTyped(state));
        Assert.Equal(2, TypingMetrics.GetUniqueLetterCount(state));

        var window = Assert.IsType<List<object>>(state.TypingMetrics["rolling_window_chars"]);
        Assert.Equal(3, window.Count);
        var first = Assert.IsType<Dictionary<string, object>>(window[0]);
        Assert.Equal("A", first["char"]);
        Assert.True(Convert.ToInt64(first["time"]) > 0);

        var letters = Assert.IsType<Dictionary<string, object>>(state.TypingMetrics["unique_letters_window"]);
        Assert.Equal(2, Convert.ToInt32(letters["a"]));
        Assert.Equal(1, Convert.ToInt32(letters["b"]));
    }

    [Fact]
    public void RecordError_IncrementsBattleAndCurrentWordErrorCounters()
    {
        var state = CreateInitializedState();

        TypingMetrics.RecordError(state);
        TypingMetrics.RecordError(state);

        Assert.Equal(2, Convert.ToInt32(state.TypingMetrics["battle_errors"]));
        Assert.Equal(2, Convert.ToInt32(state.TypingMetrics["current_word_errors"]));
    }

    [Fact]
    public void RecordWordCompleted_WhenNoErrors_IncrementsWordCountAndStreak()
    {
        var state = CreateInitializedState();

        TypingMetrics.RecordWordCompleted(state);
        TypingMetrics.RecordWordCompleted(state);

        Assert.Equal(2, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
        Assert.Equal(2, Convert.ToInt32(state.TypingMetrics["perfect_word_streak"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["current_word_errors"]));
    }

    [Fact]
    public void RecordWordCompleted_WhenWordHasErrors_ResetsStreakAndCurrentWordErrors()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["perfect_word_streak"] = 4;
        state.TypingMetrics["current_word_errors"] = 1;

        TypingMetrics.RecordWordCompleted(state);

        Assert.Equal(1, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["perfect_word_streak"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["current_word_errors"]));
    }

    [Fact]
    public void GetWpmAndGetCurrentWpm_ReturnZero_WhenElapsedUnderOneSecond()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["battle_chars_typed"] = 50;
        SetBattleStartSecondsAgo(state, 0.5);

        Assert.Equal(0, TypingMetrics.GetWpm(state));
        Assert.Equal(0, TypingMetrics.GetCurrentWpm(state));
    }

    [Fact]
    public void GetWpmAndGetBattleDuration_ReturnExpectedValues_ForOneMinuteSample()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["battle_chars_typed"] = 300;
        SetBattleStartSecondsAgo(state, 60);

        double wpm = TypingMetrics.GetWpm(state);
        double duration = TypingMetrics.GetBattleDuration(state);

        Assert.InRange(wpm, 59.0, 61.0);
        Assert.InRange(duration, 59.0, 61.0);
    }

    [Fact]
    public void GetAccuracy_ReturnsOneWhenNoChars_AndComputesRatioWhenCharsExist()
    {
        var state = CreateInitializedState();

        Assert.Equal(1.0, TypingMetrics.GetAccuracy(state));

        state.TypingMetrics["battle_chars_typed"] = 20;
        state.TypingMetrics["battle_errors"] = 3;
        Assert.Equal(0.85, TypingMetrics.GetAccuracy(state), 6);
    }

    [Fact]
    public void GetAccuracy_ClampsAtZero_WhenErrorsExceedChars()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["battle_chars_typed"] = 2;
        state.TypingMetrics["battle_errors"] = 8;

        Assert.Equal(0.0, TypingMetrics.GetAccuracy(state));
    }

    [Fact]
    public void GetComboCountAndGetPerfectStreak_ReturnCurrentStreakValue()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["perfect_word_streak"] = 7;

        Assert.Equal(7, TypingMetrics.GetComboCount(state));
        Assert.Equal(7, TypingMetrics.GetPerfectStreak(state));
    }

    [Fact]
    public void GetComboMultiplier_UsesConfiguredThresholds()
    {
        Assert.Equal(1.0, TypingMetrics.GetComboMultiplier(0));
        Assert.Equal(1.1, TypingMetrics.GetComboMultiplier(3));
        Assert.Equal(1.25, TypingMetrics.GetComboMultiplier(5));
        Assert.Equal(1.5, TypingMetrics.GetComboMultiplier(10));
        Assert.Equal(2.0, TypingMetrics.GetComboMultiplier(20));
        Assert.Equal(2.5, TypingMetrics.GetComboMultiplier(50));
        Assert.Equal(2.5, TypingMetrics.GetComboMultiplier(80));
    }

    [Fact]
    public void GetUniqueLetterCount_ReturnsZero_WhenUniqueLettersWindowIsMissing()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["unique_letters_window"] = new List<object>();

        Assert.Equal(0, TypingMetrics.GetUniqueLetterCount(state));
    }

    [Fact]
    public void IncrementCombo_IncrementsStreakAndUpdatesMaxComboEver()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["perfect_word_streak"] = 4;
        state.MaxComboEver = 4;

        TypingMetrics.IncrementCombo(state);

        Assert.Equal(5, TypingMetrics.GetComboCount(state));
        Assert.Equal(5, state.MaxComboEver);
    }

    [Fact]
    public void IncrementCombo_DoesNotReduceExistingMaxComboEver()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["perfect_word_streak"] = 2;
        state.MaxComboEver = 10;

        TypingMetrics.IncrementCombo(state);

        Assert.Equal(3, TypingMetrics.GetComboCount(state));
        Assert.Equal(10, state.MaxComboEver);
    }

    [Fact]
    public void ResetCombo_SetsPerfectWordStreakToZero()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["perfect_word_streak"] = 9;

        TypingMetrics.ResetCombo(state);

        Assert.Equal(0, TypingMetrics.GetPerfectStreak(state));
    }
}
