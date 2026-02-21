using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Open world tick for exploration, threat, and roaming enemies.
/// Ported from sim/world_tick.gd.
/// </summary>
public static class WorldTick
{
    public const double WorldTickInterval = 1.0;
    public const double TimeAdvanceRate = 0.02;
    public const double PoiSpawnChance = 0.15;
    public const double RoamingSpawnChance = 0.10;
    public const int MaxActivePois = 5;
    public const int MaxRoamingEnemies = 8;
    public const double ThreatDecayRate = 0.01;
    public const double ThreatGrowthRate = 0.02;
    public const double WaveAssaultThreshold = 0.8;
    public const double WaveCooldownDuration = 30.0;
    /// <summary>Reward constants for wave completion.</summary>
    public const int WaveBaseGold = 10;
    public const int WavePerEnemyGold = 3;
    public const int WaveBaseWood = 5;
    public const int WaveBaseStone = 3;
    public const int WaveBaseFood = 2;
    private static readonly string[] WaveEnemyKinds = { "scout", "raider", "armored", "swarm", "berserker" };

    public static Dictionary<string, object> Tick(GameState state, double delta)
    {
        state.WorldTickAccum += (float)delta;
        var events = new List<string>();
        bool changed = false;

        if (state.WaveCooldown > 0)
            state.WaveCooldown = (float)Math.Max(0, state.WaveCooldown - delta);

        while (state.WorldTickAccum >= WorldTickInterval)
        {
            state.WorldTickAccum -= (float)WorldTickInterval;

            state.TimeOfDay += (float)TimeAdvanceRate;
            if (state.TimeOfDay >= 1.0f)
                state.TimeOfDay -= 1.0f;

            switch (state.ActivityMode)
            {
                case "exploration":
                    WorldEntities.TickEntityMovement(state);
                    TickThreatLevel(state);
                    var encounterEvent = CheckProximityEncounter(state);
                    if (encounterEvent != "") events.Add(encounterEvent);
                    var waveEvent = CheckWaveAssaultTrigger(state);
                    if (waveEvent != "") events.Add(waveEvent);
                    break;

                case "encounter":
                    var approachEvents = InlineCombat.TickEnemyApproach(state, (float)WorldTickInterval);
                    events.AddRange(approachEvents);
                    break;

                case "wave_assault":
                    SpawnWaveEnemies(state);
                    if (state.Enemies.Count == 0 && state.NightSpawnRemaining <= 0)
                    {
                        EndWaveAssault(state);
                        events.Add("Wave repelled! The kingdom is safe... for now.");
                    }
                    break;
            }

            changed = true;
        }

        return new Dictionary<string, object>
        {
            ["events"] = events,
            ["changed"] = changed
        };
    }

    private static string CheckWaveAssaultTrigger(GameState state)
    {
        if (state.WaveCooldown > 0) return "";
        if (state.ThreatLevel < WaveAssaultThreshold) return "";
        StartWaveAssault(state);
        return "WAVE ASSAULT! Enemies converge on the castle!";
    }

    private static void StartWaveAssault(GameState state)
    {
        state.ActivityMode = "wave_assault";
        state.Phase = "night";
        string difficultyMode = GetDifficultyMode(state);
        int threatForScaling = GetThreatForScaling(state);
        int waveSize = SimBalance.CalculateWaveSize(state.Day, threatForScaling);
        waveSize = Difficulty.ApplyWaveSizeModifier(waveSize, difficultyMode);
        state.NightWaveTotal = waveSize;
        state.NightSpawnRemaining = waveSize;
        state.Enemies.Clear();
        state.ThreatLevel = 0.3f;
    }

    private static void EndWaveAssault(GameState state)
    {
        string difficultyMode = GetDifficultyMode(state);

        // Calculate rewards based on wave size
        int waveSize = state.NightWaveTotal;
        int goldReward = WaveBaseGold + waveSize * WavePerEnemyGold;
        goldReward = Difficulty.ApplyGoldModifier(goldReward, difficultyMode);
        int woodReward = WaveBaseWood + waveSize / 2;
        int stoneReward = WaveBaseStone + waveSize / 3;
        int foodReward = WaveBaseFood + waveSize / 4;

        // Apply proficiency multiplier
        var profTier = TypingProficiency.GetTier();
        double profMult = TypingProficiency.GetGoldMultiplier(profTier);
        goldReward = (int)(goldReward * profMult);
        double resMult = TypingProficiency.GetResourceMultiplier(profTier);
        woodReward = (int)(woodReward * resMult);
        stoneReward = (int)(stoneReward * resMult);
        foodReward = (int)(foodReward * resMult);

        // Apply rewards
        state.Gold += goldReward;
        state.Resources["wood"] = state.Resources.GetValueOrDefault("wood", 0) + woodReward;
        state.Resources["stone"] = state.Resources.GetValueOrDefault("stone", 0) + stoneReward;
        state.Resources["food"] = state.Resources.GetValueOrDefault("food", 0) + foodReward;

        // Track wave completion
        state.WavesSurvived++;

        // Reset state
        state.ActivityMode = "exploration";
        state.Phase = "day";
        state.Ap = state.ApMax;
        state.WaveCooldown = (float)WaveCooldownDuration;
        state.Day++;
    }

    private static void EndEncounter(GameState state)
    {
        state.ActivityMode = "exploration";
        state.Phase = "day";
    }

    private static string CheckProximityEncounter(GameState state)
    {
        const int encounterRadius = 2;
        var nearbyEnemies = WorldEntities.GetEntitiesNear(state, state.PlayerPos, encounterRadius);
        var hostiles = new List<Dictionary<string, object>>();

        foreach (var entity in nearbyEnemies)
        {
            if (entity.GetValueOrDefault("entity_type")?.ToString() == "enemy")
                hostiles.Add(entity);
        }

        if (hostiles.Count == 0) return "";

        // Move the closest enemy into the encounter
        state.ActivityMode = "encounter";
        state.EncounterEnemies.Clear();

        foreach (var hostile in hostiles)
        {
            // Remove from roaming list
            int hostileId = Convert.ToInt32(hostile.GetValueOrDefault("id", -1));
            state.RoamingEnemies.RemoveAll(e =>
            {
                if (e.TryGetValue("id", out var idObj))
                    return Convert.ToInt32(idObj) == hostileId;
                return false;
            });

            ApplyDifficultyToEnemy(hostile, state);
            state.EncounterEnemies.Add(hostile);
        }

        // Assign words to encounter enemies
        InlineCombat.AssignWords(state, state.EncounterEnemies);

        return $"Encounter! {hostiles.Count} enem{(hostiles.Count == 1 ? "y" : "ies")} engage you!";
    }

    private static void SpawnWaveEnemies(GameState state)
    {
        if (state.NightSpawnRemaining <= 0) return;

        int maxConcurrentEnemies = Math.Max(3, Math.Min(6, state.NightWaveTotal));
        if (state.Enemies.Count >= maxConcurrentEnemies) return;

        string difficultyMode = GetDifficultyMode(state);
        int threatForScaling = GetThreatForScaling(state);

        int hp = SimBalance.CalculateEnemyHp(state.Day, threatForScaling);
        hp = Difficulty.ApplyHealthModifier(hp, difficultyMode);

        int damage = 1 + (state.Day / 6);
        damage = Difficulty.ApplyDamageModifier(damage, difficultyMode);

        int speed = 1 + (state.Day / 10);
        speed = (int)Difficulty.ApplySpeedModifier(speed, difficultyMode);

        var usedWords = new HashSet<string>();
        foreach (var enemy in state.Enemies)
        {
            string existingWord = enemy.GetValueOrDefault("word")?.ToString() ?? "";
            if (!string.IsNullOrWhiteSpace(existingWord))
                usedWords.Add(existingWord);
        }

        string kind = WaveEnemyKinds[SimRng.RollRange(state, 0, WaveEnemyKinds.Length - 1)];
        string word = WordPool.WordForEnemy(
            state.RngSeed,
            state.Day,
            kind,
            state.EnemyNextId,
            usedWords,
            state.LessonId);

        var enemyEntry = new Dictionary<string, object>
        {
            ["id"] = state.EnemyNextId++,
            ["kind"] = kind,
            ["pos"] = SimMap.GetSpawnPos(state),
            ["word"] = word,
            ["hp"] = hp,
            ["max_hp"] = hp,
            ["damage"] = damage,
            ["speed"] = speed,
            ["dist"] = 10,
            ["tier"] = Math.Max(0, damage - 1),
            ["gold"] = Math.Max(1, 1 + threatForScaling / 3),
        };

        state.Enemies.Add(enemyEntry);
        state.NightSpawnRemaining--;
    }

    private static void ApplyDifficultyToEnemy(Dictionary<string, object> enemy, GameState state)
    {
        string difficultyMode = GetDifficultyMode(state);
        int threatForScaling = GetThreatForScaling(state);

        int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", SimBalance.CalculateEnemyHp(state.Day, threatForScaling)));
        hp = Difficulty.ApplyHealthModifier(hp, difficultyMode);
        enemy["hp"] = hp;
        enemy["max_hp"] = hp;

        int damage = Convert.ToInt32(enemy.GetValueOrDefault("damage", 1 + Convert.ToInt32(enemy.GetValueOrDefault("tier", 0))));
        damage = Difficulty.ApplyDamageModifier(damage, difficultyMode);
        enemy["damage"] = damage;
        enemy["tier"] = Math.Max(0, damage - 1);

        int speed = Convert.ToInt32(enemy.GetValueOrDefault("speed", 1));
        speed = (int)Difficulty.ApplySpeedModifier(speed, difficultyMode);
        enemy["speed"] = speed;
    }

    private static int GetThreatForScaling(GameState state)
    {
        int explorationThreat = (int)Math.Round(state.ThreatLevel * SimBalance.ThreatMax);
        return Math.Max(state.Threat, explorationThreat);
    }

    private static string GetDifficultyMode(GameState state)
    {
        if (state.EventFlags.TryGetValue("difficulty_mode", out var modeObj))
        {
            string mode = modeObj?.ToString() ?? "";
            if (!string.IsNullOrWhiteSpace(mode))
                return mode;
        }

        var difficultyModeProp = state.GetType().GetProperty("DifficultyMode");
        if (difficultyModeProp != null)
        {
            string mode = difficultyModeProp.GetValue(state)?.ToString() ?? "";
            if (!string.IsNullOrWhiteSpace(mode))
                return mode;
        }

        return Difficulty.DefaultMode;
    }

    private static void TickThreatLevel(GameState state)
    {
        double contribution = 0;
        int threshold = 5;

        foreach (var entity in state.RoamingEnemies)
        {
            if (entity.GetValueOrDefault("pos") is not GridPoint pos) continue;
            int dist = Math.Abs(pos.X - state.BasePos.X) + Math.Abs(pos.Y - state.BasePos.Y);
            if (dist <= threshold)
            {
                double proximity = 1.0 + (double)(threshold - dist) / threshold;
                string zone = SimMap.GetZoneAt(state, pos);
                double zoneMult = SimMap.GetZoneThreatMultiplier(zone);
                contribution += zoneMult * proximity;
            }
        }

        if (contribution > 0)
            state.ThreatLevel = (float)Math.Min(1.0, state.ThreatLevel + ThreatGrowthRate * contribution);
        else
            state.ThreatLevel = (float)Math.Max(0.0, state.ThreatLevel - ThreatDecayRate);
    }
}
