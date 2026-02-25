using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

[Collection("StaticData")]
public class FactionReputationTests
{
    private static readonly Lazy<IReadOnlyDictionary<string, FactionSnapshot>> FactionSnapshots =
        new(LoadFactionSnapshots, true);

    [Fact]
    public void ReputationGainAndLoss_ChangeRelationAppliesDeltaAndClamp()
    {
        var state = CreateState();

        FactionsData.SetRelation(state, "forest_clans", 0);
        FactionsData.ChangeRelation(state, "forest_clans", 35);
        Assert.Equal(35, FactionsData.GetRelation(state, "forest_clans"));

        FactionsData.ChangeRelation(state, "forest_clans", -80);
        Assert.Equal(-45, FactionsData.GetRelation(state, "forest_clans"));

        FactionsData.ChangeRelation(state, "forest_clans", -1000);
        Assert.Equal(-100, FactionsData.GetRelation(state, "forest_clans"));

        FactionsData.ChangeRelation(state, "forest_clans", 500);
        Assert.Equal(100, FactionsData.GetRelation(state, "forest_clans"));
    }

    [Fact]
    public void StandingThresholds_RelationValuesMapToExpectedLabels()
    {
        Assert.Equal("hostile", FactionsData.GetRelationStatus(-100));
        Assert.Equal("hostile", FactionsData.GetRelationStatus(-50));
        Assert.Equal("unfriendly", FactionsData.GetRelationStatus(-49));
        Assert.Equal("unfriendly", FactionsData.GetRelationStatus(-20));
        Assert.Equal("neutral", FactionsData.GetRelationStatus(-19));
        Assert.Equal("neutral", FactionsData.GetRelationStatus(20));
        Assert.Equal("friendly", FactionsData.GetRelationStatus(21));
        Assert.Equal("friendly", FactionsData.GetRelationStatus(50));
        Assert.Equal("allied", FactionsData.GetRelationStatus(51));
    }

    [Fact]
    public void StandingProgression_CrossingThresholdsUpdatesStanding()
    {
        var state = CreateState();
        const string factionId = "mountain_kingdom";

        FactionsData.SetRelation(state, factionId, 50);
        Assert.Equal("friendly", FactionsData.GetRelationStatus(FactionsData.GetRelation(state, factionId)));

        FactionsData.ChangeRelation(state, factionId, 1);
        Assert.Equal("allied", FactionsData.GetRelationStatus(FactionsData.GetRelation(state, factionId)));

        FactionsData.ChangeRelation(state, factionId, -71);
        Assert.Equal("unfriendly", FactionsData.GetRelationStatus(FactionsData.GetRelation(state, factionId)));
    }

    [Fact]
    public void FactionSpecificRewards_HigherStandingReducesTributeDemandForSameFaction()
    {
        var state = CreateState();
        state.Day = 1;
        var faction = GetFactionSnapshot("merchant_guild");

        FactionsData.SetRelation(state, faction.Id, -30);
        int lowStandingDemand = CalculateTributeDemand(state, faction);

        FactionsData.SetRelation(state, faction.Id, 20);
        int neutralStandingDemand = CalculateTributeDemand(state, faction);

        FactionsData.SetRelation(state, faction.Id, 60);
        int highStandingDemand = CalculateTributeDemand(state, faction);

        Assert.Equal(39, lowStandingDemand);
        Assert.Equal(30, neutralStandingDemand);
        Assert.Equal(21, highStandingDemand);
        Assert.True(lowStandingDemand > neutralStandingDemand);
        Assert.True(neutralStandingDemand > highStandingDemand);
    }

    [Fact]
    public void FactionSpecificRewards_DifferentFactionsYieldDifferentTributeAtSameStanding()
    {
        var state = CreateState();
        state.Day = 5;
        var merchantGuild = GetFactionSnapshot("merchant_guild");
        var northernTribes = GetFactionSnapshot("northern_tribes");

        FactionsData.SetRelation(state, merchantGuild.Id, 60);
        FactionsData.SetRelation(state, northernTribes.Id, 60);

        int merchantTribute = CalculateTributeDemand(state, merchantGuild);
        int northernTribute = CalculateTributeDemand(state, northernTribes);

        Assert.Equal(25, merchantTribute);
        Assert.Equal(42, northernTribute);
        Assert.True(merchantTribute < northernTribute);
    }

    [Fact]
    public void ReputationDecay_OverDaysDriftsTowardFactionBaseRelation()
    {
        var state = CreateState();

        FactionsData.SetRelation(state, "merchant_guild", 26); // Base is 20.
        FactionsData.SetRelation(state, "northern_tribes", -14); // Base is -10.

        for (int i = 0; i < 3; i++)
            FactionsData.ApplyDailyDecay(state);

        Assert.Equal(23, FactionsData.GetRelation(state, "merchant_guild"));
        Assert.Equal(-11, FactionsData.GetRelation(state, "northern_tribes"));
    }

    [Fact]
    public void ReputationDecay_ReachesBaseAndDoesNotOvershoot()
    {
        var state = CreateState();
        const string factionId = "coastal_federation"; // Base is 10.
        FactionsData.SetRelation(state, factionId, 40);

        for (int i = 0; i < 100; i++)
            FactionsData.ApplyDailyDecay(state);

        Assert.Equal(10, FactionsData.GetRelation(state, factionId));
    }

    [Fact]
    public void FactionRelationships_IsAlliedAndIsHostileTrackThresholds()
    {
        var state = CreateState();
        const string factionId = "forest_clans";

        FactionsData.SetRelation(state, factionId, FactionsData.RelationAllied);
        Assert.True(FactionsData.IsAllied(state, factionId));
        Assert.False(FactionsData.IsHostile(state, factionId));

        FactionsData.SetRelation(state, factionId, FactionsData.RelationHostile);
        Assert.True(FactionsData.IsHostile(state, factionId));
        Assert.False(FactionsData.IsAllied(state, factionId));
    }

    [Fact]
    public void TradePrices_BetterReputationImprovesFactionPriceMultiplier()
    {
        var state = CreateState();
        var faction = GetFactionSnapshot("merchant_guild");

        FactionsData.SetRelation(state, faction.Id, -30);
        double hostilePrice = CalculateTradePriceMultiplier(state, faction);

        FactionsData.SetRelation(state, faction.Id, 60);
        state.FactionAgreements["trade"].Add(faction.Id);
        double friendlyTradePrice = CalculateTradePriceMultiplier(state, faction);

        Assert.Equal(0.88, hostilePrice, 2);
        Assert.Equal(0.646, friendlyTradePrice, 3);
        Assert.True(friendlyTradePrice < hostilePrice);
    }

    [Fact]
    public void TradePrices_FactionTradeModifiersDifferAtSameReputation()
    {
        var state = CreateState();
        var merchantGuild = GetFactionSnapshot("merchant_guild");
        var northernTribes = GetFactionSnapshot("northern_tribes");

        FactionsData.SetRelation(state, merchantGuild.Id, 20);
        FactionsData.SetRelation(state, northernTribes.Id, 20);

        double merchantPrice = CalculateTradePriceMultiplier(state, merchantGuild);
        double northernPrice = CalculateTradePriceMultiplier(state, northernTribes);

        Assert.Equal(0.8, merchantPrice, 3);
        Assert.Equal(1.2, northernPrice, 3);
        Assert.True(merchantPrice < northernPrice);
    }

    private static GameState CreateState(string seed = "faction_reputation_tests")
    {
        string dataDir = ResolveDataDirectory();
        FactionsData.LoadData(dataDir);
        var state = DefaultState.Create(seed);
        FactionsData.InitFactionState(state);
        return state;
    }

    private static FactionSnapshot GetFactionSnapshot(string factionId)
    {
        Assert.True(FactionSnapshots.Value.TryGetValue(factionId, out var faction), $"Missing faction '{factionId}' in factions.json.");
        return faction!;
    }

    private static int CalculateTributeDemand(GameState state, FactionSnapshot faction)
    {
        double dayMultiplier = 1.0 + (state.Day - 1) * 0.05;
        int relation = FactionsData.GetRelation(state, faction.Id);
        double relationMultiplier = 1.0;

        if (relation >= FactionsData.RelationFriendly)
            relationMultiplier = 0.7;
        else if (relation < FactionsData.RelationUnfriendly)
            relationMultiplier = 1.3;

        return (int)(faction.TributeBase * dayMultiplier * relationMultiplier);
    }

    private static double CalculateTradePriceMultiplier(GameState state, FactionSnapshot faction)
    {
        double multiplier = faction.TradeModifier;

        if (state.FactionAgreements.TryGetValue("trade", out List<string>? tradeAgreements) &&
            tradeAgreements.Contains(faction.Id))
        {
            multiplier *= 0.85;
        }

        int relation = FactionsData.GetRelation(state, faction.Id);
        if (relation >= FactionsData.RelationFriendly)
            multiplier *= 0.95;
        else if (relation < FactionsData.RelationUnfriendly)
            multiplier *= 1.1;

        return Math.Round(multiplier, 3);
    }

    private static IReadOnlyDictionary<string, FactionSnapshot> LoadFactionSnapshots()
    {
        string dataDir = ResolveDataDirectory();
        string factionsPath = Path.Combine(dataDir, "factions.json");
        using JsonDocument doc = JsonDocument.Parse(File.ReadAllText(factionsPath));

        var factionsNode = doc.RootElement.GetProperty("factions");
        var snapshots = new Dictionary<string, FactionSnapshot>(StringComparer.Ordinal);
        foreach (JsonProperty factionProperty in factionsNode.EnumerateObject())
        {
            string id = factionProperty.Name;
            JsonElement faction = factionProperty.Value;
            snapshots[id] = new FactionSnapshot(
                id,
                faction.GetProperty("trade_modifier").GetDouble(),
                faction.GetProperty("tribute_base").GetInt32());
        }

        return snapshots;
    }

    private static string ResolveDataDirectory()
    {
        string? dir = AppContext.BaseDirectory;
        for (int i = 0; i < 12 && !string.IsNullOrWhiteSpace(dir); i++)
        {
            string candidate = Path.Combine(dir!, "data");
            if (File.Exists(Path.Combine(candidate, "factions.json")))
                return candidate;

            dir = Directory.GetParent(dir!)?.FullName;
        }

        throw new DirectoryNotFoundException("Could not locate data/factions.json from test base directory.");
    }

    private sealed record FactionSnapshot(
        string Id,
        double TradeModifier,
        int TributeBase);
}
