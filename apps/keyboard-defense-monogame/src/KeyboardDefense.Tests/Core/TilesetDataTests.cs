using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class TilesetDataTests
{
    // --- CardinalMaskToCornerWang ---

    [Fact]
    public void AllMatch_ReturnsWang0()
    {
        // Cardinal mask 15 = all neighbors match = all corners "lower" = wang 0
        Assert.Equal(0, TilesetData.CardinalMaskToCornerWang(15));
    }

    [Fact]
    public void NoneMatch_ReturnsWang15()
    {
        // Cardinal mask 0 = no neighbors match = all corners "upper" = wang 15
        Assert.Equal(15, TilesetData.CardinalMaskToCornerWang(0));
    }

    [Fact]
    public void NorthDifferent_NorthCornersUpper()
    {
        // Cardinal mask 14 = E+S+W match, N different
        // NE corner: N is diff → upper (bit 2 = 4)
        // NW corner: N is diff → upper (bit 3 = 8)
        // SE corner: S+E both match → lower
        // SW corner: S+W both match → lower
        // wang = 0 + 0 + 4 + 8 = 12
        Assert.Equal(12, TilesetData.CardinalMaskToCornerWang(14));
    }

    [Fact]
    public void SouthDifferent_SouthCornersUpper()
    {
        // Cardinal mask 11 = N+E+W match, S different (N=1, E=2, W=8 = 11)
        // SE: S diff → upper
        // SW: S diff → upper
        // NE: N+E match → lower
        // NW: N+W match → lower
        // wang = 1 + 2 + 0 + 0 = 3
        Assert.Equal(3, TilesetData.CardinalMaskToCornerWang(11));
    }

    [Fact]
    public void EastDifferent_EastCornersUpper()
    {
        // Cardinal mask 13 = N+S+W match, E different (N=1, S=4, W=8 = 13)
        // SE: E diff → upper
        // NE: E diff → upper
        // SW: S+W match → lower
        // NW: N+W match → lower
        // wang = 1 + 0 + 4 + 0 = 5
        Assert.Equal(5, TilesetData.CardinalMaskToCornerWang(13));
    }

    [Fact]
    public void WestDifferent_WestCornersUpper()
    {
        // Cardinal mask 7 = N+E+S match, W different (N=1, E=2, S=4 = 7)
        // SW: W diff → upper
        // NW: W diff → upper
        // SE: S+E match → lower
        // NE: N+E match → lower
        // wang = 0 + 2 + 0 + 8 = 10
        Assert.Equal(10, TilesetData.CardinalMaskToCornerWang(7));
    }

    [Fact]
    public void NorthAndEast_Match_OnlyNECornerLower()
    {
        // Cardinal mask 3 = N+E match, S+W different
        // NE: N+E both match → lower
        // NW: N match but W diff → upper
        // SE: E match but S diff → upper
        // SW: S+W both diff → upper
        // wang = 1 + 2 + 0 + 8 = 11
        Assert.Equal(11, TilesetData.CardinalMaskToCornerWang(3));
    }

    [Fact]
    public void SouthAndWest_Match_OnlySWCornerLower()
    {
        // Cardinal mask 12 = S+W match, N+E different (S=4, W=8 = 12)
        // SW: S+W both match → lower
        // SE: S match but E diff → upper
        // NE: N+E both diff → upper
        // NW: W match but N diff → upper
        // wang = 1 + 0 + 4 + 8 = 13
        Assert.Equal(13, TilesetData.CardinalMaskToCornerWang(12));
    }

    [Fact]
    public void OppositeNS_Match_AllCornersUpper()
    {
        // Cardinal mask 5 = N+S match, E+W different (N=1, S=4 = 5)
        // Every corner has at least one different adjacent cardinal
        // NE: N match, E diff → upper
        // NW: N match, W diff → upper
        // SE: S match, E diff → upper
        // SW: S match, W diff → upper
        // wang = 15
        Assert.Equal(15, TilesetData.CardinalMaskToCornerWang(5));
    }

    [Fact]
    public void OppositeEW_Match_AllCornersUpper()
    {
        // Cardinal mask 10 = E+W match, N+S different (E=2, W=8 = 10)
        // wang = 15
        Assert.Equal(15, TilesetData.CardinalMaskToCornerWang(10));
    }

    [Fact]
    public void SingleNorth_AllCornersUpper()
    {
        // Cardinal mask 1 = only N matches
        // All corners have at least one different adjacent
        Assert.Equal(15, TilesetData.CardinalMaskToCornerWang(1));
    }

    // --- TilesetData source rect management ---

    [Fact]
    public void SetAndGetSourceRect()
    {
        var data = new TilesetData();
        data.SetTileRect(0, 32, 16, 16, 16);
        var rect = data.GetSourceRect(0);
        Assert.NotNull(rect);
        Assert.Equal(32, rect!.X);
        Assert.Equal(16, rect.Y);
        Assert.Equal(16, rect.Width);
        Assert.Equal(16, rect.Height);
    }

    [Fact]
    public void MissingWangId_ReturnsNull()
    {
        var data = new TilesetData();
        Assert.Null(data.GetSourceRect(7));
    }

    [Fact]
    public void Count_TracksRegisteredTiles()
    {
        var data = new TilesetData();
        Assert.Equal(0, data.Count);
        data.SetTileRect(0, 0, 0, 16, 16);
        data.SetTileRect(5, 48, 32, 16, 16);
        Assert.Equal(2, data.Count);
    }

    [Fact]
    public void AllWangIds_Registered()
    {
        var data = new TilesetData();
        for (int i = 0; i < 16; i++)
            data.SetTileRect(i, (i % 4) * 16, (i / 4) * 16, 16, 16);
        Assert.Equal(16, data.Count);
        for (int i = 0; i < 16; i++)
            Assert.NotNull(data.GetSourceRect(i));
    }

    // --- Full wang lookup table validation ---

    [Theory]
    [InlineData(0, 15)]  // No neighbors match → all corners upper
    [InlineData(1, 15)]  // Only N → still all upper
    [InlineData(2, 15)]  // Only E → still all upper
    [InlineData(3, 11)]  // N+E → NE lower, rest upper
    [InlineData(4, 15)]  // Only S → all upper
    [InlineData(5, 15)]  // N+S opposite → all upper
    [InlineData(6, 14)]  // E+S → SE lower, rest upper
    [InlineData(7, 10)]  // N+E+S → SE+NE lower, SW+NW upper
    [InlineData(8, 15)]  // Only W → all upper
    [InlineData(9, 7)]   // N+W → NW lower, rest upper
    [InlineData(10, 15)] // E+W opposite → all upper
    [InlineData(11, 3)]  // N+E+W → NE+NW lower, SE+SW upper
    [InlineData(12, 13)] // S+W → SW lower, rest upper
    [InlineData(13, 5)]  // N+S+W → NW+SW lower, NE+SE upper
    [InlineData(14, 12)] // E+S+W → SE+SW lower, NE+NW upper
    [InlineData(15, 0)]  // All match → all corners lower
    public void CardinalToWang_FullTable(int cardinal, int expectedWang)
    {
        Assert.Equal(expectedWang, TilesetData.CardinalMaskToCornerWang(cardinal));
    }
}
