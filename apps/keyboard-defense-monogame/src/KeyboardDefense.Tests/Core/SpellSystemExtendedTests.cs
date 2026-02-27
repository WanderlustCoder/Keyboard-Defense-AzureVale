using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for SpellSystem — edge cases, multi-cast sequences,
/// cooldown interactions, and effect boundary conditions.
/// </summary>
public class SpellSystemExtendedTests
{
    // =========================================================================
    // Registry
    // =========================================================================

    [Fact]
    public void Registry_AllSpellsHaveNonEmptyDescriptions()
    {
        foreach (var (_, def) in SpellSystem.Registry)
        {
            Assert.False(string.IsNullOrWhiteSpace(def.Description),
                $"Spell '{def.Name}' has empty description");
        }
    }

    [Fact]
    public void Registry_AllCooldownsArePositive()
    {
        foreach (var (_, def) in SpellSystem.Registry)
        {
            Assert.True(def.CooldownSeconds > 0,
                $"Spell '{def.Name}' has non-positive cooldown");
        }
    }

    [Fact]
    public void Registry_KeywordMatchesKey()
    {
        foreach (var (key, def) in SpellSystem.Registry)
        {
            Assert.Equal(key, def.Keyword);
        }
    }

    // =========================================================================
    // IsSpellKeyword — case variants
    // =========================================================================

    [Theory]
    [InlineData("fireball")]
    [InlineData("FIREBALL")]
    [InlineData("Fireball")]
    [InlineData("fIrEbAlL")]
    public void IsSpellKeyword_CaseInsensitive(string keyword)
    {
        Assert.True(SpellSystem.IsSpellKeyword(keyword));
    }

    // =========================================================================
    // TryCast — case insensitivity
    // =========================================================================

    [Fact]
    public void TryCast_CaseInsensitive_CastsSuccessfully()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "HEAL");

        Assert.True(result.Success);
        Assert.Contains("Heal", result.Message);
    }

    // =========================================================================
    // Freeze — edge cases
    // =========================================================================

    [Fact]
    public void Freeze_NoEnemies_ReturnsChillsMessage()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var result = spells.TryCast(state, "freeze");

        Assert.True(result.Success);
        Assert.Equal("Freeze chills the empty air.", result.Message);
    }

    [Fact]
    public void Freeze_SpeedOneEnemy_ClampsToOne()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("slow", hp: 10, speed: 1));

        var result = spells.TryCast(state, "freeze");

        Assert.True(result.Success);
        Assert.Equal(1, Convert.ToInt32(state.Enemies[0]["speed"]));
    }

    [Fact]
    public void Freeze_StoresPreFreezeSpeed()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("fast", hp: 10, speed: 6));

        spells.TryCast(state, "freeze");

        Assert.Equal(6, Convert.ToInt32(state.Enemies[0]["_pre_freeze_speed"]));
        Assert.Equal(3, Convert.ToInt32(state.Enemies[0]["speed"]));
    }

    // =========================================================================
    // Shield — replacement behavior
    // =========================================================================

    [Fact]
    public void Shield_ReplacesExistingShieldBuff()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        // Cast shield twice (reset cooldown between)
        spells.TryCast(state, "shield");
        spells.Reset();
        spells.TryCast(state, "shield");

        var shields = state.ActiveBuffs
            .Where(b => b.GetValueOrDefault("buff_id")?.ToString() == "spell_shield")
            .ToList();
        Assert.Single(shields);
    }

    // =========================================================================
    // Thunder — ties
    // =========================================================================

    [Fact]
    public void Thunder_SameHp_KillsOne()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("alpha", hp: 5));
        state.Enemies.Add(CreateEnemy("beta", hp: 5));

        spells.TryCast(state, "thunder");

        Assert.Single(state.Enemies);
    }

    // =========================================================================
    // Heal — no HP cap
    // =========================================================================

    [Fact]
    public void Heal_CanExceedStartingHp()
    {
        var spells = new SpellSystem();
        var state = new GameState { Hp = 10 };

        var result = spells.TryCast(state, "heal");

        Assert.True(result.Success);
        Assert.Equal(13, state.Hp);
    }

    // =========================================================================
    // Cooldown sequencing
    // =========================================================================

    [Fact]
    public void CastingOneSpell_DoesNotAffectOtherCooldowns()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "fireball");

        var healState = spells.GetState("heal");
        Assert.NotNull(healState);
        Assert.True(healState!.IsReady);
    }

    [Fact]
    public void UpdateCooldowns_TicksAllSpellsSimultaneously()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "fireball"); // 30s cd
        spells.TryCast(state, "heal");     // 45s cd

        spells.UpdateCooldowns(10f);

        Assert.InRange(spells.GetState("fireball")!.CooldownRemaining, 19.9f, 20.1f);
        Assert.InRange(spells.GetState("heal")!.CooldownRemaining, 34.9f, 35.1f);
    }

    [Fact]
    public void UpdateCooldowns_SpellBecomesReadyAfterFullDuration()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "fireball"); // 30s cd
        spells.UpdateCooldowns(30f);

        Assert.True(spells.GetState("fireball")!.IsReady);
    }

    // =========================================================================
    // SpellEffect enum coverage
    // =========================================================================

    [Fact]
    public void SpellEffect_AllValuesRepresentedInRegistry()
    {
        var registeredEffects = SpellSystem.Registry.Values
            .Select(d => d.Effect)
            .Distinct()
            .ToHashSet();

        foreach (SpellEffect effect in Enum.GetValues<SpellEffect>())
        {
            Assert.Contains(effect, registeredEffects);
        }
    }

    // =========================================================================
    // Fireball — damage calculation
    // =========================================================================

    [Fact]
    public void Fireball_DealsFiveDamageToEachEnemy()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(CreateEnemy("a", hp: 20));
        state.Enemies.Add(CreateEnemy("b", hp: 20));
        state.Enemies.Add(CreateEnemy("c", hp: 20));

        spells.TryCast(state, "fireball");

        Assert.All(state.Enemies, e =>
            Assert.Equal(15, Convert.ToInt32(e["hp"])));
    }

    // =========================================================================
    // Constructor — all registry keys get state entries
    // =========================================================================

    [Fact]
    public void Constructor_CreatesStateForEveryRegisteredSpell()
    {
        var spells = new SpellSystem();

        foreach (var key in SpellSystem.Registry.Keys)
        {
            Assert.NotNull(spells.GetState(key));
        }
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static Dictionary<string, object> CreateEnemy(
        string word, int hp = 10, int speed = 2)
    {
        return new Dictionary<string, object>
        {
            ["hp"] = hp,
            ["alive"] = true,
            ["word"] = word,
            ["speed"] = speed,
            ["armor"] = 0,
            ["affix"] = "",
        };
    }
}
