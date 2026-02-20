using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class SpellSystemTests
{
    private static Dictionary<string, object> MakeEnemy(int id, int hp, int x = 5, int y = 5, int speed = 2)
    {
        return new Dictionary<string, object>
        {
            ["id"] = id,
            ["hp"] = hp,
            ["max_hp"] = hp,
            ["alive"] = true,
            ["x"] = x,
            ["y"] = y,
            ["speed"] = speed,
            ["word"] = $"enemy{id}",
        };
    }

    // --- Cooldown tracking ---

    [Fact]
    public void TryCast_ValidSpell_PutsOnCooldown()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var (success, _) = spells.TryCast(state, "fireball");
        Assert.True(success);

        var spellState = spells.GetState("fireball");
        Assert.NotNull(spellState);
        Assert.False(spellState!.IsReady);
    }

    [Fact]
    public void TryCast_WhileOnCooldown_ReturnsFalse()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "fireball");
        var (second, message) = spells.TryCast(state, "fireball");

        Assert.False(second);
        Assert.Contains("cooldown", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void UpdateCooldowns_EventuallyMakesSpellReady()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "fireball");
        var def = SpellSystem.Registry["fireball"];

        // Tick past the full cooldown
        spells.UpdateCooldowns(def.CooldownSeconds + 1f);

        var spellState = spells.GetState("fireball");
        Assert.NotNull(spellState);
        Assert.True(spellState!.IsReady);
    }

    [Fact]
    public void CooldownRemaining_DoesNotGoNegative()
    {
        var spells = new SpellSystem();

        // Tick many times without casting
        spells.UpdateCooldowns(1000f);

        var spellState = spells.GetState("fireball");
        Assert.NotNull(spellState);
        Assert.True(spellState!.CooldownRemaining >= 0f);
    }

    [Fact]
    public void TryCast_InvalidKeyword_ReturnsFalse()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var (success, message) = spells.TryCast(state, "nonexistent_spell");
        Assert.False(success);
        Assert.Empty(message);
    }

    [Fact]
    public void Reset_ClearsAllCooldowns()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "fireball");
        spells.TryCast(state, "heal");

        spells.Reset();

        Assert.True(spells.GetState("fireball")!.IsReady);
        Assert.True(spells.GetState("heal")!.IsReady);
    }

    // --- Spell effects ---

    [Fact]
    public void Fireball_DamagesEnemies()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(MakeEnemy(1, 20));

        int hpBefore = Convert.ToInt32(state.Enemies[0]["hp"]);
        spells.TryCast(state, "fireball");
        int hpAfter = Convert.ToInt32(state.Enemies[0]["hp"]);

        Assert.True(hpAfter < hpBefore);
    }

    [Fact]
    public void Heal_RestoresPlayerHp()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Hp = 5;

        spells.TryCast(state, "heal");
        Assert.True(state.Hp > 5);
    }

    [Fact]
    public void Freeze_SlowsEnemies()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(MakeEnemy(1, 10, speed: 4));

        int speedBefore = Convert.ToInt32(state.Enemies[0]["speed"]);
        spells.TryCast(state, "freeze");
        int speedAfter = Convert.ToInt32(state.Enemies[0]["speed"]);

        Assert.True(speedAfter < speedBefore);
    }

    [Fact]
    public void Shield_AddsShieldBuff()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        spells.TryCast(state, "shield");

        Assert.Contains(state.ActiveBuffs,
            b => b.GetValueOrDefault("buff_id")?.ToString() == "spell_shield");
    }

    [Fact]
    public void Thunder_KillsWeakestEnemy()
    {
        var spells = new SpellSystem();
        var state = new GameState();
        state.Enemies.Add(MakeEnemy(1, 100));
        state.Enemies.Add(MakeEnemy(2, 3));

        spells.TryCast(state, "thunder");

        // Weakest enemy (id=2, hp=3) should be removed from list
        Assert.Single(state.Enemies);
        Assert.Equal(1, state.Enemies[0]["id"]);
    }

    [Fact]
    public void Thunder_NoEnemies_DoesNotCrash()
    {
        var spells = new SpellSystem();
        var state = new GameState();

        var (success, message) = spells.TryCast(state, "thunder");
        Assert.True(success);
        Assert.NotEmpty(message);
    }

    // --- Registry ---

    [Fact]
    public void Registry_ContainsAllFiveSpells()
    {
        Assert.Equal(5, SpellSystem.Registry.Count);
        Assert.True(SpellSystem.Registry.ContainsKey("fireball"));
        Assert.True(SpellSystem.Registry.ContainsKey("heal"));
        Assert.True(SpellSystem.Registry.ContainsKey("freeze"));
        Assert.True(SpellSystem.Registry.ContainsKey("shield"));
        Assert.True(SpellSystem.Registry.ContainsKey("thunder"));
    }

    [Fact]
    public void IsSpellKeyword_ValidKeyword_ReturnsTrue()
    {
        Assert.True(SpellSystem.IsSpellKeyword("fireball"));
        Assert.True(SpellSystem.IsSpellKeyword("HEAL")); // case-insensitive
    }

    [Fact]
    public void IsSpellKeyword_InvalidKeyword_ReturnsFalse()
    {
        Assert.False(SpellSystem.IsSpellKeyword("nonexistent"));
    }

    [Fact]
    public void AllSpells_HavePositiveCooldown()
    {
        foreach (var (key, def) in SpellSystem.Registry)
            Assert.True(def.CooldownSeconds > 0f, $"Spell '{key}' should have positive cooldown");
    }
}
