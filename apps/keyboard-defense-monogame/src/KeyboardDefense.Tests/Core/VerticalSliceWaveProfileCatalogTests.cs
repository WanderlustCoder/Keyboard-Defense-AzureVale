using System.IO;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

[Collection("VerticalSliceWaveDataSerial")]
public sealed class VerticalSliceWaveProfileCatalogTests
{
    [Fact]
    public void Catalog_ContainsExpectedNamedProfiles()
    {
        VerticalSliceWaveData.LoadData(GetDataDirectory());

        Assert.Equal("campaign_intro", VerticalSliceWaveData.GetProfile("campaign_intro").ProfileId);
        Assert.Equal("campaign_elite", VerticalSliceWaveData.GetProfile("campaign_elite").ProfileId);
        Assert.Equal("campaign_boss", VerticalSliceWaveData.GetProfile("campaign_boss").ProfileId);
    }

    [Fact]
    public void Catalog_ResolvesExplicitNodeMappings()
    {
        VerticalSliceWaveData.LoadData(GetDataDirectory());

        Assert.Equal("campaign_intro", VerticalSliceWaveData.ResolveProfileIdForNode("forest-gate"));
        Assert.Equal("campaign_elite", VerticalSliceWaveData.ResolveProfileIdForNode("citadel-rise"));
        Assert.Equal("campaign_boss", VerticalSliceWaveData.ResolveProfileIdForNode("the-nexus"));
    }

    [Fact]
    public void Catalog_ResolvesHeuristicFallbacks_ForUnmappedNodes()
    {
        VerticalSliceWaveData.LoadData(GetDataDirectory());

        Assert.Equal("campaign_boss", VerticalSliceWaveData.ResolveProfileIdForNode("custom-boss-lane"));
        Assert.Equal("campaign_elite", VerticalSliceWaveData.ResolveProfileIdForNode("custom-elite-lane"));
        Assert.Equal("campaign_intro", VerticalSliceWaveData.ResolveProfileIdForNode("start-gate-01"));
        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode("custom-mid-node"));
    }

    private static string GetDataDirectory()
    {
        return Path.Combine(AppContext.BaseDirectory, "data");
    }
}
