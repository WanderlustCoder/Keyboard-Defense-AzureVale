using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Inline combat system for open-world encounters.
/// Handles encounter start, typing-to-damage, enemy approach, and encounter end.
/// </summary>
public static class InlineCombat
{
    public const int EncounterTriggerRadius = 2;
    public const float EnemyApproachSpeed = 0.3f; // tiles per second toward player

    /// <summary>Assign typing words to encounter enemies based on lesson and tier.</summary>
    public static void AssignWords(GameState state, List<Dictionary<string, object>> enemies)
    {
        var usedWords = new HashSet<string>();
        foreach (var enemy in enemies)
        {
            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "raider";
            int id = Convert.ToInt32(enemy.GetValueOrDefault("id", state.EnemyNextId++));
            string word = WordPool.WordForEnemy(
                state.RngSeed, state.Day, kind, id, usedWords, state.LessonId);
            enemy["word"] = word;
            usedWords.Add(word);
        }
    }

    /// <summary>
    /// Process typed input against encounter enemies.
    /// Returns events describing what happened.
    /// </summary>
    public static List<string> ProcessTyping(GameState state, string input)
    {
        var events = new List<string>();
        if (state.ActivityMode != "encounter" || state.EncounterEnemies.Count == 0)
            return events;

        string typed = input.Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(typed)) return events;

        // Find matching enemy by word
        Dictionary<string, object>? target = null;
        foreach (var enemy in state.EncounterEnemies)
        {
            string word = (enemy.GetValueOrDefault("word")?.ToString() ?? "").ToLowerInvariant();
            if (word == typed)
            {
                target = enemy;
                break;
            }
        }

        if (target == null)
        {
            events.Add($"Miss! No enemy has the word '{input}'.");
            // Track errors in typing metrics
            if (state.TypingMetrics.TryGetValue("battle_errors", out var errObj))
                state.TypingMetrics["battle_errors"] = Convert.ToInt32(errObj) + 1;
            return events;
        }

        // Calculate damage
        int baseDamage = 1;
        int combo = TypingMetrics.GetComboCount(state);
        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        var profTier = TypingProficiency.GetTier(wpm, accuracy);
        double profDamageMult = TypingProficiency.GetDamageMultiplier(profTier);
        int damage = (int)(SimBalance.CalculateTypingDamage(baseDamage, wpm, accuracy, combo) * profDamageMult);
        damage = Math.Max(1, damage);

        // Apply damage to enemy
        int hp = Convert.ToInt32(target.GetValueOrDefault("hp", 1));
        hp -= damage;
        target["hp"] = hp;

        // Track typing
        TypingMetrics.IncrementCombo(state);
        IncrementTypingMetric(state, "battle_words_typed");

        string kind = target.GetValueOrDefault("kind")?.ToString() ?? "enemy";

        if (hp <= 0)
        {
            // Enemy defeated
            state.EncounterEnemies.Remove(target);
            state.EnemiesDefeated++;

            // Award gold
            int tier = Convert.ToInt32(target.GetValueOrDefault("tier", 0));
            double profGoldMult = TypingProficiency.GetGoldMultiplier(profTier);
            int goldReward = (int)((3 + tier * 2) * profGoldMult);
            state.Gold += goldReward;

            events.Add($"Defeated {kind}! +{goldReward} gold. ({damage} damage)");

            // Check if encounter is over
            if (state.EncounterEnemies.Count == 0)
            {
                EndEncounter(state);
                events.Add("Encounter cleared! Continue exploring.");
            }
        }
        else
        {
            events.Add($"Hit {kind} for {damage} damage! ({hp} HP remaining)");
        }

        return events;
    }

    /// <summary>Tick enemy approach toward player. Called during encounter mode.</summary>
    public static List<string> TickEnemyApproach(GameState state, float delta)
    {
        var events = new List<string>();
        if (state.ActivityMode != "encounter") return events;

        var toRemove = new List<Dictionary<string, object>>();
        foreach (var enemy in state.EncounterEnemies)
        {
            if (enemy.GetValueOrDefault("pos") is not GridPoint ePos) continue;

            // Move toward player
            float approach = Convert.ToSingle(enemy.GetValueOrDefault("approach_progress", 0f));
            approach += EnemyApproachSpeed * delta;
            enemy["approach_progress"] = approach;

            // If approach reaches 1.0, enemy reaches player
            if (approach >= 1.0f)
            {
                // Enemy hits player
                int tier = Convert.ToInt32(enemy.GetValueOrDefault("tier", 0));
                int damage = 1 + tier;
                state.Hp -= damage;
                events.Add($"A {enemy.GetValueOrDefault("kind")} strikes you for {damage} damage!");
                toRemove.Add(enemy);

                if (state.Hp <= 0)
                {
                    state.Phase = "game_over";
                    events.Add("You have been defeated!");
                    break;
                }
            }
        }

        foreach (var enemy in toRemove)
            state.EncounterEnemies.Remove(enemy);

        // Check if encounter ended (all enemies gone)
        if (state.EncounterEnemies.Count == 0 && state.Phase != "game_over")
        {
            EndEncounter(state);
            events.Add("Encounter cleared! Continue exploring.");
        }

        return events;
    }

    /// <summary>End the encounter and return to exploration mode.</summary>
    public static void EndEncounter(GameState state)
    {
        state.ActivityMode = "exploration";
        state.EncounterEnemies.Clear();
        TypingMetrics.ResetCombo(state);
    }

    private static void IncrementTypingMetric(GameState state, string key)
    {
        if (state.TypingMetrics.TryGetValue(key, out var val))
            state.TypingMetrics[key] = Convert.ToInt32(val) + 1;
        else
            state.TypingMetrics[key] = 1;
    }
}
