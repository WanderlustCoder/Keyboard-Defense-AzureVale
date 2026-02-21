using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingTrendsCoreTests
{
    [Fact]
    public void Summarize_EmptyHistory_ReturnsDefaultSummary()
    {
        var summary = TypingTrends.Summarize(new List<Dictionary<string, object>>());

        Assert.Equal(0, Convert.ToInt32(summary["count"]));
        Assert.Equal("balanced", summary["goal_id"]);
        Assert.Equal("Balanced", summary["goal_label"]);
        Assert.Equal("A well-rounded target for all typing metrics.", summary["goal_description"]);
        Assert.False(Convert.ToBoolean(summary["goal_met"]));

        Assert.Equal(0.0, GetDouble(summary, "latest_accuracy"), 6);
        Assert.Equal(0.0, GetDouble(summary, "latest_hit_rate"), 6);
        Assert.Equal(0.0, GetDouble(summary, "latest_backspace_rate"), 6);
        Assert.Equal(0.0, GetDouble(summary, "latest_incomplete_rate"), 6);
        Assert.Equal(0.0, GetDouble(summary, "delta_accuracy"), 6);
        Assert.Equal(0.0, GetDouble(summary, "delta_hit_rate"), 6);
        Assert.Equal(0.0, GetDouble(summary, "delta_backspace_rate"), 6);
        Assert.Equal(0.0, GetDouble(summary, "avg_accuracy"), 6);
        Assert.Equal(0.0, GetDouble(summary, "avg_hit_rate"), 6);
        Assert.Equal(0.0, GetDouble(summary, "avg_backspace_rate"), 6);

        var suggestions = GetSuggestions(summary);
        Assert.Contains("Play 2+ nights to unlock trend insights.", suggestions);
        Assert.Contains("Hit rate below target: build or upgrade towers and reduce exploration.", suggestions);
        Assert.Contains("Accuracy below target: slow down and focus on clean words.", suggestions);
    }

    [Fact]
    public void Summarize_SingleEntry_UsesEntryForLatestDeltaAndAverage()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.88, 0.66, 0.11, 0.14),
        };

        var summary = TypingTrends.Summarize(history);

        Assert.Equal(1, Convert.ToInt32(summary["count"]));
        Assert.Equal(0.88, GetDouble(summary, "latest_accuracy"), 6);
        Assert.Equal(0.66, GetDouble(summary, "latest_hit_rate"), 6);
        Assert.Equal(0.11, GetDouble(summary, "latest_backspace_rate"), 6);
        Assert.Equal(0.14, GetDouble(summary, "latest_incomplete_rate"), 6);
        Assert.Equal(0.88, GetDouble(summary, "delta_accuracy"), 6);
        Assert.Equal(0.66, GetDouble(summary, "delta_hit_rate"), 6);
        Assert.Equal(0.11, GetDouble(summary, "delta_backspace_rate"), 6);
        Assert.Equal(0.88, GetDouble(summary, "avg_accuracy"), 6);
        Assert.Equal(0.66, GetDouble(summary, "avg_hit_rate"), 6);
        Assert.Equal(0.11, GetDouble(summary, "avg_backspace_rate"), 6);
    }

    [Fact]
    public void Summarize_TwoEntries_ComputesDeltasFromPreviousEntry()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.80, 0.50, 0.20, 0.20),
            Entry(0.90, 0.75, 0.10, 0.15),
        };

        var summary = TypingTrends.Summarize(history);

        Assert.Equal(0.10, GetDouble(summary, "delta_accuracy"), 6);
        Assert.Equal(0.25, GetDouble(summary, "delta_hit_rate"), 6);
        Assert.Equal(-0.10, GetDouble(summary, "delta_backspace_rate"), 6);
    }

    [Fact]
    public void Summarize_MultipleEntries_ComputesAveragesAcrossHistory()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.80, 0.50, 0.20, 0.25),
            Entry(0.85, 0.60, 0.15, 0.20),
            Entry(0.90, 0.70, 0.10, 0.15),
        };

        var summary = TypingTrends.Summarize(history);

        Assert.Equal(0.85, GetDouble(summary, "avg_accuracy"), 6);
        Assert.Equal(0.60, GetDouble(summary, "avg_hit_rate"), 6);
        Assert.Equal(0.15, GetDouble(summary, "avg_backspace_rate"), 6);
    }

    [Fact]
    public void Summarize_GoalMet_IsTrueWhenLatestMeetsThresholds()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.82, 0.58, 0.18, 0.20),
            Entry(0.88, 0.65, 0.10, 0.10),
        };

        var summary = TypingTrends.Summarize(history, "balanced");

        Assert.True(Convert.ToBoolean(summary["goal_met"]));
    }

    [Fact]
    public void Summarize_GoalMet_IsFalseWhenAnyThresholdFails()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.90, 0.70, 0.10, 0.10),
            Entry(0.88, 0.40, 0.10, 0.10),
        };

        var summary = TypingTrends.Summarize(history, "balanced");

        Assert.False(Convert.ToBoolean(summary["goal_met"]));
    }

    [Fact]
    public void ReportMeetsGoal_EmptyReport_ReturnsFalse()
    {
        var thresholds = PracticeGoals.Thresholds("balanced");

        var met = TypingTrends.ReportMeetsGoal(new Dictionary<string, object>(), thresholds);

        Assert.False(met);
    }

    [Fact]
    public void ReportMeetsGoal_AllThresholdsSatisfied_ReturnsTrue()
    {
        var report = Entry(0.88, 0.70, 0.10, 0.20);
        var thresholds = PracticeGoals.Thresholds("balanced");

        var met = TypingTrends.ReportMeetsGoal(report, thresholds);

        Assert.True(met);
    }

    [Fact]
    public void ReportMeetsGoal_HitRateBelowThreshold_ReturnsFalse()
    {
        var report = Entry(0.88, 0.54, 0.10, 0.20);
        var thresholds = PracticeGoals.Thresholds("balanced");

        var met = TypingTrends.ReportMeetsGoal(report, thresholds);

        Assert.False(met);
    }

    [Fact]
    public void ReportMeetsGoal_AccuracyBelowThreshold_ReturnsFalse()
    {
        var report = Entry(0.77, 0.70, 0.10, 0.20);
        var thresholds = PracticeGoals.Thresholds("balanced");

        var met = TypingTrends.ReportMeetsGoal(report, thresholds);

        Assert.False(met);
    }

    [Fact]
    public void ReportMeetsGoal_BackspaceAboveThreshold_ReturnsFalse()
    {
        var report = Entry(0.88, 0.70, 0.21, 0.20);
        var thresholds = PracticeGoals.Thresholds("balanced");

        var met = TypingTrends.ReportMeetsGoal(report, thresholds);

        Assert.False(met);
    }

    [Fact]
    public void ReportMeetsGoal_IncompleteAboveThreshold_ReturnsFalse()
    {
        var report = Entry(0.88, 0.70, 0.10, 0.31);
        var thresholds = PracticeGoals.Thresholds("balanced");

        var met = TypingTrends.ReportMeetsGoal(report, thresholds);

        Assert.False(met);
    }

    [Fact]
    public void Summarize_SuggestionsIncludeLowHitRateGuidance()
    {
        var history = HistoryForSuggestions(Entry(0.90, 0.40, 0.10, 0.10));

        var summary = TypingTrends.Summarize(history, "balanced");
        var suggestions = GetSuggestions(summary);

        Assert.Contains("Hit rate below target: build or upgrade towers and reduce exploration.", suggestions);
    }

    [Fact]
    public void Summarize_SuggestionsIncludeLowAccuracyGuidance()
    {
        var history = HistoryForSuggestions(Entry(0.70, 0.70, 0.10, 0.10));

        var summary = TypingTrends.Summarize(history, "balanced");
        var suggestions = GetSuggestions(summary);

        Assert.Contains("Accuracy below target: slow down and focus on clean words.", suggestions);
    }

    [Fact]
    public void Summarize_SuggestionsIncludeHighBackspaceGuidance()
    {
        var history = HistoryForSuggestions(Entry(0.90, 0.70, 0.25, 0.10));

        var summary = TypingTrends.Summarize(history, "balanced");
        var suggestions = GetSuggestions(summary);

        Assert.Contains("Backspace rate high: pause before typing and aim for clean first hits.", suggestions);
    }

    [Fact]
    public void Summarize_SuggestionsIncludeHighIncompleteGuidance()
    {
        var history = HistoryForSuggestions(Entry(0.90, 0.70, 0.10, 0.35));

        var summary = TypingTrends.Summarize(history, "balanced");
        var suggestions = GetSuggestions(summary);

        Assert.Contains("Too many incomplete enters: finish words before pressing Enter.", suggestions);
    }

    [Fact]
    public void Summarize_SuggestionsIncludePlayTwoNights_WhenHistoryCountLessThanTwo()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.90, 0.70, 0.10, 0.10),
        };

        var summary = TypingTrends.Summarize(history, "balanced");
        var suggestions = GetSuggestions(summary);

        Assert.Contains("Play 2+ nights to unlock trend insights.", suggestions);
    }

    [Fact]
    public void Summarize_SuggestionsIncludeGoalMet_WhenAllThresholdsPassAndEnoughHistory()
    {
        var history = new List<Dictionary<string, object>>
        {
            Entry(0.85, 0.58, 0.18, 0.20),
            Entry(0.90, 0.75, 0.10, 0.10),
        };

        var summary = TypingTrends.Summarize(history, "balanced");
        var suggestions = GetSuggestions(summary);

        Assert.Single(suggestions);
        Assert.Equal("Goal met: keep upgrading towers and expanding safely.", suggestions[0]);
    }

    [Fact]
    public void Summarize_KnownGoalIds_ReturnExpectedGoalMetadata()
    {
        var cases = new (string Id, string Label, string Description)[]
        {
            ("balanced", "Balanced", "A well-rounded target for all typing metrics."),
            ("accuracy", "Accuracy Focus", "Prioritize accuracy over speed."),
            ("speed", "Speed Focus", "Prioritize speed and throughput."),
            ("backspace", "Clean Keystrokes", "Minimize use of backspace key."),
        };

        var history = HistoryForSuggestions(Entry(0.90, 0.75, 0.10, 0.10));

        foreach (var (id, label, description) in cases)
        {
            var summary = TypingTrends.Summarize(history, id);
            Assert.Equal(id, summary["goal_id"]);
            Assert.Equal(label, summary["goal_label"]);
            Assert.Equal(description, summary["goal_description"]);
        }
    }

    [Fact]
    public void Summarize_UnknownGoalId_FallsBackToBalancedThresholdsAndMetadata()
    {
        var history = HistoryForSuggestions(Entry(0.90, 0.50, 0.10, 0.10));

        var summary = TypingTrends.Summarize(history, "not-a-goal");

        Assert.Equal("balanced", summary["goal_id"]);
        Assert.Equal("Balanced", summary["goal_label"]);
        Assert.Equal("A well-rounded target for all typing metrics.", summary["goal_description"]);
        Assert.False(Convert.ToBoolean(summary["goal_met"]));
    }

    private static Dictionary<string, object> Entry(double accuracy, double hitRate, double backspaceRate, double incompleteRate)
    {
        return new Dictionary<string, object>
        {
            ["avg_accuracy"] = accuracy,
            ["hit_rate"] = hitRate,
            ["backspace_rate"] = backspaceRate,
            ["incomplete_rate"] = incompleteRate,
        };
    }

    private static List<Dictionary<string, object>> HistoryForSuggestions(Dictionary<string, object> latest)
    {
        return new List<Dictionary<string, object>>
        {
            Entry(0.85, 0.60, 0.15, 0.20),
            latest,
        };
    }

    private static double GetDouble(Dictionary<string, object> summary, string key)
    {
        return Convert.ToDouble(summary[key]);
    }

    private static List<string> GetSuggestions(Dictionary<string, object> summary)
    {
        return (List<string>)summary["suggestions"];
    }
}
