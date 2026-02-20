using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace KeyboardDefense.Core.Data;

/// <summary>
/// Loads and manages narrative content from story.json.
/// Provides access to acts, dialogue, lesson intros, enemy taunts,
/// performance feedback, and lore.
/// </summary>
public class StoryManager
{
    private static StoryManager? _instance;
    public static StoryManager Instance => _instance ??= new();

    private List<StoryAct> _acts = new();
    private Dictionary<string, DialogueEntry> _dialogue = new();
    private Dictionary<string, LessonIntro> _lessonIntros = new();
    private Dictionary<string, List<string>> _enemyTaunts = new();
    private Dictionary<string, PerformanceTier> _performanceFeedback = new();
    private LoreData _lore = new();
    private string _title = "";
    private string _subtitle = "";
    private bool _loaded;

    public string Title => _title;
    public string Subtitle => _subtitle;
    public bool IsLoaded => _loaded;

    public void LoadData(string dataDirectory)
    {
        string path = Path.Combine(dataDirectory, "story.json");
        if (!File.Exists(path)) return;

        try
        {
            string json = File.ReadAllText(path);
            var root = JObject.Parse(json);
            _title = root["title"]?.ToString() ?? "";
            _subtitle = root["subtitle"]?.ToString() ?? "";
            ParseActs(root["acts"] as JArray);
            ParseDialogue(root["dialogue"] as JObject);
            ParseLessonIntros(root["lesson_introductions"] as JObject);
            ParseEnemyTaunts(root["enemy_taunts"] as JObject);
            ParsePerformanceFeedback(root["performance_feedback"] as JObject);
            ParseLore(root["lore"] as JObject);
            _loaded = true;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load story.json: {ex.Message}");
        }
    }

    // --- Act Access ---

    public IReadOnlyList<StoryAct> GetActs() => _acts;

    public StoryAct? GetActForDay(int day)
    {
        return _acts.FirstOrDefault(a => day >= a.DayStart && day <= a.DayEnd);
    }

    public StoryAct? GetAct(string actId)
    {
        return _acts.FirstOrDefault(a => a.Id == actId);
    }

    public bool IsBossDay(int day)
    {
        return _acts.Any(a => a.BossDay == day);
    }

    public StoryAct? GetActWithBoss(int day)
    {
        return _acts.FirstOrDefault(a => a.BossDay == day);
    }

    // --- Dialogue Access ---

    public DialogueEntry? GetDialogue(string context)
    {
        _dialogue.TryGetValue(context, out var entry);
        return entry;
    }

    /// <summary>
    /// Get dialogue with variable substitution.
    /// Supports: {boss_name}, {act_name}, {lesson_name}, {day}, {player_name}
    /// </summary>
    public List<string> GetDialogueLines(string context, Dictionary<string, string>? vars = null)
    {
        var entry = GetDialogue(context);
        if (entry == null) return new();
        if (vars == null) return new(entry.Lines);
        return entry.Lines.Select(line => SubstituteVars(line, vars)).ToList();
    }

    public string GetDialogueSpeaker(string context)
    {
        var entry = GetDialogue(context);
        return entry?.Speaker ?? "Elder Lyra";
    }

    // --- Lesson Intros ---

    public LessonIntro? GetLessonIntro(string lessonId)
    {
        _lessonIntros.TryGetValue(lessonId, out var intro);
        return intro;
    }

    // --- Enemy Taunts ---

    public string GetRandomTaunt(string enemyKind, Random? rng = null)
    {
        if (!_enemyTaunts.TryGetValue(enemyKind, out var taunts) || taunts.Count == 0)
            return "";
        rng ??= Random.Shared;
        return taunts[rng.Next(taunts.Count)];
    }

    // --- Performance Feedback ---

    public string GetPerformanceFeedback(string category, double value, Random? rng = null)
    {
        if (!_performanceFeedback.TryGetValue(category, out var tier))
            return "";
        rng ??= Random.Shared;

        // Find the highest threshold the value meets
        var sorted = tier.Levels.OrderByDescending(l => l.Threshold).ToList();
        foreach (var level in sorted)
        {
            if (value >= level.Threshold && level.Messages.Count > 0)
                return level.Messages[rng.Next(level.Messages.Count)];
        }
        // Fallback to lowest tier
        var lowest = sorted.LastOrDefault();
        if (lowest != null && lowest.Messages.Count > 0)
            return lowest.Messages[rng.Next(lowest.Messages.Count)];
        return "";
    }

    // --- Lore ---

    public LoreData GetLore() => _lore;

    // --- Parsing ---

    private void ParseActs(JArray? acts)
    {
        if (acts == null) return;
        foreach (var act in acts)
        {
            var days = act["days"] as JArray;
            var boss = act["boss"];
            var mentor = act["mentor"];
            _acts.Add(new StoryAct
            {
                Id = act["id"]?.ToString() ?? "",
                Name = act["name"]?.ToString() ?? "",
                DayStart = days?.Count > 0 ? days[0]!.Value<int>() : 0,
                DayEnd = days?.Count > 1 ? days[1]!.Value<int>() : 0,
                Lessons = act["lessons"]?.ToObject<List<string>>() ?? new(),
                Theme = act["theme"]?.ToString() ?? "",
                IntroText = act["intro_text"]?.ToString() ?? "",
                CompletionText = act["completion_text"]?.ToString() ?? "",
                Reward = act["reward"]?.ToString() ?? "",
                MentorName = mentor?["name"]?.ToString() ?? "Elder Lyra",
                MentorPortrait = mentor?["portrait"]?.ToString() ?? "lyra",
                BossKind = boss?["kind"]?.ToString() ?? "",
                BossName = boss?["name"]?.ToString() ?? "",
                BossDay = boss?["day"]?.Value<int>() ?? 0,
                BossIntro = boss?["intro"]?.ToString() ?? "",
                BossTaunt = boss?["taunt"]?.ToString() ?? "",
                BossDefeat = boss?["defeat"]?.ToString() ?? "",
                BossLore = boss?["lore"]?.ToString() ?? "",
            });
        }
    }

    private void ParseDialogue(JObject? dialogue)
    {
        if (dialogue == null) return;
        foreach (var (key, value) in dialogue)
        {
            if (value == null) continue;
            _dialogue[key] = new DialogueEntry
            {
                Speaker = value["speaker"]?.ToString() ?? "Elder Lyra",
                Lines = value["lines"]?.ToObject<List<string>>() ?? new(),
            };
        }
    }

    private void ParseLessonIntros(JObject? intros)
    {
        if (intros == null) return;
        foreach (var (key, value) in intros)
        {
            if (value == null) continue;
            _lessonIntros[key] = new LessonIntro
            {
                Speaker = value["speaker"]?.ToString() ?? "Elder Lyra",
                Title = value["title"]?.ToString() ?? "",
                Lines = value["lines"]?.ToObject<List<string>>() ?? new(),
                Keys = value["keys"]?.ToObject<List<string>>() ?? new(),
                PracticeTips = value["practice_tips"]?.ToObject<List<string>>() ?? new(),
            };
        }
    }

    private void ParseEnemyTaunts(JObject? taunts)
    {
        if (taunts == null) return;
        foreach (var (key, value) in taunts)
        {
            if (value is JArray arr)
                _enemyTaunts[key] = arr.ToObject<List<string>>() ?? new();
        }
    }

    private void ParsePerformanceFeedback(JObject? feedback)
    {
        if (feedback == null) return;
        foreach (var (category, catValue) in feedback)
        {
            if (catValue is not JObject catObj) continue;
            var tier = new PerformanceTier();
            foreach (var (levelName, levelValue) in catObj)
            {
                if (levelValue is not JObject levelObj) continue;
                tier.Levels.Add(new PerformanceLevel
                {
                    Name = levelName,
                    Threshold = levelObj["threshold"]?.Value<double>() ?? 0,
                    Messages = levelObj["messages"]?.ToObject<List<string>>() ?? new(),
                });
            }
            _performanceFeedback[category] = tier;
        }
    }

    private void ParseLore(JObject? lore)
    {
        if (lore == null) return;
        var kingdom = lore["kingdom"];
        if (kingdom != null)
        {
            _lore.KingdomName = kingdom["name"]?.ToString() ?? "";
            _lore.KingdomDescription = kingdom["description"]?.ToString() ?? "";
            _lore.KingdomHistory = kingdom["history"]?.ToString() ?? "";
        }
        var horde = lore["typhos_horde"];
        if (horde != null)
        {
            _lore.HordeName = horde["name"]?.ToString() ?? "";
            _lore.HordeDescription = horde["description"]?.ToString() ?? "";
            _lore.HordeWeakness = horde["weakness"]?.ToString() ?? "";
        }
        var characters = lore["characters"] as JObject;
        if (characters != null)
        {
            foreach (var (charId, charData) in characters)
            {
                if (charData == null) continue;
                _lore.Characters[charId] = new CharacterLore
                {
                    Name = charData["name"]?.ToString() ?? "",
                    Title = charData["title"]?.ToString() ?? "",
                    Description = charData["description"]?.ToString() ?? "",
                    Backstory = charData["backstory"]?.ToString() ?? "",
                    Quotes = charData["quotes"]?.ToObject<List<string>>() ?? new(),
                };
            }
        }
    }

    private static string SubstituteVars(string line, Dictionary<string, string> vars)
    {
        foreach (var (key, value) in vars)
            line = line.Replace($"{{{key}}}", value);
        return line;
    }
}

// --- Data Classes ---

public class StoryAct
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public int DayStart { get; set; }
    public int DayEnd { get; set; }
    public List<string> Lessons { get; set; } = new();
    public string Theme { get; set; } = "";
    public string IntroText { get; set; } = "";
    public string CompletionText { get; set; } = "";
    public string Reward { get; set; } = "";
    public string MentorName { get; set; } = "Elder Lyra";
    public string MentorPortrait { get; set; } = "lyra";
    public string BossKind { get; set; } = "";
    public string BossName { get; set; } = "";
    public int BossDay { get; set; }
    public string BossIntro { get; set; } = "";
    public string BossTaunt { get; set; } = "";
    public string BossDefeat { get; set; } = "";
    public string BossLore { get; set; } = "";
}

public class DialogueEntry
{
    public string Speaker { get; set; } = "";
    public List<string> Lines { get; set; } = new();
}

public class LessonIntro
{
    public string Speaker { get; set; } = "";
    public string Title { get; set; } = "";
    public List<string> Lines { get; set; } = new();
    public List<string> Keys { get; set; } = new();
    public List<string> PracticeTips { get; set; } = new();
}

public class PerformanceTier
{
    public List<PerformanceLevel> Levels { get; set; } = new();
}

public class PerformanceLevel
{
    public string Name { get; set; } = "";
    public double Threshold { get; set; }
    public List<string> Messages { get; set; } = new();
}

public class LoreData
{
    public string KingdomName { get; set; } = "";
    public string KingdomDescription { get; set; } = "";
    public string KingdomHistory { get; set; } = "";
    public string HordeName { get; set; } = "";
    public string HordeDescription { get; set; } = "";
    public string HordeWeakness { get; set; } = "";
    public Dictionary<string, CharacterLore> Characters { get; set; } = new();
}

public class CharacterLore
{
    public string Name { get; set; } = "";
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public string Backstory { get; set; } = "";
    public List<string> Quotes { get; set; } = new();
}
