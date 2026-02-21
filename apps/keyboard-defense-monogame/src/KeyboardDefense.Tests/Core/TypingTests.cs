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
