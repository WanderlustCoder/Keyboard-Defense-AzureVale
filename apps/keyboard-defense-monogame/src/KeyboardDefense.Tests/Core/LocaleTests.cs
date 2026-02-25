using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

[Collection("LocaleSerial")]
public sealed class LocaleTests : IDisposable
{
    public LocaleTests()
    {
        ResetLocaleState();
    }

    public void Dispose()
    {
        ResetLocaleState();
    }

    [Fact]
    public void CurrentLocale_DefaultsToEnglish()
    {
        Assert.Equal("en", Locale.CurrentLocale);
    }

    [Fact]
    public void SupportedLocales_MatchExpectedIds()
    {
        Assert.Equal(new[] { "en", "es", "de", "fr", "pt" }, Locale.SupportedLocales);
    }

    [Fact]
    public void SetLocale_AppliesSupportedLocale_AndIgnoresUnsupportedLocale()
    {
        Locale.SetLocale("de");
        Assert.Equal("de", Locale.CurrentLocale);

        Locale.SetLocale("xx");
        Assert.Equal("de", Locale.CurrentLocale);
    }

    [Fact]
    public void LoadTranslations_FromEnglishFile_LoadsKnownKeys()
    {
        Locale.LoadTranslations(LoadFlattenedTranslations("en"));

        Assert.True(Locale.HasTranslation("ui.save"));
        Assert.True(Locale.HasTranslation("menu.title"));
        Assert.Equal("Save", Locale.Tr("ui.save"));
        Assert.Equal("KEYBOARD DEFENSE", Locale.Tr("menu.title"));
    }

    [Fact]
    public void Tr_WithPlaceholders_ReplacesNamedTokens()
    {
        Locale.LoadTranslations(LoadFlattenedTranslations("en"));

        var result = Locale.Tr(
            "ui.current_language",
            new Dictionary<string, string> { ["language"] = "English" });

        Assert.Equal("Current Language: English", result);
    }

    [Fact]
    public void Tr_MissingKey_FallsBackToKey()
    {
        Locale.LoadTranslations(new Dictionary<string, string> { ["ui.save"] = "Save" });

        Assert.False(Locale.HasTranslation("ui.missing"));
        Assert.Equal("ui.missing", Locale.Tr("ui.missing"));
    }

    [Fact]
    public void LoadTranslations_ReplacesExistingDictionary()
    {
        Locale.LoadTranslations(new Dictionary<string, string> { ["first"] = "one" });
        Assert.Equal("one", Locale.Tr("first"));

        Locale.LoadTranslations(new Dictionary<string, string> { ["second"] = "two" });

        Assert.Equal("first", Locale.Tr("first"));
        Assert.Equal("two", Locale.Tr("second"));
    }

    [Fact]
    public void TranslationFiles_ParseForAllSupportedLocales()
    {
        foreach (string localeId in new[] { "en", "de", "es", "fr", "pt" })
        {
            var translation = ReadTranslation(localeId);

            Assert.Equal(1, translation.Version);
            Assert.Equal(localeId, translation.LocaleId);
            Assert.False(string.IsNullOrWhiteSpace(translation.Name));
            Assert.NotEmpty(translation.FlattenedValues);
            Assert.True(
                translation.FlattenedValues.ContainsKey("ui.save"),
                $"Expected ui.save translation in locale '{localeId}'.");
        }
    }

    private static void ResetLocaleState()
    {
        Locale.SetLocale("en");
        Locale.LoadTranslations(new Dictionary<string, string>());
    }

    private static Dictionary<string, string> LoadFlattenedTranslations(string localeId)
    {
        return new Dictionary<string, string>(ReadTranslation(localeId).FlattenedValues, StringComparer.Ordinal);
    }

    private static TranslationFile ReadTranslation(string localeId)
    {
        string path = Path.Combine(ResolveTranslationsDirectory(), $"{localeId}.json");
        using var document = JsonDocument.Parse(File.ReadAllText(path));
        JsonElement root = document.RootElement;

        var flattened = new Dictionary<string, string>(StringComparer.Ordinal);
        FlattenJson(root, "", flattened);

        return new TranslationFile(
            Version: TryReadInt(root, "version"),
            LocaleId: TryReadString(root, "locale"),
            Name: TryReadString(root, "name"),
            FlattenedValues: flattened);
    }

    private static void FlattenJson(JsonElement element, string prefix, Dictionary<string, string> result)
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
                FlattenJson(property.Value, key, result);
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

    private sealed record TranslationFile(
        int Version,
        string LocaleId,
        string Name,
        Dictionary<string, string> FlattenedValues);
}

[CollectionDefinition("LocaleSerial", DisableParallelization = true)]
public sealed class LocaleSerialCollection
{
}
