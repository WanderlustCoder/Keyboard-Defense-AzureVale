using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Deterministic single-wave battle simulation for vertical-slice mode.
/// Keeps spawn timing, lane advancement, and typing resolution in core.
/// </summary>
public static class VerticalSliceWaveSim
{
    private const string SpawnTimerKey = "vs_spawn_timer_sec";
    private const string EnemyStepTimerKey = "vs_enemy_step_timer_sec";
    private const string RunClockKey = "vs_run_clock_sec";
    private const string ActiveTargetIdKey = "vs_active_target_id";
    private const string ActivePrefixKey = "vs_active_prefix";
    private const string ResultKey = "vs_result";
    private const string StartHpKey = "vs_start_hp";
    private const string MissCountKey = "vs_miss_count";
    private const string ScoreKey = "vs_score";
    private const string ElapsedSecondsKey = "vs_elapsed_seconds";
    private const string DamageTakenKey = "vs_damage_taken";
    private const string SummaryPayloadKey = "vs_summary_payload";
    private const string BattleCharsTypedKey = "battle_chars_typed";
    private const string BattleWordsTypedKey = "battle_words_typed";

    private const int NoEnemyIndex = -1;
    private const int DefaultEnemyId = 0;
    private const int DefaultEnemyHp = 1;
    private const int DefaultEnemyGoldReward = 1;
    private const int DefaultEnemyDistance = 10;

    private const int VictoryScoreBonus = 500;
    private const int ScorePerEnemyDefeated = 100;
    private const int ScorePerWordTyped = 20;
    private const int ScorePerHpRemaining = 10;
    private const int ScorePenaltyPerMiss = 15;
    private const int ScorePenaltyPerDamageTaken = 20;

    private static readonly string[] EnemyKinds = { "scout", "raider", "armored", "swarm", "berserker" };

    /// <summary>
    /// Initializes deterministic state for a single vertical-slice night wave.
    /// </summary>
    public static void StartSingleWave(GameState state, VerticalSliceWaveConfig config, List<string> events)
    {
        state.Phase = "night";
        state.Ap = 0;
        state.NightWaveTotal = config.SpawnTotal;
        state.NightSpawnRemaining = config.SpawnTotal;
        state.NightPrompt = "";
        state.Enemies.Clear();

        SetMetricFloat(state, SpawnTimerKey, 0f);
        SetMetricFloat(state, EnemyStepTimerKey, config.EnemyStepIntervalSeconds);
        SetMetricFloat(state, RunClockKey, 0f);
        SetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
        SetMetricString(state, ActivePrefixKey, string.Empty);
        SetMetricString(state, ResultKey, string.Empty);
        SetMetricInt(state, StartHpKey, state.Hp);
        SetMetricInt(state, MissCountKey, 0);
        SetMetricInt(state, ScoreKey, 0);
        SetMetricInt(state, ElapsedSecondsKey, 0);
        SetMetricInt(state, DamageTakenKey, 0);
        SetMetricObject(state, SummaryPayloadKey, new Dictionary<string, object>());

        events.Add($"Night falls. Enemy wave: {config.SpawnTotal}.");
    }

    /// <summary>
    /// Advances the active wave simulation by a time slice and optional typed input.
    /// </summary>
    public static void Step(
        GameState state,
        VerticalSliceWaveConfig config,
        float deltaSeconds,
        string? typedInput,
        List<string> events)
    {
        if (state.Phase != "night")
            return;

        float dt = Math.Max(0f, deltaSeconds);
        SetMetricFloat(state, RunClockKey, GetMetricFloat(state, RunClockKey, 0f) + dt);
        SyncActiveTarget(state);

        if (!string.IsNullOrWhiteSpace(typedInput))
            ResolveTypedInput(state, config, typedInput!, events);

        if (state.Phase == "game_over")
        {
            FinalizeResult(state, victory: false, events);
            return;
        }

        float spawnTimer = GetMetricFloat(state, SpawnTimerKey, 0f) - dt;
        while (state.NightSpawnRemaining > 0 && spawnTimer <= 0f)
        {
            SpawnEnemy(state, events);
            spawnTimer += config.SpawnIntervalSeconds;
        }
        SetMetricFloat(state, SpawnTimerKey, spawnTimer);

        float enemyStepTimer = GetMetricFloat(state, EnemyStepTimerKey, config.EnemyStepIntervalSeconds) - dt;
        while (enemyStepTimer <= 0f && state.Phase == "night")
        {
            TowerAttackStep(state, config, events);
            EnemyAdvanceStep(state, config, events);
            enemyStepTimer += config.EnemyStepIntervalSeconds;
        }
        SetMetricFloat(state, EnemyStepTimerKey, enemyStepTimer);
        SyncActiveTarget(state);

        if (state.Phase == "game_over" || state.Hp <= 0)
        {
            state.Phase = "game_over";
            FinalizeResult(state, victory: false, events);
            return;
        }

        if (state.NightSpawnRemaining <= 0 && state.Enemies.Count == 0)
        {
            state.Phase = "day";
            state.Ap = state.ApMax;
            state.NightPrompt = "";
            state.NightWaveTotal = 0;
            events.Add("Dawn breaks.");
            FinalizeResult(state, victory: true, events);
        }
    }

    private static void ResolveTypedInput(
        GameState state,
        VerticalSliceWaveConfig config,
        string typedInput,
        List<string> events)
    {
        string fragment = TypingFeedback.NormalizeInput(typedInput);
        if (string.IsNullOrEmpty(fragment))
            return;

        IncrementMetricInt(state, BattleCharsTypedKey, fragment.Length);
        SyncActiveTarget(state);

        int activeTargetId = GetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
        string activePrefix = GetMetricString(state, ActivePrefixKey, string.Empty);
        int targetIndex = activeTargetId > 0 ? TryGetEnemyIndexById(state, activeTargetId) : NoEnemyIndex;

        if (targetIndex >= 0)
        {
            string targetWord = TypingFeedback.NormalizeInput(
                state.Enemies[targetIndex].GetValueOrDefault("word")?.ToString() ?? string.Empty);
            string nextPrefix = activePrefix + fragment;

            if (targetWord.StartsWith(nextPrefix, StringComparison.Ordinal))
            {
                SetMetricString(state, ActivePrefixKey, nextPrefix);
                state.NightPrompt = targetWord.Length > nextPrefix.Length
                    ? targetWord[nextPrefix.Length..]
                    : string.Empty;
                events.Add(
                    $"typing_hit: target='{targetWord}' progress={nextPrefix.Length}/{targetWord.Length}");

                if (nextPrefix.Length >= targetWord.Length)
                {
                    CompleteWordHit(state, config, targetIndex, targetWord, events);
                }
                return;
            }

            SetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
            SetMetricString(state, ActivePrefixKey, string.Empty);
            state.NightPrompt = string.Empty;
        }

        targetIndex = SelectTargetByPrefix(state, fragment);
        if (targetIndex < 0)
        {
            ApplyTypingMiss(state, config, events);
            return;
        }

        var targetEnemy = state.Enemies[targetIndex];
        int targetId = Convert.ToInt32(targetEnemy.GetValueOrDefault("id", DefaultEnemyId));
        string word = TypingFeedback.NormalizeInput(
            targetEnemy.GetValueOrDefault("word")?.ToString() ?? string.Empty);
        if (string.IsNullOrEmpty(word))
        {
            ApplyTypingMiss(state, config, events);
            return;
        }

        SetMetricInt(state, ActiveTargetIdKey, targetId);
        SetMetricString(state, ActivePrefixKey, fragment);

        state.NightPrompt = word.Length > fragment.Length
            ? word[fragment.Length..]
            : string.Empty;
        events.Add($"typing_hit: target='{word}' progress={fragment.Length}/{word.Length}");

        if (fragment.Length >= word.Length)
            CompleteWordHit(state, config, targetIndex, word, events);
    }

    private static void CompleteWordHit(
        GameState state,
        VerticalSliceWaveConfig config,
        int targetIndex,
        string word,
        List<string> events)
    {
        if (targetIndex < 0 || targetIndex >= state.Enemies.Count)
            return;

        SetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
        SetMetricString(state, ActivePrefixKey, string.Empty);
        state.NightPrompt = string.Empty;

        var enemy = state.Enemies[targetIndex];
        int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", DefaultEnemyHp));
        hp -= config.TypedHitDamage;
        enemy["hp"] = hp;

        IncrementMetricInt(state, BattleWordsTypedKey, 1);
        events.Add($"typing_word_complete: target='{word}' damage={config.TypedHitDamage}");

        if (hp <= 0)
        {
            int goldReward = Convert.ToInt32(enemy.GetValueOrDefault("gold", DefaultEnemyGoldReward));
            state.Gold += goldReward;
            state.Enemies.RemoveAt(targetIndex);
            state.EnemiesDefeated++;
            events.Add($"Enemy defeated! +{goldReward} gold.");
            return;
        }

        state.Enemies[targetIndex] = enemy;
        events.Add($"Enemy survives with {hp} HP.");
    }

    private static void ApplyTypingMiss(GameState state, VerticalSliceWaveConfig config, List<string> events)
    {
        IncrementMetricInt(state, MissCountKey, 1);
        events.Add("typing_miss: no_match");

        if (!state.PracticeMode && config.TypedMissDamage > 0)
        {
            state.Hp -= config.TypedMissDamage;
            events.Add($"Miss. -{config.TypedMissDamage} HP.");
            if (state.Hp <= 0)
            {
                state.Phase = "game_over";
                events.Add("Game Over.");
            }
        }
    }

    private static void FinalizeResult(GameState state, bool victory, List<string> events)
    {
        string existing = GetMetricString(state, ResultKey, string.Empty);
        if (!string.IsNullOrEmpty(existing))
            return;

        string result = victory ? "victory" : "defeat";
        int elapsedSeconds = Math.Max(0, (int)MathF.Round(GetMetricFloat(state, RunClockKey, 0f)));
        int startHp = GetMetricInt(state, StartHpKey, state.Hp);
        int hpRemaining = Math.Max(0, state.Hp);
        int damageTaken = Math.Max(0, startHp - hpRemaining);
        int enemiesDefeated = Math.Max(0, state.EnemiesDefeated);
        int wordsTyped = Math.Max(0, GetMetricInt(state, BattleWordsTypedKey, 0));
        int misses = Math.Max(0, GetMetricInt(state, MissCountKey, 0));
        int score = ComputeScore(victory, hpRemaining, enemiesDefeated, wordsTyped, misses, damageTaken);

        SetMetricString(state, ResultKey, result);
        SetMetricInt(state, ScoreKey, score);
        SetMetricInt(state, ElapsedSecondsKey, elapsedSeconds);
        SetMetricInt(state, DamageTakenKey, damageTaken);

        var payload = new Dictionary<string, object>
        {
            ["result"] = result,
            ["score"] = score,
            ["elapsed_seconds"] = elapsedSeconds,
            ["enemies_defeated"] = enemiesDefeated,
            ["words_typed"] = wordsTyped,
            ["misses"] = misses,
            ["damage_taken"] = damageTaken,
            ["hp_remaining"] = hpRemaining,
            ["wave_total"] = state.NightWaveTotal,
            ["gold"] = state.Gold
        };
        SetMetricObject(state, SummaryPayloadKey, payload);

        events.Add(
            $"run_summary: result={result} score={score} " +
            $"time={elapsedSeconds}s enemies={enemiesDefeated} words={wordsTyped} " +
            $"misses={misses} damage={damageTaken}");
    }

    private static int ComputeScore(
        bool victory,
        int hpRemaining,
        int enemiesDefeated,
        int wordsTyped,
        int misses,
        int damageTaken)
    {
        int score = 0;
        if (victory)
            score += VictoryScoreBonus;

        score += enemiesDefeated * ScorePerEnemyDefeated;
        score += wordsTyped * ScorePerWordTyped;
        score += hpRemaining * ScorePerHpRemaining;
        score -= misses * ScorePenaltyPerMiss;
        score -= damageTaken * ScorePenaltyPerDamageTaken;

        return Math.Max(0, score);
    }

    private static int SelectTargetByPrefix(GameState state, string prefix)
    {
        int bestIndex = NoEnemyIndex;
        int bestDist = int.MaxValue;
        int bestWordLen = int.MaxValue;

        for (int i = 0; i < state.Enemies.Count; i++)
        {
            var enemy = state.Enemies[i];
            string word = TypingFeedback.NormalizeInput(enemy.GetValueOrDefault("word")?.ToString() ?? string.Empty);
            if (!word.StartsWith(prefix, StringComparison.Ordinal))
                continue;

            int dist = Convert.ToInt32(enemy.GetValueOrDefault("dist", DefaultEnemyDistance));
            int wordLen = word.Length;

            if (dist < bestDist || (dist == bestDist && wordLen < bestWordLen))
            {
                bestIndex = i;
                bestDist = dist;
                bestWordLen = wordLen;
            }
        }

        return bestIndex;
    }

    private static void SyncActiveTarget(GameState state)
    {
        int activeTargetId = GetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
        if (activeTargetId <= 0)
        {
            state.NightPrompt = string.Empty;
            SetMetricString(state, ActivePrefixKey, string.Empty);
            return;
        }

        int enemyIndex = TryGetEnemyIndexById(state, activeTargetId);
        if (enemyIndex < 0)
        {
            SetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
            SetMetricString(state, ActivePrefixKey, string.Empty);
            state.NightPrompt = string.Empty;
            return;
        }

        string word = TypingFeedback.NormalizeInput(
            state.Enemies[enemyIndex].GetValueOrDefault("word")?.ToString() ?? string.Empty);
        string prefix = GetMetricString(state, ActivePrefixKey, string.Empty);

        if (string.IsNullOrEmpty(word) || !word.StartsWith(prefix, StringComparison.Ordinal))
        {
            SetMetricInt(state, ActiveTargetIdKey, DefaultEnemyId);
            SetMetricString(state, ActivePrefixKey, string.Empty);
            state.NightPrompt = string.Empty;
            return;
        }

        state.NightPrompt = word.Length > prefix.Length
            ? word[prefix.Length..]
            : string.Empty;
    }

    private static void SpawnEnemy(GameState state, List<string> events)
    {
        if (state.NightSpawnRemaining <= 0)
            return;

        var usedWords = new HashSet<string>();
        foreach (var e in state.Enemies)
        {
            string w = e.GetValueOrDefault("word")?.ToString() ?? "";
            if (!string.IsNullOrEmpty(w))
                usedWords.Add(w);
        }

        string kind = PickEnemyKind(state);
        var spawnPos = SimMap.GetSpawnPos(state);
        string word = WordPool.WordForEnemy(
            state.RngSeed,
            state.Day,
            kind,
            state.EnemyNextId,
            usedWords,
            state.LessonId);

        var enemy = Enemies.MakeEnemy(state, kind, spawnPos, word, state.Day);
        state.Enemies.Add(enemy);
        state.NightSpawnRemaining--;
        events.Add($"Enemy spawned: '{word}'");
    }

    private static void TowerAttackStep(GameState state, VerticalSliceWaveConfig config, List<string> events)
    {
        if (state.Enemies.Count == 0 || config.TowerTickDamage <= 0)
            return;

        foreach (var (_, structureType) in state.Structures)
        {
            if (!structureType.StartsWith("auto_", StringComparison.Ordinal))
                continue;
            if (state.Enemies.Count == 0)
                break;

            var target = state.Enemies[0];
            int hp = Convert.ToInt32(target.GetValueOrDefault("hp", DefaultEnemyHp));
            hp -= config.TowerTickDamage;
            target["hp"] = hp;

            if (hp <= 0)
            {
                int goldReward = Convert.ToInt32(target.GetValueOrDefault("gold", DefaultEnemyGoldReward));
                state.Gold += goldReward;
                state.Enemies.RemoveAt(0);
                state.EnemiesDefeated++;
                events.Add($"Auto-tower defeats enemy! +{goldReward} gold.");
            }
            else
            {
                state.Enemies[0] = target;
            }
        }
    }

    private static void EnemyAdvanceStep(GameState state, VerticalSliceWaveConfig config, List<string> events)
    {
        for (int i = state.Enemies.Count - 1; i >= 0; i--)
        {
            var enemy = state.Enemies[i];
            int dist = Convert.ToInt32(enemy.GetValueOrDefault("dist", DefaultEnemyDistance));
            dist = Math.Max(0, dist - config.EnemyStepDistance);
            enemy["dist"] = dist;

            if (dist <= 0)
            {
                int enemyDamage = Convert.ToInt32(enemy.GetValueOrDefault("damage", config.EnemyContactDamage));
                int appliedDamage = Math.Max(config.EnemyContactDamage, enemyDamage);
                state.Hp -= appliedDamage;
                events.Add($"Enemy reached the base! -{appliedDamage} HP.");
                state.Enemies.RemoveAt(i);
                continue;
            }

            state.Enemies[i] = enemy;
        }

    }

    private static string PickEnemyKind(GameState state)
    {
        int idx = SimRng.RollRange(state, 0, EnemyKinds.Length - 1);
        return EnemyKinds[idx];
    }

    private static int FindEnemyIndexByWord(GameState state, string input)
    {
        for (int i = 0; i < state.Enemies.Count; i++)
        {
            string word = state.Enemies[i].GetValueOrDefault("word")?.ToString() ?? "";
            if (TypingFeedback.NormalizeInput(word) == input)
                return i;
        }

        for (int i = 0; i < state.Enemies.Count; i++)
        {
            string word = state.Enemies[i].GetValueOrDefault("word")?.ToString() ?? "";
            if (TypingFeedback.NormalizeInput(word).StartsWith(input, StringComparison.Ordinal))
                return i;
        }

        return NoEnemyIndex;
    }

    private static int TryGetEnemyIndexById(GameState state, int enemyId)
    {
        for (int i = 0; i < state.Enemies.Count; i++)
        {
            int id = Convert.ToInt32(state.Enemies[i].GetValueOrDefault("id", DefaultEnemyId));
            if (id == enemyId)
                return i;
        }
        return NoEnemyIndex;
    }

    private static float GetMetricFloat(GameState state, string key, float fallback)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return fallback;

        if (value is float f) return f;
        if (value is double d) return (float)d;
        if (value is int i) return i;
        if (float.TryParse(value.ToString(), out float parsed)) return parsed;
        return fallback;
    }

    private static void SetMetricFloat(GameState state, string key, float value)
    {
        state.TypingMetrics[key] = value;
    }

    private static int GetMetricInt(GameState state, string key, int fallback)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return fallback;

        if (value is int i) return i;
        if (int.TryParse(value.ToString(), out int parsed)) return parsed;
        return fallback;
    }

    private static void SetMetricInt(GameState state, string key, int value)
    {
        state.TypingMetrics[key] = value;
    }

    private static string GetMetricString(GameState state, string key, string fallback)
    {
        if (!state.TypingMetrics.TryGetValue(key, out object? value) || value == null)
            return fallback;

        string text = value.ToString() ?? fallback;
        return text;
    }

    private static void SetMetricString(GameState state, string key, string value)
    {
        state.TypingMetrics[key] = value;
    }

    private static void SetMetricObject(GameState state, string key, object value)
    {
        state.TypingMetrics[key] = value;
    }

    private static void IncrementMetricInt(GameState state, string key, int delta)
    {
        int current = 0;
        if (state.TypingMetrics.TryGetValue(key, out object? value) && value != null)
        {
            if (value is int intValue)
                current = intValue;
            else if (int.TryParse(value.ToString(), out int parsed))
                current = parsed;
        }
        state.TypingMetrics[key] = current + delta;
    }
}

/// <summary>
/// Configuration values that control spawn cadence, enemy advancement, and damage tuning
/// for a single vertical-slice wave simulation.
/// </summary>
public sealed class VerticalSliceWaveConfig
{
    private const int DefaultSpawnTotal = 6;
    private const float DefaultSpawnIntervalSeconds = 1.0f;
    private const float DefaultEnemyStepIntervalSeconds = 1.0f;
    private const int DefaultEnemyStepDistance = 1;
    private const int DefaultEnemyContactDamage = 1;
    private const int DefaultTypedHitDamage = 2;
    private const int DefaultTypedMissDamage = 1;
    private const int DefaultTowerTickDamage = 1;

    /// <summary>
    /// Total number of enemies to spawn during the wave.
    /// </summary>
    public int SpawnTotal { get; init; } = DefaultSpawnTotal;

    /// <summary>
    /// Seconds between enemy spawn attempts.
    /// </summary>
    public float SpawnIntervalSeconds { get; init; } = DefaultSpawnIntervalSeconds;

    /// <summary>
    /// Seconds between simulation combat/advance ticks.
    /// </summary>
    public float EnemyStepIntervalSeconds { get; init; } = DefaultEnemyStepIntervalSeconds;

    /// <summary>
    /// Distance each enemy advances per step tick.
    /// </summary>
    public int EnemyStepDistance { get; init; } = DefaultEnemyStepDistance;

    /// <summary>
    /// Minimum damage applied when an enemy reaches the base.
    /// </summary>
    public int EnemyContactDamage { get; init; } = DefaultEnemyContactDamage;

    /// <summary>
    /// Damage applied when typing fully completes an enemy word.
    /// </summary>
    public int TypedHitDamage { get; init; } = DefaultTypedHitDamage;

    /// <summary>
    /// Self-damage applied on typing misses when practice mode is disabled.
    /// </summary>
    public int TypedMissDamage { get; init; } = DefaultTypedMissDamage;

    /// <summary>
    /// Damage dealt by each auto tower during a tower tick.
    /// </summary>
    public int TowerTickDamage { get; init; } = DefaultTowerTickDamage;

    /// <summary>
    /// Creates a runtime wave configuration from a vertical-slice profile.
    /// </summary>
    public static VerticalSliceWaveConfig FromProfile(VerticalSliceWaveProfile profile)
    {
        return new VerticalSliceWaveConfig
        {
            SpawnTotal = profile.WaveSpawnTotal,
            SpawnIntervalSeconds = profile.SpawnIntervalSeconds,
            EnemyStepIntervalSeconds = profile.EnemyStepIntervalSeconds,
            EnemyStepDistance = profile.EnemyStepDistance,
            EnemyContactDamage = profile.EnemyContactDamage,
            TypedHitDamage = profile.TypedHitDamage,
            TypedMissDamage = profile.TypedMissDamage,
            TowerTickDamage = profile.TowerTickDamage,
        };
    }
}
