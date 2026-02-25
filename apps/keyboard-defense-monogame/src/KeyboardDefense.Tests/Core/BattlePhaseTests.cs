using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class BattlePhaseTests
{
    [Fact]
    public void Wait_DuringNight_SpawnsEnemyOnEdgeTile()
    {
        var state = CreateNightState("battle_spawn_edge");
        state.NightSpawnRemaining = 1;

        var (newState, events) = ApplyWait(state);

        var enemy = Assert.Single(newState.Enemies);
        int x = Convert.ToInt32(enemy.GetValueOrDefault("pos_x", -1));
        int y = Convert.ToInt32(enemy.GetValueOrDefault("pos_y", -1));

        bool isOnEdge = x == 0 || y == 0 || x == newState.MapW - 1 || y == newState.MapH - 1;
        Assert.True(isOnEdge, $"Expected edge spawn, got ({x},{y}).");
        Assert.Equal(0, newState.NightSpawnRemaining);
        Assert.Contains(events, e => e.StartsWith("Enemy spawned: '", StringComparison.Ordinal));
    }

    [Fact]
    public void AutoTower_FiresAtEnemyWithinRange()
    {
        var state = CreateNightState("battle_tower_range");
        int towerIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;

        state.Enemies.Add(AutoEnemy(id: 1, pos: new GridPoint(state.BasePos.X + 1, state.BasePos.Y), hp: 12));
        state.Enemies.Add(AutoEnemy(id: 2, pos: new GridPoint(state.BasePos.X + 8, state.BasePos.Y), hp: 12));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Single(events);
        Assert.Equal(7, HpById(state, 1));
        Assert.Equal(12, HpById(state, 2));
    }

    [Fact]
    public void AutoTower_DoesNotFireWhenEnemiesAreOutOfRange()
    {
        var state = CreateNightState("battle_tower_out_of_range");
        int towerIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;

        state.Enemies.Add(AutoEnemy(id: 10, pos: new GridPoint(state.BasePos.X + 7, state.BasePos.Y + 7), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Empty(events);
        Assert.Equal(20, HpById(state, 10));
        Assert.False(state.TowerCooldowns.ContainsKey(towerIndex));
    }

    [Fact]
    public void EnemyReachingBase_ReducesPlayerHp()
    {
        var state = CreateNightState("battle_enemy_damage");
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(NightEnemy(word: "raider", hp: 6, gold: 2, dist: 1, damage: 3));
        int hpBefore = state.Hp;

        var (newState, events) = ApplyWait(state);

        Assert.Equal(hpBefore - 3, newState.Hp);
        Assert.Empty(newState.Enemies);
        Assert.Contains("Enemy reached the base! -3 HP.", events);
    }

    [Fact]
    public void KilledEnemy_DropsGoldReward()
    {
        var state = CreateNightState("battle_kill_reward");
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(NightEnemy(word: "alpha", hp: 1, gold: 5, dist: 6));
        state.Enemies.Add(NightEnemy(word: "bravo", hp: 20, gold: 1, dist: 6));
        int goldBefore = state.Gold;
        int defeatedBefore = state.EnemiesDefeated;

        var (newState, events) = ApplyDefendInput(state, "alpha");

        Assert.Equal(goldBefore + 5, newState.Gold);
        Assert.Equal(defeatedBefore + 1, newState.EnemiesDefeated);
        Assert.DoesNotContain(newState.Enemies, e => string.Equals(e["word"]?.ToString(), "alpha", StringComparison.Ordinal));
        Assert.Contains(events, e => e.Contains("+5 gold.", StringComparison.Ordinal));
    }

    [Fact]
    public void ClearingNightWave_TransitionsToDay()
    {
        var state = CreateNightState("battle_wave_transition");
        state.Ap = 0;
        state.Threat = 2;
        state.NightPrompt = "pending";
        state.NightWaveTotal = 4;
        state.NightSpawnRemaining = 0;

        var (newState, events) = ApplyWait(state);

        Assert.Equal("day", newState.Phase);
        Assert.Equal(newState.ApMax, newState.Ap);
        Assert.Equal(1, newState.Threat);
        Assert.Equal("", newState.NightPrompt);
        Assert.Equal(0, newState.NightWaveTotal);
        Assert.Contains("Dawn breaks.", events);
    }

    [Fact]
    public void MultipleTowers_FocusFireNearestEnemy()
    {
        var state = CreateNightState("battle_focus_fire");
        int leftTower = SimMap.Idx(state.BasePos.X - 1, state.BasePos.Y, state.MapW);
        int rightTower = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);
        state.Structures[leftTower] = AutoTowerTypes.Sentry;
        state.Structures[rightTower] = AutoTowerTypes.Sentry;

        state.Enemies.Add(AutoEnemy(id: 1, pos: new GridPoint(state.BasePos.X, state.BasePos.Y - 1), hp: 20));
        state.Enemies.Add(AutoEnemy(id: 2, pos: new GridPoint(state.BasePos.X, state.BasePos.Y + 3), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Equal(2, events.Count);
        Assert.All(events, e => Assert.Equal(1, Convert.ToInt32(e.GetValueOrDefault("target_id", -1))));
        Assert.Equal(10, HpById(state, 1));
        Assert.Equal(20, HpById(state, 2));
    }

    [Fact]
    public void TowerCooldown_PreventsRefireUntilRecovered()
    {
        var state = CreateNightState("battle_tower_cooldown");
        int towerIndex = SimMap.Idx(state.BasePos.X, state.BasePos.Y, state.MapW);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(AutoEnemy(id: 42, pos: new GridPoint(state.BasePos.X + 1, state.BasePos.Y), hp: 40));

        var firstTick = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var secondTick = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.5);
        var thirdTick = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.75);
        var fourthTick = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.0);

        Assert.Single(firstTick);
        Assert.Empty(secondTick);
        Assert.Empty(thirdTick);
        Assert.Single(fourthTick);
        Assert.Equal(1250, state.TowerCooldowns[towerIndex]);
        Assert.Equal(30, HpById(state, 42));
    }

    [Fact]
    public void EnemyAdvance_TowardBase_DecreasesDistanceEachNightStep()
    {
        var state = CreateNightState("battle_enemy_path_progress");
        state.NightSpawnRemaining = 0;
        state.Enemies.Add(NightEnemy(word: "crawler", hp: 10, gold: 1, dist: 4, damage: 1));

        var (afterFirst, _) = ApplyWait(state);
        var (afterSecond, _) = ApplyWait(afterFirst);

        Assert.Equal(3, Convert.ToInt32(afterFirst.Enemies[0].GetValueOrDefault("dist", -1)));
        Assert.Equal(2, Convert.ToInt32(afterSecond.Enemies[0].GetValueOrDefault("dist", -1)));
    }

    private static GameState CreateNightState(string seed)
    {
        var state = DefaultState.Create(seed);
        state.Phase = "night";
        state.Structures.Clear();
        state.TowerCooldowns.Clear();
        state.Enemies.Clear();
        return state;
    }

    private static int HpById(GameState state, int id)
    {
        var enemy = state.Enemies.Single(e => Convert.ToInt32(e.GetValueOrDefault("id", -1)) == id);
        return Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
    }

    private static Dictionary<string, object> NightEnemy(string word, int hp, int gold, int dist, int damage = 1)
    {
        return new Dictionary<string, object>
        {
            ["word"] = word,
            ["hp"] = hp,
            ["gold"] = gold,
            ["dist"] = dist,
            ["damage"] = damage,
            ["kind"] = "raider",
        };
    }

    private static Dictionary<string, object> AutoEnemy(int id, GridPoint pos, int hp)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["pos"] = pos,
            ["hp"] = hp,
            ["max_hp"] = hp,
            ["word"] = $"e{id}",
            ["damage"] = 1,
            ["speed"] = 1.0,
            ["kind"] = "raider",
        };
    }

    private static (GameState State, List<string> Events) ApplyWait(GameState state)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make("wait"));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }

    private static (GameState State, List<string> Events) ApplyDefendInput(GameState state, string input)
    {
        var intent = SimIntents.Make("defend_input", new Dictionary<string, object> { ["text"] = input });
        var result = IntentApplier.Apply(state, intent);
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }
}
