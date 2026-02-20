using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Visual combat arena renderer for the battlefield screen.
/// Draws castle, enemies advancing, projectiles, HP bar, word progress.
/// </summary>
public class BattleStageRenderer
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    // Layout
    private Rectangle _bounds;
    private const int CastleWidth = 80;
    private const int CastleHeight = 120;
    private const int EnemySize = 40;
    private const int ProjectileSize = 6;
    private const int HpBarHeight = 20;
    private const float EnemySpacing = 70f;

    // Animation
    private float _totalTime;

    // Projectiles
    private readonly List<Projectile> _projectiles = new();
    private const float ProjectileSpeed = 600f;
    private const float ProjectileLifetime = 1.0f;

    // Hit flashes
    private readonly Dictionary<int, float> _hitFlashes = new();
    private const float HitFlashDuration = 0.15f;

    // Death animations
    private readonly List<DeathAnim> _deathAnims = new();
    private const float DeathAnimDuration = 0.4f;

    // Spawn animations (enemy ID -> remaining fade-in time)
    private readonly Dictionary<int, float> _spawnAnims = new();
    private const float SpawnAnimDuration = 0.3f;

    // Castle damage flash
    private float _castleFlashTimer;
    private const float CastleFlashDuration = 0.2f;

    // Combo counter
    private int _displayCombo;
    private float _comboPopTimer;
    private const float ComboPopDuration = 0.3f;

    // Dust trail timer
    private float _dustTimer;
    private bool _dustSpawnPending;
    private const float DustInterval = 0.4f;

    // Per-enemy animation states
    private readonly Dictionary<int, SpriteAnimator.AnimationState> _enemyAnimStates = new();

    // Status effect colors
    private static readonly Dictionary<string, Color> StatusColors = new()
    {
        ["burn"] = new Color(255, 140, 40),
        ["fire"] = new Color(255, 140, 40),
        ["poison"] = new Color(60, 200, 60),
        ["shield"] = new Color(80, 140, 255),
        ["slow"] = new Color(80, 220, 220),
        ["freeze"] = new Color(150, 200, 255),
        ["stun"] = new Color(255, 255, 80),
    };

    private struct Projectile
    {
        public Vector2 Position;
        public Vector2 Target;
        public Vector2 Velocity;
        public float Lifetime;
        public Color Color;
    }

    private struct DeathAnim
    {
        public Vector2 Position;
        public float Timer;
        public Color Color;
    }

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public void SetBounds(Rectangle bounds)
    {
        _bounds = bounds;
    }

    public void Update(GameTime gameTime, float speedMultiplier = 1f)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds * speedMultiplier;
        _totalTime += dt;

        // Update projectiles
        for (int i = _projectiles.Count - 1; i >= 0; i--)
        {
            var p = _projectiles[i];
            p.Lifetime -= dt;
            p.Position += p.Velocity * dt;
            _projectiles[i] = p;

            if (p.Lifetime <= 0f || Vector2.Distance(p.Position, p.Target) < 10f)
                _projectiles.RemoveAt(i);
        }

        // Update hit flashes
        var expiredFlashes = new List<int>();
        foreach (var (id, remaining) in _hitFlashes)
        {
            float newVal = remaining - dt;
            if (newVal <= 0f)
                expiredFlashes.Add(id);
        }
        foreach (int id in expiredFlashes)
            _hitFlashes.Remove(id);
        // Decay remaining
        var flashKeys = new List<int>(_hitFlashes.Keys);
        foreach (int key in flashKeys)
            _hitFlashes[key] -= dt;

        // Update death animations
        for (int i = _deathAnims.Count - 1; i >= 0; i--)
        {
            var d = _deathAnims[i];
            d.Timer -= dt;
            _deathAnims[i] = d;
            if (d.Timer <= 0f)
                _deathAnims.RemoveAt(i);
        }

        // Update spawn animations
        var expiredSpawns = new List<int>();
        foreach (var (id, remaining) in _spawnAnims)
        {
            if (remaining - dt <= 0f)
                expiredSpawns.Add(id);
        }
        foreach (int id in expiredSpawns)
            _spawnAnims.Remove(id);
        var spawnKeys = new List<int>(_spawnAnims.Keys);
        foreach (int key in spawnKeys)
            _spawnAnims[key] -= dt;

        // Update castle flash
        if (_castleFlashTimer > 0f)
            _castleFlashTimer -= dt;

        // Update combo pop
        if (_comboPopTimer > 0f)
            _comboPopTimer -= dt;

        // Update enemy animation states
        foreach (var (_, animState) in _enemyAnimStates)
            animState.Update(dt, _totalTime);

        // Periodic dust trails for walking enemies
        _dustTimer -= dt;
        if (_dustTimer <= 0f)
        {
            _dustTimer = DustInterval;
            _dustSpawnPending = true;
        }
    }

    /// <summary>
    /// Get or create an animation state for an enemy.
    /// </summary>
    private SpriteAnimator.AnimationState GetEnemyAnimState(int enemyId, string kind, int index)
    {
        if (!_enemyAnimStates.TryGetValue(enemyId, out var state))
        {
            state = SpriteAnimator.CreateState();
            // Stagger bob phase per enemy for visual variety
            state.EnableBob(speed: 2f, amplitude: 3f, phase: index * 0.7f);

            // Try to start walk animation if sprite sheet is available
            string spriteId = $"enemy_{kind}";
            AssetLoader.Instance.RegisterEnemySprite(kind);
            var sheet = AssetLoader.Instance.Animator.GetSheet(spriteId);
            var walkClip = sheet?.GetClip("walk") ?? sheet?.GetClip("idle");
            if (walkClip != null)
                state.Play(walkClip);

            _enemyAnimStates[enemyId] = state;
        }
        return state;
    }

    public void Draw(SpriteBatch spriteBatch, GameState state)
    {
        if (_pixel == null || _font == null) return;

        spriteBatch.Begin(
            blendState: BlendState.AlphaBlend,
            samplerState: SamplerState.PointClamp);

        DrawBackground(spriteBatch);
        DrawHpBar(spriteBatch, state);
        DrawCastle(spriteBatch, state);
        DrawCastleFlash(spriteBatch);
        DrawEnemies(spriteBatch, state);
        DrawStatusEffects(spriteBatch, state);
        DrawProjectiles(spriteBatch);
        DrawDeathAnims(spriteBatch);
        DrawWordProgress(spriteBatch, state);
        DrawComboCounter(spriteBatch, state);

        spriteBatch.End();
    }

    private void DrawBackground(SpriteBatch spriteBatch)
    {
        // Dark stage background
        spriteBatch.Draw(_pixel!, _bounds, new Color(15, 18, 25));

        // Ground line
        int groundY = _bounds.Bottom - 60;
        spriteBatch.Draw(_pixel!, new Rectangle(_bounds.X, groundY, _bounds.Width, 2),
            new Color(60, 70, 50));

        // Ground fill
        spriteBatch.Draw(_pixel!, new Rectangle(_bounds.X, groundY + 2, _bounds.Width, 58),
            new Color(25, 30, 20));
    }

    private void DrawHpBar(SpriteBatch spriteBatch, GameState state)
    {
        int maxHp = Math.Max(state.Hp, 20);
        float hpPct = Math.Clamp((float)state.Hp / maxHp, 0f, 1f);

        var barBg = new Rectangle(_bounds.X + 10, _bounds.Y + 8, _bounds.Width - 20, HpBarHeight);
        spriteBatch.Draw(_pixel!, barBg, new Color(30, 25, 40));

        int fillWidth = (int)(barBg.Width * hpPct);
        var barFill = new Rectangle(barBg.X, barBg.Y, fillWidth, barBg.Height);
        Color hpColor = ThemeColors.GetHealthColor(hpPct);
        spriteBatch.Draw(_pixel!, barFill, hpColor);

        // Border
        DrawRectOutline(spriteBatch, barBg, ThemeColors.Border, 1);

        // HP text
        string hpText = $"HP: {state.Hp}/{maxHp}";
        var textSize = _font!.MeasureString(hpText);
        spriteBatch.DrawString(_font, hpText,
            new Vector2(barBg.X + (barBg.Width - textSize.X) * 0.5f, barBg.Y + 2),
            Color.White, 0f, Vector2.Zero, 0.8f, SpriteEffects.None, 0f);
    }

    private void DrawCastle(SpriteBatch spriteBatch, GameState state)
    {
        int groundY = _bounds.Bottom - 60;
        int castleX = _bounds.X + 40;
        int castleY = groundY - CastleHeight;

        // Castle body
        var castleRect = new Rectangle(castleX, castleY, CastleWidth, CastleHeight);
        int castleMaxHp = Math.Max(state.Hp, 20);
        float hpPct = Math.Clamp((float)state.Hp / castleMaxHp, 0f, 1f);
        Color castleColor = ThemeColors.GetHealthColor(hpPct);

        var castleTexture = AssetLoader.Instance.GetBuildingTexture("castle");
        if (castleTexture != null)
            spriteBatch.Draw(castleTexture, castleRect, Color.White);
        else
            spriteBatch.Draw(_pixel!, castleRect, castleColor * 0.8f);

        // Castle battlements (3 notches across top)
        int notchW = CastleWidth / 5;
        int notchH = 12;
        for (int i = 0; i < 3; i++)
        {
            int nx = castleX + notchW * (i * 2) + 2;
            spriteBatch.Draw(_pixel!, new Rectangle(nx, castleY - notchH, notchW - 2, notchH),
                castleColor);
        }

        // Castle gate
        int gateW = 20;
        int gateH = 30;
        spriteBatch.Draw(_pixel!, new Rectangle(
            castleX + (CastleWidth - gateW) / 2,
            castleY + CastleHeight - gateH,
            gateW, gateH), new Color(30, 25, 15));

        // Castle label
        string label = "CASTLE";
        var labelSize = _font!.MeasureString(label);
        spriteBatch.DrawString(_font, label,
            new Vector2(castleX + (CastleWidth - labelSize.X * 0.6f) * 0.5f, castleY + 20),
            Color.White, 0f, Vector2.Zero, 0.6f, SpriteEffects.None, 0f);

        // Outline
        DrawRectOutline(spriteBatch, castleRect, castleColor, 2);
    }

    private void DrawEnemies(SpriteBatch spriteBatch, GameState state)
    {
        int groundY = _bounds.Bottom - 60;
        int startX = _bounds.Right - 60;

        // Track active enemy IDs for animation state cleanup
        var activeIds = new HashSet<int>();

        for (int i = 0; i < state.Enemies.Count; i++)
        {
            var enemy = state.Enemies[i];

            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";
            Color color = GetEnemyColor(kind);

            int enemyId = 0;
            if (enemy.TryGetValue("id", out var idObj))
                enemyId = Convert.ToInt32(idObj);
            activeIds.Add(enemyId);

            // Get per-enemy animation state (manages bob, frame animation)
            var animState = GetEnemyAnimState(enemyId, kind, i);

            // Position enemies from right, advancing left
            float xPos = startX - i * EnemySpacing;
            float yPos = groundY - EnemySize - 8;

            // Apply animation-driven bob offset
            yPos += animState.BobOffset;

            // Hit flash: override to white + knockback
            bool isFlashing = _hitFlashes.TryGetValue(enemyId, out float flashTime) && flashTime > 0;
            Color drawColor = isFlashing ? Color.White : color;
            if (isFlashing)
                xPos += 4f * (flashTime / HitFlashDuration);  // knockback toward right

            // Spawn fade-in
            float spawnAlpha = 1f;
            if (_spawnAnims.TryGetValue(enemyId, out float spawnTime) && spawnTime > 0)
            {
                spawnAlpha = 1f - (spawnTime / SpawnAnimDuration);
                xPos += (1f - spawnAlpha) * 30f;  // slide in from right
            }

            // Enemy body — use sprite animator if available
            var enemyRect = new Rectangle((int)xPos, (int)yPos, EnemySize, EnemySize);
            string spriteId = $"enemy_{kind}";
            var sheet = AssetLoader.Instance.Animator.GetSheet(spriteId);

            if (sheet?.Texture != null && !isFlashing)
                AssetLoader.Instance.Animator.Draw(spriteBatch, spriteId, animState,
                    enemyRect, Color.White * spawnAlpha);
            else
                spriteBatch.Draw(_pixel!, enemyRect, drawColor * spawnAlpha);

            // Dust trail at enemy feet (spawned between SpriteBatch Begin/End via HitEffects)
            if (_dustSpawnPending && spawnAlpha >= 1f && !isFlashing)
            {
                HitEffects.Instance.SpawnDustTrail(
                    new Vector2(xPos + EnemySize * 0.5f, yPos + EnemySize));
            }

            // Small HP bar above enemy
            if (enemy.TryGetValue("hp", out var hpObj))
            {
                int hp = Convert.ToInt32(hpObj);
                int maxHp = hp; // Approximate
                if (enemy.TryGetValue("max_hp", out var mhpObj))
                    maxHp = Math.Max(1, Convert.ToInt32(mhpObj));
                float hpPct = Math.Clamp((float)hp / maxHp, 0f, 1f);

                var hpBg = new Rectangle((int)xPos, (int)yPos - 8, EnemySize, 4);
                spriteBatch.Draw(_pixel!, hpBg, new Color(30, 10, 10));
                spriteBatch.Draw(_pixel!, new Rectangle(hpBg.X, hpBg.Y, (int)(hpBg.Width * hpPct), 4),
                    ThemeColors.GetHealthColor(hpPct));
            }

            // Word label below
            string word = enemy.GetValueOrDefault("word")?.ToString() ?? "";
            if (!string.IsNullOrEmpty(word))
            {
                var wordSize = _font!.MeasureString(word);
                float scale = Math.Min(0.7f, (EnemySpacing - 4) / wordSize.X);
                spriteBatch.DrawString(_font, word,
                    new Vector2(xPos + (EnemySize - wordSize.X * scale) * 0.5f, yPos + EnemySize + 4),
                    Color.White, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            }

            // Enemy kind letter on body (only when no sprite texture)
            if (sheet?.Texture == null && kind.Length > 0)
            {
                string letter = kind[..1].ToUpper();
                var letterSize = _font!.MeasureString(letter);
                spriteBatch.DrawString(_font, letter,
                    new Vector2(xPos + (EnemySize - letterSize.X) * 0.5f, yPos + (EnemySize - letterSize.Y) * 0.5f),
                    Color.White * 0.8f);
            }
        }

        _dustSpawnPending = false;

        // Clean up animation states for enemies no longer present
        var staleIds = new List<int>();
        foreach (var id in _enemyAnimStates.Keys)
        {
            if (!activeIds.Contains(id))
                staleIds.Add(id);
        }
        foreach (var id in staleIds)
            _enemyAnimStates.Remove(id);
    }

    private void DrawProjectiles(SpriteBatch spriteBatch)
    {
        foreach (var p in _projectiles)
        {
            var rect = new Rectangle(
                (int)(p.Position.X - ProjectileSize * 0.5f),
                (int)(p.Position.Y - ProjectileSize * 0.5f),
                ProjectileSize, ProjectileSize);
            spriteBatch.Draw(_pixel!, rect, p.Color);

            // Trail glow
            var trailRect = new Rectangle(rect.X - 2, rect.Y - 2, rect.Width + 4, rect.Height + 4);
            spriteBatch.Draw(_pixel!, trailRect, p.Color * 0.3f);
        }
    }

    private void DrawDeathAnims(SpriteBatch spriteBatch)
    {
        foreach (var d in _deathAnims)
        {
            float t = 1f - (d.Timer / DeathAnimDuration);
            float alpha = 1f - t;
            float scale = 1f + t * 0.5f;
            int size = (int)(EnemySize * scale);

            var rect = new Rectangle(
                (int)(d.Position.X - size * 0.5f),
                (int)(d.Position.Y - size * 0.5f),
                size, size);
            spriteBatch.Draw(_pixel!, rect, d.Color * alpha);
        }
    }

    private void DrawWordProgress(SpriteBatch spriteBatch, GameState state)
    {
        // Show the current typing target at the bottom of the stage
        string prompt = state.NightPrompt;
        if (string.IsNullOrEmpty(prompt) || state.Phase != "night") return;

        float y = _bounds.Bottom - 30;
        float x = _bounds.X + 150;

        // Background bar
        var promptSize = _font!.MeasureString(prompt);
        var bgRect = new Rectangle((int)x - 8, (int)y - 4, (int)(promptSize.X * 1.2f) + 16, 28);
        spriteBatch.Draw(_pixel!, bgRect, new Color(20, 15, 30) * 0.9f);
        DrawRectOutline(spriteBatch, bgRect, ThemeColors.Border, 1);

        // Render each character - typed chars in green, remaining in white
        float charX = x;
        for (int i = 0; i < prompt.Length; i++)
        {
            string ch = prompt[i].ToString();
            // Heuristic: use NightSpawnRemaining vs NightWaveTotal to indicate progress
            Color charColor = ThemeColors.TypedPending;
            spriteBatch.DrawString(_font, ch, new Vector2(charX, y), charColor);
            charX += _font.MeasureString(ch).X;
        }
    }

    // Public effect triggers
    public void FireProjectile(Vector2 from, Vector2 to, Color color)
    {
        var dir = to - from;
        float dist = dir.Length();
        if (dist < 1f) return;

        _projectiles.Add(new Projectile
        {
            Position = from,
            Target = to,
            Velocity = dir / dist * ProjectileSpeed,
            Lifetime = ProjectileLifetime,
            Color = color,
        });
    }

    public void FlashEnemy(int enemyId)
    {
        _hitFlashes[enemyId] = HitFlashDuration;
    }

    public void EnemyDeath(Vector2 position, Color color)
    {
        _deathAnims.Add(new DeathAnim
        {
            Position = position,
            Timer = DeathAnimDuration,
            Color = color,
        });
    }

    private void DrawCastleFlash(SpriteBatch spriteBatch)
    {
        if (_castleFlashTimer <= 0f) return;

        int groundY = _bounds.Bottom - 60;
        int castleX = _bounds.X + 40;
        int castleY = groundY - CastleHeight;
        var castleRect = new Rectangle(castleX, castleY, CastleWidth, CastleHeight);

        float alpha = _castleFlashTimer / CastleFlashDuration * 0.5f;
        spriteBatch.Draw(_pixel!, castleRect, new Color(255, 40, 40) * alpha);
    }

    private void DrawStatusEffects(SpriteBatch spriteBatch, GameState state)
    {
        int groundY = _bounds.Bottom - 60;
        int startX = _bounds.Right - 60;

        for (int i = 0; i < state.Enemies.Count; i++)
        {
            var enemy = state.Enemies[i];
            if (!enemy.TryGetValue("effects", out var effectsObj))
                continue;

            if (effectsObj is not List<Dictionary<string, object>> effects || effects.Count == 0)
                continue;

            float xPos = startX - i * EnemySpacing;
            float yBase = groundY - EnemySize - 16;

            int dotIndex = 0;
            foreach (var effect in effects)
            {
                string effectType = effect.GetValueOrDefault("type")?.ToString() ?? "";
                if (StatusColors.TryGetValue(effectType, out Color statusColor))
                {
                    int dotX = (int)xPos + dotIndex * 8;
                    int dotY = (int)yBase;
                    // Pulsing dot
                    float pulse = 0.7f + 0.3f * MathF.Sin(_totalTime * 4f + dotIndex);
                    spriteBatch.Draw(_pixel!, new Rectangle(dotX, dotY, 6, 6), statusColor * pulse);
                    dotIndex++;
                }
            }
        }
    }

    private void DrawComboCounter(SpriteBatch spriteBatch, GameState state)
    {
        if (state.Phase != "night" || _displayCombo <= 1)
            return;

        string comboText = $"x{_displayCombo}";
        var textSize = _font!.MeasureString(comboText);

        // Position: upper right of battle stage
        float x = _bounds.Right - textSize.X * 1.4f - 20;
        float y = _bounds.Y + 40;

        // Pop scale animation
        float scale = 1.2f;
        if (_comboPopTimer > 0f)
        {
            float t = _comboPopTimer / ComboPopDuration;
            scale = 1.2f + t * 0.4f;
        }

        // Background
        var bgRect = new Rectangle((int)(x - 8), (int)(y - 4),
            (int)(textSize.X * scale + 16), (int)(textSize.Y * scale + 8));
        spriteBatch.Draw(_pixel!, bgRect, new Color(20, 10, 30) * 0.8f);

        // Combo color based on streak
        Color comboColor = _displayCombo >= 20 ? new Color(255, 200, 40) :
                           _displayCombo >= 10 ? new Color(200, 100, 255) :
                           _displayCombo >= 5 ? new Color(100, 200, 255) :
                           new Color(200, 200, 200);

        spriteBatch.DrawString(_font, comboText, new Vector2(x, y),
            comboColor, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);

        // "COMBO" label
        string label = _displayCombo >= 20 ? "MEGA COMBO!" :
                       _displayCombo >= 10 ? "SUPER COMBO!" :
                       _displayCombo >= 5 ? "COMBO!" : "COMBO";
        spriteBatch.DrawString(_font, label,
            new Vector2(x, y + textSize.Y * scale + 2),
            comboColor * 0.7f, 0f, Vector2.Zero, 0.6f, SpriteEffects.None, 0f);
    }

    // Public effect triggers
    public void FlashCastle()
    {
        _castleFlashTimer = CastleFlashDuration;
    }

    public void SpawnEnemy(int enemyId)
    {
        _spawnAnims[enemyId] = SpawnAnimDuration;
    }

    public void SetCombo(int combo)
    {
        if (combo > _displayCombo)
            _comboPopTimer = ComboPopDuration;
        _displayCombo = combo;
    }

    /// <summary>
    /// Gets the screen position of an enemy by index, for effect spawning.
    /// </summary>
    public Vector2 GetEnemyPosition(int index, int totalEnemies)
    {
        int groundY = _bounds.Bottom - 60;
        int startX = _bounds.Right - 60;
        float xPos = startX - index * EnemySpacing;
        float yPos = groundY - EnemySize - 8;
        return new Vector2(xPos + EnemySize * 0.5f, yPos + EnemySize * 0.5f);
    }

    public Vector2 CastlePosition
    {
        get
        {
            int groundY = _bounds.Bottom - 60;
            return new Vector2(_bounds.X + 40 + CastleWidth * 0.5f, groundY - CastleHeight * 0.5f);
        }
    }

    private static Color GetEnemyColor(string kind) => kind switch
    {
        "scout" => new Color(180, 180, 60),
        "raider" => new Color(50, 200, 50),
        "armored" => new Color(150, 150, 170),
        "swarm" => new Color(220, 160, 40),
        "tank" => new Color(120, 100, 80),
        "berserker" => new Color(200, 60, 60),
        "phantom" => new Color(140, 120, 200),
        "champion" => new Color(180, 160, 60),
        "healer" => new Color(50, 200, 200),
        "elite" => new Color(160, 80, 160),
        "forest_guardian" => new Color(40, 120, 40),
        "stone_golem" => new Color(130, 130, 140),
        "fen_seer" => new Color(60, 120, 100),
        "sunlord" => new Color(220, 180, 40),
        _ => ThemeColors.DamageRed,
    };

    private void DrawRectOutline(SpriteBatch spriteBatch, Rectangle rect, Color color, int thickness)
    {
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.Right - thickness, rect.Y, thickness, rect.Height), color);
    }
}
