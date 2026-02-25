using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace KeyboardDefense.Tests.Core;

public class EventsDataTests
{
    private static readonly Lazy<EventsFileModel> EventsFile = new(LoadEventsFile);
    private static readonly Lazy<EventTablesFileModel> EventTablesFile = new(LoadEventTablesFile);

    [Theory]
    [InlineData("events/events.json")]
    [InlineData("events/event_tables.json")]
    public void EventJsonFiles_ParseAsJsonObjects(string relativePath)
    {
        using JsonDocument document = JsonDocument.Parse(ReadDataFile(relativePath));
        Assert.Equal(JsonValueKind.Object, document.RootElement.ValueKind);
    }

    [Fact]
    public void EventsFile_HasNonEmptyEventsArray()
    {
        Assert.NotEmpty(GetEvents());
    }

    [Fact]
    public void EventTablesFile_HasNonEmptyTablesArray()
    {
        Assert.NotEmpty(GetTables());
    }

    [Fact]
    public void Events_HaveUniqueNonEmptyIds()
    {
        var seenIds = new HashSet<string>(StringComparer.Ordinal);

        foreach (EventModel evt in GetEvents())
        {
            Assert.False(string.IsNullOrWhiteSpace(evt.Id), "Found event with missing id.");
            Assert.True(seenIds.Add(evt.Id!), $"Duplicate event id '{evt.Id}'.");
        }
    }

    [Fact]
    public void Events_HaveTypeNameAndDescriptionMetadata()
    {
        foreach (EventModel evt in GetEvents())
        {
            string eventId = evt.Id ?? "<missing-id>";
            string typeValue = FirstNonEmpty(evt.Type, evt.Tier?.ToString());
            string nameValue = FirstNonEmpty(evt.Name, evt.Title);
            string descriptionValue = FirstNonEmpty(evt.Description, evt.Body);

            Assert.False(string.IsNullOrWhiteSpace(typeValue), $"Event '{eventId}' is missing type metadata (type or tier).");
            Assert.False(string.IsNullOrWhiteSpace(nameValue), $"Event '{eventId}' is missing name metadata (name or title).");
            Assert.False(string.IsNullOrWhiteSpace(descriptionValue), $"Event '{eventId}' is missing description metadata (description or body).");
        }
    }

    [Fact]
    public void Events_HaveValidTierCooldownTagsAndChoices()
    {
        foreach (EventModel evt in GetEvents())
        {
            string eventId = evt.Id ?? "<missing-id>";

            Assert.True(evt.Tier.HasValue, $"Event '{eventId}' is missing tier.");
            Assert.True(evt.Tier!.Value >= 0, $"Event '{eventId}' has negative tier {evt.Tier.Value}.");

            Assert.True(evt.CooldownDays.HasValue, $"Event '{eventId}' is missing cooldown_days.");
            Assert.True(evt.CooldownDays!.Value >= 0, $"Event '{eventId}' has negative cooldown_days {evt.CooldownDays.Value}.");

            Assert.NotNull(evt.Tags);
            Assert.NotEmpty(evt.Tags!);
            foreach (string? tag in evt.Tags!)
            {
                Assert.False(string.IsNullOrWhiteSpace(tag), $"Event '{eventId}' contains an empty tag.");
            }

            Assert.NotNull(evt.Choices);
            Assert.NotEmpty(evt.Choices!);
        }
    }

    [Fact]
    public void EventChoices_HaveUniqueIds_Labels_AndInputModes()
    {
        foreach (EventModel evt in GetEvents())
        {
            string eventId = evt.Id ?? "<missing-id>";
            var seenChoiceIds = new HashSet<string>(StringComparer.Ordinal);

            foreach (EventChoiceModel choice in evt.Choices!)
            {
                Assert.False(string.IsNullOrWhiteSpace(choice.Id), $"Event '{eventId}' has choice with missing id.");
                Assert.True(seenChoiceIds.Add(choice.Id!), $"Event '{eventId}' has duplicate choice id '{choice.Id}'.");
                Assert.False(string.IsNullOrWhiteSpace(choice.Label), $"Event '{eventId}' choice '{choice.Id}' is missing label.");
                Assert.NotNull(choice.Input);
                Assert.False(string.IsNullOrWhiteSpace(choice.Input!.Mode), $"Event '{eventId}' choice '{choice.Id}' is missing input.mode.");
            }
        }
    }

    [Fact]
    public void EventChoiceInputPayloads_MatchDeclaredMode()
    {
        foreach (EventModel evt in GetEvents())
        {
            string eventId = evt.Id ?? "<missing-id>";

            foreach (EventChoiceModel choice in evt.Choices!)
            {
                Assert.NotNull(choice.Input);
                EventInputModel input = choice.Input!;
                string mode = input.Mode ?? string.Empty;

                switch (mode)
                {
                    case "phrase":
                    case "code":
                        Assert.False(string.IsNullOrWhiteSpace(input.Text), $"Event '{eventId}' choice '{choice.Id}' mode '{mode}' requires input.text.");
                        break;

                    case "prompt_burst":
                        Assert.NotNull(input.Prompts);
                        Assert.NotEmpty(input.Prompts!);
                        foreach (string? prompt in input.Prompts!)
                        {
                            Assert.False(string.IsNullOrWhiteSpace(prompt), $"Event '{eventId}' choice '{choice.Id}' has empty prompt_burst prompt.");
                        }
                        break;

                    case "challenge":
                        Assert.Equal(JsonValueKind.Object, input.Challenge.ValueKind);
                        break;

                    default:
                        Assert.Fail($"Event '{eventId}' choice '{choice.Id}' uses unsupported input mode '{mode}'.");
                        break;
                }
            }
        }
    }

    [Fact]
    public void EventChoiceEffects_HaveNonEmptyType_ForSuccessAndFailureEffects()
    {
        foreach (EventModel evt in GetEvents())
        {
            string eventId = evt.Id ?? "<missing-id>";

            foreach (EventChoiceModel choice in evt.Choices!)
            {
                Assert.NotNull(choice.Effects);
                foreach (EventEffectModel effect in choice.Effects!)
                {
                    Assert.False(string.IsNullOrWhiteSpace(effect.Type), $"Event '{eventId}' choice '{choice.Id}' has effect missing type.");
                }

                if (choice.FailEffects == null)
                    continue;

                foreach (EventEffectModel effect in choice.FailEffects)
                {
                    Assert.False(string.IsNullOrWhiteSpace(effect.Type), $"Event '{eventId}' choice '{choice.Id}' has fail_effect missing type.");
                }
            }
        }
    }

    [Fact]
    public void ChoiceNextEventReferences_ResolveToExistingEvents()
    {
        var eventIds = GetEvents()
            .Select(e => e.Id)
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Cast<string>()
            .ToHashSet(StringComparer.Ordinal);

        foreach (EventModel evt in GetEvents())
        {
            string eventId = evt.Id ?? "<missing-id>";
            foreach (EventChoiceModel choice in evt.Choices!)
            {
                if (string.IsNullOrWhiteSpace(choice.NextEventId))
                    continue;

                Assert.Contains(choice.NextEventId!, eventIds);
                Assert.NotEqual(eventId, choice.NextEventId);
            }
        }
    }

    [Fact]
    public void EventTables_HaveUniqueIdsAndNonEmptyEntries()
    {
        var seenTableIds = new HashSet<string>(StringComparer.Ordinal);

        foreach (EventTableModel table in GetTables())
        {
            Assert.False(string.IsNullOrWhiteSpace(table.Id), "Found event table with missing id.");
            Assert.True(seenTableIds.Add(table.Id!), $"Duplicate event table id '{table.Id}'.");
            Assert.NotNull(table.Entries);
            Assert.NotEmpty(table.Entries!);
        }
    }

    [Fact]
    public void EventTableEntries_HavePositiveWeights_UniqueEventIds_AndValidReferences()
    {
        var eventIds = GetEvents()
            .Select(e => e.Id)
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Cast<string>()
            .ToHashSet(StringComparer.Ordinal);

        foreach (EventTableModel table in GetTables())
        {
            string tableId = table.Id ?? "<missing-table-id>";
            var seenEventIds = new HashSet<string>(StringComparer.Ordinal);
            double totalWeight = 0;

            foreach (EventTableEntryModel entry in table.Entries!)
            {
                Assert.False(string.IsNullOrWhiteSpace(entry.EventId), $"Table '{tableId}' contains entry with missing event_id.");
                Assert.True(seenEventIds.Add(entry.EventId!), $"Table '{tableId}' contains duplicate event_id '{entry.EventId}'.");
                Assert.Contains(entry.EventId!, eventIds);

                Assert.True(entry.Weight.HasValue, $"Table '{tableId}' entry '{entry.EventId}' is missing weight.");
                Assert.True(double.IsFinite(entry.Weight!.Value), $"Table '{tableId}' entry '{entry.EventId}' has non-finite weight {entry.Weight.Value}.");
                Assert.True(entry.Weight.Value > 0, $"Table '{tableId}' entry '{entry.EventId}' has non-positive weight {entry.Weight.Value}.");
                totalWeight += entry.Weight.Value;
            }

            Assert.True(totalWeight > 0, $"Table '{tableId}' has non-positive total weight.");
        }
    }

    private static IReadOnlyList<EventModel> GetEvents()
    {
        var events = EventsFile.Value.Events;
        Assert.NotNull(events);
        return events!;
    }

    private static IReadOnlyList<EventTableModel> GetTables()
    {
        var tables = EventTablesFile.Value.Tables;
        Assert.NotNull(tables);
        return tables!;
    }

    private static EventsFileModel LoadEventsFile()
    {
        string json = ReadDataFile("events/events.json");
        var model = JsonSerializer.Deserialize<EventsFileModel>(json);
        if (model?.Events == null)
            throw new InvalidDataException("Could not parse data/events/events.json.");
        return model;
    }

    private static EventTablesFileModel LoadEventTablesFile()
    {
        string json = ReadDataFile("events/event_tables.json");
        var model = JsonSerializer.Deserialize<EventTablesFileModel>(json);
        if (model?.Tables == null)
            throw new InvalidDataException("Could not parse data/events/event_tables.json.");
        return model;
    }

    private static string ReadDataFile(string relativePath)
    {
        string normalized = relativePath.Replace('\\', Path.DirectorySeparatorChar).Replace('/', Path.DirectorySeparatorChar);
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data", normalized);
            if (File.Exists(candidate))
            {
                return File.ReadAllText(candidate);
            }

            string? parent = Path.GetDirectoryName(dir);
            if (parent == dir)
                break;

            dir = parent;
        }

        throw new FileNotFoundException($"Could not locate data file '{relativePath}' from test base directory.");
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (string? value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
                return value;
        }

        return string.Empty;
    }

    private sealed class EventsFileModel
    {
        [JsonPropertyName("events")]
        public List<EventModel>? Events { get; init; }
    }

    private sealed class EventModel
    {
        [JsonPropertyName("id")]
        public string? Id { get; init; }

        [JsonPropertyName("type")]
        public string? Type { get; init; }

        [JsonPropertyName("name")]
        public string? Name { get; init; }

        [JsonPropertyName("description")]
        public string? Description { get; init; }

        [JsonPropertyName("title")]
        public string? Title { get; init; }

        [JsonPropertyName("body")]
        public string? Body { get; init; }

        [JsonPropertyName("tier")]
        public int? Tier { get; init; }

        [JsonPropertyName("cooldown_days")]
        public int? CooldownDays { get; init; }

        [JsonPropertyName("tags")]
        public List<string>? Tags { get; init; }

        [JsonPropertyName("choices")]
        public List<EventChoiceModel>? Choices { get; init; }
    }

    private sealed class EventChoiceModel
    {
        [JsonPropertyName("id")]
        public string? Id { get; init; }

        [JsonPropertyName("label")]
        public string? Label { get; init; }

        [JsonPropertyName("input")]
        public EventInputModel? Input { get; init; }

        [JsonPropertyName("effects")]
        public List<EventEffectModel>? Effects { get; init; }

        [JsonPropertyName("fail_effects")]
        public List<EventEffectModel>? FailEffects { get; init; }

        [JsonPropertyName("next_event_id")]
        public string? NextEventId { get; init; }
    }

    private sealed class EventInputModel
    {
        [JsonPropertyName("mode")]
        public string? Mode { get; init; }

        [JsonPropertyName("text")]
        public string? Text { get; init; }

        [JsonPropertyName("prompts")]
        public List<string>? Prompts { get; init; }

        [JsonPropertyName("challenge")]
        public JsonElement Challenge { get; init; }
    }

    private sealed class EventEffectModel
    {
        [JsonPropertyName("type")]
        public string? Type { get; init; }
    }

    private sealed class EventTablesFileModel
    {
        [JsonPropertyName("tables")]
        public List<EventTableModel>? Tables { get; init; }
    }

    private sealed class EventTableModel
    {
        [JsonPropertyName("id")]
        public string? Id { get; init; }

        [JsonPropertyName("entries")]
        public List<EventTableEntryModel>? Entries { get; init; }
    }

    private sealed class EventTableEntryModel
    {
        [JsonPropertyName("event_id")]
        public string? EventId { get; init; }

        [JsonPropertyName("weight")]
        public double? Weight { get; init; }
    }
}
