using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for Enemies — Serialize/Deserialize, MakeEnemy with unknown kind,
/// MakeBoss for all boss kinds, ApplyDamage edge cases, NormalizeEnemy completeness,
/// EnsureEnemyWords with various states, and EnemyKindDef defaults.
/// </summary>
public class EnemiesExtendedTests
{
    // =========================================================================
    // Serialize / Deserialize round-trip
    // =========================================================================

    [Fact]
    public void Serialize_PreservesAllFields()
    {
        var state = DefaultState.Create();
        var enemy = Enemies.MakeEnemy(state, "scout", new GridPoint(3, 4), "alpha", 5);

        var serialized = Enemies.Serialize(enemy);

        Assert.Equal(enemy["id"], serialized["id"]);
        Assert.Equal(enemy["kind"], serialized["kind"]);
        Assert.Equal(enemy["hp"], serialized["hp"]);
        Assert.Equal(enemy["word"], serialized["word"]);
        Assert.Equal(enemy["pos_x"], serialized["pos_x"]);
        Assert.Equal(enemy["pos_y"], serialized["pos_y"]);
    }

    [Fact]
    public void Serialize_CreatesNewDictionary_NotSameReference()
    {
        var enemy = CreateEnemy("raider", 10, 0);
        var serialized = Enemies.Serialize(enemy);

        Assert.NotSame(enemy, serialized);
    }

    [Fact]
    public void Serialize_ClonesEffectsList()
    {
        var effects = new List<Dictionary<string, object>>
        {
            new() { ["id"] = "burning", ["duration"] = 3 },
        };
        var enemy = new Dictionary<string, object>
        {
            ["kind"] = "raider",
            ["hp"] = 10,
            ["effects"] = effects,
        };

        var serialized = Enemies.Serialize(enemy);
        var serializedEffects = (List<Dictionary<string, object>>)serialized["effects"];

        Assert.NotSame(effects, serializedEffects);
        Assert.NotSame(effects[0], serializedEffects[0]);
        Assert.Equal("burning", serializedEffects[0]["id"]);
    }

    [Fact]
    public void Deserialize_CreatesNewDictionary()
    {
        var data = new Dictionary<string, object>
        {
            ["kind"] = "raider",
            ["hp"] = 10,
        };

        var enemy = Enemies.Deserialize(data);

        Assert.NotSame(data, enemy);
        Assert.Equal("raider", enemy["kind"]);
        Assert.Equal(10, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void SerializeDeserialize_RoundTrip_PreservesData()
    {
        var state = DefaultState.Create();
        var original = Enemies.MakeEnemy(state, "armored", new GridPoint(7, 8), "test", 3);

        var serialized = Enemies.Serialize(original);
        var deserialized = Enemies.Deserialize(serialized);

        Assert.Equal(original["id"], deserialized["id"]);
        Assert.Equal(original["kind"], deserialized["kind"]);
        Assert.Equal(original["hp"], deserialized["hp"]);
        Assert.Equal(original["word"], deserialized["word"]);
    }

    // =========================================================================
    // MakeEnemy — unknown kind uses defaults
    // =========================================================================

    [Fact]
    public void MakeEnemy_UnknownKind_UsesDefaults()
    {
        var state = DefaultState.Create();
        var enemy = Enemies.MakeEnemy(state, "unknown_kind", new GridPoint(1, 1), "word", 1);

        Assert.Equal("unknown_kind", enemy["kind"]);
        Assert.True(Convert.ToBoolean(enemy["alive"]));
        // Default EnemyKindDef: Speed=1, Armor=0, HpBonus=0, Glyph="?"
        Assert.Equal(0, Convert.ToInt32(enemy["armor"]));
        Assert.Equal(1, Convert.ToInt32(enemy["speed"]));
        Assert.Equal("?", enemy["glyph"]);
    }

    [Fact]
    public void MakeEnemy_AllKinds_ProduceValidEnemies()
    {
        var state = DefaultState.Create();
        foreach (var kind in Enemies.EnemyKinds.Keys)
        {
            var enemy = Enemies.MakeEnemy(state, kind, new GridPoint(0, 0), "word", 1);
            Assert.Equal(kind, enemy["kind"]);
            Assert.True(Convert.ToInt32(enemy["hp"]) > 0,
                $"Enemy '{kind}' should have positive HP");
            Assert.True(Convert.ToBoolean(enemy["alive"]));
        }
    }

    // =========================================================================
    // MakeBoss — all boss kinds
    // =========================================================================

    [Theory]
    [InlineData("forest_guardian", 2, "G")]
    [InlineData("stone_golem", 5, "S")]
    [InlineData("fen_seer", 1, "F")]
    [InlineData("sunlord", 3, "L")]
    public void MakeBoss_AllKinds_HaveCorrectStats(string kind, int armor, string glyph)
    {
        var state = DefaultState.Create();
        var boss = Enemies.MakeBoss(state, kind, new GridPoint(5, 5), "boss", 5);

        Assert.True(Convert.ToBoolean(boss["is_boss"]));
        Assert.Equal(armor, Convert.ToInt32(boss["armor"]));
        Assert.Equal(glyph, boss["glyph"]);
        Assert.True(Convert.ToInt32(boss["hp"]) > 0);
    }

    [Fact]
    public void MakeBoss_UnknownKind_UsesDefaults()
    {
        var state = DefaultState.Create();
        var boss = Enemies.MakeBoss(state, "unknown_boss", new GridPoint(0, 0), "boss", 1);

        Assert.True(Convert.ToBoolean(boss["is_boss"]));
        Assert.Equal(0, Convert.ToInt32(boss["armor"]));
        Assert.Equal("?", boss["glyph"]);
    }

    [Fact]
    public void MakeBoss_HpAlwaysHigherThanEnemy_SameDay()
    {
        var state = DefaultState.Create();
        state.Threat = 5;
        int day = 10;

        foreach (var bossKind in Enemies.BossKinds.Keys)
        {
            var boss = Enemies.MakeBoss(state, bossKind, new GridPoint(0, 0), "b", day);
            int bossHp = Convert.ToInt32(boss["hp"]);

            foreach (var enemyKind in Enemies.EnemyKinds.Keys)
            {
                var enemy = Enemies.MakeEnemy(state, enemyKind, new GridPoint(0, 0), "e", day);
                int enemyHp = Convert.ToInt32(enemy["hp"]);

                Assert.True(bossHp > enemyHp,
                    $"Boss '{bossKind}' ({bossHp}) should have more HP than enemy '{enemyKind}' ({enemyHp})");
            }
        }
    }

    // =========================================================================
    // ApplyDamage — edge cases
    // =========================================================================

    [Fact]
    public void ApplyDamage_ZeroDamage_DealsMinimumOne()
    {
        var enemy = CreateEnemy("raider", 10, 0);
        Enemies.ApplyDamage(enemy, 0);
        Assert.Equal(9, Convert.ToInt32(enemy["hp"])); // max(1, 0 - 0) = 1
    }

    [Fact]
    public void ApplyDamage_ExactlyLethal_SetsAliveToFalse()
    {
        var enemy = CreateEnemy("raider", 1, 0);
        Enemies.ApplyDamage(enemy, 1);

        Assert.Equal(0, Convert.ToInt32(enemy["hp"]));
        Assert.False(Convert.ToBoolean(enemy["alive"]));
    }

    [Fact]
    public void ApplyDamage_OverkillDamage_HpGoesNegative()
    {
        var enemy = CreateEnemy("raider", 5, 0);
        Enemies.ApplyDamage(enemy, 100);

        Assert.True(Convert.ToInt32(enemy["hp"]) < 0);
        Assert.False(Convert.ToBoolean(enemy["alive"]));
    }

    [Fact]
    public void ApplyDamage_HighArmor_StillDealsMinOne()
    {
        var enemy = CreateEnemy("tank", 10, 999);
        Enemies.ApplyDamage(enemy, 5);
        Assert.Equal(9, Convert.ToInt32(enemy["hp"])); // max(1, 5-999) = 1
    }

    [Fact]
    public void ApplyDamage_PhantomShielded_BothEvadesSeparately()
    {
        // Phantom kind + shielded affix: phantom evade happens first
        var enemy = CreateEnemy("phantom", 10, 0, "shielded");

        Enemies.ApplyDamage(enemy, 5); // phantom evade (first hit)
        Assert.Equal(10, Convert.ToInt32(enemy["hp"]));

        Enemies.ApplyDamage(enemy, 5); // shield absorb (second hit, phantom already used)
        Assert.Equal(10, Convert.ToInt32(enemy["hp"]));

        Enemies.ApplyDamage(enemy, 5); // normal damage (third hit)
        Assert.Equal(5, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void ApplyDamage_GhostlyWithArmor_BothApply()
    {
        var enemy = CreateEnemy("raider", 20, 4, "ghostly");

        Enemies.ApplyDamage(enemy, 10); // (10 - 4) / 2 = 3
        Assert.Equal(17, Convert.ToInt32(enemy["hp"]));
    }

    [Fact]
    public void ApplyDamage_GhostlyMinDamage_IsOne()
    {
        var enemy = CreateEnemy("raider", 20, 8, "ghostly");

        Enemies.ApplyDamage(enemy, 1); // max(1, max(1, 1-8) / 2) = max(1, 0) = 1
        Assert.Equal(19, Convert.ToInt32(enemy["hp"]));
    }

    // =========================================================================
    // NormalizeEnemy — bare dictionary
    // =========================================================================

    [Fact]
    public void NormalizeEnemy_EmptyDictionary_AddsAllDefaults()
    {
        var enemy = new Dictionary<string, object>();
        Enemies.NormalizeEnemy(enemy);

        Assert.True(Convert.ToBoolean(enemy["alive"]));
        Assert.Empty((List<Dictionary<string, object>>)enemy["effects"]);
        Assert.Equal("", enemy["affix"]?.ToString());
        Assert.Equal(0, Convert.ToInt32(enemy["armor"]));
        Assert.Equal(1, Convert.ToInt32(enemy["speed"]));
        Assert.Equal("?", enemy["glyph"]);
    }

    [Fact]
    public void NormalizeEnemy_DoesNotOverwriteExistingValues()
    {
        var enemy = new Dictionary<string, object>
        {
            ["alive"] = false,
            ["armor"] = 5,
            ["speed"] = 3,
            ["glyph"] = "X",
            ["affix"] = "burning",
        };

        Enemies.NormalizeEnemy(enemy);

        Assert.False(Convert.ToBoolean(enemy["alive"]));
        Assert.Equal(5, Convert.ToInt32(enemy["armor"]));
        Assert.Equal(3, Convert.ToInt32(enemy["speed"]));
        Assert.Equal("X", enemy["glyph"]);
        Assert.Equal("burning", enemy["affix"]);
    }

    // =========================================================================
    // EnsureEnemyWords — edge cases
    // =========================================================================

    [Fact]
    public void EnsureEnemyWords_NoEnemies_NoCrash()
    {
        var state = DefaultState.Create();
        state.Enemies.Clear();

        Enemies.EnsureEnemyWords(state);

        Assert.Empty(state.Enemies);
    }

    [Fact]
    public void EnsureEnemyWords_AllHaveWords_NoChanges()
    {
        var state = DefaultState.Create();
        state.Enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1, ["word"] = "alpha" },
            new() { ["id"] = 2, ["word"] = "beta" },
        };

        Enemies.EnsureEnemyWords(state);

        Assert.Equal("alpha", state.Enemies[0]["word"]);
        Assert.Equal("beta", state.Enemies[1]["word"]);
    }

    [Fact]
    public void EnsureEnemyWords_NullWord_GetsFallback()
    {
        var state = DefaultState.Create();
        state.Enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 42, ["word"] = null! },
        };

        Enemies.EnsureEnemyWords(state);

        Assert.Equal("enemy_42", state.Enemies[0]["word"]);
    }

    [Fact]
    public void EnsureEnemyWords_MultipleWordless_GetUniqueWords()
    {
        var state = DefaultState.Create();
        state.Enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1 },
            new() { ["id"] = 2 },
            new() { ["id"] = 3 },
        };

        Enemies.EnsureEnemyWords(state);

        var words = state.Enemies.Select(e => e["word"].ToString()).ToList();
        Assert.Equal(words.Count, words.Distinct().Count());
    }

    // =========================================================================
    // EnemyKindDef — defaults
    // =========================================================================

    [Fact]
    public void EnemyKindDef_DefaultValues()
    {
        var def = new EnemyKindDef();
        Assert.Equal(1, def.Speed);
        Assert.Equal(0, def.Armor);
        Assert.Equal(0, def.HpBonus);
        Assert.Equal("?", def.Glyph);
    }

    [Fact]
    public void EnemyKindDef_CanBeSet()
    {
        var def = new EnemyKindDef
        {
            Speed = 5,
            Armor = 3,
            HpBonus = 10,
            Glyph = "X",
        };
        Assert.Equal(5, def.Speed);
        Assert.Equal(3, def.Armor);
        Assert.Equal(10, def.HpBonus);
        Assert.Equal("X", def.Glyph);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static Dictionary<string, object> CreateEnemy(
        string kind, int hp, int armor, string affix = "")
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
