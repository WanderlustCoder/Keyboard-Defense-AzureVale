using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Typing challenges for exploration events.
/// Ported from sim/exploration_challenges.gd.
/// </summary>
public static class ExplorationChallenges
{
    public enum ChallengeType { Accuracy, Speed, Consistency, Timed, WordCount, Mixed }

    public static readonly Dictionary<string, ChallengeDifficulty> Difficulties = new()
    {
        ["easy"] = new(5, 30, 0.7, 30.0, 1.0),
        ["medium"] = new(8, 50, 0.85, 20.0, 1.5),
        ["hard"] = new(12, 70, 0.95, 15.0, 2.0),
        ["legendary"] = new(20, 90, 0.98, 10.0, 3.0),
    };

    public static string GetDifficultyForDay(int day)
    {
        if (day >= 20) return "legendary";
        if (day >= 12) return "hard";
        if (day >= 5) return "medium";
        return "easy";
    }

    public static Dictionary<string, object> CreateChallenge(ChallengeType type, string difficulty)
    {
        var diff = Difficulties.GetValueOrDefault(difficulty, Difficulties["easy"]);
        return new Dictionary<string, object>
        {
            ["type"] = type.ToString(),
            ["difficulty"] = difficulty,
            ["word_count"] = diff.WordCount,
            ["target_wpm"] = diff.TargetWpm,
            ["target_accuracy"] = diff.TargetAccuracy,
            ["time_limit"] = diff.TimeLimit,
            ["reward_multiplier"] = diff.RewardMultiplier,
        };
    }

    public static Dictionary<string, object> EvaluateChallenge(Dictionary<string, object> challenge, double wpm, double accuracy, int wordsTyped, double timeElapsed)
    {
        string difficulty = challenge.GetValueOrDefault("difficulty", "easy").ToString() ?? "easy";
        var diff = Difficulties.GetValueOrDefault(difficulty, Difficulties["easy"]);

        bool passed = wordsTyped >= diff.WordCount && accuracy >= diff.TargetAccuracy;
        double score = CalculateScore(wpm, accuracy, diff);
        double rewardMult = passed ? diff.RewardMultiplier * (score / 100.0) : 0.25;

        return new()
        {
            ["passed"] = passed,
            ["score"] = (int)score,
            ["reward_multiplier"] = rewardMult,
        };
    }

    private static double CalculateScore(double wpm, double accuracy, ChallengeDifficulty diff)
    {
        double wpmScore = Math.Min(1.0, wpm / Math.Max(1, diff.TargetWpm)) * 50;
        double accScore = Math.Min(1.0, accuracy / Math.Max(0.01, diff.TargetAccuracy)) * 50;
        return Math.Clamp(wpmScore + accScore, 0, 100);
    }
}

public record ChallengeDifficulty(int WordCount, int TargetWpm, double TargetAccuracy, double TimeLimit, double RewardMultiplier);
