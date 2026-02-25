using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace KeyboardDefense.Tests.Core;

public class ExpeditionsDataTests
{
    public static IEnumerable<object[]> ExpeditionIdentityRows =>
        LoadExpeditionEntries().Select(expedition => new object[] { expedition.Id, expedition.Name });

    public static IEnumerable<object[]> ExpeditionDurationRows =>
        LoadExpeditionEntries().Select(expedition => new object[] { expedition.Id, expedition.DurationSeconds });

    public static IEnumerable<object[]> ExpeditionRewardCountRows =>
        LoadExpeditionEntries().Select(expedition => new object[] { expedition.Id, expedition.BaseRewards.Count + expedition.BonusRewards.Count });

    public static IEnumerable<object[]> ExpeditionRewardRows =>
        LoadExpeditionEntries().SelectMany(expedition =>
            expedition.BaseRewards.Select(reward => new object[] { expedition.Id, "base_yield", reward.Key, reward.Value })
                .Concat(expedition.BonusRewards.Select(reward => new object[] { expedition.Id, "bonus_yield", reward.Key, reward.Value })));

    [Fact]
    public void ExpeditionsJson_ParsesIntoEntries()
    {
        using JsonDocument document = LoadExpeditionsJson();
        JsonElement root = document.RootElement;

        Assert.True(root.TryGetProperty("expeditions", out JsonElement expeditionsNode));
        Assert.Equal(JsonValueKind.Array, expeditionsNode.ValueKind);

        List<ExpeditionEntry> expeditions = LoadExpeditionEntries();
        Assert.NotEmpty(expeditions);
        Assert.Equal(expeditionsNode.GetArrayLength(), expeditions.Count);
    }

    [Fact]
    public void ExpeditionsJson_CategoryReferencesExistInCategoriesMap()
    {
        using JsonDocument document = LoadExpeditionsJson();
        JsonElement root = document.RootElement;

        Assert.True(root.TryGetProperty("categories", out JsonElement categoriesNode));
        Assert.Equal(JsonValueKind.Object, categoriesNode.ValueKind);

        var categoryIds = categoriesNode.EnumerateObject()
            .Select(category => category.Name)
            .ToHashSet(StringComparer.Ordinal);

        Assert.NotEmpty(categoryIds);

        foreach (ExpeditionEntry expedition in LoadExpeditionEntries())
        {
            Assert.True(
                categoryIds.Contains(expedition.Category),
                $"Expedition '{expedition.Id}' references unknown category '{expedition.Category}'.");
        }
    }

    [Fact]
    public void ExpeditionsJson_HasNoDuplicateIds()
    {
        List<string> ids = LoadExpeditionEntries()
            .Select(expedition => expedition.Id)
            .ToList();

        Assert.NotEmpty(ids);
        Assert.Equal(ids.Count, ids.Distinct(StringComparer.Ordinal).Count());
    }

    [Theory]
    [MemberData(nameof(ExpeditionIdentityRows))]
    public void Expedition_HasNonEmptyId(string id, string _)
    {
        Assert.False(string.IsNullOrWhiteSpace(id));
    }

    [Theory]
    [MemberData(nameof(ExpeditionIdentityRows))]
    public void Expedition_HasNonEmptyName(string id, string name)
    {
        Assert.False(string.IsNullOrWhiteSpace(name), $"Expedition '{id}' is missing a name/label.");
    }

    [Theory]
    [MemberData(nameof(ExpeditionDurationRows))]
    public void Expedition_DurationSeconds_IsPositive(string id, int durationSeconds)
    {
        Assert.True(durationSeconds > 0, $"Expedition '{id}' has non-positive duration_seconds '{durationSeconds}'.");
    }

    [Theory]
    [MemberData(nameof(ExpeditionRewardCountRows))]
    public void Expedition_DefinesAtLeastOneReward(string id, int rewardCount)
    {
        Assert.True(rewardCount > 0, $"Expedition '{id}' must define at least one reward.");
    }

    [Theory]
    [MemberData(nameof(ExpeditionRewardRows))]
    public void Expedition_RewardValues_AreNonNegative(string id, string rewardType, string resource, double amount)
    {
        Assert.True(double.IsFinite(amount), $"Expedition '{id}' {rewardType}.{resource} is non-finite.");
        Assert.True(amount >= 0, $"Expedition '{id}' {rewardType}.{resource} has negative value '{amount}'.");
    }

    private static List<ExpeditionEntry> LoadExpeditionEntries()
    {
        using JsonDocument document = LoadExpeditionsJson();
        JsonElement expeditionsNode = document.RootElement.GetProperty("expeditions");
        var expeditions = new List<ExpeditionEntry>();

        foreach (JsonElement expeditionNode in expeditionsNode.EnumerateArray())
        {
            expeditions.Add(new ExpeditionEntry(
                Id: GetString(expeditionNode, "id"),
                Name: GetString(expeditionNode, "label", GetString(expeditionNode, "name")),
                Category: GetString(expeditionNode, "category"),
                DurationSeconds: GetInt(expeditionNode, "duration_seconds"),
                BaseRewards: ReadRewardMap(expeditionNode, "base_yield"),
                BonusRewards: ReadRewardMap(expeditionNode, "bonus_yield")));
        }

        return expeditions;
    }

    private static Dictionary<string, double> ReadRewardMap(JsonElement expeditionNode, string propertyName)
    {
        var rewards = new Dictionary<string, double>(StringComparer.Ordinal);
        if (!expeditionNode.TryGetProperty(propertyName, out JsonElement rewardNode) ||
            rewardNode.ValueKind != JsonValueKind.Object)
        {
            return rewards;
        }

        foreach (JsonProperty reward in rewardNode.EnumerateObject())
        {
            rewards[reward.Name] = ReadDouble(reward.Value);
        }

        return rewards;
    }

    private static string GetString(JsonElement node, string propertyName, string fallback = "")
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) ||
            value.ValueKind != JsonValueKind.String)
        {
            return fallback;
        }

        return value.GetString() ?? fallback;
    }

    private static int GetInt(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value))
        {
            return 0;
        }

        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out int number))
        {
            return number;
        }

        if (value.ValueKind == JsonValueKind.Number)
        {
            return Convert.ToInt32(value.GetDouble());
        }

        if (value.ValueKind == JsonValueKind.String &&
            int.TryParse(value.GetString(), out int parsed))
        {
            return parsed;
        }

        return 0;
    }

    private static double ReadDouble(JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Number)
        {
            return value.GetDouble();
        }

        if (value.ValueKind == JsonValueKind.String &&
            double.TryParse(value.GetString(), out double parsed))
        {
            return parsed;
        }

        return double.NaN;
    }

    private static JsonDocument LoadExpeditionsJson()
    {
        string dataDirectory = FindDataDirectory();
        string expeditionsPath = Path.Combine(dataDirectory, "expeditions.json");
        return JsonDocument.Parse(File.ReadAllText(expeditionsPath));
    }

    private static string FindDataDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 10 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "expeditions.json")))
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

        throw new DirectoryNotFoundException("Could not locate data/expeditions.json from the test output directory.");
    }

    private readonly record struct ExpeditionEntry(
        string Id,
        string Name,
        string Category,
        int DurationSeconds,
        Dictionary<string, double> BaseRewards,
        Dictionary<string, double> BonusRewards);
}
