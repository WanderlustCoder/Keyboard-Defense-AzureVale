using System;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace KeyboardDefense.Tests.Core;

public class StoryDataTests
{
    [Fact]
    public void StoryJson_CanParse_AllTopLevelEntriesAreNonNull()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement root = doc.RootElement;

        Assert.Equal(JsonValueKind.Object, root.ValueKind);

        int propertyCount = 0;
        foreach (JsonProperty property in root.EnumerateObject())
        {
            propertyCount++;
            Assert.NotEqual(JsonValueKind.Null, property.Value.ValueKind);

            using JsonDocument reparsed = JsonDocument.Parse(property.Value.GetRawText());
            Assert.NotEqual(JsonValueKind.Undefined, reparsed.RootElement.ValueKind);
        }

        Assert.True(propertyCount >= 6, "story.json should include at least six top-level entries.");
    }

    [Fact]
    public void StoryJson_ContainsRequiredTopLevelSections()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement root = doc.RootElement;

        Assert.True(root.TryGetProperty("version", out JsonElement version), "Missing top-level 'version'.");
        Assert.Equal(JsonValueKind.Number, version.ValueKind);
        Assert.True(version.GetInt32() > 0, "Version must be positive.");

        AssertNonEmptyString(root, "title", "story");
        AssertNonEmptyString(root, "subtitle", "story");

        Assert.True(root.TryGetProperty("acts", out JsonElement acts), "Missing top-level 'acts'.");
        Assert.Equal(JsonValueKind.Array, acts.ValueKind);

        Assert.True(root.TryGetProperty("dialogue", out JsonElement dialogue), "Missing top-level 'dialogue'.");
        Assert.Equal(JsonValueKind.Object, dialogue.ValueKind);

        Assert.True(root.TryGetProperty("lore", out JsonElement lore), "Missing top-level 'lore'.");
        Assert.Equal(JsonValueKind.Object, lore.ValueKind);
    }

    [Fact]
    public void StoryJson_AllChapterAndDialogueEntriesParseAsObjects()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement root = doc.RootElement;

        JsonElement acts = root.GetProperty("acts");
        foreach (JsonElement chapter in acts.EnumerateArray())
        {
            using JsonDocument parsedChapter = JsonDocument.Parse(chapter.GetRawText());
            Assert.Equal(JsonValueKind.Object, parsedChapter.RootElement.ValueKind);
        }

        JsonElement dialogue = root.GetProperty("dialogue");
        foreach (JsonProperty entry in dialogue.EnumerateObject())
        {
            using JsonDocument parsedDialogueEntry = JsonDocument.Parse(entry.Value.GetRawText());
            Assert.Equal(JsonValueKind.Object, parsedDialogueEntry.RootElement.ValueKind);
        }
    }

    [Theory]
    [InlineData("id")]
    [InlineData("name")]
    [InlineData("theme")]
    [InlineData("intro_text")]
    [InlineData("completion_text")]
    [InlineData("reward")]
    public void Chapters_RequiredStringFields_ArePresentAndNonEmpty(string fieldName)
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement acts = doc.RootElement.GetProperty("acts");

        int index = 0;
        foreach (JsonElement chapter in acts.EnumerateArray())
        {
            AssertNonEmptyString(chapter, fieldName, $"acts[{index}]");
            index++;
        }
    }

    [Theory]
    [InlineData("mentor", "name")]
    [InlineData("mentor", "portrait")]
    [InlineData("mentor", "title")]
    [InlineData("boss", "kind")]
    [InlineData("boss", "name")]
    [InlineData("boss", "intro")]
    [InlineData("boss", "taunt")]
    [InlineData("boss", "defeat")]
    [InlineData("boss", "lore")]
    public void Chapters_RequiredNestedStringFields_ArePresentAndNonEmpty(string objectName, string fieldName)
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement acts = doc.RootElement.GetProperty("acts");

        int index = 0;
        foreach (JsonElement chapter in acts.EnumerateArray())
        {
            Assert.True(
                chapter.TryGetProperty(objectName, out JsonElement nested) && nested.ValueKind == JsonValueKind.Object,
                $"acts[{index}] is missing required object '{objectName}'.");

            AssertNonEmptyString(nested, fieldName, $"acts[{index}].{objectName}");
            index++;
        }
    }

    [Fact]
    public void Chapters_DaysAndLessons_AreWellFormed()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement acts = doc.RootElement.GetProperty("acts");

        int index = 0;
        foreach (JsonElement chapter in acts.EnumerateArray())
        {
            Assert.True(chapter.TryGetProperty("days", out JsonElement days), $"acts[{index}] missing 'days'.");
            Assert.Equal(JsonValueKind.Array, days.ValueKind);
            JsonElement[] dayRange = days.EnumerateArray().ToArray();
            Assert.Equal(2, dayRange.Length);
            int dayStart = ReadRequiredInt(dayRange[0], $"acts[{index}].days[0]");
            int dayEnd = ReadRequiredInt(dayRange[1], $"acts[{index}].days[1]");
            Assert.True(dayStart > 0, $"acts[{index}].days[0] must be positive.");
            Assert.True(dayEnd >= dayStart, $"acts[{index}] has invalid day range {dayStart}-{dayEnd}.");

            Assert.True(chapter.TryGetProperty("lessons", out JsonElement lessons), $"acts[{index}] missing 'lessons'.");
            Assert.Equal(JsonValueKind.Array, lessons.ValueKind);
            string[] lessonIds = lessons.EnumerateArray()
                .Select((lesson, lessonIndex) => ReadRequiredString(lesson, $"acts[{index}].lessons[{lessonIndex}]"))
                .ToArray();

            Assert.NotEmpty(lessonIds);
            Assert.Equal(lessonIds.Length, lessonIds.Distinct(StringComparer.Ordinal).Count());
            index++;
        }
    }

    [Fact]
    public void Chapters_AreSequentiallyOrderedByActId()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement acts = doc.RootElement.GetProperty("acts");
        JsonElement[] chapters = acts.EnumerateArray().ToArray();

        Assert.NotEmpty(chapters);

        for (int i = 0; i < chapters.Length; i++)
        {
            string actualId = ReadRequiredString(chapters[i].GetProperty("id"), $"acts[{i}].id");
            string expectedId = $"act{i + 1}";
            Assert.Equal(expectedId, actualId);
        }
    }

    [Fact]
    public void Chapters_HaveContiguousDayRanges_AndBossDayAtChapterEnd()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement[] chapters = doc.RootElement.GetProperty("acts").EnumerateArray().ToArray();

        Assert.NotEmpty(chapters);

        int previousEndDay = 0;
        for (int i = 0; i < chapters.Length; i++)
        {
            JsonElement[] days = chapters[i].GetProperty("days").EnumerateArray().ToArray();
            int dayStart = ReadRequiredInt(days[0], $"acts[{i}].days[0]");
            int dayEnd = ReadRequiredInt(days[1], $"acts[{i}].days[1]");

            if (i == 0)
            {
                Assert.Equal(1, dayStart);
            }
            else
            {
                Assert.Equal(previousEndDay + 1, dayStart);
            }

            JsonElement boss = chapters[i].GetProperty("boss");
            int bossDay = ReadRequiredInt(boss.GetProperty("day"), $"acts[{i}].boss.day");
            Assert.InRange(bossDay, dayStart, dayEnd);
            Assert.Equal(dayEnd, bossDay);

            previousEndDay = dayEnd;
        }
    }

    [Fact]
    public void DialogueEntries_HaveSpeakerAndNonEmptyText()
    {
        using JsonDocument doc = LoadStoryDocument();
        JsonElement dialogue = doc.RootElement.GetProperty("dialogue");

        int entryCount = 0;
        foreach (JsonProperty entry in dialogue.EnumerateObject())
        {
            entryCount++;

            AssertNonEmptyString(entry.Value, "speaker", $"dialogue.{entry.Name}");
            string[] lineValues = ReadDialogueTextLines(entry.Value, $"dialogue.{entry.Name}");

            Assert.NotEmpty(lineValues);
        }

        Assert.True(entryCount > 0, "story.json dialogue section should contain at least one entry.");
    }

    private static JsonDocument LoadStoryDocument()
    {
        string dataDir = ResolveDataDirectory();
        string path = Path.Combine(dataDir, "story.json");
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"Could not locate story.json at '{path}'.");
        }

        return JsonDocument.Parse(File.ReadAllText(path));
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "story.json")))
            {
                return candidate;
            }

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir)
            {
                break;
            }

            dir = parent;
        }

        throw new DirectoryNotFoundException("Could not locate data/story.json from test base directory.");
    }

    private static string ReadRequiredString(JsonElement value, string context)
    {
        Assert.Equal(JsonValueKind.String, value.ValueKind);
        string? text = value.GetString();
        Assert.False(string.IsNullOrWhiteSpace(text), $"{context} must be a non-empty string.");
        return text!;
    }

    private static int ReadRequiredInt(JsonElement value, string context)
    {
        Assert.Equal(JsonValueKind.Number, value.ValueKind);
        Assert.True(value.TryGetInt32(out int result), $"{context} must be a 32-bit integer.");
        return result;
    }

    private static void AssertNonEmptyString(JsonElement obj, string propertyName, string context)
    {
        Assert.True(obj.TryGetProperty(propertyName, out JsonElement value), $"{context} missing '{propertyName}'.");
        _ = ReadRequiredString(value, $"{context}.{propertyName}");
    }

    private static string[] ReadDialogueTextLines(JsonElement dialogueEntry, string context)
    {
        if (dialogueEntry.TryGetProperty("text", out JsonElement text))
        {
            return new[] { ReadRequiredString(text, $"{context}.text") };
        }

        Assert.True(
            dialogueEntry.TryGetProperty("lines", out JsonElement lines) && lines.ValueKind == JsonValueKind.Array,
            $"{context} must include either 'text' or 'lines'.");

        string[] lineValues = lines.EnumerateArray()
            .Select((line, index) => ReadRequiredString(line, $"{context}.lines[{index}]"))
            .ToArray();

        Assert.NotEmpty(lineValues);
        return lineValues;
    }
}
