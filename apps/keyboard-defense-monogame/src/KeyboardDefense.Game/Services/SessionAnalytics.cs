using System;
using System.Collections.Generic;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Tracks per-session gameplay metrics for the run summary screen.
/// </summary>
public class SessionAnalytics
{
    private static SessionAnalytics? _instance;
    /// <summary>
    /// Gets the shared analytics instance used for the current run.
    /// </summary>
    public static SessionAnalytics Instance => _instance ??= new();

    /// <summary>
    /// Gets the local timestamp when the current session started.
    /// </summary>
    public DateTime SessionStartTime { get; private set; }
    /// <summary>
    /// Gets the total elapsed play time captured for this session in seconds.
    /// </summary>
    public double TotalPlayTimeSeconds { get; private set; }
    /// <summary>
    /// Gets the number of completed in-game days recorded this session.
    /// </summary>
    public int DaysCompleted { get; private set; }
    /// <summary>
    /// Gets the number of enemies defeated this session.
    /// </summary>
    public int EnemiesDefeated { get; private set; }
    /// <summary>
    /// Gets the number of typed words counted this session.
    /// </summary>
    public int WordsTyped { get; private set; }
    /// <summary>
    /// Gets the number of correctly typed characters counted this session.
    /// </summary>
    public int CharsTyped { get; private set; }
    /// <summary>
    /// Gets the number of typing errors recorded this session.
    /// </summary>
    public int TotalErrors { get; private set; }
    /// <summary>
    /// Gets the highest combo value reached during this session.
    /// </summary>
    public int PeakCombo { get; private set; }
    /// <summary>
    /// Gets the total amount of gold earned this session.
    /// </summary>
    public int GoldEarned { get; private set; }
    /// <summary>
    /// Gets the number of buildings placed this session.
    /// </summary>
    public int BuildingsPlaced { get; private set; }
    /// <summary>
    /// Gets the number of explored tiles recorded this session.
    /// </summary>
    public int TilesExplored { get; private set; }

    private bool _active;

    /// <summary>
    /// Starts a new analytics session and resets all tracked counters.
    /// </summary>
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

    /// <summary>
    /// Records a normalized analytics event and updates matching counters.
    /// </summary>
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

    /// <summary>
    /// Parses raw gameplay event messages and maps them to analytics counters.
    /// </summary>
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

    /// <summary>
    /// Builds a report snapshot with derived accuracy, speed, and performance grade.
    /// </summary>
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
    /// <summary>
    /// Gets the local timestamp when the reported session started.
    /// </summary>
    public DateTime SessionStartTime { get; init; }
    /// <summary>
    /// Gets the total elapsed play time represented by the report, in seconds.
    /// </summary>
    public double TotalPlayTimeSeconds { get; init; }
    /// <summary>
    /// Gets the number of completed in-game days included in the report.
    /// </summary>
    public int DaysCompleted { get; init; }
    /// <summary>
    /// Gets the number of defeated enemies included in the report.
    /// </summary>
    public int EnemiesDefeated { get; init; }
    /// <summary>
    /// Gets the total typed word count included in the report.
    /// </summary>
    public int WordsTyped { get; init; }
    /// <summary>
    /// Gets the total correct character count included in the report.
    /// </summary>
    public int CharsTyped { get; init; }
    /// <summary>
    /// Gets the total typing error count included in the report.
    /// </summary>
    public int TotalErrors { get; init; }
    /// <summary>
    /// Gets the highest combo reached during the reported session.
    /// </summary>
    public int PeakCombo { get; init; }
    /// <summary>
    /// Gets the total gold earned in the reported session.
    /// </summary>
    public int GoldEarned { get; init; }
    /// <summary>
    /// Gets the number of buildings placed in the reported session.
    /// </summary>
    public int BuildingsPlaced { get; init; }
    /// <summary>
    /// Gets the number of explored tiles in the reported session.
    /// </summary>
    public int TilesExplored { get; init; }
    /// <summary>
    /// Gets the typing accuracy ratio computed for the report.
    /// </summary>
    public double AccuracyRate { get; init; }
    /// <summary>
    /// Gets the words-per-minute speed computed for the report.
    /// </summary>
    public double WordsPerMinute { get; init; }
    /// <summary>
    /// Gets the letter-grade performance rank assigned to the report.
    /// </summary>
    public string PerformanceGrade { get; init; } = "D";
}
