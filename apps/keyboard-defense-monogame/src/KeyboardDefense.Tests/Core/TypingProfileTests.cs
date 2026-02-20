using System.Linq;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class TypingProfileTests
{
    private static TypingProfile CreateFreshProfile()
    {
        var profile = new TypingProfile();
        profile.Reset();
        return profile;
    }

    [Fact]
    public void RecordCorrectChar_IncrementsTotals()
    {
        var profile = CreateFreshProfile();
        profile.RecordCorrectChar('a');
        profile.RecordCorrectChar('a');
        profile.RecordCorrectChar('a');
        Assert.Equal(3, profile.TotalCharsTyped);
        Assert.True(profile.KeyStats.ContainsKey('a'));
        Assert.Equal(3, profile.KeyStats['a'].Correct);
        Assert.Equal(3, profile.KeyStats['a'].Total);
    }

    [Fact]
    public void RecordError_IncrementsTotal_NotCorrect()
    {
        var profile = CreateFreshProfile();
        profile.RecordCorrectChar('a');
        profile.RecordError('a', 's');
        Assert.Equal(1, profile.TotalErrors);
        Assert.Equal(1, profile.KeyStats['a'].Correct);
        Assert.Equal(2, profile.KeyStats['a'].Total);
    }

    [Fact]
    public void GetKeyAccuracy_ReturnsMinus1_InsufficientData()
    {
        var profile = CreateFreshProfile();
        Assert.Equal(-1, profile.GetKeyAccuracy('z'));
        profile.RecordCorrectChar('z');
        Assert.Equal(-1, profile.GetKeyAccuracy('z')); // Still below MinSamplesForWeakKey
    }

    [Fact]
    public void GetKeyAccuracy_CalculatesCorrectly()
    {
        var profile = CreateFreshProfile();
        for (int i = 0; i < 8; i++) profile.RecordCorrectChar('f');
        for (int i = 0; i < 2; i++) profile.RecordError('f', 'd');
        // 8 correct, 2 errors => 10 total, 8/10 = 0.8
        Assert.Equal(0.8, profile.GetKeyAccuracy('f'), 2);
    }

    [Fact]
    public void GetWeakKeys_IdentifiesLowAccuracy()
    {
        var profile = CreateFreshProfile();
        // Strong key: 10/10 = 100%
        for (int i = 0; i < 10; i++) profile.RecordCorrectChar('a');
        // Weak key: 6/10 = 60%
        for (int i = 0; i < 6; i++) profile.RecordCorrectChar('z');
        for (int i = 0; i < 4; i++) profile.RecordError('z', 'x');

        var weak = profile.GetWeakKeys();
        Assert.Contains('z', weak);
        Assert.DoesNotContain('a', weak);
    }

    [Fact]
    public void GetStrongKeys_IdentifiesHighAccuracy()
    {
        var profile = CreateFreshProfile();
        for (int i = 0; i < 10; i++) profile.RecordCorrectChar('a');
        for (int i = 0; i < 6; i++) profile.RecordCorrectChar('z');
        for (int i = 0; i < 4; i++) profile.RecordError('z', 'x');

        var strong = profile.GetStrongKeys();
        Assert.Contains('a', strong);
        Assert.DoesNotContain('z', strong);
    }

    [Fact]
    public void RecordSession_AddsToCappedHistory()
    {
        var profile = CreateFreshProfile();
        for (int i = 0; i < 25; i++)
            profile.RecordSession(30 + i, 0.9, 10, 1, 60.0, "home_row");

        Assert.Equal(TypingProfile.MaxSessionHistory, profile.Sessions.Count);
        // Oldest should have been trimmed
        Assert.Equal(35, profile.Sessions[0].Wpm, 1);
    }

    [Fact]
    public void GetAverageWpm_ReturnsLastNAverage()
    {
        var profile = CreateFreshProfile();
        profile.RecordSession(20, 0.9, 10, 1, 60.0);
        profile.RecordSession(30, 0.9, 10, 1, 60.0);
        profile.RecordSession(40, 0.9, 10, 1, 60.0);

        double avg = profile.GetAverageWpm(3);
        Assert.Equal(30.0, avg, 1);
    }

    [Fact]
    public void GetWpmTrend_PositiveWhenImproving()
    {
        var profile = CreateFreshProfile();
        profile.RecordSession(20, 0.9, 10, 1, 60.0);
        profile.RecordSession(25, 0.9, 10, 1, 60.0);
        profile.RecordSession(35, 0.9, 10, 1, 60.0);
        profile.RecordSession(40, 0.9, 10, 1, 60.0);

        Assert.True(profile.GetWpmTrend() > 0);
    }

    [Fact]
    public void GetDifficultyLevel_ScalesWithSkill()
    {
        var profile = CreateFreshProfile();
        // Low skill = low difficulty
        profile.RecordSession(15, 0.6, 5, 5, 60.0);
        double lowDiff = profile.GetDifficultyLevel();

        // High skill = high difficulty
        profile.Reset();
        profile.RecordSession(60, 0.95, 50, 1, 60.0);
        // Need some key data for accuracy
        for (int i = 0; i < 20; i++) profile.RecordCorrectChar('a');
        double highDiff = profile.GetDifficultyLevel();

        Assert.True(highDiff > lowDiff);
    }

    [Fact]
    public void GetRecommendedLessonIds_ReturnsLessonsForWeakKeys()
    {
        var profile = CreateFreshProfile();
        // Make 'a' (home row) weak
        for (int i = 0; i < 6; i++) profile.RecordCorrectChar('a');
        for (int i = 0; i < 4; i++) profile.RecordError('a', 's');

        var recs = profile.GetRecommendedLessonIds();
        Assert.Contains("home_row", recs);
    }

    [Fact]
    public void GetFingerZone_ReturnsCorrectZones()
    {
        Assert.Equal(0, TypingProfile.GetFingerZone('q')); // left pinky
        Assert.Equal(0, TypingProfile.GetFingerZone('a'));
        Assert.Equal(1, TypingProfile.GetFingerZone('w')); // left ring
        Assert.Equal(2, TypingProfile.GetFingerZone('e')); // left middle
        Assert.Equal(3, TypingProfile.GetFingerZone('f')); // left index
        Assert.Equal(4, TypingProfile.GetFingerZone('j')); // right index
        Assert.Equal(5, TypingProfile.GetFingerZone('k')); // right middle
        Assert.Equal(6, TypingProfile.GetFingerZone('l')); // right ring
        Assert.Equal(7, TypingProfile.GetFingerZone('p')); // right pinky
    }

    [Fact]
    public void GetKeyRow_ReturnsCorrectRow()
    {
        Assert.Equal("home", TypingProfile.GetKeyRow('a'));
        Assert.Equal("home", TypingProfile.GetKeyRow('j'));
        Assert.Equal("top", TypingProfile.GetKeyRow('q'));
        Assert.Equal("top", TypingProfile.GetKeyRow('p'));
        Assert.Equal("bottom", TypingProfile.GetKeyRow('z'));
        Assert.Equal("bottom", TypingProfile.GetKeyRow('m'));
        Assert.Equal("number", TypingProfile.GetKeyRow('5'));
    }

    [Fact]
    public void GetOverallAccuracy_CalculatesAcrossAllKeys()
    {
        var profile = CreateFreshProfile();
        for (int i = 0; i < 9; i++) profile.RecordCorrectChar('a');
        profile.RecordError('a', 'b');
        // 9 correct / 10 total = 0.9
        Assert.Equal(0.9, profile.GetOverallAccuracy(), 2);
    }

    [Fact]
    public void IgnoresNonAlphanumeric()
    {
        var profile = CreateFreshProfile();
        profile.RecordCorrectChar('!');
        profile.RecordCorrectChar('@');
        Assert.Empty(profile.KeyStats);
        Assert.Equal(0, profile.TotalCharsTyped);
    }

    [Fact]
    public void CaseInsensitive()
    {
        var profile = CreateFreshProfile();
        profile.RecordCorrectChar('A');
        profile.RecordCorrectChar('a');
        Assert.Single(profile.KeyStats);
        Assert.Equal(2, profile.KeyStats['a'].Correct);
    }

    [Fact]
    public void KeyAccuracy_DefaultAccuracy_Is1()
    {
        var acc = new KeyAccuracy();
        Assert.Equal(1.0, acc.Accuracy);
    }

    [Fact]
    public void SessionSummary_DefaultValues()
    {
        var s = new SessionSummary();
        Assert.Equal(0, s.Wpm);
        Assert.Equal(0, s.Accuracy);
        Assert.Equal("", s.LessonId);
    }

    [Fact]
    public void Reset_ClearsEverything()
    {
        var profile = CreateFreshProfile();
        profile.RecordCorrectChar('a');
        profile.RecordSession(30, 0.9, 10, 1, 60.0);
        profile.Reset();

        Assert.Empty(profile.KeyStats);
        Assert.Empty(profile.Sessions);
        Assert.Equal(0, profile.TotalCharsTyped);
        Assert.Equal(0, profile.TotalWordsTyped);
        Assert.Equal(0, profile.TotalErrors);
    }
}
