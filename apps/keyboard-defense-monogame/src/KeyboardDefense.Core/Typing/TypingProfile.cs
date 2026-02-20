using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Persistent typing profile that tracks per-key accuracy, WPM history,
/// and session data across play sessions. Supports adaptive difficulty
/// by identifying weak keys and recommending lessons.
/// </summary>
public class TypingProfile
{
    private static TypingProfile? _instance;
    public static TypingProfile Instance => _instance ??= new();

    public const int MaxSessionHistory = 20;
    public const int MinSamplesForWeakKey = 10;
    public const double WeakKeyThreshold = 0.75;
    public const double StrongKeyThreshold = 0.92;

    /// <summary>Per-character accuracy tracking (lowercase chars).</summary>
    public Dictionary<char, KeyAccuracy> KeyStats { get; set; } = new();

    /// <summary>Session summaries, newest last, capped at MaxSessionHistory.</summary>
    public List<SessionSummary> Sessions { get; set; } = new();

    /// <summary>Total characters typed across all sessions.</summary>
    public int TotalCharsTyped { get; set; }

    /// <summary>Total words typed across all sessions.</summary>
    public int TotalWordsTyped { get; set; }

    /// <summary>Total errors across all sessions.</summary>
    public int TotalErrors { get; set; }

    /// <summary>Total play time in seconds across all sessions.</summary>
    public double TotalPlayTimeSeconds { get; set; }

    // --- Recording Methods ---

    /// <summary>Record a correct character typed.</summary>
    public void RecordCorrectChar(char c)
    {
        char key = char.ToLower(c);
        if (!char.IsLetterOrDigit(key) && key != ' ') return;
        var stats = GetOrCreateKey(key);
        stats.Correct++;
        stats.Total++;
        TotalCharsTyped++;
    }

    /// <summary>Record a mistyped character (expected vs actual).</summary>
    public void RecordError(char expected, char actual)
    {
        char expKey = char.ToLower(expected);
        if (char.IsLetterOrDigit(expKey) || expKey == ' ')
        {
            var stats = GetOrCreateKey(expKey);
            stats.Total++;
        }
        TotalErrors++;
    }

    /// <summary>Record a completed practice/battle session.</summary>
    public void RecordSession(double wpm, double accuracy, int wordsTyped, int errors, double durationSec, string? lessonId = null)
    {
        var summary = new SessionSummary
        {
            Wpm = wpm,
            Accuracy = accuracy,
            WordsTyped = wordsTyped,
            Errors = errors,
            DurationSeconds = durationSec,
            LessonId = lessonId ?? "",
            Timestamp = DateTime.UtcNow,
        };
        Sessions.Add(summary);
        while (Sessions.Count > MaxSessionHistory)
            Sessions.RemoveAt(0);

        TotalWordsTyped += wordsTyped;
        TotalPlayTimeSeconds += durationSec;
    }

    // --- Analysis Methods ---

    /// <summary>Get per-key accuracy ratio (0.0-1.0). Returns -1 if insufficient data.</summary>
    public double GetKeyAccuracy(char c)
    {
        char key = char.ToLower(c);
        if (!KeyStats.TryGetValue(key, out var stats)) return -1;
        if (stats.Total < MinSamplesForWeakKey) return -1;
        return (double)stats.Correct / stats.Total;
    }

    /// <summary>Get characters with accuracy below WeakKeyThreshold, sorted weakest first.</summary>
    public List<char> GetWeakKeys()
    {
        return KeyStats
            .Where(kv => kv.Value.Total >= MinSamplesForWeakKey)
            .Where(kv => (double)kv.Value.Correct / kv.Value.Total < WeakKeyThreshold)
            .OrderBy(kv => (double)kv.Value.Correct / kv.Value.Total)
            .Select(kv => kv.Key)
            .ToList();
    }

    /// <summary>Get characters with accuracy above StrongKeyThreshold, sorted strongest first.</summary>
    public List<char> GetStrongKeys()
    {
        return KeyStats
            .Where(kv => kv.Value.Total >= MinSamplesForWeakKey)
            .Where(kv => (double)kv.Value.Correct / kv.Value.Total >= StrongKeyThreshold)
            .OrderByDescending(kv => (double)kv.Value.Correct / kv.Value.Total)
            .Select(kv => kv.Key)
            .ToList();
    }

    /// <summary>Get average WPM from last N sessions.</summary>
    public double GetAverageWpm(int lastN = 5)
    {
        if (Sessions.Count == 0) return 0;
        var recent = Sessions.Skip(Math.Max(0, Sessions.Count - lastN)).ToList();
        return recent.Average(s => s.Wpm);
    }

    /// <summary>Get WPM trend: positive = improving, negative = declining.</summary>
    public double GetWpmTrend()
    {
        if (Sessions.Count < 2) return 0;
        int halfPoint = Sessions.Count / 2;
        var older = Sessions.Take(halfPoint).ToList();
        var newer = Sessions.Skip(halfPoint).ToList();
        if (older.Count == 0 || newer.Count == 0) return 0;
        return newer.Average(s => s.Wpm) - older.Average(s => s.Wpm);
    }

    /// <summary>Get accuracy trend: positive = improving, negative = declining.</summary>
    public double GetAccuracyTrend()
    {
        if (Sessions.Count < 2) return 0;
        int halfPoint = Sessions.Count / 2;
        var older = Sessions.Take(halfPoint).ToList();
        var newer = Sessions.Skip(halfPoint).ToList();
        if (older.Count == 0 || newer.Count == 0) return 0;
        return newer.Average(s => s.Accuracy) - older.Average(s => s.Accuracy);
    }

    /// <summary>Get the overall accuracy rate.</summary>
    public double GetOverallAccuracy()
    {
        int totalCorrect = KeyStats.Values.Sum(k => k.Correct);
        int totalAttempts = KeyStats.Values.Sum(k => k.Total);
        if (totalAttempts == 0) return 1.0;
        return (double)totalCorrect / totalAttempts;
    }

    /// <summary>
    /// Recommend lesson IDs based on weak keys. Maps weak keys to keyboard rows/groups
    /// and suggests appropriate lessons.
    /// </summary>
    public List<string> GetRecommendedLessonIds()
    {
        var weakKeys = GetWeakKeys();
        if (weakKeys.Count == 0) return new List<string>();

        var recommendations = new HashSet<string>();
        foreach (char key in weakKeys)
        {
            string? lessonId = MapKeyToLesson(key);
            if (lessonId != null)
                recommendations.Add(lessonId);
        }
        return recommendations.ToList();
    }

    /// <summary>
    /// Get difficulty level (0.0-1.0) based on current profile.
    /// Used for adaptive word selection: higher = harder words.
    /// </summary>
    public double GetDifficultyLevel()
    {
        double wpm = GetAverageWpm();
        double accuracy = GetOverallAccuracy();

        // Base difficulty from WPM (0-80+ maps to 0.0-1.0)
        double wpmFactor = Math.Clamp(wpm / 80.0, 0, 1);
        // Accuracy factor (below 70% = reduce difficulty)
        double accFactor = accuracy >= 0.7 ? 1.0 : accuracy / 0.7;

        return Math.Clamp(wpmFactor * accFactor, 0, 1);
    }

    /// <summary>Get the finger zone (0-7) for a character.</summary>
    public static int GetFingerZone(char c)
    {
        char lower = char.ToLower(c);
        return lower switch
        {
            'q' or 'a' or 'z' or '1' => 0,  // left pinky
            'w' or 's' or 'x' or '2' => 1,  // left ring
            'e' or 'd' or 'c' or '3' => 2,  // left middle
            'r' or 'f' or 'v' or 't' or 'g' or 'b' or '4' or '5' => 3, // left index
            'y' or 'h' or 'n' or 'u' or 'j' or 'm' or '6' or '7' => 4, // right index
            'i' or 'k' or ',' or '8' => 5,  // right middle
            'o' or 'l' or '.' or '9' => 6,  // right ring
            'p' or ';' or '/' or '0' => 7,  // right pinky
            _ => -1,
        };
    }

    /// <summary>Get the keyboard row name for a character.</summary>
    public static string GetKeyRow(char c)
    {
        char lower = char.ToLower(c);
        if ("qwertyuiop".Contains(lower)) return "top";
        if ("asdfghjkl;".Contains(lower)) return "home";
        if ("zxcvbnm,./".Contains(lower)) return "bottom";
        if ("1234567890".Contains(lower)) return "number";
        return "other";
    }

    // --- Persistence ---

    public void Save(string directory)
    {
        try
        {
            Directory.CreateDirectory(directory);
            string json = JsonConvert.SerializeObject(ToData(), Formatting.Indented);
            File.WriteAllText(Path.Combine(directory, "typing_profile.json"), json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to save typing profile: {ex.Message}");
        }
    }

    public void Load(string directory)
    {
        string path = Path.Combine(directory, "typing_profile.json");
        if (!File.Exists(path)) return;
        try
        {
            string json = File.ReadAllText(path);
            var data = JsonConvert.DeserializeObject<ProfileData>(json);
            if (data != null)
                FromData(data);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load typing profile: {ex.Message}");
        }
    }

    public void Reset()
    {
        KeyStats.Clear();
        Sessions.Clear();
        TotalCharsTyped = 0;
        TotalWordsTyped = 0;
        TotalErrors = 0;
        TotalPlayTimeSeconds = 0;
    }

    // --- Private Helpers ---

    private KeyAccuracy GetOrCreateKey(char key)
    {
        if (!KeyStats.TryGetValue(key, out var stats))
        {
            stats = new KeyAccuracy();
            KeyStats[key] = stats;
        }
        return stats;
    }

    private static string? MapKeyToLesson(char key)
    {
        char lower = char.ToLower(key);
        // Map keys to lesson IDs based on keyboard region
        if ("asdfghjkl".Contains(lower)) return "home_row";
        if ("qwertyuiop".Contains(lower)) return "top_row";
        if ("zxcvbnm".Contains(lower)) return "bottom_row";
        if ("1234567890".Contains(lower)) return "numbers";
        return null;
    }

    private ProfileData ToData() => new()
    {
        KeyStats = KeyStats.ToDictionary(kv => kv.Key.ToString(), kv => new[] { kv.Value.Correct, kv.Value.Total }),
        Sessions = Sessions,
        TotalCharsTyped = TotalCharsTyped,
        TotalWordsTyped = TotalWordsTyped,
        TotalErrors = TotalErrors,
        TotalPlayTimeSeconds = TotalPlayTimeSeconds,
    };

    private void FromData(ProfileData data)
    {
        KeyStats.Clear();
        if (data.KeyStats != null)
        {
            foreach (var (key, vals) in data.KeyStats)
            {
                if (key.Length == 1 && vals.Length >= 2)
                    KeyStats[key[0]] = new KeyAccuracy { Correct = vals[0], Total = vals[1] };
            }
        }
        Sessions = data.Sessions ?? new();
        TotalCharsTyped = data.TotalCharsTyped;
        TotalWordsTyped = data.TotalWordsTyped;
        TotalErrors = data.TotalErrors;
        TotalPlayTimeSeconds = data.TotalPlayTimeSeconds;
    }

    private class ProfileData
    {
        public Dictionary<string, int[]>? KeyStats { get; set; }
        public List<SessionSummary>? Sessions { get; set; }
        public int TotalCharsTyped { get; set; }
        public int TotalWordsTyped { get; set; }
        public int TotalErrors { get; set; }
        public double TotalPlayTimeSeconds { get; set; }
    }
}

/// <summary>Per-character accuracy counter.</summary>
public class KeyAccuracy
{
    public int Correct { get; set; }
    public int Total { get; set; }
    public double Accuracy => Total > 0 ? (double)Correct / Total : 1.0;
}

/// <summary>Summary of one typing session.</summary>
public class SessionSummary
{
    public double Wpm { get; set; }
    public double Accuracy { get; set; }
    public int WordsTyped { get; set; }
    public int Errors { get; set; }
    public double DurationSeconds { get; set; }
    public string LessonId { get; set; } = "";
    public DateTime Timestamp { get; set; }
}
