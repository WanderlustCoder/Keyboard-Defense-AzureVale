using System;
using System.Collections.Generic;
using System.Diagnostics;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class ProficiencyWiringTests : IDisposable
{
    public ProficiencyWiringTests()
    {
        TypingProfile.Instance.Reset();
    }

    public void Dispose()
    {
        TypingProfile.Instance.Reset();
    }

    private static GameState CreateMinimalState()
    {
        var state = new GameState
        {
            MapW = 16,
            MapH = 16,
            Hp = 20,
            Phase = "day",
            ActivityMode = "exploration",
            RngSeed = "prof_test",
            LessonId = "full_alpha",
        };
        state.BasePos = new GridPoint(8, 8);
        state.PlayerPos = state.BasePos;
        state.CursorPos = state.BasePos;
        state.Terrain.Clear();
        state.Discovered.Clear();
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add("plains");
        state.Discovered.Add(SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW));
        TypingMetrics.InitBattleMetrics(state);
        return state;
    }

    private static Dictionary<string, object> AddEncounterEnemy(GameState state, int hp, int tier)
    {
        state.ActivityMode = "encounter";
        var enemy = new Dictionary<string, object>
        {
            ["id"] = 1,
            ["kind"] = "raider",
            ["hp"] = hp,
            ["tier"] = tier,
            ["word"] = "test",
            ["pos"] = new GridPoint(9, 8),
            ["approach_progress"] = 0f,
        };
        state.EncounterEnemies.Add(enemy);
        return enemy;
    }

    private static void SetBattleMetrics(GameState state, int charsTyped, int errors, double elapsedSeconds)
    {
        state.TypingMetrics["battle_chars_typed"] = charsTyped;
        state.TypingMetrics["battle_errors"] = errors;
        state.TypingMetrics["battle_words_typed"] = Math.Max(1, charsTyped / 5);
        state.TypingMetrics["battle_start_msec"] =
            Stopwatch.GetTimestamp() - (long)(elapsedSeconds * Stopwatch.Frequency);
    }

    private static void SetHighProficiencyMetrics(GameState state)
    {
        // 75 chars in 10s => ~90 WPM, 2 errors => ~97.3% accuracy.
        SetBattleMetrics(state, charsTyped: 75, errors: 2, elapsedSeconds: 10.0);
    }

    private static void SetNoviceMetrics(GameState state)
    {
        // 25 chars in 10s => ~30 WPM, 7 errors => 72% accuracy.
        SetBattleMetrics(state, charsTyped: 25, errors: 7, elapsedSeconds: 10.0);
    }

    [Fact]
    public void CombatDamage_HighProficiency_DealsMoreDamage()
    {
        var state = CreateMinimalState();
        var enemy = AddEncounterEnemy(state, hp: 100, tier: 0);
        SetHighProficiencyMetrics(state);

        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        Assert.True(wpm >= 80.0);
        Assert.True(accuracy >= 0.95);
        Assert.Equal(TypingProficiency.ProficiencyTier.Grandmaster, TypingProficiency.GetTier(wpm, accuracy));

        int baseDamage = SimBalance.CalculateTypingDamage(1, wpm, accuracy, combo: 0);
        InlineCombat.ProcessTyping(state, "test");

        int hpAfter = Convert.ToInt32(enemy["hp"]);
        int damageDealt = 100 - hpAfter;
        Assert.True(damageDealt > baseDamage);
    }

    [Fact]
    public void CombatDamage_NoviceProficiency_NormalDamage()
    {
        var state = CreateMinimalState();
        var enemy = AddEncounterEnemy(state, hp: 100, tier: 0);
        SetNoviceMetrics(state);

        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        Assert.Equal(TypingProficiency.ProficiencyTier.Novice, TypingProficiency.GetTier(wpm, accuracy));

        int baseDamage = SimBalance.CalculateTypingDamage(1, wpm, accuracy, combo: 0);
        InlineCombat.ProcessTyping(state, "test");

        int hpAfter = Convert.ToInt32(enemy["hp"]);
        int damageDealt = 100 - hpAfter;
        Assert.Equal(baseDamage, damageDealt);
    }

    [Fact]
    public void GoldReward_HighProficiency_MoreGold()
    {
        var state = CreateMinimalState();
        AddEncounterEnemy(state, hp: 1, tier: 2);
        SetHighProficiencyMetrics(state);

        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        Assert.Equal(TypingProficiency.ProficiencyTier.Grandmaster, TypingProficiency.GetTier(wpm, accuracy));

        int baseGold = 3 + (2 * 2);
        int goldBefore = state.Gold;
        InlineCombat.ProcessTyping(state, "test");
        int gainedGold = state.Gold - goldBefore;

        Assert.True(gainedGold > baseGold);
    }

    [Fact]
    public void GoldReward_NoviceProficiency_BaseGold()
    {
        var state = CreateMinimalState();
        AddEncounterEnemy(state, hp: 1, tier: 2);
        SetNoviceMetrics(state);

        double wpm = TypingMetrics.GetCurrentWpm(state);
        double accuracy = TypingMetrics.GetAccuracy(state);
        Assert.Equal(TypingProficiency.ProficiencyTier.Novice, TypingProficiency.GetTier(wpm, accuracy));

        int baseGold = 3 + (2 * 2);
        int goldBefore = state.Gold;
        InlineCombat.ProcessTyping(state, "test");
        int gainedGold = state.Gold - goldBefore;

        Assert.Equal(baseGold, gainedGold);
    }

    [Fact]
    public void DiscoveryRadius_DefaultIs3()
    {
        var state = CreateMinimalState();
        Assert.Equal(TypingProficiency.ProficiencyTier.Novice, TypingProficiency.GetTier());

        var intent = new Dictionary<string, object>
        {
            ["kind"] = "move_player",
            ["dx"] = 1,
            ["dy"] = 0,
        };
        var result = IntentApplier.Apply(state, intent);
        var movedState = Assert.IsType<GameState>(result["state"]);

        const int defaultRadius = 3;
        int expectedDiscovered = (defaultRadius * 2 + 1) * (defaultRadius * 2 + 1);
        Assert.Equal(expectedDiscovered, movedState.Discovered.Count);
    }
}
