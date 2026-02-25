using System.Collections.Generic;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingFeedbackTests
{
    [Fact]
    public void NormalizeInput_TrimsAndLowercasesText()
    {
        Assert.Equal("hello world", TypingFeedback.NormalizeInput("  HeLLo WoRLD  "));
    }

    [Fact]
    public void NormalizeInput_Null_ReturnsEmptyString()
    {
        Assert.Equal(string.Empty, TypingFeedback.NormalizeInput(null!));
    }

    [Fact]
    public void PrefixLen_ReturnsLengthUntilFirstMismatch()
    {
        Assert.Equal(4, TypingFeedback.PrefixLen("typex", "typers"));
        Assert.Equal(0, TypingFeedback.PrefixLen("x", "typers"));
    }

    [Fact]
    public void EditDistance_ComputesInsertionDeletionAndSubstitution()
    {
        Assert.Equal(1, TypingFeedback.EditDistance("cat", "cut"));
        Assert.Equal(1, TypingFeedback.EditDistance("cat", "cats"));
        Assert.Equal(1, TypingFeedback.EditDistance("cats", "cat"));
        Assert.Equal(3, TypingFeedback.EditDistance("kitten", "sitting"));
    }

    [Fact]
    public void EnemyCandidates_CorrectPartialKeystrokes_ReturnsCandidatesBestIdsAndExpectedNextChars()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, "cat"),
            Enemy(2, "cab"),
            Enemy(3, "dog"),
        };

        var result = TypingFeedback.EnemyCandidates("ca", enemies);

        Assert.Equal("ca", result.Typed);
        Assert.Null(result.ExactId);
        Assert.Equal(2, result.BestPrefixLen);
        Assert.Equal(new[] { 1, 2 }, result.BestIds);
        Assert.Equal(new[] { 1, 2 }, result.CandidateIds);
        Assert.Equal(new[] { 't', 'b' }, result.ExpectedNextChars);
    }

    [Fact]
    public void EnemyCandidates_IncorrectKeystroke_ReturnsNoCandidateFeedback()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, "cat"),
            Enemy(2, "cab"),
        };

        var result = TypingFeedback.EnemyCandidates("x", enemies);

        Assert.Equal("x", result.Typed);
        Assert.Null(result.ExactId);
        Assert.Equal(0, result.BestPrefixLen);
        Assert.Empty(result.BestIds);
        Assert.Empty(result.CandidateIds);
        Assert.Empty(result.ExpectedNextChars);
    }

    [Fact]
    public void EnemyCandidates_ComboFeedback_TiedBestPrefixesIncludeAllBestIds()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, "plant"),
            Enemy(2, "plane"),
            Enemy(3, "plow"),
        };

        var result = TypingFeedback.EnemyCandidates("pla", enemies);

        Assert.Null(result.ExactId);
        Assert.Equal(3, result.BestPrefixLen);
        Assert.Equal(new[] { 1, 2 }, result.BestIds);
        Assert.Equal(new[] { 1, 2, 3 }, result.CandidateIds);
        Assert.Equal(new[] { 'n', 'o' }, result.ExpectedNextChars);
    }

    [Fact]
    public void EnemyCandidates_StreakFeedback_GrowsPrefixAcrossSequentialCorrectKeystrokes()
    {
        var enemies = new List<Dictionary<string, object>> { Enemy(9, "storm") };
        var typedInputs = new[] { "s", "st", "sto", "stor", "storm" };

        for (int i = 0; i < typedInputs.Length; i++)
        {
            var result = TypingFeedback.EnemyCandidates(typedInputs[i], enemies);
            Assert.Equal(i + 1, result.BestPrefixLen);
            Assert.Equal(new[] { 9 }, result.BestIds);
            Assert.Equal(new[] { 9 }, result.CandidateIds);

            if (i < typedInputs.Length - 1)
            {
                Assert.Null(result.ExactId);
                Assert.Single(result.ExpectedNextChars);
                Assert.Equal("storm"[i + 1], result.ExpectedNextChars[0]);
            }
            else
            {
                Assert.Equal(9, result.ExactId);
                Assert.Empty(result.ExpectedNextChars);
            }
        }
    }

    [Fact]
    public void EnemyCandidates_ResetBehavior_EmptyInputReturnsClearedFeedback()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, "alpha"),
            Enemy(2, "alps"),
        };

        var activeResult = TypingFeedback.EnemyCandidates("al", enemies);
        Assert.NotEmpty(activeResult.CandidateIds);

        var resetResult = TypingFeedback.EnemyCandidates(string.Empty, enemies);

        Assert.Equal(string.Empty, resetResult.Typed);
        Assert.Null(resetResult.ExactId);
        Assert.Equal(0, resetResult.BestPrefixLen);
        Assert.Empty(resetResult.BestIds);
        Assert.Empty(resetResult.CandidateIds);
        Assert.Empty(resetResult.ExpectedNextChars);
    }

    [Fact]
    public void EnemyCandidates_IgnoresDeadAndInvalidEnemyEntries()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(1, "alpha", alive: false),
            new() { ["id"] = 2, ["word"] = "alpha", ["alive"] = "true" },
            new() { ["id"] = 3, ["word"] = string.Empty, ["alive"] = true },
            new() { ["id"] = 4, ["alive"] = true },
            Enemy(5, "alps"),
        };

        var result = TypingFeedback.EnemyCandidates("al", enemies);

        Assert.Null(result.ExactId);
        Assert.Equal(2, result.BestPrefixLen);
        Assert.Equal(new[] { 5 }, result.BestIds);
        Assert.Equal(new[] { 5 }, result.CandidateIds);
        Assert.Equal(new[] { 'p' }, result.ExpectedNextChars);
    }

    private static Dictionary<string, object> Enemy(int id, string word, bool alive = true)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["word"] = word,
            ["alive"] = alive,
        };
    }
}
