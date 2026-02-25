using System;
using System.Collections.Generic;
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
    /// <summary>
    /// Snapshot of minimap tile colors and marker positions derived from game state.
    /// </summary>
    public sealed record MinimapData(
        int MapWidth,
        int MapHeight,
        IReadOnlyList<Color> TileColors,
        IReadOnlySet<int> StructureTiles,
        IReadOnlySet<int> EnemyTiles,
        IReadOnlySet<int> NpcTiles,
        GridPoint BasePosition,
        GridPoint PlayerPosition,
        GridPoint CursorPosition)
    {
        /// <summary>
        /// Gets the tile color at the requested world grid coordinate.
        /// Out-of-bounds coordinates return fog color.
        /// </summary>
        public Color GetTileColorAt(int x, int y)
        {
            if (!SimMap.InBounds(x, y, MapWidth, MapHeight))
                return FogTileColor;

            return TileColors[SimMap.Idx(x, y, MapWidth)];
        }
    }

    /// <summary>
    /// Gets or sets the minimap's square size in screen pixels, including the border.
    /// </summary>
    public int MinimapSize { get; set; } = 200;
    /// <summary>
    /// Gets or sets the border thickness in pixels around the minimap content area.
    /// </summary>
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
    private static readonly Color NpcMarker = new(210, 200, 130);
    private static readonly Color ViewportColor = Color.White * 0.4f;

    private Texture2D? _pixel;

    /// <summary>
    /// Gets the color used for plains and unmapped terrain on the minimap.
    /// </summary>
    public static Color PlainsTileColor => PlainColor;
    /// <summary>
    /// Gets the color used for undiscovered minimap tiles.
    /// </summary>
    public static Color FogTileColor => FogColor;

    /// <summary>
    /// Resolves the display color for a terrain id.
    /// </summary>
    public static Color TerrainToColor(string terrain) => terrain switch
    {
        SimMap.TerrainForest => ForestColor,
        SimMap.TerrainMountain => MountainColor,
        SimMap.TerrainWater => WaterColor,
        _ => PlainColor,
    };

    /// <summary>
    /// Allocates renderer resources required for minimap drawing.
    /// </summary>
    /// <param name="device">Graphics device used to create the shared 1x1 white pixel texture.</param>
    /// <remarks>
    /// The created texture is tinted for all minimap primitives. Call this before <see cref="Draw"/>; otherwise draw
    /// calls exit early and render nothing.
    /// </remarks>
    public void Initialize(GraphicsDevice device)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
    }

    /// <summary>
    /// Renders the full minimap overlay at the requested screen position.
    /// </summary>
    /// <param name="spriteBatch">Sprite batch used to draw frame, terrain, markers, and overlays.</param>
    /// <param name="state">Game state supplying map size, discovery set, structures, enemies, and key marker positions.</param>
    /// <param name="screenPos">Top-left screen pixel where the minimap frame begins.</param>
    /// <remarks>
    /// Draw order is frame/background, discovered terrain tiles, structures, enemies, roaming enemies, base marker,
    /// player marker, cursor marker, and optional camera viewport rectangle.
    /// World tile coordinates are projected into minimap coordinates using the inner size
    /// (<c>MinimapSize - BorderWidth * 2</c>) divided by map width and height.
    /// If <see cref="Initialize"/> has not been called, the method returns without drawing.
    /// </remarks>
    public void Draw(SpriteBatch spriteBatch, GameState state, Vector2 screenPos)
    {
        if (_pixel == null) return;

        var data = GenerateData(state);
        int mapW = data.MapWidth;
        int mapH = data.MapHeight;
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

        // Terrain and fog
        for (int y = 0; y < mapH; y++)
        {
            for (int x = 0; x < mapW; x++)
            {
                int idx = SimMap.Idx(x, y, mapW);
                Color color = data.TileColors[idx];

                spriteBatch.Draw(_pixel, new Rectangle(
                    (int)(origin.X + x * tileW),
                    (int)(origin.Y + y * tileH),
                    Math.Max(1, (int)tileW),
                    Math.Max(1, (int)tileH)), color);
            }
        }

        // Structures
        foreach (int index in data.StructureTiles)
        {
            var pos = GridPoint.FromIndex(index, mapW);
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + pos.X * tileW),
                (int)(origin.Y + pos.Y * tileH),
                Math.Max(1, (int)tileW),
                Math.Max(1, (int)tileH)), StructureMarker);
        }

        // Enemies
        foreach (int index in data.EnemyTiles)
        {
            var pos = GridPoint.FromIndex(index, mapW);
            int size = Math.Max(2, (int)(tileW * 1.5f));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + pos.X * tileW),
                (int)(origin.Y + pos.Y * tileH),
                size, size), EnemyMarker);
        }

        // NPCs
        foreach (int index in data.NpcTiles)
        {
            var pos = GridPoint.FromIndex(index, mapW);
            int size = Math.Max(2, (int)(tileW * 1.25f));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + pos.X * tileW),
                (int)(origin.Y + pos.Y * tileH),
                size, size), NpcMarker);
        }

        // Base marker
        {
            int size = Math.Max(3, (int)(tileW * 2));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + data.BasePosition.X * tileW - size / 2),
                (int)(origin.Y + data.BasePosition.Y * tileH - size / 2),
                size, size), BaseMarker);
        }

        // Player marker (distinct from cursor)
        {
            int size = Math.Max(3, (int)(tileW * 2));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + data.PlayerPosition.X * tileW - size / 2),
                (int)(origin.Y + data.PlayerPosition.Y * tileH - size / 2),
                size, size), PlayerMarker);
        }

        // Cursor marker
        {
            int size = Math.Max(2, (int)(tileW * 1.5f));
            spriteBatch.Draw(_pixel, new Rectangle(
                (int)(origin.X + data.CursorPosition.X * tileW - size / 2),
                (int)(origin.Y + data.CursorPosition.Y * tileH - size / 2),
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

    /// <summary>
    /// Generates minimap tile and marker data from state without requiring graphics resources.
    /// </summary>
    public static MinimapData GenerateData(GameState state)
    {
        int mapW = Math.Max(1, state.MapW);
        int mapH = Math.Max(1, state.MapH);
        int totalTiles = mapW * mapH;

        var tileColors = new Color[totalTiles];
        for (int y = 0; y < mapH; y++)
        {
            for (int x = 0; x < mapW; x++)
            {
                int index = SimMap.Idx(x, y, mapW);
                if (state.Discovered.Contains(index))
                {
                    string terrain = SimMap.GetTerrain(state, new GridPoint(x, y));
                    tileColors[index] = TerrainToColor(terrain);
                }
                else
                {
                    tileColors[index] = FogColor;
                }
            }
        }

        var structureTiles = new HashSet<int>();
        foreach (var (index, _) in state.Structures)
        {
            if (index >= 0 && index < totalTiles)
                structureTiles.Add(index);
        }

        var enemyTiles = new HashSet<int>();
        if (string.Equals(state.Phase, "night", StringComparison.OrdinalIgnoreCase))
        {
            AddEntityTiles(state.Enemies, enemyTiles, mapW, mapH, state.Discovered, requireDiscovered: false);
            AddEntityTiles(state.RoamingEnemies, enemyTiles, mapW, mapH, state.Discovered, requireDiscovered: true);
        }

        var npcTiles = new HashSet<int>();
        AddEntityTiles(state.Npcs, npcTiles, mapW, mapH, state.Discovered, requireDiscovered: true);

        return new MinimapData(
            mapW,
            mapH,
            tileColors,
            structureTiles,
            enemyTiles,
            npcTiles,
            state.BasePos,
            state.PlayerPos,
            state.CursorPos);
    }

    private static void AddEntityTiles(
        IEnumerable<Dictionary<string, object>> entities,
        HashSet<int> result,
        int mapW,
        int mapH,
        HashSet<int> discovered,
        bool requireDiscovered)
    {
        foreach (var entity in entities)
        {
            if (!TryGetEntityPosition(entity, out GridPoint pos)) continue;
            if (!SimMap.InBounds(pos.X, pos.Y, mapW, mapH)) continue;

            int index = SimMap.Idx(pos.X, pos.Y, mapW);
            if (requireDiscovered && !discovered.Contains(index)) continue;
            result.Add(index);
        }
    }

    private static bool TryGetEntityPosition(Dictionary<string, object> entity, out GridPoint pos)
    {
        if (entity.GetValueOrDefault("pos") is GridPoint gridPoint)
        {
            pos = gridPoint;
            return true;
        }

        if (entity.TryGetValue("x", out var xObj) && entity.TryGetValue("y", out var yObj))
        {
            pos = new GridPoint(Convert.ToInt32(xObj), Convert.ToInt32(yObj));
            return true;
        }

        pos = default;
        return false;
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
