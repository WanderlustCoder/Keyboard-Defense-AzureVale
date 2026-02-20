using System;
using System.Collections.Generic;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Tracks per-session gameplay metrics for the run summary screen.
/// </summary>
public class SessionAnalytics
{
    private static SessionAnalytics? _instance;
    public static SessionAnalytics Instance => _instance ??= new();

    public DateTime SessionStartTime { get; private set; }
    public double TotalPlayTimeSeconds { get; private set; }
    public int DaysCompleted { get; private set; }
    public int EnemiesDefeated { get; private set; }
    public int WordsTyped { get; private set; }
    public int CharsTyped { get; private set; }
    public int TotalErrors { get; private set; }
    public int PeakCombo { get; private set; }
    public int GoldEarned { get; private set; }
    public int BuildingsPlaced { get; private set; }
    public int TilesExplored { get; private set; }

    private bool _active;

    public void StartSession()
    {
        SessionStartTime = DateTime.Now;
        TotalPlayTimeSeconds = 0;
        DaysCompleted = 0;
        EnemiesDefeated = 0;
        WordsTyped = 0;
        CharsTyped = 0;
        TotalErrors = 0;
        PeakCombo = 0;
        GoldEarned = 0;
        BuildingsPlaced = 0;
        TilesExplored = 0;
        _active = true;
    }

    public void RecordEvent(string eventType, int value = 1)
    {
        if (!_active) return;

        switch (eventType)
        {
            case "day_completed":
                DaysCompleted += value;
                break;
            case "enemy_defeated":
                EnemiesDefeated += value;
                break;
            case "word_typed":
                WordsTyped += value;
                break;
            case "char_typed":
                CharsTyped += value;
                break;
            case "error":
                TotalErrors += value;
                break;
            case "combo":
                if (value > PeakCombo) PeakCombo = value;
                break;
            case "gold_earned":
                GoldEarned += value;
                break;
            case "building_placed":
                BuildingsPlaced += value;
                break;
            case "tile_explored":
                TilesExplored += value;
                break;
        }
    }

    public void OnGameEvent(List<string> events)
    {
        if (!_active) return;

        foreach (string evt in events)
        {
            string lower = evt.ToLowerInvariant();

            if (lower.Contains("enemy defeated") || lower.Contains("defeated!"))
                RecordEvent("enemy_defeated");

            if (lower.Contains("gold"))
            {
                int idx = lower.IndexOf('+');
                if (idx >= 0)
                {
                    int end = idx + 1;
                    while (end < lower.Length && char.IsDigit(lower[end])) end++;
                    if (end > idx + 1 && int.TryParse(lower.AsSpan(idx + 1, end - idx - 1), out int gold))
                        RecordEvent("gold_earned", gold);
                }
            }

            if (lower.Contains("built") || lower.Contains("placed"))
                RecordEvent("building_placed");

            if (lower.Contains("explored") || lower.Contains("discovered"))
                RecordEvent("tile_explored");

            if (lower.Contains("dawn") || lower.Contains("day "))
                RecordEvent("day_completed");

            if (lower.Contains("miss") || lower.Contains("no matching"))
                RecordEvent("error");
        }
    }

    public SessionReport GetReport()
    {
        if (_active)
            TotalPlayTimeSeconds = (DateTime.Now - SessionStartTime).TotalSeconds;

        int totalAttempts = CharsTyped + TotalErrors;
        double accuracy = totalAttempts > 0 ? (double)CharsTyped / totalAttempts : 1.0;

        double minutes = TotalPlayTimeSeconds / 60.0;
        double wpm = minutes > 0.1 ? WordsTyped / minutes : 0;

        int score = DaysCompleted * 100
            + EnemiesDefeated * 50
            + WordsTyped * 10
            + PeakCombo * 25
            + GoldEarned * 2
            + BuildingsPlaced * 30
            + TilesExplored * 5;

        double accuracyBonus = accuracy * 0.5 + 0.5;
        score = (int)(score * accuracyBonus);

        string grade;
        if (score >= 20000) grade = "S";
        else if (score >= 15000) grade = "A";
        else if (score >= 10000) grade = "B";
        else if (score >= 5000) grade = "C";
        else grade = "D";

        return new SessionReport
        {
            SessionStartTime = SessionStartTime,
            TotalPlayTimeSeconds = TotalPlayTimeSeconds,
            DaysCompleted = DaysCompleted,
            EnemiesDefeated = EnemiesDefeated,
            WordsTyped = WordsTyped,
            CharsTyped = CharsTyped,
            TotalErrors = TotalErrors,
            PeakCombo = PeakCombo,
            GoldEarned = GoldEarned,
            BuildingsPlaced = BuildingsPlaced,
            TilesExplored = TilesExplored,
            AccuracyRate = accuracy,
            WordsPerMinute = wpm,
            PerformanceGrade = grade,
        };
    }
}

/// <summary>
/// Summary report of a completed gameplay session.
/// </summary>
public class SessionReport
{
    public DateTime SessionStartTime { get; init; }
    public double TotalPlayTimeSeconds { get; init; }
    public int DaysCompleted { get; init; }
    public int EnemiesDefeated { get; init; }
    public int WordsTyped { get; init; }
    public int CharsTyped { get; init; }
    public int TotalErrors { get; init; }
    public int PeakCombo { get; init; }
    public int GoldEarned { get; init; }
    public int BuildingsPlaced { get; init; }
    public int TilesExplored { get; init; }
    public double AccuracyRate { get; init; }
    public double WordsPerMinute { get; init; }
    public string PerformanceGrade { get; init; } = "D";
}
