using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using KeyboardDefense.Game.Effects;
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

    /// <summary>When true, skip per-tile terrain drawing (chunk background provides it).</summary>
    public bool UseChunkBackground { get; set; }

    /// <summary>Set from camera each frame for chunk-aware fog culling.</summary>
    public (int minX, int minY, int maxX, int maxY) VisibleRange { get; set; }

    private Texture2D? _pixel;
    private SpriteFont? _font;
    private float _totalTime;

    // Per-entity animation states
    private readonly Dictionary<int, SpriteAnimator.AnimationState> _buildingAnimStates = new();
    private readonly Dictionary<int, SpriteAnimator.AnimationState> _enemyAnimStates = new();

    public CombatVfx? Vfx { get; set; }

    // Terrain colors
    private static readonly Color PlainColor = new(90, 130, 65);
    private static readonly Color ForestColor = new(45, 90, 40);
    private static readonly Color MountainColor = new(130, 110, 90);
    private static readonly Color WaterColor = new(50, 90, 150);
    private static readonly Color DesertColor = new(190, 170, 110);
    private static readonly Color SnowColor = new(200, 210, 230);
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

        // Draw terrain for discovered tiles (skip when chunk background is used)
        if (!UseChunkBackground)
        {
            foreach (int tileIdx in state.Discovered)
            {
                var pos = GridPoint.FromIndex(tileIdx, state.MapW);
                DrawTerrain(spriteBatch, state, pos);
            }
        }

        // Draw structures
        foreach (var (index, structureType) in state.Structures)
        {
            var pos = GridPoint.FromIndex(index, state.MapW);
            DrawStructure(spriteBatch, pos, structureType, state.StructureLevels.GetValueOrDefault(index, 1));
        }

        // Draw resource nodes
        foreach (var (nodeIdx, nodeData) in state.ResourceNodes)
        {
            var pos = GridPoint.FromIndex(nodeIdx, state.MapW);
            if (state.Discovered.Contains(nodeIdx))
                DrawResourceNode(spriteBatch, pos, nodeData);
        }

        // Draw POI landmarks
        foreach (var (poiId, poiData) in state.ActivePois)
        {
            DrawPoiLandmark(spriteBatch, poiId, poiData);
        }

        // Draw NPCs
        foreach (var npc in state.Npcs)
        {
            DrawNpc(spriteBatch, npc);
        }

        // Draw roaming enemies
        foreach (var enemy in state.RoamingEnemies)
        {
            DrawRoamingEnemy(spriteBatch, enemy);
        }

        // Draw encounter enemies (with words)
        foreach (var enemy in state.EncounterEnemies)
        {
            DrawEnemy(spriteBatch, enemy);
        }

        // Draw base
        DrawBase(spriteBatch, state.BasePos);

        // Draw enemies (campaign/battle mode)
        foreach (var enemy in state.Enemies)
        {
            DrawEnemy(spriteBatch, enemy);
        }

        // Draw interaction prompts near entities
        if (state.ActivityMode == "exploration")
            DrawInteractionPrompts(spriteBatch, state);

        // Draw cursor
        DrawCursor(spriteBatch, state.CursorPos);

        // Draw fog
        if (UseChunkBackground)
            DrawChunkFog(spriteBatch, state);
        else
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
            SimMap.TerrainDesert => DesertColor,
            SimMap.TerrainSnow => SnowColor,
            _ => PlainColor,
        };

        var rect = TileRect(pos);

        // Use wang_0 (full base terrain tile) from each biome's tileset for detailed art
        bool drewTileset = TilesetManager.Instance.DrawTile(spriteBatch, terrain, 15, rect);

        if (!drewTileset)
        {
            // Try sprite texture, fall back to colored rectangle
            string tileId = terrain switch
            {
                SimMap.TerrainForest => "forest",
                SimMap.TerrainMountain => "mountain",
                SimMap.TerrainWater => "water",
                SimMap.TerrainDesert => "desert",
                SimMap.TerrainSnow => "snow",
                _ => "plain",
            };
            var texture = AssetLoader.Instance.GetTileTexture(tileId);
            if (texture != null)
                spriteBatch.Draw(texture, rect, Color.White);
            else
                spriteBatch.Draw(_pixel!, rect, color);
        }

        // Edge transitions: darken edges where biome changes
        var transitions = AutoTileResolver.GetEdgeTransitions(state, pos);
        foreach (var edge in transitions)
        {
            Color edgeColor = GetTransitionColor(terrain, edge.NeighborTerrain);
            int edgeThickness = Math.Max(2, CellSize / 8);

            Rectangle edgeRect = edge.Direction switch
            {
                AutoTileResolver.North => new Rectangle(rect.X, rect.Y, rect.Width, edgeThickness),
                AutoTileResolver.East => new Rectangle(rect.Right - edgeThickness, rect.Y, edgeThickness, rect.Height),
                AutoTileResolver.South => new Rectangle(rect.X, rect.Bottom - edgeThickness, rect.Width, edgeThickness),
                AutoTileResolver.West => new Rectangle(rect.X, rect.Y, edgeThickness, rect.Height),
                _ => Rectangle.Empty,
            };

            if (edgeRect != Rectangle.Empty)
                spriteBatch.Draw(_pixel!, edgeRect, edgeColor);
        }

        // Grid line
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, rect.Width, 1), Color.Black * 0.15f);
        spriteBatch.Draw(_pixel!, new Rectangle(rect.X, rect.Y, 1, rect.Height), Color.Black * 0.15f);

        // Decorative map objects (deterministic scatter based on position hash)
        DrawDecorations(spriteBatch, pos, terrain, rect);
    }

    private void DrawDecorations(SpriteBatch spriteBatch, GridPoint pos, string terrain, Rectangle rect)
    {
        // Deterministic hash for scatter placement (no RNG needed)
        int hash = (pos.X * 7919 + pos.Y * 7907) & 0x7FFFFFFF;
        int chance = hash % 100;

        string? textureName = null;
        int variant = hash / 100 % 4;
        if (terrain == SimMap.TerrainForest && chance < 30)
            textureName = variant switch { 0 => "tree", 1 => "pine", 2 => "tree", _ => "reeds2" };
        else if (terrain == SimMap.TerrainPlains && chance < 15)
            textureName = variant switch { 0 => "reeds", 1 => "signpost", 2 => "well", _ => "reeds" };
        else if (terrain == SimMap.TerrainMountain && chance < 18)
            textureName = variant switch { 0 => "rock", 1 => "mine", 2 => "rock", _ => "campfire" };
        else if (terrain == SimMap.TerrainDesert && chance < 14)
            textureName = variant switch { 0 => "rock", 1 => "campfire", 2 => "signpost", _ => "rock" };
        else if (terrain == SimMap.TerrainSnow && chance < 12)
            textureName = variant switch { 0 => "rock", 1 => "pine", 2 => "campfire", _ => "shrine" };
        else if (terrain == SimMap.TerrainWater && chance < 5)
            textureName = "bridge";

        if (textureName == null) return;

        var texture = AssetLoader.Instance.GetTexture(textureName);
        if (texture == null) return;

        // Place at slight offset within tile for natural look
        int offsetX = (hash / 1000) % (CellSize / 4) - CellSize / 8;
        int offsetY = (hash / 10000) % (CellSize / 4) - CellSize / 8;
        int decoSize = CellSize * 2 / 3;
        var decoRect = new Rectangle(
            rect.X + (CellSize - decoSize) / 2 + offsetX,
            rect.Y + (CellSize - decoSize) / 2 + offsetY,
            decoSize, decoSize);

        spriteBatch.Draw(texture, decoRect, Color.White * 0.85f);
    }

    /// <summary>Get the transition edge color based on the neighboring terrain type.</summary>
    private static Color GetTransitionColor(string currentTerrain, string neighborTerrain)
    {
        // Blend toward the neighbor's color at 35% opacity for a soft edge
        Color neighborColor = neighborTerrain switch
        {
            SimMap.TerrainForest => ForestColor,
            SimMap.TerrainMountain => MountainColor,
            SimMap.TerrainWater => WaterColor,
            SimMap.TerrainDesert => DesertColor,
            SimMap.TerrainSnow => SnowColor,
            _ => PlainColor,
        };
        return neighborColor * 0.35f;
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

        // Try castle sprite
        AssetLoader.Instance.RegisterBuildingSprite("castle");
        var sheet = AssetLoader.Instance.Animator.GetSheet("bld_castle");
        if (sheet?.Texture != null)
        {
            spriteBatch.Draw(sheet.Texture, inner, Color.White);
        }
        else
        {
            spriteBatch.Draw(_pixel!, inner, BaseColor);
        }

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

        // Hit flash overlay
        if (Vfx != null && Vfx.IsFlashing(enemyId))
        {
            float intensity = Vfx.GetFlashIntensity(enemyId);
            spriteBatch.Draw(_pixel!, inner, Color.White * (intensity * 0.7f));
        }

        // Word label with per-character coloring (above enemy)
        if (_font != null && enemy.TryGetValue("word", out var wordObj))
        {
            string word = wordObj?.ToString() ?? "";
            if (!string.IsNullOrEmpty(word))
            {
                int typedChars = Convert.ToInt32(enemy.GetValueOrDefault("typed_chars", 0));
                bool isTarget = enemy.GetValueOrDefault("is_target") is true;

                var fullSize = _font.MeasureString(word);
                float scale = Math.Min(0.8f, (float)(CellSize + 8) / fullSize.X);

                // Dark background pill behind word
                int pillWidth = (int)(fullSize.X * scale) + 8;
                int pillHeight = (int)(fullSize.Y * scale) + 4;
                int pillX = rect.X + (rect.Width - pillWidth) / 2;
                int pillY = rect.Y - pillHeight - 2;
                spriteBatch.Draw(_pixel!, new Rectangle(pillX, pillY, pillWidth, pillHeight),
                    Color.Black * 0.7f);

                // Per-character coloring
                float charX = pillX + 4;
                float charY = pillY + 2;
                for (int ci = 0; ci < word.Length; ci++)
                {
                    Color charColor;
                    if (ci < typedChars)
                        charColor = ThemeColors.TypedCorrect; // green for typed
                    else if (isTarget)
                        charColor = Color.White; // white remaining for active target
                    else
                        charColor = ThemeColors.TypedPending; // dim for non-target

                    string ch = word[ci].ToString();
                    spriteBatch.DrawString(_font, ch,
                        new Vector2(charX, charY), charColor,
                        0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
                    charX += _font.MeasureString(ch).X * scale;
                }
            }
        }
    }

    // Map object texture names by resource node type
    private static readonly Dictionary<string, string> NodeTextures = new()
    {
        ["wood_grove"] = "tree",
        ["stone_quarry"] = "rock",
        ["food_garden"] = "reeds",
        ["herb_patch"] = "reeds2",
        ["iron_deposit"] = "mine",
        ["pine_forest"] = "pine",
        ["gold_vein"] = "mine",
        ["crystal_cave"] = "rock",
    };

    // Map object texture names by POI type
    private static readonly Dictionary<string, string> PoiTextures = new()
    {
        ["watchtower"] = "watchtower",
        ["shrine"] = "shrine",
        ["mine"] = "mine",
        ["campfire"] = "campfire",
        ["campsite"] = "campsite",
        ["well"] = "well",
        ["market"] = "market_stall",
        ["signpost"] = "signpost",
        ["bridge"] = "bridge",
        ["training_dummy"] = "training_dummy",
        ["arena"] = "training_dummy",
        ["forge"] = "mine",
    };

    private static readonly Color ResourceNodeColor = new(120, 180, 80);
    private static readonly Color NpcColor = new(100, 160, 220);
    private static readonly Color RoamingEnemyColor = new(200, 80, 80, 180);

    private void DrawResourceNode(SpriteBatch spriteBatch, GridPoint pos, Dictionary<string, object> nodeData)
    {
        var rect = TileRect(pos);
        int inset = CellSize / 6;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        string nodeType = nodeData.GetValueOrDefault("type")?.ToString() ?? "";

        // Try map object texture
        if (NodeTextures.TryGetValue(nodeType, out string? texName))
        {
            var texture = AssetLoader.Instance.GetTexture(texName);
            if (texture != null)
            {
                spriteBatch.Draw(texture, inner, Color.White);
                return;
            }
        }

        // Fallback: colored diamond shape (approximated with rectangle)
        spriteBatch.Draw(_pixel!, inner, ResourceNodeColor);

        // Node type label
        if (_font != null && !string.IsNullOrEmpty(nodeType))
        {
            string label = nodeType.Replace('_', ' ');
            var size = _font.MeasureString(label);
            float scale = Math.Min(0.5f, (float)(CellSize - 4) / size.X);
            spriteBatch.DrawString(_font, label,
                new Vector2(rect.X + (rect.Width - size.X * scale) * 0.5f, rect.Y + rect.Height + 1),
                Color.LightGreen, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        }
    }

    private void DrawPoiLandmark(SpriteBatch spriteBatch, string poiId, Dictionary<string, object> poiData)
    {
        GridPoint pos;
        if (poiData.GetValueOrDefault("pos") is GridPoint gp)
            pos = gp;
        else
            return;

        var rect = TileRect(pos);
        int inset = CellSize / 6;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        // Try POI-specific texture (watchtower, shrine, campfire, etc.)
        string textureKey = poiId.Contains("_") ? poiId.Split('_')[0] : poiId;
        // Check POI texture map first, then raw key
        if (PoiTextures.TryGetValue(textureKey, out string? mappedTex))
            textureKey = mappedTex;
        var texture = AssetLoader.Instance.GetTexture(textureKey);
        if (texture != null)
        {
            spriteBatch.Draw(texture, inner, Color.White);
        }
        else
        {
            // Fallback: golden diamond marker
            spriteBatch.Draw(_pixel!, inner, ThemeColors.GoldAccent * 0.7f);
        }

        // POI label
        if (_font != null)
        {
            string label = poiId.Replace('_', ' ');
            var size = _font.MeasureString(label);
            float scale = Math.Min(0.5f, (float)(CellSize + 4) / size.X);
            spriteBatch.DrawString(_font, label,
                new Vector2(rect.X + (rect.Width - size.X * scale) * 0.5f, rect.Y - size.Y * scale - 1),
                ThemeColors.GoldBright, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        }
    }

    private void DrawNpc(SpriteBatch spriteBatch, Dictionary<string, object> npc)
    {
        GridPoint pos;
        if (npc.GetValueOrDefault("pos") is GridPoint gp)
            pos = gp;
        else if (npc.TryGetValue("x", out var xObj) && npc.TryGetValue("y", out var yObj))
            pos = new GridPoint(Convert.ToInt32(xObj), Convert.ToInt32(yObj));
        else
            return;

        var rect = TileRect(pos);
        int inset = CellSize / 5;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        string role = npc.GetValueOrDefault("type")?.ToString() ?? npc.GetValueOrDefault("role")?.ToString() ?? "";

        // Try character sprite texture (direction based on facing)
        string direction = npc.GetValueOrDefault("facing")?.ToString() ?? "south";
        var texture = AssetLoader.Instance.GetNpcTexture(role, direction);

        if (texture != null)
        {
            spriteBatch.Draw(texture, inner, Color.White);
        }
        else
        {
            // Fallback: colored rectangle with role-based tint
            Color color = role switch
            {
                "trainer" => new Color(80, 200, 120),
                "merchant" => new Color(220, 180, 60),
                "quest_giver" => new Color(160, 100, 220),
                _ => NpcColor,
            };
            spriteBatch.Draw(_pixel!, inner, color);
        }

        // NPC name label
        if (_font != null)
        {
            string name = npc.GetValueOrDefault("name")?.ToString() ?? role;
            if (!string.IsNullOrEmpty(name))
            {
                var size = _font.MeasureString(name);
                float scale = Math.Min(0.6f, (float)(CellSize + 8) / size.X);

                // Dark background pill for readability
                int pillWidth = (int)(size.X * scale) + 6;
                int pillHeight = (int)(size.Y * scale) + 2;
                int pillX = rect.X + (rect.Width - pillWidth) / 2;
                int pillY = (int)(rect.Y - size.Y * scale - 4);
                spriteBatch.Draw(_pixel!, new Rectangle(pillX, pillY, pillWidth, pillHeight),
                    Color.Black * 0.6f);

                spriteBatch.DrawString(_font, name,
                    new Vector2(pillX + 3, pillY + 1),
                    Color.White, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            }
        }

        // Quest marker (! for available quests)
        if (_font != null && (npc.GetValueOrDefault("quest_available") is true || npc.GetValueOrDefault("has_quest") is true))
        {
            spriteBatch.DrawString(_font, "!",
                new Vector2(rect.Right - 8, rect.Y - 12),
                ThemeColors.GoldAccent, 0f, Vector2.Zero, 0.8f, SpriteEffects.None, 0f);
        }
    }

    private void DrawRoamingEnemy(SpriteBatch spriteBatch, Dictionary<string, object> enemy)
    {
        GridPoint pos;
        if (enemy.GetValueOrDefault("pos") is GridPoint gp)
            pos = gp;
        else if (enemy.TryGetValue("x", out var xObj) && enemy.TryGetValue("y", out var yObj))
            pos = new GridPoint(Convert.ToInt32(xObj), Convert.ToInt32(yObj));
        else
            return;

        var rect = TileRect(pos);
        int inset = CellSize / 3;
        var inner = new Rectangle(rect.X + inset, rect.Y + inset, rect.Width - inset * 2, rect.Height - inset * 2);

        // Try enemy sprite via SpriteAnimator (same pattern as DrawEnemy)
        string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";
        int enemyId = 0;
        if (enemy.TryGetValue("id", out var idObj))
            enemyId = Convert.ToInt32(idObj);

        AssetLoader.Instance.RegisterEnemySprite(kind);
        string spriteId = $"enemy_{kind}";
        var sheet = AssetLoader.Instance.Animator.GetSheet(spriteId);

        if (sheet?.Texture != null)
        {
            if (!_enemyAnimStates.TryGetValue(enemyId, out var animState))
            {
                animState = SpriteAnimator.CreateState();
                animState.EnableBob(speed: 1.5f, amplitude: 1.5f, phase: enemyId * 0.7f);
                var idle = sheet.GetClip("idle");
                if (idle != null) animState.Play(idle);
                _enemyAnimStates[enemyId] = animState;
            }
            AssetLoader.Instance.Animator.Draw(spriteBatch, spriteId, animState, inner, Color.White * 0.85f);
        }
        else
        {
            // Fallback: red threat indicator
            spriteBatch.Draw(_pixel!, inner, RoamingEnemyColor);
        }

        // Threat zone overlay (semi-transparent on nearby tiles)
        int threatRadius = 2;
        for (int dy = -threatRadius; dy <= threatRadius; dy++)
        {
            for (int dx = -threatRadius; dx <= threatRadius; dx++)
            {
                if (dx == 0 && dy == 0) continue;
                int dist = Math.Abs(dx) + Math.Abs(dy);
                if (dist > threatRadius) continue;
                float alpha = 0.08f * (1f - (float)dist / (threatRadius + 1));
                var threatRect = TileRect(new GridPoint(pos.X + dx, pos.Y + dy));
                spriteBatch.Draw(_pixel!, threatRect, Color.Red * alpha);
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

    /// <summary>Draw opaque fog on all undiscovered tiles in visible range (for chunk background).</summary>
    private void DrawChunkFog(SpriteBatch spriteBatch, GameState state)
    {
        var (minX, minY, maxX, maxY) = VisibleRange;
        // Clamp to map bounds
        minX = Math.Max(0, minX);
        minY = Math.Max(0, minY);
        maxX = Math.Min(state.MapW - 1, maxX);
        maxY = Math.Min(state.MapH - 1, maxY);

        for (int y = minY; y <= maxY; y++)
        {
            for (int x = minX; x <= maxX; x++)
            {
                int idx = SimMap.Idx(x, y, state.MapW);
                if (!state.Discovered.Contains(idx))
                {
                    var rect = TileRect(new GridPoint(x, y));
                    spriteBatch.Draw(_pixel!, rect, FogColor);
                }
            }
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

    private void DrawInteractionPrompts(SpriteBatch spriteBatch, GameState state)
    {
        if (_font == null || _pixel == null) return;
        var playerPos = state.PlayerPos;

        // Check NPCs
        foreach (var npc in state.Npcs)
        {
            GridPoint npcPos;
            if (npc.GetValueOrDefault("pos") is GridPoint gp)
                npcPos = gp;
            else if (npc.TryGetValue("x", out var xObj) && npc.TryGetValue("y", out var yObj))
                npcPos = new GridPoint(Convert.ToInt32(xObj), Convert.ToInt32(yObj));
            else continue;

            if (playerPos.ManhattanDistance(npcPos) <= 1)
            {
                DrawPromptBubble(spriteBatch, npcPos, "[E] Talk");
                break; // Only show one prompt at a time
            }
        }

        // Check resource nodes
        foreach (var (nodeIdx, nodeData) in state.ResourceNodes)
        {
            if (nodeData.GetValueOrDefault("pos") is not GridPoint nPos) continue;
            float cooldown = Convert.ToSingle(nodeData.GetValueOrDefault("cooldown", 0f));
            if (cooldown > 0) continue;

            if (playerPos.ManhattanDistance(nPos) <= 1)
            {
                DrawPromptBubble(spriteBatch, nPos, "[E] Harvest");
                break;
            }
        }
    }

    private void DrawPromptBubble(SpriteBatch spriteBatch, GridPoint pos, string text)
    {
        if (_font == null || _pixel == null) return;

        var rect = TileRect(pos);
        var textSize = _font.MeasureString(text);
        float scale = 0.5f;
        int pillWidth = (int)(textSize.X * scale) + 10;
        int pillHeight = (int)(textSize.Y * scale) + 6;
        int pillX = rect.X + (rect.Width - pillWidth) / 2;
        int pillY = rect.Y - pillHeight - 6;

        // Dark background pill
        spriteBatch.Draw(_pixel, new Rectangle(pillX, pillY, pillWidth, pillHeight),
            Color.Black * 0.75f);

        // Cyan text
        spriteBatch.DrawString(_font, text,
            new Vector2(pillX + 5, pillY + 3), ThemeColors.AccentCyan,
            0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
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
