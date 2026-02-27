using System;
using System.Collections.Generic;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Central mutable game state container holding all game data across all systems.
/// Ported from sim/types.gd (GameState class).
/// </summary>
public class GameState
{
    /// <summary>
    /// Gets the canonical resource keys used by core resource dictionaries.
    /// </summary>
    public static readonly string[] ResourceKeys = { "wood", "stone", "food" };
    /// <summary>
    /// Gets the canonical building keys used by core building dictionaries.
    /// </summary>
    public static readonly string[] BuildingKeys = { "farm", "lumber", "quarry", "wall", "tower", "market", "barracks", "temple", "workshop" };

    // Core
    /// <summary>
    /// Gets or sets the current in-game day counter.
    /// </summary>
    public int Day { get; set; }
    /// <summary>
    /// Gets or sets the current simulation phase (for example day and night) that drives phase transitions.
    /// </summary>
    public string Phase { get; set; } = "day";
    /// <summary>
    /// Gets or sets the maximum action points available during day actions.
    /// </summary>
    public int ApMax { get; set; }
    /// <summary>
    /// Gets or sets the current available action points.
    /// </summary>
    public int Ap { get; set; }
    /// <summary>
    /// Gets or sets the settlement hit points.
    /// </summary>
    public int Hp { get; set; }
    /// <summary>
    /// Gets or sets the maximum settlement hit points.
    /// </summary>
    public int MaxHp { get; set; } = 10;
    /// <summary>
    /// Gets or sets the discrete threat score used by encounter pacing systems.
    /// </summary>
    public int Threat { get; set; }
    /// <summary>
    /// Gets or sets the resource inventory keyed by resource id.
    /// </summary>
    public Dictionary<string, int> Resources { get; set; } = new();
    /// <summary>
    /// Gets or sets building counts keyed by building id.
    /// </summary>
    public Dictionary<string, int> Buildings { get; set; } = new();
    /// <summary>
    /// Gets or sets the map width in tiles.
    /// </summary>
    public int MapW { get; set; }
    /// <summary>
    /// Gets or sets the map height in tiles.
    /// </summary>
    public int MapH { get; set; }
    /// <summary>
    /// Gets or sets the settlement base position on the map grid.
    /// </summary>
    public GridPoint BasePos { get; set; }
    /// <summary>
    /// Gets or sets the current map cursor position.
    /// </summary>
    public GridPoint CursorPos { get; set; }
    /// <summary>
    /// Gets or sets terrain tile ids stored as a row-major linear array.
    /// </summary>
    public List<string> Terrain { get; set; } = new();
    /// <summary>
    /// Gets or sets placed structure ids keyed by linear tile index.
    /// </summary>
    public Dictionary<int, string> Structures { get; set; } = new();
    /// <summary>
    /// Gets or sets per-structure upgrade levels keyed by linear tile index.
    /// </summary>
    public Dictionary<int, int> StructureLevels { get; set; } = new();
    /// <summary>
    /// Gets or sets discovered tile indices currently revealed to the player.
    /// </summary>
    public HashSet<int> Discovered { get; set; } = new();
    /// <summary>
    /// Gets or sets the active night encounter prompt text.
    /// </summary>
    public string NightPrompt { get; set; } = "";
    /// <summary>
    /// Gets or sets the number of night enemies still pending spawn.
    /// </summary>
    public int NightSpawnRemaining { get; set; }
    /// <summary>
    /// Gets or sets the total enemies scheduled for the active night wave.
    /// </summary>
    public int NightWaveTotal { get; set; }
    /// <summary>
    /// Gets or sets active combat enemies represented as state dictionaries.
    /// </summary>
    public List<Dictionary<string, object>> Enemies { get; set; } = new();
    /// <summary>
    /// Gets or sets the next unique enemy id.
    /// </summary>
    public int EnemyNextId { get; set; }
    /// <summary>
    /// Gets or sets whether the most recent pathfinding check found an open path.
    /// </summary>
    public bool LastPathOpen { get; set; }
    /// <summary>
    /// Gets or sets the random seed label used for deterministic initialization.
    /// </summary>
    public string RngSeed { get; set; } = "default";
    /// <summary>
    /// Gets or sets the current deterministic random generator state.
    /// </summary>
    public long RngState { get; set; }
    /// <summary>
    /// Gets or sets the active lesson identifier for typing content.
    /// </summary>
    public string LessonId { get; set; } = "full_alpha";
    /// <summary>
    /// Gets or sets the serialized game-state schema version.
    /// </summary>
    public int Version { get; set; }

    // Event system
    /// <summary>
    /// Gets or sets active points of interest keyed by POI id.
    /// </summary>
    public Dictionary<string, Dictionary<string, object>> ActivePois { get; set; } = new();
    /// <summary>
    /// Gets or sets per-event cooldowns keyed by event id.
    /// </summary>
    public Dictionary<string, int> EventCooldowns { get; set; } = new();
    /// <summary>
    /// Gets or sets event-system flags and arbitrary event state.
    /// </summary>
    public Dictionary<string, object> EventFlags { get; set; } = new();
    /// <summary>
    /// Gets or sets the currently pending event payload.
    /// </summary>
    public Dictionary<string, object> PendingEvent { get; set; } = new();
    /// <summary>
    /// Gets or sets active temporary buffs affecting gameplay.
    /// </summary>
    public List<Dictionary<string, object>> ActiveBuffs { get; set; } = new();

    // Upgrade system
    /// <summary>
    /// Gets or sets purchased kingdom upgrade ids.
    /// </summary>
    public List<string> PurchasedKingdomUpgrades { get; set; } = new();
    /// <summary>
    /// Gets or sets purchased unit upgrade ids.
    /// </summary>
    public List<string> PurchasedUnitUpgrades { get; set; } = new();
    /// <summary>
    /// Gets or sets the current gold currency amount.
    /// </summary>
    public int Gold { get; set; }

    // Progression tracking
    /// <summary>
    /// Gets or sets ids for completed quests.
    /// </summary>
    public HashSet<string> CompletedQuests { get; set; } = new();
    /// <summary>
    /// Gets or sets ids for bosses defeated by the player.
    /// </summary>
    public HashSet<string> BossesDefeated { get; set; } = new();
    /// <summary>
    /// Gets or sets progression milestone ids that have been reached.
    /// </summary>
    public HashSet<string> Milestones { get; set; } = new();
    /// <summary>
    /// Gets or sets ids for unlocked skills.
    /// </summary>
    public HashSet<string> UnlockedSkills { get; set; } = new();
    /// <summary>
    /// Gets or sets unspent skill points.
    /// </summary>
    public int SkillPoints { get; set; }
    /// <summary>
    /// Gets or sets the lifetime defeated-enemy count.
    /// </summary>
    public int EnemiesDefeated { get; set; }
    /// <summary>
    /// Gets or sets the highest combo achieved across the run.
    /// </summary>
    public int MaxComboEver { get; set; }
    /// <summary>
    /// Gets or sets the number of survived wave encounters.
    /// </summary>
    public int WavesSurvived { get; set; }
    /// <summary>
    /// Gets or sets the currently active progression title id.
    /// </summary>
    public string ActiveTitle { get; set; } = "";

    // Inventory & equipment
    /// <summary>
    /// Gets or sets inventory item quantities keyed by item id.
    /// </summary>
    public Dictionary<string, int> Inventory { get; set; } = new();
    /// <summary>
    /// Gets or sets equipped item ids keyed by equipment slot.
    /// </summary>
    public Dictionary<string, string> EquippedItems { get; set; } = new();

    // Worker system
    /// <summary>
    /// Gets or sets worker data keyed by worker id.
    /// </summary>
    public Dictionary<int, int> Workers { get; set; } = new();
    /// <summary>
    /// Gets or sets worker assignments keyed by worker id.
    /// </summary>
    public Dictionary<int, int> WorkerAssignments { get; set; } = new();
    /// <summary>
    /// Gets or sets currently available workers.
    /// </summary>
    public int WorkerCount { get; set; }
    /// <summary>
    /// Gets or sets the total worker count owned by the settlement.
    /// </summary>
    public int TotalWorkers { get; set; }
    /// <summary>
    /// Gets or sets the maximum supported worker capacity.
    /// </summary>
    public int MaxWorkers { get; set; }
    /// <summary>
    /// Gets or sets the upkeep cost per worker cycle.
    /// </summary>
    public int WorkerUpkeep { get; set; }

    // Citizen identity system
    /// <summary>
    /// Gets or sets citizen identity and biography records.
    /// </summary>
    public List<Dictionary<string, object>> Citizens { get; set; } = new();

    // Research system
    /// <summary>
    /// Gets or sets the id of the currently active research project.
    /// </summary>
    public string ActiveResearch { get; set; } = "";
    /// <summary>
    /// Gets or sets current progress points for active research.
    /// </summary>
    public int ResearchProgress { get; set; }
    /// <summary>
    /// Gets or sets ids for completed research projects.
    /// </summary>
    public List<string> CompletedResearch { get; set; } = new();

    // Trade system
    /// <summary>
    /// Gets or sets current trade conversion rates keyed by trade pair id.
    /// </summary>
    public Dictionary<string, double> TradeRates { get; set; } = new();
    /// <summary>
    /// Gets or sets the day index when the last trade occurred.
    /// </summary>
    public int LastTradeDay { get; set; }
    /// <summary>
    /// Gets or sets per-day trade cooldown tracking to prevent round-trip exploits.
    /// Each entry is a "from:to" pair traded on the current day. Cleared on day advance.
    /// </summary>
    public HashSet<string> TradeHistory { get; set; } = new();

    // Faction/Diplomacy system
    /// <summary>
    /// Gets or sets faction relation scores keyed by faction id.
    /// </summary>
    public Dictionary<string, int> FactionRelations { get; set; } = new();
    /// <summary>
    /// Gets or sets faction agreements grouped by agreement type.
    /// </summary>
    public Dictionary<string, List<string>> FactionAgreements { get; set; } = new();
    /// <summary>
    /// Gets or sets pending diplomacy offers keyed by faction id.
    /// </summary>
    public Dictionary<string, Dictionary<string, object>> PendingDiplomacy { get; set; } = new();

    // Accessibility
    /// <summary>
    /// Gets or sets an accessibility simulation speed multiplier.
    /// </summary>
    public float SpeedMultiplier { get; set; }
    /// <summary>
    /// Gets or sets a value indicating whether practice mode protections are enabled.
    /// </summary>
    public bool PracticeMode { get; set; }

    // Open-world exploration
    /// <summary>
    /// Gets or sets the player position in open-world exploration.
    /// </summary>
    public GridPoint PlayerPos { get; set; }
    /// <summary>
    /// Gets or sets the player facing direction token.
    /// </summary>
    public string PlayerFacing { get; set; } = "down";
    /// <summary>
    /// Gets or sets active NPC entities in the world layer.
    /// </summary>
    public List<Dictionary<string, object>> Npcs { get; set; } = new();
    /// <summary>
    /// Gets or sets roaming world enemies outside direct encounters.
    /// </summary>
    public List<Dictionary<string, object>> RoamingEnemies { get; set; } = new();
    /// <summary>
    /// Gets or sets roaming world resource entities.
    /// </summary>
    public List<Dictionary<string, object>> RoamingResources { get; set; } = new();
    /// <summary>
    /// Gets or sets the continuous world threat level meter.
    /// </summary>
    public float ThreatLevel { get; set; }
    /// <summary>
    /// Gets or sets normalized time-of-day progress for world simulation.
    /// </summary>
    public float TimeOfDay { get; set; }
    /// <summary>
    /// Gets or sets accumulated world tick time used for fixed-step updates.
    /// </summary>
    public float WorldTickAccum { get; set; }

    // Unified threat system
    /// <summary>
    /// Gets or sets the current threat activity mode and controls transitions between exploration and encounter states.
    /// </summary>
    public string ActivityMode { get; set; } = "exploration";
    /// <summary>
    /// Gets or sets enemies currently participating in an active encounter.
    /// </summary>
    public List<Dictionary<string, object>> EncounterEnemies { get; set; } = new();
    /// <summary>
    /// Gets or sets cooldown time remaining before the next wave can begin.
    /// </summary>
    public float WaveCooldown { get; set; }
    /// <summary>
    /// Gets or sets accumulated timer used for periodic threat decay.
    /// </summary>
    public float ThreatDecayAccum { get; set; }

    // Expedition system
    /// <summary>
    /// Gets or sets currently active expedition records.
    /// </summary>
    public List<Dictionary<string, object>> ActiveExpeditions { get; set; } = new();
    /// <summary>
    /// Gets or sets the next unique expedition id.
    /// </summary>
    public int ExpeditionNextId { get; set; }
    /// <summary>
    /// Gets or sets completed expedition records.
    /// </summary>
    public List<Dictionary<string, object>> ExpeditionHistory { get; set; } = new();

    // Resource node system
    /// <summary>
    /// Gets or sets map resource nodes keyed by node id.
    /// </summary>
    public Dictionary<int, Dictionary<string, object>> ResourceNodes { get; set; } = new();
    /// <summary>
    /// Gets or sets harvested node counters keyed by node type.
    /// </summary>
    public Dictionary<string, int> HarvestedNodes { get; set; } = new();

    // Loot tracking
    /// <summary>
    /// Gets or sets loot entries pending claim or resolution.
    /// </summary>
    public List<Dictionary<string, object>> LootPending { get; set; } = new();
    /// <summary>
    /// Gets or sets the quality scalar from the most recent loot drop.
    /// </summary>
    public float LastLootQuality { get; set; }
    /// <summary>
    /// Gets or sets the count of perfect kills achieved.
    /// </summary>
    public int PerfectKills { get; set; }

    // Tower system
    /// <summary>
    /// Gets or sets per-tower runtime states keyed by structure index.
    /// </summary>
    public Dictionary<int, Dictionary<string, object>> TowerStates { get; set; } = new();
    /// <summary>
    /// Gets or sets currently active tower synergy effects.
    /// </summary>
    public List<Dictionary<string, object>> ActiveSynergies { get; set; } = new();
    /// <summary>
    /// Gets or sets active summoned units spawned by towers.
    /// </summary>
    public List<Dictionary<string, object>> SummonedUnits { get; set; } = new();
    /// <summary>
    /// Gets or sets the next unique id for summoned units.
    /// </summary>
    public int SummonedNextId { get; set; }
    /// <summary>
    /// Gets or sets active trap instances deployed in combat.
    /// </summary>
    public List<Dictionary<string, object>> ActiveTraps { get; set; } = new();
    /// <summary>
    /// Gets or sets current charge values keyed by tower index.
    /// </summary>
    public Dictionary<int, int> TowerCharge { get; set; } = new();
    /// <summary>
    /// Gets or sets tower cooldown timers keyed by tower index.
    /// </summary>
    public Dictionary<int, int> TowerCooldowns { get; set; } = new();
    /// <summary>
    /// Gets or sets summoned unit ids grouped by originating tower index.
    /// </summary>
    public Dictionary<int, List<int>> TowerSummonIds { get; set; } = new();

    // Auto-tower management settings
    /// <summary>
    /// Gets or sets auto-tower management preferences and thresholds.
    /// </summary>
    public AutoTowerSettings AutoTower { get; set; } = new();

    // Tower targeting mode
    /// <summary>
    /// Gets or sets the active tower targeting mode key.
    /// </summary>
    public string TargetingMode { get; set; } = "nearest";

    // Typing metrics
    /// <summary>
    /// Gets or sets transient typing performance metrics for active combat.
    /// </summary>
    public Dictionary<string, object> TypingMetrics { get; set; } = new();
    /// <summary>
    /// Gets or sets remaining duration for the arrow rain effect.
    /// </summary>
    public float ArrowRainTimer { get; set; }

    // Hero system
    /// <summary>
    /// Gets or sets the active hero identifier.
    /// </summary>
    public string HeroId { get; set; } = "";
    /// <summary>
    /// Gets or sets cooldown remaining on the hero ability.
    /// </summary>
    public float HeroAbilityCooldown { get; set; }
    /// <summary>
    /// Gets or sets active hero effect payloads.
    /// </summary>
    public List<Dictionary<string, object>> HeroActiveEffects { get; set; } = new();

    // Title system
    /// <summary>
    /// Gets or sets the currently equipped cosmetic title id.
    /// </summary>
    public string EquippedTitle { get; set; } = "";
    /// <summary>
    /// Gets or sets unlocked cosmetic title ids.
    /// </summary>
    public List<string> UnlockedTitles { get; set; } = new();
    /// <summary>
    /// Gets or sets unlocked badge ids.
    /// </summary>
    public List<string> UnlockedBadges { get; set; } = new();

    // Daily challenge tracking
    /// <summary>
    /// Gets or sets ids for completed daily challenges.
    /// </summary>
    public HashSet<string> CompletedDailyChallenges { get; set; } = new();
    /// <summary>
    /// Gets or sets the date key for the currently tracked daily challenge set.
    /// </summary>
    public string DailyChallengeDate { get; set; } = "";
    /// <summary>
    /// Gets or sets the number of perfect nights completed today.
    /// </summary>
    public int PerfectNightsToday { get; set; }
    /// <summary>
    /// Gets or sets the number of no-damage nights completed today.
    /// </summary>
    public int NoDamageNightsToday { get; set; }
    /// <summary>
    /// Gets or sets the fastest night completion time in seconds.
    /// </summary>
    public int FastestNightSeconds { get; set; }

    // Victory system
    /// <summary>
    /// Gets or sets ids for victory conditions achieved.
    /// </summary>
    public List<string> VictoryAchieved { get; set; } = new();
    /// <summary>
    /// Gets or sets a value indicating whether victory evaluation has run for the current update.
    /// </summary>
    public bool VictoryChecked { get; set; }
    /// <summary>
    /// Gets or sets the highest gold amount reached this run.
    /// </summary>
    public int PeakGold { get; set; }
    /// <summary>
    /// Gets or sets a value indicating whether main story completion has been reached.
    /// </summary>
    public bool StoryCompleted { get; set; }
    /// <summary>
    /// Gets or sets the currently active story act number.
    /// </summary>
    public int CurrentAct { get; set; }

    /// <summary>
    /// Initializes a new game state with deterministic default values and seeded collections.
    /// </summary>
    public GameState()
    {
        Day = 1;
        Phase = "day";
        ApMax = 3;
        Ap = ApMax;
        Hp = 10;
        MaxHp = 10;
        Threat = 0;
        MapW = 32;
        MapH = 32;
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

    /// <summary>
    /// Converts grid coordinates into the row-major linear tile index for the current map width.
    /// </summary>
    /// <param name="x">The tile X coordinate.</param>
    /// <param name="y">The tile Y coordinate.</param>
    /// <returns>The linear index for the specified coordinates.</returns>
    public int Index(int x, int y) => y * MapW + x;
}
