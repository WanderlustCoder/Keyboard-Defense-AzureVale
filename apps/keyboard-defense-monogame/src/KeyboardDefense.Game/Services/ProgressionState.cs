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
    /// <summary>
    /// Gets the singleton progression state instance used by runtime services.
    /// </summary>
    public static ProgressionState Instance => _instance ??= new();

    private const string FileName = "progression.json";

    // Lifetime stats
    /// <summary>
    /// Gets or sets the highest day survived across all recorded runs.
    /// </summary>
    public int HighestDayReached { get; set; }
    /// <summary>
    /// Gets or sets the total number of completed game sessions.
    /// </summary>
    public int TotalGamesPlayed { get; set; }
    /// <summary>
    /// Gets or sets the total number of victorious sessions.
    /// </summary>
    public int TotalVictories { get; set; }
    /// <summary>
    /// Gets or sets the cumulative number of defeated enemies.
    /// </summary>
    public int TotalEnemiesDefeated { get; set; }
    /// <summary>
    /// Gets or sets the cumulative number of words typed in recorded sessions.
    /// </summary>
    public int TotalWordsTyped { get; set; }
    /// <summary>
    /// Gets or sets the best words-per-minute value achieved.
    /// </summary>
    public double BestWpm { get; set; }
    /// <summary>
    /// Gets or sets the best typing accuracy value achieved.
    /// </summary>
    public double BestAccuracy { get; set; }

    // Unlocks
    /// <summary>
    /// Gets or sets the lesson identifiers currently unlocked for play.
    /// </summary>
    public HashSet<string> UnlockedLessons { get; set; } = new() { "home_row", "full_alpha" };
    /// <summary>
    /// Gets or sets the hero identifiers unlocked in progression.
    /// </summary>
    public HashSet<string> UnlockedHeroes { get; set; } = new();
    /// <summary>
    /// Gets or sets the title identifiers unlocked by the player.
    /// </summary>
    public HashSet<string> UnlockedTitles { get; set; } = new();
    /// <summary>
    /// Gets or sets the badge identifiers unlocked by the player.
    /// </summary>
    public HashSet<string> UnlockedBadges { get; set; } = new();
    /// <summary>
    /// Gets or sets the achievement identifiers completed by the player.
    /// </summary>
    public HashSet<string> CompletedAchievements { get; set; } = new();

    // Completed nodes (legacy int-based)
    /// <summary>
    /// Gets or sets completed legacy node identifiers that use integer IDs.
    /// </summary>
    public HashSet<int> CompletedNodes { get; set; } = new();
    /// <summary>
    /// Gets or sets the highest legacy node index completed so far.
    /// </summary>
    public int FurthestNode { get; set; }

    // Completed nodes (string-based)
    /// <summary>
    /// Gets or sets completed node identifiers for string-based progression graphs.
    /// </summary>
    public HashSet<string> CompletedNodeIds { get; set; } = new();
    /// <summary>
    /// Gets or sets the current accumulated progression currency.
    /// </summary>
    public int Gold { get; set; }

    // Preferences
    /// <summary>
    /// Gets or sets the last selected lesson identifier.
    /// </summary>
    public string LastLessonId { get; set; } = "full_alpha";
    /// <summary>
    /// Gets or sets the last selected hero identifier.
    /// </summary>
    public string LastHeroId { get; set; } = "";
    /// <summary>
    /// Gets or sets the last seed value used for run generation.
    /// </summary>
    public string LastSeed { get; set; } = "";

    /// <summary>
    /// Records end-of-run stats, updates best values, and persists the state.
    /// </summary>
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

    /// <summary>
    /// Unlocks a lesson identifier and saves if this call adds a new lesson.
    /// </summary>
    public void UnlockLesson(string lessonId)
    {
        if (UnlockedLessons.Add(lessonId)) Save();
    }

    /// <summary>
    /// Marks a legacy integer node as completed and updates furthest progress.
    /// </summary>
    public void CompleteNode(int nodeId)
    {
        CompletedNodes.Add(nodeId);
        if (nodeId > FurthestNode) FurthestNode = nodeId;
        Save();
    }

    /// <summary>
    /// Marks a string-based node as completed, applies rewards, and saves.
    /// </summary>
    public void CompleteNode(string nodeId, int rewardGold = 0)
    {
        if (CompletedNodeIds.Add(nodeId))
        {
            Gold += rewardGold;
            Save();
        }
    }

    /// <summary>
    /// Returns whether the provided string-based node identifier is completed.
    /// </summary>
    public bool IsNodeCompleted(string nodeId) => CompletedNodeIds.Contains(nodeId);

    /// <summary>
    /// Returns whether a node is unlocked based on its prerequisite node identifiers.
    /// </summary>
    public bool IsNodeUnlocked(string nodeId, List<string> requires)
    {
        if (requires.Count == 0) return true;
        foreach (string req in requires)
        {
            if (!CompletedNodeIds.Contains(req)) return false;
        }
        return true;
    }

    /// <summary>
    /// Serializes and saves progression state to the per-user progression file.
    /// </summary>
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

    /// <summary>
    /// Loads progression state from disk and replaces in-memory values if present.
    /// </summary>
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
