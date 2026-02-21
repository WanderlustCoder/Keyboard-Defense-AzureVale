using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Persistent progression state across game sessions (unlocks, stats, preferences).
/// Ported from scripts/ProgressionState.gd.
/// </summary>
public class ProgressionState
{
    private static ProgressionState? _instance;
    public static ProgressionState Instance => _instance ??= new();

    private const string FileName = "progression.json";

    // Lifetime stats
    public int HighestDayReached { get; set; }
    public int TotalGamesPlayed { get; set; }
    public int TotalVictories { get; set; }
    public int TotalEnemiesDefeated { get; set; }
    public int TotalWordsTyped { get; set; }
    public double BestWpm { get; set; }
    public double BestAccuracy { get; set; }

    // Unlocks
    public HashSet<string> UnlockedLessons { get; set; } = new() { "home_row", "full_alpha" };
    public HashSet<string> UnlockedHeroes { get; set; } = new();
    public HashSet<string> UnlockedTitles { get; set; } = new();
    public HashSet<string> UnlockedBadges { get; set; } = new();
    public HashSet<string> CompletedAchievements { get; set; } = new();

    // Completed nodes (legacy int-based)
    public HashSet<int> CompletedNodes { get; set; } = new();
    public int FurthestNode { get; set; }

    // Completed nodes (string-based)
    public HashSet<string> CompletedNodeIds { get; set; } = new();
    public int Gold { get; set; }

    // Preferences
    public string LastLessonId { get; set; } = "full_alpha";
    public string LastHeroId { get; set; } = "";
    public string LastSeed { get; set; } = "";

    public void RecordGameEnd(bool victory, int day, int enemiesDefeated, int wordsTyped, double wpm, double accuracy)
    {
        TotalGamesPlayed++;
        if (victory) TotalVictories++;
        if (day > HighestDayReached) HighestDayReached = day;
        TotalEnemiesDefeated += enemiesDefeated;
        TotalWordsTyped += wordsTyped;
        if (wpm > BestWpm) BestWpm = wpm;
        if (accuracy > BestAccuracy) BestAccuracy = accuracy;
        Save();
    }

    public void UnlockLesson(string lessonId)
    {
        if (UnlockedLessons.Add(lessonId)) Save();
    }

    public void CompleteNode(int nodeId)
    {
        CompletedNodes.Add(nodeId);
        if (nodeId > FurthestNode) FurthestNode = nodeId;
        Save();
    }

    public void CompleteNode(string nodeId, int rewardGold = 0)
    {
        if (CompletedNodeIds.Add(nodeId))
        {
            Gold += rewardGold;
            Save();
        }
    }

    public bool IsNodeCompleted(string nodeId) => CompletedNodeIds.Contains(nodeId);

    public bool IsNodeUnlocked(string nodeId, List<string> requires)
    {
        if (requires.Count == 0) return true;
        foreach (string req in requires)
        {
            if (!CompletedNodeIds.Contains(req)) return false;
        }
        return true;
    }

    public void Save()
    {
        string dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "KeyboardDefense");
        Directory.CreateDirectory(dir);
        string path = Path.Combine(dir, FileName);
        string json = JsonConvert.SerializeObject(this, Formatting.Indented);
        File.WriteAllText(path, json);
    }

    public void Load()
    {
        string dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "KeyboardDefense");
        string path = Path.Combine(dir, FileName);
        if (!File.Exists(path)) return;

        try
        {
            string json = File.ReadAllText(path);
            var loaded = JsonConvert.DeserializeObject<ProgressionState>(json);
            if (loaded == null) return;

            HighestDayReached = loaded.HighestDayReached;
            TotalGamesPlayed = loaded.TotalGamesPlayed;
            TotalVictories = loaded.TotalVictories;
            TotalEnemiesDefeated = loaded.TotalEnemiesDefeated;
            TotalWordsTyped = loaded.TotalWordsTyped;
            BestWpm = loaded.BestWpm;
            BestAccuracy = loaded.BestAccuracy;
            UnlockedLessons = loaded.UnlockedLessons;
            UnlockedHeroes = loaded.UnlockedHeroes;
            UnlockedTitles = loaded.UnlockedTitles;
            UnlockedBadges = loaded.UnlockedBadges;
            CompletedAchievements = loaded.CompletedAchievements;
            CompletedNodes = loaded.CompletedNodes;
            FurthestNode = loaded.FurthestNode;
            CompletedNodeIds = loaded.CompletedNodeIds ?? new();
            Gold = loaded.Gold;
            LastLessonId = loaded.LastLessonId;
            LastHeroId = loaded.LastHeroId;
            LastSeed = loaded.LastSeed;
        }
        catch
        {
            // Corrupt file - start fresh
        }
    }
}
