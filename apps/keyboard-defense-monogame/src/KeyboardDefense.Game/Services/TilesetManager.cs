using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Newtonsoft.Json.Linq;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Loads and manages Wang tilesets for terrain rendering.
/// Each tileset is a 4x4 sprite sheet (16 Wang tiles) with JSON metadata
/// describing the bounding box of each wang_id within the sheet.
///
/// Terrain types are mapped to tilesets:
///   plains → rd (meadow/road), forest → sd (swamp/dark),
///   mountain → mc (mountain/cliff), water → wb (water/beach)
/// </summary>
public class TilesetManager
{
    private static TilesetManager? _instance;
    public static TilesetManager Instance => _instance ??= new();

    private readonly Dictionary<string, Texture2D> _tilesetTextures = new();
    private readonly Dictionary<string, TilesetData> _tilesetData = new();
    private bool _initialized;

    // Terrain type → tileset ID mapping
    private static readonly Dictionary<string, string> TerrainToTileset = new()
    {
        ["plains"] = "rd",
        ["forest"] = "sd",
        ["mountain"] = "mc",
        ["water"] = "wb",
    };

    /// <summary>
    /// Load all tilesets from Content/Textures/tilesets/ directory.
    /// </summary>
    public void Initialize(GraphicsDevice device, string textureRoot)
    {
        if (_initialized) return;
        _initialized = true;

        string tilesetDir = Path.Combine(textureRoot, "tilesets");
        if (!Directory.Exists(tilesetDir)) return;

        foreach (string jsonPath in Directory.GetFiles(tilesetDir, "*.json"))
        {
            string id = Path.GetFileNameWithoutExtension(jsonPath);
            string pngPath = Path.ChangeExtension(jsonPath, ".png");

            if (!File.Exists(pngPath)) continue;

            try
            {
                var data = ParseTilesetJson(jsonPath);
                if (data == null) continue;

                using var stream = File.OpenRead(pngPath);
                var texture = Texture2D.FromStream(device, stream);

                _tilesetData[id] = data;
                _tilesetTextures[id] = texture;
            }
            catch (Exception)
            {
                // Non-fatal: skip broken tilesets
            }
        }
    }

    /// <summary>
    /// Get the tileset texture and metadata for a terrain type.
    /// Returns null if no tileset is mapped for this terrain.
    /// </summary>
    public (Texture2D? Texture, TilesetData? Data) GetTilesetForTerrain(string terrain)
    {
        if (!TerrainToTileset.TryGetValue(terrain, out string? tilesetId))
            return (null, null);

        if (!_tilesetTextures.TryGetValue(tilesetId, out var texture))
            return (null, null);

        if (!_tilesetData.TryGetValue(tilesetId, out var data))
            return (null, null);

        return (texture, data);
    }

    /// <summary>
    /// Draw a terrain tile using the appropriate Wang tileset.
    /// Returns true if drawn, false if no tileset available (caller should fallback).
    /// </summary>
    public bool DrawTile(SpriteBatch spriteBatch, string terrain, int cardinalMask, Rectangle destRect)
    {
        var (texture, data) = GetTilesetForTerrain(terrain);
        if (texture == null || data == null) return false;

        int wangId = TilesetData.CardinalMaskToCornerWang(cardinalMask);
        var sourceRect = data.GetSourceRect(wangId);
        if (sourceRect == null) return false;

        var src = new Rectangle(sourceRect.X, sourceRect.Y, sourceRect.Width, sourceRect.Height);
        spriteBatch.Draw(texture, destRect, src, Color.White);
        return true;
    }

    /// <summary>Number of loaded tilesets.</summary>
    public int LoadedCount => _tilesetTextures.Count;

    private static TilesetData? ParseTilesetJson(string jsonPath)
    {
        string json = File.ReadAllText(jsonPath);
        var root = JObject.Parse(json);

        var tileSize = root["tile_size"];
        int tw = tileSize?["width"]?.ToObject<int>() ?? 16;
        int th = tileSize?["height"]?.ToObject<int>() ?? 16;

        string lower = root["lower_description"]?.ToString() ?? "";
        string upper = root["upper_description"]?.ToString() ?? "";

        var data = new TilesetData
        {
            TileWidth = tw,
            TileHeight = th,
            LowerTerrain = lower,
            UpperTerrain = upper,
        };

        var tiles = root["tileset_data"]?["tiles"] as JArray;
        if (tiles == null) return null;

        foreach (var tile in tiles)
        {
            string name = tile["name"]?.ToString() ?? "";

            // Extract wang ID from name "wang_N"
            int wangId = -1;
            if (name.StartsWith("wang_"))
            {
                if (int.TryParse(name.AsSpan(5), out int parsed))
                    wangId = parsed;
            }
            if (wangId < 0 || wangId > 15) continue;

            var bbox = tile["bounding_box"];
            if (bbox == null) continue;

            int x = bbox["x"]?.ToObject<int>() ?? 0;
            int y = bbox["y"]?.ToObject<int>() ?? 0;
            int w = bbox["width"]?.ToObject<int>() ?? tw;
            int h = bbox["height"]?.ToObject<int>() ?? th;

            data.SetTileRect(wangId, x, y, w, h);
        }

        return data.Count > 0 ? data : null;
    }
}
