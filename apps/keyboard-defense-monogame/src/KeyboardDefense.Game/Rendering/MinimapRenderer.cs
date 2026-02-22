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

    private static readonly Color BorderColor = new(60, 60, 80);
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
        float tileW = (float)(MinimapSize - BorderWidth * 2) / mapW;
        float tileH = (float)(MinimapSize - BorderWidth * 2) / mapH;
        var origin = screenPos + new Vector2(BorderWidth, BorderWidth);

        // Background + border
        spriteBatch.Draw(_pixel, new Rectangle(
            (int)screenPos.X, (int)screenPos.Y, MinimapSize, MinimapSize), BorderColor);
        spriteBatch.Draw(_pixel, new Rectangle(
            (int)screenPos.X + BorderWidth, (int)screenPos.Y + BorderWidth,
            MinimapSize - BorderWidth * 2, MinimapSize - BorderWidth * 2), BgColor);

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
    }
}
