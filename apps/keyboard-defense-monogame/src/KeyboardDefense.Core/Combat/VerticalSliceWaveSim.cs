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

    private static readonly string[] EnemyKinds = { "scout", "raider", "armored", "swarm", "berserker" };

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

        events.Add($"Night falls. Enemy wave: {config.SpawnTotal}.");
    }

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

        if (!string.IsNullOrWhiteSpace(typedInput))
            ResolveTypedInput(state, config, typedInput!, events);

        if (state.Phase != "night")
            return;

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

        if (state.Phase != "night")
            return;

        if (state.Hp <= 0)
        {
            state.Phase = "game_over";
            events.Add("Game Over.");
            return;
        }

        if (state.NightSpawnRemaining <= 0 && state.Enemies.Count == 0)
        {
            state.Phase = "day";
            state.Ap = state.ApMax;
            state.NightPrompt = "";
            state.NightWaveTotal = 0;
            events.Add("Dawn breaks.");
        }
    }

    private static void ResolveTypedInput(
        GameState state,
        VerticalSliceWaveConfig config,
        string typedInput,
        List<string> events)
    {
        string normalized = TypingFeedback.NormalizeInput(typedInput);
        if (string.IsNullOrEmpty(normalized))
            return;

        IncrementMetricInt(state, "battle_chars_typed", normalized.Length);

        int targetIndex = FindEnemyIndexByWord(state, normalized);
        if (targetIndex < 0)
        {
            if (!state.PracticeMode && config.TypedMissDamage > 0)
            {
                state.Hp -= config.TypedMissDamage;
                events.Add("Miss. No matching enemy word.");
                if (state.Hp <= 0)
                {
                    state.Phase = "game_over";
                    events.Add("Game Over.");
                }
            }
            else
            {
                events.Add("Miss.");
            }
            return;
        }

        var enemy = state.Enemies[targetIndex];
        int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 1));
        hp -= config.TypedHitDamage;
        enemy["hp"] = hp;
        state.Enemies[targetIndex] = enemy;

        string enemyWord = enemy.GetValueOrDefault("word")?.ToString() ?? normalized;
        IncrementMetricInt(state, "battle_words_typed", 1);

        if (hp <= 0)
        {
            int goldReward = Convert.ToInt32(enemy.GetValueOrDefault("gold", 1));
            state.Gold += goldReward;
            state.Enemies.RemoveAt(targetIndex);
            state.EnemiesDefeated++;
            events.Add($"Typed '{enemyWord}' — enemy defeated! +{goldReward} gold.");
            return;
        }

        events.Add($"Typed '{enemyWord}' — {config.TypedHitDamage} damage. Enemy HP: {hp}.");
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
            int hp = Convert.ToInt32(target.GetValueOrDefault("hp", 1));
            hp -= config.TowerTickDamage;
            target["hp"] = hp;

            if (hp <= 0)
            {
                int goldReward = Convert.ToInt32(target.GetValueOrDefault("gold", 1));
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
            int dist = Convert.ToInt32(enemy.GetValueOrDefault("dist", 10));
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

        if (state.Hp <= 0)
        {
            state.Phase = "game_over";
            events.Add("Game Over.");
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

        return -1;
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

public sealed class VerticalSliceWaveConfig
{
    public int SpawnTotal { get; init; } = 6;
    public float SpawnIntervalSeconds { get; init; } = 1.0f;
    public float EnemyStepIntervalSeconds { get; init; } = 1.0f;
    public int EnemyStepDistance { get; init; } = 1;
    public int EnemyContactDamage { get; init; } = 1;
    public int TypedHitDamage { get; init; } = 2;
    public int TypedMissDamage { get; init; } = 1;
    public int TowerTickDamage { get; init; } = 1;

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

