using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SummonedUnitsCoreTests
{
    [Fact]
    public void MaxSummonsPerTower_HasExpectedValue()
    {
        Assert.Equal(3, SummonedUnits.MaxSummonsPerTower);
    }

    [Fact]
    public void BaseUnitHp_HasExpectedValue()
    {
        Assert.Equal(15, SummonedUnits.BaseUnitHp);
    }

    [Fact]
    public void BaseUnitDamage_HasExpectedValue()
    {
        Assert.Equal(4, SummonedUnits.BaseUnitDamage);
    }

    [Fact]
    public void BaseUnitSpeed_HasExpectedValue()
    {
        Assert.Equal(1.0, SummonedUnits.BaseUnitSpeed);
    }

    [Fact]
    public void CreateUnit_ReturnsDictionaryWithAllExpectedKeys()
    {
        var state = CreateState();

        var unit = SummonedUnits.CreateUnit(state, towerIndex: 8, level: 2);

        var expectedKeys = new HashSet<string>
        {
            "id",
            "tower_index",
            "hp",
            "max_hp",
            "damage",
            "speed",
            "pos",
            "target_id",
        };

        Assert.Equal(expectedKeys.Count, unit.Count);
        Assert.True(expectedKeys.SetEquals(unit.Keys));
    }

    [Fact]
    public void CreateUnit_SetsTowerIndexAndDefaultTargetId()
    {
        var state = CreateState();

        var unit = SummonedUnits.CreateUnit(state, towerIndex: 12, level: 1);

        Assert.Equal(12, Convert.ToInt32(unit["tower_index"]));
        Assert.Equal(-1, Convert.ToInt32(unit["target_id"]));
    }

    [Fact]
    public void CreateUnit_SetsPositionFromTowerIndexAndMapWidth()
    {
        var state = CreateState(mapWidth: 7);

        var unit = SummonedUnits.CreateUnit(state, towerIndex: 19, level: 0);

        var pos = Assert.IsType<GridPoint>(unit["pos"]);
        Assert.Equal(GridPoint.FromIndex(19, 7), pos);
    }

    [Fact]
    public void CreateUnit_LevelZeroUsesBaseStats()
    {
        var state = CreateState();

        var unit = SummonedUnits.CreateUnit(state, towerIndex: 1, level: 0);

        Assert.Equal(SummonedUnits.BaseUnitHp, Convert.ToInt32(unit["hp"]));
        Assert.Equal(SummonedUnits.BaseUnitHp, Convert.ToInt32(unit["max_hp"]));
        Assert.Equal(SummonedUnits.BaseUnitDamage, Convert.ToInt32(unit["damage"]));
        Assert.Equal(SummonedUnits.BaseUnitSpeed, Convert.ToDouble(unit["speed"]));
    }

    [Fact]
    public void CreateUnit_LevelScalingIncreasesHpAndDamage()
    {
        var state = CreateState();

        var unit = SummonedUnits.CreateUnit(state, towerIndex: 1, level: 3);

        Assert.Equal(30, Convert.ToInt32(unit["hp"]));
        Assert.Equal(30, Convert.ToInt32(unit["max_hp"]));
        Assert.Equal(10, Convert.ToInt32(unit["damage"]));
    }

    [Fact]
    public void CreateUnit_AutoIncrementsIdAcrossCalls()
    {
        var state = CreateState();

        var first = SummonedUnits.CreateUnit(state, towerIndex: 1, level: 0);
        var second = SummonedUnits.CreateUnit(state, towerIndex: 2, level: 0);

        Assert.Equal(1, Convert.ToInt32(first["id"]));
        Assert.Equal(2, Convert.ToInt32(second["id"]));
        Assert.Equal(3, state.SummonedNextId);
    }

    [Fact]
    public void CanSummon_WhenTowerHasNoTrackedSummons_ReturnsTrue()
    {
        var state = CreateState();

        var canSummon = SummonedUnits.CanSummon(state, towerIndex: 4);

        Assert.True(canSummon);
    }

    [Fact]
    public void CanSummon_WhenTowerHasFewerThanMaxActive_ReturnsTrue()
    {
        var state = CreateState();
        state.TowerSummonIds[3] = new List<int> { 1, 2 };
        state.SummonedUnits.Add(MakeUnit(1, hp: 5));
        state.SummonedUnits.Add(MakeUnit(2, hp: 8));

        var canSummon = SummonedUnits.CanSummon(state, towerIndex: 3);

        Assert.True(canSummon);
    }

    [Fact]
    public void CanSummon_WhenTowerHasMaxActive_ReturnsFalse()
    {
        var state = CreateState();
        state.TowerSummonIds[9] = new List<int> { 10, 11, 12 };
        state.SummonedUnits.Add(MakeUnit(10, hp: 3));
        state.SummonedUnits.Add(MakeUnit(11, hp: 4));
        state.SummonedUnits.Add(MakeUnit(12, hp: 5));

        var canSummon = SummonedUnits.CanSummon(state, towerIndex: 9);

        Assert.False(canSummon);
    }

    [Fact]
    public void CanSummon_IgnoresTrackedIdsThatAreNoLongerActive()
    {
        var state = CreateState();
        state.TowerSummonIds[2] = new List<int> { 21, 22, 23 };
        state.SummonedUnits.Add(MakeUnit(99, hp: 10));

        var canSummon = SummonedUnits.CanSummon(state, towerIndex: 2);

        Assert.True(canSummon);
    }

    [Fact]
    public void SpawnUnit_WhenAllowed_AddsToSummonedUnitsAndReturnsUnit()
    {
        var state = CreateState();

        var spawned = SummonedUnits.SpawnUnit(state, towerIndex: 6, level: 2);

        Assert.NotNull(spawned);
        Assert.Single(state.SummonedUnits);
        Assert.Same(spawned, state.SummonedUnits[0]);
    }

    [Fact]
    public void SpawnUnit_WhenAllowed_RegistersUnitIdInTowerSummonIds()
    {
        var state = CreateState();

        var spawned = SummonedUnits.SpawnUnit(state, towerIndex: 6, level: 1);

        Assert.NotNull(spawned);
        var spawnedId = Convert.ToInt32(spawned!["id"]);
        Assert.True(state.TowerSummonIds.ContainsKey(6));
        Assert.Single(state.TowerSummonIds[6]);
        Assert.Equal(spawnedId, state.TowerSummonIds[6][0]);
    }

    [Fact]
    public void SpawnUnit_WhenTowerIsAtMax_ReturnsNullAndDoesNotChangeState()
    {
        var state = CreateState();
        state.SummonedNextId = 42;
        state.TowerSummonIds[5] = new List<int> { 10, 11, 12 };
        state.SummonedUnits.Add(MakeUnit(10, hp: 8));
        state.SummonedUnits.Add(MakeUnit(11, hp: 7));
        state.SummonedUnits.Add(MakeUnit(12, hp: 6));

        var spawned = SummonedUnits.SpawnUnit(state, towerIndex: 5, level: 4);

        Assert.Null(spawned);
        Assert.Equal(3, state.SummonedUnits.Count);
        Assert.Equal(new List<int> { 10, 11, 12 }, state.TowerSummonIds[5]);
        Assert.Equal(42, state.SummonedNextId);
    }

    [Fact]
    public void MultipleTowersCanSummonIndependently()
    {
        var state = CreateState();
        state.TowerSummonIds[1] = new List<int> { 1, 2, 3 };
        state.SummonedUnits.Add(MakeUnit(1, hp: 10));
        state.SummonedUnits.Add(MakeUnit(2, hp: 10));
        state.SummonedUnits.Add(MakeUnit(3, hp: 10));

        Assert.False(SummonedUnits.CanSummon(state, towerIndex: 1));
        Assert.True(SummonedUnits.CanSummon(state, towerIndex: 2));

        var blocked = SummonedUnits.SpawnUnit(state, towerIndex: 1, level: 0);
        var allowed = SummonedUnits.SpawnUnit(state, towerIndex: 2, level: 0);

        Assert.Null(blocked);
        Assert.NotNull(allowed);
        Assert.Equal(4, state.SummonedUnits.Count);
        Assert.True(state.TowerSummonIds.ContainsKey(2));
        Assert.Single(state.TowerSummonIds[2]);
    }

    [Fact]
    public void RemoveDeadUnits_RemovesUnitsWithZeroOrNegativeHp()
    {
        var state = CreateState();
        state.SummonedUnits.Add(MakeUnit(1, hp: 5));
        state.SummonedUnits.Add(MakeUnit(2, hp: 0));
        state.SummonedUnits.Add(MakeUnit(3, hp: -2));

        SummonedUnits.RemoveDeadUnits(state);

        var remainingIds = state.SummonedUnits.Select(u => Convert.ToInt32(u["id"])).ToList();
        Assert.Equal(new List<int> { 1 }, remainingIds);
    }

    [Fact]
    public void RemoveDeadUnits_KeepsAliveUnits()
    {
        var state = CreateState();
        state.SummonedUnits.Add(MakeUnit(7, hp: 1));
        state.SummonedUnits.Add(MakeUnit(8, hp: 20));

        SummonedUnits.RemoveDeadUnits(state);

        var remainingIds = state.SummonedUnits.Select(u => Convert.ToInt32(u["id"])).ToList();
        Assert.Equal(new List<int> { 7, 8 }, remainingIds);
    }

    private static GameState CreateState(int mapWidth = 10)
    {
        var state = new GameState
        {
            MapW = mapWidth,
            SummonedNextId = 1,
        };

        state.SummonedUnits = new List<Dictionary<string, object>>();
        state.TowerSummonIds = new Dictionary<int, List<int>>();
        return state;
    }

    private static Dictionary<string, object> MakeUnit(int id, int hp)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["hp"] = hp,
        };
    }
}
