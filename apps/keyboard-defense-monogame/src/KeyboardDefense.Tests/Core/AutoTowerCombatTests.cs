using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class AutoTowerCombatCoreTests
{
    [Fact]
    public void ProcessAutoTowers_NoStructures_ReturnsEmptyEvents()
    {
        var state = CreateState();

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.1);

        Assert.Empty(events);
        Assert.Empty(state.TowerCooldowns);
    }

    [Fact]
    public void ProcessAutoTowers_StructureWithoutTowerDefinition_IsSkipped()
    {
        var state = CreateState();
        int towerIndex = Index(state, 1, 1);
        state.Structures[towerIndex] = "auto_missing";
        state.Enemies.Add(CreateEnemy(1, new GridPoint(1, 2), hp: 12));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.1);

        Assert.Empty(events);
        Assert.Equal(12, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.False(state.TowerCooldowns.ContainsKey(towerIndex));
    }

    [Fact]
    public void ProcessAutoTowers_NonContactTowerWithZeroAttackSpeed_IsSkipped()
    {
        var original = AutoTowerTypes.Towers[AutoTowerTypes.Sentry];

        try
        {
            AutoTowerTypes.Towers[AutoTowerTypes.Sentry] = original with { AttackSpeed = 0.0 };

            var state = CreateState();
            int towerIndex = Index(state, 2, 2);
            state.Structures[towerIndex] = AutoTowerTypes.Sentry;
            state.Enemies.Add(CreateEnemy(11, new GridPoint(2, 3), hp: 20));

            var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.2);

            Assert.Empty(events);
            Assert.Equal(20, Convert.ToInt32(state.Enemies[0]["hp"]));
            Assert.False(state.TowerCooldowns.ContainsKey(towerIndex));
        }
        finally
        {
            AutoTowerTypes.Towers[AutoTowerTypes.Sentry] = original;
        }
    }

    [Fact]
    public void ProcessAutoTowers_ValidTowerWithEnemyInRange_AppliesDamage()
    {
        var state = CreateState();
        int towerIndex = Index(state, 3, 3);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(21, new GridPoint(4, 3), hp: 12));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Single(events);
        Assert.Equal(7, Convert.ToInt32(state.Enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessAutoTowers_AttackEventContainsExpectedPayload()
    {
        var state = CreateState();
        int towerIndex = Index(state, 1, 1);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(31, new GridPoint(1, 2), hp: 9));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var attackEvent = Assert.Single(events);

        Assert.Equal("auto_tower_attack", attackEvent["type"]);
        Assert.Equal(towerIndex, Convert.ToInt32(attackEvent["tower_index"]));
        Assert.Equal(AutoTowerTypes.Sentry, attackEvent["tower_type"]);
        Assert.Equal(31, Convert.ToInt32(attackEvent["target_id"]));
        Assert.Equal(5, Convert.ToInt32(attackEvent["damage"]));
        Assert.False(Convert.ToBoolean(attackEvent["killed"]));
    }

    [Fact]
    public void ProcessAutoTowers_WhenTowerFires_SetsCooldownFromAttackSpeed()
    {
        var state = CreateState();
        int towerIndex = Index(state, 2, 1);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(41, new GridPoint(2, 2), hp: 15));

        AutoTowerCombat.ProcessAutoTowers(state, delta: 0.1);

        Assert.Equal(1250, state.TowerCooldowns[towerIndex]);
    }

    [Fact]
    public void ProcessAutoTowers_CooldownPreventsImmediateRefire()
    {
        var state = CreateState();
        int towerIndex = Index(state, 4, 4);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(51, new GridPoint(4, 5), hp: 20));

        AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var secondTickEvents = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.1);

        Assert.Empty(secondTickEvents);
        Assert.Equal(15, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Equal(1150, state.TowerCooldowns[towerIndex]);
    }

    [Fact]
    public void ProcessAutoTowers_CooldownDecrementsByDeltaMilliseconds()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.TowerCooldowns[towerIndex] = 900;
        state.Enemies.Add(CreateEnemy(61, new GridPoint(0, 1), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.25);

        Assert.Empty(events);
        Assert.Equal(650, state.TowerCooldowns[towerIndex]);
    }

    [Fact]
    public void ProcessAutoTowers_CooldownNeverDropsBelowZero()
    {
        var state = CreateState();
        int towerIndex = Index(state, 5, 1);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.TowerCooldowns[towerIndex] = 150;
        state.Enemies.Add(CreateEnemy(71, new GridPoint(5, 2), hp: 10));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.5);

        Assert.Empty(events);
        Assert.Equal(0, state.TowerCooldowns[towerIndex]);
    }

    [Fact]
    public void ProcessAutoTowers_CooldownReachesZero_FiresOnNextTick()
    {
        var state = CreateState();
        int towerIndex = Index(state, 6, 2);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.TowerCooldowns[towerIndex] = 100;
        state.Enemies.Add(CreateEnemy(81, new GridPoint(6, 3), hp: 20));

        var firstTickEvents = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.2);
        var secondTickEvents = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.0);

        Assert.Empty(firstTickEvents);
        Assert.Single(secondTickEvents);
        Assert.Equal(15, Convert.ToInt32(state.Enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessAutoTowers_MultipleTowers_ManageCooldownsIndependently()
    {
        var state = CreateState();
        int sentryIndex = Index(state, 1, 6);
        int flameIndex = Index(state, 6, 1);
        state.Structures[sentryIndex] = AutoTowerTypes.Sentry;
        state.Structures[flameIndex] = AutoTowerTypes.Flame;
        state.TowerCooldowns[sentryIndex] = 500;
        state.Enemies.Add(CreateEnemy(91, new GridPoint(1, 7), hp: 20));
        state.Enemies.Add(CreateEnemy(92, new GridPoint(6, 2), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.1);

        var attackEvent = Assert.Single(events);
        Assert.Equal(flameIndex, Convert.ToInt32(attackEvent["tower_index"]));
        Assert.Equal(20, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Equal(14, Convert.ToInt32(state.Enemies[1]["hp"]));
        Assert.Equal(400, state.TowerCooldowns[sentryIndex]);
        Assert.Equal(500, state.TowerCooldowns[flameIndex]);
    }

    [Fact]
    public void ProcessAutoTowers_MultipleReadyTowers_EachFire()
    {
        var state = CreateState();
        int sentryIndex = Index(state, 2, 6);
        int flameIndex = Index(state, 7, 2);
        state.Structures[sentryIndex] = AutoTowerTypes.Sentry;
        state.Structures[flameIndex] = AutoTowerTypes.Flame;
        state.Enemies.Add(CreateEnemy(101, new GridPoint(2, 7), hp: 20));
        state.Enemies.Add(CreateEnemy(102, new GridPoint(7, 3), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Equal(2, events.Count);
        Assert.Contains(events, e => Convert.ToInt32(e["tower_index"]) == sentryIndex);
        Assert.Contains(events, e => Convert.ToInt32(e["tower_index"]) == flameIndex);
        Assert.Equal(15, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Equal(14, Convert.ToInt32(state.Enemies[1]["hp"]));
    }

    [Fact]
    public void ProcessAutoTowers_KilledFlagTrue_WhenHpReachesZero()
    {
        var state = CreateState();
        int towerIndex = Index(state, 3, 1);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(111, new GridPoint(3, 2), hp: 5, maxHp: 5));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var attackEvent = Assert.Single(events);

        Assert.Equal(0, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.True(Convert.ToBoolean(attackEvent["killed"]));
    }

    [Fact]
    public void ProcessAutoTowers_KilledFlagTrue_WhenHpDropsBelowZero()
    {
        var state = CreateState();
        int towerIndex = Index(state, 4, 1);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(121, new GridPoint(4, 2), hp: 3, maxHp: 3));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var attackEvent = Assert.Single(events);

        Assert.Equal(-2, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.True(Convert.ToBoolean(attackEvent["killed"]));
    }

    [Fact]
    public void ProcessAutoTowers_NoTargetsInRange_ProducesNoEventsAndNoCooldown()
    {
        var state = CreateState();
        int towerIndex = Index(state, 0, 0);
        state.Structures[towerIndex] = AutoTowerTypes.Sentry;
        state.Enemies.Add(CreateEnemy(131, new GridPoint(9, 9), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Empty(events);
        Assert.Equal(20, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.False(state.TowerCooldowns.ContainsKey(towerIndex));
    }

    [Fact]
    public void ProcessAutoTowers_ContactModeWithZeroAttackSpeed_HitsAdjacentEnemy()
    {
        var state = CreateState();
        int towerIndex = Index(state, 5, 5);
        state.Structures[towerIndex] = AutoTowerTypes.Thorns;
        state.Enemies.Add(CreateEnemy(141, new GridPoint(5, 6), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var attackEvent = Assert.Single(events);

        Assert.Equal(12, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Equal(8, Convert.ToInt32(attackEvent["damage"]));
        Assert.False(state.TowerCooldowns.ContainsKey(towerIndex));
    }

    [Fact]
    public void ProcessAutoTowers_ContactModeWithZeroAttackSpeed_FiresConsecutiveTicks()
    {
        var state = CreateState();
        int towerIndex = Index(state, 6, 6);
        state.Structures[towerIndex] = AutoTowerTypes.Thorns;
        state.Enemies.Add(CreateEnemy(151, new GridPoint(6, 7), hp: 30));

        var firstTickEvents = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);
        var secondTickEvents = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Single(firstTickEvents);
        Assert.Single(secondTickEvents);
        Assert.Equal(14, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.False(state.TowerCooldowns.ContainsKey(towerIndex));
    }

    [Fact]
    public void ProcessAutoTowers_ContactMode_DoesNotHitNonAdjacentEnemies()
    {
        var state = CreateState();
        int towerIndex = Index(state, 3, 3);
        state.Structures[towerIndex] = AutoTowerTypes.Thorns;
        state.Enemies.Add(CreateEnemy(161, new GridPoint(3, 5), hp: 20));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Empty(events);
        Assert.Equal(20, Convert.ToInt32(state.Enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessAutoTowers_ZoneTower_HitsAllEnemiesWithinRange()
    {
        var state = CreateState();
        int towerIndex = Index(state, 4, 4);
        state.Structures[towerIndex] = AutoTowerTypes.Spark;
        state.Enemies.Add(CreateEnemy(171, new GridPoint(4, 5), hp: 10));
        state.Enemies.Add(CreateEnemy(172, new GridPoint(5, 5), hp: 11));
        state.Enemies.Add(CreateEnemy(173, new GridPoint(7, 7), hp: 12));

        var events = AutoTowerCombat.ProcessAutoTowers(state, delta: 0.016);

        Assert.Equal(2, events.Count);
        Assert.Equal(7, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Equal(8, Convert.ToInt32(state.Enemies[1]["hp"]));
        Assert.Equal(12, Convert.ToInt32(state.Enemies[2]["hp"]));
        Assert.Equal(1492, state.TowerCooldowns[towerIndex]);
    }

    private static GameState CreateState(int mapWidth = 10)
    {
        return new GameState
        {
            MapW = mapWidth,
            Structures = new Dictionary<int, string>(),
            Enemies = new List<Dictionary<string, object>>(),
            TowerCooldowns = new Dictionary<int, int>(),
        };
    }

    private static int Index(GameState state, int x, int y) => new GridPoint(x, y).ToIndex(state.MapW);

    private static Dictionary<string, object> CreateEnemy(
        int id,
        GridPoint pos,
        int hp = 20,
        int maxHp = 20,
        string word = "word")
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["pos"] = pos,
            ["hp"] = hp,
            ["max_hp"] = maxHp,
            ["word"] = word,
        };
    }
}
