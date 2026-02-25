using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class TowerCombatTests
{
    [Fact]
    public void ProcessTowerAttacks_SingleCategory_AttacksTargetAndAddsEvent()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Arrow", category: "single", damage: 7),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, word: "wisp"),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Single(events);
        Assert.Equal("Arrow hits wisp for 7.", events[0]);
        Assert.Equal(13, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTowerAttacks_UnknownCategory_FallsBackToSingleAttack()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Fallback", category: "mystery", damage: 6),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 10, word: "imp"),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Single(events);
        Assert.Equal("Fallback hits imp for 6.", events[0]);
        Assert.Equal(4, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTowerAttacks_SupportAndSummonerCategories_DoNotAttack()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Banner", category: "support", damage: 999),
            Tower(name: "Caller", category: "summoner", damage: 999),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Empty(events);
        Assert.Equal(20, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTowerAttacks_DoesNotMutateTowerCooldowns()
    {
        var state = new GameState();
        state.TowerCooldowns[42] = 750;
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Arrow", category: "single", damage: 5),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20),
        };

        TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Single(state.TowerCooldowns);
        Assert.Equal(750, state.TowerCooldowns[42]);
    }

    [Fact]
    public void ProcessSingleAttack_NoAliveTarget_DoesNothing()
    {
        var state = new GameState();
        var tower = Tower(name: "Arrow", category: "single", damage: 5);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, alive: false),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Empty(events);
        Assert.Equal(20, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessSingleAttack_UsesDamageTypeAndAddsExpectedEvent()
    {
        var state = new GameState();
        var tower = Tower(name: "Mage", category: "single", damage: 10, damageType: "magical");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, armor: 3, word: "orc"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Equal("Mage hits orc for 10.", events[0]);
        Assert.Equal(13, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessMultiAttack_UsesMultiCountAndNearestAliveTargets()
    {
        var state = new GameState();
        var tower = Tower(name: "Volley", category: "multi", damage: 4, multiCount: 2);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 12),
            Enemy(id: 2, x: 2, y: 0, hp: 12),
            Enemy(id: 3, x: 6, y: 0, hp: 12),
            Enemy(id: 4, x: 0, y: 2, hp: 12, alive: false),
        };
        var events = new List<string>();

        TowerCombat.ProcessMultiAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Equal("Volley hits 2 targets.", events[0]);
        Assert.Equal(8, Convert.ToInt32(enemies[0]["hp"]));
        Assert.Equal(8, Convert.ToInt32(enemies[1]["hp"]));
        Assert.Equal(12, Convert.ToInt32(enemies[2]["hp"]));
        Assert.Equal(12, Convert.ToInt32(enemies[3]["hp"]));
    }

    [Fact]
    public void ProcessAoeAttack_UsesRadiusAndDistanceFalloff()
    {
        var state = new GameState();
        var tower = Tower(name: "Bombard", category: "aoe", damage: 12, aoeRadius: 2);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 0, y: 1, hp: 20),
            Enemy(id: 2, x: 1, y: 1, hp: 20),
            Enemy(id: 3, x: 2, y: 1, hp: 20),
            Enemy(id: 4, x: 3, y: 1, hp: 20),
        };
        var events = new List<string>();

        TowerCombat.ProcessAoeAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Equal("Bombard blasts 3 enemies.", events[0]);
        Assert.Equal(8, Convert.ToInt32(enemies[0]["hp"]));
        Assert.Equal(12, Convert.ToInt32(enemies[1]["hp"]));
        Assert.Equal(16, Convert.ToInt32(enemies[2]["hp"]));
        Assert.Equal(20, Convert.ToInt32(enemies[3]["hp"]));
    }

    [Fact]
    public void ProcessChainAttack_UsesJumpCountRangeAndDamageFalloff()
    {
        var state = new GameState();
        var tower = Tower(name: "Arc", category: "chain", damage: 10, chainJumps: 2, chainRange: 2);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 0, y: 1, hp: 20),
            Enemy(id: 2, x: 1, y: 1, hp: 20),
            Enemy(id: 3, x: 3, y: 1, hp: 20),
            Enemy(id: 4, x: 6, y: 1, hp: 20),
        };
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Equal("Arc chains through 3 enemies.", events[0]);
        Assert.Equal(10, Convert.ToInt32(enemies[0]["hp"]));
        Assert.Equal(12, Convert.ToInt32(enemies[1]["hp"]));
        Assert.Equal(14, Convert.ToInt32(enemies[2]["hp"]));
        Assert.Equal(20, Convert.ToInt32(enemies[3]["hp"]));
    }

    [Fact]
    public void ProcessChainAttack_NoInitialTarget_DoesNothing()
    {
        var state = new GameState();
        var tower = Tower(name: "Arc", category: "chain", damage: 10);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 0, y: 1, hp: 20, alive: false),
        };
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(state, tower, enemies, events);

        Assert.Empty(events);
        Assert.Equal(20, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ParseDamageType_MapsKnownTypesAndDefaultsToPhysical()
    {
        var expected = new Dictionary<string, DamageType>
        {
            ["physical"] = DamageType.Physical,
            ["magical"] = DamageType.Magical,
            ["holy"] = DamageType.Holy,
            ["lightning"] = DamageType.Lightning,
            ["poison"] = DamageType.Poison,
            ["cold"] = DamageType.Cold,
            ["fire"] = DamageType.Fire,
            ["siege"] = DamageType.Siege,
            ["nature"] = DamageType.Nature,
            ["pure"] = DamageType.Pure,
        };

        foreach (var (name, damageType) in expected)
        {
            Assert.Equal(damageType, TowerCombat.ParseDamageType(name));
            Assert.Equal(damageType, TowerCombat.ParseDamageType(name.ToUpperInvariant()));
        }

        Assert.Equal(DamageType.Physical, TowerCombat.ParseDamageType("unknown"));
        Assert.Equal(DamageType.Physical, TowerCombat.ParseDamageType(null));
    }

    private static Dictionary<string, object> Tower(
        string name,
        string category,
        int damage,
        int x = 0,
        int y = 0,
        string targetMode = "nearest",
        string damageType = "physical",
        int multiCount = 2,
        int aoeRadius = 2,
        int chainJumps = 3,
        int chainRange = 3)
    {
        return new Dictionary<string, object>
        {
            ["name"] = name,
            ["category"] = category,
            ["x"] = x,
            ["y"] = y,
            ["damage"] = damage,
            ["target_mode"] = targetMode,
            ["damage_type"] = damageType,
            ["multi_count"] = multiCount,
            ["aoe_radius"] = aoeRadius,
            ["chain_jumps"] = chainJumps,
            ["chain_range"] = chainRange,
        };
    }

    private static Dictionary<string, object> Enemy(
        int id,
        int x,
        int y,
        int hp,
        int armor = 0,
        bool alive = true,
        string word = "enemy")
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["x"] = x,
            ["y"] = y,
            ["hp"] = hp,
            ["armor"] = armor,
            ["alive"] = alive,
            ["word"] = word,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>(),
        };
    }
}
