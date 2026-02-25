using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

[Collection("WordPoolSerial")]
public class WordPoolExtendedTests : IDisposable
{
    private const string Seed = "word_pool_extended_seed";
    private const int Day = 17;
    private const string LessonId = "intro_home_row";
    private const string HomeRowCharset = "asdfghjkl";

    public WordPoolExtendedTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    [Fact]
    public void WordDifficultyBuckets_AreDisjointAcrossTiers()
    {
        var shortSet = WordPool.ShortWords.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var mediumSet = WordPool.MediumWords.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var longSet = WordPool.LongWords.ToHashSet(StringComparer.OrdinalIgnoreCase);

        Assert.Empty(shortSet.Intersect(mediumSet, StringComparer.OrdinalIgnoreCase));
        Assert.Empty(shortSet.Intersect(longSet, StringComparer.OrdinalIgnoreCase));
        Assert.Empty(mediumSet.Intersect(longSet, StringComparer.OrdinalIgnoreCase));
    }

    [Fact]
    public void WordDifficultyBuckets_HaveIncreasingAverageLengths()
    {
        double shortAverage = WordPool.ShortWords.Average(word => word.Length);
        double mediumAverage = WordPool.MediumWords.Average(word => word.Length);
        double longAverage = WordPool.LongWords.Average(word => word.Length);

        Assert.True(shortAverage < mediumAverage, $"Expected short avg < medium avg, got {shortAverage:F2} and {mediumAverage:F2}.");
        Assert.True(mediumAverage < longAverage, $"Expected medium avg < long avg, got {mediumAverage:F2} and {longAverage:F2}.");
    }

    [Fact]
    public void WordForEnemy_WithLessonId_UsesScoutLengthBandAcrossSamples()
    {
        foreach (int enemyId in Enumerable.Range(1, 48))
        {
            string word = WordPool.WordForEnemy(Seed, Day, "scout", enemyId, new HashSet<string>(), LessonId);
            Assert.InRange(word.Length, 3, 5);
        }
    }

    [Fact]
    public void WordForEnemy_WithLessonId_UsesRaiderLengthBandAcrossSamples()
    {
        foreach (int enemyId in Enumerable.Range(1, 48))
        {
            string word = WordPool.WordForEnemy(Seed, Day, "raider", enemyId, new HashSet<string>(), LessonId);
            Assert.InRange(word.Length, 4, 7);
        }
    }

    [Fact]
    public void WordForEnemy_WithLessonId_UsesArmoredLengthBandAcrossSamples()
    {
        foreach (int enemyId in Enumerable.Range(1, 48))
        {
            string word = WordPool.WordForEnemy(Seed, Day, "armored", enemyId, new HashSet<string>(), LessonId);
            Assert.InRange(word.Length, 6, 9);
        }
    }

    [Fact]
    public void WordForEnemy_WithLessonId_ProducesLengthVarietyWithinBand()
    {
        var lengths = Enumerable.Range(1, 64)
            .Select(enemyId => WordPool.WordForEnemy(Seed, Day, "raider", enemyId, new HashSet<string>(), LessonId).Length)
            .Distinct()
            .ToArray();

        Assert.True(lengths.Length >= 2, "Expected lesson-based generation to produce at least two different word lengths.");
        Assert.All(lengths, length => Assert.InRange(length, 4, 7));
    }

    [Fact]
    public void WordLists_DoNotIncludeProfanity()
    {
        var blockedWords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "fuck", "shit", "bitch", "asshole", "cunt", "dick", "whore", "slut", "fag", "bastard"
        };

        var allWords = WordPool.ShortWords
            .Concat(WordPool.MediumWords)
            .Concat(WordPool.LongWords)
            .ToArray();

        Assert.All(allWords, word => Assert.DoesNotContain(word, blockedWords));
    }

    [Fact]
    public void WordForEnemy_PoolCanRefreshAfterDepletionWhenUsageResets()
    {
        var used = new HashSet<string>(WordPool.ShortWords, StringComparer.OrdinalIgnoreCase);

        string exhausted = WordPool.WordForEnemy(Seed, Day, "scout", 777, used, null);
        Assert.Equal("foe777", exhausted);

        used.Clear();

        string refreshed = WordPool.WordForEnemy(Seed, Day, "scout", 777, used, null);
        Assert.Contains(refreshed, WordPool.ShortWords);
        Assert.NotEqual("foe777", refreshed);
    }

    [Fact]
    public void ResourceChallenge_StartChallenge_UsesCurrentLessonCharset()
    {
        var state = CreateChallengeState("home_row_seed", LessonId);
        PlaceNodeAtPlayer(state, "wood_grove");

        var challenge = ResourceChallenge.StartChallenge(state);

        Assert.NotNull(challenge);
        string word = challenge!["word"].ToString()!;
        Assert.All(word, ch => Assert.Contains(char.ToLowerInvariant(ch), HomeRowCharset));
    }

    [Fact]
    public void ResourceChallenge_ProcessChallengeInput_PartialCompletionScoresBelowPerfectButAboveZero()
    {
        var perfectState = CreateChallengeState("score_seed", LessonId);
        PlaceNodeAtPlayer(perfectState, "wood_grove");
        var perfectChallenge = ResourceChallenge.StartChallenge(perfectState);
        Assert.NotNull(perfectChallenge);

        string targetWord = perfectChallenge!["word"].ToString()!;
        ResourceChallenge.ProcessChallengeInput(perfectState, targetWord);
        int perfectYield = perfectState.Resources.GetValueOrDefault("wood", 0);

        var partialState = CreateChallengeState("score_seed", LessonId);
        PlaceNodeAtPlayer(partialState, "wood_grove");
        var partialChallenge = ResourceChallenge.StartChallenge(partialState);
        Assert.NotNull(partialChallenge);
        Assert.Equal(targetWord, partialChallenge!["word"].ToString());

        string partialInput = targetWord.Substring(0, Math.Max(1, targetWord.Length / 2));
        ResourceChallenge.ProcessChallengeInput(partialState, partialInput);
        int partialYield = partialState.Resources.GetValueOrDefault("wood", 0);

        Assert.True(partialYield > 0, "Partial completion should still produce some harvest yield.");
        Assert.True(partialYield < perfectYield, $"Expected partial yield ({partialYield}) to be lower than perfect yield ({perfectYield}).");
    }

    private static GameState CreateChallengeState(string seed, string lessonId)
    {
        var state = DefaultState.Create(seed);
        TypingMetrics.InitBattleMetrics(state);
        state.ActivityMode = "exploration";
        state.LessonId = lessonId;
        return state;
    }

    private static void PlaceNodeAtPlayer(GameState state, string nodeType)
    {
        var nodePos = state.PlayerPos;
        int nodeIndex = SimMap.Idx(nodePos.X, nodePos.Y, state.MapW);
        state.ResourceNodes[nodeIndex] = new Dictionary<string, object>
        {
            ["type"] = nodeType,
            ["pos"] = nodePos,
            ["zone"] = "safe",
            ["cooldown"] = 0f,
        };
    }
}
