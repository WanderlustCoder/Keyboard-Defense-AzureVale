using System;
using System.Linq;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for TypingProfile — trends, edge cases, difficulty scaling,
/// space handling, finger zones, and serialization round-trips.
/// </summary>
public class TypingProfileExtendedTests
{
    private static TypingProfile CreateFresh()
    {
        var profile = new TypingProfile();
        profile.Reset();
        return profile;
    }

    // =========================================================================
    // GetAverageWpm — edge cases
    // =========================================================================

    [Fact]
    public void GetAverageWpm_NoSessions_ReturnsZero()
    {
        var profile = CreateFresh();
        Assert.Equal(0, profile.GetAverageWpm());
    }

    [Fact]
    public void GetAverageWpm_SingleSession_ReturnsItsWpm()
    {
        var profile = CreateFresh();
        profile.RecordSession(42, 0.9, 10, 1, 60.0);
        Assert.Equal(42, profile.GetAverageWpm(5), 1);
    }

    [Fact]
    public void GetAverageWpm_LastN_OnlyAveragesRecentSessions()
    {
        var profile = CreateFresh();
        profile.RecordSession(10, 0.9, 5, 0, 60);
        profile.RecordSession(20, 0.9, 5, 0, 60);
        profile.RecordSession(30, 0.9, 5, 0, 60);
        profile.RecordSession(40, 0.9, 5, 0, 60);
        profile.RecordSession(50, 0.9, 5, 0, 60);

        double avg2 = profile.GetAverageWpm(2);
        Assert.Equal(45.0, avg2, 1); // (40+50)/2
    }

    // =========================================================================
    // GetWpmTrend
    // =========================================================================

    [Fact]
    public void GetWpmTrend_SingleSession_ReturnsZero()
    {
        var profile = CreateFresh();
        profile.RecordSession(30, 0.9, 10, 1, 60);
        Assert.Equal(0, profile.GetWpmTrend());
    }

    [Fact]
    public void GetWpmTrend_DecliningPerformance_ReturnsNegative()
    {
        var profile = CreateFresh();
        profile.RecordSession(50, 0.9, 10, 1, 60);
        profile.RecordSession(45, 0.9, 10, 1, 60);
        profile.RecordSession(30, 0.9, 10, 1, 60);
        profile.RecordSession(25, 0.9, 10, 1, 60);

        Assert.True(profile.GetWpmTrend() < 0);
    }

    // =========================================================================
    // GetAccuracyTrend
    // =========================================================================

    [Fact]
    public void GetAccuracyTrend_ImprovingAccuracy_ReturnsPositive()
    {
        var profile = CreateFresh();
        profile.RecordSession(30, 0.70, 10, 3, 60);
        profile.RecordSession(30, 0.75, 10, 2, 60);
        profile.RecordSession(30, 0.90, 10, 1, 60);
        profile.RecordSession(30, 0.95, 10, 0, 60);

        Assert.True(profile.GetAccuracyTrend() > 0);
    }

    [Fact]
    public void GetAccuracyTrend_SingleSession_ReturnsZero()
    {
        var profile = CreateFresh();
        profile.RecordSession(30, 0.9, 10, 1, 60);
        Assert.Equal(0, profile.GetAccuracyTrend());
    }

    // =========================================================================
    // GetOverallAccuracy
    // =========================================================================

    [Fact]
    public void GetOverallAccuracy_NoData_ReturnsOne()
    {
        var profile = CreateFresh();
        Assert.Equal(1.0, profile.GetOverallAccuracy());
    }

    [Fact]
    public void GetOverallAccuracy_MultipleKeys_AggregatesCorrectly()
    {
        var profile = CreateFresh();
        // Key 'a': 8/10 correct
        for (int i = 0; i < 8; i++) profile.RecordCorrectChar('a');
        for (int i = 0; i < 2; i++) profile.RecordError('a', 'b');

        // Key 'b': 6/10 correct
        for (int i = 0; i < 6; i++) profile.RecordCorrectChar('b');
        for (int i = 0; i < 4; i++) profile.RecordError('b', 'c');

        // Total: 14/20 = 0.7
        Assert.Equal(0.7, profile.GetOverallAccuracy(), 2);
    }

    // =========================================================================
    // GetDifficultyLevel
    // =========================================================================

    [Fact]
    public void GetDifficultyLevel_NoData_ReturnsZero()
    {
        var profile = CreateFresh();
        Assert.Equal(0, profile.GetDifficultyLevel());
    }

    [Fact]
    public void GetDifficultyLevel_HighWpmHighAccuracy_NearOne()
    {
        var profile = CreateFresh();
        profile.RecordSession(80, 0.95, 50, 1, 60);
        for (int i = 0; i < 20; i++) profile.RecordCorrectChar('a');

        double diff = profile.GetDifficultyLevel();
        Assert.True(diff >= 0.8, $"Expected high difficulty, got {diff}");
    }

    [Fact]
    public void GetDifficultyLevel_LowAccuracy_ReducesDifficulty()
    {
        var profile = CreateFresh();
        profile.RecordSession(60, 0.95, 50, 1, 60);

        // Simulate bad accuracy
        for (int i = 0; i < 5; i++) profile.RecordCorrectChar('a');
        for (int i = 0; i < 5; i++) profile.RecordError('a', 'b');

        double diff = profile.GetDifficultyLevel();
        Assert.True(diff < 1.0, $"Low accuracy should reduce difficulty, got {diff}");
    }

    [Fact]
    public void GetDifficultyLevel_AlwaysBetweenZeroAndOne()
    {
        var profile = CreateFresh();
        profile.RecordSession(200, 0.99, 100, 0, 60); // extremely high WPM
        for (int i = 0; i < 20; i++) profile.RecordCorrectChar('a');

        double diff = profile.GetDifficultyLevel();
        Assert.InRange(diff, 0, 1);
    }

    // =========================================================================
    // Space character
    // =========================================================================

    [Fact]
    public void RecordCorrectChar_Space_IsTracked()
    {
        var profile = CreateFresh();
        profile.RecordCorrectChar(' ');

        Assert.True(profile.KeyStats.ContainsKey(' '));
        Assert.Equal(1, profile.KeyStats[' '].Correct);
        Assert.Equal(1, profile.TotalCharsTyped);
    }

    // =========================================================================
    // Digit handling
    // =========================================================================

    [Fact]
    public void RecordCorrectChar_Digits_AreTracked()
    {
        var profile = CreateFresh();
        profile.RecordCorrectChar('5');
        profile.RecordCorrectChar('0');

        Assert.True(profile.KeyStats.ContainsKey('5'));
        Assert.True(profile.KeyStats.ContainsKey('0'));
        Assert.Equal(2, profile.TotalCharsTyped);
    }

    // =========================================================================
    // GetFingerZone — extended coverage
    // =========================================================================

    [Theory]
    [InlineData('1', 0)]
    [InlineData('z', 0)]
    [InlineData('2', 1)]
    [InlineData('x', 1)]
    [InlineData('3', 2)]
    [InlineData('c', 2)]
    [InlineData('4', 3)]
    [InlineData('5', 3)]
    [InlineData('t', 3)]
    [InlineData('g', 3)]
    [InlineData('b', 3)]
    [InlineData('6', 4)]
    [InlineData('7', 4)]
    [InlineData('y', 4)]
    [InlineData('h', 4)]
    [InlineData('n', 4)]
    [InlineData('8', 5)]
    [InlineData(',', 5)]
    [InlineData('9', 6)]
    [InlineData('.', 6)]
    [InlineData('0', 7)]
    [InlineData('/', 7)]
    public void GetFingerZone_MapsCorrectly(char c, int expectedZone)
    {
        Assert.Equal(expectedZone, TypingProfile.GetFingerZone(c));
    }

    [Fact]
    public void GetFingerZone_UnknownChar_ReturnsMinusOne()
    {
        Assert.Equal(-1, TypingProfile.GetFingerZone('~'));
        Assert.Equal(-1, TypingProfile.GetFingerZone('\t'));
    }

    [Fact]
    public void GetFingerZone_CaseInsensitive()
    {
        Assert.Equal(TypingProfile.GetFingerZone('a'), TypingProfile.GetFingerZone('A'));
        Assert.Equal(TypingProfile.GetFingerZone('m'), TypingProfile.GetFingerZone('M'));
    }

    // =========================================================================
    // GetKeyRow — extended coverage
    // =========================================================================

    [Theory]
    [InlineData('!', "other")]
    [InlineData('@', "other")]
    [InlineData(' ', "other")]
    public void GetKeyRow_SpecialChars_ReturnOther(char c, string expected)
    {
        Assert.Equal(expected, TypingProfile.GetKeyRow(c));
    }

    [Fact]
    public void GetKeyRow_CaseInsensitive()
    {
        Assert.Equal(TypingProfile.GetKeyRow('a'), TypingProfile.GetKeyRow('A'));
        Assert.Equal(TypingProfile.GetKeyRow('q'), TypingProfile.GetKeyRow('Q'));
    }

    // =========================================================================
    // GetRecommendedLessonIds
    // =========================================================================

    [Fact]
    public void GetRecommendedLessonIds_NoWeakKeys_ReturnsEmpty()
    {
        var profile = CreateFresh();
        for (int i = 0; i < 20; i++) profile.RecordCorrectChar('a');

        var recs = profile.GetRecommendedLessonIds();
        Assert.Empty(recs);
    }

    [Fact]
    public void GetRecommendedLessonIds_WeakTopRow_ReturnsTopRow()
    {
        var profile = CreateFresh();
        // Make 'q' (top row) weak
        for (int i = 0; i < 5; i++) profile.RecordCorrectChar('q');
        for (int i = 0; i < 5; i++) profile.RecordError('q', 'w');

        var recs = profile.GetRecommendedLessonIds();
        Assert.Contains("top_row", recs);
    }

    [Fact]
    public void GetRecommendedLessonIds_WeakBottomRow_ReturnsBottomRow()
    {
        var profile = CreateFresh();
        for (int i = 0; i < 5; i++) profile.RecordCorrectChar('z');
        for (int i = 0; i < 5; i++) profile.RecordError('z', 'x');

        var recs = profile.GetRecommendedLessonIds();
        Assert.Contains("bottom_row", recs);
    }

    [Fact]
    public void GetRecommendedLessonIds_WeakNumber_ReturnsNumbers()
    {
        var profile = CreateFresh();
        for (int i = 0; i < 5; i++) profile.RecordCorrectChar('5');
        for (int i = 0; i < 5; i++) profile.RecordError('5', '4');

        var recs = profile.GetRecommendedLessonIds();
        Assert.Contains("numbers", recs);
    }

    // =========================================================================
    // GetWeakKeys / GetStrongKeys — sorting
    // =========================================================================

    [Fact]
    public void GetWeakKeys_SortedWeakestFirst()
    {
        var profile = CreateFresh();

        // 'a': 7/10 = 70% (below 75% threshold)
        for (int i = 0; i < 7; i++) profile.RecordCorrectChar('a');
        for (int i = 0; i < 3; i++) profile.RecordError('a', 'b');

        // 'b': 5/10 = 50% (weaker)
        for (int i = 0; i < 5; i++) profile.RecordCorrectChar('b');
        for (int i = 0; i < 5; i++) profile.RecordError('b', 'c');

        var weak = profile.GetWeakKeys();
        Assert.Equal(2, weak.Count);
        Assert.Equal('b', weak[0]); // weaker comes first
        Assert.Equal('a', weak[1]);
    }

    [Fact]
    public void GetStrongKeys_SortedStrongestFirst()
    {
        var profile = CreateFresh();

        // 'a': 10/10 = 100%
        for (int i = 0; i < 10; i++) profile.RecordCorrectChar('a');

        // 'b': 93/100 = 93% (above 92% threshold)
        for (int i = 0; i < 93; i++) profile.RecordCorrectChar('b');
        for (int i = 0; i < 7; i++) profile.RecordError('b', 'c');

        var strong = profile.GetStrongKeys();
        Assert.Equal(2, strong.Count);
        Assert.Equal('a', strong[0]); // strongest first
    }

    // =========================================================================
    // RecordSession — cumulative stats
    // =========================================================================

    [Fact]
    public void RecordSession_AccumulatesTotalWordsAndPlayTime()
    {
        var profile = CreateFresh();
        profile.RecordSession(30, 0.9, 15, 2, 120);
        profile.RecordSession(40, 0.95, 20, 1, 180);

        Assert.Equal(35, profile.TotalWordsTyped);
        Assert.Equal(300, profile.TotalPlayTimeSeconds);
    }

    [Fact]
    public void RecordSession_StoresLessonId()
    {
        var profile = CreateFresh();
        profile.RecordSession(30, 0.9, 10, 1, 60, "home_row");

        Assert.Equal("home_row", profile.Sessions[0].LessonId);
    }

    [Fact]
    public void RecordSession_NullLessonId_DefaultsToEmpty()
    {
        var profile = CreateFresh();
        profile.RecordSession(30, 0.9, 10, 1, 60, null);

        Assert.Equal("", profile.Sessions[0].LessonId);
    }

    // =========================================================================
    // Constants
    // =========================================================================

    [Fact]
    public void Constants_HaveExpectedValues()
    {
        Assert.Equal(20, TypingProfile.MaxSessionHistory);
        Assert.Equal(10, TypingProfile.MinSamplesForWeakKey);
        Assert.Equal(0.75, TypingProfile.WeakKeyThreshold);
        Assert.Equal(0.92, TypingProfile.StrongKeyThreshold);
    }

    // =========================================================================
    // KeyAccuracy.Accuracy property
    // =========================================================================

    [Fact]
    public void KeyAccuracy_ComputesRatioCorrectly()
    {
        var acc = new KeyAccuracy { Correct = 7, Total = 10 };
        Assert.Equal(0.7, acc.Accuracy, 2);
    }

    [Fact]
    public void KeyAccuracy_ZeroTotal_ReturnsOne()
    {
        var acc = new KeyAccuracy { Correct = 0, Total = 0 };
        Assert.Equal(1.0, acc.Accuracy);
    }
}
