using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Stress;

public class TypingStressTests
{
    [Fact]
    public void TypingMetrics_HandlesTenThousandKeystrokes_WithoutNaNOrOverflow()
    {
        var state = CreateInitializedState();
        const int keystrokes = 10000;
        const int wordLength = 5;
        const int errorEvery = 10;

        for (int i = 0; i < keystrokes; i++)
        {
            TypingMetrics.RecordCharTyped(state, (char)('a' + (i % 26)));

            if ((i + 1) % errorEvery == 0)
                TypingMetrics.RecordError(state);

            if ((i + 1) % wordLength == 0)
                TypingMetrics.RecordWordCompleted(state);
        }

        SetBattleStartSecondsAgo(state, 180.0);

        double wpm = TypingMetrics.GetWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);

        Assert.Equal(keystrokes, TypingMetrics.GetCharsTyped(state));
        Assert.Equal(keystrokes / wordLength, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
        Assert.Equal(keystrokes / errorEvery, Convert.ToInt32(state.TypingMetrics["battle_errors"]));

        var rollingWindow = Assert.IsType<List<object>>(state.TypingMetrics["rolling_window_chars"]);
        Assert.Equal(keystrokes, rollingWindow.Count);

        Assert.False(double.IsNaN(wpm));
        Assert.False(double.IsInfinity(wpm));
        Assert.False(double.IsNaN(accuracy));
        Assert.False(double.IsInfinity(accuracy));
        Assert.InRange(accuracy, 0.0, 1.0);
    }

    [Fact]
    public void TypingMetrics_WpmCalculation_IsAccurateForVeryFastInput()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["battle_chars_typed"] = 1200; // 240 WPM over one minute.
        SetBattleStartSecondsAgo(state, 60.0);

        double wpm = TypingMetrics.GetWpm(state);

        Assert.False(double.IsNaN(wpm));
        Assert.False(double.IsInfinity(wpm));
        Assert.True(wpm > 200.0, $"Expected fast typing above 200 WPM but got {wpm:F2}.");
        Assert.InRange(wpm, 230.0, 250.0);
    }

    [Fact]
    public void TypingMetrics_WpmCalculation_IsAccurateForVerySlowInput()
    {
        var state = CreateInitializedState();
        state.TypingMetrics["battle_chars_typed"] = 5; // 1 WPM over one minute.
        SetBattleStartSecondsAgo(state, 60.0);

        double wpm = TypingMetrics.GetWpm(state);

        Assert.False(double.IsNaN(wpm));
        Assert.False(double.IsInfinity(wpm));
        Assert.InRange(wpm, 0.95, 1.05);
    }

    [Fact]
    public void Typing_LongWordsOverHundredCharacters_AreHandledCorrectly()
    {
        var state = CreateInitializedState();
        string longWord = BuildLongWord(128);

        foreach (char ch in longWord)
            TypingMetrics.RecordCharTyped(state, ch);

        TypingMetrics.RecordWordCompleted(state);

        Assert.Equal(longWord.Length, TypingMetrics.GetCharsTyped(state));
        Assert.Equal(1, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
        Assert.Equal(1, TypingMetrics.GetPerfectStreak(state));
        Assert.Equal(longWord.Length, TypingFeedback.PrefixLen(longWord, longWord));

        string altered = longWord[..^1] + (longWord[^1] == 'a' ? 'b' : 'a');
        Assert.Equal(1, TypingFeedback.EditDistance(longWord, altered));

        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = longWord, ["id"] = 42, ["alive"] = true }
        };

        var candidates = TypingFeedback.EnemyCandidates(longWord, enemies);
        Assert.Equal(42, candidates.ExactId);
        Assert.Equal(longWord.Length, candidates.BestPrefixLen);
        Assert.Contains(42, candidates.CandidateIds);
    }

    [Fact]
    public void CommandParser_CanParseThousandsOfCommandsInRapidSuccession()
    {
        string[] commands =
        {
            "help",
            "status",
            "wait",
            "map",
            "cursor up 2",
            "history show",
            "target nearest",
            "defend quick brown fox",
            "settings scale 120",
            "trade 3 wood for stone",
            "build tower 1 2",
            "gather wood 3"
        };

        const int iterations = 5000;
        int okCount = 0;

        for (int i = 0; i < iterations; i++)
        {
            var parsed = CommandParser.Parse(commands[i % commands.Length]);
            Assert.True(parsed.ContainsKey("ok"));
            Assert.True(Convert.ToBoolean(parsed["ok"]));
            var intent = Assert.IsType<Dictionary<string, object>>(parsed["intent"]);
            Assert.True(intent.ContainsKey("kind"));
            okCount++;
        }

        Assert.Equal(iterations, okCount);
    }

    [Fact]
    public void TypingMetrics_AccuracyHandlesPerfectAndTerribleInputs()
    {
        var perfect = CreateInitializedState();
        for (int i = 0; i < 500; i++)
            TypingMetrics.RecordCharTyped(perfect, 'a');
        Assert.Equal(1.0, TypingMetrics.GetAccuracy(perfect), 6);

        var terrible = CreateInitializedState();
        for (int i = 0; i < 500; i++)
        {
            TypingMetrics.RecordCharTyped(terrible, 'a');
            TypingMetrics.RecordError(terrible);
        }

        Assert.Equal(0.0, TypingMetrics.GetAccuracy(terrible), 6);
    }

    [Fact]
    public void TypingMetrics_KeystrokeHistory_DoesNotLeakAcrossBattleReinitialization()
    {
        List<WeakReference> detachedWindows = CreateDetachedRollingWindowReferences(
            battleCount: 20,
            keystrokesPerBattle: 1000);

        ForceFullGc();

        int alive = detachedWindows.Count(reference => reference.IsAlive);
        Assert.Equal(0, alive);
    }

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

    private static string BuildLongWord(int length)
    {
        var builder = new StringBuilder(length);
        for (int i = 0; i < length; i++)
            builder.Append((char)('a' + (i % 26)));
        return builder.ToString();
    }

    private static List<WeakReference> CreateDetachedRollingWindowReferences(int battleCount, int keystrokesPerBattle)
    {
        var state = new GameState();
        var detachedWindows = new List<WeakReference>(battleCount);

        for (int battle = 0; battle < battleCount; battle++)
        {
            TypingMetrics.InitBattleMetrics(state);
            for (int i = 0; i < keystrokesPerBattle; i++)
                TypingMetrics.RecordCharTyped(state, (char)('a' + (i % 26)));

            var rollingWindow = (List<object>)state.TypingMetrics["rolling_window_chars"];
            detachedWindows.Add(new WeakReference(rollingWindow));
        }

        TypingMetrics.InitBattleMetrics(state);
        return detachedWindows;
    }

    private static void ForceFullGc()
    {
        GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true);
        GC.WaitForPendingFinalizers();
        GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true);
    }
}
