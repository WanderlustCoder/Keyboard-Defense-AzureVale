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
    public const int WpmWindowMs = 10000;
    public const double CharsPerWord = 5.0;
    public static readonly int[] ComboThresholds = { 3, 5, 10, 20, 50 };
    public static readonly double[] ComboMultipliers = { 1.1, 1.25, 1.5, 2.0, 2.5 };

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

    public static void RecordError(GameState state)
    {
        var m = state.TypingMetrics;
        m["battle_errors"] = Convert.ToInt32(m["battle_errors"]) + 1;
        m["current_word_errors"] = Convert.ToInt32(m["current_word_errors"]) + 1;
    }

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

    public static double GetAccuracy(GameState state)
    {
        var m = state.TypingMetrics;
        int chars = Convert.ToInt32(m.GetValueOrDefault("battle_chars_typed", 0));
        int errors = Convert.ToInt32(m.GetValueOrDefault("battle_errors", 0));
        if (chars == 0) return 1.0;
        return Math.Max(0, (double)(chars - errors) / chars);
    }

    public static int GetComboCount(GameState state)
    {
        var m = state.TypingMetrics;
        return Convert.ToInt32(m.GetValueOrDefault("perfect_word_streak", 0));
    }

    public static double GetComboMultiplier(int combo)
    {
        for (int i = ComboThresholds.Length - 1; i >= 0; i--)
        {
            if (combo >= ComboThresholds[i])
                return ComboMultipliers[i];
        }
        return 1.0;
    }

    public static int GetUniqueLetterCount(GameState state)
    {
        var m = state.TypingMetrics;
        if (m.GetValueOrDefault("unique_letters_window") is Dictionary<string, object> letters)
            return letters.Count;
        return 0;
    }

    public static int GetPerfectStreak(GameState state)
    {
        var m = state.TypingMetrics;
        return Convert.ToInt32(m.GetValueOrDefault("perfect_word_streak", 0));
    }

    public static int GetCharsTyped(GameState state)
    {
        var m = state.TypingMetrics;
        return Convert.ToInt32(m.GetValueOrDefault("battle_chars_typed", 0));
    }

    public static double GetBattleDuration(GameState state)
    {
        var m = state.TypingMetrics;
        long start = Convert.ToInt64(m.GetValueOrDefault("battle_start_msec", 0L));
        long now = Stopwatch.GetTimestamp();
        return (double)(now - start) / Stopwatch.Frequency;
    }
}
