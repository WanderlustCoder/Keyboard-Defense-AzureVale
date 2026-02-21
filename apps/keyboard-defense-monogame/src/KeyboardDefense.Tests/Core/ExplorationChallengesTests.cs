using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Progression;

namespace KeyboardDefense.Tests.Core;

public class ExplorationChallengesCoreTests
{
    [Fact]
    public void GetDifficultyForDay_Day1_ReturnsEasy()
    {
        Assert.Equal("easy", ExplorationChallenges.GetDifficultyForDay(1));
    }

    [Fact]
    public void GetDifficultyForDay_Day5_ReturnsMedium()
    {
        Assert.Equal("medium", ExplorationChallenges.GetDifficultyForDay(5));
    }

    [Fact]
    public void GetDifficultyForDay_Day6_ReturnsMedium()
    {
        Assert.Equal("medium", ExplorationChallenges.GetDifficultyForDay(6));
    }

    [Fact]
    public void GetDifficultyForDay_Day12_ReturnsHard()
    {
        Assert.Equal("hard", ExplorationChallenges.GetDifficultyForDay(12));
    }

    [Fact]
    public void GetDifficultyForDay_Day13_ReturnsHard()
    {
        Assert.Equal("hard", ExplorationChallenges.GetDifficultyForDay(13));
    }

    [Fact]
    public void GetDifficultyForDay_Day20_ReturnsLegendary()
    {
        Assert.Equal("legendary", ExplorationChallenges.GetDifficultyForDay(20));
    }

    [Fact]
    public void GetDifficultyForDay_Day21_ReturnsLegendary()
    {
        Assert.Equal("legendary", ExplorationChallenges.GetDifficultyForDay(21));
    }

    [Fact]
    public void GetDifficultyForDay_Day100_ReturnsLegendary()
    {
        Assert.Equal("legendary", ExplorationChallenges.GetDifficultyForDay(100));
    }

    [Fact]
    public void CreateChallenge_IncludesExpectedKeys()
    {
        var challenge = ExplorationChallenges.CreateChallenge(ExplorationChallenges.ChallengeType.Speed, "medium");

        Assert.Equal(7, challenge.Count);
        Assert.True(challenge.ContainsKey("type"));
        Assert.True(challenge.ContainsKey("difficulty"));
        Assert.True(challenge.ContainsKey("word_count"));
        Assert.True(challenge.ContainsKey("target_wpm"));
        Assert.True(challenge.ContainsKey("target_accuracy"));
        Assert.True(challenge.ContainsKey("time_limit"));
        Assert.True(challenge.ContainsKey("reward_multiplier"));
        Assert.Equal("Speed", challenge["type"]);
        Assert.Equal("medium", challenge["difficulty"]);
    }

    [Fact]
    public void CreateChallenge_Easy_UsesExpectedWordCount()
    {
        var challenge = CreateChallengeFor("easy");

        Assert.Equal(5, AsInt(challenge, "word_count"));
    }

    [Fact]
    public void CreateChallenge_Medium_UsesExpectedWordCount()
    {
        var challenge = CreateChallengeFor("medium");

        Assert.Equal(8, AsInt(challenge, "word_count"));
    }

    [Fact]
    public void CreateChallenge_Hard_UsesExpectedWordCount()
    {
        var challenge = CreateChallengeFor("hard");

        Assert.Equal(12, AsInt(challenge, "word_count"));
    }

    [Fact]
    public void CreateChallenge_Legendary_UsesExpectedWordCount()
    {
        var challenge = CreateChallengeFor("legendary");

        Assert.Equal(20, AsInt(challenge, "word_count"));
    }

    [Fact]
    public void CreateChallenge_TimeLimitMatchesDifficultyTable()
    {
        Assert.Equal(30d, AsDouble(CreateChallengeFor("easy"), "time_limit"), 6);
        Assert.Equal(20d, AsDouble(CreateChallengeFor("medium"), "time_limit"), 6);
        Assert.Equal(15d, AsDouble(CreateChallengeFor("hard"), "time_limit"), 6);
        Assert.Equal(10d, AsDouble(CreateChallengeFor("legendary"), "time_limit"), 6);
    }

    [Fact]
    public void CreateChallenge_UnknownDifficulty_UsesEasyMetrics()
    {
        var challenge = CreateChallengeFor("unknown");

        Assert.Equal("unknown", challenge["difficulty"]);
        Assert.Equal(5, AsInt(challenge, "word_count"));
        Assert.Equal(30, AsInt(challenge, "target_wpm"));
        Assert.Equal(0.7d, AsDouble(challenge, "target_accuracy"), 6);
        Assert.Equal(30d, AsDouble(challenge, "time_limit"), 6);
        Assert.Equal(1d, AsDouble(challenge, "reward_multiplier"), 6);
    }

    [Fact]
    public void EvaluateChallenge_PassesWhenTargetsAreMet()
    {
        var challenge = CreateChallengeFor("medium");

        var result = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 50, accuracy: 0.85, wordsTyped: 8, timeElapsed: 2);

        Assert.True((bool)result["passed"]);
        Assert.Equal(100, AsInt(result, "score"));
        Assert.Equal(1.5d, AsDouble(result, "reward_multiplier"), 6);
    }

    [Fact]
    public void EvaluateChallenge_FailsWhenWordCountBelowTarget()
    {
        var challenge = CreateChallengeFor("medium");

        var result = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 200, accuracy: 1.0, wordsTyped: 7, timeElapsed: 2);

        Assert.False((bool)result["passed"]);
    }

    [Fact]
    public void EvaluateChallenge_FailsWhenAccuracyBelowTarget()
    {
        var challenge = CreateChallengeFor("medium");

        var result = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 200, accuracy: 0.84, wordsTyped: 8, timeElapsed: 2);

        Assert.False((bool)result["passed"]);
    }

    [Fact]
    public void EvaluateChallenge_TimeElapsedDoesNotAffectResult()
    {
        var challenge = CreateChallengeFor("medium");

        var fast = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 50, accuracy: 0.85, wordsTyped: 8, timeElapsed: 0.5);
        var slow = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 50, accuracy: 0.85, wordsTyped: 8, timeElapsed: 999);

        Assert.Equal(fast["passed"], slow["passed"]);
        Assert.Equal(fast["score"], slow["score"]);
        Assert.Equal(AsDouble(fast, "reward_multiplier"), AsDouble(slow, "reward_multiplier"), 6);
    }

    [Fact]
    public void EvaluateChallenge_ScoreUsesWpmContribution()
    {
        var challenge = CreateChallengeFor("medium");

        var result = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 25, accuracy: 0.85, wordsTyped: 8, timeElapsed: 2);

        Assert.Equal(75, AsInt(result, "score"));
        Assert.Equal(1.125d, AsDouble(result, "reward_multiplier"), 6);
    }

    [Fact]
    public void EvaluateChallenge_ScoreUsesAccuracyContribution()
    {
        var challenge = CreateChallengeFor("medium");

        var result = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 50, accuracy: 0.425, wordsTyped: 8, timeElapsed: 2);

        Assert.False((bool)result["passed"]);
        Assert.Equal(75, AsInt(result, "score"));
        Assert.Equal(0.25d, AsDouble(result, "reward_multiplier"), 6);
    }

    [Fact]
    public void EvaluateChallenge_FailureUsesMinimumRewardMultiplier()
    {
        var challenge = CreateChallengeFor("legendary");

        var result = ExplorationChallenges.EvaluateChallenge(challenge, wpm: 500, accuracy: 0.2, wordsTyped: 1, timeElapsed: 2);

        Assert.False((bool)result["passed"]);
        Assert.Equal(0.25d, AsDouble(result, "reward_multiplier"), 6);
    }

    private static Dictionary<string, object> CreateChallengeFor(string difficulty)
    {
        return ExplorationChallenges.CreateChallenge(ExplorationChallenges.ChallengeType.Speed, difficulty);
    }

    private static int AsInt(Dictionary<string, object> values, string key)
    {
        return Convert.ToInt32(values[key]);
    }

    private static double AsDouble(Dictionary<string, object> values, string key)
    {
        return Convert.ToDouble(values[key]);
    }
}
