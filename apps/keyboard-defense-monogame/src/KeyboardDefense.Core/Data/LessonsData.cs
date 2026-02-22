using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Lesson management system. Lazy-loads and caches lesson data.
/// Ported from sim/lessons.gd.
/// </summary>
public static class LessonsData
{
    private static Dictionary<string, LessonEntry>? _cache;
    private static List<GraduationPath>? _paths;

    public static void LoadData(string dataDir)
    {
        var path = Path.Combine(dataDir, "lessons.json");
        _cache = new Dictionary<string, LessonEntry>();
        _paths = new List<GraduationPath>();
        if (!File.Exists(path)) return;
        var text = File.ReadAllText(path);
        var root = JObject.Parse(text);

        // Parse graduation paths
        if (root["graduation_paths"] is JObject pathsObj)
        {
            foreach (var prop in pathsObj.Properties())
            {
                var pathData = prop.Value as JObject;
                if (pathData == null) continue;
                var gp = new GraduationPath
                {
                    Id = prop.Name,
                    Name = pathData.Value<string>("name") ?? prop.Name,
                    Description = pathData.Value<string>("description") ?? "",
                };
                if (pathData["stages"] is JArray stagesArr)
                {
                    foreach (var stageItem in stagesArr)
                    {
                        var stageData = stageItem as JObject;
                        if (stageData == null) continue;
                        gp.Stages.Add(new PathStage
                        {
                            Stage = stageData.Value<int>("stage"),
                            Name = stageData.Value<string>("name") ?? "",
                            Goal = stageData.Value<string>("goal") ?? "",
                            LessonIds = stageData["lessons"]?.ToObject<List<string>>() ?? new(),
                        });
                    }
                }
                _paths.Add(gp);
            }
        }

        // Parse lessons
        var lessons = root["lessons"] as JArray;
        if (lessons == null) return;
        foreach (var item in lessons)
        {
            var data = item as JObject;
            if (data == null) continue;
            string id = data.Value<string>("id") ?? "";
            if (string.IsNullOrEmpty(id)) continue;
            // charset can be a string like "asdf" - split into individual chars
            var charsetRaw = data.Value<string>("charset");
            var charset = charsetRaw != null
                ? charsetRaw.Select(c => c.ToString()).ToList()
                : new List<string>();
            _cache[id] = new LessonEntry
            {
                Id = id,
                Name = data.Value<string>("name") ?? id,
                Description = data.Value<string>("description") ?? "",
                Mode = data.Value<string>("mode") ?? "charset",
                Charset = charset,
                WordList = data["wordlist"]?.ToObject<List<string>>()
                    ?? data["word_pool"]?.ToObject<List<string>>()
                    ?? new(),
                Sentences = data["sentences"]?.ToObject<List<string>>() ?? new(),
                Difficulty = data.Value<int>("difficulty"),
                Category = data.Value<string>("category") ?? "",
            };
        }
    }

    public static IReadOnlyList<string> LessonIds()
    {
        EnsureLoaded();
        var keys = _cache!.Keys;
        var list = new List<string>(keys.Count);
        foreach (var k in keys) list.Add(k);
        return list;
    }

    public static IReadOnlyList<GraduationPath> GetPaths()
    {
        EnsureLoaded();
        return _paths!;
    }

    public static string DefaultLessonId() => "full_alpha";

    public static bool IsValid(string lessonId)
    {
        EnsureLoaded();
        return _cache!.ContainsKey(lessonId);
    }

    public static string NormalizeLessonId(string lessonId)
    {
        if (string.IsNullOrWhiteSpace(lessonId)) return DefaultLessonId();
        var normalized = lessonId.Trim().ToLowerInvariant();
        return IsValid(normalized) ? normalized : DefaultLessonId();
    }

    public static LessonEntry? GetLesson(string lessonId)
    {
        EnsureLoaded();
        return _cache!.GetValueOrDefault(lessonId);
    }

    public static string LessonLabel(string lessonId)
    {
        var lesson = GetLesson(lessonId);
        return lesson?.Name ?? lessonId;
    }

    private static void EnsureLoaded()
    {
        _cache ??= new Dictionary<string, LessonEntry>();
        _paths ??= new List<GraduationPath>();
    }
}

public class LessonEntry
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string Mode { get; set; } = "charset";
    public List<string> Charset { get; set; } = new();
    public List<string> WordList { get; set; } = new();
    public List<string> Sentences { get; set; } = new();
    public int Difficulty { get; set; }
    public string Category { get; set; } = "";
}

public class GraduationPath
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public List<PathStage> Stages { get; set; } = new();
}

public class PathStage
{
    public int Stage { get; set; }
    public string Name { get; set; } = "";
    public string Goal { get; set; } = "";
    public List<string> LessonIds { get; set; } = new();
}
