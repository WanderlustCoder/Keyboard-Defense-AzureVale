using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Progression;

/// <summary>
/// Daily challenge generation and tracking.
/// Generates 3 deterministic challenges per day that scale with player progression.
/// Ported from sim/daily_challenges.gd.
/// </summary>
public static class DailyChallenges
{
    // ---------- legacy template registry (kept for backward compat + tests) ----------
    public static readonly Dictionary<string, DailyChallengeDef> Templates = new()
    {
        ["speed_demon"] = new("Speed Demon", "Achieve 80+ WPM", "typing", 3),
        ["glass_cannon"] = new("Glass Cannon", "Win with only 1 HP remaining", "combat", 5),
        ["swarm_survival"] = new("Swarm Survival", "Survive 20+ enemies in one wave", "combat", 4),
        ["perfect_night"] = new("Perfect Night", "100% accuracy in a night battle", "typing", 5),
        ["economy_king"] = new("Economy King", "Accumulate 200+ gold", "economy", 3),
        ["explorer"] = new("Explorer", "Discover 30 new tiles", "exploration", 3),
        ["combo_master"] = new("Combo Master", "Reach a 30-hit combo", "typing", 4),
        ["tower_defense"] = new("Tower Defense", "Build 5 towers in one day", "building", 3),
        ["minimalist"] = new("Minimalist", "Win a night with no towers", "combat", 6),
        ["wordsmith"] = new("Wordsmith", "Type 100 words without error", "typing", 5),
        ["builder"] = new("Builder", "Construct 10 buildings", "economy", 3),
        ["diplomat"] = new("Diplomat", "Improve relations with 2 factions", "diplomacy", 4),
    };

    public static string GetChallengeForDay(int dayNumber)
    {
        var keys = Templates.Keys.ToArray();
        int index = dayNumber % keys.Length;
        return keys[index];
    }

    public static DailyChallengeDef? GetChallenge(string id) => Templates.GetValueOrDefault(id);

    public static int CalculateStreakBonus(int streakDays)
    {
        if (streakDays >= 7) return 3;
        if (streakDays >= 3) return 2;
        if (streakDays >= 1) return 1;
        return 0;
    }

    // ---------- new typed challenge pool ----------

    public static readonly ChallengeDef[] ChallengePool =
    {
        // DefeatEnemies variants
        new("defeat_10", "Monster Slayer", "Defeat 10 enemies in a single session.", ChallengeType.DefeatEnemies, 10, 15),
        new("defeat_25", "Monster Hunter", "Defeat 25 enemies in a single session.", ChallengeType.DefeatEnemies, 25, 30),
        new("defeat_50", "Exterminator", "Defeat 50 enemies in a single session.", ChallengeType.DefeatEnemies, 50, 50),

        // TypeWords variants
        new("type_20", "Wordsmith", "Type 20 words correctly.", ChallengeType.TypeWords, 20, 10),
        new("type_50", "Scribe", "Type 50 words correctly.", ChallengeType.TypeWords, 50, 25),
        new("type_100", "Chronicler", "Type 100 words correctly.", ChallengeType.TypeWords, 100, 45),

        // PerfectAccuracy
        new("perfect_1", "Flawless Typist", "Complete a night with 100% accuracy.", ChallengeType.PerfectAccuracy, 1, 40),
        new("perfect_2", "Precision Master", "Complete 2 nights with 100% accuracy.", ChallengeType.PerfectAccuracy, 2, 75),

        // ComboStreak variants
        new("combo_5", "Combo Starter", "Achieve a 5-word combo streak.", ChallengeType.ComboStreak, 5, 15),
        new("combo_10", "Combo Adept", "Achieve a 10-word combo streak.", ChallengeType.ComboStreak, 10, 30),
        new("combo_20", "Combo Champion", "Achieve a 20-word combo streak.", ChallengeType.ComboStreak, 20, 50),
        new("combo_30", "Combo Legend", "Achieve a 30-word combo streak.", ChallengeType.ComboStreak, 30, 70),

        // SurviveDays variants
        new("survive_3", "Endurance", "Survive 3 days.", ChallengeType.SurviveDays, 3, 20),
        new("survive_5", "Resilience", "Survive 5 days.", ChallengeType.SurviveDays, 5, 35),
        new("survive_7", "Persistence", "Survive 7 days.", ChallengeType.SurviveDays, 7, 55),

        // SpeedRun variants
        new("speed_120", "Quick Defense", "Complete a night in under 120 seconds.", ChallengeType.SpeedRun, 120, 30),
        new("speed_90", "Swift Defender", "Complete a night in under 90 seconds.", ChallengeType.SpeedRun, 90, 50),
        new("speed_60", "Lightning Fast", "Complete a night in under 60 seconds.", ChallengeType.SpeedRun, 60, 75),

        // NoDamage
        new("no_damage_1", "Untouchable", "Complete a night without taking damage.", ChallengeType.NoDamage, 1, 35),
        new("no_damage_2", "Iron Wall", "Complete 2 nights without taking damage.", ChallengeType.NoDamage, 2, 65),
    };

    /// <summary>
    /// Get today's 3 daily challenges, deterministic based on date and player progression.
    /// </summary>
    public static List<ChallengeDef> GetTodaysChallenges(int highestDayReached = 1)
    {
        return GetChallengesForDate(DateTime.UtcNow, highestDayReached);
    }

    /// <summary>
    /// Get 3 challenges for a specific date. Deterministic: same date + progression tier = same challenges.
    /// </summary>
    public static List<ChallengeDef> GetChallengesForDate(DateTime date, int highestDayReached)
    {
        int dayOfYear = date.DayOfYear + date.Year * 366;
        var rng = new Random(dayOfYear);

        // Determine difficulty tier based on progression
        int tier = highestDayReached switch
        {
            < 5 => 0,   // early game
            < 10 => 1,  // mid game
            < 20 => 2,  // late game
            _ => 3,      // endgame
        };

        // Filter pool to challenges appropriate for difficulty tier
        var eligible = FilterByTier(tier);

        // Shuffle deterministically and pick 3 from different types
        var shuffled = eligible.OrderBy(_ => rng.Next()).ToList();
        var selected = new List<ChallengeDef>(3);
        var usedTypes = new HashSet<ChallengeType>();

        foreach (var challenge in shuffled)
        {
            if (selected.Count >= 3) break;
            if (usedTypes.Contains(challenge.Type)) continue;
            usedTypes.Add(challenge.Type);
            selected.Add(challenge);
        }

        // If we couldn't get 3 distinct types, fill from remaining
        if (selected.Count < 3)
        {
            foreach (var challenge in shuffled)
            {
                if (selected.Count >= 3) break;
                if (selected.Any(c => c.Id == challenge.Id)) continue;
                selected.Add(challenge);
            }
        }

        // Scale rewards with tier
        float rewardMultiplier = 1f + tier * 0.25f;
        return selected.Select(c => c with
        {
            Reward = (int)(c.Reward * rewardMultiplier)
        }).ToList();
    }

    /// <summary>
    /// Check which of today's challenges have been completed given the current game state.
    /// Returns list of newly-completed challenge IDs.
    /// </summary>
    public static List<string> CheckProgress(GameState state)
    {
        var completed = new List<string>();
        var today = GetTodaysChallenges(state.Day);

        foreach (var challenge in today)
        {
            if (state.CompletedDailyChallenges.Contains(challenge.Id)) continue;
            if (IsChallengeComplete(state, challenge))
                completed.Add(challenge.Id);
        }

        return completed;
    }

    /// <summary>
    /// Get current progress value for a challenge given the game state.
    /// Returns (current, target) for progress bar display.
    /// </summary>
    public static (int Current, int Target) GetProgress(GameState state, ChallengeDef challenge)
    {
        int current = challenge.Type switch
        {
            ChallengeType.DefeatEnemies => state.EnemiesDefeated,
            ChallengeType.TypeWords => GetWordsTyped(state),
            ChallengeType.PerfectAccuracy => state.PerfectNightsToday,
            ChallengeType.ComboStreak => state.MaxComboEver,
            ChallengeType.SurviveDays => state.Day,
            ChallengeType.SpeedRun => state.FastestNightSeconds > 0
                ? Math.Min(state.FastestNightSeconds, challenge.Target)
                : 0,
            ChallengeType.NoDamage => state.NoDamageNightsToday,
            _ => 0,
        };

        return (Math.Min(current, challenge.Target), challenge.Target);
    }

    /// <summary>
    /// Complete a daily challenge: mark it done and award gold.
    /// </summary>
    public static Dictionary<string, object> CompleteChallenge(GameState state, string challengeId)
    {
        if (state.CompletedDailyChallenges.Contains(challengeId))
            return new() { ["ok"] = false, ["error"] = "Already completed." };

        var today = GetTodaysChallenges(state.Day);
        var challenge = today.FirstOrDefault(c => c.Id == challengeId);
        if (challenge == null)
            return new() { ["ok"] = false, ["error"] = "Challenge not available today." };

        state.CompletedDailyChallenges.Add(challengeId);
        state.Gold += challenge.Reward;

        return new()
        {
            ["ok"] = true,
            ["message"] = $"Challenge complete: {challenge.Name}! +{challenge.Reward} gold"
        };
    }

    /// <summary>
    /// Get the date key for today (used for tracking which day's challenges are active).
    /// </summary>
    public static string GetTodayKey() => DateTime.UtcNow.ToString("yyyy-MM-dd");

    /// <summary>
    /// Time remaining until next challenge refresh (midnight UTC).
    /// </summary>
    public static TimeSpan TimeUntilRefresh()
    {
        var now = DateTime.UtcNow;
        var tomorrow = now.Date.AddDays(1);
        return tomorrow - now;
    }

    private static bool IsChallengeComplete(GameState state, ChallengeDef challenge)
    {
        var (current, target) = GetProgress(state, challenge);
        return challenge.Type == ChallengeType.SpeedRun
            ? state.FastestNightSeconds > 0 && state.FastestNightSeconds <= target
            : current >= target;
    }

    private static List<ChallengeDef> FilterByTier(int tier)
    {
        return ChallengePool.Where(c => tier switch
        {
            0 => c.Reward <= 30,
            1 => c.Reward <= 50,
            2 => c.Reward <= 70,
            _ => true,
        }).ToList();
    }

    private static int GetWordsTyped(GameState state)
    {
        if (state.TypingMetrics.TryGetValue("battle_words_typed", out var val) && val is int words)
            return words;
        return 0;
    }
}

public enum ChallengeType
{
    DefeatEnemies,
    TypeWords,
    PerfectAccuracy,
    ComboStreak,
    SurviveDays,
    SpeedRun,
    NoDamage,
}

public record ChallengeDef(string Id, string Name, string Description,
    ChallengeType Type, int Target, int Reward);

public record DailyChallengeDef(string Name, string Description, string Category, int TokenReward);
