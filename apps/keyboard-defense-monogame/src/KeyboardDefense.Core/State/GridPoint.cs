using System;

namespace KeyboardDefense.Core.State;

/// <summary>
/// Integer 2D point for grid coordinates. Replaces Godot's Vector2i.
/// </summary>
public readonly struct GridPoint : IEquatable<GridPoint>
{
    /// <summary>
    /// Gets the X coordinate.
    /// </summary>
    public int X { get; }
    /// <summary>
    /// Gets the Y coordinate.
    /// </summary>
    public int Y { get; }

    /// <summary>
    /// Initializes a new instance of the <see cref="GridPoint"/> struct.
    /// </summary>
    /// <param name="x">The X coordinate.</param>
    /// <param name="y">The Y coordinate.</param>
    public GridPoint(int x, int y)
    {
        X = x;
        Y = y;
    }

    /// <summary>
    /// Gets the zero grid point at coordinate (0, 0).
    /// </summary>
    public static GridPoint Zero => new(0, 0);

    /// <summary>
    /// Adds two grid points component-wise.
    /// </summary>
    /// <param name="a">The left operand.</param>
    /// <param name="b">The right operand.</param>
    /// <returns>The summed grid point.</returns>
    public static GridPoint operator +(GridPoint a, GridPoint b) => new(a.X + b.X, a.Y + b.Y);
    /// <summary>
    /// Subtracts one grid point from another component-wise.
    /// </summary>
    /// <param name="a">The left operand.</param>
    /// <param name="b">The right operand.</param>
    /// <returns>The difference grid point.</returns>
    public static GridPoint operator -(GridPoint a, GridPoint b) => new(a.X - b.X, a.Y - b.Y);
    /// <summary>
    /// Multiplies a grid point by an integer scalar.
    /// </summary>
    /// <param name="a">The grid point operand.</param>
    /// <param name="scalar">The scalar value.</param>
    /// <returns>The scaled grid point.</returns>
    public static GridPoint operator *(GridPoint a, int scalar) => new(a.X * scalar, a.Y * scalar);
    /// <summary>
    /// Compares two grid points for coordinate equality.
    /// </summary>
    /// <param name="a">The left operand.</param>
    /// <param name="b">The right operand.</param>
    /// <returns><see langword="true"/> when both coordinates are equal; otherwise <see langword="false"/>.</returns>
    public static bool operator ==(GridPoint a, GridPoint b) => a.X == b.X && a.Y == b.Y;
    /// <summary>
    /// Compares two grid points for coordinate inequality.
    /// </summary>
    /// <param name="a">The left operand.</param>
    /// <param name="b">The right operand.</param>
    /// <returns><see langword="true"/> when coordinates differ; otherwise <see langword="false"/>.</returns>
    public static bool operator !=(GridPoint a, GridPoint b) => !(a == b);

    /// <summary>
    /// Computes Manhattan distance to another point.
    /// </summary>
    /// <param name="other">The destination point.</param>
    /// <returns>The Manhattan distance in grid steps.</returns>
    public int ManhattanDistance(GridPoint other) => Math.Abs(X - other.X) + Math.Abs(Y - other.Y);
    /// <summary>
    /// Computes Euclidean distance to another point.
    /// </summary>
    /// <param name="other">The destination point.</param>
    /// <returns>The straight-line distance.</returns>
    public double EuclideanDistance(GridPoint other) => Math.Sqrt((X - other.X) * (X - other.X) + (Y - other.Y) * (Y - other.Y));

    /// <summary>
    /// Determines whether this point equals another point.
    /// </summary>
    /// <param name="other">The point to compare against.</param>
    /// <returns><see langword="true"/> when coordinates are equal; otherwise <see langword="false"/>.</returns>
    public bool Equals(GridPoint other) => X == other.X && Y == other.Y;
    /// <summary>
    /// Determines whether this point equals another object.
    /// </summary>
    /// <param name="obj">The object to compare.</param>
    /// <returns><see langword="true"/> when <paramref name="obj"/> is an equal <see cref="GridPoint"/>.</returns>
    public override bool Equals(object? obj) => obj is GridPoint other && Equals(other);
    /// <summary>
    /// Returns the hash code for this point.
    /// </summary>
    /// <returns>A hash code representing this point.</returns>
    public override int GetHashCode() => HashCode.Combine(X, Y);
    /// <summary>
    /// Returns a string representation of this point.
    /// </summary>
    /// <returns>The formatted coordinate text.</returns>
    public override string ToString() => $"({X}, {Y})";

    /// <summary>
    /// Converts a linear tile index into grid coordinates.
    /// </summary>
    /// <param name="index">The tile index.</param>
    /// <param name="mapWidth">The map width used for indexing.</param>
    /// <returns>The corresponding grid point.</returns>
    public static GridPoint FromIndex(int index, int mapWidth) => new(index % mapWidth, index / mapWidth);
    /// <summary>
    /// Converts this point into a linear tile index.
    /// </summary>
    /// <param name="mapWidth">The map width used for indexing.</param>
    /// <returns>The linear index for this coordinate.</returns>
    public int ToIndex(int mapWidth) => Y * mapWidth + X;
}
