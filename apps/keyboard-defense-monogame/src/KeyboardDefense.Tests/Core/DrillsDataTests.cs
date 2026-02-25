using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace KeyboardDefense.Tests.Core;

public class DrillsDataTests
{
    private static readonly HashSet<string> ValidModes = new(StringComparer.Ordinal)
    {
        "lesson",
        "targets",
        "intermission",
    };

    private static readonly HashSet<string> ValidDifficultyLevels = new(StringComparer.OrdinalIgnoreCase)
    {
        "story",
        "adventure",
        "champion",
        "nightmare",
        "zen",
        "easy",
        "medium",
        "hard",
        "expert",
        "legendary",
    };

    [Fact]
    public void DrillsJson_AllTemplatesParseSuccessfully()
    {
        var drills = LoadDrillsData();

        Assert.True(drills.Version > 0, "Expected drills.json to have a positive version.");
        Assert.NotEmpty(drills.Templates);
    }

    [Fact]
    public void DrillsJson_TemplatesHaveUniqueNonEmptyIds()
    {
        var templates = LoadDrillsData().Templates;

        foreach (var template in templates)
        {
            Assert.False(string.IsNullOrWhiteSpace(template.Id));
        }

        int distinctIds = templates
            .Select(template => template.Id)
            .Distinct(StringComparer.Ordinal)
            .Count();
        Assert.Equal(templates.Count, distinctIds);
    }

    [Fact]
    public void DrillsJson_TemplatesHaveNonEmptyNames()
    {
        var templates = LoadDrillsData().Templates;

        foreach (var template in templates)
        {
            Assert.False(string.IsNullOrWhiteSpace(template.Label));
        }
    }

    [Fact]
    public void DrillsJson_TemplatesHaveNonEmptyContent()
    {
        var templates = LoadDrillsData().Templates;

        foreach (var template in templates)
        {
            Assert.NotEmpty(template.Plan);
        }
    }

    [Fact]
    public void DrillsJson_AllPlanStepsHaveNonEmptyNameAndMode()
    {
        var steps = LoadDrillsData().Templates.SelectMany(template => template.Plan).ToList();
        Assert.NotEmpty(steps);

        foreach (var step in steps)
        {
            Assert.False(string.IsNullOrWhiteSpace(step.Label));
            Assert.False(string.IsNullOrWhiteSpace(step.Mode));
        }
    }

    [Fact]
    public void DrillsJson_AllPlanStepModesAreValid()
    {
        var modes = LoadDrillsData().Templates
            .SelectMany(template => template.Plan)
            .Select(step => step.Mode)
            .ToList();

        Assert.NotEmpty(modes);
        foreach (string mode in modes)
        {
            Assert.Contains(mode, ValidModes);
        }
    }

    [Theory]
    [InlineData("lesson")]
    [InlineData("targets")]
    [InlineData("intermission")]
    public void DrillsJson_ContainsExpectedPlanModes(string expectedMode)
    {
        var modes = LoadDrillsData().Templates
            .SelectMany(template => template.Plan)
            .Select(step => step.Mode)
            .ToHashSet(StringComparer.Ordinal);

        Assert.Contains(expectedMode, modes);
    }

    [Fact]
    public void DrillsJson_LessonStepsHaveValidContent()
    {
        var lessonSteps = LoadDrillsData().Templates
            .SelectMany(template => template.Plan)
            .Where(step => step.Mode == "lesson")
            .ToList();

        Assert.NotEmpty(lessonSteps);
        foreach (var step in lessonSteps)
        {
            Assert.True(step.WordCount.HasValue && step.WordCount.Value > 0);
            Assert.True(step.Shuffle.HasValue, "Lesson step is missing 'shuffle'.");
            Assert.False(string.IsNullOrWhiteSpace(step.Hint));
        }
    }

    [Fact]
    public void DrillsJson_IntermissionStepsHaveValidContent()
    {
        var intermissionSteps = LoadDrillsData().Templates
            .SelectMany(template => template.Plan)
            .Where(step => step.Mode == "intermission")
            .ToList();

        Assert.NotEmpty(intermissionSteps);
        foreach (var step in intermissionSteps)
        {
            Assert.True(step.Duration.HasValue && step.Duration.Value > 0);
            Assert.False(string.IsNullOrWhiteSpace(step.Message));
        }
    }

    [Fact]
    public void DrillsJson_TargetStepsHaveValidContentAndTypingCharacters()
    {
        var targetSteps = LoadDrillsData().Templates
            .SelectMany(template => template.Plan)
            .Where(step => step.Mode == "targets")
            .ToList();

        Assert.NotEmpty(targetSteps);
        foreach (var step in targetSteps)
        {
            Assert.NotEmpty(step.Targets);
            Assert.False(string.IsNullOrWhiteSpace(step.Hint));

            foreach (string target in step.Targets)
            {
                Assert.False(string.IsNullOrWhiteSpace(target));
                foreach (char c in target)
                {
                    Assert.True(IsValidTypingCharacter(c), $"Invalid typing character '{c}' in target '{target}'.");
                }
            }
        }
    }

    [Fact]
    public void DrillsJson_DifficultyLevelsAreValidWhenSpecified()
    {
        var templates = LoadDrillsData().Templates;

        foreach (var template in templates)
        {
            if (string.IsNullOrWhiteSpace(template.Difficulty))
            {
                continue;
            }

            Assert.True(
                ValidDifficultyLevels.Contains(template.Difficulty),
                $"Template '{template.Id}' uses invalid difficulty '{template.Difficulty}'.");
        }
    }

    private static bool IsValidTypingCharacter(char c)
    {
        return c is >= ' ' and <= '~';
    }

    private static DrillsDataFile LoadDrillsData()
    {
        string path = ResolveDrillsPath();
        using var document = JsonDocument.Parse(File.ReadAllText(path));
        JsonElement root = document.RootElement;

        int version = GetRequiredInt(root, "version");
        JsonElement templatesNode = GetRequiredProperty(root, "templates", JsonValueKind.Array);

        var templates = new List<DrillTemplate>();
        foreach (JsonElement templateNode in templatesNode.EnumerateArray())
        {
            string id = GetRequiredString(templateNode, "id");
            string label = GetRequiredString(templateNode, "label");
            string? difficulty = GetOptionalString(templateNode, "difficulty");

            JsonElement planNode = GetRequiredProperty(templateNode, "plan", JsonValueKind.Array);
            var plan = new List<DrillStep>();
            foreach (JsonElement stepNode in planNode.EnumerateArray())
            {
                plan.Add(new DrillStep
                {
                    Mode = GetRequiredString(stepNode, "mode"),
                    Label = GetRequiredString(stepNode, "label"),
                    Hint = GetOptionalString(stepNode, "hint"),
                    Message = GetOptionalString(stepNode, "message"),
                    WordCount = GetOptionalInt(stepNode, "word_count"),
                    Shuffle = GetOptionalBool(stepNode, "shuffle"),
                    Duration = GetOptionalDouble(stepNode, "duration"),
                    Targets = GetOptionalStringArray(stepNode, "targets"),
                });
            }

            templates.Add(new DrillTemplate
            {
                Id = id,
                Label = label,
                Difficulty = difficulty,
                Plan = plan,
            });
        }

        return new DrillsDataFile
        {
            Version = version,
            Templates = templates,
        };
    }

    private static JsonElement GetRequiredProperty(JsonElement node, string propertyName, JsonValueKind expectedKind)
    {
        Assert.True(node.ValueKind == JsonValueKind.Object, "Expected a JSON object.");
        Assert.True(node.TryGetProperty(propertyName, out JsonElement value), $"Missing required property '{propertyName}'.");
        Assert.Equal(expectedKind, value.ValueKind);
        return value;
    }

    private static string GetRequiredString(JsonElement node, string propertyName)
    {
        JsonElement value = GetRequiredProperty(node, propertyName, JsonValueKind.String);
        string? content = value.GetString();
        Assert.False(string.IsNullOrWhiteSpace(content), $"Property '{propertyName}' must be a non-empty string.");
        return content!;
    }

    private static string? GetOptionalString(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return null;
        }

        Assert.Equal(JsonValueKind.String, value.ValueKind);
        return value.GetString();
    }

    private static int GetRequiredInt(JsonElement node, string propertyName)
    {
        Assert.True(node.TryGetProperty(propertyName, out JsonElement value), $"Missing required property '{propertyName}'.");
        Assert.Equal(JsonValueKind.Number, value.ValueKind);
        Assert.True(value.TryGetInt32(out int result), $"Property '{propertyName}' must be an Int32.");
        return result;
    }

    private static int? GetOptionalInt(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return null;
        }

        Assert.Equal(JsonValueKind.Number, value.ValueKind);
        Assert.True(value.TryGetInt32(out int result), $"Property '{propertyName}' must be an Int32.");
        return result;
    }

    private static bool? GetOptionalBool(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return null;
        }

        Assert.True(value.ValueKind is JsonValueKind.True or JsonValueKind.False, $"Property '{propertyName}' must be a Boolean.");
        return value.GetBoolean();
    }

    private static double? GetOptionalDouble(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return null;
        }

        Assert.Equal(JsonValueKind.Number, value.ValueKind);
        return value.GetDouble();
    }

    private static IReadOnlyList<string> GetOptionalStringArray(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return Array.Empty<string>();
        }

        Assert.Equal(JsonValueKind.Array, value.ValueKind);
        var result = new List<string>();
        foreach (JsonElement item in value.EnumerateArray())
        {
            Assert.Equal(JsonValueKind.String, item.ValueKind);
            string? text = item.GetString();
            Assert.False(string.IsNullOrWhiteSpace(text), $"Property '{propertyName}' contains an empty string item.");
            result.Add(text!);
        }

        return result;
    }

    private static string ResolveDrillsPath()
    {
        string? directory = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrEmpty(directory); i++)
        {
            string candidate = Path.Combine(directory, "data", "drills.json");
            if (File.Exists(candidate))
            {
                return candidate;
            }

            directory = Directory.GetParent(directory)?.FullName;
        }

        throw new DirectoryNotFoundException("Unable to locate data/drills.json from test base directory.");
    }

    private sealed class DrillsDataFile
    {
        public required int Version { get; init; }
        public required List<DrillTemplate> Templates { get; init; }
    }

    private sealed class DrillTemplate
    {
        public required string Id { get; init; }
        public required string Label { get; init; }
        public string? Difficulty { get; init; }
        public required List<DrillStep> Plan { get; init; }
    }

    private sealed class DrillStep
    {
        public required string Mode { get; init; }
        public required string Label { get; init; }
        public string? Hint { get; init; }
        public string? Message { get; init; }
        public int? WordCount { get; init; }
        public bool? Shuffle { get; init; }
        public double? Duration { get; init; }
        public IReadOnlyList<string> Targets { get; init; } = Array.Empty<string>();
    }
}
