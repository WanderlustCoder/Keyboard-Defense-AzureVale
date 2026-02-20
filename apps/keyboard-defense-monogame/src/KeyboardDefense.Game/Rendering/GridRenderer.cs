using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Services;
using KeyboardDefense.Game.UI;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Renders the game grid: terrain, structures, enemies, fog of war, cursor.
/// Simplified port of game/grid_renderer.gd (38K+ lines - core rendering only).
/// </summary>
public class GridRenderer
{
    public int CellSize { get; set; } = 48;
    public Vector2 Origin { get; set; } = Vector2.Zero;

    private Texture2D? _pixel;
    private SpriteFont? _font;
    private float _totalTime;

    // Per-entity animation states
    private readonly Dictionary<int, SpriteAnimator.AnimationState> _buildingAnimStates = new();
    private readonly Dictionary<int, SpriteAnimator.AnimationState> _enemyAnimStates = new();

    // Terrain colors
    private static readonly Color PlainColor = new(90, 130, 65);
    private static readonly Color ForestColor = new(45, 90, 40);
    private static readonly Color MountainColor = new(130, 110, 90);
    private static readonly Color WaterColor = new(50, 90, 150);
    private static readonly Color FogColor = new(20, 20, 30);

    // Entity colors
    private static readonly Color BaseColor = ThemeColors.GoldAccent;
    private static readonly Color CursorColor = ThemeColors.Cyan;
    private static readonly Color StructureColor = new(160, 140, 100);
    private static readonly Color TowerColor = ThemeColors.ShieldBlue;
    private static readonly Color EnemyColor = ThemeColors.DamageRed;

    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, 1, 1);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    /// <summary>Update animation states. Call once per frame before Draw.</summary>
    public void Update(float deltaTime)
    {
        _totalTime += deltaTime;
        foreach (var (_, animState) in _buildingAnimStates)
            animState.Update(deltaTime, _totalTime);
        foreach (var (_, animState) in _enemyAnimStates)
            animState.Update(deltaTime, _totalTime);
    }

    public void Draw(SpriteBatch spriteBatch, GameState state, Matrix cameraTransform, Rectangle viewport)
    {
        if (_pixel == null) return;

        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            samplerState: SamplerState.PointClamp,
            blendState: BlendState.AlphaBlend);

        // Draw terrain for discovered tiles
        foreach (int tileIdx in state.Discovered)
        {
            var pos = GridPoint.FromIndex(tileIdx, state.MapW);
            DrawTerrain(spriteBatch, state, pos);
        }

        // Draw structures
        foreach (var (index, structureType) in state.Structures)
        {
            var pos = GridPoint.FromIndex(index, state.MapW);
            DrawStructure(spriteBatch, pos, structureType, state.StructureLevels.GetValueOrDefault(index, 1));
        }

        // Draw base
        DrawBase(spriteBatch, state.BasePos);

        // Draw enemies
        foreach (var enemy in state.Enemies)
        {
            DrawEnemy(spriteBatch, enemy);
        }

        // Draw cursor
        DrawCursor(spriteBatch, state.CursorPos);

        // Draw fog for undiscovered adjacent tiles
        DrawFog(spriteBatch, state);

        spriteBatch.End();
    }

    private void DrawTerrain(SpriteBatch spriteBatch, GameState state, GridPoint pos)
    {
        string terrain = SimMap.GetTerrain(state, pos);
        Color color = terrain switch
        {
            SimMap.TerrainForest => ForestColor,
            SimMap.TerrainMountain => MountainColor,
            SimMap.TerrainWater => WaterColor,
            _ => PlainColor,
        };

        var rect = TileRect(pos);

        // Try sprite texture, fall back to colored rectangle
        string tileId = terrain switch
        {
            SimMap.TerrainForest => "forest",
            SimMap.TerrainMountain => "mountain",
            SimMap.TerrainWater => "water",
            _ => "plain",
        };
        var texture = AssetLoader.Instance.GetTileTexture(tileId);
        if (texture != null)
            spriteBatch.Draw(texture, rect, Color.White);
        else
            spriteBatch.Draw(_pixel!, rect, color);

        // Grid line
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, 1), Color.Black * 0.15f);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, 1, rect.Height), Color.Black * 0.15f);
    }

    private void DrawStructure(SpriteBatch spriteBatch, GridPoint pos, string type, int level)
    {
        var rect = TileRect(pos);
        int inset = CellSize / 6;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        // Try animated sprite via SpriteAnimator
        int structKey = pos.Y * 1000 + pos.X; // Stable key from grid position
        AssetLoader.Instance.RegisterBuildingSprite(type);
        string spriteId = $"bld_{type}";
        var sheet = AssetLoader.Instance.Animator.GetSheet(spriteId);

        if (sheet?.Texture != null)
        {
            if (!_buildingAnimStates.TryGetValue(structKey, out var animState))
            {
                animState = SpriteAnimator.CreateState();
                animState.EnablePulse(speed: 1.5f, amplitude: 0.02f);
                var idle = sheet.GetClip("idle");
                if (idle != null) animState.Play(idle);
                _buildingAnimStates[structKey] = animState;
            }
            AssetLoader.Instance.Animator.Draw(spriteBatch, spriteId, animState, inner, Color.White);
        }
        else
        {
            Color color = type.StartsWith("auto_") ? TowerColor : StructureColor;
            spriteBatch.Draw(_pixel!, inner, color);
        }

        // Level indicator
        if (level > 1 && _font != null)
        {
            string lvl = level.ToString();
            var size = _font.MeasureString(lvl);
            spriteBatch.DrawString(_font, lvl,
                new Vector2(rect.X + (rect.Width - size.X) * 0.5f, rect.Y + 2),
                Color.White, 0f, Vector2.Zero, 0.6f, SpriteEffects.None, 0f);
        }
    }

    private void DrawBase(SpriteBatch spriteBatch, GridPoint pos)
    {
        var rect = TileRect(pos);
        int inset = CellSize / 8;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);
        spriteBatch.Draw(_pixel!, inner, BaseColor);

        // Base outline
        DrawRectOutline(spriteBatch, inner, ThemeColors.GoldBright, 2);
    }

    private void DrawEnemy(SpriteBatch spriteBatch, Dictionary<string, object> enemy)
    {
        if (!enemy.TryGetValue("pos", out var posObj)) return;

        int x, y;
        if (posObj is GridPoint gp)
        {
            x = gp.X; y = gp.Y;
        }
        else if (enemy.TryGetValue("x", out var ex) && enemy.TryGetValue("y", out var ey))
        {
            x = Convert.ToInt32(ex);
            y = Convert.ToInt32(ey);
        }
        else return;

        var rect = TileRect(new GridPoint(x, y));
        int inset = CellSize / 4;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";
        Color color = kind switch
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
            _ => EnemyColor,
        };

        // Try animated sprite via SpriteAnimator
        int enemyId = 0;
        if (enemy.TryGetValue("id", out var idObj2))
            enemyId = Convert.ToInt32(idObj2);

        AssetLoader.Instance.RegisterEnemySprite(kind);
        string spriteId = $"enemy_{kind}";
        var sheet = AssetLoader.Instance.Animator.GetSheet(spriteId);

        if (sheet?.Texture != null)
        {
            if (!_enemyAnimStates.TryGetValue(enemyId, out var animState))
            {
                animState = SpriteAnimator.CreateState();
                animState.EnableBob(speed: 2f, amplitude: 2f, phase: enemyId * 0.5f);
                var idle = sheet.GetClip("idle");
                if (idle != null) animState.Play(idle);
                _enemyAnimStates[enemyId] = animState;
            }
            AssetLoader.Instance.Animator.Draw(spriteBatch, spriteId, animState, inner, Color.White);
        }
        else
        {
            spriteBatch.Draw(_pixel!, inner, color);
        }

        // Word label
        if (_font != null && enemy.TryGetValue("word", out var wordObj))
        {
            string word = wordObj?.ToString() ?? "";
            if (!string.IsNullOrEmpty(word))
            {
                var size = _font.MeasureString(word);
                float scale = Math.Min(1f, (float)(CellSize - 4) / size.X);
                spriteBatch.DrawString(_font, word,
                    new Vector2(rect.X + (rect.Width - size.X * scale) * 0.5f, rect.Y + rect.Height + 2),
                    Color.White, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            }
        }
    }

    private void DrawCursor(SpriteBatch spriteBatch, GridPoint pos)
    {
        var rect = TileRect(pos);
        DrawRectOutline(spriteBatch, rect, CursorColor, 3);
    }

    private void DrawFog(SpriteBatch spriteBatch, GameState state)
    {
        // Draw dark tiles for undiscovered area around discovered tiles
        int[] offsets = { -1, 1, -state.MapW, state.MapW };
        var fogTiles = new HashSet<int>();

        foreach (int discovered in state.Discovered)
        {
            foreach (int offset in offsets)
            {
                int neighbor = discovered + offset;
                if (neighbor >= 0 && neighbor < state.MapW * state.MapH && !state.Discovered.Contains(neighbor))
                    fogTiles.Add(neighbor);
            }
        }

        foreach (int tileIdx in fogTiles)
        {
            var pos = GridPoint.FromIndex(tileIdx, state.MapW);
            var rect = TileRect(pos);
            spriteBatch.Draw(_pixel!, rect, FogColor * 0.7f);
        }
    }

    public Vector2 TileCenter(GridPoint pos)
    {
        return new Vector2(
            Origin.X + pos.X * CellSize + CellSize * 0.5f,
            Origin.Y + pos.Y * CellSize + CellSize * 0.5f);
    }

    private Rectangle TileRect(GridPoint pos)
    {
        return new Rectangle(
            (int)Origin.X + pos.X * CellSize,
            (int)Origin.Y + pos.Y * CellSize,
            CellSize, CellSize);
    }

    private void DrawRectOutline(SpriteBatch spriteBatch, Rectangle rect, Color color, int thickness)
    {
        // Top
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, thickness), color);
        // Bottom
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Bottom - thickness, rect.Width, thickness), color);
        // Left
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, thickness, rect.Height), color);
        // Right
        spriteBatch.Draw(_pixel!, new Rectangle(rect.Right - thickness, rect.Y, thickness, rect.Height), color);
    }
}
