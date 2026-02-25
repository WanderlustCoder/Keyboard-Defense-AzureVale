using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.Json;
using KeyboardDefense.Core.Combat;

namespace KeyboardDefense.Tests.Core;

public class ScenarioDataTests
{
    private static readonly HashSet<string> AllowedStopTypes = new(StringComparer.Ordinal)
    {
        "after_commands",
        "until_day",
        "until_phase",
    };

    private static readonly HashSet<string> AllowedComparators = new(StringComparer.Ordinal)
    {
        "eq",
        "min",
        "max",
    };

    private static readonly HashSet<string> AllowedPhases = new(StringComparer.OrdinalIgnoreCase)
    {
        "day",
        "night",
    };

    [Fact]
    public void ScenariosJson_ParsesAndContainsScenarioArray()
    {
        using JsonDocument doc = LoadDataDocument("scenarios.json");
        JsonElement root = doc.RootElement;
        Assert.Equal(JsonValueKind.Object, root.ValueKind);

        Assert.True(root.TryGetProperty("version", out JsonElement versionNode), "Missing root 'version'.");
        Assert.True(ReadInt(versionNode) >= 1, "Scenario data version must be >= 1.");

        Assert.True(root.TryGetProperty("scenarios", out JsonElement scenariosNode), "Missing root 'scenarios'.");
        Assert.Equal(JsonValueKind.Array, scenariosNode.ValueKind);

        List<ScenarioRow> rows = ReadScenarioRows();
        Assert.Equal(scenariosNode.GetArrayLength(), rows.Count);
        Assert.True(rows.Count >= 20, $"Expected at least 20 scenarios; found {rows.Count}.");
    }

    [Fact]
    public void ScenarioRows_HaveUniqueSnakeCaseIds()
    {
        List<ScenarioRow> rows = ReadScenarioRows();
        var unique = new HashSet<string>(StringComparer.Ordinal);

        foreach (ScenarioRow row in rows)
        {
            Assert.False(string.IsNullOrWhiteSpace(row.Id), "Scenario id cannot be blank.");
            Assert.True(unique.Add(row.Id), $"Duplicate scenario id '{row.Id}'.");
            AssertSnakeCaseIdentifier(row.Id);
        }
    }

    [Fact]
    public void ScenarioRows_HaveValidNamesAndPriorityCodes()
    {
        using JsonDocument doc = LoadDataDocument("scenarios.json");
        JsonElement scenarios = doc.RootElement.GetProperty("scenarios");

        foreach (JsonElement scenario in scenarios.EnumerateArray())
        {
            string id = GetRequiredString(scenario, "id");
            string priority = GetRequiredString(scenario, "priority");

            string displayName = scenario.TryGetProperty("name", out JsonElement nameNode) && nameNode.ValueKind == JsonValueKind.String
                ? nameNode.GetString() ?? string.Empty
                : GetRequiredString(scenario, "description");

            Assert.False(string.IsNullOrWhiteSpace(displayName), $"Scenario '{id}' has empty name/description.");
            Assert.Equal(displayName.Trim(), displayName);
            Assert.DoesNotContain('\n', displayName);
            Assert.DoesNotContain('\r', displayName);
            Assert.Matches("^P[0-3]$", priority);
        }
    }

    [Theory]
    [InlineData("id")]
    [InlineData("description")]
    [InlineData("tags")]
    [InlineData("priority")]
    [InlineData("script")]
    [InlineData("stop")]
    [InlineData("expect_baseline")]
    public void ScenarioRows_ContainRequiredTopLevelProperties(string propertyName)
    {
        using JsonDocument doc = LoadDataDocument("scenarios.json");
        JsonElement scenarios = doc.RootElement.GetProperty("scenarios");

        foreach (JsonElement scenario in scenarios.EnumerateArray())
        {
            string id = scenario.TryGetProperty("id", out JsonElement idNode) && idNode.ValueKind == JsonValueKind.String
                ? idNode.GetString() ?? "<missing-id>"
                : "<missing-id>";

            Assert.True(
                scenario.TryGetProperty(propertyName, out _),
                $"Scenario '{id}' is missing required property '{propertyName}'.");
        }
    }

    [Fact]
    public void ScenarioRows_HaveNonEmptyUniqueTags()
    {
        List<ScenarioRow> rows = ReadScenarioRows();

        foreach (ScenarioRow row in rows)
        {
            Assert.NotEmpty(row.Tags);
            Assert.Equal(row.Tags.Count, row.Tags.Distinct(StringComparer.OrdinalIgnoreCase).Count());

            foreach (string tag in row.Tags)
            {
                Assert.False(string.IsNullOrWhiteSpace(tag), $"Scenario '{row.Id}' contains a blank tag.");
                AssertSnakeCaseIdentifier(tag);
            }
        }
    }

    [Fact]
    public void ScenarioRows_HaveNonEmptyScriptCommands()
    {
        List<ScenarioRow> rows = ReadScenarioRows();

        foreach (ScenarioRow row in rows)
        {
            Assert.NotEmpty(row.Script);
            foreach (string command in row.Script)
            {
                Assert.False(string.IsNullOrWhiteSpace(command), $"Scenario '{row.Id}' has a blank script command.");
            }
        }
    }

    [Theory]
    [InlineData("after_commands")]
    [InlineData("until_day")]
    [InlineData("until_phase")]
    public void ScenarioRows_StopTypes_AreRepresented(string stopType)
    {
        List<ScenarioRow> rows = ReadScenarioRows();
        Assert.Contains(rows, row => string.Equals(row.Stop.Type, stopType, StringComparison.Ordinal));
    }

    [Fact]
    public void ScenarioRows_StopBlocks_UseSupportedTypesAndRequiredFields()
    {
        List<ScenarioRow> rows = ReadScenarioRows();

        foreach (ScenarioRow row in rows)
        {
            Assert.Contains(row.Stop.Type, AllowedStopTypes);

            switch (row.Stop.Type)
            {
                case "after_commands":
                    if (row.Stop.MaxSteps.HasValue)
                    {
                        Assert.True(row.Stop.MaxSteps.Value > 0, $"Scenario '{row.Id}' max_steps must be positive.");
                    }
                    break;

                case "until_day":
                    Assert.True(row.Stop.Day.HasValue && row.Stop.Day.Value > 0, $"Scenario '{row.Id}' requires stop.day > 0.");
                    Assert.True(row.Stop.MaxSteps.HasValue && row.Stop.MaxSteps.Value > 0, $"Scenario '{row.Id}' requires stop.max_steps > 0.");
                    break;

                case "until_phase":
                    Assert.True(!string.IsNullOrWhiteSpace(row.Stop.Phase), $"Scenario '{row.Id}' requires stop.phase.");
                    Assert.Contains(row.Stop.Phase!, AllowedPhases);
                    Assert.True(row.Stop.MaxSteps.HasValue && row.Stop.MaxSteps.Value > 0, $"Scenario '{row.Id}' requires stop.max_steps > 0.");
                    break;
            }
        }
    }

    [Fact]
    public void ScenarioRows_ExpectationBlocks_HaveValidComparatorsAndConsistentBounds()
    {
        List<ScenarioRow> rows = ReadScenarioRows();

        foreach (ScenarioRow row in rows)
        {
            ValidateExpectationBlock(row, "expect_baseline", row.Baseline);
            ValidateExpectationBlock(row, "expect_target", row.Target);
        }
    }

    [Fact]
    public void ScenarioRows_NightWaveExpectations_ArePositiveForNightPhase()
    {
        List<ScenarioRow> rows = ReadScenarioRows();
        List<ScenarioRow> nightRows = rows
            .Where(row => string.Equals(GetEqString(row.Baseline, "phase"), "night", StringComparison.OrdinalIgnoreCase))
            .ToList();

        Assert.NotEmpty(nightRows);

        foreach (ScenarioRow row in nightRows)
        {
            Assert.True(row.Baseline.TryGetValue("night_wave_total", out MetricExpectation waveMetric),
                $"Night scenario '{row.Id}' is missing 'night_wave_total' expectation.");

            double? expectedValue = waveMetric.EqNumber ?? waveMetric.Min ?? waveMetric.Max;
            Assert.True(expectedValue.HasValue, $"Night scenario '{row.Id}' has no numeric wave expectation.");
            Assert.True(expectedValue.Value > 0, $"Night scenario '{row.Id}' must expect positive waves, got {expectedValue.Value}.");
        }
    }

    [Fact]
    public void ScenarioRows_EnemyTypeReferences_ResolveToKnownEnemyKinds()
    {
        List<ScenarioRow> rows = ReadScenarioRows();
        var knownKinds = EnemyTypes.Registry.Keys.ToHashSet(StringComparer.Ordinal);
        var referencedKinds = rows
            .SelectMany(ExtractEnemyKindReferences)
            .Distinct(StringComparer.Ordinal)
            .ToList();

        Assert.NotEmpty(knownKinds);

        foreach (string kind in referencedKinds)
        {
            Assert.Contains(kind, knownKinds);
        }

        bool hasEnemyAggregateMetrics = rows.Any(row =>
            row.Baseline.Keys.Concat(row.Target.Keys).Any(metric => metric.StartsWith("enemies_", StringComparison.OrdinalIgnoreCase)));

        Assert.True(
            referencedKinds.Count > 0 || hasEnemyAggregateMetrics,
            "Scenario data should define either explicit enemy kinds or aggregate enemy metrics.");
    }

    [Fact]
    public void ScenarioRows_RewardAndResourceExpectations_AreNonNegative()
    {
        List<ScenarioRow> rows = ReadScenarioRows();
        var rewardValues = new List<(string ScenarioId, string Metric, string Comparator, double Value)>();

        foreach (ScenarioRow row in rows)
        {
            CollectNonNegativeEconomyValues(row, row.Baseline, rewardValues);
            CollectNonNegativeEconomyValues(row, row.Target, rewardValues);
        }

        Assert.NotEmpty(rewardValues);
    }

    [Fact]
    public void ScenarioRows_DifficultyTags_AreOrderedByExpectedDay()
    {
        List<ScenarioRow> rows = ReadScenarioRows();
        List<int> earlyDays = rows
            .Where(row => row.Tags.Contains("early", StringComparer.OrdinalIgnoreCase))
            .Select(TryGetExpectedDay)
            .Where(day => day.HasValue)
            .Select(day => day!.Value)
            .ToList();
        List<int> midOnlyDays = rows
            .Where(row => row.Tags.Contains("mid", StringComparer.OrdinalIgnoreCase) &&
                          !row.Tags.Contains("long", StringComparer.OrdinalIgnoreCase))
            .Select(TryGetExpectedDay)
            .Where(day => day.HasValue)
            .Select(day => day!.Value)
            .ToList();
        List<int> longDays = rows
            .Where(row => row.Tags.Contains("long", StringComparer.OrdinalIgnoreCase))
            .Select(TryGetExpectedDay)
            .Where(day => day.HasValue)
            .Select(day => day!.Value)
            .ToList();

        Assert.NotEmpty(earlyDays);
        Assert.NotEmpty(midOnlyDays);
        Assert.NotEmpty(longDays);

        Assert.True(earlyDays.Max() < midOnlyDays.Min(), "Expected early scenarios to precede mid scenarios.");
        Assert.True(midOnlyDays.Max() <= longDays.Min(), "Expected long scenarios to be at least as late as mid scenarios.");
        Assert.True(longDays.Min() >= 7, "Expected long scenarios to target late-game days.");
    }

    private static void CollectNonNegativeEconomyValues(
        ScenarioRow row,
        IReadOnlyDictionary<string, MetricExpectation> expectations,
        List<(string ScenarioId, string Metric, string Comparator, double Value)> values)
    {
        foreach ((string metric, MetricExpectation expectation) in expectations)
        {
            if (!IsRewardOrResourceMetric(metric))
            {
                continue;
            }

            if (expectation.EqNumber.HasValue)
            {
                Assert.True(expectation.EqNumber.Value >= 0, $"{row.Id}:{metric}.eq is negative ({expectation.EqNumber.Value}).");
                values.Add((row.Id, metric, "eq", expectation.EqNumber.Value));
            }

            if (expectation.Min.HasValue)
            {
                Assert.True(expectation.Min.Value >= 0, $"{row.Id}:{metric}.min is negative ({expectation.Min.Value}).");
                values.Add((row.Id, metric, "min", expectation.Min.Value));
            }

            if (expectation.Max.HasValue)
            {
                Assert.True(expectation.Max.Value >= 0, $"{row.Id}:{metric}.max is negative ({expectation.Max.Value}).");
                values.Add((row.Id, metric, "max", expectation.Max.Value));
            }
        }
    }

    private static bool IsRewardOrResourceMetric(string metric)
        => metric.StartsWith("resources.", StringComparison.OrdinalIgnoreCase) ||
           metric.Contains("reward", StringComparison.OrdinalIgnoreCase) ||
           string.Equals(metric, "gold", StringComparison.OrdinalIgnoreCase);

    private static int? TryGetExpectedDay(ScenarioRow row)
    {
        if (!row.Baseline.TryGetValue("day", out MetricExpectation dayMetric))
        {
            return null;
        }

        double? dayValue = dayMetric.EqNumber ?? dayMetric.Min ?? dayMetric.Max;
        if (!dayValue.HasValue)
        {
            return null;
        }

        double rounded = Math.Round(dayValue.Value);
        if (Math.Abs(dayValue.Value - rounded) > 0.0001)
        {
            return null;
        }

        return (int)rounded;
    }

    private static string? GetEqString(IReadOnlyDictionary<string, MetricExpectation> expectations, string metricKey)
        => expectations.TryGetValue(metricKey, out MetricExpectation metric) ? metric.EqString : null;

    private static void ValidateExpectationBlock(
        ScenarioRow row,
        string blockName,
        IReadOnlyDictionary<string, MetricExpectation> expectations)
    {
        foreach ((string metric, MetricExpectation expectation) in expectations)
        {
            Assert.False(string.IsNullOrWhiteSpace(metric), $"Scenario '{row.Id}' has blank metric in {blockName}.");
            Assert.NotEmpty(expectation.ComparatorKeys);

            foreach (string comparator in expectation.ComparatorKeys)
            {
                Assert.Contains(comparator, AllowedComparators);
            }

            if (expectation.EqString is not null)
            {
                Assert.False(expectation.EqNumber.HasValue, $"{row.Id}:{blockName}.{metric} cannot have string and numeric eq values.");
                Assert.False(expectation.Min.HasValue || expectation.Max.HasValue, $"{row.Id}:{blockName}.{metric} string eq cannot combine with min/max.");
            }

            if (expectation.Min.HasValue && expectation.Max.HasValue)
            {
                Assert.True(
                    expectation.Min.Value <= expectation.Max.Value,
                    $"{row.Id}:{blockName}.{metric} has min {expectation.Min.Value} > max {expectation.Max.Value}.");
            }

            if (expectation.EqNumber.HasValue && expectation.Min.HasValue)
            {
                Assert.True(
                    expectation.EqNumber.Value >= expectation.Min.Value,
                    $"{row.Id}:{blockName}.{metric} has eq {expectation.EqNumber.Value} below min {expectation.Min.Value}.");
            }

            if (expectation.EqNumber.HasValue && expectation.Max.HasValue)
            {
                Assert.True(
                    expectation.EqNumber.Value <= expectation.Max.Value,
                    $"{row.Id}:{blockName}.{metric} has eq {expectation.EqNumber.Value} above max {expectation.Max.Value}.");
            }
        }
    }

    private static IEnumerable<string> ExtractEnemyKindReferences(ScenarioRow row)
    {
        var kinds = new HashSet<string>(StringComparer.Ordinal);
        ExtractKindsFromExpectationMap(row.Baseline, kinds);
        ExtractKindsFromExpectationMap(row.Target, kinds);

        foreach (string command in row.Script)
        {
            string[] tokens = command.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (tokens.Length < 2)
            {
                continue;
            }

            if (tokens[0].Equals("spawn", StringComparison.OrdinalIgnoreCase) ||
                tokens[0].Equals("spawn_enemy", StringComparison.OrdinalIgnoreCase) ||
                tokens[0].Equals("enemy", StringComparison.OrdinalIgnoreCase))
            {
                string kind = NormalizeToken(tokens[1]);
                if (!string.IsNullOrWhiteSpace(kind))
                {
                    kinds.Add(kind);
                }
            }
        }

        return kinds;
    }

    private static void ExtractKindsFromExpectationMap(
        IReadOnlyDictionary<string, MetricExpectation> expectations,
        HashSet<string> output)
    {
        foreach ((string metric, MetricExpectation expectation) in expectations)
        {
            if (metric.StartsWith("enemies_by_type.", StringComparison.OrdinalIgnoreCase))
            {
                string kind = NormalizeToken(metric["enemies_by_type.".Length..]);
                if (!string.IsNullOrWhiteSpace(kind))
                {
                    output.Add(kind);
                }
                continue;
            }

            if (metric.Contains("enemy_kind", StringComparison.OrdinalIgnoreCase) &&
                !string.IsNullOrWhiteSpace(expectation.EqString))
            {
                string kind = NormalizeToken(expectation.EqString!);
                if (!string.IsNullOrWhiteSpace(kind))
                {
                    output.Add(kind);
                }
            }
        }
    }

    private static string NormalizeToken(string token)
    {
        string normalized = token.Trim().Trim(',', '.', ';', ':', '[', ']', '(', ')', '"', '\'');
        return normalized.ToLowerInvariant();
    }

    private static void AssertSnakeCaseIdentifier(string value)
    {
        Assert.False(string.IsNullOrWhiteSpace(value));
        Assert.False(value.StartsWith('_'));
        Assert.False(value.EndsWith('_'));
        Assert.DoesNotContain("__", value);

        foreach (char c in value)
        {
            Assert.True(char.IsLower(c) || char.IsDigit(c) || c == '_', $"Identifier '{value}' has invalid character '{c}'.");
        }
    }

    private static List<ScenarioRow> ReadScenarioRows()
    {
        using JsonDocument doc = LoadDataDocument("scenarios.json");
        JsonElement scenarios = doc.RootElement.GetProperty("scenarios");
        var rows = new List<ScenarioRow>();

        foreach (JsonElement scenario in scenarios.EnumerateArray())
        {
            string id = GetRequiredString(scenario, "id");
            string description = GetRequiredString(scenario, "description");
            string priority = GetRequiredString(scenario, "priority");
            List<string> tags = ReadRequiredStringArray(scenario, "tags");
            List<string> script = ReadRequiredStringArray(scenario, "script");
            StopSpec stop = ReadStopSpec(scenario);
            Dictionary<string, MetricExpectation> baseline = ReadExpectationMap(scenario, "expect_baseline", required: true);
            Dictionary<string, MetricExpectation> target = ReadExpectationMap(scenario, "expect_target", required: false);

            rows.Add(new ScenarioRow(
                Id: id,
                Description: description,
                Priority: priority,
                Tags: tags,
                Script: script,
                Stop: stop,
                Baseline: baseline,
                Target: target));
        }

        return rows;
    }

    private static StopSpec ReadStopSpec(JsonElement scenario)
    {
        if (!scenario.TryGetProperty("stop", out JsonElement stopNode) || stopNode.ValueKind != JsonValueKind.Object)
        {
            throw new InvalidDataException($"Scenario '{GetRequiredString(scenario, "id")}' is missing object 'stop'.");
        }

        string type = GetRequiredString(stopNode, "type");
        int? day = TryGetInt(stopNode, "day");
        string? phase = TryGetString(stopNode, "phase");
        int? maxSteps = TryGetInt(stopNode, "max_steps");

        return new StopSpec(type, day, phase, maxSteps);
    }

    private static Dictionary<string, MetricExpectation> ReadExpectationMap(
        JsonElement scenario,
        string propertyName,
        bool required)
    {
        if (!scenario.TryGetProperty(propertyName, out JsonElement block))
        {
            if (required)
            {
                throw new InvalidDataException($"Scenario '{GetRequiredString(scenario, "id")}' is missing required '{propertyName}'.");
            }

            return new Dictionary<string, MetricExpectation>(StringComparer.Ordinal);
        }

        if (block.ValueKind != JsonValueKind.Object)
        {
            throw new InvalidDataException($"Scenario '{GetRequiredString(scenario, "id")}' has non-object '{propertyName}'.");
        }

        var output = new Dictionary<string, MetricExpectation>(StringComparer.Ordinal);

        foreach (JsonProperty metric in block.EnumerateObject())
        {
            if (metric.Value.ValueKind != JsonValueKind.Object)
            {
                throw new InvalidDataException(
                    $"Scenario '{GetRequiredString(scenario, "id")}' metric '{propertyName}.{metric.Name}' must be an object.");
            }

            output[metric.Name] = ReadMetricExpectation(metric.Value);
        }

        return output;
    }

    private static MetricExpectation ReadMetricExpectation(JsonElement node)
    {
        var comparators = new HashSet<string>(StringComparer.Ordinal);
        double? eqNumber = null;
        string? eqString = null;
        double? min = null;
        double? max = null;

        foreach (JsonProperty comparator in node.EnumerateObject())
        {
            comparators.Add(comparator.Name);

            switch (comparator.Name)
            {
                case "eq":
                    if (TryReadDouble(comparator.Value, out double numericEq))
                    {
                        eqNumber = numericEq;
                    }
                    else if (comparator.Value.ValueKind == JsonValueKind.String)
                    {
                        eqString = comparator.Value.GetString();
                    }
                    break;

                case "min":
                    if (TryReadDouble(comparator.Value, out double minValue))
                    {
                        min = minValue;
                    }
                    break;

                case "max":
                    if (TryReadDouble(comparator.Value, out double maxValue))
                    {
                        max = maxValue;
                    }
                    break;
            }
        }

        return new MetricExpectation(
            EqNumber: eqNumber,
            EqString: eqString,
            Min: min,
            Max: max,
            ComparatorKeys: comparators);
    }

    private static string GetRequiredString(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) || value.ValueKind != JsonValueKind.String)
        {
            throw new InvalidDataException($"Expected string property '{propertyName}'.");
        }

        return value.GetString() ?? string.Empty;
    }

    private static string? TryGetString(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) || value.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        return value.GetString();
    }

    private static int? TryGetInt(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return null;
        }

        return TryReadInt(value, out int result) ? result : null;
    }

    private static List<string> ReadRequiredStringArray(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) || value.ValueKind != JsonValueKind.Array)
        {
            throw new InvalidDataException($"Expected array property '{propertyName}'.");
        }

        var output = new List<string>();
        foreach (JsonElement item in value.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.String)
            {
                throw new InvalidDataException($"Property '{propertyName}' must contain only strings.");
            }

            output.Add(item.GetString() ?? string.Empty);
        }

        return output;
    }

    private static bool TryReadInt(JsonElement value, out int output)
    {
        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out int intValue))
        {
            output = intValue;
            return true;
        }

        if (value.ValueKind == JsonValueKind.String &&
            int.TryParse(value.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out int parsed))
        {
            output = parsed;
            return true;
        }

        output = 0;
        return false;
    }

    private static int ReadInt(JsonElement value)
    {
        if (TryReadInt(value, out int output))
        {
            return output;
        }

        throw new InvalidDataException($"Expected integer-compatible JSON value but found '{value.ValueKind}'.");
    }

    private static bool TryReadDouble(JsonElement value, out double output)
    {
        if (value.ValueKind == JsonValueKind.Number)
        {
            output = value.GetDouble();
            return true;
        }

        if (value.ValueKind == JsonValueKind.String &&
            double.TryParse(value.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out double parsed))
        {
            output = parsed;
            return true;
        }

        output = 0;
        return false;
    }

    private static JsonDocument LoadDataDocument(string fileName)
    {
        string dataDir = ResolveDataDirectory();
        string path = Path.Combine(dataDir, fileName);
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"Could not locate data file '{fileName}' at '{path}'.");
        }

        return JsonDocument.Parse(File.ReadAllText(path));
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "scenarios.json")))
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

        throw new DirectoryNotFoundException("Could not locate data/scenarios.json from test base directory.");
    }

    private readonly record struct ScenarioRow(
        string Id,
        string Description,
        string Priority,
        List<string> Tags,
        List<string> Script,
        StopSpec Stop,
        IReadOnlyDictionary<string, MetricExpectation> Baseline,
        IReadOnlyDictionary<string, MetricExpectation> Target);

    private readonly record struct StopSpec(
        string Type,
        int? Day,
        string? Phase,
        int? MaxSteps);

    private readonly record struct MetricExpectation(
        double? EqNumber,
        string? EqString,
        double? Min,
        double? Max,
        IReadOnlyCollection<string> ComparatorKeys);
}
