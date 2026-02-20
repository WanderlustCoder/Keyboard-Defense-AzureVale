using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.Intent;

public static partial class IntentApplier
{
    private static bool ApplyDefendInput(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        if (state.Phase != "night")
        {
            events.Add("No threats to defend right now.");
            return false;
        }
        string text = intent.GetValueOrDefault("text")?.ToString() ?? "";
        string normalized = TypingFeedback.NormalizeInput(text);
        if (string.IsNullOrEmpty(normalized))
        {
            events.Add("Type an enemy word to defend.");
            return false;
        }
        int targetIndex = FindEnemyIndexByWord(state, normalized);
        if (targetIndex >= 0)
            return AdvanceNightStep(state, targetIndex, true, events, normalized);
        if (state.Enemies.Count == 0)
        {
            events.Add("No enemies yet; wait or defend after spawn.");
            return AdvanceNightStep(state, -1, false, events, "");
        }
        return AdvanceNightStep(state, -1, true, events, "");
    }

    private static bool ApplyWait(GameState state, List<string> events)
    {
        if (state.Phase != "night")
        {
            events.Add("Wait is only available at night.");
            return false;
        }
        return AdvanceNightStep(state, -1, false, events, "");
    }

    private static bool AdvanceNightStep(GameState state, int hitEnemyIndex, bool applyMissPenalty, List<string> events, string hitWord)
    {
        // Player attack
        if (hitEnemyIndex >= 0)
        {
            ApplyPlayerAttack(state, hitEnemyIndex, hitWord, events);
        }
        else if (applyMissPenalty)
        {
            if (!state.PracticeMode)
            {
                state.Hp -= 1;
                events.Add("Miss. No matching enemy word.");
            }
            else
            {
                events.Add("Miss. (practice mode - no damage)");
            }
        }
        else
        {
            events.Add("Waited.");
        }

        // Spawn enemies
        SpawnEnemyStep(state, events);

        // Tower attacks
        TowerAttackStep(state, events);

        // Enemy movement
        EnemyMoveStep(state, events);

        // Check game over
        if (state.Hp <= 0)
        {
            state.Phase = "game_over";
            events.Add("Game Over.");
            return false;
        }

        // Check dawn
        if (state.NightSpawnRemaining <= 0 && state.Enemies.Count == 0)
        {
            state.Phase = "day";
            state.Ap = state.ApMax;
            state.NightPrompt = "";
            state.NightWaveTotal = 0;
            state.Threat = Math.Max(0, state.Threat - 1);

            // Victory check
            if (state.Day >= 21)
            {
                state.Phase = "victory";
                events.Add("VICTORY! The kingdom is saved!");
                events.Add($"You survived {state.Day} days and defeated all bosses.");
                events.Add($"Final gold: {state.Gold}");
                return true;
            }
            events.Add("Dawn breaks.");
            return true;
        }

        return false;
    }

    private static void ApplyPlayerAttack(GameState state, int targetIndex, string hitWord, List<string> events)
    {
        if (targetIndex < 0 || targetIndex >= state.Enemies.Count)
        {
            events.Add("No matching targets.");
            return;
        }
        var enemy = state.Enemies[targetIndex];
        int baseDamage = SimBalance.CalculateTypingDamage(SimBalance.TypingBaseDamage, 60.0, 1.0, 0);
        int damage = Math.Max(1, baseDamage);

        int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 1));
        hp -= damage;
        enemy["hp"] = hp;
        state.Enemies[targetIndex] = enemy;

        string enemyWord = enemy.GetValueOrDefault("word")?.ToString() ?? "";
        string wordText = !string.IsNullOrEmpty(hitWord) ? hitWord : enemyWord;

        if (hp <= 0)
        {
            int goldReward = Convert.ToInt32(enemy.GetValueOrDefault("gold", 1));
            state.Gold += goldReward;
            state.Enemies.RemoveAt(targetIndex);
            state.EnemiesDefeated++;
            events.Add($"Typed '{wordText}' — {damage} damage. Enemy defeated! +{goldReward} gold.");
        }
        else
        {
            events.Add($"Typed '{wordText}' — {damage} damage. Enemy HP: {hp}.");
        }
    }

    private static void SpawnEnemyStep(GameState state, List<string> events)
    {
        if (state.NightSpawnRemaining <= 0) return;
        var spawnPos = SimMap.GetSpawnPos(state);
        var usedWords = new HashSet<string>();
        foreach (var e in state.Enemies)
        {
            string w = e.GetValueOrDefault("word")?.ToString() ?? "";
            if (!string.IsNullOrEmpty(w)) usedWords.Add(w);
        }
        string kind = PickEnemyKind(state);
        string word = WordPool.WordForEnemy(state.RngSeed, state.Day, kind, state.EnemyNextId, usedWords, state.LessonId);
        var enemy = Enemies.MakeEnemy(state, kind, spawnPos, word, state.Day);
        state.Enemies.Add(enemy);
        state.NightSpawnRemaining--;
        events.Add($"Enemy spawned: '{word}'");
    }

    private static void TowerAttackStep(GameState state, List<string> events)
    {
        // Auto-towers attack enemies
        var toRemove = new List<int>();
        foreach (var (index, towerType) in state.Structures)
        {
            if (!towerType.StartsWith("auto_")) continue;
            if (state.Enemies.Count == 0) break;

            // Simple: auto-tower deals 1 damage to first enemy
            var target = state.Enemies[0];
            int hp = Convert.ToInt32(target.GetValueOrDefault("hp", 1));
            hp -= 1;
            target["hp"] = hp;
            state.Enemies[0] = target;
            if (hp <= 0)
            {
                int goldReward = Convert.ToInt32(target.GetValueOrDefault("gold", 1));
                state.Gold += goldReward;
                state.EnemiesDefeated++;
                toRemove.Add(0);
                events.Add($"Auto-tower defeats enemy! +{goldReward} gold.");
            }
        }
        // Remove defeated enemies (reverse order to preserve indices)
        foreach (int idx in toRemove.OrderByDescending(i => i))
        {
            if (idx < state.Enemies.Count)
                state.Enemies.RemoveAt(idx);
        }
    }

    private static void EnemyMoveStep(GameState state, List<string> events)
    {
        foreach (var enemy in state.Enemies)
        {
            // Enemies deal damage when they reach the base
            int dist = Convert.ToInt32(enemy.GetValueOrDefault("dist", 10));
            dist--;
            enemy["dist"] = dist;
            if (dist <= 0)
            {
                int dmg = Convert.ToInt32(enemy.GetValueOrDefault("damage", 1));
                state.Hp -= dmg;
                events.Add($"Enemy reached the base! -{dmg} HP.");
            }
        }
        // Remove enemies that reached base
        state.Enemies.RemoveAll(e => Convert.ToInt32(e.GetValueOrDefault("dist", 10)) <= 0);
    }

    private static string PickEnemyKind(GameState state)
    {
        string[] kinds = { "scout", "raider", "armored", "swarm", "berserker" };
        int idx = SimRng.RollRange(state, 0, kinds.Length - 1);
        return kinds[idx];
    }

    private static int FindEnemyIndexByWord(GameState state, string input)
    {
        for (int i = 0; i < state.Enemies.Count; i++)
        {
            string word = state.Enemies[i].GetValueOrDefault("word")?.ToString() ?? "";
            if (TypingFeedback.NormalizeInput(word) == input)
                return i;
        }
        // Prefix match fallback
        for (int i = 0; i < state.Enemies.Count; i++)
        {
            string word = state.Enemies[i].GetValueOrDefault("word")?.ToString() ?? "";
            if (TypingFeedback.NormalizeInput(word).StartsWith(input))
                return i;
        }
        return -1;
    }

    // --- Session actions ---
    private static Dictionary<string, object> ApplyRestart(GameState state, List<string> events)
    {
        if (state.Phase != "game_over" && state.Phase != "victory")
        {
            events.Add("Restart is only available after game over or victory.");
            return new() { ["state"] = state, ["events"] = events };
        }
        string seedValue = state.RngSeed;
        var newState = DefaultState.Create(seedValue, true);
        newState.LessonId = state.LessonId;
        events.Add(state.Phase == "victory"
            ? $"Starting a new challenge with seed '{seedValue}'."
            : $"Restarted run with seed '{seedValue}'.");
        return new() { ["state"] = newState, ["events"] = events };
    }

    private static Dictionary<string, object> ApplyNew(GameState state, List<string> events)
    {
        string seedValue = state.RngSeed;
        var newState = DefaultState.Create(seedValue, true);
        newState.LessonId = state.LessonId;
        events.Add($"New run started with seed '{seedValue}'.");
        return new() { ["state"] = newState, ["events"] = events };
    }
}
