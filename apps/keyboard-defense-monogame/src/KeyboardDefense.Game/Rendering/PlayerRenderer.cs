using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Game.Services;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Draws the player avatar at the current PlayerPos.
/// 4-directional facing with idle/walk states.
/// Falls back to colored rectangle until Pixel Lab avatar is generated.
/// </summary>
public class PlayerRenderer
{
    private Texture2D? _pixel;
    private SpriteFont? _font;
    private SpriteAnimator.AnimationState? _animState;

    private static readonly Color PlayerColor = new(80, 160, 255);
    private static readonly Color PlayerOutline = new(40, 100, 200);

    public int CellSize { get; set; } = 48;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    public void Draw(SpriteBatch spriteBatch, int tileX, int tileY, string facing)
    {
        if (_pixel == null) return;

        var rect = new Rectangle(tileX * CellSize, tileY * CellSize, CellSize, CellSize);
        int inset = CellSize / 6;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        // Try animated sprite via SpriteAnimator
        string spriteId = "player_avatar";
        var sheet = AssetLoader.Instance.Animator.GetSheet(spriteId);
        if (sheet?.Texture != null)
        {
            if (_animState == null)
            {
                _animState = SpriteAnimator.CreateState();
                _animState.EnableBob(speed: 2.5f, amplitude: 1.5f, phase: 0f);
                var idle = sheet.GetClip("idle");
                if (idle != null) _animState.Play(idle);
            }
            AssetLoader.Instance.Animator.Draw(spriteBatch, spriteId, _animState, inner, Color.White);
        }
        else
        {
            // Fallback: colored rectangle with facing indicator
            spriteBatch.Draw(_pixel, inner, PlayerColor);
            DrawOutline(spriteBatch, inner, PlayerOutline, 2);
            DrawFacingIndicator(spriteBatch, inner, facing);
        }
    }

    public void Update(float deltaTime)
    {
        _animState?.Update(deltaTime, 0f);
    }

    private void DrawFacingIndicator(SpriteBatch spriteBatch, Rectangle rect, string facing)
    {
        if (_pixel == null) return;

        int size = 6;
        var indicatorRect = facing switch
        {
            "up" => new Rectangle(rect.X + rect.Width / 2 - size / 2, rect.Y - 2, size, size),
            "down" => new Rectangle(rect.X + rect.Width / 2 - size / 2, rect.Bottom - size + 2, size, size),
            "left" => new Rectangle(rect.X - 2, rect.Y + rect.Height / 2 - size / 2, size, size),
            "right" => new Rectangle(rect.Right - size + 2, rect.Y + rect.Height / 2 - size / 2, size, size),
            _ => new Rectangle(rect.X + rect.Width / 2 - size / 2, rect.Bottom - size + 2, size, size),
        };

        spriteBatch.Draw(_pixel, indicatorRect, Color.White);
    }

    private void DrawOutline(SpriteBatch spriteBatch, Rectangle rect, Color color, int thickness)
    {
        if (_pixel == null) return;
        spriteBatch.Draw(_pixel, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        spriteBatch.Draw(_pixel, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        spriteBatch.Draw(_pixel, new Rectangle(rect.Right - thickness, rect.Y, thickness, rect.Height), color);
    }
}
