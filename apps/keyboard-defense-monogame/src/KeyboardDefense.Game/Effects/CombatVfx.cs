using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Effects;

/// <summary>
/// Combat visual effects: floating damage numbers, hit flash tracking,
/// screen shake on kills, combo announcement triggers.
/// </summary>
public class CombatVfx
{
    private readonly List<FloatingText> _floatingTexts = new();
    private readonly Dictionary<int, float> _hitFlashTimers = new();

    private const float FloatingTextDuration = 1.2f;
    private const float FloatingTextSpeed = 40f; // pixels per second upward
    private const float HitFlashDuration = 0.15f;

    /// <summary>Show a floating damage number at a world position.</summary>
    public void ShowDamage(Vector2 worldPos, int damage, bool isCrit)
    {
        var color = isCrit ? ThemeColors.GoldAccent : ThemeColors.DamageRed;
        string text = isCrit ? $"{damage}!" : damage.ToString();
        float scale = isCrit ? 1.4f : 1.0f;

        _floatingTexts.Add(new FloatingText
        {
            Text = text,
            WorldPos = worldPos + new Vector2(0, -8),
            Color = color,
            Timer = 0f,
            Scale = scale,
        });
    }

    /// <summary>Show a floating text message (e.g., "MISS!", "+5 gold").</summary>
    public void ShowText(Vector2 worldPos, string text, Color color)
    {
        _floatingTexts.Add(new FloatingText
        {
            Text = text,
            WorldPos = worldPos + new Vector2(0, -8),
            Color = color,
            Timer = 0f,
            Scale = 0.8f,
        });
    }

    /// <summary>Register an enemy hit flash by enemy ID.</summary>
    public void FlashEnemy(int enemyId)
    {
        _hitFlashTimers[enemyId] = HitFlashDuration;
    }

    /// <summary>Check if an enemy should render with a white flash overlay.</summary>
    public bool IsFlashing(int enemyId)
    {
        return _hitFlashTimers.TryGetValue(enemyId, out float t) && t > 0;
    }

    /// <summary>Get flash intensity (1.0 = full flash, 0.0 = none).</summary>
    public float GetFlashIntensity(int enemyId)
    {
        if (_hitFlashTimers.TryGetValue(enemyId, out float t) && t > 0)
            return t / HitFlashDuration;
        return 0f;
    }

    /// <summary>Trigger screen shake for a kill. Bigger shake for combo milestones.</summary>
    public void OnEnemyKilled(int comboCount)
    {
        if (comboCount >= 10)
            ScreenShake.Instance.ShakeMedium();
        else if (comboCount >= 5)
            ScreenShake.Instance.ShakeLight();
        else
            ScreenShake.Instance.AddTrauma(0.1f);
    }

    /// <summary>Trigger combo announcement if we hit a milestone.</summary>
    public void CheckComboAnnouncement(int comboCount, UI.Components.ComboAnnouncement comboOverlay)
    {
        if (comboOverlay == null) return;
        if (ComboSystem.IsTierMilestone(comboCount - 1, comboCount))
        {
            string tierName = ComboSystem.GetTierAnnouncement(comboCount);
            comboOverlay.Show(comboCount, $"x{comboCount} {tierName}!");
        }
    }

    public void Update(float deltaTime)
    {
        // Update floating texts
        for (int i = _floatingTexts.Count - 1; i >= 0; i--)
        {
            var ft = _floatingTexts[i];
            ft.Timer += deltaTime;
            ft.WorldPos += new Vector2(0, -FloatingTextSpeed * deltaTime);
            if (ft.Timer >= FloatingTextDuration)
                _floatingTexts.RemoveAt(i);
        }

        // Update hit flash timers
        var expired = new List<int>();
        foreach (var (id, timer) in _hitFlashTimers)
        {
            _hitFlashTimers[id] = timer - deltaTime;
            if (_hitFlashTimers[id] <= 0)
                expired.Add(id);
        }
        foreach (int id in expired)
            _hitFlashTimers.Remove(id);
    }

    /// <summary>Draw all floating texts. Call within a SpriteBatch.Begin with camera transform.</summary>
    public void Draw(SpriteBatch spriteBatch, SpriteFont font)
    {
        foreach (var ft in _floatingTexts)
        {
            float progress = ft.Timer / FloatingTextDuration;
            float alpha = progress > 0.6f ? 1f - (progress - 0.6f) / 0.4f : 1f;

            // Scale pop effect at start
            float scale = ft.Scale;
            if (progress < 0.1f)
                scale *= MathHelper.Lerp(0.5f, 1.2f, progress / 0.1f);
            else if (progress < 0.2f)
                scale *= MathHelper.Lerp(1.2f, 1.0f, (progress - 0.1f) / 0.1f);

            var size = font.MeasureString(ft.Text);
            var origin = size / 2;

            // Shadow
            spriteBatch.DrawString(font, ft.Text,
                ft.WorldPos + new Vector2(1, 1),
                Color.Black * (alpha * 0.5f),
                0f, origin, scale * 0.7f, SpriteEffects.None, 0f);

            // Main text
            spriteBatch.DrawString(font, ft.Text,
                ft.WorldPos,
                ft.Color * alpha,
                0f, origin, scale * 0.7f, SpriteEffects.None, 0f);
        }
    }

    private class FloatingText
    {
        public string Text = "";
        public Vector2 WorldPos;
        public Color Color;
        public float Timer;
        public float Scale;
    }
}
