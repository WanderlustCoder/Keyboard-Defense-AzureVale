using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Renders a minimap overview of the game world.
/// Ported from game/minimap_renderer.gd (325 lines).
/// </summary>
public class MinimapRenderer
{
    public int MinimapSize { get; set; } = 200;
    public int BorderWidth { get; set; } = 2;

    /// <summary>Visible tile range from camera, used to draw a viewport indicator.</summary>
    public (int minX, int minY, int maxX, int maxY)? ViewportRange { get; set; }

    private static readonly Color OuterFrame = new(25, 22, 40);
    private static readonly Color BronzeAccent = new(80, 70, 50);
    private static readonly Color BgColor = new(15, 15, 25);
    private static readonly Color PlainColor = new(90, 130, 65);
    private static readonly Color ForestColor = new(45, 90, 40);
    private static readonly Color MountainColor = new(130, 110, 90);
    private static readonly Color WaterColor = new(50, 90, 150);
    private static readonly Color FogColor = new(25, 25, 35);
    private static readonly Color BaseMarker = ThemeColors.GoldAccent;
    private static readonly Color CursorMarker = ThemeColors.Cyan;
    private static readonly Color PlayerMarker = new(80, 160, 255);
    private static readonly Color EnemyMarker = ThemeColors.DamageRed;
    private static readonly Color StructureMarker = new(160, 140, 100);
    private static readonly Color ViewportColor = Color.White * 0.4f;

    private Texture2D? _pixel;

    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    public void Draw(SpriteBatch spriteBatch, GameState state, Vector2 screenPos)
    {
        if (_pixel == null) return;

        int mapW = state.MapW;
        int mapH = state.MapH;
        int inner = MinimapSize - BorderWidth * 2;
        float tileW = (float)inner / mapW;
        float tileH = (float)inner / mapH;
        var origin = screenPos + new Vector2(BorderWidth, BorderWidth);

        // 3-layer border frame: outer dark → bronze accent → inner bg
        spriteBatch.Draw(_pixel, new Rectangle(
            (int)screenPos.X, (int)screenPos.Y, MinimapSize, MinimapSize), OuterFrame);
        spriteBatch.Draw(_pixel, new Rectangle(
            (int)screenPos.X + 1, (int)screenPos.Y + 1,
            MinimapSize - 2, MinimapSize - 2), BronzeAccent);
        spriteBatch.Draw(_pixel, new Rectangle(
            (int)screenPos.X + BorderWidth, (int)screenPos.Y + BorderWidth,
            inner, inner), BgColor);

        // Terrain
        foreach (int tileIdx in state.Discovered)
        {
            var pos = GridPoint.FromIndex(tileIdx, mapW);
            string terrain = SimMap.GetTerrain(state, pos);
            Color color = terrain switch
            {
                SimMap.TerrainForest => ForestColor,
                SimMap.TerrainMountain => MountainColor,
                SimMap.TerrainWater => WaterColor,
                _ => PlainColor,
            };

            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + pos.X * tileW),
                (int)(origin.Y + pos.Y * tileH),
                Math.Max(1, (int)tileW),
                Math.Max(1, (int)tileH)), color);
        }

        // Structures
        foreach (var (index, _) in state.Structures)
        {
            var pos = GridPoint.FromIndex(index, mapW);
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + pos.X * tileW),
                (int)(origin.Y + pos.Y * tileH),
                Math.Max(1, (int)tileW),
                Math.Max(1, (int)tileH)), StructureMarker);
        }

        // Enemies
        foreach (var enemy in state.Enemies)
        {
            if (enemy.TryGetValue("x", out var ex) && enemy.TryGetValue("y", out var ey))
            {
                int x = Convert.ToInt32(ex);
                int y = Convert.ToInt32(ey);
                int size = Math.Max(2, (int)(tileW * 1.5f));
                spriteBatch.Draw(_pixel, new Rectangle(
                    (int)(origin.X + x * tileW),
                    (int)(origin.Y + y * tileH),
                    size, size), EnemyMarker);
            }
        }

        // Roaming enemies (only show on discovered tiles)
        foreach (var roamer in state.RoamingEnemies)
        {
            if (roamer.TryGetValue("pos", out var rpos) && rpos is GridPoint rp && state.Discovered.Contains(SimMap.Idx(rp.X, rp.Y, mapW)))
            {
                int size = Math.Max(2, (int)(tileW * 1.5f));
                spriteBatch.Draw(_pixel, new Rectangle(
                    (int)(origin.X + rp.X * tileW),
                    (int)(origin.Y + rp.Y * tileH),
                    size, size), EnemyMarker);
            }
        }

        // Base marker
        {
            int size = Math.Max(3, (int)(tileW * 2));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + state.BasePos.X * tileW - size / 2),
                (int)(origin.Y + state.BasePos.Y * tileH - size / 2),
                size, size), BaseMarker);
        }

        // Player marker (distinct from cursor)
        {
            int size = Math.Max(3, (int)(tileW * 2));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + state.PlayerPos.X * tileW - size / 2),
                (int)(origin.Y + state.PlayerPos.Y * tileH - size / 2),
                size, size), PlayerMarker);
        }

        // Cursor marker
        {
            int size = Math.Max(2, (int)(tileW * 1.5f));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + state.CursorPos.X * tileW - size / 2),
                (int)(origin.Y + state.CursorPos.Y * tileH - size / 2),
                size, size), CursorMarker);
        }

        // Viewport indicator — white semi-transparent rectangle showing camera view
        if (ViewportRange is var (vMinX, vMinY, vMaxX, vMaxY))
        {
            int rx = (int)(origin.X + vMinX * tileW);
            int ry = (int)(origin.Y + vMinY * tileH);
            int rw = Math.Max(1, (int)((vMaxX - vMinX) * tileW));
            int rh = Math.Max(1, (int)((vMaxY - vMinY) * tileH));
            var vpRect = new Rectangle(rx, ry, rw, rh);
            DrawRectBorder(spriteBatch, vpRect, ViewportColor, 1);
        }
    }

    private void DrawRectBorder(SpriteBatch sb, Rectangle rect, Color color, int thickness)
    {
        if (_pixel == null) return;
        sb.Draw(_pixel, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        sb.Draw(_pixel, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        sb.Draw(_pixel, new Rectangle(rect.X, rect.Y + thickness, thickness, rect.Height - thickness * 2), color);
        sb.Draw(_pixel, new Rectangle(rect.Right - thickness, rect.Y + thickness, thickness, rect.Height - thickness * 2), color);
    }
}
