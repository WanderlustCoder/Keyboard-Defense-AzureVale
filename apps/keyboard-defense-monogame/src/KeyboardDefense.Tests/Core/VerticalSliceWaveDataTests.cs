using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

[Collection("VerticalSliceWaveDataSerial")]
public sealed class VerticalSliceWaveDataTests : IDisposable
{
    private readonly List<string> _tempDirs = new();

    [Fact]
    public void ResolveProfileIdForNode_UsesExplicitNodeMapping_WhenProfileExists()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro" }
          ],
          "node_profiles": {
            "custom-node": "campaign_intro"
          }
        }
        """;

        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("campaign_intro", VerticalSliceWaveData.ResolveProfileIdForNode("custom-node"));
    }

    [Fact]
    public void ResolveProfileIdForNode_UsesHeuristicProfiles_WhenAvailable()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro" },
            { "profile_id": "campaign_elite" },
            { "profile_id": "campaign_boss" }
          ]
        }
        """;

        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("campaign_boss", VerticalSliceWaveData.ResolveProfileIdForNode("frost-boss-1"));
        Assert.Equal("campaign_elite", VerticalSliceWaveData.ResolveProfileIdForNode("ember-elite-lane"));
        Assert.Equal("campaign_intro", VerticalSliceWaveData.ResolveProfileIdForNode("forest-gate"));
    }

    [Fact]
    public void ResolveProfileIdForNode_FallsBackToDefault_WhenMappedOrHeuristicProfileMissing()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro" }
          ],
          "node_profiles": {
            "boss-node": "campaign_boss"
          }
        }
        """;

        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode("boss-node"));
        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode("my-elite-path"));
        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode("the-boss-room"));
    }

    public void Dispose()
    {
        foreach (string dir in _tempDirs)
        {
            try
            {
                if (Directory.Exists(dir))
                    Directory.Delete(dir, recursive: true);
            }
            catch
            {
                // Best effort temp cleanup.
            }
        }
    }

    private string CreateTempDataDir(string profilesJson)
    {
        string dir = Path.Combine(
            Path.GetTempPath(),
            "KeyboardDefenseVerticalSliceWaveDataTests",
            Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        _tempDirs.Add(dir);

        File.WriteAllText(Path.Combine(dir, "vertical_slice_wave_profiles.json"), profilesJson);
        return dir;
    }
}
