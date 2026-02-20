using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.Combat;

/// <summary>
/// Spell effect types applied when a spell is cast.
/// </summary>
public enum SpellEffect
{
    AreaDamage,
    HealCastle,
    FreezeEnemies,
    ShieldCastle,
    InstantKill,
}

/// <summary>
/// Definition of a castable spell.
/// </summary>
public record SpellDef(
    string Name,
    string Description,
    string Keyword,
    float CooldownSeconds,
    SpellEffect Effect);

/// <summary>
/// Tracks per-spell cooldown state.
/// </summary>
public class SpellState
{
    public float CooldownRemaining { get; set; }
    public bool IsReady => CooldownRemaining <= 0f;
}

/// <summary>
/// Spell casting system for battle mode.
/// Players type spell keywords to cast special abilities during combat.
/// Ported from Godot's spell/ability system.
/// </summary>
public class SpellSystem
{
    private static SpellSystem? _instance;
    public static SpellSystem Instance => _instance ??= new();

    /// <summary>
    /// Static registry of all available spells.
    /// </summary>
    public static readonly Dictionary<string, SpellDef> Registry = new()
    {
        ["fireball"] = new("Fireball", "Deal 5 damage to all enemies.", "fireball", 30f, SpellEffect.AreaDamage),
        ["heal"] = new("Heal", "Restore 3 HP to the castle.", "heal", 45f, SpellEffect.HealCastle),
        ["freeze"] = new("Freeze", "Slow all enemies for 5 seconds.", "freeze", 40f, SpellEffect.FreezeEnemies),
        ["shield"] = new("Shield", "Block the next 2 damage to the castle.", "shield", 60f, SpellEffect.ShieldCastle),
        ["thunder"] = new("Thunder", "Instantly kill the lowest-HP enemy.", "thunder", 50f, SpellEffect.InstantKill),
    };

    private readonly Dictionary<string, SpellState> _states = new();

    public SpellSystem()
    {
        foreach (var key in Registry.Keys)
            _states[key] = new SpellState();
    }

    /// <summary>
    /// Reset all cooldowns (e.g. at battle start).
    /// </summary>
    public void Reset()
    {
        foreach (var state in _states.Values)
            state.CooldownRemaining = 0f;
    }

    /// <summary>
    /// Check if a keyword matches any spell.
    /// </summary>
    public static bool IsSpellKeyword(string keyword)
        => Registry.ContainsKey(keyword.ToLowerInvariant());

    /// <summary>
    /// Get the cooldown state for a spell.
    /// </summary>
    public SpellState? GetState(string keyword)
        => _states.GetValueOrDefault(keyword.ToLowerInvariant());

    /// <summary>
    /// Tick down all cooldowns by deltaSeconds.
    /// </summary>
    public void UpdateCooldowns(float deltaSeconds)
    {
        foreach (var state in _states.Values)
        {
            if (state.CooldownRemaining > 0f)
                state.CooldownRemaining = MathF.Max(0f, state.CooldownRemaining - deltaSeconds);
        }
    }

    /// <summary>
    /// Attempt to cast a spell by keyword. Returns true if the spell was cast,
    /// along with a log message describing the result.
    /// </summary>
    public (bool Success, string Message) TryCast(GameState state, string keyword)
    {
        string key = keyword.ToLowerInvariant();

        if (!Registry.TryGetValue(key, out var def))
            return (false, "");

        if (!_states.TryGetValue(key, out var spellState))
            return (false, "");

        if (!spellState.IsReady)
        {
            float remaining = MathF.Ceiling(spellState.CooldownRemaining);
            return (false, $"{def.Name} is on cooldown ({remaining:F0}s remaining).");
        }

        string message = ApplyEffect(state, def);
        spellState.CooldownRemaining = def.CooldownSeconds;
        return (true, message);
    }

    private static string ApplyEffect(GameState state, SpellDef def)
    {
        switch (def.Effect)
        {
            case SpellEffect.AreaDamage:
                return ApplyAreaDamage(state);

            case SpellEffect.HealCastle:
                return ApplyHeal(state);

            case SpellEffect.FreezeEnemies:
                return ApplyFreeze(state);

            case SpellEffect.ShieldCastle:
                return ApplyShield(state);

            case SpellEffect.InstantKill:
                return ApplyInstantKill(state);

            default:
                return $"{def.Name} fizzled.";
        }
    }

    private static string ApplyAreaDamage(GameState state)
    {
        const int damage = 5;
        int hit = 0;
        foreach (var enemy in state.Enemies)
        {
            Enemies.ApplyDamage(enemy, damage);
            hit++;
        }
        // Remove dead enemies
        state.Enemies.RemoveAll(e =>
        {
            bool alive = Convert.ToBoolean(e.GetValueOrDefault("alive", true));
            return !alive;
        });
        return hit > 0
            ? $"Fireball hits {hit} enemies for {damage} damage each!"
            : "Fireball blazes across an empty field.";
    }

    private static string ApplyHeal(GameState state)
    {
        const int healAmount = 3;
        int before = state.Hp;
        state.Hp += healAmount;
        int healed = state.Hp - before;
        return $"Heal restores {healed} HP! (HP: {state.Hp})";
    }

    private static string ApplyFreeze(GameState state)
    {
        const float slowDuration = 5.0f;
        int affected = 0;
        foreach (var enemy in state.Enemies)
        {
            // Apply slow status via the status effect key
            if (!enemy.ContainsKey("_statuses"))
                enemy["_statuses"] = new Dictionary<string, object>();

            var statuses = enemy["_statuses"] as Dictionary<string, object>
                ?? new Dictionary<string, object>();
            statuses["frozen"] = slowDuration;
            enemy["_statuses"] = statuses;

            // Also reduce speed directly for immediate gameplay effect
            int speed = Convert.ToInt32(enemy.GetValueOrDefault("speed", 1));
            enemy["_pre_freeze_speed"] = speed;
            enemy["speed"] = Math.Max(1, speed / 2);
            affected++;
        }
        return affected > 0
            ? $"Freeze slows {affected} enemies for {slowDuration:F0}s!"
            : "Freeze chills the empty air.";
    }

    private static string ApplyShield(GameState state)
    {
        const int blockCharges = 2;
        // Store shield charges in active buffs
        var shieldBuff = new Dictionary<string, object>
        {
            ["buff_id"] = "spell_shield",
            ["remaining_charges"] = blockCharges,
            ["remaining_days"] = 999, // Lasts until charges consumed
        };

        // Replace existing spell shield or add new
        state.ActiveBuffs.RemoveAll(b =>
            b.GetValueOrDefault("buff_id")?.ToString() == "spell_shield");
        state.ActiveBuffs.Add(shieldBuff);

        return $"Shield activated! Next {blockCharges} damage blocked.";
    }

    private static string ApplyInstantKill(GameState state)
    {
        if (state.Enemies.Count == 0)
            return "Thunder strikes, but no enemies remain.";

        // Find the enemy with the lowest HP
        Dictionary<string, object>? weakest = null;
        int lowestHp = int.MaxValue;
        foreach (var enemy in state.Enemies)
        {
            int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
            if (hp < lowestHp)
            {
                lowestHp = hp;
                weakest = enemy;
            }
        }

        if (weakest == null)
            return "Thunder strikes, but finds no target.";

        string word = weakest.GetValueOrDefault("word")?.ToString() ?? "enemy";
        weakest["hp"] = 0;
        weakest["alive"] = false;
        state.Enemies.Remove(weakest);

        return $"Thunder obliterates {word}! (had {lowestHp} HP)";
    }
}
