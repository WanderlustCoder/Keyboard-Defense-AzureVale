using System.IO;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Loads and draws pre-rendered world chunk textures as the map background.
/// Four chunks (NW, NE, SW, SE) compose the full 192x108 tile world at 32px/tile.
/// </summary>
public class WorldMapRenderer
{
    private Texture2D? _chunkNw;
    private Texture2D? _chunkNe;
    private Texture2D? _chunkSw;
    private Texture2D? _chunkSe;

    // Each chunk is 96x54 tiles at 32px = 3072x1728 pixels
    private const int ChunkPixelW = 3072;
    private const int ChunkPixelH = 1728;

    public bool HasChunks => _chunkNw != null;

    public void Initialize(GraphicsDevice device, string chunkDir)
    {
        _chunkNw = LoadChunk(device, Path.Combine(chunkDir, "chunk_nw.png"));
        _chunkNe = LoadChunk(device, Path.Combine(chunkDir, "chunk_ne.png"));
        _chunkSw = LoadChunk(device, Path.Combine(chunkDir, "chunk_sw.png"));
        _chunkSe = LoadChunk(device, Path.Combine(chunkDir, "chunk_se.png"));
    }

    public void Draw(SpriteBatch spriteBatch, Matrix cameraTransform)
    {
        if (!HasChunks) return;

        spriteBatch.Begin(
            transformMatrix: cameraTransform,
            samplerState: SamplerState.PointClamp,
            blendState: BlendState.AlphaBlend);

        spriteBatch.Draw(_chunkNw!, new Vector2(0, 0), Color.White);
        spriteBatch.Draw(_chunkNe!, new Vector2(ChunkPixelW, 0), Color.White);
        spriteBatch.Draw(_chunkSw!, new Vector2(0, ChunkPixelH), Color.White);
        spriteBatch.Draw(_chunkSe!, new Vector2(ChunkPixelW, ChunkPixelH), Color.White);

        spriteBatch.End();
    }

    private static Texture2D? LoadChunk(GraphicsDevice device, string path)
    {
        if (!File.Exists(path)) return null;
        try
        {
            using var stream = File.OpenRead(path);
            return Texture2D.FromStream(device, stream);
        }
        catch
        {
            return null;
        }
    }
}
