using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Visual tint overlay based on time of day (0.0-1.0).
/// Night: dark blue. Dawn/dusk: warm gradients. Day: clear.
/// </summary>
public class DayNightOverlay
{
    private Texture2D? _pixel;

    // Time thresholds (matching WorldScreen.GetTimeOfDayName)
    private const float NightEnd = 0.15f;
    private const float DawnEnd = 0.30f;
    private const float DayEnd = 0.70f;
    private const float DuskEnd = 0.85f;

    // Overlay colors at full intensity
    private static readonly Color NightColor = new(10, 15, 40, 120);
    private static readonly Color DawnColor = new(80, 50, 20, 40);
    private static readonly Color DuskColor = new(70, 40, 25, 50);
    private static readonly Color DayColor = Color.Transparent;

    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    /// <summary>
    /// Draw the day/night overlay on top of the world.
    /// Call after all world rendering, before UI.
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, float timeOfDay, int viewportWidth, int viewportHeight)
    {
        if (_pixel == null) return;

        var tint = GetOverlayColor(timeOfDay);
        if (tint.A == 0) return; // fully transparent during day

        spriteBatch.Begin(blendState: BlendState.AlphaBlend);
        spriteBatch.Draw(_pixel, new Rectangle(0, 0, viewportWidth, viewportHeight), tint);
        spriteBatch.End();
    }

    private static Color GetOverlayColor(float t)
    {
        // Wrap to 0-1
        t = t - MathF.Floor(t);

        if (t < NightEnd)
        {
            // Deep night → approaching dawn
            float progress = t / NightEnd;
            return Color.Lerp(NightColor, DawnColor, progress);
        }
        if (t < DawnEnd)
        {
            // Dawn → day
            float progress = (t - NightEnd) / (DawnEnd - NightEnd);
            return Color.Lerp(DawnColor, DayColor, progress);
        }
        if (t < DayEnd)
        {
            // Full daylight
            return DayColor;
        }
        if (t < DuskEnd)
        {
            // Day → dusk
            float progress = (t - DayEnd) / (DuskEnd - DayEnd);
            return Color.Lerp(DayColor, DuskColor, progress);
        }

        // Dusk → night
        float nightProgress = (t - DuskEnd) / (1f - DuskEnd);
        return Color.Lerp(DuskColor, NightColor, nightProgress);
    }
}
