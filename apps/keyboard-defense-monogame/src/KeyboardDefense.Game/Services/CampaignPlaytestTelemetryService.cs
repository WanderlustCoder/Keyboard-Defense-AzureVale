using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace KeyboardDefense.Game.Services;

public static class CampaignPlaytestTelemetryService
{
    private const string FileName = "campaign_playtest_telemetry.json";

    private static readonly object Sync = new();
    private static bool _loaded;
    private static TelemetrySnapshot _snapshot = new();

    public static void RecordMapEntered()
    {
        Mutate(s => s.MapVisits++);
    }

    public static void RecordTraversalModeToggled(string mode)
    {
        Mutate(s => Increment(s.TraversalModeToggleCount, Sanitize(mode)));
    }

    public static void RecordLaunchPromptShown(string nodeId)
    {
        Mutate(s =>
        {
            s.LaunchPromptCount++;
            Increment(s.LaunchPromptByNode, Sanitize(nodeId));
        });
    }

    public static void RecordLaunchConfirmed(string nodeId, string inputMode)
    {
        Mutate(s =>
        {
            s.LaunchConfirmedCount++;
            Increment(s.LaunchConfirmedByNode, Sanitize(nodeId));
            Increment(s.LaunchConfirmedByInputMode, Sanitize(inputMode));
        });
    }

    public static void RecordReturnContextShown(
        string nodeId,
        CampaignProgressionService.CampaignOutcomeTone tone)
    {
        Mutate(s =>
        {
            s.ReturnContextShownCount++;
            Increment(s.ReturnContextByNode, Sanitize(nodeId));
            Increment(s.ReturnContextToneCount, tone.ToString());
        });
    }

    public static void RecordOnboardingShown()
    {
        Mutate(s => s.OnboardingShownCount++);
    }

    public static void RecordOnboardingCompleted()
    {
        Mutate(s => s.OnboardingCompletedCount++);
    }

    public static TelemetrySnapshot GetSnapshot()
    {
        lock (Sync)
        {
            EnsureLoaded();
            return _snapshot.Clone();
        }
    }

    private static void Mutate(Action<TelemetrySnapshot> change)
    {
        lock (Sync)
        {
            EnsureLoaded();
            change(_snapshot);
            _snapshot.LastUpdatedUtc = DateTime.UtcNow.ToString("O");
            Save();
        }
    }

    private static void Increment(Dictionary<string, int> map, string key)
    {
        if (map.TryGetValue(key, out int count))
            map[key] = count + 1;
        else
            map[key] = 1;
    }

    private static string Sanitize(string? value)
    {
        string normalized = (value ?? string.Empty).Trim();
        return string.IsNullOrWhiteSpace(normalized) ? "unknown" : normalized;
    }

    private static void EnsureLoaded()
    {
        if (_loaded)
            return;

        _loaded = true;
        string path = GetFilePath();
        if (!File.Exists(path))
            return;

        try
        {
            string json = File.ReadAllText(path);
            var loaded = JsonSerializer.Deserialize<TelemetrySnapshot>(json);
            if (loaded != null)
                _snapshot = loaded;
        }
        catch
        {
            // ignore malformed telemetry and keep fresh snapshot
        }
    }

    private static void Save()
    {
        try
        {
            string path = GetFilePath();
            var options = new JsonSerializerOptions { WriteIndented = true };
            string json = JsonSerializer.Serialize(_snapshot, options);
            File.WriteAllText(path, json);
        }
        catch
        {
            // telemetry must never break runtime flow
        }
    }

    private static string GetFilePath()
    {
        string dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "KeyboardDefense");
        Directory.CreateDirectory(dir);
        return Path.Combine(dir, FileName);
    }

    public sealed class TelemetrySnapshot
    {
        public int MapVisits { get; set; }
        public int OnboardingShownCount { get; set; }
        public int OnboardingCompletedCount { get; set; }
        public int LaunchPromptCount { get; set; }
        public int LaunchConfirmedCount { get; set; }
        public int ReturnContextShownCount { get; set; }
        public string LastUpdatedUtc { get; set; } = string.Empty;
        public Dictionary<string, int> TraversalModeToggleCount { get; set; } = new();
        public Dictionary<string, int> LaunchPromptByNode { get; set; } = new();
        public Dictionary<string, int> LaunchConfirmedByNode { get; set; } = new();
        public Dictionary<string, int> LaunchConfirmedByInputMode { get; set; } = new();
        public Dictionary<string, int> ReturnContextByNode { get; set; } = new();
        public Dictionary<string, int> ReturnContextToneCount { get; set; } = new();

        public TelemetrySnapshot Clone()
        {
            return new TelemetrySnapshot
            {
                MapVisits = MapVisits,
                OnboardingShownCount = OnboardingShownCount,
                OnboardingCompletedCount = OnboardingCompletedCount,
                LaunchPromptCount = LaunchPromptCount,
                LaunchConfirmedCount = LaunchConfirmedCount,
                ReturnContextShownCount = ReturnContextShownCount,
                LastUpdatedUtc = LastUpdatedUtc,
                TraversalModeToggleCount = new Dictionary<string, int>(TraversalModeToggleCount),
                LaunchPromptByNode = new Dictionary<string, int>(LaunchPromptByNode),
                LaunchConfirmedByNode = new Dictionary<string, int>(LaunchConfirmedByNode),
                LaunchConfirmedByInputMode = new Dictionary<string, int>(LaunchConfirmedByInputMode),
                ReturnContextByNode = new Dictionary<string, int>(ReturnContextByNode),
                ReturnContextToneCount = new Dictionary<string, int>(ReturnContextToneCount),
            };
        }
    }
}
