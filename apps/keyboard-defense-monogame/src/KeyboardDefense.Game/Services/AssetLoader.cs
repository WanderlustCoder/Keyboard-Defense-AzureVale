using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Newtonsoft.Json.Linq;
using KeyboardDefense.Game.Rendering;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Runtime texture loading service with caching and graceful fallback.
/// Loads PNG textures from Content/Textures/ directory.
/// Returns null if texture is missing (renderers use colored rectangle fallback).
/// </summary>
public class AssetLoader
{
    private static AssetLoader? _instance;
    public static AssetLoader Instance => _instance ??= new();

    private GraphicsDevice? _device;
    private readonly Dictionary<string, Texture2D?> _textureCache = new();
    private readonly Dictionary<string, string> _manifestPaths = new();
    private readonly Dictionary<string, JObject> _animationDefs = new();
    private readonly SpriteAnimator _animator = new();
    private string _textureRoot = "";
    private bool _initialized;

    /// <summary>Path to the Content/Textures/ directory.</summary>
    public string TextureRoot => _textureRoot;

    /// <summary>Global sprite animator with registered sheets.</summary>
    public SpriteAnimator Animator => _animator;

    public void Initialize(GraphicsDevice device)
    {
        _device = device;
        _textureRoot = FindTextureRoot();
        _initialized = true;
        LoadManifest();
    }

    /// <summary>
    /// Load the texture manifest to map asset IDs to file paths.
    /// </summary>
    private void LoadManifest()
    {
        // Try loading the generated texture manifest
        string manifestPath = Path.Combine(_textureRoot, "texture_manifest.json");
        if (File.Exists(manifestPath))
        {
            try
            {
                string json = File.ReadAllText(manifestPath);
                var manifest = JObject.Parse(json);
                var textures = manifest["textures"] as JArray;
                if (textures != null)
                {
                    foreach (var entry in textures)
                    {
                        string id = entry["id"]?.ToString() ?? "";
                        string path = entry["path"]?.ToString() ?? "";
                        if (!string.IsNullOrEmpty(id) && !string.IsNullOrEmpty(path))
                            _manifestPaths[id] = path;

                        // Store animation definitions if present
                        if (entry["animations"] is JObject anims)
                            _animationDefs[id] = anims;
                    }
                }
            }
            catch (Exception)
            {
                // Manifest load failure is non-fatal
            }
        }

        // Also try loading the main assets_manifest.json from data/
        string dataManifest = FindDataFile("assets_manifest.json");
        if (!string.IsNullOrEmpty(dataManifest) && File.Exists(dataManifest))
        {
            try
            {
                string json = File.ReadAllText(dataManifest);
                var manifest = JObject.Parse(json);
                var textures = manifest["textures"] as JArray;
                if (textures != null)
                {
                    foreach (var entry in textures)
                    {
                        string id = entry["id"]?.ToString() ?? "";
                        string category = entry["category"]?.ToString() ?? "sprites";
                        if (!string.IsNullOrEmpty(id) && !_manifestPaths.ContainsKey(id))
                            _manifestPaths[id] = $"{category}/{id}.png";
                    }
                }
            }
            catch (Exception)
            {
                // Non-fatal
            }
        }
    }

    /// <summary>
    /// Get a texture by asset ID. Returns null if not found (caller uses fallback).
    /// </summary>
    public Texture2D? GetTexture(string id)
    {
        if (!_initialized || _device == null) return null;

        if (_textureCache.TryGetValue(id, out var cached))
            return cached;

        Texture2D? texture = TryLoadTexture(id);
        _textureCache[id] = texture;
        return texture;
    }

    public Texture2D? GetEnemyTexture(string kind)
        => GetTexture($"enemy_{kind}");

    public Texture2D? GetBuildingTexture(string type)
        => GetTexture($"bld_{type}");

    public Texture2D? GetTileTexture(string biome)
        => GetTexture($"tile_{biome}");

    public Texture2D? GetIconTexture(string name)
        => GetTexture($"ico_{name}");

    public Texture2D? GetPortrait(string name)
        => GetTexture(name);

    /// <summary>
    /// Get NPC character texture by type and direction (south/east/north/west).
    /// Files stored as characters/npc_{type}_{direction}.png.
    /// </summary>
    public Texture2D? GetNpcTexture(string npcType, string direction = "south")
        => GetTexture($"npc_{npcType}_{direction}");

    /// <summary>
    /// Get player character texture by direction.
    /// Files stored as characters/player_hero_{direction}.png.
    /// </summary>
    public Texture2D? GetPlayerTexture(string direction = "south")
        => GetTexture($"player_hero_{direction}");

    private Texture2D? TryLoadTexture(string id)
    {
        // Try manifest path first
        if (_manifestPaths.TryGetValue(id, out string? manifestPath))
        {
            string fullPath = Path.Combine(_textureRoot, manifestPath.Replace('/', Path.DirectorySeparatorChar));
            var tex = LoadFromFile(fullPath);
            if (tex != null) return tex;
        }

        // Try common paths
        string[] searchPaths = new[]
        {
            Path.Combine(_textureRoot, "sprites", $"{id}.png"),
            Path.Combine(_textureRoot, "tiles", $"{id}.png"),
            Path.Combine(_textureRoot, "icons", $"{id}.png"),
            Path.Combine(_textureRoot, "portraits", $"{id}.png"),
            Path.Combine(_textureRoot, "characters", $"{id}.png"),
            Path.Combine(_textureRoot, "ui", $"{id}.png"),
            Path.Combine(_textureRoot, "effects", $"{id}.png"),
            Path.Combine(_textureRoot, "tilesets", $"{id}.png"),
            Path.Combine(_textureRoot, "map_objects", $"{id}.png"),
            Path.Combine(_textureRoot, $"{id}.png"),
        };

        foreach (string path in searchPaths)
        {
            var tex = LoadFromFile(path);
            if (tex != null) return tex;
        }

        return null;
    }

    private Texture2D? LoadFromFile(string path)
    {
        if (!File.Exists(path) || _device == null) return null;

        try
        {
            using var stream = File.OpenRead(path);
            return Texture2D.FromStream(_device, stream);
        }
        catch (Exception)
        {
            return null;
        }
    }

    private string FindTextureRoot()
    {
        // Look for Content/Textures relative to the executable
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;

        string[] candidates = new[]
        {
            Path.Combine(baseDir, "Content", "Textures"),
            Path.Combine(baseDir, "..", "Content", "Textures"),
            Path.Combine(Directory.GetCurrentDirectory(), "Content", "Textures"),
        };

        // Also walk up from base directory
        string dir = baseDir;
        for (int i = 0; i < 6; i++)
        {
            string candidate = Path.Combine(dir, "Content", "Textures");
            if (Directory.Exists(candidate))
                return candidate;
            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir) break;
            dir = parent;
        }

        foreach (string candidate in candidates)
        {
            if (Directory.Exists(candidate))
                return candidate;
        }

        // Return default even if it doesn't exist
        return Path.Combine(baseDir, "Content", "Textures");
    }

    private static string FindDataFile(string filename)
    {
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string[] candidates = new[]
        {
            Path.Combine(baseDir, "data", filename),
            Path.Combine(Directory.GetCurrentDirectory(), "data", filename),
        };

        string dir = baseDir;
        for (int i = 0; i < 6; i++)
        {
            string candidate = Path.Combine(dir, "data", filename);
            if (File.Exists(candidate))
                return candidate;
            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir) break;
            dir = parent;
        }

        foreach (string c in candidates)
        {
            if (File.Exists(c))
                return c;
        }

        return "";
    }

    /// <summary>
    /// Preload textures by category for faster first access.
    /// </summary>
    public void PreloadCategory(string category)
    {
        foreach (var (id, path) in _manifestPaths)
        {
            if (path.Contains($"/{category}/") || path.Contains($"\\{category}\\"))
                GetTexture(id);
        }
    }

    /// <summary>
    /// Load a texture and register it with the animator.
    /// If the manifest has animation data, creates a full sprite sheet.
    /// Otherwise registers as a static single-frame sprite.
    /// </summary>
    public SpriteAnimator.SpriteSheet? GetAnimatedSprite(string id)
    {
        // Check if already registered
        var existing = _animator.GetSheet(id);
        if (existing != null) return existing;

        var texture = GetTexture(id);
        if (texture == null) return null;

        // Check for animation definitions in manifest
        if (_animationDefs.TryGetValue(id, out var animDefs))
        {
            int frameWidth = texture.Height; // Assume square frames
            int frameCount = texture.Width / frameWidth;
            if (frameCount < 1) frameCount = 1;

            // Parse animation clips from manifest
            var clips = new Dictionary<string, SpriteAnimator.AnimationClip>();
            int row = 0;
            foreach (var (clipName, clipData) in animDefs)
            {
                if (clipData is not JObject cd) continue;
                int frames = cd["frames"]?.ToObject<int>() ?? 2;
                float duration = cd["duration"]?.ToObject<float>() ?? 0.15f;
                bool loop = cd["loop"]?.ToObject<bool>() ?? true;

                clips[clipName] = new SpriteAnimator.AnimationClip
                {
                    Name = clipName,
                    FrameCount = frames,
                    FrameDuration = duration,
                    Loop = loop,
                    Row = row++,
                };
            }

            var sheet = new SpriteAnimator.SpriteSheet
            {
                Texture = texture,
                FrameWidth = frameWidth,
                FrameHeight = texture.Height / Math.Max(1, row),
                Clips = clips,
            };
            _animator.RegisterSheet(id, sheet);
            return sheet;
        }

        // No animation data — register as static
        _animator.RegisterStatic(id, texture);
        return _animator.GetSheet(id);
    }

    /// <summary>
    /// Register a static texture with the animator using standard enemy clips.
    /// Uses procedural animation (bobbing/pulsing) since there's only 1 frame.
    /// </summary>
    public void RegisterEnemySprite(string kind)
    {
        string id = $"enemy_{kind}";
        if (_animator.GetSheet(id) != null) return;

        var texture = GetEnemyTexture(kind);
        if (texture == null) return;

        // Check for sprite sheet animation
        if (_animationDefs.ContainsKey(id))
        {
            GetAnimatedSprite(id);
            return;
        }

        // Single-frame: register as static with idle clip
        _animator.RegisterStatic(id, texture);
    }

    /// <summary>
    /// Register a static texture with the animator using standard building clips.
    /// </summary>
    public void RegisterBuildingSprite(string type)
    {
        string id = $"bld_{type}";
        if (_animator.GetSheet(id) != null) return;

        var texture = GetBuildingTexture(type);
        if (texture == null) return;

        if (_animationDefs.ContainsKey(id))
        {
            GetAnimatedSprite(id);
            return;
        }

        _animator.RegisterStatic(id, texture);
    }

    public int CachedCount => _textureCache.Count;
    public int ManifestCount => _manifestPaths.Count;
}
