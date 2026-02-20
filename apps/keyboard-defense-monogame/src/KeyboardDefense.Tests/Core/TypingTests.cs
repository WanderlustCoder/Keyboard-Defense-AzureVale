using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TypingFeedbackTests
{
    [Fact]
    public void NormalizeInput_TrimsAndLowers()
    {
        Assert.Equal("hello", TypingFeedback.NormalizeInput("  HELLO  "));
    }

    [Fact]
    public void NormalizeInput_NullReturnsEmpty()
    {
        Assert.Equal("", TypingFeedback.NormalizeInput(null!));
    }

    [Fact]
    public void PrefixLen_FullMatch()
    {
        Assert.Equal(5, TypingFeedback.PrefixLen("hello", "hello"));
    }

    [Fact]
    public void PrefixLen_PartialMatch()
    {
        Assert.Equal(3, TypingFeedback.PrefixLen("hel", "hello"));
    }

    [Fact]
    public void PrefixLen_NoMatch()
    {
        Assert.Equal(0, TypingFeedback.PrefixLen("xyz", "hello"));
    }

    [Fact]
    public void EditDistance_SameString_ReturnsZero()
    {
        Assert.Equal(0, TypingFeedback.EditDistance("hello", "hello"));
    }

    [Fact]
    public void EditDistance_OneDifference_ReturnsOne()
    {
        Assert.Equal(1, TypingFeedback.EditDistance("hello", "hallo"));
    }

    [Fact]
    public void EditDistance_EmptyString()
    {
        Assert.Equal(5, TypingFeedback.EditDistance("", "hello"));
        Assert.Equal(5, TypingFeedback.EditDistance("hello", ""));
    }

    [Fact]
    public void EditDistance_BothEmpty_ReturnsZero()
    {
        Assert.Equal(0, TypingFeedback.EditDistance("", ""));
    }

    [Fact]
    public void EnemyCandidates_EmptyInput_ReturnsNoMatches()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = "test", ["id"] = 1, ["alive"] = true },
        };
        var result = TypingFeedback.EnemyCandidates("", enemies);
        Assert.Null(result.ExactId);
    }

    [Fact]
    public void EnemyCandidates_ExactMatch_ReturnsMatch()
    {
        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = "test", ["id"] = 1, ["alive"] = true },
            new() { ["word"] = "other", ["id"] = 2, ["alive"] = true },
        };
        var result = TypingFeedback.EnemyCandidates("test", enemies);
        Assert.NotNull(result.ExactId);
    }
}

public class ComboSystemTests
{
    [Fact]
    public void GetTier_Zero_ReturnsDefault()
    {
        var tier = ComboSystem.GetTier(0);
        Assert.Equal("Default", tier.Name);
    }

    [Fact]
    public void GetTier_HighCombo_ReturnsHigherTier()
    {
        var tier3 = ComboSystem.GetTier(3);
        var tier10 = ComboSystem.GetTier(10);
        Assert.True(ComboSystem.GetTierIndex(10) > ComboSystem.GetTierIndex(3));
    }

    [Fact]
    public void GetDamageBonusPercent_Zero_ReturnsZero()
    {
        Assert.Equal(0, ComboSystem.GetDamageBonusPercent(0));
    }

    [Fact]
    public void GetDamageBonusPercent_HighCombo_ReturnsBonus()
    {
        Assert.True(ComboSystem.GetDamageBonusPercent(10) > 0);
    }

    [Fact]
    public void ApplyDamageBonus_NoCombo_NoChange()
    {
        Assert.Equal(10, ComboSystem.ApplyDamageBonus(10, 0));
    }

    [Fact]
    public void ApplyDamageBonus_WithCombo_Increases()
    {
        int boosted = ComboSystem.ApplyDamageBonus(10, 10);
        Assert.True(boosted > 10);
    }

    [Fact]
    public void IsTierMilestone_SameTier_ReturnsFalse()
    {
        Assert.False(ComboSystem.IsTierMilestone(0, 1));
    }

    [Fact]
    public void IsTierMilestone_CrossingThreshold_ReturnsTrue()
    {
        Assert.True(ComboSystem.IsTierMilestone(2, 3));
    }

    [Fact]
    public void FormatComboDisplay_Zero_ReturnsEmpty()
    {
        Assert.Equal("", ComboSystem.FormatComboDisplay(0));
    }
}

public class WordPoolTests
{
    [Fact]
    public void ShortWords_NotEmpty()
    {
        Assert.NotEmpty(WordPool.ShortWords);
    }

    [Fact]
    public void MediumWords_NotEmpty()
    {
        Assert.NotEmpty(WordPool.MediumWords);
    }

    [Fact]
    public void LongWords_NotEmpty()
    {
        Assert.NotEmpty(WordPool.LongWords);
    }

    [Fact]
    public void WordForEnemy_ReturnsNonEmpty()
    {
        var used = new HashSet<string>();
        string word = WordPool.WordForEnemy("seed", 1, "raider", 1, used);
        Assert.NotNull(word);
        Assert.NotEmpty(word);
    }

    [Fact]
    public void WordForEnemy_AvoidsDuplicates()
    {
        var used = new HashSet<string>();
        var words = new List<string>();
        for (int i = 0; i < 5; i++)
        {
            string word = WordPool.WordForEnemy("seed", 1, "raider", i + 1, used);
            words.Add(word);
            used.Add(word);
        }
        // All should be unique
        Assert.Equal(5, new HashSet<string>(words).Count);
    }

    [Fact]
    public void ScrambleWord_ReturnsSameLength()
    {
        string original = "hello";
        string scrambled = WordPool.ScrambleWord(original, "seed");
        Assert.Equal(original.Length, scrambled.Length);
    }

    [Fact]
    public void ScrambleWord_SingleChar_ReturnsSame()
    {
        Assert.Equal("a", WordPool.ScrambleWord("a", "seed"));
    }
}

public class TypingMetricsTests
{
    [Fact]
    public void InitBattleMetrics_SetsDefaults()
    {
        var state = new GameState();
        TypingMetrics.InitBattleMetrics(state);

        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["battle_chars_typed"]));
        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["battle_words_typed"]));
    }

    [Fact]
    public void RecordCharTyped_IncrementsCount()
    {
        var state = new GameState();
        TypingMetrics.InitBattleMetrics(state);
        TypingMetrics.RecordCharTyped(state, 'a');

        Assert.Equal(1, Convert.ToInt32(state.TypingMetrics["battle_chars_typed"]));
    }
}
