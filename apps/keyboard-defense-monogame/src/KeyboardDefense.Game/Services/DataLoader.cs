using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.World;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Loads all JSON data files at game startup.
/// Resolves the data directory and calls each loader.
/// </summary>
public static class DataLoader
{
    public static string DataDirectory { get; private set; } = "";

    public static void LoadAll()
    {
        DataDirectory = ResolveDataDir();

        BuildingsData.LoadData(DataDirectory);
        LessonsData.LoadData(DataDirectory);
        FactionsData.LoadData(DataDirectory);
        VerticalSliceWaveData.LoadData(DataDirectory);
        StoryManager.Instance.LoadData(DataDirectory);

        LoadEventTables(DataDirectory);
        LoadPois(DataDirectory);
        LoadTranslations(DataDirectory, Locale.CurrentLocale);
    }

    private static string ResolveDataDir()
    {
        // Check relative to executable first (build output)
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string candidate = Path.Combine(baseDir, "data");
        if (Directory.Exists(candidate))
            return candidate;

        // Fallback: check relative to working directory
        candidate = Path.Combine(Directory.GetCurrentDirectory(), "data");
        if (Directory.Exists(candidate))
            return candidate;

        // Fallback: walk up from base directory (dev environment)
        string? dir = baseDir;
        for (int i = 0; i < 6; i++)
        {
            dir = Path.GetDirectoryName(dir);
            if (dir == null) break;
            candidate = Path.Combine(dir, "data");
            if (Directory.Exists(candidate))
                return candidate;
        }

        // Last resort: return expected path (loaders handle missing files gracefully)
        return Path.Combine(baseDir, "data");
    }

    private static void LoadEventTables(string dataDir)
    {
        var path = Path.Combine(dataDir, "events", "event_tables.json");
        if (!File.Exists(path)) return;
        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);
        var tablesArray = root["tables"] as JArray;
        if (tablesArray == null) return;

        // Convert array of {id, entries[]} into Dictionary<string, List<Dict>>
        var tables = new Dictionary<string, List<Dictionary<string, object>>>();
        foreach (var item in tablesArray)
        {
            var obj = item as JObject;
            if (obj == null) continue;
            string id = obj.Value<string>("id") ?? "";
            if (string.IsNullOrEmpty(id)) continue;
            var entries = obj["entries"]?.ToObject<List<Dictionary<string, object>>>() ?? new();
            tables[id] = entries;
        }
        EventTables.LoadTables(tables);
    }

    private static void LoadPois(string dataDir)
    {
        var path = Path.Combine(dataDir, "pois", "pois.json");
        if (!File.Exists(path)) return;
        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);
        var poisArray = root["pois"] as JArray;
        if (poisArray == null) return;

        // Convert array of {id, ...} into Dictionary<string, Dict>
        var pois = new Dictionary<string, Dictionary<string, object>>();
        foreach (var item in poisArray)
        {
            var obj = item as JObject;
            if (obj == null) continue;
            string id = obj.Value<string>("id") ?? "";
            if (string.IsNullOrEmpty(id)) continue;
            pois[id] = obj.ToObject<Dictionary<string, object>>() ?? new();
        }
        Poi.LoadPois(pois);
    }

    public static void LoadTranslations(string dataDir, string locale)
    {
        var path = Path.Combine(dataDir, "translations", $"{locale}.json");
        if (!File.Exists(path)) return;
        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);

        // Flatten nested JSON into dot-delimited keys: "ui.save" => "Save"
        var translations = new Dictionary<string, string>();
        FlattenJson(root, "", translations);
        Locale.LoadTranslations(translations);
    }

    private static void FlattenJson(JObject obj, string prefix, Dictionary<string, string> result)
    {
        foreach (var prop in obj.Properties())
        {
            string key = string.IsNullOrEmpty(prefix) ? prop.Name : $"{prefix}.{prop.Name}";
            if (prop.Value is JObject nested)
                FlattenJson(nested, key, result);
            else if (prop.Value.Type == JTokenType.String)
                result[key] = prop.Value.Value<string>() ?? "";
        }
    }
}
