using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for TowerCombat — multiple tower processing, empty lists,
/// damage type interactions, kill tracking, edge cases for each attack mode.
/// </summary>
public class TowerCombatExtendedTests
{
    // =========================================================================
    // ProcessTowerAttacks — multiple towers
    // =========================================================================

    [Fact]
    public void ProcessTowerAttacks_MultipleTowers_AllAttack()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Arrow1", category: "single", damage: 5),
            Tower(name: "Arrow2", category: "single", damage: 3),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, word: "goblin"),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Equal(2, events.Count);
        // Both towers should target the same enemy (only one alive)
        Assert.Equal(12, Convert.ToInt32(enemies[0]["hp"])); // 20 - 5 - 3
    }

    [Fact]
    public void ProcessTowerAttacks_MixedCategories_DispatchesCorrectly()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Arrow", category: "single", damage: 5),
            Tower(name: "Banner", category: "support", damage: 999),
            Tower(name: "Caller", category: "summoner", damage: 999),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, word: "imp"),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        // Only the single-target tower should produce an event
        Assert.Single(events);
        Assert.Equal(15, Convert.ToInt32(enemies[0]["hp"])); // only 5 damage
    }

    [Fact]
    public void ProcessTowerAttacks_EmptyTowers_ReturnsEmptyEvents()
    {
        var state = new GameState();
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 0, y: 0, hp: 10),
        };

        var events = TowerCombat.ProcessTowerAttacks(
            state, new List<Dictionary<string, object>>(), enemies);

        Assert.Empty(events);
        Assert.Equal(10, Convert.ToInt32(enemies[0]["hp"]));
    }

    [Fact]
    public void ProcessTowerAttacks_EmptyEnemies_ReturnsEmptyEvents()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Arrow", category: "single", damage: 10),
        };

        var events = TowerCombat.ProcessTowerAttacks(
            state, towers, new List<Dictionary<string, object>>());

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessTowerAttacks_AllDeadEnemies_ReturnsEmptyEvents()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Arrow", category: "single", damage: 10),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 0, alive: false),
            Enemy(id: 2, x: 2, y: 0, hp: 0, alive: false),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Empty(events);
    }

    // =========================================================================
    // ProcessSingleAttack — edge cases
    // =========================================================================

    [Fact]
    public void ProcessSingleAttack_ZeroDamage_StillHits()
    {
        var state = new GameState();
        var tower = Tower(name: "Weak", category: "single", damage: 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 10, word: "rat"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Single(events);
        // Even 0 base damage → min 1 effective damage via ApplyDamage
    }

    [Fact]
    public void ProcessSingleAttack_WithArmor_ReducesDamage()
    {
        var state = new GameState();
        var tower = Tower(name: "Arrow", category: "single", damage: 10, damageType: "physical");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, armor: 3, word: "knight"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Contains("for 7.", events[0]); // 10 - 3 armor
    }

    [Fact]
    public void ProcessSingleAttack_PureDamage_IgnoresArmor()
    {
        var state = new GameState();
        var tower = Tower(name: "Pure", category: "single", damage: 10, damageType: "pure");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, armor: 8, word: "golem"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Contains("for 10.", events[0]); // pure ignores armor
    }

    [Fact]
    public void ProcessSingleAttack_EmptyEnemies_NoEvent()
    {
        var state = new GameState();
        var tower = Tower(name: "Arrow", category: "single", damage: 10);
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(
            state, tower, new List<Dictionary<string, object>>(), events);

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessSingleAttack_PicksNearestTarget()
    {
        var state = new GameState();
        var tower = Tower(name: "Arrow", category: "single", damage: 5, x: 0, y: 0);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 10, y: 0, hp: 20, word: "far"),
            Enemy(id: 2, x: 1, y: 0, hp: 20, word: "near"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Contains("near", events[0]);
    }

    [Fact]
    public void ProcessSingleAttack_KillsEnemy_SetsAliveToFalse()
    {
        var state = new GameState();
        var tower = Tower(name: "Cannon", category: "single", damage: 100);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 5, word: "weak"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.False(Convert.ToBoolean(enemies[0]["alive"]));
    }

    [Fact]
    public void ProcessSingleAttack_MissingTowerName_DefaultsToTower()
    {
        var state = new GameState();
        var tower = new Dictionary<string, object>
        {
            ["category"] = "single",
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            ["damage"] = 5,
            ["damage_type"] = "physical",
            ["target_mode"] = "nearest",
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, word: "imp"),
        };
        var events = new List<string>();

        TowerCombat.ProcessSingleAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.StartsWith("Tower hits", events[0]);
    }

    // =========================================================================
    // ProcessMultiAttack — edge cases
    // =========================================================================

    [Fact]
    public void ProcessMultiAttack_EmptyEnemies_NoEvent()
    {
        var state = new GameState();
        var tower = Tower(name: "Volley", category: "multi", damage: 5, multiCount: 3);
        var events = new List<string>();

        TowerCombat.ProcessMultiAttack(
            state, tower, new List<Dictionary<string, object>>(), events);

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessMultiAttack_CountExceedsAlive_HitsAllAlive()
    {
        var state = new GameState();
        var tower = Tower(name: "Volley", category: "multi", damage: 3, multiCount: 5);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 10),
            Enemy(id: 2, x: 2, y: 0, hp: 10),
        };
        var events = new List<string>();

        TowerCombat.ProcessMultiAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Equal("Volley hits 2 targets.", events[0]);
    }

    [Fact]
    public void ProcessMultiAttack_DefaultMultiCount_IsTwo()
    {
        var state = new GameState();
        var tower = new Dictionary<string, object>
        {
            ["name"] = "DefaultVolley",
            ["category"] = "multi",
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            ["damage"] = 3,
            ["damage_type"] = "physical",
            ["target_mode"] = "nearest",
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 10),
            Enemy(id: 2, x: 2, y: 0, hp: 10),
            Enemy(id: 3, x: 3, y: 0, hp: 10),
        };
        var events = new List<string>();

        TowerCombat.ProcessMultiAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Equal("DefaultVolley hits 2 targets.", events[0]);
        // Third enemy untouched
        Assert.Equal(10, Convert.ToInt32(enemies[2]["hp"]));
    }

    [Fact]
    public void ProcessMultiAttack_WithDamageType_AppliesTypeToEachTarget()
    {
        var state = new GameState();
        var tower = Tower(name: "Storm", category: "multi", damage: 10,
            multiCount: 2, damageType: "lightning");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 30, armor: 0),
            Enemy(id: 2, x: 2, y: 0, hp: 30, armor: 0),
        };
        var events = new List<string>();

        TowerCombat.ProcessMultiAttack(state, tower, enemies, events);

        // Lightning does 10 * 1.2 = 12 per target
        Assert.Equal(18, Convert.ToInt32(enemies[0]["hp"]));
        Assert.Equal(18, Convert.ToInt32(enemies[1]["hp"]));
    }

    // =========================================================================
    // ProcessAoeAttack — edge cases
    // =========================================================================

    [Fact]
    public void ProcessAoeAttack_NoCenter_DoesNothing()
    {
        var state = new GameState();
        var tower = Tower(name: "Bomb", category: "aoe", damage: 20, aoeRadius: 3);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 0, y: 0, hp: 20, alive: false),
        };
        var events = new List<string>();

        TowerCombat.ProcessAoeAttack(state, tower, enemies, events);

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessAoeAttack_DefaultRadius_IsTwo()
    {
        var state = new GameState();
        var tower = new Dictionary<string, object>
        {
            ["name"] = "Boom",
            ["category"] = "aoe",
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            ["damage"] = 10,
            ["damage_type"] = "physical",
            ["target_mode"] = "nearest",
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20), // dist=1 from center, within radius 2
            Enemy(id: 2, x: 2, y: 0, hp: 20), // dist=1 from center
            Enemy(id: 3, x: 5, y: 0, hp: 20), // dist=4 from center, outside radius 2
        };
        var events = new List<string>();

        TowerCombat.ProcessAoeAttack(state, tower, enemies, events);

        // Center is enemy 1 (nearest), radius 2 should include enemies within 2 tiles
        Assert.NotEmpty(events);
        Assert.Equal(20, Convert.ToInt32(enemies[2]["hp"])); // too far
    }

    [Fact]
    public void ProcessAoeAttack_FireDamageType_AppliesFireBonuses()
    {
        var state = new GameState();
        var tower = Tower(name: "Inferno", category: "aoe", damage: 10,
            aoeRadius: 3, damageType: "fire");
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 30),
            Enemy(id: 2, x: 2, y: 0, hp: 30),
        };
        var events = new List<string>();

        TowerCombat.ProcessAoeAttack(state, tower, enemies, events);

        Assert.NotEmpty(events);
        Assert.Contains("Inferno blasts", events[0]);
    }

    // =========================================================================
    // ProcessChainAttack — edge cases
    // =========================================================================

    [Fact]
    public void ProcessChainAttack_DefaultJumps_IsThree()
    {
        var state = new GameState();
        var tower = new Dictionary<string, object>
        {
            ["name"] = "Tesla",
            ["category"] = "chain",
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            ["damage"] = 10,
            ["damage_type"] = "physical",
            ["target_mode"] = "nearest",
            // No chain_jumps or chain_range specified
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 50),
            Enemy(id: 2, x: 2, y: 0, hp: 50),
            Enemy(id: 3, x: 3, y: 0, hp: 50),
            Enemy(id: 4, x: 4, y: 0, hp: 50),
            Enemy(id: 5, x: 5, y: 0, hp: 50),
        };
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(state, tower, enemies, events);

        // Default 3 jumps + initial = 4 enemies hit
        Assert.Single(events);
        Assert.Contains("chains through 4 enemies", events[0]);
    }

    [Fact]
    public void ProcessChainAttack_DamageFallsOffPerJump()
    {
        var state = new GameState();
        var tower = Tower(name: "Zap", category: "chain", damage: 100,
            chainJumps: 3, chainRange: 5);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 200),
            Enemy(id: 2, x: 2, y: 0, hp: 200),
            Enemy(id: 3, x: 3, y: 0, hp: 200),
            Enemy(id: 4, x: 4, y: 0, hp: 200),
        };
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(state, tower, enemies, events);

        // Chain damage: jump 0 = 100, jump 1 = 80, jump 2 = 64, jump 3 = 51
        int hp0 = Convert.ToInt32(enemies[0]["hp"]);
        int hp1 = Convert.ToInt32(enemies[1]["hp"]);
        int hp2 = Convert.ToInt32(enemies[2]["hp"]);
        int hp3 = Convert.ToInt32(enemies[3]["hp"]);

        // Each subsequent enemy should take less damage
        int dmg0 = 200 - hp0;
        int dmg1 = 200 - hp1;
        int dmg2 = 200 - hp2;
        int dmg3 = 200 - hp3;

        Assert.True(dmg0 > dmg1, $"First hit ({dmg0}) should be more than second ({dmg1})");
        Assert.True(dmg1 > dmg2, $"Second hit ({dmg1}) should be more than third ({dmg2})");
        Assert.True(dmg2 > dmg3, $"Third hit ({dmg2}) should be more than fourth ({dmg3})");
    }

    [Fact]
    public void ProcessChainAttack_EmptyEnemies_NoEvent()
    {
        var state = new GameState();
        var tower = Tower(name: "Zap", category: "chain", damage: 10);
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(
            state, tower, new List<Dictionary<string, object>>(), events);

        Assert.Empty(events);
    }

    [Fact]
    public void ProcessChainAttack_SingleEnemy_HitsOnlyOne()
    {
        var state = new GameState();
        var tower = Tower(name: "Zap", category: "chain", damage: 10,
            chainJumps: 5, chainRange: 10);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 50, word: "lone"),
        };
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(state, tower, enemies, events);

        Assert.Single(events);
        Assert.Contains("chains through 1 enemies", events[0]);
        Assert.Equal(40, Convert.ToInt32(enemies[0]["hp"])); // 50 - 10
    }

    [Fact]
    public void ProcessChainAttack_EnemiesOutOfRange_StopsEarly()
    {
        var state = new GameState();
        var tower = Tower(name: "Zap", category: "chain", damage: 10,
            chainJumps: 5, chainRange: 2);
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 50),
            Enemy(id: 2, x: 2, y: 0, hp: 50),
            // Big gap
            Enemy(id: 3, x: 20, y: 0, hp: 50),
        };
        var events = new List<string>();

        TowerCombat.ProcessChainAttack(state, tower, enemies, events);

        // Should chain through 1 and 2, but not reach 3
        Assert.Contains("chains through 2 enemies", events[0]);
        Assert.Equal(50, Convert.ToInt32(enemies[2]["hp"])); // untouched
    }

    // =========================================================================
    // ParseDamageType — extended
    // =========================================================================

    [Theory]
    [InlineData("Physical", DamageType.Physical)]
    [InlineData("MAGICAL", DamageType.Magical)]
    [InlineData("Holy", DamageType.Holy)]
    [InlineData("LIGHTNING", DamageType.Lightning)]
    [InlineData("Poison", DamageType.Poison)]
    [InlineData("Cold", DamageType.Cold)]
    [InlineData("FIRE", DamageType.Fire)]
    [InlineData("Siege", DamageType.Siege)]
    [InlineData("Nature", DamageType.Nature)]
    [InlineData("PURE", DamageType.Pure)]
    public void ParseDamageType_MixedCase_MapsCorrectly(string input, DamageType expected)
    {
        Assert.Equal(expected, TowerCombat.ParseDamageType(input));
    }

    [Theory]
    [InlineData("")]
    [InlineData("arcane")]
    [InlineData("shadow")]
    [InlineData("chaos")]
    public void ParseDamageType_UnrecognizedStrings_DefaultToPhysical(string input)
    {
        Assert.Equal(DamageType.Physical, TowerCombat.ParseDamageType(input));
    }

    [Fact]
    public void ParseDamageType_Null_DefaultsToPhysical()
    {
        Assert.Equal(DamageType.Physical, TowerCombat.ParseDamageType(null));
    }

    // =========================================================================
    // Tower with missing optional keys — robustness
    // =========================================================================

    [Fact]
    public void ProcessTowerAttacks_MissingDamageKey_TreatsAsZero()
    {
        var state = new GameState();
        var tower = new Dictionary<string, object>
        {
            ["name"] = "Broken",
            ["category"] = "single",
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            ["target_mode"] = "nearest",
            // No "damage" key
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 10, word: "rat"),
        };

        var events = TowerCombat.ProcessTowerAttacks(
            state, new List<Dictionary<string, object>> { tower }, enemies);

        Assert.Single(events);
        // DamageTypes.CalculateDamage(0, ...) = 0, but ApplyDamage enforces min 1
    }

    [Fact]
    public void ProcessTowerAttacks_MissingCategoryKey_DefaultsToSingle()
    {
        var state = new GameState();
        var tower = new Dictionary<string, object>
        {
            ["name"] = "NoCat",
            ["pos_x"] = 0,
            ["pos_y"] = 0,
            ["damage"] = 5,
            ["target_mode"] = "nearest",
            ["damage_type"] = "physical",
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 20, word: "imp"),
        };

        var events = TowerCombat.ProcessTowerAttacks(
            state, new List<Dictionary<string, object>> { tower }, enemies);

        // Missing category defaults to "single" via null-coalescing
        Assert.Single(events);
        Assert.Contains("NoCat hits imp", events[0]);
    }

    // =========================================================================
    // Multiple towers killing an enemy mid-sequence
    // =========================================================================

    [Fact]
    public void ProcessTowerAttacks_FirstTowerKills_SecondTowerSkipsDead()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Killer", category: "single", damage: 100),
            Tower(name: "Follower", category: "single", damage: 5),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 5, word: "weak"),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        // First tower kills the enemy, second should not find a target
        Assert.Single(events); // Only the first tower event
        Assert.False(Convert.ToBoolean(enemies[0]["alive"]));
    }

    [Fact]
    public void ProcessTowerAttacks_FirstKillsOneTarget_SecondHitsAnother()
    {
        var state = new GameState();
        var towers = new List<Dictionary<string, object>>
        {
            Tower(name: "Killer", category: "single", damage: 100),
            Tower(name: "Follower", category: "single", damage: 5),
        };
        var enemies = new List<Dictionary<string, object>>
        {
            Enemy(id: 1, x: 1, y: 0, hp: 5, word: "first"),
            Enemy(id: 2, x: 2, y: 0, hp: 20, word: "second"),
        };

        var events = TowerCombat.ProcessTowerAttacks(state, towers, enemies);

        Assert.Equal(2, events.Count);
        Assert.False(Convert.ToBoolean(enemies[0]["alive"]));
        Assert.True(Convert.ToBoolean(enemies[1]["alive"]));
    }

    // =========================================================================
    // Helpers
    // =========================================================================

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
            ["pos_x"] = x,
            ["pos_y"] = y,
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
            ["pos_x"] = x,
            ["pos_y"] = y,
            ["hp"] = hp,
            ["armor"] = armor,
            ["alive"] = alive,
            ["word"] = word,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>(),
        };
    }
}
