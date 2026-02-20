using System.Collections.Generic;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Practice goal definitions and thresholds.
/// Ported from sim/practice_goals.gd.
/// </summary>
public static class PracticeGoals
{
    public static readonly Dictionary<string, GoalThresholds> Goals = new()
    {
        ["balanced"] = new(0.55, 0.78, 0.20, 0.30),
        ["accuracy"] = new(0.45, 0.85, 0.25, 0.35),
        ["backspace"] = new(0.50, 0.75, 0.12, 0.30),
        ["speed"] = new(0.70, 0.75, 0.25, 0.25),
    };

    public static string NormalizeGoal(string goal)
    {
        var normalized = goal?.Trim().ToLowerInvariant() ?? "balanced";
        return Goals.ContainsKey(normalized) ? normalized : "balanced";
    }

    public static GoalThresholds Thresholds(string goal) => Goals.GetValueOrDefault(NormalizeGoal(goal), Goals["balanced"]);

    public static string GoalLabel(string goal) => goal switch
    {
        "balanced" => "Balanced",
        "accuracy" => "Accuracy Focus",
        "backspace" => "Clean Keystrokes",
        "speed" => "Speed Focus",
        _ => "Balanced",
    };

    public static string GoalDescription(string goal) => goal switch
    {
        "balanced" => "A well-rounded target for all typing metrics.",
        "accuracy" => "Prioritize accuracy over speed.",
        "backspace" => "Minimize use of backspace key.",
        "speed" => "Prioritize speed and throughput.",
        _ => "",
    };
}

public readonly struct GoalThresholds
{
    public double MinHitRate { get; }
    public double MinAccuracy { get; }
    public double MaxBackspaceRate { get; }
    public double MaxIncompleteRate { get; }

    public GoalThresholds(double hitRate, double accuracy, double backspaceRate, double incompleteRate)
    {
        MinHitRate = hitRate;
        MinAccuracy = accuracy;
        MaxBackspaceRate = backspaceRate;
        MaxIncompleteRate = incompleteRate;
    }
}
