using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Floating damage/heal/gold numbers with pooling.
/// Ported from game/damage_numbers.gd (325 lines).
/// </summary>
public class DamageNumbers
{
    public enum NumberType
    {
        Damage, Heal, Gold, Xp, Combo, Critical, Miss, Blocked
    }

    private class FloatingNumber
    {
        public Vector2 Position;
        public Vector2 Velocity;
        public string Text = "";
        public Color BaseColor;
        public float Lifetime;
        public float MaxLifetime;
        public float Scale;
        public bool Active;
    }

    private static DamageNumbers? _instance;
    /// <summary>
    /// Gets the shared floating number renderer instance.
    /// </summary>
    public static DamageNumbers Instance => _instance ??= new();

    private const float FloatDuration = 1.2f;
    private const float FloatDistance = 60f;
    private const float InitialVelocityY = -120f;
    private const float Gravity = 200f;
    private const int MaxNumbers = 64;

    private static readonly Dictionary<NumberType, Color> TypeColors = new()
    {
        [NumberType.Damage] = ThemeColors.DamageRed,
        [NumberType.Heal] = ThemeColors.HealGreen,
        [NumberType.Gold] = ThemeColors.GoldAccent,
        [NumberType.Xp] = ThemeColors.Cyan,
        [NumberType.Combo] = ThemeColors.ComboOrange,
        [NumberType.Critical] = new Color(255, 50, 50),
        [NumberType.Miss] = ThemeColors.TextMuted,
        [NumberType.Blocked] = ThemeColors.ShieldBlue,
    };

    private readonly List<FloatingNumber> _numbers = new();
    private readonly ObjectPool<FloatingNumber> _pool;

    /// <summary>
    /// Initializes pooling for floating combat number instances.
    /// </summary>
    public DamageNumbers()
    {
        _pool = new ObjectPool<FloatingNumber>(
            () => new FloatingNumber(),
            n => { n.Active = false; n.Text = ""; },
            32, MaxNumbers);
    }

    /// <summary>
    /// Gets the number of currently active floating numbers.
    /// </summary>
    public int ActiveCount => _numbers.Count;

    /// <summary>
    /// Spawns a standard damage number using the default float animation.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="damage">Damage value to display.</param>
    public void SpawnDamage(Vector2 worldPos, int damage)
        => Spawn(worldPos, damage.ToString(), NumberType.Damage, false);

    /// <summary>
    /// Spawns a critical damage number with emphasized scale and stronger upward launch.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="damage">Critical damage value to display.</param>
    public void SpawnCrit(Vector2 worldPos, int damage)
        => Spawn(worldPos, damage.ToString() + "!", NumberType.Critical, true);

    /// <summary>
    /// Spawns a heal number using the default floating animation.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="amount">Healing amount to display.</param>
    public void SpawnHeal(Vector2 worldPos, int amount)
        => Spawn(worldPos, "+" + amount, NumberType.Heal, false);

    /// <summary>
    /// Spawns a blocked-hit label using the default floating animation.
    /// </summary>
    /// <param name="worldPos">World position where the label appears.</param>
    public void SpawnBlocked(Vector2 worldPos)
        => Spawn(worldPos, "BLOCKED", NumberType.Blocked, false);

    /// <summary>
    /// Spawns a gold gain number using the default floating animation.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="amount">Gold amount to display.</param>
    public void SpawnGold(Vector2 worldPos, int amount)
        => Spawn(worldPos, "+" + amount + "g", NumberType.Gold, false);

    /// <summary>
    /// Spawns an experience gain number using the default floating animation.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="amount">Experience amount to display.</param>
    public void SpawnXp(Vector2 worldPos, int amount)
        => Spawn(worldPos, "+" + amount + "xp", NumberType.Xp, false);

    /// <summary>
    /// Spawns a combo counter using the default floating animation.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="combo">Combo multiplier to display.</param>
    public void SpawnCombo(Vector2 worldPos, int combo)
        => Spawn(worldPos, combo + "x!", NumberType.Combo, false);

    /// <summary>
    /// Spawns a miss label using the default floating animation.
    /// </summary>
    /// <param name="worldPos">World position where the label appears.</param>
    public void SpawnMiss(Vector2 worldPos)
        => Spawn(worldPos, "MISS", NumberType.Miss, false);

    /// <summary>
    /// Spawns a floating number with 1.2 second lifetime, horizontal jitter, upward launch, and optional crit scaling.
    /// </summary>
    /// <param name="worldPos">World position where the number appears.</param>
    /// <param name="text">Display text rendered for this floating number.</param>
    /// <param name="type">Semantic number type used to choose color.</param>
    /// <param name="isCrit">When <see langword="true"/>, applies larger scale and stronger upward velocity.</param>
    public void Spawn(Vector2 worldPos, string text, NumberType type, bool isCrit)
    {
        if (_numbers.Count >= MaxNumbers) return;

        var num = _pool.Get();
        num.Position = worldPos;
        num.Velocity = new Vector2(
            (float)(Random.Shared.NextDouble() * 40 - 20),
            InitialVelocityY + (isCrit ? -40f : 0f));
        num.Text = text;
        num.BaseColor = TypeColors.GetValueOrDefault(type, Color.White);
        num.Lifetime = 0f;
        num.MaxLifetime = FloatDuration;
        num.Scale = isCrit ? 1.5f : 1.0f;
        num.Active = true;
        _numbers.Add(num);
    }

    /// <summary>
    /// Advances floating number animation by applying gravity, position integration, and lifetime expiration.
    /// </summary>
    /// <param name="gameTime">Frame timing used to compute simulation delta time.</param>
    public void Update(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;

        for (int i = _numbers.Count - 1; i >= 0; i--)
        {
            var num = _numbers[i];
            num.Lifetime += dt;

            if (num.Lifetime >= num.MaxLifetime)
            {
                _pool.Return(num);
                _numbers.RemoveAt(i);
                continue;
            }

            num.Velocity.Y += Gravity * dt;
            num.Position += num.Velocity * dt;
        }
    }

    /// <summary>
    /// Draws active floating numbers with shadow, pulse scale animation, and fade-out during the final 30 percent of lifetime.
    /// </summary>
    /// <param name="spriteBatch">Sprite batch used to render text.</param>
    /// <param name="font">SpriteFont used to measure and draw labels.</param>
    /// <param name="cameraTransform">Optional world-to-screen transform matrix.</param>
    public void Draw(SpriteBatch spriteBatch, SpriteFont font, Matrix? cameraTransform = null)
    {
        if (_numbers.Count == 0) return;

        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            blendState: BlendState.AlphaBlend,
            samplerState: SamplerState.PointClamp);

        foreach (var num in _numbers)
        {
            float t = num.Lifetime / num.MaxLifetime;
            float alpha = t < 0.7f ? 1f : 1f - (t - 0.7f) / 0.3f;
            float scale = num.Scale * (1f + MathF.Sin(t * MathF.PI) * 0.2f);

            var color = num.BaseColor * alpha;
            var origin = font.MeasureString(num.Text) * 0.5f;

            // Shadow
            spriteBatch.DrawString(font, num.Text, num.Position + Vector2.One * 2,
                Color.Black * alpha * 0.5f, 0f, origin, scale, SpriteEffects.None, 0f);

            // Text
            spriteBatch.DrawString(font, num.Text, num.Position,
                color, 0f, origin, scale, SpriteEffects.None, 0f);
        }

        spriteBatch.End();
    }

    /// <summary>
    /// Returns all active floating numbers to the pool and clears the active list.
    /// </summary>
    public void Clear()
    {
        foreach (var num in _numbers)
            _pool.Return(num);
        _numbers.Clear();
    }
}
