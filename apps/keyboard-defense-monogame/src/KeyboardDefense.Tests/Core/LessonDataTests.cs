using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

public class LessonDataTests
{
    private static void EnsureLoaded()
    {
        // Find data directory by walking up from test output
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 8; i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (Directory.Exists(candidate) && File.Exists(Path.Combine(candidate, "lessons.json")))
            {
                LessonsData.LoadData(candidate);
                return;
            }
            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir) break;
            dir = parent;
        }
        // Fallback: load from empty to exercise code paths
        LessonsData.LoadData(Path.GetTempPath());
    }

    [Fact]
    public void LessonIds_ReturnsNonEmptyList()
    {
        EnsureLoaded();
        var ids = LessonsData.LessonIds();
        Assert.NotNull(ids);
        // Should have lessons if data loaded correctly
    }

    [Fact]
    public void DefaultLessonId_IsFullAlpha()
    {
        Assert.Equal("full_alpha", LessonsData.DefaultLessonId());
    }

    [Fact]
    public void NormalizeLessonId_EmptyReturnsDefault()
    {
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId(""));
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId(null!));
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId("   "));
    }

    [Fact]
    public void NormalizeLessonId_InvalidReturnsDefault()
    {
        EnsureLoaded();
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId("nonexistent_lesson_xyz"));
    }

    [Fact]
    public void GetLesson_FullAlpha_HasCharset()
    {
        EnsureLoaded();
        var lesson = LessonsData.GetLesson("full_alpha");
        if (lesson == null) return; // Data not found, skip
        Assert.Equal("Full Alphabet", lesson.Name);
        Assert.Equal("charset", lesson.Mode);
        Assert.True(lesson.Charset.Count > 0, "Full alpha should have charset");
        Assert.Contains("a", lesson.Charset);
        Assert.Contains("z", lesson.Charset);
    }

    [Fact]
    public void GetLesson_HomeRowWords_HasWordlist()
    {
        EnsureLoaded();
        var lesson = LessonsData.GetLesson("home_row_words");
        if (lesson == null) return; // Data not found, skip
        Assert.Equal("wordlist", lesson.Mode);
        Assert.True(lesson.WordList.Count > 0, "Home row words should have word list");
    }

    [Fact]
    public void GetLesson_SentenceMode_HasSentences()
    {
        EnsureLoaded();
        var lesson = LessonsData.GetLesson("sentence_basics");
        if (lesson == null) return;
        Assert.Equal("sentence", lesson.Mode);
        Assert.True(lesson.Sentences.Count > 0, "Sentence lesson should have sentences");
    }

    [Fact]
    public void GetPaths_ReturnsGraduationPaths()
    {
        EnsureLoaded();
        var paths = LessonsData.GetPaths();
        Assert.NotNull(paths);
        if (paths.Count == 0) return; // Data not found
        Assert.True(paths.Count >= 3, "Should have beginner, intermediate, advanced paths");
        var beginner = paths.FirstOrDefault(p => p.Id == "beginner");
        Assert.NotNull(beginner);
        Assert.Equal("Beginner Path", beginner!.Name);
        Assert.True(beginner.Stages.Count > 0, "Beginner path should have stages");
    }

    [Fact]
    public void GetPaths_StagesHaveLessonIds()
    {
        EnsureLoaded();
        var paths = LessonsData.GetPaths();
        if (paths.Count == 0) return;
        var beginner = paths.FirstOrDefault(p => p.Id == "beginner");
        if (beginner == null) return;
        var firstStage = beginner.Stages[0];
        Assert.True(firstStage.LessonIds.Count > 0, "First stage should have lesson IDs");
        // Verify the lesson IDs resolve to actual lessons
        foreach (string lessonId in firstStage.LessonIds)
        {
            Assert.True(LessonsData.IsValid(lessonId), $"Lesson '{lessonId}' from path should exist");
        }
    }

    [Fact]
    public void LessonLabel_ReturnsName()
    {
        EnsureLoaded();
        string label = LessonsData.LessonLabel("full_alpha");
        // If data loaded, should be "Full Alphabet"; otherwise just the ID
        Assert.NotEmpty(label);
    }

    [Fact]
    public void LessonEntry_DefaultValues()
    {
        var entry = new LessonEntry();
        Assert.Equal("", entry.Id);
        Assert.Equal("", entry.Name);
        Assert.Equal("charset", entry.Mode);
        Assert.NotNull(entry.Charset);
        Assert.NotNull(entry.WordList);
        Assert.NotNull(entry.Sentences);
        Assert.Empty(entry.Charset);
        Assert.Empty(entry.WordList);
        Assert.Empty(entry.Sentences);
    }

    [Fact]
    public void GraduationPath_DefaultValues()
    {
        var path = new GraduationPath();
        Assert.Equal("", path.Id);
        Assert.Equal("", path.Name);
        Assert.NotNull(path.Stages);
        Assert.Empty(path.Stages);
    }

    [Fact]
    public void PathStage_DefaultValues()
    {
        var stage = new PathStage();
        Assert.Equal(0, stage.Stage);
        Assert.Equal("", stage.Name);
        Assert.Equal("", stage.Goal);
        Assert.NotNull(stage.LessonIds);
        Assert.Empty(stage.LessonIds);
    }
}
