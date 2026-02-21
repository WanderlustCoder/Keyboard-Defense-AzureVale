using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SpellSystemCoreTests
{
    [Fact]
    public void Registry_ContainsFiveSpellsWithExpectedDefinitions()
    {
        var expected = new Dictionary<string, (string Name, float CooldownSeconds, SpellEffect Effect)>
        {
            ["fireball"] = ("Fireball", 30f, SpellEffect.AreaDamage),
            ["heal"] = ("Heal", 45f, SpellEffect.HealCastle),
            ["freeze"] = ("Freeze", 40f, SpellEffect.FreezeEnemies),
            ["shield"] = ("Shield", 60f, SpellEffect.ShieldCastle),
            ["thunder"] = ("Thunder", 50f, SpellEffect.InstantKill),
        };

        Assert.Equal(5, SpellSystem.Registry.Count);

        foreach (var (keyword, value) in expected)
        {
            Assert.True(SpellSystem.Registry.TryGetValue(keyword, out var def));
            Assert.NotNull(def);
            Assert.Equal(value.Name, def!.Name);
            Assert.Equal(keyword, def.Keyword);
            Assert.Equal(value.CooldownSeconds, def.CooldownSeconds);
            Assert.Equal(value.Effect, def.Effect);
            Assert.False(string.IsNullOrWhiteSpace(def.Description));
        }
    }

    [Fact]
    public void IsSpellKeyword_KnownKeywords_ReturnsTrue()
    {
        Assert.True(SpellSystem.IsSpellKeyword("fireball"));
        Assert.True(SpellSystem.IsSpellKeyword("HEAL"));
    }

    [Fact]
    public void IsSpellKeyword_UnknownKeyword_ReturnsFalse()
    {
        Assert.False(SpellSystem.IsSpellKeyword("nonexistent"));
    }

    [Fact]
    public void GetState_KnownSpell_ReturnsNonNull()
    {
        var spells = new SpellSystem();

        Assert.NotNull(spells.GetState("fireball"));
    }

    [Fact]
    public void GetState_UnknownSpell_ReturnsNull()
    {
        var spells = new SpellSystem();

        Assert.Null(spells.GetState("unknown"));
    }

    [Fact]
    public void SpellState_IsReady_TrueWhenCooldownZero()
    {
        var state = new SpellState { CooldownRemaining = 0f };

        Assert.True(state.IsReady);
    }

    [Fact]
    public void SpellState_IsReady_FalseWhenCooldownPositive()
    {
        var state = new SpellState { CooldownRemaining = 0.01f };

        Assert.False(state.IsReady);
    }

    [Fact]
    public void Reset_AfterSpellsCast_AllSpellsReady()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        foreach (var keyword in SpellSystem.Registry.Keys)
        {
            var result = spells.TryCast(state, keyword);
            Assert.True(result.Success);
        }

        spells.Reset();

        foreach (var keyword in SpellSystem.Registry.Keys)
        {
            var spellState = spells.GetState(keyword);
            Assert.NotNull(spellState);
            Assert.True(spellState!.IsReady);
            Assert.Equal(0f, spellState.CooldownRemaining);
        }
    }

    [Fact]
    public void UpdateCooldowns_ReducesCooldownByDelta()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var castResult = spells.TryCast(state, "fireball");
        Assert.True(castResult.Success);

        spells.UpdateCooldowns(2.25f);

        var spellState = spells.GetState("fireball");
        Assert.NotNull(spellState);
        Assert.InRange(spellState!.CooldownRemaining, 27.74f, 27.76f);
    }

    [Fact]
    public void UpdateCooldowns_FloorsAtZero()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var castResult = spells.TryCast(state, "fireball");
        Assert.True(castResult.Success);

        spells.UpdateCooldowns(100f);

        var spellState = spells.GetState("fireball");
        Assert.NotNull(spellState);
        Assert.Equal(0f, spellState!.CooldownRemaining);
        Assert.True(spellState.IsReady);
    }

    [Fact]
    public void TryCast_UnknownSpell_ReturnsFalseAndEmptyMessage()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "nonexistent");

        Assert.False(result.Success);
        Assert.Equal(string.Empty, result.Message);
    }

    [Fact]
    public void TryCast_OnCooldown_ReturnsFalseAndCooldownMessage()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        var spellState = spells.GetState("fireball");
        Assert.NotNull(spellState);
        spellState!.CooldownRemaining = 7.2f;

        var result = spells.TryCast(state, "fireball");

        Assert.False(result.Success);
        Assert.Equal("Fireball is on cooldown (8s remaining).", result.Message);
    }

    [Fact]
    public void TryCast_Fireball_DamagesAllEnemiesAndReturnsHitCount()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("alpha", hp: 10));
        state.Enemies.Add(CreateEnemy("beta", hp: 9));

        var result = spells.TryCast(state, "fireball");

        Assert.True(result.Success);
        Assert.Equal("Fireball hits 2 enemies for 5 damage each!", result.Message);
        Assert.Equal(5, Convert.ToInt32(state.Enemies[0]["hp"]));
        Assert.Equal(4, Convert.ToInt32(state.Enemies[1]["hp"]));
    }

    [Fact]
    public void TryCast_Fireball_RemovesDeadEnemiesFromList()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("dead", hp: 5));
        state.Enemies.Add(CreateEnemy("survivor", hp: 8));

        var result = spells.TryCast(state, "fireball");

        Assert.True(result.Success);
        Assert.Single(state.Enemies);
        Assert.Equal("survivor", state.Enemies[0]["word"]);
    }

    [Fact]
    public void TryCast_Fireball_NoEnemies_ReturnsEmptyFieldMessage()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "fireball");

        Assert.True(result.Success);
        Assert.Equal("Fireball blazes across an empty field.", result.Message);
    }

    [Fact]
    public void TryCast_Heal_IncreasesHpByThree()
    {
        var spells = new SpellSystem();
        var state = new GameState { Hp = 4 };

        var result = spells.TryCast(state, "heal");

        Assert.True(result.Success);
        Assert.Equal(7, state.Hp);
        Assert.Equal("Heal restores 3 HP! (HP: 7)", result.Message);
    }

    [Fact]
    public void TryCast_Freeze_AddsFrozenStatusAndHalvesSpeed()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        var enemy = CreateEnemy("frozen-target", hp: 10, speed: 4);
        state.Enemies.Add(enemy);

        var result = spells.TryCast(state, "freeze");

        Assert.True(result.Success);
        Assert.Equal("Freeze slows 1 enemies for 5s!", result.Message);
        Assert.Equal(2, Convert.ToInt32(enemy["speed"]));
        Assert.Equal(4, Convert.ToInt32(enemy["_pre_freeze_speed"]));

        var statuses = Assert.IsType<Dictionary<string, object>>(enemy["_statuses"]);
        Assert.Equal(5f, Convert.ToSingle(statuses["frozen"]));
    }

    [Fact]
    public void TryCast_Shield_AddsSpellShieldBuffWithTwoCharges()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "shield");

        Assert.True(result.Success);
        Assert.Equal("Shield activated! Next 2 damage blocked.", result.Message);

        var shield = Assert.Single(state.ActiveBuffs, buff =>
            buff.GetValueOrDefault("buff_id")?.ToString() == "spell_shield");

        Assert.Equal(2, Convert.ToInt32(shield["remaining_charges"]));
        Assert.Equal(999, Convert.ToInt32(shield["remaining_days"]));
    }

    [Fact]
    public void TryCast_Thunder_KillsLowestHpEnemyAndRemovesFromList()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("high", hp: 9));
        state.Enemies.Add(CreateEnemy("low", hp: 3));

        var result = spells.TryCast(state, "thunder");

        Assert.True(result.Success);
        Assert.Equal("Thunder obliterates low! (had 3 HP)", result.Message);
        Assert.Single(state.Enemies);
        Assert.Equal("high", state.Enemies[0]["word"]);
    }

    [Fact]
    public void TryCast_Thunder_NoEnemies_ReturnsNoEnemiesMessage()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "thunder");

        Assert.True(result.Success);
        Assert.Equal("Thunder strikes, but no enemies remain.", result.Message);
    }

    [Fact]
    public void TryCast_SuccessfulCast_SetsCooldownForSpell()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "heal");
        var spellState = spells.GetState("heal");

        Assert.True(result.Success);
        Assert.NotNull(spellState);
        Assert.Equal(45f, spellState!.CooldownRemaining);
        Assert.False(spellState.IsReady);
    }

    [Fact]
    public void TryCast_SecondCastWhileOnCooldown_Fails()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var first = spells.TryCast(state, "shield");
        var second = spells.TryCast(state, "shield");

        Assert.True(first.Success);
        Assert.False(second.Success);
        Assert.Equal("Shield is on cooldown (60s remaining).", second.Message);
    }

    private static Dictionary<string, object> CreateEnemy(
        string word,
        int hp = 10,
        int speed = 2,
        int armor = 0,
        string affix = "")
    {
        return new Dictionary<string, object>
        {
            ["hp"] = hp,
            ["alive"] = true,
            ["word"] = word,
            ["speed"] = speed,
            ["armor"] = armor,
            ["affix"] = affix,
        };
    }
}
