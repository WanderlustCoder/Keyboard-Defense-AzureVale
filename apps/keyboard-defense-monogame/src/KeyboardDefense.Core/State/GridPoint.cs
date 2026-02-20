using System;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Integer 2D point for grid coordinates. Replaces Godot's Vector2i.
/// </summary>
public readonly struct GridPoint : IEquatable<GridPoint>
{
    public int X { get; }
    public int Y { get; }

    public GridPoint(int x, int y)
    {
        X = x;
        Y = y;
    }

    public static GridPoint Zero => new(0, 0);

    public static GridPoint operator +(GridPoint a, GridPoint b) => new(a.X + b.X, a.Y + b.Y);
    public static GridPoint operator -(GridPoint a, GridPoint b) => new(a.X - b.X, a.Y - b.Y);
    public static GridPoint operator *(GridPoint a, int scalar) => new(a.X * scalar, a.Y * scalar);
    public static bool operator ==(GridPoint a, GridPoint b) => a.X == b.X && a.Y == b.Y;
    public static bool operator !=(GridPoint a, GridPoint b) => !(a == b);

    public int ManhattanDistance(GridPoint other) => Math.Abs(X - other.X) + Math.Abs(Y - other.Y);
    public double EuclideanDistance(GridPoint other) => Math.Sqrt((X - other.X) * (X - other.X) + (Y - other.Y) * (Y - other.Y));

    public bool Equals(GridPoint other) => X == other.X && Y == other.Y;
    public override bool Equals(object? obj) => obj is GridPoint other && Equals(other);
    public override int GetHashCode() => HashCode.Combine(X, Y);
    public override string ToString() => $"({X}, {Y})";

    public static GridPoint FromIndex(int index, int mapWidth) => new(index % mapWidth, index / mapWidth);
    public int ToIndex(int mapWidth) => Y * mapWidth + X;
}
