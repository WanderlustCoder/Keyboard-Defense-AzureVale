using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class LessonsDataTests
{
    [Fact]
    public void LoadData_LoadsAllLessonDefinitionsFromJson()
    {
        var expectedLessons = LoadExpectedLessonsAndEnsureLoaded();

        var lessonIds = LessonsData.LessonIds();

        Assert.NotEmpty(expectedLessons);
        Assert.Equal(expectedLessons.Count, lessonIds.Count);
        Assert.Equal(lessonIds.Count, lessonIds.Distinct(StringComparer.Ordinal).Count());

        var expectedIds = expectedLessons.Select(l => l.Id).ToHashSet(StringComparer.Ordinal);
        var actualIds = lessonIds.ToHashSet(StringComparer.Ordinal);
        Assert.True(expectedIds.SetEquals(actualIds), "Loaded lesson IDs do not match lessons.json.");
    }

    [Fact]
    public void LoadData_LoadsGraduationPathsFromJson()
    {
        var (_, expectedPaths) = LoadExpectedLessonsAndPathsAndEnsureLoaded();
        var actualPaths = LessonsData.GetPaths();

        Assert.Equal(expectedPaths.Count, actualPaths.Count);
        var actualById = actualPaths.ToDictionary(path => path.Id, StringComparer.Ordinal);

        foreach (var expectedPath in expectedPaths)
        {
            Assert.True(actualById.TryGetValue(expectedPath.Id, out var actualPath), $"Missing path '{expectedPath.Id}'.");
            Assert.Equal(expectedPath.Name, actualPath!.Name);
            Assert.Equal(expectedPath.Description, actualPath.Description);
            Assert.Equal(expectedPath.Stages.Count, actualPath.Stages.Count);

            for (int i = 0; i < expectedPath.Stages.Count; i++)
            {
                var expectedStage = expectedPath.Stages[i];
                var actualStage = actualPath.Stages[i];

                Assert.Equal(expectedStage.Stage, actualStage.Stage);
                Assert.Equal(expectedStage.Name, actualStage.Name);
                Assert.Equal(expectedStage.Goal, actualStage.Goal);
                Assert.Equal(expectedStage.LessonIds, actualStage.LessonIds);
            }
        }
    }

    [Fact]
    public void DefaultLessonId_AndNormalization_UseFullAlphaFallback()
    {
        LoadExpectedLessonsAndEnsureLoaded();

        Assert.Equal("full_alpha", LessonsData.DefaultLessonId());
        Assert.True(LessonsData.IsValid("full_alpha"));
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId(" FULL_ALPHA "));
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId("unknown_lesson"));
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId("   "));
        Assert.Equal("full_alpha", LessonsData.NormalizeLessonId(null!));
    }

    [Fact]
    public void GetLesson_SpecificLookups_MatchExpectedJsonContent()
    {
        var expectedById = LoadExpectedLessonsAndEnsureLoaded()
            .ToDictionary(lesson => lesson.Id, StringComparer.Ordinal);

        AssertLessonMatchesExpected("full_alpha", expectedById);
        AssertLessonMatchesExpected("home_row_words", expectedById);
        AssertLessonMatchesExpected("sentence_coding", expectedById);

        var fullAlpha = RequireLesson("full_alpha");
        Assert.Equal("a", fullAlpha.Charset.First());
        Assert.Equal("z", fullAlpha.Charset.Last());

        var wordLesson = RequireLesson("home_row_words");
        Assert.Contains("flash", wordLesson.WordList);
        Assert.Contains("salads", wordLesson.WordList);

        var sentenceLesson = RequireLesson("sentence_coding");
        Assert.Contains("The algorithm has a time complexity of O(n log n).", sentenceLesson.Sentences);
        Assert.Contains("Documentation helps other developers understand your code.", sentenceLesson.Sentences);
    }

    [Fact]
    public void ProjectLessons_EachLessonHasModeSpecificNonEmptyContent()
    {
        var expectedLessons = LoadExpectedLessonsAndEnsureLoaded();
        Assert.NotEmpty(expectedLessons);

        foreach (var lesson in LessonsData.LessonIds().Select(RequireLesson))
        {
            Assert.False(string.IsNullOrWhiteSpace(lesson.Id));
            Assert.False(string.IsNullOrWhiteSpace(lesson.Name));
            Assert.False(string.IsNullOrWhiteSpace(lesson.Description));
            Assert.False(string.IsNullOrWhiteSpace(lesson.Mode));

            switch (lesson.Mode)
            {
                case "charset":
                    Assert.NotEmpty(lesson.Charset);
                    Assert.Empty(lesson.WordList);
                    Assert.Empty(lesson.Sentences);
                    break;
                case "wordlist":
                    Assert.NotEmpty(lesson.WordList);
                    Assert.Empty(lesson.Charset);
                    Assert.Empty(lesson.Sentences);
                    break;
                case "sentence":
                    Assert.NotEmpty(lesson.Sentences);
                    Assert.Empty(lesson.Charset);
                    Assert.Empty(lesson.WordList);
                    break;
                default:
                    Assert.Fail($"Unsupported lesson mode '{lesson.Mode}' for lesson '{lesson.Id}'.");
                    break;
            }
        }
    }

    [Fact]
    public void GetPaths_StagesAreSequential_AndLessonReferencesExist()
    {
        var (_, expectedPaths) = LoadExpectedLessonsAndPathsAndEnsureLoaded();
        var validLessonIds = LessonsData.LessonIds().ToHashSet(StringComparer.Ordinal);
        int expectedReferences = expectedPaths.Sum(path => path.Stages.Sum(stage => stage.LessonIds.Length));

        int actualReferences = 0;
        foreach (var path in LessonsData.GetPaths())
        {
            for (int i = 0; i < path.Stages.Count; i++)
            {
                var stage = path.Stages[i];
                Assert.Equal(i + 1, stage.Stage);
                Assert.False(string.IsNullOrWhiteSpace(stage.Name));
                Assert.False(string.IsNullOrWhiteSpace(stage.Goal));
                Assert.NotEmpty(stage.LessonIds);

                foreach (var lessonId in stage.LessonIds)
                {
                    actualReferences++;
                    Assert.Contains(lessonId, validLessonIds);
                }
            }
        }

        Assert.Equal(expectedReferences, actualReferences);
    }

    [Fact]
    public void ProjectLessons_DifficultyAndCategoryMatchJsonOrDefaultValues()
    {
        var expectedLessons = LoadExpectedLessonsAndEnsureLoaded();

        foreach (var expected in expectedLessons)
        {
            var actual = RequireLesson(expected.Id);
            Assert.Equal(expected.Difficulty, actual.Difficulty);
            Assert.Equal(expected.Category, actual.Category);
        }
    }

    [Fact]
    public void LoadData_CustomJson_PreservesDifficultyOrderingWithinPath()
    {
        LoadFromTemporaryJson(
            @"{
  ""graduation_paths"": {
    ""custom"": {
      ""name"": ""Custom Path"",
      ""description"": ""Custom progression"",
      ""stages"": [
        {
          ""stage"": 1,
          ""name"": ""Start"",
          ""goal"": ""Learn from easy to hard"",
          ""lessons"": [""easy_keys"", ""medium_words"", ""hard_sentence""]
        }
      ]
    }
  },
  ""lessons"": [
    { ""id"": ""easy_keys"", ""name"": ""Easy Keys"", ""description"": ""Easy mode"", ""mode"": ""charset"", ""charset"": ""asdf"", ""difficulty"": 1, ""category"": ""beginner"" },
    { ""id"": ""medium_words"", ""name"": ""Medium Words"", ""description"": ""Medium mode"", ""mode"": ""wordlist"", ""wordlist"": [""as"", ""sad"", ""dad""], ""difficulty"": 2, ""category"": ""beginner"" },
    { ""id"": ""hard_sentence"", ""name"": ""Hard Sentence"", ""description"": ""Hard mode"", ""mode"": ""sentence"", ""sentences"": [""Type this now.""], ""difficulty"": 3, ""category"": ""advanced"" }
  ]
}",
            () =>
            {
                var path = Assert.Single(LessonsData.GetPaths(), p => p.Id == "custom");
                var stage = Assert.Single(path.Stages);
                var orderedDifficulties = stage.LessonIds
                    .Select(lessonId => RequireLesson(lessonId).Difficulty)
                    .ToArray();

                Assert.Equal(new[] { 1, 2, 3 }, orderedDifficulties);
                for (int i = 1; i < orderedDifficulties.Length; i++)
                {
                    Assert.True(
                        orderedDifficulties[i - 1] <= orderedDifficulties[i],
                        $"Difficulty should be non-decreasing but found {orderedDifficulties[i - 1]} before {orderedDifficulties[i]}.");
                }
            });
    }

    [Fact]
    public void LoadData_CustomJson_SupportsCategoryFiltering()
    {
        LoadFromTemporaryJson(
            @"{
  ""lessons"": [
    { ""id"": ""a"", ""name"": ""A"", ""description"": ""A desc"", ""mode"": ""charset"", ""charset"": ""a"", ""difficulty"": 1, ""category"": ""left"" },
    { ""id"": ""b"", ""name"": ""B"", ""description"": ""B desc"", ""mode"": ""charset"", ""charset"": ""b"", ""difficulty"": 2, ""category"": ""left"" },
    { ""id"": ""c"", ""name"": ""C"", ""description"": ""C desc"", ""mode"": ""charset"", ""charset"": ""c"", ""difficulty"": 3, ""category"": ""right"" }
  ]
}",
            () =>
            {
                var lessons = LessonsData.LessonIds().Select(RequireLesson).ToList();
                var left = lessons.Where(lesson => lesson.Category == "left").Select(lesson => lesson.Id).OrderBy(id => id, StringComparer.Ordinal).ToArray();
                var right = lessons.Where(lesson => lesson.Category == "right").Select(lesson => lesson.Id).OrderBy(id => id, StringComparer.Ordinal).ToArray();
                var missing = lessons.Where(lesson => lesson.Category == "missing").Select(lesson => lesson.Id).ToArray();

                Assert.Equal(new[] { "a", "b" }, left);
                Assert.Equal(new[] { "c" }, right);
                Assert.Empty(missing);
            });
    }

    [Fact]
    public void LoadData_CustomJson_UsesWordPoolWhenWordListIsMissing()
    {
        LoadFromTemporaryJson(
            @"{
  ""lessons"": [
    { ""id"": ""pool_only"", ""name"": ""Pool Only"", ""description"": ""Uses word_pool fallback"", ""mode"": ""wordlist"", ""word_pool"": [""alpha"", ""beta"", ""gamma""] }
  ]
}",
            () =>
            {
                var lesson = RequireLesson("pool_only");
                Assert.Equal("wordlist", lesson.Mode);
                Assert.Equal(new[] { "alpha", "beta", "gamma" }, lesson.WordList);
            });
    }

    [Fact]
    public void LessonLabel_ReturnsNameForKnownId_AndFallsBackToId()
    {
        LoadExpectedLessonsAndEnsureLoaded();

        Assert.Equal("Full Alphabet", LessonsData.LessonLabel("full_alpha"));
        Assert.Equal("missing_lesson", LessonsData.LessonLabel("missing_lesson"));
    }

    private static LessonEntry RequireLesson(string lessonId)
    {
        var lesson = LessonsData.GetLesson(lessonId);
        Assert.NotNull(lesson);
        return lesson!;
    }

    private static void AssertLessonMatchesExpected(
        string lessonId,
        IReadOnlyDictionary<string, ExpectedLesson> expectedById)
    {
        Assert.True(expectedById.TryGetValue(lessonId, out var expected), $"Missing expected lesson '{lessonId}'.");
        var actual = RequireLesson(lessonId);

        Assert.Equal(expected!.Id, actual.Id);
        Assert.Equal(expected.Name, actual.Name);
        Assert.Equal(expected.Description, actual.Description);
        Assert.Equal(expected.Mode, actual.Mode);
        Assert.Equal(expected.Charset, actual.Charset);
        Assert.Equal(expected.WordList, actual.WordList);
        Assert.Equal(expected.Sentences, actual.Sentences);
        Assert.Equal(expected.Difficulty, actual.Difficulty);
        Assert.Equal(expected.Category, actual.Category);
    }

    private static List<ExpectedLesson> LoadExpectedLessonsAndEnsureLoaded()
    {
        var (lessons, _) = LoadExpectedLessonsAndPathsAndEnsureLoaded();
        return lessons;
    }

    private static (List<ExpectedLesson> Lessons, List<ExpectedPath> Paths) LoadExpectedLessonsAndPathsAndEnsureLoaded()
    {
        string dataDir = ResolveDataDirectory();
        LessonsData.LoadData(dataDir);
        return ReadExpectedLessonsAndPaths(dataDir);
    }

    private static (List<ExpectedLesson> Lessons, List<ExpectedPath> Paths) ReadExpectedLessonsAndPaths(string dataDir)
    {
        string path = Path.Combine(dataDir, "lessons.json");
        using var document = JsonDocument.Parse(File.ReadAllText(path));
        var root = document.RootElement;

        var lessons = new List<ExpectedLesson>();
        if (root.TryGetProperty("lessons", out var lessonsNode) && lessonsNode.ValueKind == JsonValueKind.Array)
        {
            foreach (var lessonNode in lessonsNode.EnumerateArray())
            {
                string id = GetStringOrDefault(lessonNode, "id", string.Empty);
                if (string.IsNullOrWhiteSpace(id))
                {
                    continue;
                }

                string mode = GetStringOrDefault(lessonNode, "mode", "charset");
                string[] wordList = lessonNode.TryGetProperty("wordlist", out var wordListNode)
                    ? ReadStringArray(wordListNode)
                    : lessonNode.TryGetProperty("word_pool", out var wordPoolNode)
                        ? ReadStringArray(wordPoolNode)
                        : Array.Empty<string>();

                lessons.Add(new ExpectedLesson
                {
                    Id = id,
                    Name = GetStringOrDefault(lessonNode, "name", id),
                    Description = GetStringOrDefault(lessonNode, "description", string.Empty),
                    Mode = mode,
                    Charset = ReadCharset(lessonNode),
                    WordList = wordList,
                    Sentences = lessonNode.TryGetProperty("sentences", out var sentencesNode)
                        ? ReadStringArray(sentencesNode)
                        : Array.Empty<string>(),
                    Difficulty = GetIntOrDefault(lessonNode, "difficulty", 0),
                    Category = GetStringOrDefault(lessonNode, "category", string.Empty),
                });
            }
        }

        var paths = new List<ExpectedPath>();
        if (root.TryGetProperty("graduation_paths", out var pathsNode) && pathsNode.ValueKind == JsonValueKind.Object)
        {
            foreach (var pathProp in pathsNode.EnumerateObject())
            {
                var pathNode = pathProp.Value;
                var stages = new List<ExpectedStage>();

                if (pathNode.TryGetProperty("stages", out var stagesNode) && stagesNode.ValueKind == JsonValueKind.Array)
                {
                    foreach (var stageNode in stagesNode.EnumerateArray())
                    {
                        stages.Add(new ExpectedStage
                        {
                            Stage = GetIntOrDefault(stageNode, "stage", 0),
                            Name = GetStringOrDefault(stageNode, "name", string.Empty),
                            Goal = GetStringOrDefault(stageNode, "goal", string.Empty),
                            LessonIds = stageNode.TryGetProperty("lessons", out var lessonsByStageNode)
                                ? ReadStringArray(lessonsByStageNode)
                                : Array.Empty<string>(),
                        });
                    }
                }

                paths.Add(new ExpectedPath
                {
                    Id = pathProp.Name,
                    Name = GetStringOrDefault(pathNode, "name", pathProp.Name),
                    Description = GetStringOrDefault(pathNode, "description", string.Empty),
                    Stages = stages,
                });
            }
        }

        return (lessons, paths);
    }

    private static string[] ReadCharset(JsonElement lessonNode)
    {
        if (!lessonNode.TryGetProperty("charset", out var charsetNode) || charsetNode.ValueKind != JsonValueKind.String)
        {
            return Array.Empty<string>();
        }

        var charsetRaw = charsetNode.GetString();
        return charsetRaw == null
            ? Array.Empty<string>()
            : charsetRaw.Select(c => c.ToString()).ToArray();
    }

    private static string[] ReadStringArray(JsonElement node)
    {
        if (node.ValueKind != JsonValueKind.Array)
        {
            return Array.Empty<string>();
        }

        return node.EnumerateArray()
            .Where(item => item.ValueKind == JsonValueKind.String)
            .Select(item => item.GetString())
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => value!)
            .ToArray();
    }

    private static string GetStringOrDefault(JsonElement node, string propertyName, string defaultValue)
    {
        if (!node.TryGetProperty(propertyName, out var value) || value.ValueKind != JsonValueKind.String)
        {
            return defaultValue;
        }

        return value.GetString() ?? defaultValue;
    }

    private static int GetIntOrDefault(JsonElement node, string propertyName, int defaultValue)
    {
        if (!node.TryGetProperty(propertyName, out var value) || value.ValueKind != JsonValueKind.Number)
        {
            return defaultValue;
        }

        return value.TryGetInt32(out int result) ? result : defaultValue;
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "lessons.json")))
            {
                return candidate;
            }

            dir = Directory.GetParent(dir)?.FullName;
        }

        throw new DirectoryNotFoundException("Unable to locate data/lessons.json from test base directory.");
    }

    private static void LoadFromTemporaryJson(string lessonsJson, Action assertions)
    {
        string tempDir = Path.Combine(Path.GetTempPath(), "keyboard-defense-lessons-tests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        try
        {
            File.WriteAllText(Path.Combine(tempDir, "lessons.json"), lessonsJson);
            LessonsData.LoadData(tempDir);
            assertions();
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, recursive: true);
            }
        }
    }

    private sealed class ExpectedLesson
    {
        public required string Id { get; init; }
        public required string Name { get; init; }
        public required string Description { get; init; }
        public required string Mode { get; init; }
        public required string[] Charset { get; init; }
        public required string[] WordList { get; init; }
        public required string[] Sentences { get; init; }
        public required int Difficulty { get; init; }
        public required string Category { get; init; }
    }

    private sealed class ExpectedPath
    {
        public required string Id { get; init; }
        public required string Name { get; init; }
        public required string Description { get; init; }
        public required List<ExpectedStage> Stages { get; init; }
    }

    private sealed class ExpectedStage
    {
        public required int Stage { get; init; }
        public required string Name { get; init; }
        public required string Goal { get; init; }
        public required string[] LessonIds { get; init; }
    }
}

[CollectionDefinition("StaticData", DisableParallelization = true)]
public sealed class StaticDataCollection
{
}
