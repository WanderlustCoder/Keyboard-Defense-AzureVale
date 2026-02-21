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

    public float SmoothSpeed { get; set; } = 8.0f;
    public float Zoom
    {
        get => _zoom;
        set => _zoom = MathHelper.Clamp(value, 0.25f, 4.0f);
    }
    public Vector2 Position => _position;

    public void Initialize(int viewportWidth, int viewportHeight, int worldTilesW, int worldTilesH, int cellSize)
    {
        _viewportWidth = viewportWidth;
        _viewportHeight = viewportHeight;
        _worldWidth = worldTilesW;
        _worldHeight = worldTilesH;
        _cellSize = cellSize;
    }

    public void SetViewport(int width, int height)
    {
        _viewportWidth = width;
        _viewportHeight = height;
    }

    /// <summary>Instantly center the camera on a tile position.</summary>
    public void SnapTo(int tileX, int tileY)
    {
        _position = TileToWorld(tileX, tileY);
        ClampPosition();
    }

    /// <summary>Smoothly move the camera toward the target tile position.</summary>
    public void Follow(int tileX, int tileY, float deltaTime)
    {
        var target = TileToWorld(tileX, tileY);
        float t = 1f - MathF.Exp(-SmoothSpeed * deltaTime);
        _position = Vector2.Lerp(_position, target, t);
        ClampPosition();
    }

    /// <summary>Returns the SpriteBatch transform matrix for this camera.</summary>
    public Matrix GetTransform()
    {
        return Matrix.CreateTranslation(-_position.X, -_position.Y, 0)
             * Matrix.CreateScale(_zoom, _zoom, 1)
             * Matrix.CreateTranslation(_viewportWidth * 0.5f, _viewportHeight * 0.5f, 0);
    }

    /// <summary>Returns the visible tile range for viewport culling.</summary>
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

    /// <summary>Convert screen coordinates to world tile position.</summary>
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

        _position.X = MathHelper.Clamp(_position.X, halfW, maxWorldX - halfW);
        _position.Y = MathHelper.Clamp(_position.Y, halfH, maxWorldY - halfH);
    }
}
