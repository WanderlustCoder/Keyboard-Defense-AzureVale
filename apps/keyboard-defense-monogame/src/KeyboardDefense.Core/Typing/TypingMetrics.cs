using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Tracks and calculates typing performance (WPM, accuracy, combo).
/// Ported from sim/typing_metrics.gd.
/// </summary>
public static class TypingMetrics
{
    /// <summary>
    /// Size of the rolling typing window used for WPM-style metric sampling, in milliseconds.
    /// </summary>
    public const int WpmWindowMs = 10000;

    /// <summary>
    /// Number of characters treated as one word for WPM calculations.
    /// </summary>
    public const double CharsPerWord = 5.0;

    /// <summary>
    /// Combo breakpoints that map to multiplier tiers.
    /// </summary>
    public static readonly int[] ComboThresholds = { 3, 5, 10, 20, 50 };

    /// <summary>
    /// Damage multipliers paired with <see cref="ComboThresholds"/>.
    /// </summary>
    public static readonly double[] ComboMultipliers = { 1.1, 1.25, 1.5, 2.0, 2.5 };

    /// <summary>
    /// Initializes per-battle typing metrics on the supplied game state.
    /// </summary>
    /// <param name="state">The game state that will hold battle typing metrics.</param>
    public static void InitBattleMetrics(GameState state)
    {
        state.TypingMetrics = new Dictionary<string, object>
        {
            ["battle_chars_typed"] = 0,
            ["battle_words_typed"] = 0,
            ["battle_start_msec"] = Stopwatch.GetTimestamp(),
            ["battle_errors"] = 0,
            ["rolling_window_chars"] = new List<object>(),
            ["unique_letters_window"] = new Dictionary<string, object>(),
            ["perfect_word_streak"] = 0,
            ["current_word_errors"] = 0,
        };
    }

    /// <summary>
    /// Records a successfully typed character into battle totals and rolling windows.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <param name="ch">The character that was typed.</param>
    public static void RecordCharTyped(GameState state, char ch)
    {
        var m = state.TypingMetrics;
        m["battle_chars_typed"] = Convert.ToInt32(m["battle_chars_typed"]) + 1;

        if (m["rolling_window_chars"] is List<object> window)
        {
            window.Add(new Dictionary<string, object>
            {
                ["char"] = ch.ToString(),
                ["time"] = Stopwatch.GetTimestamp(),
            });
        }

        if (m["unique_letters_window"] is Dictionary<string, object> letters)
        {
            string key = ch.ToString().ToLowerInvariant();
            letters[key] = Convert.ToInt32(letters.GetValueOrDefault(key, 0)) + 1;
        }
    }

    /// <summary>
    /// Records a typing error for the current battle and current word.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    public static void RecordError(GameState state)
    {
        var m = state.TypingMetrics;
        m["battle_errors"] = Convert.ToInt32(m["battle_errors"]) + 1;
        m["current_word_errors"] = Convert.ToInt32(m["current_word_errors"]) + 1;
    }

    /// <summary>
    /// Records completion of the current word and updates the perfect-word streak.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    public static void RecordWordCompleted(GameState state)
    {
        var m = state.TypingMetrics;
        m["battle_words_typed"] = Convert.ToInt32(m["battle_words_typed"]) + 1;
        int errors = Convert.ToInt32(m["current_word_errors"]);
        if (errors == 0)
            m["perfect_word_streak"] = Convert.ToInt32(m["perfect_word_streak"]) + 1;
        else
            m["perfect_word_streak"] = 0;
        m["current_word_errors"] = 0;
    }

    /// <summary>
    /// Computes words per minute using battle character count and elapsed battle time.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The current WPM value, or <c>0</c> when less than one second has elapsed.</returns>
    public static double GetWpm(GameState state)
    {
        var m = state.TypingMetrics;
        int chars = Convert.ToInt32(m.GetValueOrDefault("battle_chars_typed", 0));
        long start = Convert.ToInt64(m.GetValueOrDefault("battle_start_msec", 0L));
        long now = Stopwatch.GetTimestamp();
        double elapsedMs = (double)(now - start) / Stopwatch.Frequency * 1000.0;
        if (elapsedMs < 1000) return 0;
        double minutes = elapsedMs / 60000.0;
        return (chars / CharsPerWord) / minutes;
    }

    /// <summary>
    /// Computes current typing accuracy for the active battle.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>
    /// A value in the range [0, 1], where <c>1</c> means no recorded errors.
    /// </returns>
    public static double GetAccuracy(GameState state)
    {
        var m = state.TypingMetrics;
        int chars = Convert.ToInt32(m.GetValueOrDefault("battle_chars_typed", 0));
        int errors = Convert.ToInt32(m.GetValueOrDefault("battle_errors", 0));
        if (chars == 0) return 1.0;
        return Math.Max(0, (double)(chars - errors) / chars);
    }

    /// <summary>
    /// Gets the current combo count based on the perfect-word streak.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The number of consecutive words completed without errors.</returns>
    public static int GetComboCount(GameState state)
    {
        var m = state.TypingMetrics;
        return Convert.ToInt32(m.GetValueOrDefault("perfect_word_streak", 0));
    }

    /// <summary>
    /// Resolves the combo damage multiplier for a given combo count.
    /// </summary>
    /// <param name="combo">The current combo count.</param>
    /// <returns>The multiplier matching the highest reached combo threshold, or <c>1.0</c>.</returns>
    public static double GetComboMultiplier(int combo)
    {
        for (int i = ComboThresholds.Length - 1; i >= 0; i--)
        {
            if (combo >= ComboThresholds[i])
                return ComboMultipliers[i];
        }
        return 1.0;
    }

    /// <summary>
    /// Gets the number of distinct letters typed in the tracked window.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The count of unique letter keys recorded in the current window.</returns>
    public static int GetUniqueLetterCount(GameState state)
    {
        var m = state.TypingMetrics;
        if (m.GetValueOrDefault("unique_letters_window") is Dictionary<string, object> letters)
            return letters.Count;
        return 0;
    }

    /// <summary>
    /// Gets the current perfect-word streak.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The number of consecutive words completed without errors.</returns>
    public static int GetPerfectStreak(GameState state)
    {
        var m = state.TypingMetrics;
        return Convert.ToInt32(m.GetValueOrDefault("perfect_word_streak", 0));
    }

    /// <summary>
    /// Gets the total number of characters typed in the current battle.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The total number of recorded typed characters.</returns>
    public static int GetCharsTyped(GameState state)
    {
        var m = state.TypingMetrics;
        return Convert.ToInt32(m.GetValueOrDefault("battle_chars_typed", 0));
    }

    /// <summary>
    /// Gets elapsed battle duration in seconds based on the stored battle start timestamp.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The elapsed duration, in seconds.</returns>
    public static double GetBattleDuration(GameState state)
    {
        var m = state.TypingMetrics;
        long start = Convert.ToInt64(m.GetValueOrDefault("battle_start_msec", 0L));
        long now = Stopwatch.GetTimestamp();
        return (double)(now - start) / Stopwatch.Frequency;
    }

    /// <summary>
    /// Alias for <see cref="GetWpm"/> that returns current words per minute.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    /// <returns>The current WPM value.</returns>
    public static double GetCurrentWpm(GameState state) => GetWpm(state);

    /// <summary>
    /// Increments the perfect-word streak (combo counter) and updates max combo history.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    public static void IncrementCombo(GameState state)
    {
        var m = state.TypingMetrics;
        m["perfect_word_streak"] = Convert.ToInt32(m.GetValueOrDefault("perfect_word_streak", 0)) + 1;
        int newCombo = Convert.ToInt32(m["perfect_word_streak"]);
        if (newCombo > state.MaxComboEver)
            state.MaxComboEver = newCombo;
    }

    /// <summary>
    /// Resets the perfect-word streak (combo counter) to zero.
    /// </summary>
    /// <param name="state">The game state containing active typing metrics.</param>
    public static void ResetCombo(GameState state)
    {
        state.TypingMetrics["perfect_word_streak"] = 0;
    }
}
