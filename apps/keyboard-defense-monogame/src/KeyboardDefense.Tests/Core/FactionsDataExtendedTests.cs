using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for FactionsData — relation boundary thresholds, status transitions,
/// daily decay edge cases, clamping, and FactionDef defaults.
/// </summary>
[Collection("StaticData")]
public class FactionsDataExtendedTests
{
    // =========================================================================
    // Constants — relation thresholds
    // =========================================================================

    [Fact]
    public void RelationConstants_FormAscendingOrder()
    {
        Assert.True(FactionsData.RelationHostile < FactionsData.RelationUnfriendly);
        Assert.True(FactionsData.RelationUnfriendly < FactionsData.RelationNeutral);
        Assert.True(FactionsData.RelationNeutral < FactionsData.RelationFriendly);
        Assert.True(FactionsData.RelationFriendly < FactionsData.RelationAllied);
    }

    [Fact]
    public void RelationConstants_ExpectedValues()
    {
        Assert.Equal(-50, FactionsData.RelationHostile);
        Assert.Equal(-20, FactionsData.RelationUnfriendly);
        Assert.Equal(20, FactionsData.RelationNeutral);
        Assert.Equal(50, FactionsData.RelationFriendly);
        Assert.Equal(80, FactionsData.RelationAllied);
    }

    [Fact]
    public void RelationChangeConstants_AreExpected()
    {
        Assert.Equal(10, FactionsData.RelationChangeTrade);
        Assert.Equal(15, FactionsData.RelationChangeTribute);
        Assert.Equal(25, FactionsData.RelationChangeAlliance);
        Assert.Equal(-30, FactionsData.RelationChangeBrokenPact);
    }

    // =========================================================================
    // GetRelationStatus — boundary values
    // =========================================================================

    [Theory]
    [InlineData(-100, "hostile")]
    [InlineData(-51, "hostile")]
    [InlineData(-50, "hostile")]
    [InlineData(-49, "unfriendly")]
    [InlineData(-21, "unfriendly")]
    [InlineData(-20, "unfriendly")]
    [InlineData(-19, "neutral")]
    [InlineData(0, "neutral")]
    [InlineData(20, "neutral")]
    [InlineData(21, "friendly")]
    [InlineData(50, "friendly")]
    [InlineData(51, "allied")]
    [InlineData(80, "allied")]
    [InlineData(100, "allied")]
    public void GetRelationStatus_BoundaryValues(int relation, string expected)
    {
        Assert.Equal(expected, FactionsData.GetRelationStatus(relation));
    }

    // =========================================================================
    // SetRelation — clamping
    // =========================================================================

    [Theory]
    [InlineData(200, 100)]
    [InlineData(100, 100)]
    [InlineData(0, 0)]
    [InlineData(-100, -100)]
    [InlineData(-200, -100)]
    public void SetRelation_ClampsToRange(int input, int expected)
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test_faction", input);
        Assert.Equal(expected, FactionsData.GetRelation(state, "test_faction"));
    }

    // =========================================================================
    // ChangeRelation — accumulation and clamping
    // =========================================================================

    [Fact]
    public void ChangeRelation_PositiveDelta_Increases()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 0);
        FactionsData.ChangeRelation(state, "test", 25);
        Assert.Equal(25, FactionsData.GetRelation(state, "test"));
    }

    [Fact]
    public void ChangeRelation_NegativeDelta_Decreases()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 50);
        FactionsData.ChangeRelation(state, "test", -30);
        Assert.Equal(20, FactionsData.GetRelation(state, "test"));
    }

    [Fact]
    public void ChangeRelation_OverflowPositive_ClampsTo100()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 90);
        FactionsData.ChangeRelation(state, "test", 50);
        Assert.Equal(100, FactionsData.GetRelation(state, "test"));
    }

    [Fact]
    public void ChangeRelation_OverflowNegative_ClampsToMinus100()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", -80);
        FactionsData.ChangeRelation(state, "test", -50);
        Assert.Equal(-100, FactionsData.GetRelation(state, "test"));
    }

    [Fact]
    public void ChangeRelation_ZeroDelta_NoChange()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 42);
        FactionsData.ChangeRelation(state, "test", 0);
        Assert.Equal(42, FactionsData.GetRelation(state, "test"));
    }

    // =========================================================================
    // IsHostile / IsAllied — boundary
    // =========================================================================

    [Fact]
    public void IsHostile_AtThreshold_ReturnsTrue()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", -50);
        Assert.True(FactionsData.IsHostile(state, "test"));
    }

    [Fact]
    public void IsHostile_JustAboveThreshold_ReturnsFalse()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", -49);
        Assert.False(FactionsData.IsHostile(state, "test"));
    }

    [Fact]
    public void IsAllied_AtThreshold_ReturnsTrue()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 80);
        Assert.True(FactionsData.IsAllied(state, "test"));
    }

    [Fact]
    public void IsAllied_JustBelowThreshold_ReturnsFalse()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 79);
        Assert.False(FactionsData.IsAllied(state, "test"));
    }

    // =========================================================================
    // GetRelation — default for unknown
    // =========================================================================

    [Fact]
    public void GetRelation_UnknownFaction_ReturnsZero()
    {
        var state = new GameState();
        Assert.Equal(0, FactionsData.GetRelation(state, "nonexistent"));
    }

    [Fact]
    public void GetRelation_AfterSet_ReturnsSetValue()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", 42);
        Assert.Equal(42, FactionsData.GetRelation(state, "test"));
    }

    // =========================================================================
    // GetFaction — without loading
    // =========================================================================

    [Fact]
    public void GetFaction_WithoutLoad_ReturnsNull()
    {
        // Reset cache by loading from empty path
        FactionsData.LoadData("/nonexistent/path/that/does/not/exist");
        Assert.Null(FactionsData.GetFaction("merchant_guild"));
    }

    [Fact]
    public void GetFactionIds_AfterEmptyLoad_ReturnsEmpty()
    {
        FactionsData.LoadData("/nonexistent/path");
        Assert.Empty(FactionsData.GetFactionIds());
    }

    [Fact]
    public void GetFactionName_UnknownFaction_ReturnsId()
    {
        Assert.Equal("totally_unknown", FactionsData.GetFactionName("totally_unknown"));
    }

    // =========================================================================
    // FactionDef defaults
    // =========================================================================

    [Fact]
    public void FactionDef_DefaultsAreNonNull()
    {
        var def = new FactionDef();
        Assert.Equal("", def.Id);
        Assert.Equal("", def.Name);
        Assert.Equal("neutral", def.Personality);
        Assert.Equal(0, def.BaseRelation);
    }

    [Fact]
    public void FactionDef_CanBeSet()
    {
        var def = new FactionDef
        {
            Id = "test",
            Name = "Test Faction",
            Personality = "aggressive",
            BaseRelation = -25,
        };
        Assert.Equal("test", def.Id);
        Assert.Equal("Test Faction", def.Name);
        Assert.Equal("aggressive", def.Personality);
        Assert.Equal(-25, def.BaseRelation);
    }

    // =========================================================================
    // Multiple factions — independent
    // =========================================================================

    [Fact]
    public void MultipleFactions_HaveIndependentRelations()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "faction_a", 50);
        FactionsData.SetRelation(state, "faction_b", -30);

        Assert.Equal(50, FactionsData.GetRelation(state, "faction_a"));
        Assert.Equal(-30, FactionsData.GetRelation(state, "faction_b"));

        FactionsData.ChangeRelation(state, "faction_a", -10);
        Assert.Equal(40, FactionsData.GetRelation(state, "faction_a"));
        Assert.Equal(-30, FactionsData.GetRelation(state, "faction_b"));
    }

    // =========================================================================
    // Status transitions
    // =========================================================================

    [Fact]
    public void StatusTransition_HostileToAllied_AllStatusesPassed()
    {
        var state = new GameState();
        FactionsData.SetRelation(state, "test", -100);

        var statuses = new List<string>();
        for (int rel = -100; rel <= 100; rel += 10)
        {
            FactionsData.SetRelation(state, "test", rel);
            string status = FactionsData.GetRelationStatus(rel);
            if (statuses.Count == 0 || statuses.Last() != status)
                statuses.Add(status);
        }

        Assert.Contains("hostile", statuses);
        Assert.Contains("unfriendly", statuses);
        Assert.Contains("neutral", statuses);
        Assert.Contains("friendly", statuses);
        Assert.Contains("allied", statuses);
    }
}
