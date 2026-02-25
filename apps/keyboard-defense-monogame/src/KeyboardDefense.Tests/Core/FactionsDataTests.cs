using System.Collections.Generic;
using System.IO;
using System.Linq;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class FactionsDataTests
{
    private static readonly Dictionary<string, int> ExpectedBaseRelations = new()
    {
        ["northern_tribes"] = -10,
        ["merchant_guild"] = 20,
        ["forest_clans"] = 0,
        ["mountain_kingdom"] = 5,
        ["coastal_federation"] = 10,
    };

    [Fact]
    public void LoadData_ProjectData_LoadsExpectedFactionCountAndIds()
    {
        LoadFromProjectData();

        var ids = FactionsData.GetFactionIds().OrderBy(id => id).ToList();

        Assert.Equal(5, ids.Count);
        Assert.Equal(
            new[]
            {
                "coastal_federation",
                "forest_clans",
                "merchant_guild",
                "mountain_kingdom",
                "northern_tribes",
            },
            ids);
    }

    [Fact]
    public void GetFaction_KnownFaction_ReturnsExpectedDefinition()
    {
        LoadFromProjectData();

        var faction = FactionsData.GetFaction("merchant_guild");

        Assert.NotNull(faction);
        Assert.Equal("merchant_guild", faction!.Id);
        Assert.Equal("Merchant Guild", faction.Name);
        Assert.Equal("mercantile", faction.Personality);
        Assert.Equal(20, faction.BaseRelation);
    }

    [Fact]
    public void GetFactionName_KnownAndUnknown_ReturnsNameOrId()
    {
        LoadFromProjectData();

        Assert.Equal("Northern Tribes", FactionsData.GetFactionName("northern_tribes"));
        Assert.Equal("unknown_faction", FactionsData.GetFactionName("unknown_faction"));
    }

    [Fact]
    public void InitFactionState_SeedsDefaultReputationValuesFromData()
    {
        LoadFromProjectData();
        var state = new GameState();

        FactionsData.InitFactionState(state);

        Assert.Equal(ExpectedBaseRelations.Count, state.FactionRelations.Count);
        foreach (var (factionId, expectedRelation) in ExpectedBaseRelations)
            Assert.Equal(expectedRelation, state.FactionRelations[factionId]);
    }

    [Fact]
    public void GetRelation_UnknownFaction_ReturnsZeroByDefault()
    {
        var state = new GameState();

        int relation = FactionsData.GetRelation(state, "missing_faction");

        Assert.Equal(0, relation);
    }

    [Fact]
    public void SetRelation_AndChangeRelation_ClampBetweenMinus100And100()
    {
        var state = new GameState();

        FactionsData.SetRelation(state, "merchant_guild", 999);
        Assert.Equal(100, FactionsData.GetRelation(state, "merchant_guild"));

        FactionsData.ChangeRelation(state, "merchant_guild", -250);
        Assert.Equal(-100, FactionsData.GetRelation(state, "merchant_guild"));
    }

    [Fact]
    public void RelationStatusThresholds_MapToExpectedLabels()
    {
        Assert.Equal("hostile", FactionsData.GetRelationStatus(-50));
        Assert.Equal("unfriendly", FactionsData.GetRelationStatus(-20));
        Assert.Equal("neutral", FactionsData.GetRelationStatus(20));
        Assert.Equal("friendly", FactionsData.GetRelationStatus(50));
        Assert.Equal("allied", FactionsData.GetRelationStatus(80));
    }

    [Fact]
    public void IsHostile_IsAllied_AndDailyDecay_UseCurrentRelations()
    {
        LoadFromProjectData();
        var state = new GameState();
        FactionsData.InitFactionState(state);

        FactionsData.SetRelation(state, "merchant_guild", 85);
        Assert.True(FactionsData.IsAllied(state, "merchant_guild"));
        Assert.False(FactionsData.IsHostile(state, "merchant_guild"));

        FactionsData.SetRelation(state, "northern_tribes", -60);
        Assert.True(FactionsData.IsHostile(state, "northern_tribes"));
        Assert.False(FactionsData.IsAllied(state, "northern_tribes"));

        FactionsData.ApplyDailyDecay(state);

        Assert.Equal(84, FactionsData.GetRelation(state, "merchant_guild"));
        Assert.Equal(-59, FactionsData.GetRelation(state, "northern_tribes"));
    }

    private static void LoadFromProjectData()
    {
        string? dataDir = FindDataDirectory();
        Assert.False(string.IsNullOrWhiteSpace(dataDir), "Could not locate data directory containing factions.json.");
        FactionsData.LoadData(dataDir!);
    }

    private static string? FindDataDirectory()
    {
        string dir = AppContext.BaseDirectory;
        for (int i = 0; i < 10; i++)
        {
            string candidate = Path.Combine(dir, "data");
            if (File.Exists(Path.Combine(candidate, "factions.json")))
                return candidate;

            string parent = Path.GetDirectoryName(dir) ?? dir;
            if (parent == dir) break;
            dir = parent;
        }

        return null;
    }
}
