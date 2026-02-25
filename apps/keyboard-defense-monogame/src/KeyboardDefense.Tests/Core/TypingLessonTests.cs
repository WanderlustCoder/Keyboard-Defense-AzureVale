using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public sealed class TypingLessonTests
{
    [Fact]
    public void LessonProgression_NextLessonAdvancesWithinAndAcrossStages()
    {
        EnsureLessonsLoaded();
        var path = RequirePath("beginner");
        var stage1 = path.Stages.Single(stage => stage.Stage == 1);
        var stage2 = path.Stages.Single(stage => stage.Stage == 2);
        var progress = new LessonProgress();

        Assert.True(stage1.LessonIds.Count >= 2, "Expected beginner stage 1 to have at least two lessons.");
        Assert.NotEmpty(stage2.LessonIds);
        Assert.Equal(stage1.LessonIds[0], GetNextLessonToPractice(path, progress));

        progress.RecordAttempt(stage1.LessonIds[0], 24, 0.90, 10, 1);
        Assert.Equal(stage1.LessonIds[1], GetNextLessonToPractice(path, progress));

        CompleteLessons(progress, stage1.LessonIds.Skip(1));
        Assert.Equal(stage2.LessonIds[0], GetNextLessonToPractice(path, progress));
    }

    [Fact]
    public void LessonProgression_UnlockingNextStageRequiresCompletingCurrentStage()
    {
        EnsureLessonsLoaded();
        var path = RequirePath("beginner");
        var stage1 = path.Stages.Single(stage => stage.Stage == 1);
        var stage2 = path.Stages.Single(stage => stage.Stage == 2);
        var progress = new LessonProgress();

        var initiallyUnlocked = ComputeUnlockedLessonsByStage(path, progress);
        Assert.True(initiallyUnlocked.SetEquals(stage1.LessonIds), "Only stage 1 should be unlocked initially.");

        CompleteLessons(progress, stage1.LessonIds.Take(stage1.LessonIds.Count - 1));
        var stillLocked = ComputeUnlockedLessonsByStage(path, progress);
        Assert.DoesNotContain(stage2.LessonIds[0], stillLocked);

        progress.RecordAttempt(stage1.LessonIds[^1], 22, 0.88, 10, 2);
        var afterStageOne = ComputeUnlockedLessonsByStage(path, progress);
        Assert.Contains(stage2.LessonIds[0], afterStageOne);
    }

    [Fact]
    public void DrillCompletionTracking_TracksAttemptsPerTemplate()
    {
        var drillIds = LoadDrillTemplateIds();
        Assert.True(drillIds.Count >= 2, "Expected at least two drill templates in drills.json.");

        string firstDrill = drillIds[0];
        string secondDrill = drillIds[1];
        var progress = new LessonProgress();

        progress.RecordAttempt(firstDrill, 31, 0.96, 20, 0);  // 3 stars
        progress.RecordAttempt(secondDrill, 24, 0.90, 16, 2); // 2 stars
        progress.RecordAttempt(secondDrill, 18, 0.80, 10, 5); // 1 star attempt, best remains 2

        Assert.True(progress.IsCompleted(firstDrill));
        Assert.True(progress.IsCompleted(secondDrill));
        Assert.Equal(3, progress.GetStars(firstDrill));
        Assert.Equal(2, progress.GetStars(secondDrill));
        Assert.Equal(2, progress.GetResult(secondDrill).Attempts);
        Assert.Equal(5, progress.GetTotalStars());
        Assert.Equal(2, progress.GetCompletedCount());
    }

    [Fact]
    public void DrillCompletionTracking_DrillResultsDoNotAffectLessonResults()
    {
        EnsureLessonsLoaded();
        string drillId = LoadDrillTemplateIds().First();
        const string lessonId = "full_alpha";
        var progress = new LessonProgress();

        progress.RecordAttempt(drillId, 20, 0.86, 12, 2);

        Assert.True(progress.IsCompleted(drillId));
        Assert.False(progress.IsCompleted(lessonId));
        Assert.Equal(0, progress.GetStars(lessonId));
    }

    [Fact]
    public void LessonData_CharsetLessonsUseUniquePrintableCharacters()
    {
        EnsureLessonsLoaded();
        var charsetLessons = LessonsData.LessonIds()
            .Select(RequireLesson)
            .Where(lesson => lesson.Mode == "charset")
            .ToList();

        Assert.NotEmpty(charsetLessons);
        foreach (var lesson in charsetLessons)
        {
            Assert.NotEmpty(lesson.Charset);
            var seen = new HashSet<string>(StringComparer.Ordinal);

            foreach (string symbol in lesson.Charset)
            {
                Assert.True(symbol.Length == 1, $"Lesson '{lesson.Id}' contains non-single-character token '{symbol}'.");
                char ch = symbol[0];
                Assert.False(char.IsWhiteSpace(ch), $"Lesson '{lesson.Id}' contains whitespace in charset.");
                Assert.InRange((int)ch, 32, 126);
                Assert.True(seen.Add(symbol), $"Lesson '{lesson.Id}' contains duplicate charset token '{symbol}'.");
            }
        }
    }

    [Fact]
    public void StarRatingCalculation_UsesExpectedThresholds()
    {
        Assert.Equal(3, LessonProgress.CalculateStars(30, 0.95));
        Assert.Equal(3, LessonProgress.CalculateStars(45, 0.99));
        Assert.Equal(2, LessonProgress.CalculateStars(29.9, 0.95));
        Assert.Equal(2, LessonProgress.CalculateStars(10, 0.85));
        Assert.Equal(1, LessonProgress.CalculateStars(120, 0.8499));
    }

    [Fact]
    public void LessonDifficultyOrdering_MilestoneCharsetBreadthIncreases()
    {
        EnsureLessonsLoaded();
        var milestoneIds = new[]
        {
            "intro_home_row",
            "home_row_1",
            "reach_row_1",
            "bottom_row_2",
            "full_alpha",
            "numbers_2",
            "symbols_2",
        };

        var breadth = milestoneIds
            .Select(id => RequireLesson(id).Charset.Distinct(StringComparer.Ordinal).Count())
            .ToArray();

        for (int i = 1; i < breadth.Length; i++)
        {
            Assert.True(
                breadth[i] > breadth[i - 1],
                $"Expected '{milestoneIds[i]}' to have broader charset than '{milestoneIds[i - 1]}', but found {breadth[i]} <= {breadth[i - 1]}.");
        }
    }

    [Fact]
    public void HomeRowVsFullKeyboardGating_HomeRowLessonsComeBeforeFullAlphabet()
    {
        EnsureLessonsLoaded();
        var path = RequirePath("beginner");
        var stageByLesson = path.Stages
            .SelectMany(stage => stage.LessonIds.Select(lessonId => new { lessonId, stage.Stage }))
            .ToDictionary(item => item.lessonId, item => item.Stage, StringComparer.Ordinal);

        Assert.True(stageByLesson["home_row_1"] < stageByLesson["full_alpha"]);
        Assert.True(stageByLesson["home_row_words"] < stageByLesson["full_alpha_words"]);
    }

    [Fact]
    public void HomeRowVsFullKeyboardGating_FullAlphabetUnlocksAfterPriorStagesComplete()
    {
        EnsureLessonsLoaded();
        var path = RequirePath("beginner");
        var progress = new LessonProgress();

        var stage3AndEarlier = path.Stages
            .Where(stage => stage.Stage <= 3)
            .SelectMany(stage => stage.LessonIds);
        CompleteLessons(progress, stage3AndEarlier);

        var afterHomeRow = ComputeUnlockedLessonsByStage(path, progress);
        Assert.DoesNotContain("full_alpha", afterHomeRow);
        Assert.Contains(path.Stages.Single(stage => stage.Stage == 4).LessonIds[0], afterHomeRow);

        var stage4And5 = path.Stages
            .Where(stage => stage.Stage is 4 or 5)
            .SelectMany(stage => stage.LessonIds);
        CompleteLessons(progress, stage4And5);

        var afterStageFive = ComputeUnlockedLessonsByStage(path, progress);
        Assert.Contains("full_alpha", afterStageFive);
    }

    private static void EnsureLessonsLoaded()
    {
        LessonsData.LoadData(ResolveDataDirectory());
    }

    private static GraduationPath RequirePath(string pathId)
    {
        var path = LessonsData.GetPaths().SingleOrDefault(candidate => candidate.Id == pathId);
        Assert.NotNull(path);
        return path!;
    }

    private static LessonEntry RequireLesson(string lessonId)
    {
        var lesson = LessonsData.GetLesson(lessonId);
        Assert.NotNull(lesson);
        return lesson!;
    }

    private static IReadOnlyList<string> LoadDrillTemplateIds()
    {
        string path = Path.Combine(ResolveDataDirectory(), "drills.json");
        using var document = JsonDocument.Parse(File.ReadAllText(path));
        JsonElement templates = document.RootElement.GetProperty("templates");

        var ids = new List<string>();
        foreach (JsonElement template in templates.EnumerateArray())
        {
            if (!template.TryGetProperty("id", out JsonElement idNode) || idNode.ValueKind != JsonValueKind.String)
            {
                continue;
            }

            string? id = idNode.GetString();
            if (!string.IsNullOrWhiteSpace(id))
            {
                ids.Add(id);
            }
        }

        return ids;
    }

    private static HashSet<string> ComputeUnlockedLessonsByStage(GraduationPath path, LessonProgress progress)
    {
        var unlocked = new HashSet<string>(StringComparer.Ordinal);
        var orderedStages = path.Stages.OrderBy(stage => stage.Stage).ToList();

        foreach (var stage in orderedStages)
        {
            bool previousStagesComplete = orderedStages
                .Where(previous => previous.Stage < stage.Stage)
                .All(previous => previous.LessonIds.All(progress.IsCompleted));
            if (!previousStagesComplete)
            {
                break;
            }

            foreach (string lessonId in stage.LessonIds)
            {
                unlocked.Add(lessonId);
            }
        }

        return unlocked;
    }

    private static string? GetNextLessonToPractice(GraduationPath path, LessonProgress progress)
    {
        foreach (var stage in path.Stages.OrderBy(candidate => candidate.Stage))
        {
            if (stage.LessonIds.All(progress.IsCompleted))
            {
                continue;
            }

            return stage.LessonIds.FirstOrDefault(lessonId => !progress.IsCompleted(lessonId));
        }

        return null;
    }

    private static void CompleteLessons(LessonProgress progress, IEnumerable<string> lessonIds)
    {
        foreach (string lessonId in lessonIds)
        {
            progress.RecordAttempt(lessonId, 24, 0.90, 10, 1);
        }
    }

    private static string ResolveDataDirectory()
    {
        string? directory = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrEmpty(directory); i++)
        {
            string candidate = Path.Combine(directory, "data");
            if (File.Exists(Path.Combine(candidate, "lessons.json")) &&
                File.Exists(Path.Combine(candidate, "drills.json")))
            {
                return candidate;
            }

            directory = Directory.GetParent(directory)?.FullName;
        }

        throw new DirectoryNotFoundException("Unable to locate data/lessons.json and data/drills.json from test base directory.");
    }
}
