using System;
using System.IO;
using Newtonsoft.Json;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Stores minimal vertical-slice profile progression.
/// File is versioned for forward compatibility.
/// </summary>
public static class VerticalSliceProfileService
{
    private const int CurrentVersion = 1;
    private const string FileName = "vertical_slice_profile.json";

    public static VerticalSliceProfile Current { get; private set; } = VerticalSliceProfile.CreateDefault();

    public static void Load()
    {
        Current = VerticalSliceProfile.CreateDefault();
        string path = GetPath();
        if (!File.Exists(path))
            return;

        try
        {
            string json = File.ReadAllText(path);
            var loaded = JsonConvert.DeserializeObject<VerticalSliceProfile>(json);
            if (loaded == null)
                return;

            if (loaded.Version <= 0)
                loaded.Version = CurrentVersion;

            Current = loaded;
        }
        catch
        {
            Current = VerticalSliceProfile.CreateDefault();
        }
    }

    public static void RecordRun(string result, int score, int elapsedSeconds)
    {
        var profile = Current;
        profile.Version = CurrentVersion;
        profile.RunsPlayed = Math.Max(0, profile.RunsPlayed) + 1;
        profile.LastScore = Math.Max(0, score);
        profile.LastElapsedSeconds = Math.Max(0, elapsedSeconds);
        profile.LastResult = string.IsNullOrWhiteSpace(result) ? "unknown" : result.Trim().ToLowerInvariant();
        profile.BestScore = Math.Max(profile.BestScore, profile.LastScore);
        profile.UpdatedUtc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");
        Current = profile;
        Save();
    }

    public static void Save()
    {
        try
        {
            SaveService.EnsureSaveDirectory();
            string baseDir = SaveService.GetBaseDir();
            Directory.CreateDirectory(baseDir);

            string path = GetPath();
            string json = JsonConvert.SerializeObject(Current, Formatting.Indented);
            File.WriteAllText(path, json);
        }
        catch
        {
            // Intentionally swallow file system failures.
        }
    }

    private static string GetPath()
    {
        return Path.Combine(SaveService.GetBaseDir(), FileName);
    }
}

public sealed class VerticalSliceProfile
{
    [JsonProperty("version")]
    public int Version { get; set; } = 1;

    [JsonProperty("runs_played")]
    public int RunsPlayed { get; set; }

    [JsonProperty("last_score")]
    public int LastScore { get; set; }

    [JsonProperty("best_score")]
    public int BestScore { get; set; }

    [JsonProperty("last_result")]
    public string LastResult { get; set; } = "unknown";

    [JsonProperty("last_elapsed_seconds")]
    public int LastElapsedSeconds { get; set; }

    [JsonProperty("updated_utc")]
    public string UpdatedUtc { get; set; } = "";

    public static VerticalSliceProfile CreateDefault() => new()
    {
        Version = 1,
        RunsPlayed = 0,
        LastScore = 0,
        BestScore = 0,
        LastResult = "unknown",
        LastElapsedSeconds = 0,
        UpdatedUtc = ""
    };
}

