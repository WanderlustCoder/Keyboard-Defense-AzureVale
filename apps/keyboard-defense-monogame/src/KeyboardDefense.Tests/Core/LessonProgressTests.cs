using System;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

public class LessonProgressCoreTests : IDisposable
{
    private readonly LessonProgress _progress = LessonProgress.Instance;

    public LessonProgressCoreTests()
    {
        _progress.Reset();
    }

    public void Dispose()
    {
        _progress.Reset();
    }

    [Fact]
    public void GetResult_CreatesNewEntry_WhenLessonIsMissing()
    {
        var result = _progress.GetResult("lesson_1");

        Assert.NotNull(result);
        Assert.True(_progress.Results.ContainsKey("lesson_1"));
        Assert.Equal(0, result.Stars);
        Assert.Equal(0, result.Attempts);
    }

    [Fact]
    public void GetResult_ReturnsSameEntry_OnSecondCall()
    {
        var first = _progress.GetResult("lesson_repeat");
        var second = _progress.GetResult("lesson_repeat");

        Assert.Same(first, second);
        Assert.Single(_progress.Results);
    }

    [Fact]
    public void RecordAttempt_IncrementsAttempts()
    {
        _progress.RecordAttempt("lesson_attempts", 20, 0.9, 10, 2);
        _progress.RecordAttempt("lesson_attempts", 25, 0.92, 11, 1);

        Assert.Equal(2, _progress.GetResult("lesson_attempts").Attempts);
    }

    [Fact]
    public void RecordAttempt_ReturnsStarsForCurrentAttempt()
    {
        int stars = _progress.RecordAttempt("lesson_return", 30, 0.95, 12, 0);

        Assert.Equal(3, stars);
    }

    [Fact]
    public void RecordAttempt_UpdatesBestWpm_WhenImproved()
    {
        _progress.RecordAttempt("lesson_wpm_up", 20, 0.9, 10, 2);
        _progress.RecordAttempt("lesson_wpm_up", 28, 0.9, 10, 2);

        Assert.Equal(28, _progress.GetResult("lesson_wpm_up").BestWpm, 6);
    }

    [Fact]
    public void RecordAttempt_DoesNotLowerBestWpm_WhenNotImproved()
    {
        _progress.RecordAttempt("lesson_wpm_hold", 31, 0.9, 10, 2);
        _progress.RecordAttempt("lesson_wpm_hold", 25, 0.95, 10, 1);

        Assert.Equal(31, _progress.GetResult("lesson_wpm_hold").BestWpm, 6);
    }

    [Fact]
    public void RecordAttempt_UpdatesBestAccuracy_WhenImproved()
    {
        _progress.RecordAttempt("lesson_acc_up", 20, 0.86, 10, 3);
        _progress.RecordAttempt("lesson_acc_up", 20, 0.93, 10, 1);

        Assert.Equal(0.93, _progress.GetResult("lesson_acc_up").BestAccuracy, 6);
    }

    [Fact]
    public void RecordAttempt_DoesNotLowerBestAccuracy_WhenNotImproved()
    {
        _progress.RecordAttempt("lesson_acc_hold", 20, 0.96, 10, 1);
        _progress.RecordAttempt("lesson_acc_hold", 20, 0.9, 10, 2);

        Assert.Equal(0.96, _progress.GetResult("lesson_acc_hold").BestAccuracy, 6);
    }

    [Fact]
    public void RecordAttempt_UpdatesBestWordsCompleted_WhenImproved()
    {
        _progress.RecordAttempt("lesson_words_up", 20, 0.9, 8, 2);
        _progress.RecordAttempt("lesson_words_up", 20, 0.9, 12, 2);

        Assert.Equal(12, _progress.GetResult("lesson_words_up").BestWordsCompleted);
    }

    [Fact]
    public void RecordAttempt_DoesNotLowerBestWordsCompleted_WhenNotImproved()
    {
        _progress.RecordAttempt("lesson_words_hold", 20, 0.9, 12, 2);
        _progress.RecordAttempt("lesson_words_hold", 20, 0.9, 9, 1);

        Assert.Equal(12, _progress.GetResult("lesson_words_hold").BestWordsCompleted);
    }

    [Fact]
    public void RecordAttempt_StarsOnlyIncrease_NeverDecrease()
    {
        _progress.RecordAttempt("lesson_stars_hold", 30, 0.95, 12, 0);
        _progress.RecordAttempt("lesson_stars_hold", 10, 0.5, 4, 5);

        Assert.Equal(3, _progress.GetResult("lesson_stars_hold").Stars);
    }

    [Fact]
    public void RecordAttempt_SetsLastPlayedUtc()
    {
        DateTime before = DateTime.UtcNow;
        _progress.RecordAttempt("lesson_time", 22, 0.9, 10, 2);
        DateTime after = DateTime.UtcNow;

        var played = _progress.GetResult("lesson_time").LastPlayedUtc;
        Assert.True(played >= before);
        Assert.True(played <= after);
    }

    [Fact]
    public void CalculateStars_ReturnsThree_AtBoundary()
    {
        int stars = LessonProgress.CalculateStars(30, 0.95);

        Assert.Equal(3, stars);
    }

    [Fact]
    public void CalculateStars_ReturnsTwo_AtBoundary()
    {
        int stars = LessonProgress.CalculateStars(29.9, 0.85);

        Assert.Equal(2, stars);
    }

    [Fact]
    public void CalculateStars_ReturnsOne_BelowThreshold()
    {
        int stars = LessonProgress.CalculateStars(120, 0.8499);

        Assert.Equal(1, stars);
    }

    [Fact]
    public void GetStars_UnknownLesson_ReturnsZero()
    {
        Assert.Equal(0, _progress.GetStars("unknown"));
    }

    [Fact]
    public void IsCompleted_FalseBeforeAttempt_TrueAfterAttempt()
    {
        Assert.False(_progress.IsCompleted("lesson_done"));

        _progress.RecordAttempt("lesson_done", 18, 0.9, 8, 2);

        Assert.True(_progress.IsCompleted("lesson_done"));
    }

    [Fact]
    public void GetTotalStars_SumsAcrossMultipleLessons()
    {
        _progress.RecordAttempt("lesson_a", 30, 0.95, 12, 0); // 3
        _progress.RecordAttempt("lesson_b", 20, 0.9, 10, 2); // 2
        _progress.RecordAttempt("lesson_c", 15, 0.7, 6, 4); // 1

        Assert.Equal(6, _progress.GetTotalStars());
    }

    [Fact]
    public void GetCompletedCount_CountsLessonsWithStarsAboveZero()
    {
        _progress.GetResult("lesson_unplayed");
        _progress.RecordAttempt("lesson_played_1", 20, 0.9, 8, 1);
        _progress.RecordAttempt("lesson_played_2", 30, 0.95, 12, 0);

        Assert.Equal(2, _progress.GetCompletedCount());
    }

    [Fact]
    public void FormatStars_ReturnsExpectedStrings()
    {
        Assert.Equal("---", LessonProgress.FormatStars(0));
        Assert.Equal("*--", LessonProgress.FormatStars(1));
        Assert.Equal("**-", LessonProgress.FormatStars(2));
        Assert.Equal("***", LessonProgress.FormatStars(3));
        Assert.Equal("***", LessonProgress.FormatStars(9));
    }

    [Fact]
    public void Reset_ClearsAllLessonData()
    {
        _progress.RecordAttempt("lesson_reset_1", 20, 0.9, 8, 1);
        _progress.RecordAttempt("lesson_reset_2", 30, 0.95, 12, 0);

        _progress.Reset();

        Assert.Empty(_progress.Results);
        Assert.Equal(0, _progress.GetTotalStars());
        Assert.Equal(0, _progress.GetCompletedCount());
        Assert.Equal(0, _progress.GetStars("lesson_reset_1"));
        Assert.False(_progress.IsCompleted("lesson_reset_1"));
    }
}
