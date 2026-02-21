using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class EnemiesTests
{
    [Fact]
    public void EnemyKinds_ContainsAllTenKinds()
    {
        var expectedKinds = new[]
        {
            "scout", "raider", "armored", "swarm", "tank",
            "berserker", "phantom", "champion", "healer", "elite"
        };

        Assert.Equal(10, Enemies.EnemyKinds.Count);
        foreach (string kind in expectedKinds)
            Assert.Contains(kind, Enemies.EnemyKinds.Keys);
    }

    [Fact]
    public void EnemyKind_Scout_HasExpectedStats()
    {
        AssertEnemyKind("scout", speed: 2, armor: 0, hpBonus: 0, glyph: "s");
    }

    [Fact]
    public void EnemyKind_Raider_HasExpectedStats()
    {
        AssertEnemyKind("raider", speed: 1, armor: 0, hpBonus: 0, glyph: "r");
    }

    [Fact]
    public void EnemyKind_Armored_HasExpectedStats()
    {
        AssertEnemyKind("armored", speed: 1, armor: 2, hpBonus: 3, glyph: "A");
    }

    [Fact]
    public void EnemyKind_Swarm_HasExpectedStats()
    {
        AssertEnemyKind("swarm", speed: 2, armor: 0, hpBonus: -1, glyph: "w");
    }

    [Fact]
    public void EnemyKind_Tank_HasExpectedStats()
    {
        AssertEnemyKind("tank", speed: 0, armor: 3, hpBonus: 5, glyph: "T");
    }

    [Fact]
    public void EnemyKind_Berserker_HasExpectedStats()
    {
        AssertEnemyKind("berserker", speed: 1, armor: 0, hpBonus: 2, glyph: "B");
    }

    [Fact]
    public void EnemyKind_Phantom_HasExpectedStats()
    {
        AssertEnemyKind("phantom", speed: 2, armor: 0, hpBonus: 0, glyph: "P");
    }

    [Fact]
    public void EnemyKind_Champion_HasExpectedStats()
    {
        AssertEnemyKind("champion", speed: 1, armor: 1, hpBonus: 4, glyph: "C");
    }

    [Fact]
    public void EnemyKind_Healer_HasExpectedStats()
    {
        AssertEnemyKind("healer", speed: 1, armor: 0, hpBonus: 1, glyph: "H");
    }

    [Fact]
    public void EnemyKind_Elite_HasExpectedStats()
    {
        AssertEnemyKind("elite", speed: 1, armor: 1, hpBonus: 3, glyph: "E");
    }

    [Fact]
    public void BossKinds_ContainsAllFourKinds()
    {
        var expectedKinds = new[] { "forest_guardian", "stone_golem", "fen_seer", "sunlord" };

        Assert.Equal(4, Enemies.BossKinds.Count);
        foreach (string kind in expectedKinds)
            Assert.Contains(kind, Enemies.BossKinds.Keys);
    }

    [Fact]
    public void BossKinds_DefinitionsMatchExpectedStats()
    {
        AssertEnemyKind(Enemies.BossKinds, "forest_guardian", speed: 0, armor: 2, hpBonus: 10, glyph: "G");
        AssertEnemyKind(Enemies.BossKinds, "stone_golem", speed: 0, armor: 5, hpBonus: 15, glyph: "S");
        AssertEnemyKind(Enemies.BossKinds, "fen_seer", speed: 1, armor: 1, hpBonus: 8, glyph: "F");
        AssertEnemyKind(Enemies.BossKinds, "sunlord", speed: 1, armor: 3, hpBonus: 20, glyph: "L");
    }

    [Fact]
    public void MakeEnemy_PopulatesExpectedFieldsAndDefaults()
    {
        var state = DefaultState.Create();
        var pos = new GridPoint(5, 5);

        int expectedId = state.EnemyNextId;
        var enemy = Enemies.MakeEnemy(state, "scout", pos, "alpha", day: 3);

        Assert.Equal(expectedId, Convert.ToInt32(enemy["id"]));
        Assert.Equal("scout", enemy["kind"]);
        Assert.Equal(5, Convert.ToInt32(enemy["pos_x"]));
        Assert.Equal(5, Convert.ToInt32(enemy["pos_y"]));
        Assert.Equal("alpha", enemy["word"]);
        Assert.Equal(Convert.ToInt32(enemy["hp"]), Convert.ToInt32(enemy["max_hp"]));
        Assert.Equal(0, Convert.ToInt32(enemy["armor"]));
        Assert.Equal(2, Convert.ToInt32(enemy["speed"]));
        Assert.Equal("s", enemy["glyph"]);
        Assert.True(Convert.ToBoolean(enemy["alive"]));
        Assert.Equal(string.Empty, enemy["affix"]?.ToString());

        var effects = Assert.IsType<List<Dictionary<string, object>>>(enemy["effects"]);
        Assert.Empty(effects);
        Assert.Equal(expectedId + 1, state.EnemyNextId);
    }

    [Fact]
    public void MakeEnemy_UsesEnemyHpFormulaPlusKindBonus()
    {
        var state = DefaultState.Create();
        state.Threat = 8;

        int day = 9;
        int expectedHp = KeyboardDefense.Core.Balance.SimBalance.CalculateEnemyHp(day, state.Threat) + 3; // armored bonus

        var enemy = Enemies.MakeEnemy(state, "armored", new GridPoint(5, 5), "armor", day);

        Assert.Equal(expectedHp, Convert.ToInt32(enemy["hp"]));
        Assert.Equal(expectedHp, Convert.ToInt32(enemy["max_hp"]));
    }

    [Fact]
    public void MakeEnemy_IncrementsEnemyIdOnEachCreation()
    {
        var state = DefaultState.Create();
        var pos = new GridPoint(5, 5);

        int startId = state.EnemyNextId;
        var first = Enemies.MakeEnemy(state, "raider", pos, "one", day: 1);
        var second = Enemies.MakeEnemy(state, "raider", pos, "two", day: 1);

        Assert.Equal(startId, Convert.ToInt32(first["id"]));
        Assert.Equal(startId + 1, Convert.ToInt32(second["id"]));
        Assert.Equal(startId + 2, state.EnemyNextId);
    }

    [Fact]
    public void MakeBoss_SetsBossFlagAndUsesBossHpFormula()
    {
        var state = DefaultState.Create();
        state.Threat = 6;

        int day = 10;
        int expectedHp = KeyboardDefense.Core.Balance.SimBalance.CalculateBossHp(day, state.Threat, 15); // stone_golem bonus

        var boss = Enemies.MakeBoss(state, "stone_golem", new GridPoint(5, 5), "bossword", day);

        Assert.True(Convert.ToBoolean(boss["is_boss"]));
        Assert.Equal(expectedHp, Convert.ToInt32(boss["hp"]));
        Assert.Equal(expectedHp, Convert.ToInt32(boss["max_hp"]));
        Assert.Equal(5, Convert.ToInt32(boss["armor"]));
        Assert.Equal("S", boss["glyph"]);
    }

    [Fact]
    public void ApplyDamage_ReducesHpWhenNoArmorOrAffix()
    {
        var enemy = CreateEnemy(kind: "raider", hp: 10, armor: 0);

        Enemies.ApplyDamage(enemy, damage: 3);

        Assert.Equal(7, Convert.ToInt32(enemy["hp"]));
        Assert.True(Convert.ToBoolean(enemy["alive"]));
    }

    [Fact]
    public void ApplyDamage_ArmorReducesDamageAndStillDealsMinimumOne()
    {
        var enemy = CreateEnemy(kind: "armored", hp: 10, armor: 2);

        Enemies.ApplyDamage(enemy, damage: 1); // max(1, 1 - 2) => 1
        Assert.Equal(9, Convert.ToInt32(enemy["hp"]));

        Enemies.ApplyDamage(enemy, damage: 5); // max(1, 5 - 2) => 3
        Assert.Equal(6, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void ApplyDamage_PhantomEvadesFirstHitOnly()
    {
        var enemy = CreateEnemy(kind: "phantom", hp: 10, armor: 0);

        Enemies.ApplyDamage(enemy, damage: 4);
        Assert.Equal(10, Convert.ToInt32(enemy["hp"]));
        Assert.True(enemy.ContainsKey("_phantom_evaded"));

        Enemies.ApplyDamage(enemy, damage: 4);
        Assert.Equal(6, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void ApplyDamage_ShieldedAffixAbsorbsFirstHitOnly()
    {
        var enemy = CreateEnemy(kind: "raider", hp: 10, armor: 0, affix: "shielded");

        Enemies.ApplyDamage(enemy, damage: 4);
        Assert.Equal(10, Convert.ToInt32(enemy["hp"]));
        Assert.True(enemy.ContainsKey("_shield_used"));

        Enemies.ApplyDamage(enemy, damage: 4);
        Assert.Equal(6, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void ApplyDamage_GhostlyAffixHalvesEffectiveDamage()
    {
        var enemy = CreateEnemy(kind: "champion", hp: 10, armor: 2, affix: "ghostly");

        Enemies.ApplyDamage(enemy, damage: 7); // (7 - 2) / 2 => 2

        Assert.Equal(8, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void ApplyDamage_LethalHitMarksEnemyAsDead()
    {
        var enemy = CreateEnemy(kind: "raider", hp: 3, armor: 0);

        Enemies.ApplyDamage(enemy, damage: 10);

        Assert.True(Convert.ToInt32(enemy["hp"]) <= 0);
        Assert.False(Convert.ToBoolean(enemy["alive"]));
    }

    [Fact]
    public void NormalizeEnemy_AddsMissingDefaultsAndKeepsExistingValues()
    {
        var existingEffects = new List<Dictionary<string, object>>
        {
            new() { ["id"] = "slow" }
        };

        var enemy = new Dictionary<string, object>
        {
            ["alive"] = false,
            ["armor"] = 9,
            ["glyph"] = "Z",
            ["effects"] = existingEffects,
        };

        Enemies.NormalizeEnemy(enemy);

        Assert.False(Convert.ToBoolean(enemy["alive"]));
        Assert.Equal(9, Convert.ToInt32(enemy["armor"]));
        Assert.Equal("Z", enemy["glyph"]);
        Assert.Same(existingEffects, enemy["effects"]);

        Assert.Equal(string.Empty, enemy["affix"]?.ToString());
        Assert.Equal(1, Convert.ToInt32(enemy["speed"]));
    }

    [Fact]
    public void EnsureEnemyWords_AssignsFallbackForMissingOrBlankOnly()
    {
        var state = DefaultState.Create();
        state.Enemies = new List<Dictionary<string, object>>
        {
            new Dictionary<string, object> { ["id"] = 1, ["kind"] = "raider" },
            new Dictionary<string, object> { ["id"] = 2, ["kind"] = "scout", ["word"] = "" },
            new Dictionary<string, object> { ["id"] = 3, ["kind"] = "elite", ["word"] = "typed" },
        };

        Enemies.EnsureEnemyWords(state);

        Assert.Equal("enemy", state.Enemies[0]["word"]);
        Assert.Equal("enemy", state.Enemies[1]["word"]);
        Assert.Equal("typed", state.Enemies[2]["word"]);
    }

    private static void AssertEnemyKind(string kind, int speed, int armor, int hpBonus, string glyph)
    {
        AssertEnemyKind(Enemies.EnemyKinds, kind, speed, armor, hpBonus, glyph);
    }

    private static void AssertEnemyKind(
        Dictionary<string, EnemyKindDef> source,
        string kind,
        int speed,
        int armor,
        int hpBonus,
        string glyph)
    {
        Assert.Contains(kind, source.Keys);
        var def = source[kind];
        Assert.Equal(speed, def.Speed);
        Assert.Equal(armor, def.Armor);
        Assert.Equal(hpBonus, def.HpBonus);
        Assert.Equal(glyph, def.Glyph);
    }

    private static Dictionary<string, object> CreateEnemy(string kind, int hp, int armor, string affix = "")
    {
        return new Dictionary<string, object>
        {
            ["kind"] = kind,
            ["hp"] = hp,
            ["armor"] = armor,
            ["alive"] = true,
            ["affix"] = affix,
        };
    }
}
