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
    private const int DefaultCellSize = 48;
    private const int SinglePixelTextureSize = 1;
    private const int DefaultStructureLevel = 1;
    private const int TerrainAutoTileMask = 15;
    private const int TerrainHashSalt = 17;
    private const int RoadHashXMultiplier = 3571;
    private const int RoadHashYMultiplier = 4219;
    private const int RoadVariantCount = 3;
    private const float RoadOverlayAlpha = 0.85f;
    private const int TransitionMinThickness = 2;
    private const int TransitionThicknessDivisor = 8;
    private const int CursorOutlineThickness = 3;
    private const int InteractionPromptDistance = 1;
    private const float FogTileAlpha = 0.7f;
    private const float ChunkFogTileAlpha = 0.85f;
    private const float TileCenterOffsetFactor = 0.5f;
    private const float PromptBubbleScale = 0.5f;
    private const int PromptBubbleWidthPadding = 10;
    private const int PromptBubbleHeightPadding = 6;
    private const int PromptBubbleYOffset = 6;
    private const int PromptTextXOffset = 5;
    private const int PromptTextYOffset = 3;
    private const float PromptBubbleBackgroundAlpha = 0.75f;

    /// <summary>Gets or sets the world-space pixel size of one map tile used during all world render stages.</summary>
    public int CellSize { get; set; } = DefaultCellSize;
    /// <summary>Gets or sets the world-space origin offset applied when converting grid coordinates to screen space.</summary>
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

    /// <summary>Gets or sets the combat visual-effects service used during enemy overlay rendering.</summary>
    public CombatVfx? Vfx { get; set; }

    // Terrain colors
    private static readonly Color PlainColor = new(90, 130, 65);
    private static readonly Color ForestColor = new(45, 90, 40);
    private static readonly Color MountainColor = new(130, 110, 90);
    private static readonly Color WaterColor = new(50, 90, 150);
    private static readonly Color DesertColor = new(190, 170, 110);
    private static readonly Color SnowColor = new(200, 210, 230);
    private static readonly Color RoadColor = new(140, 120, 80);
    private static readonly Color FogColor = new(20, 20, 30);

    // Entity colors
    private static readonly Color BaseColor = ThemeColors.GoldAccent;
    private static readonly Color CursorColor = ThemeColors.Cyan;
    private static readonly Color StructureColor = new(160, 140, 100);
    private static readonly Color TowerColor = ThemeColors.ShieldBlue;
    private static readonly Color EnemyColor = ThemeColors.DamageRed;

    /// <summary>Initializes rendering resources used during the setup stage before per-frame updates and draws.</summary>
    /// <param name="device">Graphics device used to allocate GPU-backed textures.</param>
    /// <param name="font">Default font used by world-space text overlays and prompts.</param>
    public void Initialize(GraphicsDevice device, SpriteFont font)
    {
        _pixel = new Texture2D(device, SinglePixelTextureSize, SinglePixelTextureSize);
        _pixel.SetData(new[] { Color.White });
        _font = font;
    }

    /// <summary>Advances cached animation state during the frame update stage before the render pass starts.</summary>
    /// <param name="deltaTime">Elapsed frame time in seconds for deterministic animation stepping.</param>
    public void Update(float deltaTime)
    {
        _totalTime += deltaTime;
        foreach (var (_, animState) in _buildingAnimStates)
            animState.Update(deltaTime, _totalTime);
        foreach (var (_, animState) in _enemyAnimStates)
            animState.Update(deltaTime, _totalTime);
    }

    /// <summary>Executes the world render pipeline stage order: terrain, entities, interaction overlays, cursor, and fog.</summary>
    /// <param name="spriteBatch">Sprite batch used for all draw calls in this renderer pass.</param>
    /// <param name="state">Current game simulation state that provides discovered tiles and world entities.</param>
    /// <param name="cameraTransform">Camera transform applied to convert world-space tiles to the active viewport.</param>
    /// <param name="viewport">Current viewport bounds associated with this render pass.</param>
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
            DrawStructure(spriteBatch, pos, structureType, state.StructureLevels.GetValueOrDefault(index, DefaultStructureLevel));
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
        bool isRoad = terrain == SimMap.TerrainRoad;
        string baseTerrain = isRoad ? SimMap.TerrainPlains : terrain;

        Color color = baseTerrain switch
        {
            SimMap.TerrainForest => ForestColor,
            SimMap.TerrainMountain => MountainColor,
            SimMap.TerrainWater => WaterColor,
            SimMap.TerrainDesert => DesertColor,
            SimMap.TerrainSnow => SnowColor,
            _ => PlainColor,
        };

        var rect = TileRect(pos);

        // Use Wang tilesets for non-plains terrain.
        bool drewTileset = baseTerrain != SimMap.TerrainPlains &&
                           TilesetManager.Instance.DrawTile(spriteBatch, baseTerrain, TerrainAutoTileMask, rect);
        int terrainHash = GetDeterministicHash(pos.X, pos.Y, TerrainHashSalt);

        if (!drewTileset)
        {
            if (baseTerrain == SimMap.TerrainPlains)
            {
                DrawPlainsTerrain(spriteBatch, rect, pos, terrainHash, color);
                if (!isRoad)
                    DrawPlainsMacroOverlay(spriteBatch, pos, terrainHash);
            }
            else
            {
                // Try sprite texture, fall back to colored rectangle
                string tileId = baseTerrain switch
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
        }

        // Road overlay — draw dirt path on top of base terrain
        if (isRoad)
        {
            int roadHash = (pos.X * RoadHashXMultiplier + pos.Y * RoadHashYMultiplier) & 0x7FFFFFFF;
            int roadVariant = roadHash % RoadVariantCount;
            string roadId = $"tile_road_{roadVariant}";
            var roadTex = AssetLoader.Instance.GetTexture(roadId);
            if (roadTex != null)
                spriteBatch.Draw(roadTex, rect, Color.White * RoadOverlayAlpha);
            else
                spriteBatch.Draw(_pixel!, rect, RoadColor);
        }

        // Edge transitions: darken edges where biome changes (roads use base terrain for transitions)
        var transitions = AutoTileResolver.GetEdgeTransitions(state, pos);
        foreach (var edge in transitions)
        {
            Color edgeColor = GetTransitionColor(terrain, edge.NeighborTerrain);
            int edgeThickness = Math.Max(TransitionMinThickness, CellSize / TransitionThicknessDivisor);

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

        // Decorative map objects (deterministic scatter based on position hash)
        // Roads don't get decorations; use base terrain for scatter checks
        if (!isRoad)
            DrawDecorations(spriteBatch, baseTerrain, rect, pos, terrainHash);
    }

    private void DrawDecorations(SpriteBatch spriteBatch, string terrain, Rectangle rect, GridPoint pos, int terrainHash)
    {
        // Deterministic hash for scatter placement (no RNG needed)
        int hash = terrainHash;
        int chance = hash % 100;

        if (terrain == SimMap.TerrainPlains)
        {
            DrawPlainsTufts(spriteBatch, rect, pos, hash);
            return;
        }

        string? textureName = null;
        int variant = hash / 100 % 4;
        if (terrain == SimMap.TerrainForest && chance < 30)
            textureName = variant switch { 0 => "tree", 1 => "pine", 2 => "tree", _ => "reeds2" };
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

    private static readonly string[] TuftIds = { "tuft_a", "tuft_b", "tuft_c", "tuft_d", "tuft_e" };

    private Texture2D? GetTuftTexture(int localHash)
    {
        string tuftId = TuftIds[localHash % TuftIds.Length];
        return AssetLoader.Instance.GetTexture(tuftId) ?? AssetLoader.Instance.GetTexture("tuft_a");
    }

    private void DrawPlainsTufts(SpriteBatch spriteBatch, Rectangle rect, GridPoint pos, int hash)
    {
        // Pass 1: Edge tufts — placed at tile boundaries to hide seams (85% of tiles)
        int edgeHash = GetDeterministicHash(pos.X, pos.Y, hash ^ 0x600D);
        if ((edgeHash % 100) < 85)
        {
            // Place 1-3 tufts straddling tile edges
            int edgeCount = 1 + (edgeHash / 100 % 3);
            for (int e = 0; e < edgeCount; e++)
            {
                int eh = GetDeterministicHash(pos.X + e * 3, pos.Y, edgeHash ^ (e * 5471));
                var texture = GetTuftTexture(eh);
                if (texture == null) continue;

                float scale = 0.8f + ((eh >> 6) & 0xF) / 60f;
                int size = (int)(CellSize * 0.5f * scale);
                int edge = eh % 4; // 0=top, 1=right, 2=bottom, 3=left
                int along = (int)(((eh >> 4) & 0x3FF) / 1023f * (CellSize - size));

                int x, y;
                switch (edge)
                {
                    case 0: x = rect.X + along; y = rect.Y - size / 3; break;
                    case 1: x = rect.Right - size * 2 / 3; y = rect.Y + along; break;
                    case 2: x = rect.X + along; y = rect.Bottom - size * 2 / 3; break;
                    default: x = rect.X - size / 3; y = rect.Y + along; break;
                }

                var effects = (eh & 1) != 0 ? SpriteEffects.FlipHorizontally : SpriteEffects.None;
                spriteBatch.Draw(texture, new Rectangle(x, y, size, size), null,
                    Color.White * 0.75f, 0f, Vector2.Zero, effects, 0f);
            }
        }

        // Pass 2: Interior tufts — random scatter within tile (50% of tiles)
        if ((hash % 100) < 50)
        {
            int count = 1 + (hash / 100 % 3);
            for (int i = 0; i < count; i++)
            {
                int localHash = GetDeterministicHash(pos.X + i, pos.Y, hash ^ (i * 7919));
                var texture = GetTuftTexture(localHash);
                if (texture == null) continue;

                float seedX = ((localHash >> 2) & 0x3FF) / 1023f;
                float seedY = ((localHash >> 12) & 0x3FF) / 1023f;

                float scale = 0.85f + ((localHash >> 6) & 0xF) / 50f;
                int size = (int)(CellSize * 0.55f * scale);
                int x = rect.X + (int)(seedX * (rect.Width - size));
                int y = rect.Y + (int)(seedY * (rect.Height - size));

                var effects = (localHash & 1) != 0 ? SpriteEffects.FlipHorizontally : SpriteEffects.None;
                spriteBatch.Draw(texture, new Rectangle(x, y, size, size), null,
                    Color.White * 0.80f, 0f, Vector2.Zero, effects, 0f);
            }
        }

        // Rare wildflower/stone accents at ~5% density
        int accentHash = hash ^ unchecked((int)0xdeadbeef);
        if ((accentHash % 100) < 5)
        {
            string accentId = (accentHash / 100 % 2) == 0 ? "wildflowers" : "small_stones";
            var accentTex = AssetLoader.Instance.GetTexture(accentId);
            if (accentTex != null)
            {
                int ax = rect.X + (accentHash / 1000 % (rect.Width / 2)) + rect.Width / 4;
                int ay = rect.Y + (accentHash / 10000 % (rect.Height / 2)) + rect.Height / 4;
                int aSize = CellSize * 2 / 5;
                spriteBatch.Draw(accentTex, new Rectangle(ax, ay, aSize, aSize), Color.White * 0.7f);
            }
        }
    }

    private void DrawPlainsTerrain(SpriteBatch spriteBatch, Rectangle rect, GridPoint pos, int terrainHash, Color fallbackColor)
    {
        // Use large noise cells (9-12) so tone changes gradually across many tiles — no visible steps
        float tone = GetPlainsField(pos, 11, 73);
        float warmth = GetPlainsField(pos, 14, 131);
        var toneColor = new Color(
            MathHelper.Clamp(0.82f + tone * 0.28f + warmth * 0.05f, 0f, 1.15f),
            MathHelper.Clamp(0.85f + tone * 0.28f, 0f, 1.15f),
            MathHelper.Clamp(0.76f + tone * 0.22f, 0f, 1.05f),
            1f);

        // Layer 1: seamless base — NO flips so Wang tile edges match perfectly between neighbors
        var baseTex = AssetLoader.Instance.GetTexture("tile_grass_base")
                   ?? AssetLoader.Instance.GetTexture("tile_grass_simple");
        if (baseTex != null)
            spriteBatch.Draw(baseTex, rect, toneColor);
        else
            spriteBatch.Draw(_pixel!, rect, fallbackColor);

        // Layer 2: flipped overlay at 30% alpha to break repetition — seams hidden by transparency
        if (baseTex != null)
        {
            var flip = GetPlainsFlip(terrainHash);
            var overRect = new Rectangle(rect.X - 2, rect.Y - 2, rect.Width + 4, rect.Height + 4);
            spriteBatch.Draw(baseTex, overRect, null, toneColor * 0.30f, 0f, Vector2.Zero, flip, 0f);
        }
    }

    private void DrawPlainsMacroOverlay(SpriteBatch spriteBatch, GridPoint pos, int terrainHash)
    {
        DrawPlainsMacroPatch(
            spriteBatch,
            pos,
            terrainHash,
            macroCell: 6,
            patchSalt: unchecked((int)0x9e3779b9),
            densityPercent: 80f,
            alphaPrimary: 0.055f,
            alphaSecondary: 0.03f,
            stretch: 0.40f);
        DrawPlainsMacroPatch(
            spriteBatch,
            pos,
            terrainHash,
            macroCell: 10,
            patchSalt: unchecked((int)0xcafef00d),
            densityPercent: 42f,
            alphaPrimary: 0.030f,
            alphaSecondary: 0.018f,
            stretch: 0.60f);
    }

    private void DrawPlainsMacroPatch(
        SpriteBatch spriteBatch,
        GridPoint pos,
        int terrainHash,
        int macroCell,
        int patchSalt,
        float densityPercent,
        float alphaPrimary,
        float alphaSecondary,
        float stretch)
    {
        int macroX = pos.X / macroCell;
        int macroY = pos.Y / macroCell;
        int macroHash = GetDeterministicHash(macroX, macroY, terrainHash ^ patchSalt);
        if ((macroHash % 100) >= densityPercent) return;

        int anchorX = macroX * macroCell + ((macroHash & 0x7) % macroCell);
        int anchorY = macroY * macroCell + ((macroHash >> 3) & 0x7) % macroCell;
        if (pos.X != anchorX || pos.Y != anchorY) return;

        float tone = GetPlainsTone(pos);
        var toneColor = new Color(
            MathHelper.Clamp(0.82f + tone * 0.32f, 0f, 1.2f),
            MathHelper.Clamp(0.82f + tone * 0.32f, 0f, 1.2f),
            MathHelper.Clamp(0.82f + tone * 0.32f, 0f, 1.2f),
            1f);

        int primaryIdx = GetPlainsVariant(pos, patchSalt, 4, macroCell + 4);
        int secondaryIdx = GetPlainsVariant(pos, patchSalt ^ 0x55aa, 4, macroCell + 5);
        if (secondaryIdx == primaryIdx) secondaryIdx = (secondaryIdx + 1) % 4;
        string overlayPrimaryId = $"tile_grass_{primaryIdx}";
        string overlaySecondaryId = $"tile_grass_{secondaryIdx}";

        var macroPrimary = AssetLoader.Instance.GetTexture(overlayPrimaryId);
        var macroSecondary = AssetLoader.Instance.GetTexture(overlaySecondaryId);
        if (macroPrimary == null && macroSecondary == null) return;

        int macroW = macroCell - ((macroHash >> 1) & 1);
        int macroH = macroCell - ((macroHash >> 2) & 1);
        float macroShiftX = (((macroHash >> 3) & 0x7) - 3.5f) * stretch;
        float macroShiftY = (((macroHash >> 6) & 0x7) - 3.5f) * stretch;
        var macroRect = new Rectangle(
            macroX * CellSize * macroCell + (int)macroShiftX,
            macroY * CellSize * macroCell + (int)macroShiftY,
            macroW * CellSize + 2,
            macroH * CellSize + 2);

        var primaryFlip = GetPlainsFlip(macroHash);
        var secondaryFlip = GetPlainsFlip(macroHash ^ unchecked((int)0x85ebca6b));

        if (macroPrimary != null)
            spriteBatch.Draw(macroPrimary, macroRect, null, toneColor * alphaPrimary, 0f, Vector2.Zero, primaryFlip, 0f);

        if (macroSecondary != null && overlayPrimaryId != overlaySecondaryId)
            spriteBatch.Draw(macroSecondary, macroRect, null, toneColor * alphaSecondary, 0f, Vector2.Zero, secondaryFlip, 0f);
    }

    private int GetPlainsVariant(GridPoint pos, int salt, int variantCount, int cellSize = 7)
    {
        float noise = GetPlainsField(pos, cellSize, salt);
        int variant = (int)(noise * variantCount);
        if (variant >= variantCount) variant = variantCount - 1;
        return variant;
    }

    private float GetPlainsTone(GridPoint pos)
    {
        const int toneCell = 5;
        return GetPlainsField(pos, toneCell, 73);
    }

    private float GetPlainsField(GridPoint pos, int cellSize, int salt)
    {
        int toneCellX = Math.Max(0, pos.X / cellSize);
        int toneCellY = Math.Max(0, pos.Y / cellSize);
        float localX = (float)(pos.X % cellSize) / cellSize;
        float localY = (float)(pos.Y % cellSize) / cellSize;

        float n00 = Hash01(toneCellX, toneCellY, salt);
        float n10 = Hash01(toneCellX + 1, toneCellY, salt);
        float n01 = Hash01(toneCellX, toneCellY + 1, salt);
        float n11 = Hash01(toneCellX + 1, toneCellY + 1, salt);

        float top = MathHelper.Lerp(n00, n10, localX);
        float bottom = MathHelper.Lerp(n01, n11, localX);
        return MathHelper.Lerp(top, bottom, localY);
    }

    private static float Hash01(int x, int y, int salt)
    {
        return GetDeterministicHash(x, y, salt) / (float)int.MaxValue;
    }

    private static SpriteEffects GetPlainsFlip(int hash)
    {
        var effects = SpriteEffects.None;
        if ((hash & 1) != 0) effects |= SpriteEffects.FlipHorizontally;
        if ((hash & 2) != 0) effects |= SpriteEffects.FlipVertically;
        return effects;
    }

    private static int GetDeterministicHash(int x, int y, int salt = 0)
    {
        unchecked
        {
            int h = x * 31 + y * 17 + salt;
            h ^= (h << 13);
            h ^= (h >> 17);
            h ^= (h << 5);
            return h & 0x7FFFFFFF;
        }
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
            SimMap.TerrainRoad => RoadColor,
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

    private void DrawBase(SpriteBatch spriteBatch, GridPoint center)
    {
        var loader = AssetLoader.Instance;

        // Try single cohesive settlement sprite across the 3x3 area
        var settlementTex = loader.GetTexture("bld_settlement");
        if (settlementTex != null)
        {
            var topLeft = new GridPoint(center.X - 1, center.Y - 1);
            var compoundRect = new Rectangle(
                (int)Origin.X + topLeft.X * CellSize,
                (int)Origin.Y + topLeft.Y * CellSize,
                CellSize * 3, CellSize * 3);
            spriteBatch.Draw(settlementTex, compoundRect, Color.White);
            DrawRectOutline(spriteBatch, compoundRect, ThemeColors.GoldBright, 2);
            return;
        }

        // Fallback: 3x3 walled settlement compound from individual pieces
        // Layout:
        //   [corner] [wall_h/gate] [corner]
        //   [wall_v] [  keep     ] [wall_v]
        //   [corner] [  wall_h  ] [corner]
        for (int dy = -1; dy <= 1; dy++)
        {
            for (int dx = -1; dx <= 1; dx++)
            {
                var tilePos = new GridPoint(center.X + dx, center.Y + dy);
                var rect = TileRect(tilePos);

                if (dx == 0 && dy == 0)
                {
                    // Center: castle keep
                    var keepTex = loader.GetTexture("bld_keep");
                    if (keepTex != null)
                        spriteBatch.Draw(keepTex, rect, Color.White);
                    else
                        spriteBatch.Draw(_pixel!, rect, BaseColor);
                    DrawRectOutline(spriteBatch, rect, ThemeColors.GoldBright, 2);
                }
                else if (dx == 0 && dy == -1)
                {
                    // North center: gate
                    var gateTex = loader.GetTexture("bld_gate");
                    if (gateTex != null)
                        spriteBatch.Draw(gateTex, rect, Color.White);
                    else
                    {
                        spriteBatch.Draw(_pixel!, rect, StructureColor);
                        DrawRectOutline(spriteBatch, rect, ThemeColors.Border, 1);
                    }
                }
                else if (Math.Abs(dx) == 1 && Math.Abs(dy) == 1)
                {
                    // Corners
                    var cornerTex = loader.GetTexture("bld_wall_corner");
                    if (cornerTex != null)
                    {
                        var flip = SpriteEffects.None;
                        if (dx > 0) flip |= SpriteEffects.FlipHorizontally;
                        if (dy > 0) flip |= SpriteEffects.FlipVertically;
                        spriteBatch.Draw(cornerTex, rect, null, Color.White, 0f, Vector2.Zero, flip, 0f);
                    }
                    else
                    {
                        spriteBatch.Draw(_pixel!, rect, MountainColor);
                        DrawRectOutline(spriteBatch, rect, ThemeColors.Border, 1);
                    }
                }
                else if (dx == 0)
                {
                    // South center: horizontal wall
                    var wallHTex = loader.GetTexture("bld_wall_h");
                    if (wallHTex != null)
                        spriteBatch.Draw(wallHTex, rect, Color.White);
                    else
                    {
                        spriteBatch.Draw(_pixel!, rect, MountainColor);
                        DrawRectOutline(spriteBatch, rect, ThemeColors.Border, 1);
                    }
                }
                else
                {
                    // East/West: vertical wall
                    var wallVTex = loader.GetTexture("bld_wall_v");
                    if (wallVTex != null)
                        spriteBatch.Draw(wallVTex, rect, Color.White);
                    else
                    {
                        spriteBatch.Draw(_pixel!, rect, MountainColor);
                        DrawRectOutline(spriteBatch, rect, ThemeColors.Border, 1);
                    }
                }
            }
        }
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
        DrawRectOutline(spriteBatch, rect, CursorColor, CursorOutlineThickness);
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
            spriteBatch.Draw(_pixel!, rect, FogColor * FogTileAlpha);
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
                    spriteBatch.Draw(_pixel!, rect, FogColor * ChunkFogTileAlpha);
                }
            }
        }
    }

    /// <summary>Computes the center point of a grid tile during coordinate conversion for world-space overlays.</summary>
    /// <param name="pos">Grid position to convert.</param>
    /// <returns>World-space pixel center of the tile.</returns>
    public Vector2 TileCenter(GridPoint pos)
    {
        return new Vector2(
            Origin.X + pos.X * CellSize + CellSize * TileCenterOffsetFactor,
            Origin.Y + pos.Y * CellSize + CellSize * TileCenterOffsetFactor);
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

            if (playerPos.ManhattanDistance(npcPos) <= InteractionPromptDistance)
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

            if (playerPos.ManhattanDistance(nPos) <= InteractionPromptDistance)
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
        float scale = PromptBubbleScale;
        int pillWidth = (int)(textSize.X * scale) + PromptBubbleWidthPadding;
        int pillHeight = (int)(textSize.Y * scale) + PromptBubbleHeightPadding;
        int pillX = rect.X + (rect.Width - pillWidth) / 2;
        int pillY = rect.Y - pillHeight - PromptBubbleYOffset;

        // Dark background pill
        spriteBatch.Draw(_pixel, new Rectangle(pillX, pillY, pillWidth, pillHeight),
            Color.Black * PromptBubbleBackgroundAlpha);

        // Cyan text
        spriteBatch.DrawString(_font, text,
            new Vector2(pillX + PromptTextXOffset, pillY + PromptTextYOffset), ThemeColors.AccentCyan,
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
