using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

[Collection("LocaleSerial")]
public sealed class LocaleExtendedTests : IDisposable
{
    public LocaleExtendedTests()
    {
        ResetLocaleState();
    }

    public void Dispose()
    {
        ResetLocaleState();
    }

    [Fact]
    public void Tr_ReturnsLoadedLocaleStringValue()
    {
        Locale.LoadTranslations(LoadFlattenedTranslations("de"));

        Assert.Equal("Speichern", Locale.Tr("ui.save"));
        Assert.Equal("KEYBOARD DEFENSE", Locale.Tr("menu.title"));
    }

    [Fact]
    public void Tr_MissingKey_ReturnsKey()
    {
        Locale.LoadTranslations(LoadFlattenedTranslations("en"));

        Assert.Equal("ui.not_a_real_key", Locale.Tr("ui.not_a_real_key"));
    }

    [Fact]
    public void Tr_WithPlaceholders_ReplacesNamedTokens()
    {
        Locale.LoadTranslations(LoadFlattenedTranslations("en"));

        string result = Locale.Tr(
            "messages.unknown_command",
            new Dictionary<string, string> { ["command"] = "build barracks" });

        Assert.Equal("Unknown command: build barracks", result);
    }

    [Fact]
    public void Tr_WithMissingPlaceholder_LeavesUnknownTokenInOutput()
    {
        Locale.LoadTranslations(LoadFlattenedTranslations("en"));

        string result = Locale.Tr("messages.unknown_command", new Dictionary<string, string>());

        Assert.Equal("Unknown command: {command}", result);
    }

    [Fact]
    public void SetLocale_AcceptsEachSupportedLocale()
    {
        foreach (string localeId in Locale.SupportedLocales)
        {
            Locale.SetLocale(localeId);
            Assert.Equal(localeId, Locale.CurrentLocale);
        }
    }

    [Fact]
    public void AllLocaleFiles_ParseAndContainRequiredMetadata()
    {
        IReadOnlyList<string> localeFiles = EnumerateLocaleFiles();
        Assert.NotEmpty(localeFiles);

        foreach (string filePath in localeFiles)
        {
            LocaleFile localeFile = ReadLocaleFileFromPath(filePath);
            string expectedId = Path.GetFileNameWithoutExtension(filePath);

            Assert.Equal(1, localeFile.Version);
            Assert.Equal(expectedId, localeFile.LocaleId);
            Assert.False(string.IsNullOrWhiteSpace(localeFile.Name));
            Assert.NotEmpty(localeFile.FlattenedValues);
        }
    }

    [Fact]
    public void LocaleFiles_HaveNoDuplicateKeysWithinAnyObject()
    {
        foreach (string filePath in EnumerateLocaleFiles())
        {
            byte[] jsonUtf8 = Encoding.UTF8.GetBytes(File.ReadAllText(filePath));
            List<string> duplicates = FindDuplicateKeysWithinObjects(jsonUtf8);

            Assert.True(
                duplicates.Count == 0,
                $"Expected no duplicate keys in '{Path.GetFileName(filePath)}' but found: {string.Join(", ", duplicates)}");
        }
    }

    [Fact]
    public void AllSupportedLocales_HaveSameFlattenedKeySet()
    {
        var localeFilesById = new Dictionary<string, LocaleFile>(StringComparer.Ordinal);
        foreach (string localeId in Locale.SupportedLocales)
        {
            localeFilesById[localeId] = ReadLocaleFile(localeId);
        }

        string baselineLocaleId = Locale.SupportedLocales[0];
        var baselineKeys = new HashSet<string>(
            localeFilesById[baselineLocaleId].FlattenedValues.Keys,
            StringComparer.Ordinal);

        foreach (string localeId in Locale.SupportedLocales.Skip(1))
        {
            var localeKeys = new HashSet<string>(localeFilesById[localeId].FlattenedValues.Keys, StringComparer.Ordinal);
            string[] missing = baselineKeys.Except(localeKeys, StringComparer.Ordinal).OrderBy(x => x, StringComparer.Ordinal).ToArray();
            string[] extra = localeKeys.Except(baselineKeys, StringComparer.Ordinal).OrderBy(x => x, StringComparer.Ordinal).ToArray();

            Assert.True(
                missing.Length == 0 && extra.Length == 0,
                $"Locale '{localeId}' key set mismatch. Missing: [{string.Join(", ", missing)}] Extra: [{string.Join(", ", extra)}]");
        }
    }

    [Fact]
    public void LocaleFiles_HaveNoEmptyStringValues()
    {
        foreach (string localeId in Locale.SupportedLocales)
        {
            LocaleFile localeFile = ReadLocaleFile(localeId);
            string[] emptyKeys = localeFile.FlattenedValues
                .Where(pair => string.IsNullOrWhiteSpace(pair.Value))
                .Select(pair => pair.Key)
                .OrderBy(x => x, StringComparer.Ordinal)
                .ToArray();

            Assert.True(
                emptyKeys.Length == 0,
                $"Locale '{localeId}' has empty values for keys: [{string.Join(", ", emptyKeys)}]");
        }
    }

    private static void ResetLocaleState()
    {
        Locale.SetLocale("en");
        Locale.LoadTranslations(new Dictionary<string, string>());
    }

    private static Dictionary<string, string> LoadFlattenedTranslations(string localeId)
    {
        return new Dictionary<string, string>(ReadLocaleFile(localeId).FlattenedValues, StringComparer.Ordinal);
    }

    private static LocaleFile ReadLocaleFile(string localeId)
    {
        string filePath = Path.Combine(ResolveTranslationsDirectory(), $"{localeId}.json");
        return ReadLocaleFileFromPath(filePath);
    }

    private static LocaleFile ReadLocaleFileFromPath(string filePath)
    {
        using var document = JsonDocument.Parse(File.ReadAllText(filePath));
        JsonElement root = document.RootElement;

        var flattened = new Dictionary<string, string>(StringComparer.Ordinal);
        FlattenStringValues(root, "", flattened);

        return new LocaleFile(
            LocaleId: TryReadString(root, "locale"),
            Name: TryReadString(root, "name"),
            Version: TryReadInt(root, "version"),
            FlattenedValues: flattened);
    }

    private static IReadOnlyList<string> EnumerateLocaleFiles()
    {
        return Directory.GetFiles(ResolveTranslationsDirectory(), "*.json")
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static void FlattenStringValues(JsonElement element, string prefix, Dictionary<string, string> result)
    {
        if (element.ValueKind != JsonValueKind.Object)
        {
            return;
        }

        foreach (JsonProperty property in element.EnumerateObject())
        {
            string key = string.IsNullOrEmpty(prefix) ? property.Name : $"{prefix}.{property.Name}";
            if (property.Value.ValueKind == JsonValueKind.Object)
            {
                FlattenStringValues(property.Value, key, result);
            }
            else if (property.Value.ValueKind == JsonValueKind.String)
            {
                result[key] = property.Value.GetString() ?? string.Empty;
            }
        }
    }

    private static int TryReadInt(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) || value.ValueKind != JsonValueKind.Number)
        {
            return default;
        }

        return value.TryGetInt32(out int parsed) ? parsed : default;
    }

    private static string TryReadString(JsonElement node, string propertyName)
    {
        if (!node.TryGetProperty(propertyName, out JsonElement value) || value.ValueKind != JsonValueKind.String)
        {
            return string.Empty;
        }

        return value.GetString() ?? string.Empty;
    }

    private static List<string> FindDuplicateKeysWithinObjects(byte[] jsonUtf8)
    {
        var duplicates = new List<string>();
        var reader = new Utf8JsonReader(jsonUtf8, new JsonReaderOptions
        {
            CommentHandling = JsonCommentHandling.Skip,
            AllowTrailingCommas = false
        });

        var objectPropertySets = new Stack<HashSet<string>>();
        while (reader.Read())
        {
            if (reader.TokenType == JsonTokenType.StartObject)
            {
                objectPropertySets.Push(new HashSet<string>(StringComparer.Ordinal));
                continue;
            }

            if (reader.TokenType == JsonTokenType.EndObject)
            {
                if (objectPropertySets.Count > 0)
                {
                    objectPropertySets.Pop();
                }

                continue;
            }

            if (reader.TokenType == JsonTokenType.PropertyName && objectPropertySets.Count > 0)
            {
                string propertyName = reader.GetString() ?? string.Empty;
                if (!objectPropertySets.Peek().Add(propertyName))
                {
                    duplicates.Add(propertyName);
                }
            }
        }

        return duplicates;
    }

    private static string ResolveTranslationsDirectory()
    {
        string? dir = AppDomain.CurrentDomain.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrEmpty(dir); i++)
        {
            string candidate = Path.Combine(dir, "data", "translations");
            if (File.Exists(Path.Combine(candidate, "en.json")))
            {
                return candidate;
            }

            dir = Directory.GetParent(dir)?.FullName;
        }

        throw new DirectoryNotFoundException("Unable to locate data/translations/en.json from test base directory.");
    }

    private sealed record LocaleFile(
        string LocaleId,
        string Name,
        int Version,
        Dictionary<string, string> FlattenedValues);
}
