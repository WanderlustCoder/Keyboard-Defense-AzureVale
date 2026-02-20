using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace KeyboardDefense.Core.Typing;

/// <summary>
/// Persistent per-lesson completion data: star ratings, best WPM/accuracy.
/// Saved alongside the typing profile in the saves directory.
/// </summary>
public class LessonProgress
{
    private static LessonProgress? _instance;
    public static LessonProgress Instance => _instance ??= new();

    private const string FileName = "lesson_progress.json";

    /// <summary>Per-lesson best results keyed by lesson ID.</summary>
    public Dictionary<string, LessonResult> Results { get; set; } = new();

    /// <summary>Get or create the result entry for a lesson.</summary>
    public LessonResult GetResult(string lessonId)
    {
        if (!Results.TryGetValue(lessonId, out var result))
        {
            result = new LessonResult();
            Results[lessonId] = result;
        }
        return result;
    }

    /// <summary>
    /// Record a completed lesson attempt. Updates best scores and star rating.
    /// Returns the star rating achieved this attempt.
    /// </summary>
    public int RecordAttempt(string lessonId, double wpm, double accuracy, int wordsCompleted, int totalErrors)
    {
        var result = GetResult(lessonId);
        int stars = CalculateStars(wpm, accuracy);

        result.Attempts++;
        result.LastPlayedUtc = DateTime.UtcNow;

        if (wpm > result.BestWpm)
            result.BestWpm = wpm;
        if (accuracy > result.BestAccuracy)
            result.BestAccuracy = accuracy;
        if (stars > result.Stars)
            result.Stars = stars;
        if (wordsCompleted > result.BestWordsCompleted)
            result.BestWordsCompleted = wordsCompleted;

        return stars;
    }

    /// <summary>
    /// Calculate star rating: 3 = >95% accuracy + >30 WPM, 2 = >85% accuracy, 1 = completed.
    /// </summary>
    public static int CalculateStars(double wpm, double accuracy)
    {
        if (accuracy >= 0.95 && wpm >= 30)
            return 3;
        if (accuracy >= 0.85)
            return 2;
        return 1;
    }

    /// <summary>Get star rating for a lesson (0 if never completed).</summary>
    public int GetStars(string lessonId)
    {
        return Results.TryGetValue(lessonId, out var result) ? result.Stars : 0;
    }

    /// <summary>Check if a lesson has been completed at least once.</summary>
    public bool IsCompleted(string lessonId)
    {
        return Results.TryGetValue(lessonId, out var result) && result.Attempts > 0;
    }

    /// <summary>Get total stars earned across all lessons.</summary>
    public int GetTotalStars()
    {
        int total = 0;
        foreach (var result in Results.Values)
            total += result.Stars;
        return total;
    }

    /// <summary>Get count of completed lessons (at least 1 star).</summary>
    public int GetCompletedCount()
    {
        int count = 0;
        foreach (var result in Results.Values)
            if (result.Stars > 0) count++;
        return count;
    }

    /// <summary>Format stars as a display string (e.g., "***" or "--*").</summary>
    public static string FormatStars(int stars)
    {
        return stars switch
        {
            0 => "---",
            1 => "*--",
            2 => "**-",
            3 => "***",
            _ => "***",
        };
    }

    // --- Persistence ---

    public void Save(string directory)
    {
        try
        {
            Directory.CreateDirectory(directory);
            string json = JsonConvert.SerializeObject(Results, Formatting.Indented);
            File.WriteAllText(Path.Combine(directory, FileName), json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to save lesson progress: {ex.Message}");
        }
    }

    public void Load(string directory)
    {
        string path = Path.Combine(directory, FileName);
        if (!File.Exists(path)) return;
        try
        {
            string json = File.ReadAllText(path);
            var data = JsonConvert.DeserializeObject<Dictionary<string, LessonResult>>(json);
            if (data != null)
                Results = data;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load lesson progress: {ex.Message}");
        }
    }

    public void Reset()
    {
        Results.Clear();
    }
}

/// <summary>Per-lesson completion record with best scores.</summary>
public class LessonResult
{
    public int Stars { get; set; }
    public double BestWpm { get; set; }
    public double BestAccuracy { get; set; }
    public int BestWordsCompleted { get; set; }
    public int Attempts { get; set; }
    public DateTime LastPlayedUtc { get; set; }
}
