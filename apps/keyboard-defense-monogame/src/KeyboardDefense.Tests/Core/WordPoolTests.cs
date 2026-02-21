using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

[Collection("WordPoolSerial")]
public class WordPoolCoreTests : IDisposable
{
    private const string Seed = "word_pool_test_seed";
    private const int Day = 11;

    public WordPoolCoreTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    [Fact]
    public void ShortWords_HasExpectedCount()
    {
        Assert.Equal(12, WordPool.ShortWords.Length);
    }

    [Fact]
    public void ShortWords_AreLowercaseAndLengthFourOrFive()
    {
        Assert.All(WordPool.ShortWords, word =>
        {
            Assert.InRange(word.Length, 4, 5);
            Assert.Equal(word, word.ToLowerInvariant());
        });
    }

    [Fact]
    public void MediumWords_HasExpectedCount()
    {
        Assert.Equal(14, WordPool.MediumWords.Length);
    }

    [Fact]
    public void MediumWords_AreLowercaseAndLengthFiveToSeven()
    {
        Assert.All(WordPool.MediumWords, word =>
        {
            Assert.InRange(word.Length, 5, 7);
            Assert.Equal(word, word.ToLowerInvariant());
        });
    }

    [Fact]
    public void LongWords_HasExpectedCount()
    {
        Assert.Equal(12, WordPool.LongWords.Length);
    }

    [Fact]
    public void LongWords_AreLowercaseAndLengthAtLeastEight()
    {
        Assert.All(WordPool.LongWords, word =>
        {
            Assert.True(word.Length >= 8, $"Expected long word length >= 8 but was {word.Length} for '{word}'.");
            Assert.Equal(word, word.ToLowerInvariant());
        });
    }

    [Fact]
    public void WordLists_HaveUniqueEntries()
    {
        Assert.Equal(WordPool.ShortWords.Length, WordPool.ShortWords.Distinct(StringComparer.Ordinal).Count());
        Assert.Equal(WordPool.MediumWords.Length, WordPool.MediumWords.Distinct(StringComparer.Ordinal).Count());
        Assert.Equal(WordPool.LongWords.Length, WordPool.LongWords.Distinct(StringComparer.Ordinal).Count());
    }

    [Fact]
    public void WordForEnemy_ScoutRaiderArmored_ReturnNonEmpty()
    {
        var kinds = new[] { "scout", "raider", "armored" };
        var used = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        int enemyId = 100;

        foreach (var kind in kinds)
        {
            var word = WordPool.WordForEnemy(Seed, Day, kind, enemyId++, used);
            Assert.False(string.IsNullOrWhiteSpace(word));
        }
    }

    [Fact]
    public void WordForEnemy_SameInputs_ReturnsDeterministicWord()
    {
        var wordA = WordPool.WordForEnemy(Seed, Day, "raider", 42, new HashSet<string>(), null);
        var wordB = WordPool.WordForEnemy(Seed, Day, "raider", 42, new HashSet<string>(), null);

        Assert.Equal(wordA, wordB);
    }

    [Fact]
    public void WordForEnemy_DifferentEnemyIds_ProduceVariedDeterministicResults()
    {
        var firstPass = Enumerable.Range(1, 8)
            .Select(id => WordPool.WordForEnemy(Seed, Day, "raider", id, new HashSet<string>(), null))
            .ToArray();
        var secondPass = Enumerable.Range(1, 8)
            .Select(id => WordPool.WordForEnemy(Seed, Day, "raider", id, new HashSet<string>(), null))
            .ToArray();

        Assert.Equal(firstPass, secondPass);
        Assert.True(firstPass.Distinct(StringComparer.Ordinal).Count() > 1);
    }

    [Fact]
    public void WordForEnemy_ScoutFallback_UsesShortWords()
    {
        var word = WordPool.WordForEnemy(Seed, Day, "scout", 7, new HashSet<string>(), null);

        Assert.InRange(word.Length, 3, 5);
        Assert.Contains(word, WordPool.ShortWords);
    }

    [Fact]
    public void WordForEnemy_ArmoredFallback_UsesLongWords()
    {
        var word = WordPool.WordForEnemy(Seed, Day, "armored", 7, new HashSet<string>(), null);

        Assert.True(word.Length >= 6);
        Assert.Contains(word, WordPool.LongWords);
    }

    [Fact]
    public void WordForEnemy_UnknownKindFallback_UsesMediumWords()
    {
        var word = WordPool.WordForEnemy(Seed, Day, "unknown_kind", 7, new HashSet<string>(), null);

        Assert.InRange(word.Length, 5, 7);
        Assert.Contains(word, WordPool.MediumWords);
    }

    [Fact]
    public void WordForEnemy_AvoidsAlreadyUsedWords()
    {
        var first = WordPool.WordForEnemy(Seed, Day, "raider", 25, new HashSet<string>(), null);
        var used = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { first };
        var second = WordPool.WordForEnemy(Seed, Day, "raider", 25, used, null);

        Assert.NotEqual(first, second);
        Assert.DoesNotContain(second, used);
    }

    [Fact]
    public void WordForEnemy_WhenFallbackListExhausted_ReturnsFoeIdentifier()
    {
        var used = new HashSet<string>(WordPool.ShortWords, StringComparer.OrdinalIgnoreCase);
        var word = WordPool.WordForEnemy(Seed, Day, "scout", 77, used, null);

        Assert.Equal("foe77", word);
    }

    [Fact]
    public void WordForEnemy_WithLessonId_ReturnsWordInExpectedRange()
    {
        var word = WordPool.WordForEnemy(Seed, Day, "raider", 90, new HashSet<string>(), "home_row");

        Assert.False(string.IsNullOrWhiteSpace(word));
        Assert.InRange(word.Length, 4, 7);
    }

    [Fact]
    public void WordForEnemy_WithLessonId_AvoidsAlreadyUsedWord()
    {
        var first = WordPool.WordForEnemy(Seed, Day, "raider", 91, new HashSet<string>(), "home_row");
        var used = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { first };
        var second = WordPool.WordForEnemy(Seed, Day, "raider", 91, used, "home_row");

        Assert.False(string.IsNullOrWhiteSpace(second));
        Assert.NotEqual(first, second);
    }

    [Fact]
    public void ScrambleWord_ReturnsSameLength()
    {
        const string word = "harvest";
        var scrambled = WordPool.ScrambleWord(word, Seed);

        Assert.Equal(word.Length, scrambled.Length);
    }

    [Fact]
    public void ScrambleWord_SingleCharacter_ReturnsSame()
    {
        Assert.Equal("q", WordPool.ScrambleWord("q", Seed));
    }

    [Fact]
    public void ScrambleWord_MultiCharacterWord_ChangesOrdering()
    {
        const string word = "abcd";
        var scrambled = WordPool.ScrambleWord(word, Seed);

        Assert.NotEqual(word, scrambled);
    }

    [Fact]
    public void ScrambleWord_SameSeed_IsDeterministic()
    {
        const string word = "riverstone";
        var scrambledA = WordPool.ScrambleWord(word, "stable-seed");
        var scrambledB = WordPool.ScrambleWord(word, "stable-seed");

        Assert.Equal(scrambledA, scrambledB);
    }

    [Fact]
    public void ScrambleWord_PreservesCharacterMultiset()
    {
        const string word = "moonlight";
        var scrambled = WordPool.ScrambleWord(word, Seed);

        Assert.Equal(word.OrderBy(c => c), scrambled.OrderBy(c => c));
    }
}

[CollectionDefinition("WordPoolSerial", DisableParallelization = true)]
public sealed class WordPoolSerialCollection
{
}
