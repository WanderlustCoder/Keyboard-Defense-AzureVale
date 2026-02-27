using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Particle-based hit effects with object pooling.
/// Ported from game/hit_effects.gd (373 lines).
/// </summary>
public class HitEffects : IDisposable
{
    private class Particle
    {
        public Vector2 Position;
        public Vector2 Velocity;
        public Color BaseColor;
        public float Lifetime;
        public float MaxLifetime;
        public float Size;
        public bool Active;
    }

    private static HitEffects? _instance;
    /// <summary>
    /// Gets the shared hit effects renderer instance.
    /// </summary>
    public static HitEffects Instance => _instance ??= new();

    private const float DefaultLifetime = 0.5f;
    private const float DefaultSpeed = 200f;
    private const float DefaultSize = 4f;
    private const int DefaultCount = 8;
    private const int MaxParticles = 512;

    private readonly List<Particle> _particles = new();
    private readonly ObjectPool<Particle> _pool;
    private Texture2D? _pixel;

    /// <summary>
    /// Initializes particle pooling for hit effect bursts.
    /// </summary>
    public HitEffects()
    {
        _pool = new ObjectPool<Particle>(
            () => new Particle(),
            p => { p.Active = false; },
            64, MaxParticles);
    }

    /// <summary>
    /// Gets the number of currently active particles.
    /// </summary>
    public int ActiveCount => _particles.Count;

    /// <summary>
    /// Creates the 1x1 texture used to render square particles.
    /// </summary>
    /// <param name="device">Graphics device that owns the particle texture resource.</param>
    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    /// <summary>
    /// Spawns a standard radial spark burst at 200 px/s with a 0.5 second lifetime and 4 px particle size.
    /// </summary>
    /// <param name="position">World position where the burst originates.</param>
    /// <param name="color">Base particle color for the burst.</param>
    /// <param name="count">Number of particles to emit before reduced-motion scaling.</param>
    public void SpawnHitSparks(Vector2 position, Color color, int count = DefaultCount)
    {
        SpawnBurst(position, color, count, DefaultSpeed, DefaultLifetime, DefaultSize);
    }

    /// <summary>
    /// Spawns a high-intensity burst (16 particles, 300 px/s, 0.6 seconds, 6 px) for power actions.
    /// </summary>
    /// <param name="position">World position where the burst originates.</param>
    public void SpawnPowerBurst(Vector2 position)
    {
        SpawnBurst(position, ThemeColors.GoldAccent, 16, 300f, 0.6f, 6f);
    }

    /// <summary>
    /// Spawns a short damage flash burst (6 particles, 150 px/s, 0.3 seconds, 3 px).
    /// </summary>
    /// <param name="position">World position where the flash originates.</param>
    public void SpawnDamageFlash(Vector2 position)
    {
        SpawnBurst(position, ThemeColors.DamageRed, 6, 150f, 0.3f, 3f);
    }

    /// <summary>
    /// Spawns a completion burst (12 particles, 250 px/s, 0.5 seconds, 5 px) for completed words.
    /// </summary>
    /// <param name="position">World position where the completion burst originates.</param>
    public void SpawnWordCompleteBurst(Vector2 position)
    {
        SpawnBurst(position, ThemeColors.Cyan, 12, 250f, 0.5f, 5f);
    }

    /// <summary>
    /// Spawns a critical-hit burst (20 particles, 350 px/s, 0.7 seconds, 7 px).
    /// </summary>
    /// <param name="position">World position where the critical burst originates.</param>
    public void SpawnCriticalHit(Vector2 position)
    {
        SpawnBurst(position, new Color(255, 50, 50), 20, 350f, 0.7f, 7f);
    }

    /// <summary>
    /// Spawns layered death effects: a primary colored burst and a slower gray smoke burst.
    /// </summary>
    /// <param name="position">World position where the enemy died.</param>
    /// <param name="color">Primary burst color, typically tied to enemy type.</param>
    public void SpawnEnemyDeath(Vector2 position, Color color)
    {
        SpawnBurst(position, color, 24, 400f, 0.8f, 6f);
        SpawnBurst(position, Color.Gray, 8, 100f, 1.0f, 3f); // Smoke
    }

    /// <summary>
    /// Spawns short-lived trail bursts along a tower projectile path.
    /// </summary>
    /// <param name="from">Start world position of the shot path.</param>
    /// <param name="to">End world position of the shot path.</param>
    /// <param name="color">Trail particle color.</param>
    public void SpawnTowerShot(Vector2 from, Vector2 to, Color color)
    {
        // Trail particles along the shot path
        Vector2 dir = to - from;
        float dist = dir.Length();
        if (dist < 1f) return;
        dir /= dist;

        int trailCount = Math.Min(8, (int)(dist / 20f));
        for (int i = 0; i < trailCount; i++)
        {
            float t = (float)i / trailCount;
            Vector2 pos = Vector2.Lerp(from, to, t);
            SpawnBurst(pos, color, 2, 60f, 0.3f, 2f);
        }
    }

    /// <summary>
    /// Spawns subtle ground dust (3 particles, 30 px/s, 0.4 seconds, 2 px) for enemy movement.
    /// </summary>
    /// <param name="position">World position near the enemy feet.</param>
    public void SpawnDustTrail(Vector2 position)
    {
        SpawnBurst(position + new Vector2(0, 4), new Color(120, 110, 90), 3, 30f, 0.4f, 2f);
    }

    /// <summary>
    /// Spawns small status particles (2 particles, 40 px/s, 0.3 seconds, 2 px) color-coded by effect type.
    /// </summary>
    /// <param name="position">World position where the status pulse appears.</param>
    /// <param name="effectType">Status key used to select particle color.</param>
    public void SpawnStatusTick(Vector2 position, string effectType)
    {
        Color color = effectType switch
        {
            "burn" or "fire" => new Color(255, 140, 40),
            "poison" => new Color(60, 200, 60),
            "freeze" or "slow" => new Color(150, 200, 255),
            "shield" => new Color(80, 140, 255),
            _ => Color.Gray,
        };
        SpawnBurst(position, color, 2, 40f, 0.3f, 2f);
    }

    /// <summary>
    /// Spawns layered construction completion sparkles with a gold burst and a white accent burst.
    /// </summary>
    /// <param name="position">World position where construction completed.</param>
    public void SpawnBuildComplete(Vector2 position)
    {
        SpawnBurst(position, ThemeColors.GoldAccent, 10, 120f, 0.6f, 4f);
        SpawnBurst(position, Color.White, 6, 80f, 0.4f, 3f);
    }

    private void SpawnBurst(Vector2 position, Color color, int count, float speed, float lifetime, float size)
    {
        // Reduce particle count when reduced motion is enabled
        var sm = KeyboardDefenseGame.Instance?.SettingsManager;
        if (sm != null && sm.ReducedMotion)
            count = Math.Max(1, count / 4);

        for (int i = 0; i < count; i++)
        {
            if (_particles.Count >= MaxParticles) break;

            var p = _pool.Get();
            float angle = (float)(Random.Shared.NextDouble() * MathHelper.TwoPi);
            float spd = speed * (0.5f + (float)Random.Shared.NextDouble() * 0.5f);

            p.Position = position;
            p.Velocity = new Vector2(MathF.Cos(angle) * spd, MathF.Sin(angle) * spd);
            p.BaseColor = color;
            p.Lifetime = 0f;
            p.MaxLifetime = lifetime * (0.7f + (float)Random.Shared.NextDouble() * 0.3f);
            p.Size = size * (0.8f + (float)Random.Shared.NextDouble() * 0.4f);
            p.Active = true;
            _particles.Add(p);
        }
    }

    /// <summary>
    /// Advances particle simulation, applying deceleration and removing particles once their lifetime expires.
    /// </summary>
    /// <param name="gameTime">Frame timing used to compute simulation delta time.</param>
    public void Update(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;

        for (int i = _particles.Count - 1; i >= 0; i--)
        {
            var p = _particles[i];
            p.Lifetime += dt;

            if (p.Lifetime >= p.MaxLifetime)
            {
                _pool.Return(p);
                _particles.RemoveAt(i);
                continue;
            }

            // Deceleration
            p.Velocity *= 1f - dt * 3f;
            p.Position += p.Velocity * dt;
        }
    }

    /// <summary>
    /// Draws active particles with time-based fade and size shrink animation.
    /// </summary>
    /// <param name="spriteBatch">Sprite batch used to render particle quads.</param>
    /// <param name="cameraTransform">Optional world-to-screen transform matrix.</param>
    public void Draw(SpriteBatch spriteBatch, Matrix? cameraTransform = null)
    {
        if (_particles.Count == 0 || _pixel == null) return;

        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            blendState: BlendState.AlphaBlend,
            samplerState: SamplerState.PointClamp);

        foreach (var p in _particles)
        {
            float t = p.Lifetime / p.MaxLifetime;
            float alpha = t < 0.5f ? 1f : 1f - (t - 0.5f) / 0.5f;
            float size = p.Size * (1f - t * 0.5f);

            var color = p.BaseColor * alpha;
            var rect = new Rectangle(
                (int)(p.Position.X - size * 0.5f),
                (int)(p.Position.Y - size * 0.5f),
                (int)size, (int)size);

            spriteBatch.Draw(_pixel, rect, color);
        }

        spriteBatch.End();
    }

    /// <summary>
    /// Returns all active particles to the pool and clears the active list.
    /// </summary>
    public void Clear()
    {
        foreach (var p in _particles)
            _pool.Return(p);
        _particles.Clear();
    }

    public void Dispose()
    {
        _pixel?.Dispose();
        _pixel = null;
    }
}
