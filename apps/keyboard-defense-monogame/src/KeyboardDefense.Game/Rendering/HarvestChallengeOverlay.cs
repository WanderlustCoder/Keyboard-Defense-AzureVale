using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Centered overlay during harvest_challenge mode.
/// Shows node name, challenge word with per-char coloring, and cancel hint.
/// </summary>
public class HarvestChallengeOverlay
{
    private Texture2D? _pixel;
    private SpriteFont? _font;

    private string _word = "";
    private string _nodeName = "";
    private string _resource = "";
    private bool _visible;

    // Animation
    private readonly TweenValue _slideAnim = new(0f);
    private readonly TweenValue _fadeAnim = new(0f);

    private const int PanelWidth = 400;
    private const int PanelHeight = 160;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public void Show(string word, string nodeName, string resource)
    {
        _word = word;
        _nodeName = nodeName;
        _resource = resource;
        _visible = true;
        _slideAnim.Start(40f, 0f, DesignSystem.AnimNormal, Transitions.EaseOutBack);
        _fadeAnim.Start(0f, 1f, DesignSystem.AnimNormal, Transitions.EaseOut);
    }

    public void Hide()
    {
        _visible = false;
        _slideAnim.Cancel();
        _fadeAnim.Cancel();
    }

    public void Update(float deltaTime)
    {
        _slideAnim.Update(deltaTime);
        _fadeAnim.Update(deltaTime);
    }

    /// <summary>
    /// Draw the harvest challenge overlay. Call in screen space (no camera transform).
    /// </summary>
    public void Draw(SpriteBatch spriteBatch, string currentInput, int screenWidth, int screenHeight)
    {
        if (!_visible || _pixel == null || _font == null) return;

        float opacity = _fadeAnim.IsComplete ? 1f : _fadeAnim.Value;
        float slideY = _slideAnim.IsComplete ? 0f : _slideAnim.Value;

        int panelX = (screenWidth - PanelWidth) / 2;
        int panelY = (screenHeight - PanelHeight) / 2 + (int)slideY;

        // Panel background
        spriteBatch.Draw(_pixel, new Rectangle(panelX, panelY, PanelWidth, PanelHeight),
            Color.Black * (0.85f * opacity));

        // Border
        DrawBorder(spriteBatch, new Rectangle(panelX, panelY, PanelWidth, PanelHeight),
            ThemeColors.GetResourceColor(_resource) * opacity, 2);

        // Node name header
        string header = $"Harvesting: {_nodeName}";
        var headerSize = _font.MeasureString(header);
        float headerScale = 0.6f;
        spriteBatch.DrawString(_font, header,
            new Vector2(panelX + (PanelWidth - headerSize.X * headerScale) / 2, panelY + 12),
            ThemeColors.GoldAccent * opacity,
            0f, Vector2.Zero, headerScale, SpriteEffects.None, 0f);

        // Challenge word with per-character coloring
        string input = (currentInput ?? "").ToLowerInvariant();
        string word = _word.ToLowerInvariant();
        float charX = panelX + (PanelWidth - _font.MeasureString(_word).X * 0.9f) / 2;
        float charY = panelY + 50;

        for (int i = 0; i < _word.Length; i++)
        {
            Color charColor;
            if (i < input.Length)
            {
                charColor = (i < word.Length && input[i] == word[i])
                    ? ThemeColors.TypedCorrect
                    : ThemeColors.TypedError;
            }
            else
            {
                charColor = ThemeColors.Text;
            }

            string ch = _word[i].ToString();
            spriteBatch.DrawString(_font, ch,
                new Vector2(charX, charY), charColor * opacity,
                0f, Vector2.Zero, 0.9f, SpriteEffects.None, 0f);
            charX += _font.MeasureString(ch).X * 0.9f;
        }

        // Resource type indicator
        Color resColor = ThemeColors.GetResourceColor(_resource);
        string resText = _resource.ToUpperInvariant();
        var resSize = _font.MeasureString(resText);
        spriteBatch.DrawString(_font, resText,
            new Vector2(panelX + (PanelWidth - resSize.X * 0.4f) / 2, panelY + 90),
            resColor * (opacity * 0.7f),
            0f, Vector2.Zero, 0.4f, SpriteEffects.None, 0f);

        // Cancel hint
        string hint = "Press Escape to cancel";
        var hintSize = _font.MeasureString(hint);
        spriteBatch.DrawString(_font, hint,
            new Vector2(panelX + (PanelWidth - hintSize.X * 0.4f) / 2, panelY + PanelHeight - 30),
            ThemeColors.TextDim * opacity,
            0f, Vector2.Zero, 0.4f, SpriteEffects.None, 0f);
    }

    private void DrawBorder(SpriteBatch spriteBatch, Rectangle rect, Color color, int thickness)
    {
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.Right - thickness, rect.Y, thickness, rect.Height), color);
    }
}
