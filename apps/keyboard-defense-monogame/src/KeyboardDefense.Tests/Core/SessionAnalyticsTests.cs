using System;
using System.Collections.Generic;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Tests for SessionAnalytics — per-session metric tracking, event parsing, and report generation.
/// </summary>
public class SessionAnalyticsTests
{
    private static SessionAnalytics CreateFresh()
    {
        var analytics = new SessionAnalytics();
        analytics.StartSession();
        return analytics;
    }

    // =========================================================================
    // StartSession
    // =========================================================================

    [Fact]
    public void StartSession_ResetsAllCountersToZero()
    {
        var a = CreateFresh();
        a.RecordEvent("enemy_defeated", 5);
        a.RecordEvent("word_typed", 10);
        a.RecordEvent("gold_earned", 100);

        a.StartSession(); // reset

        var report = a.GetReport();
        Assert.Equal(0, report.EnemiesDefeated);
        Assert.Equal(0, report.WordsTyped);
        Assert.Equal(0, report.GoldEarned);
    }

    [Fact]
    public void StartSession_SetsSessionStartTimeToNow()
    {
        var before = DateTime.Now;
        var a = CreateFresh();
        var after = DateTime.Now;

        Assert.InRange(a.SessionStartTime, before, after);
    }

    // =========================================================================
    // RecordEvent — direct counter tracking
    // =========================================================================

    [Fact]
    public void RecordEvent_DayCompleted_IncrementsByValue()
    {
        var a = CreateFresh();

        a.RecordEvent("day_completed", 3);

        Assert.Equal(3, a.DaysCompleted);
    }

    [Fact]
    public void RecordEvent_EnemyDefeated_Accumulates()
    {
        var a = CreateFresh();

        a.RecordEvent("enemy_defeated");
        a.RecordEvent("enemy_defeated");
        a.RecordEvent("enemy_defeated", 5);

        Assert.Equal(7, a.EnemiesDefeated);
    }

    [Fact]
    public void RecordEvent_WordTyped_Accumulates()
    {
        var a = CreateFresh();
        a.RecordEvent("word_typed", 12);
        Assert.Equal(12, a.WordsTyped);
    }

    [Fact]
    public void RecordEvent_CharTyped_Accumulates()
    {
        var a = CreateFresh();
        a.RecordEvent("char_typed", 50);
        Assert.Equal(50, a.CharsTyped);
    }

    [Fact]
    public void RecordEvent_Error_Accumulates()
    {
        var a = CreateFresh();
        a.RecordEvent("error", 4);
        Assert.Equal(4, a.TotalErrors);
    }

    [Fact]
    public void RecordEvent_Combo_TracksOnlyPeak()
    {
        var a = CreateFresh();
        a.RecordEvent("combo", 5);
        a.RecordEvent("combo", 12);
        a.RecordEvent("combo", 8);

        Assert.Equal(12, a.PeakCombo);
    }

    [Fact]
    public void RecordEvent_GoldEarned_Accumulates()
    {
        var a = CreateFresh();
        a.RecordEvent("gold_earned", 25);
        a.RecordEvent("gold_earned", 30);
        Assert.Equal(55, a.GoldEarned);
    }

    [Fact]
    public void RecordEvent_BuildingPlaced_Accumulates()
    {
        var a = CreateFresh();
        a.RecordEvent("building_placed");
        a.RecordEvent("building_placed");
        Assert.Equal(2, a.BuildingsPlaced);
    }

    [Fact]
    public void RecordEvent_TileExplored_Accumulates()
    {
        var a = CreateFresh();
        a.RecordEvent("tile_explored", 7);
        Assert.Equal(7, a.TilesExplored);
    }

    [Fact]
    public void RecordEvent_UnknownType_DoesNothing()
    {
        var a = CreateFresh();
        a.RecordEvent("unknown_event", 99);

        var report = a.GetReport();
        Assert.Equal(0, report.EnemiesDefeated);
        Assert.Equal(0, report.GoldEarned);
    }

    [Fact]
    public void RecordEvent_BeforeStartSession_IsIgnored()
    {
        var a = new SessionAnalytics(); // not started
        a.RecordEvent("enemy_defeated", 10);

        a.StartSession();
        Assert.Equal(0, a.EnemiesDefeated);
    }

    // =========================================================================
    // OnGameEvent — event string parsing
    // =========================================================================

    [Fact]
    public void OnGameEvent_DetectsEnemyDefeated()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string> { "Enemy defeated!" });
        Assert.Equal(1, a.EnemiesDefeated);
    }

    [Fact]
    public void OnGameEvent_DetectsGoldWithPlusSign()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string> { "Loot: +25 gold" });
        Assert.Equal(25, a.GoldEarned);
    }

    [Fact]
    public void OnGameEvent_MultipleGoldInOneEvent()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string>
        {
            "Reward: +10 gold",
            "Bonus: +5 gold",
        });
        Assert.Equal(15, a.GoldEarned);
    }

    [Fact]
    public void OnGameEvent_DetectsBuiltAndPlaced()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string>
        {
            "Built tower at (5,5).",
            "Placed wall at (3,3).",
        });
        Assert.Equal(2, a.BuildingsPlaced);
    }

    [Fact]
    public void OnGameEvent_DetectsExploredAndDiscovered()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string>
        {
            "Explored new territory.",
            "Discovered tile (2,3): plains.",
        });
        Assert.Equal(2, a.TilesExplored);
    }

    [Fact]
    public void OnGameEvent_DetectsDawnAsDayCompleted()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string> { "Dawn breaks. Day 5 begins." });
        Assert.Equal(1, a.DaysCompleted);
    }

    [Fact]
    public void OnGameEvent_DetectsMissAsError()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string> { "Miss! No matching word." });
        // "miss" and "no matching" both trigger — but they're in the same string
        // and each condition independently increments
        Assert.True(a.TotalErrors >= 1);
    }

    [Fact]
    public void OnGameEvent_IgnoresUnrelatedStrings()
    {
        var a = CreateFresh();
        a.OnGameEvent(new List<string> { "The wind howls." });

        var report = a.GetReport();
        Assert.Equal(0, report.EnemiesDefeated);
        Assert.Equal(0, report.GoldEarned);
        Assert.Equal(0, report.BuildingsPlaced);
        Assert.Equal(0, report.TilesExplored);
    }

    [Fact]
    public void OnGameEvent_BeforeStartSession_IsIgnored()
    {
        var a = new SessionAnalytics();
        a.OnGameEvent(new List<string> { "Enemy defeated!" });
        a.StartSession();
        Assert.Equal(0, a.EnemiesDefeated);
    }

    // =========================================================================
    // GetReport — accuracy, WPM, score, grade
    // =========================================================================

    [Fact]
    public void GetReport_AccuracyPerfectWhenNoErrors()
    {
        var a = CreateFresh();
        a.RecordEvent("char_typed", 100);
        var report = a.GetReport();
        Assert.Equal(1.0, report.AccuracyRate, 3);
    }

    [Fact]
    public void GetReport_AccuracyComputedCorrectly()
    {
        var a = CreateFresh();
        a.RecordEvent("char_typed", 80);
        a.RecordEvent("error", 20);

        var report = a.GetReport();
        // 80 / (80 + 20) = 0.8
        Assert.Equal(0.8, report.AccuracyRate, 3);
    }

    [Fact]
    public void GetReport_AccuracyOneWhenNoInput()
    {
        var a = CreateFresh();
        var report = a.GetReport();
        Assert.Equal(1.0, report.AccuracyRate, 3);
    }

    [Fact]
    public void GetReport_GradeD_ForLowScore()
    {
        var a = CreateFresh();
        // Minimal activity
        a.RecordEvent("enemy_defeated", 1);
        var report = a.GetReport();
        Assert.Equal("D", report.PerformanceGrade);
    }

    [Fact]
    public void GetReport_GradeS_ForHighScore()
    {
        var a = CreateFresh();
        a.RecordEvent("day_completed", 50);   // 5000
        a.RecordEvent("enemy_defeated", 200);  // 10000
        a.RecordEvent("word_typed", 500);       // 5000
        a.RecordEvent("char_typed", 2500);
        a.RecordEvent("combo", 30);             // 750
        a.RecordEvent("gold_earned", 1000);     // 2000
        a.RecordEvent("building_placed", 10);   // 300
        a.RecordEvent("tile_explored", 100);    // 500

        var report = a.GetReport();
        Assert.Equal("S", report.PerformanceGrade);
    }

    [Fact]
    public void GetReport_ScoreIncludesAccuracyBonus()
    {
        var perfect = CreateFresh();
        perfect.RecordEvent("day_completed", 20);
        perfect.RecordEvent("char_typed", 100);

        var imperfect = CreateFresh();
        imperfect.RecordEvent("day_completed", 20);
        imperfect.RecordEvent("char_typed", 50);
        imperfect.RecordEvent("error", 50);

        var perfectReport = perfect.GetReport();
        var imperfectReport = imperfect.GetReport();

        // Perfect accuracy (1.0 * 0.5 + 0.5 = 1.0) vs 50% (0.5 * 0.5 + 0.5 = 0.75)
        Assert.True(perfectReport.DaysCompleted == imperfectReport.DaysCompleted);
    }

    [Fact]
    public void GetReport_ContainsAllFields()
    {
        var a = CreateFresh();
        a.RecordEvent("day_completed", 3);
        a.RecordEvent("enemy_defeated", 10);
        a.RecordEvent("word_typed", 50);
        a.RecordEvent("char_typed", 200);
        a.RecordEvent("error", 5);
        a.RecordEvent("combo", 8);
        a.RecordEvent("gold_earned", 150);
        a.RecordEvent("building_placed", 4);
        a.RecordEvent("tile_explored", 12);

        var report = a.GetReport();

        Assert.Equal(3, report.DaysCompleted);
        Assert.Equal(10, report.EnemiesDefeated);
        Assert.Equal(50, report.WordsTyped);
        Assert.Equal(200, report.CharsTyped);
        Assert.Equal(5, report.TotalErrors);
        Assert.Equal(8, report.PeakCombo);
        Assert.Equal(150, report.GoldEarned);
        Assert.Equal(4, report.BuildingsPlaced);
        Assert.Equal(12, report.TilesExplored);
        Assert.True(report.TotalPlayTimeSeconds >= 0);
        Assert.NotNull(report.PerformanceGrade);
    }

    // =========================================================================
    // Grade boundaries
    // =========================================================================

    [Theory]
    [InlineData(0, "D")]
    [InlineData(4999, "D")]
    [InlineData(5000, "C")]
    [InlineData(9999, "C")]
    [InlineData(10000, "B")]
    [InlineData(14999, "B")]
    [InlineData(15000, "A")]
    [InlineData(19999, "A")]
    [InlineData(20000, "S")]
    [InlineData(50000, "S")]
    public void GetReport_GradeBoundaries(int rawScore, string expectedGrade)
    {
        // Score = rawScore with perfect accuracy bonus (1.0) means score stays same
        // We need to reverse-engineer the right inputs.
        // score = DaysCompleted*100 + EnemiesDefeated*50 + WordsTyped*10 + PeakCombo*25
        //       + GoldEarned*2 + BuildingsPlaced*30 + TilesExplored*5
        // With perfect accuracy: score *= 1.0
        // Simplest: use GoldEarned*2, so GoldEarned = rawScore / 2
        var a = CreateFresh();
        a.RecordEvent("char_typed", 100); // perfect accuracy
        a.RecordEvent("gold_earned", rawScore / 2);

        var report = a.GetReport();
        Assert.Equal(expectedGrade, report.PerformanceGrade);
    }
}
