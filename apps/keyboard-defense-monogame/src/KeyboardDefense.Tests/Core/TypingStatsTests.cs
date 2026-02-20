using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingStatsInstanceTests
{
    [Fact]
    public void StartNight_ResetsAllCounters()
    {
        var stats = new TypingStats();
        stats.Hits = 5;
        stats.Misses = 3;
        stats.TypedChars = 100;

        stats.StartNight(2, 3);

        Assert.Equal(2, stats.NightDay);
        Assert.Equal(3, stats.WaveTotal);
        Assert.Equal(0, stats.Hits);
        Assert.Equal(0, stats.Misses);
        Assert.Equal(0, stats.TypedChars);
        Assert.Equal(0, stats.CurrentCombo);
        Assert.Equal(0, stats.MaxCombo);
    }

    [Fact]
    public void OnTextChanged_TypingIncreasesTypedChars()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        stats.OnTextChanged("", "hel");
        Assert.Equal(3, stats.TypedChars);

        stats.OnTextChanged("hel", "hello");
        Assert.Equal(5, stats.TypedChars);
    }

    [Fact]
    public void OnTextChanged_DeletingIncreasesDeletedChars()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        stats.OnTextChanged("hello", "hel");
        Assert.Equal(2, stats.DeletedChars);
    }

    [Fact]
    public void OnEnterPressed_IncrementsCounter()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        stats.OnEnterPressed();
        stats.OnEnterPressed();
        Assert.Equal(2, stats.EnterPresses);
    }

    [Fact]
    public void RecordDefendAttempt_Hit_IncrementsHitsAndCombo()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = "test", ["id"] = 1, ["alive"] = true },
        };

        stats.RecordDefendAttempt("test", enemies);

        Assert.Equal(1, stats.Hits);
        Assert.Equal(0, stats.Misses);
        Assert.Equal(1, stats.CurrentCombo);
        Assert.Equal(1, stats.MaxCombo);
    }

    [Fact]
    public void RecordDefendAttempt_Miss_IncrementsAndResetsCombo()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = "test", ["id"] = 1, ["alive"] = true },
        };

        // Build combo
        stats.RecordDefendAttempt("test", enemies);
        stats.RecordDefendAttempt("test", enemies);
        Assert.Equal(2, stats.CurrentCombo);

        // Miss
        stats.RecordDefendAttempt("wrong", enemies);
        Assert.Equal(0, stats.CurrentCombo);
        Assert.Equal(2, stats.MaxCombo); // Max preserved
        Assert.Equal(1, stats.Misses);
    }

    [Fact]
    public void RecordDefendAttempt_CaseInsensitive()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = "Test", ["id"] = 1, ["alive"] = true },
        };

        stats.RecordDefendAttempt("TEST", enemies);
        Assert.Equal(1, stats.Hits);
    }

    [Fact]
    public void GetComboTier_ZeroCombo_ReturnsZero()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);
        Assert.Equal(0, stats.GetComboTier());
    }

    [Fact]
    public void GetComboTier_HighCombo_ReturnsHigherTier()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);
        stats.CurrentCombo = 50;
        Assert.True(stats.GetComboTier() > 0);
    }

    [Fact]
    public void DidReachThreshold_CrossingBoundary_ReturnsTrue()
    {
        var stats = new TypingStats();
        stats.CurrentCombo = 3; // First threshold
        Assert.True(stats.DidReachThreshold(2));
    }

    [Fact]
    public void DidReachThreshold_SameSide_ReturnsFalse()
    {
        var stats = new TypingStats();
        stats.CurrentCombo = 2;
        Assert.False(stats.DidReachThreshold(1));
    }

    [Fact]
    public void ToReportDict_ContainsAllKeys()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 3);

        var report = stats.ToReportDict();

        Assert.True(report.ContainsKey("night_day"));
        Assert.True(report.ContainsKey("wave_total"));
        Assert.True(report.ContainsKey("hits"));
        Assert.True(report.ContainsKey("misses"));
        Assert.True(report.ContainsKey("typed_chars"));
        Assert.True(report.ContainsKey("hit_rate"));
        Assert.True(report.ContainsKey("max_combo"));
        Assert.True(report.ContainsKey("avg_accuracy"));
    }

    [Fact]
    public void ToReportDict_HitRate_CalculatesCorrectly()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["word"] = "test", ["id"] = 1, ["alive"] = true },
        };

        stats.RecordDefendAttempt("test", enemies);
        stats.RecordDefendAttempt("wrong", enemies);

        var report = stats.ToReportDict();
        double hitRate = Convert.ToDouble(report["hit_rate"]);
        Assert.Equal(0.5, hitRate);
    }

    [Fact]
    public void RecordCommandEnter_IncrementsCount()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        stats.RecordCommandEnter("wait", true);
        Assert.Equal(1, stats.CommandEnters);
        Assert.Equal(1, stats.NightSteps);
        Assert.Equal(1, stats.WaitSteps);
    }

    [Fact]
    public void RecordCommandEnter_NonAdvancing_DoesNotIncrementSteps()
    {
        var stats = new TypingStats();
        stats.StartNight(1, 1);

        stats.RecordCommandEnter("status", false);
        Assert.Equal(1, stats.CommandEnters);
        Assert.Equal(0, stats.NightSteps);
    }
}
