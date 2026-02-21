using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Central mutable game state container holding all game data across all systems.
/// Ported from sim/types.gd (GameState class).
/// </summary>
public class GameState
{
    public static readonly string[] ResourceKeys = { "wood", "stone", "food" };
    public static readonly string[] BuildingKeys = { "farm", "lumber", "quarry", "wall", "tower", "market", "barracks", "temple", "workshop" };

    // Core
    public int Day { get; set; }
    public string Phase { get; set; } = "day";
    public int ApMax { get; set; }
    public int Ap { get; set; }
    public int Hp { get; set; }
    public int Threat { get; set; }
    public Dictionary<string, int> Resources { get; set; } = new();
    public Dictionary<string, int> Buildings { get; set; } = new();
    public int MapW { get; set; }
    public int MapH { get; set; }
    public GridPoint BasePos { get; set; }
    public GridPoint CursorPos { get; set; }
    public List<string> Terrain { get; set; } = new();
    public Dictionary<int, string> Structures { get; set; } = new();
    public Dictionary<int, int> StructureLevels { get; set; } = new();
    public HashSet<int> Discovered { get; set; } = new();
    public string NightPrompt { get; set; } = "";
    public int NightSpawnRemaining { get; set; }
    public int NightWaveTotal { get; set; }
    public List<Dictionary<string, object>> Enemies { get; set; } = new();
    public int EnemyNextId { get; set; }
    public bool LastPathOpen { get; set; }
    public string RngSeed { get; set; } = "default";
    public long RngState { get; set; }
    public string LessonId { get; set; } = "full_alpha";
    public int Version { get; set; }

    // Event system
    public Dictionary<string, Dictionary<string, object>> ActivePois { get; set; } = new();
    public Dictionary<string, int> EventCooldowns { get; set; } = new();
    public Dictionary<string, object> EventFlags { get; set; } = new();
    public Dictionary<string, object> PendingEvent { get; set; } = new();
    public List<Dictionary<string, object>> ActiveBuffs { get; set; } = new();

    // Upgrade system
    public List<string> PurchasedKingdomUpgrades { get; set; } = new();
    public List<string> PurchasedUnitUpgrades { get; set; } = new();
    public int Gold { get; set; }

    // Progression tracking
    public HashSet<string> CompletedQuests { get; set; } = new();
    public HashSet<string> BossesDefeated { get; set; } = new();
    public HashSet<string> Milestones { get; set; } = new();
    public HashSet<string> UnlockedSkills { get; set; } = new();
    public int SkillPoints { get; set; }
    public int EnemiesDefeated { get; set; }
    public int MaxComboEver { get; set; }
    public string ActiveTitle { get; set; } = "";

    // Inventory & equipment
    public Dictionary<string, int> Inventory { get; set; } = new();
    public Dictionary<string, string> EquippedItems { get; set; } = new();

    // Worker system
    public Dictionary<int, int> Workers { get; set; } = new();
    public Dictionary<int, int> WorkerAssignments { get; set; } = new();
    public int WorkerCount { get; set; }
    public int TotalWorkers { get; set; }
    public int MaxWorkers { get; set; }
    public int WorkerUpkeep { get; set; }

    // Citizen identity system
    public List<Dictionary<string, object>> Citizens { get; set; } = new();

    // Research system
    public string ActiveResearch { get; set; } = "";
    public int ResearchProgress { get; set; }
    public List<string> CompletedResearch { get; set; } = new();

    // Trade system
    public Dictionary<string, double> TradeRates { get; set; } = new();
    public int LastTradeDay { get; set; }

    // Faction/Diplomacy system
    public Dictionary<string, int> FactionRelations { get; set; } = new();
    public Dictionary<string, List<string>> FactionAgreements { get; set; } = new();
    public Dictionary<string, Dictionary<string, object>> PendingDiplomacy { get; set; } = new();

    // Accessibility
    public float SpeedMultiplier { get; set; }
    public bool PracticeMode { get; set; }

    // Open-world exploration
    public GridPoint PlayerPos { get; set; }
    public string PlayerFacing { get; set; } = "down";
    public List<Dictionary<string, object>> Npcs { get; set; } = new();
    public List<Dictionary<string, object>> RoamingEnemies { get; set; } = new();
    public List<Dictionary<string, object>> RoamingResources { get; set; } = new();
    public float ThreatLevel { get; set; }
    public float TimeOfDay { get; set; }
    public float WorldTickAccum { get; set; }

    // Unified threat system
    public string ActivityMode { get; set; } = "exploration";
    public List<Dictionary<string, object>> EncounterEnemies { get; set; } = new();
    public float WaveCooldown { get; set; }
    public float ThreatDecayAccum { get; set; }

    // Expedition system
    public List<Dictionary<string, object>> ActiveExpeditions { get; set; } = new();
    public int ExpeditionNextId { get; set; }
    public List<Dictionary<string, object>> ExpeditionHistory { get; set; } = new();

    // Resource node system
    public Dictionary<int, Dictionary<string, object>> ResourceNodes { get; set; } = new();
    public Dictionary<string, int> HarvestedNodes { get; set; } = new();

    // Loot tracking
    public List<Dictionary<string, object>> LootPending { get; set; } = new();
    public float LastLootQuality { get; set; }
    public int PerfectKills { get; set; }

    // Tower system
    public Dictionary<int, Dictionary<string, object>> TowerStates { get; set; } = new();
    public List<Dictionary<string, object>> ActiveSynergies { get; set; } = new();
    public List<Dictionary<string, object>> SummonedUnits { get; set; } = new();
    public int SummonedNextId { get; set; }
    public List<Dictionary<string, object>> ActiveTraps { get; set; } = new();
    public Dictionary<int, int> TowerCharge { get; set; } = new();
    public Dictionary<int, int> TowerCooldowns { get; set; } = new();
    public Dictionary<int, List<int>> TowerSummonIds { get; set; } = new();

    // Auto-tower management settings
    public AutoTowerSettings AutoTower { get; set; } = new();

    // Tower targeting mode
    public string TargetingMode { get; set; } = "nearest";

    // Typing metrics
    public Dictionary<string, object> TypingMetrics { get; set; } = new();
    public float ArrowRainTimer { get; set; }

    // Hero system
    public string HeroId { get; set; } = "";
    public float HeroAbilityCooldown { get; set; }
    public List<Dictionary<string, object>> HeroActiveEffects { get; set; } = new();

    // Title system
    public string EquippedTitle { get; set; } = "";
    public List<string> UnlockedTitles { get; set; } = new();
    public List<string> UnlockedBadges { get; set; } = new();

    // Daily challenge tracking
    public HashSet<string> CompletedDailyChallenges { get; set; } = new();
    public string DailyChallengeDate { get; set; } = "";
    public int PerfectNightsToday { get; set; }
    public int NoDamageNightsToday { get; set; }
    public int FastestNightSeconds { get; set; }

    // Victory system
    public List<string> VictoryAchieved { get; set; } = new();
    public bool VictoryChecked { get; set; }
    public int PeakGold { get; set; }
    public bool StoryCompleted { get; set; }
    public int CurrentAct { get; set; }

    public GameState()
    {
        Day = 1;
        Phase = "day";
        ApMax = 3;
        Ap = ApMax;
        Hp = 10;
        Threat = 0;
        MapW = 64;
        MapH = 64;
        BasePos = new GridPoint(MapW / 2, MapH / 2);
        CursorPos = BasePos;
        PlayerPos = BasePos;
        NightPrompt = "";
        NightSpawnRemaining = 0;
        NightWaveTotal = 0;
        EnemyNextId = 1;
        LastPathOpen = true;
        RngSeed = "default";
        RngState = 0;
        LessonId = "full_alpha";
        Version = 1;

        foreach (var key in ResourceKeys)
            Resources[key] = 0;

        foreach (var key in BuildingKeys)
            Buildings[key] = 0;

        for (int i = 0; i < MapW * MapH; i++)
            Terrain.Add("");

        // Event system
        ActiveBuffs = new List<Dictionary<string, object>>();

        // Upgrade system
        Gold = 0;

        // Worker system
        TotalWorkers = 3;
        WorkerCount = 3;
        MaxWorkers = 10;
        WorkerUpkeep = 1;

        // Research system
        ActiveResearch = "";
        ResearchProgress = 0;

        // Trade system
        TradeRates = new Dictionary<string, double>
        {
            ["wood_to_stone"] = 1.5,
            ["stone_to_wood"] = 0.67,
            ["food_to_gold"] = 0.5,
            ["gold_to_food"] = 2.0,
            ["wood_to_gold"] = 0.33,
            ["gold_to_wood"] = 3.0,
            ["stone_to_gold"] = 0.5,
            ["gold_to_stone"] = 2.0
        };
        LastTradeDay = 0;

        // Faction/Diplomacy
        FactionAgreements = new Dictionary<string, List<string>>
        {
            ["trade"] = new(),
            ["non_aggression"] = new(),
            ["alliance"] = new(),
            ["war"] = new()
        };

        // Accessibility
        SpeedMultiplier = 1.0f;
        PracticeMode = false;

        // Open-world
        ThreatLevel = 0.0f;
        TimeOfDay = 0.25f;
        WorldTickAccum = 0.0f;

        // Unified threat
        ActivityMode = "exploration";
        WaveCooldown = 0.0f;
        ThreatDecayAccum = 0.0f;

        // Expedition
        ExpeditionNextId = 1;

        // Loot
        LastLootQuality = 1.0f;
        PerfectKills = 0;

        // Tower system
        SummonedNextId = 1;

        // Typing metrics
        TypingMetrics = new Dictionary<string, object>
        {
            ["battle_chars_typed"] = 0,
            ["battle_words_typed"] = 0,
            ["battle_start_msec"] = 0L,
            ["battle_errors"] = 0,
            ["rolling_window_chars"] = new List<object>(),
            ["unique_letters_window"] = new Dictionary<string, object>(),
            ["perfect_word_streak"] = 0,
            ["current_word_errors"] = 0
        };
        ArrowRainTimer = 0.0f;

        // Hero system
        HeroId = "";
        HeroAbilityCooldown = 0.0f;

        // Title system
        EquippedTitle = "";

        // Victory system
        VictoryChecked = false;
        PeakGold = 0;
        StoryCompleted = false;
        CurrentAct = 1;

        Discovered.Add(Index(BasePos.X, BasePos.Y));
    }

    public int Index(int x, int y) => y * MapW + x;
}
