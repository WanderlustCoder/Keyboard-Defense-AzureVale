using System;
using Microsoft.Xna.Framework;

namespace KeyboardDefense.Game.Rendering;

/// <summary>
/// Smooth-follow camera targeting the player position.
/// Returns a Matrix transform for SpriteBatch rendering.
/// </summary>
public class WorldCamera
{
    private Vector2 _position;
    private float _zoom = 1.0f;
    private int _viewportWidth;
    private int _viewportHeight;
    private int _worldWidth;
    private int _worldHeight;
    private int _cellSize;

    /// <summary>
    /// Gets or sets the exponential follow response speed in inverse seconds when interpolating toward a tile target.
    /// </summary>
    public float SmoothSpeed { get; set; } = 8.0f;

    /// <summary>
    /// Gets or sets the camera zoom scale used for world-to-screen transforms.
    /// </summary>
    /// <remarks>
    /// Assigned values are clamped to the inclusive range [0.25, 4.0].
    /// </remarks>
    public float Zoom
    {
        get => _zoom;
        set => _zoom = MathHelper.Clamp(value, 0.25f, 4.0f);
    }

    /// <summary>
    /// Gets the camera center position in world-space pixels.
    /// </summary>
    public Vector2 Position => _position;

    /// <summary>
    /// Configures viewport and world dimensions used by camera transforms and clamping.
    /// </summary>
    /// <param name="viewportWidth">Viewport width in screen pixels.</param>
    /// <param name="viewportHeight">Viewport height in screen pixels.</param>
    /// <param name="worldTilesW">World width in tile columns.</param>
    /// <param name="worldTilesH">World height in tile rows.</param>
    /// <param name="cellSize">Tile size in world-space pixels per tile.</param>
    /// <remarks>
    /// This method updates camera bounds metadata only. It does not recenter the camera; call <see cref="SnapTo"/> or
    /// <see cref="Follow"/> to move the camera after initialization.
    /// </remarks>
    public void Initialize(int viewportWidth, int viewportHeight, int worldTilesW, int worldTilesH, int cellSize)
    {
        _viewportWidth = viewportWidth;
        _viewportHeight = viewportHeight;
        _worldWidth = worldTilesW;
        _worldHeight = worldTilesH;
        _cellSize = cellSize;
    }

    /// <summary>
    /// Updates the active viewport size used by world-to-screen and screen-to-world conversion.
    /// </summary>
    /// <param name="width">Viewport width in screen pixels.</param>
    /// <param name="height">Viewport height in screen pixels.</param>
    /// <remarks>
    /// The camera center is not modified by this call. Subsequent transform and visible-range calculations will use the
    /// new viewport dimensions.
    /// </remarks>
    public void SetViewport(int width, int height)
    {
        _viewportWidth = width;
        _viewportHeight = height;
    }

    /// <summary>
    /// Immediately repositions the camera to the center of a target tile and applies world-bound clamping.
    /// </summary>
    /// <param name="tileX">Zero-based tile column in world grid coordinates.</param>
    /// <param name="tileY">Zero-based tile row in world grid coordinates.</param>
    /// <remarks>
    /// Target tile coordinates are converted to world-space pixel center coordinates before clamping to the currently
    /// configured world extents.
    /// </remarks>
    public void SnapTo(int tileX, int tileY)
    {
        _position = TileToWorld(tileX, tileY);
        ClampPosition();
    }

    /// <summary>
    /// Smoothly interpolates the camera center toward a target tile using exponential smoothing.
    /// </summary>
    /// <param name="tileX">Zero-based tile column in world grid coordinates.</param>
    /// <param name="tileY">Zero-based tile row in world grid coordinates.</param>
    /// <param name="deltaTime">Elapsed frame time in seconds used to compute interpolation weight.</param>
    /// <remarks>
    /// The interpolation factor is computed as <c>1 - exp(-SmoothSpeed * deltaTime)</c>, producing frame-rate independent
    /// smoothing. The resulting position is then clamped to world bounds.
    /// </remarks>
    public void Follow(int tileX, int tileY, float deltaTime)
    {
        var target = TileToWorld(tileX, tileY);
        float t = 1f - MathF.Exp(-SmoothSpeed * deltaTime);
        _position = Vector2.Lerp(_position, target, t);
        ClampPosition();
    }

    /// <summary>
    /// Builds the camera transform matrix consumed by <c>SpriteBatch.Begin</c> for world rendering.
    /// </summary>
    /// <returns>
    /// A matrix that translates by negative camera position, scales by <see cref="Zoom"/>, and then offsets to the viewport
    /// center so the camera position appears at screen center.
    /// </returns>
    public Matrix GetTransform()
    {
        return Matrix.CreateTranslation(-_position.X, -_position.Y, 0)
             * Matrix.CreateScale(_zoom, _zoom, 1)
             * Matrix.CreateTranslation(_viewportWidth * 0.5f, _viewportHeight * 0.5f, 0);
    }

    /// <summary>
    /// Computes the approximate visible tile range for the current camera position, zoom, and viewport.
    /// </summary>
    /// <returns>
    /// Inclusive tile bounds as <c>(minX, minY, maxX, maxY)</c> in zero-based world coordinates, expanded by one tile of
    /// padding to reduce edge pop-in during rendering.
    /// </returns>
    /// <remarks>
    /// Returns <c>(0, 0, 0, 0)</c> when tile size is not configured (<c>cellSize &lt;= 0</c>).
    /// </remarks>
    public (int minX, int minY, int maxX, int maxY) GetVisibleTileRange()
    {
        if (_cellSize <= 0) return (0, 0, 0, 0);

        float halfW = _viewportWidth * 0.5f / _zoom;
        float halfH = _viewportHeight * 0.5f / _zoom;

        int minX = Math.Max(0, (int)((_position.X - halfW) / _cellSize) - 1);
        int minY = Math.Max(0, (int)((_position.Y - halfH) / _cellSize) - 1);
        int maxX = Math.Min(_worldWidth - 1, (int)((_position.X + halfW) / _cellSize) + 1);
        int maxY = Math.Min(_worldHeight - 1, (int)((_position.Y + halfH) / _cellSize) + 1);

        return (minX, minY, maxX, maxY);
    }

    /// <summary>
    /// Converts a screen-space pixel coordinate into the corresponding world tile indices.
    /// </summary>
    /// <param name="screenX">Screen-space X pixel from the viewport's top-left origin.</param>
    /// <param name="screenY">Screen-space Y pixel from the viewport's top-left origin.</param>
    /// <returns>Zero-based tile coordinates <c>(tileX, tileY)</c> at the sampled screen location.</returns>
    /// <remarks>
    /// This applies the inverse of the camera translation and zoom, then divides by tile size to map world-space pixels
    /// into grid coordinates.
    /// </remarks>
    public (int tileX, int tileY) ScreenToTile(int screenX, int screenY)
    {
        float worldX = (screenX - _viewportWidth * 0.5f) / _zoom + _position.X;
        float worldY = (screenY - _viewportHeight * 0.5f) / _zoom + _position.Y;
        return ((int)(worldX / _cellSize), (int)(worldY / _cellSize));
    }

    private Vector2 TileToWorld(int tileX, int tileY)
    {
        return new Vector2(
            tileX * _cellSize + _cellSize * 0.5f,
            tileY * _cellSize + _cellSize * 0.5f);
    }

    private void ClampPosition()
    {
        float halfW = _viewportWidth * 0.5f / _zoom;
        float halfH = _viewportHeight * 0.5f / _zoom;
        float maxWorldX = _worldWidth * _cellSize;
        float maxWorldY = _worldHeight * _cellSize;

        float minX = halfW;
        float maxClampX = maxWorldX - halfW;
        if (minX > maxClampX) { float mid = (minX + maxClampX) / 2; minX = maxClampX = mid; }

        float minY = halfH;
        float maxClampY = maxWorldY - halfH;
        if (minY > maxClampY) { float mid = (minY + maxClampY) / 2; minY = maxClampY = mid; }

        _position.X = MathHelper.Clamp(_position.X, minX, maxClampX);
        _position.Y = MathHelper.Clamp(_position.Y, minY, maxClampY);
    }
}
