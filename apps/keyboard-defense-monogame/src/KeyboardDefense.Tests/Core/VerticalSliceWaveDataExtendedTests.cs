using System;
using System.Collections.Generic;
using System.IO;
using KeyboardDefense.Core.Data;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for VerticalSliceWaveData — profile defaults, GetProfile fallback,
/// LoadData with missing/malformed JSON, clamping validation, profile collection loading,
/// and ResolveProfileIdForNode heuristic edge cases.
/// </summary>
[Collection("VerticalSliceWaveDataSerial")]
public sealed class VerticalSliceWaveDataExtendedTests : IDisposable
{
    private readonly List<string> _tempDirs = new();

    // =========================================================================
    // VerticalSliceWaveProfile.CreateDefault — field defaults
    // =========================================================================

    [Fact]
    public void CreateDefault_HasExpectedVersion()
    {
        var profile = VerticalSliceWaveProfile.CreateDefault();
        Assert.Equal("1.0.0", profile.Version);
    }

    [Fact]
    public void CreateDefault_HasExpectedProfileId()
    {
        var profile = VerticalSliceWaveProfile.CreateDefault();
        Assert.Equal("vertical_slice_default", profile.ProfileId);
    }

    [Fact]
    public void CreateDefault_HasExpectedDescription()
    {
        var profile = VerticalSliceWaveProfile.CreateDefault();
        Assert.Equal("Default single-wave profile", profile.Description);
    }

    [Fact]
    public void CreateDefault_HasExpectedStartState()
    {
        var profile = VerticalSliceWaveProfile.CreateDefault();
        Assert.Equal(1, profile.StartDay);
        Assert.Equal(20, profile.StartHp);
        Assert.Equal(10, profile.StartGold);
        Assert.Equal(0, profile.StartThreat);
        Assert.Equal("full_alpha", profile.LessonId);
        Assert.False(profile.PracticeMode);
    }

    [Fact]
    public void CreateDefault_HasExpectedWaveParams()
    {
        var profile = VerticalSliceWaveProfile.CreateDefault();
        Assert.Equal(32, profile.WaveSpawnTotal);
        Assert.Equal(2.5f, profile.SpawnIntervalSeconds, 0.01f);
        Assert.Equal(1.4f, profile.EnemyStepIntervalSeconds, 0.01f);
        Assert.Equal(1, profile.EnemyStepDistance);
        Assert.Equal(1, profile.EnemyContactDamage);
        Assert.Equal(2, profile.TypedHitDamage);
        Assert.Equal(1, profile.TypedMissDamage);
        Assert.Equal(1, profile.TowerTickDamage);
    }

    // =========================================================================
    // VerticalSliceWaveProfile — record equality
    // =========================================================================

    [Fact]
    public void Profile_RecordEquality_TwoDefaults_AreEqual()
    {
        var a = VerticalSliceWaveProfile.CreateDefault();
        var b = VerticalSliceWaveProfile.CreateDefault();
        Assert.Equal(a, b);
    }

    [Fact]
    public void Profile_WithModification_AreNotEqual()
    {
        var a = VerticalSliceWaveProfile.CreateDefault();
        var b = a with { StartHp = 99 };
        Assert.NotEqual(a, b);
        Assert.Equal(99, b.StartHp);
        Assert.Equal(20, a.StartHp);
    }

    // =========================================================================
    // Current — property
    // =========================================================================

    [Fact]
    public void Current_ReturnsDefaultProfile()
    {
        // Reset by loading empty dir
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        var current = VerticalSliceWaveData.Current;
        Assert.Equal("vertical_slice_default", current.ProfileId);
    }

    // =========================================================================
    // GetProfile — fallback behavior
    // =========================================================================

    [Fact]
    public void GetProfile_Null_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        var profile = VerticalSliceWaveData.GetProfile(null);
        Assert.Equal("vertical_slice_default", profile.ProfileId);
    }

    [Fact]
    public void GetProfile_EmptyString_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        var profile = VerticalSliceWaveData.GetProfile("");
        Assert.Equal("vertical_slice_default", profile.ProfileId);
    }

    [Fact]
    public void GetProfile_Whitespace_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        var profile = VerticalSliceWaveData.GetProfile("   ");
        Assert.Equal("vertical_slice_default", profile.ProfileId);
    }

    [Fact]
    public void GetProfile_UnknownId_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        var profile = VerticalSliceWaveData.GetProfile("nonexistent_profile");
        Assert.Equal("vertical_slice_default", profile.ProfileId);
    }

    [Fact]
    public void GetProfile_KnownId_ReturnsSpecificProfile()
    {
        const string json = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro", "start_state": { "hp": 30 } }
          ]
        }
        """;
        string dataDir = CreateTempDataDir(json);
        VerticalSliceWaveData.LoadData(dataDir);

        var profile = VerticalSliceWaveData.GetProfile("campaign_intro");
        Assert.Equal("campaign_intro", profile.ProfileId);
        Assert.Equal(30, profile.StartHp);
    }

    // =========================================================================
    // LoadData — missing file uses defaults
    // =========================================================================

    [Fact]
    public void LoadData_NoFiles_UsesDefaults()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        var current = VerticalSliceWaveData.Current;
        Assert.Equal("vertical_slice_default", current.ProfileId);
        Assert.Equal(20, current.StartHp);
    }

    [Fact]
    public void LoadData_NonexistentDirectory_UsesDefaults()
    {
        string fakeDir = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"));
        VerticalSliceWaveData.LoadData(fakeDir);

        var current = VerticalSliceWaveData.Current;
        Assert.Equal("vertical_slice_default", current.ProfileId);
    }

    // =========================================================================
    // LoadData — single wave file (vertical_slice_wave.json)
    // =========================================================================

    [Fact]
    public void LoadData_ValidSingleWaveFile_OverridesDefaults()
    {
        string dataDir = CreateTempDataDir(null);
        string waveJson = """
        {
          "version": "2.0.0",
          "start_state": { "hp": 50, "gold": 100, "day": 5, "threat": 3 },
          "wave": { "spawn_total": 10, "enemy_contact_damage": 5 }
        }
        """;
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"), waveJson);
        VerticalSliceWaveData.LoadData(dataDir);

        var current = VerticalSliceWaveData.Current;
        Assert.Equal("2.0.0", current.Version);
        Assert.Equal(50, current.StartHp);
        Assert.Equal(100, current.StartGold);
        Assert.Equal(5, current.StartDay);
        Assert.Equal(3, current.StartThreat);
        Assert.Equal(10, current.WaveSpawnTotal);
        Assert.Equal(5, current.EnemyContactDamage);
    }

    [Fact]
    public void LoadData_MalformedJson_FallsBackToDefaults()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"), "{{not valid json}}");
        VerticalSliceWaveData.LoadData(dataDir);

        var current = VerticalSliceWaveData.Current;
        Assert.Equal("vertical_slice_default", current.ProfileId);
        Assert.Equal(20, current.StartHp);
    }

    // =========================================================================
    // LoadData — clamping validation
    // =========================================================================

    [Fact]
    public void LoadData_HpBelowMin_ClampedToOne()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "start_state": { "hp": -5 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(1, VerticalSliceWaveData.Current.StartHp);
    }

    [Fact]
    public void LoadData_HpAboveMax_ClampedTo999()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "start_state": { "hp": 99999 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(999, VerticalSliceWaveData.Current.StartHp);
    }

    [Fact]
    public void LoadData_DayBelowMin_ClampedToOne()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "start_state": { "day": 0 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(1, VerticalSliceWaveData.Current.StartDay);
    }

    [Fact]
    public void LoadData_SpawnTotalBelowMin_ClampedToOne()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "wave": { "spawn_total": 0 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(1, VerticalSliceWaveData.Current.WaveSpawnTotal);
    }

    [Fact]
    public void LoadData_SpawnTotalAboveMax_ClampedTo128()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "wave": { "spawn_total": 500 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(128, VerticalSliceWaveData.Current.WaveSpawnTotal);
    }

    [Fact]
    public void LoadData_SpawnIntervalBelowMin_ClampedTo01()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "wave": { "spawn_interval_sec": 0.001 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(0.1f, VerticalSliceWaveData.Current.SpawnIntervalSeconds, 0.01f);
    }

    [Fact]
    public void LoadData_SpawnIntervalAboveMax_ClampedTo10()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "wave": { "spawn_interval_sec": 99.0 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(10f, VerticalSliceWaveData.Current.SpawnIntervalSeconds, 0.01f);
    }

    [Fact]
    public void LoadData_GoldBelowMin_ClampedToZero()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "start_state": { "gold": -100 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(0, VerticalSliceWaveData.Current.StartGold);
    }

    [Fact]
    public void LoadData_ThreatClampedToRange()
    {
        string dataDir = CreateTempDataDir(null);
        File.WriteAllText(Path.Combine(dataDir, "vertical_slice_wave.json"),
            """{ "start_state": { "threat": 200 } }""");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal(99, VerticalSliceWaveData.Current.StartThreat);
    }

    // =========================================================================
    // LoadData — profile collection
    // =========================================================================

    [Fact]
    public void LoadData_ProfileCollection_MultipleProfilesLoaded()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro", "start_state": { "hp": 15 } },
            { "profile_id": "campaign_boss", "start_state": { "hp": 50 } }
          ]
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        var intro = VerticalSliceWaveData.GetProfile("campaign_intro");
        var boss = VerticalSliceWaveData.GetProfile("campaign_boss");

        Assert.Equal(15, intro.StartHp);
        Assert.Equal(50, boss.StartHp);
    }

    [Fact]
    public void LoadData_ProfileCollection_EmptyProfilesArray_NoError()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": []
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        // Should still have default
        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.Current.ProfileId);
    }

    [Fact]
    public void LoadData_ProfileCollection_SkipsProfilesWithoutId()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "start_state": { "hp": 99 } },
            { "profile_id": "valid_one", "start_state": { "hp": 42 } }
          ]
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        var valid = VerticalSliceWaveData.GetProfile("valid_one");
        Assert.Equal(42, valid.StartHp);
    }

    [Fact]
    public void LoadData_ProfileCollection_MalformedProfilesJson_KeepsDefaults()
    {
        string dataDir = CreateTempDataDir("{{malformed}}");
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.Current.ProfileId);
    }

    // =========================================================================
    // ResolveProfileIdForNode — extended heuristics
    // =========================================================================

    [Fact]
    public void ResolveProfileIdForNode_NullInput_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode(null!));
    }

    [Fact]
    public void ResolveProfileIdForNode_EmptyString_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode(""));
    }

    [Fact]
    public void ResolveProfileIdForNode_WhitespaceOnly_ReturnsDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode("   "));
    }

    [Fact]
    public void ResolveProfileIdForNode_StartHeuristic_MatchesCampaignIntro()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro" }
          ]
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("campaign_intro", VerticalSliceWaveData.ResolveProfileIdForNode("village-start-zone"));
    }

    [Fact]
    public void ResolveProfileIdForNode_ExplicitMapping_TakesPriorityOverHeuristic()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro" },
            { "profile_id": "campaign_boss" }
          ],
          "node_profiles": {
            "intro-boss-node": "campaign_boss"
          }
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        // Node name contains both "intro" and "boss", but explicit mapping wins
        Assert.Equal("campaign_boss", VerticalSliceWaveData.ResolveProfileIdForNode("intro-boss-node"));
    }

    [Fact]
    public void ResolveProfileIdForNode_CaseInsensitive_NodeId()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_boss" }
          ]
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("campaign_boss", VerticalSliceWaveData.ResolveProfileIdForNode("DARK-BOSS-LAIR"));
    }

    [Fact]
    public void ResolveProfileIdForNode_NoMatchingProfile_FallsBackToDefault()
    {
        string dataDir = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir);

        Assert.Equal("vertical_slice_default", VerticalSliceWaveData.ResolveProfileIdForNode("random-node-123"));
    }

    [Fact]
    public void ResolveProfileIdForNode_ExplicitMappingToMissingProfile_FallsBackToDefault()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_intro" }
          ],
          "node_profiles": {
            "special-node": "deleted_profile"
          }
        }
        """;
        string dataDir = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir);

        // Explicit mapping exists but target profile doesn't — should fall through to heuristic then default
        string resolved = VerticalSliceWaveData.ResolveProfileIdForNode("special-node");
        Assert.Equal("vertical_slice_default", resolved);
    }

    // =========================================================================
    // LoadData called twice — resets state
    // =========================================================================

    [Fact]
    public void LoadData_CalledTwice_ResetsProfiles()
    {
        const string profilesJson = """
        {
          "version": "1.0.0",
          "profiles": [
            { "profile_id": "campaign_boss", "start_state": { "hp": 99 } }
          ]
        }
        """;
        string dataDir1 = CreateTempDataDir(profilesJson);
        VerticalSliceWaveData.LoadData(dataDir1);
        Assert.Equal(99, VerticalSliceWaveData.GetProfile("campaign_boss").StartHp);

        // Load from empty directory
        string dataDir2 = CreateTempDataDir(null);
        VerticalSliceWaveData.LoadData(dataDir2);

        // campaign_boss should no longer exist
        var profile = VerticalSliceWaveData.GetProfile("campaign_boss");
        Assert.Equal("vertical_slice_default", profile.ProfileId);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    public void Dispose()
    {
        foreach (string dir in _tempDirs)
        {
            try
            {
                if (Directory.Exists(dir))
                    Directory.Delete(dir, recursive: true);
            }
            catch { }
        }
    }

    /// <summary>
    /// Creates a temp data directory. If profilesJson is not null,
    /// writes vertical_slice_wave_profiles.json into it.
    /// </summary>
    private string CreateTempDataDir(string? profilesJson)
    {
        string dir = Path.Combine(
            Path.GetTempPath(),
            "KeyboardDefenseVSWDExtTests",
            Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        _tempDirs.Add(dir);

        if (profilesJson != null)
            File.WriteAllText(Path.Combine(dir, "vertical_slice_wave_profiles.json"), profilesJson);

        return dir;
    }
}
