using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

public class GridPointTests
{
    [Fact]
    public void Zero_ReturnsOrigin()
    {
        Assert.Equal(new GridPoint(0, 0), GridPoint.Zero);
    }

    [Fact]
    public void EqualityMembers_ReturnTrueForSameCoordinates()
    {
        var a = new GridPoint(3, -2);
        var b = new GridPoint(3, -2);

        Assert.True(a == b);
        Assert.False(a != b);
        Assert.True(a.Equals(b));
        Assert.True(a.Equals((object)b));
    }

    [Fact]
    public void EqualityMembers_ReturnFalseForDifferentCoordinates()
    {
        var a = new GridPoint(3, -2);
        var b = new GridPoint(3, -1);

        Assert.False(a == b);
        Assert.True(a != b);
        Assert.False(a.Equals(b));
        Assert.False(a.Equals((object)b));
    }

    [Fact]
    public void GetHashCode_EqualPointsProduceSameHashAndDeduplicateInHashSet()
    {
        var a = new GridPoint(-7, 11);
        var b = new GridPoint(-7, 11);

        Assert.Equal(a.GetHashCode(), b.GetHashCode());

        var set = new HashSet<GridPoint> { a, b };
        Assert.Single(set);
    }

    [Fact]
    public void ArithmeticOperators_ReturnExpectedCoordinates()
    {
        var a = new GridPoint(4, -3);
        var b = new GridPoint(-2, 5);

        Assert.Equal(new GridPoint(2, 2), a + b);
        Assert.Equal(new GridPoint(6, -8), a - b);
        Assert.Equal(new GridPoint(-8, 20), b * 4);
    }

    [Fact]
    public void ManhattanDistance_ComputesAbsoluteGridDistanceIncludingNegativeCoordinates()
    {
        var a = new GridPoint(-2, 5);
        var b = new GridPoint(4, -1);

        Assert.Equal(12, a.ManhattanDistance(b));
        Assert.Equal(12, b.ManhattanDistance(a));
    }

    [Fact]
    public void EuclideanDistance_ComputesPythagoreanDistance()
    {
        var a = new GridPoint(-1, -1);
        var b = new GridPoint(2, 3);

        Assert.Equal(5.0, a.EuclideanDistance(b), 10);
        Assert.Equal(5.0, b.EuclideanDistance(a), 10);
    }

    [Fact]
    public void NeighborGeneration_UsingCardinalOffsetsProducesOrthogonalNeighbors()
    {
        var center = new GridPoint(10, 20);
        var offsets = new[]
        {
            new GridPoint(1, 0),
            new GridPoint(-1, 0),
            new GridPoint(0, 1),
            new GridPoint(0, -1),
        };

        var neighbors = new HashSet<GridPoint>();
        foreach (var offset in offsets)
            neighbors.Add(center + offset);

        Assert.Equal(4, neighbors.Count);
        Assert.Contains(new GridPoint(11, 20), neighbors);
        Assert.Contains(new GridPoint(9, 20), neighbors);
        Assert.Contains(new GridPoint(10, 21), neighbors);
        Assert.Contains(new GridPoint(10, 19), neighbors);
    }

    [Fact]
    public void IndexConversion_RoundTripsPointForGivenMapWidth()
    {
        var original = new GridPoint(6, 4);
        int mapWidth = 12;

        int index = original.ToIndex(mapWidth);
        var roundTrip = GridPoint.FromIndex(index, mapWidth);

        Assert.Equal(54, index);
        Assert.Equal(original, roundTrip);
    }

    [Fact]
    public void ToString_FormatsCoordinatesWithParenthesesAndComma()
    {
        var point = new GridPoint(-4, 9);

        Assert.Equal("(-4, 9)", point.ToString());
    }
}
