using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Typing trend analysis and goal checking.
/// Ported from sim/typing_trends.gd.
/// </summary>
public static class TypingTrends
{
    public static Dictionary<string, object> Summarize(List<Dictionary<string, object>> history, string goalId = "balanced")
    {
        string normalized = PracticeGoals.NormalizeGoal(goalId);
        var thresholds = PracticeGoals.Thresholds(normalized);
        int count = history.Count;

        var latest = count > 0 ? history[count - 1] : new();
        var previous = count > 1 ? history[count - 2] : new();

        double latestAcc = GetValue(latest, "avg_accuracy");
        double latestHit = GetValue(latest, "hit_rate");
        double latestBs = GetValue(latest, "backspace_rate");
        double latestInc = GetValue(latest, "incomplete_rate");
        double prevAcc = GetValue(previous, "avg_accuracy");
        double prevHit = GetValue(previous, "hit_rate");
        double prevBs = GetValue(previous, "backspace_rate");

        bool goalMet = ReportMeetsGoal(latest, thresholds);
        var suggestions = BuildSuggestions(count, latestHit, latestAcc, latestBs, latestInc, thresholds);

        return new Dictionary<string, object>
        {
            ["count"] = count,
            ["goal_id"] = normalized,
            ["goal_label"] = PracticeGoals.GoalLabel(normalized),
            ["goal_description"] = PracticeGoals.GoalDescription(normalized),
            ["goal_met"] = goalMet,
            ["suggestions"] = suggestions,
            ["latest_accuracy"] = latestAcc,
            ["latest_hit_rate"] = latestHit,
            ["latest_backspace_rate"] = latestBs,
            ["latest_incomplete_rate"] = latestInc,
            ["delta_accuracy"] = latestAcc - prevAcc,
            ["delta_hit_rate"] = latestHit - prevHit,
            ["delta_backspace_rate"] = latestBs - prevBs,
            ["avg_accuracy"] = Average(history, "avg_accuracy"),
            ["avg_hit_rate"] = Average(history, "hit_rate"),
            ["avg_backspace_rate"] = Average(history, "backspace_rate"),
        };
    }

    public static bool ReportMeetsGoal(Dictionary<string, object> report, GoalThresholds thresholds)
    {
        if (report.Count == 0) return false;
        if (GetValue(report, "hit_rate") < thresholds.MinHitRate) return false;
        if (GetValue(report, "avg_accuracy") < thresholds.MinAccuracy) return false;
        if (GetValue(report, "backspace_rate") > thresholds.MaxBackspaceRate) return false;
        if (GetValue(report, "incomplete_rate") > thresholds.MaxIncompleteRate) return false;
        return true;
    }

    private static List<string> BuildSuggestions(
        int count, double hitRate, double accuracy, double backspaceRate,
        double incompleteRate, GoalThresholds thresholds)
    {
        var suggestions = new List<string>();
        if (count < 2)
            suggestions.Add("Play 2+ nights to unlock trend insights.");
        if (hitRate < thresholds.MinHitRate)
            suggestions.Add("Hit rate below target: build or upgrade towers and reduce exploration.");
        if (accuracy < thresholds.MinAccuracy)
            suggestions.Add("Accuracy below target: slow down and focus on clean words.");
        if (backspaceRate > thresholds.MaxBackspaceRate)
            suggestions.Add("Backspace rate high: pause before typing and aim for clean first hits.");
        if (incompleteRate > thresholds.MaxIncompleteRate)
            suggestions.Add("Too many incomplete enters: finish words before pressing Enter.");
        if (suggestions.Count == 0)
            suggestions.Add("Goal met: keep upgrading towers and expanding safely.");
        return suggestions;
    }

    private static double GetValue(Dictionary<string, object> entry, string key)
    {
        if (entry.TryGetValue(key, out var val))
            return Convert.ToDouble(val);
        return 0.0;
    }

    private static double Average(List<Dictionary<string, object>> history, string key)
    {
        if (history.Count == 0) return 0.0;
        double sum = 0;
        int count = 0;
        foreach (var entry in history)
        {
            sum += GetValue(entry, key);
            count++;
        }
        return count > 0 ? sum / count : 0.0;
    }
}
