using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Extended tests for SynergyDetector — all 8 synergies, adjacency rules,
/// multiplier stacking, edge cases for empty/no-match states.
/// </summary>
public class SynergyDetectorExtendedTests
{
    // =========================================================================
    // ExtraSynergies registry — completeness
    // =========================================================================

    [Fact]
    public void ExtraSynergies_HasEightEntries()
    {
        Assert.Equal(8, SynergyDetector.ExtraSynergies.Count);
    }

    [Theory]
    [InlineData("fire_ice", "Fire & Ice", 2, 1.2)]
    [InlineData("arrow_rain", "Arrow Rain", 3, 1.3)]
    [InlineData("arcane_support", "Arcane Support", 2, 1.25)]
    [InlineData("holy_purification", "Holy Purification", 2, 1.35)]
    [InlineData("chain_reaction", "Chain Reaction", 2, 1.2)]
    [InlineData("kill_box", "Kill Box", 2, 1.4)]
    [InlineData("legion", "Legion", 2, 1.2)]
    [InlineData("titan_slayer", "Titan Slayer", 2, 1.3)]
    public void ExtraSynergies_AllHaveCorrectMetadata(
        string id, string name, int minCount, double multiplier)
    {
        Assert.True(SynergyDetector.ExtraSynergies.TryGetValue(id, out var def));
        Assert.Equal(name, def!.Name);
        Assert.Equal(minCount, def.MinCount);
        Assert.Equal(multiplier, def.DamageMultiplier, 5);
    }

    [Fact]
    public void ExtraSynergies_AllHaveNonEmptyRequiredTypes()
    {
        foreach (var (id, def) in SynergyDetector.ExtraSynergies)
        {
            Assert.NotEmpty(def.RequiredTypes);
            Assert.All(def.RequiredTypes, t => Assert.False(string.IsNullOrEmpty(t)));
        }
    }

    // =========================================================================
    // DetectActiveSynergies — each synergy type
    // =========================================================================

    [Fact]
    public void DetectActiveSynergies_FireIce_AdjacentFrostAndFire()
    {
        var state = CreateState(
            (new GridPoint(5, 5), "frost"),
            (new GridPoint(6, 5), "fire"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("fire_ice", active);
    }

    [Fact]
    public void DetectActiveSynergies_ArcaneSupport_Adjacent()
    {
        var state = CreateState(
            (new GridPoint(3, 3), "arcane"),
            (new GridPoint(3, 4), "support"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("arcane_support", active);
    }

    [Fact]
    public void DetectActiveSynergies_HolyPurification_Adjacent()
    {
        var state = CreateState(
            (new GridPoint(7, 7), "holy"),
            (new GridPoint(8, 7), "purifier"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("holy_purification", active);
    }

    [Fact]
    public void DetectActiveSynergies_ChainReaction_TwoAdjacentTesla()
    {
        var state = CreateState(
            (new GridPoint(4, 4), "tesla"),
            (new GridPoint(4, 5), "tesla"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("chain_reaction", active);
    }

    [Fact]
    public void DetectActiveSynergies_Legion_TwoAdjacentSummoner()
    {
        var state = CreateState(
            (new GridPoint(10, 10), "summoner"),
            (new GridPoint(10, 11), "summoner"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("legion", active);
    }

    [Fact]
    public void DetectActiveSynergies_TitanSlayer_AdjacentSiegeAndHoly()
    {
        var state = CreateState(
            (new GridPoint(6, 6), "siege"),
            (new GridPoint(7, 6), "holy"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("titan_slayer", active);
    }

    // =========================================================================
    // DetectActiveSynergies — non-adjacent → no synergy
    // =========================================================================

    [Fact]
    public void DetectActiveSynergies_FireIce_NonAdjacent_DoesNotActivate()
    {
        var state = CreateState(
            (new GridPoint(1, 1), "frost"),
            (new GridPoint(10, 10), "fire"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.DoesNotContain("fire_ice", active);
    }

    [Fact]
    public void DetectActiveSynergies_DiagonalTowers_DoNotCount()
    {
        // Diagonal = Manhattan distance 2, not adjacent
        var state = CreateState(
            (new GridPoint(5, 5), "cannon"),
            (new GridPoint(6, 6), "frost"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.DoesNotContain("kill_box", active);
    }

    // =========================================================================
    // DetectActiveSynergies — empty/minimal states
    // =========================================================================

    [Fact]
    public void DetectActiveSynergies_EmptyStructures_ReturnsEmpty()
    {
        var state = new GameState();
        state.Structures.Clear();

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Empty(active);
    }

    [Fact]
    public void DetectActiveSynergies_SingleTower_ReturnsEmpty()
    {
        var state = CreateState(
            (new GridPoint(5, 5), "cannon"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Empty(active);
    }

    [Fact]
    public void DetectActiveSynergies_WrongTypes_ReturnsEmpty()
    {
        var state = CreateState(
            (new GridPoint(5, 5), "arrow"),
            (new GridPoint(6, 5), "cannon"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        // arrow + cannon isn't a valid synergy combo
        Assert.Empty(active);
    }

    // =========================================================================
    // DetectActiveSynergies — arrow_rain needs 3 adjacent
    // =========================================================================

    [Fact]
    public void DetectActiveSynergies_TwoArrows_NotEnoughForArrowRain()
    {
        var state = CreateState(
            (new GridPoint(5, 5), "arrow"),
            (new GridPoint(6, 5), "arrow"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.DoesNotContain("arrow_rain", active);
    }

    [Fact]
    public void DetectActiveSynergies_ThreeArrows_VerticalLine_ActivatesArrowRain()
    {
        var state = CreateState(
            (new GridPoint(5, 5), "arrow"),
            (new GridPoint(5, 6), "arrow"),
            (new GridPoint(5, 7), "arrow"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("arrow_rain", active);
    }

    [Fact]
    public void DetectActiveSynergies_ThreeArrows_LShape_ActivatesArrowRain()
    {
        // L-shape: (5,5) adj to (6,5) adj to (6,6)
        var state = CreateState(
            (new GridPoint(5, 5), "arrow"),
            (new GridPoint(6, 5), "arrow"),
            (new GridPoint(6, 6), "arrow"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("arrow_rain", active);
    }

    // =========================================================================
    // DetectActiveSynergies — multiple synergies simultaneously
    // =========================================================================

    [Fact]
    public void DetectActiveSynergies_MultipleSynergies_AllDetected()
    {
        var state = CreateState(
            // kill_box: cannon + frost adjacent
            (new GridPoint(5, 5), "cannon"),
            (new GridPoint(6, 5), "frost"),
            // fire_ice: frost + fire adjacent (different frost tower)
            (new GridPoint(10, 10), "frost"),
            (new GridPoint(11, 10), "fire"),
            // chain_reaction: tesla + tesla adjacent
            (new GridPoint(15, 15), "tesla"),
            (new GridPoint(16, 15), "tesla"));

        var active = SynergyDetector.DetectActiveSynergies(state);

        Assert.Contains("kill_box", active);
        Assert.Contains("fire_ice", active);
        Assert.Contains("chain_reaction", active);
    }

    // =========================================================================
    // GetSynergyDamageMultiplier
    // =========================================================================

    [Fact]
    public void GetSynergyDamageMultiplier_EmptyList_ReturnsOne()
    {
        double mult = SynergyDetector.GetSynergyDamageMultiplier(new List<string>());
        Assert.Equal(1.0, mult, 5);
    }

    [Fact]
    public void GetSynergyDamageMultiplier_SingleSynergy_ReturnsThatMultiplier()
    {
        var synergies = new List<string> { "kill_box" };
        double mult = SynergyDetector.GetSynergyDamageMultiplier(synergies);
        Assert.Equal(1.4, mult, 5);
    }

    [Fact]
    public void GetSynergyDamageMultiplier_UnknownId_IgnoresIt()
    {
        var synergies = new List<string> { "nonexistent_synergy" };
        double mult = SynergyDetector.GetSynergyDamageMultiplier(synergies);
        Assert.Equal(1.0, mult, 5);
    }

    [Fact]
    public void GetSynergyDamageMultiplier_MixedKnownAndUnknown_OnlyMultipliesKnown()
    {
        var synergies = new List<string> { "fire_ice", "fake_synergy", "chain_reaction" };
        double mult = SynergyDetector.GetSynergyDamageMultiplier(synergies);
        Assert.Equal(1.2 * 1.2, mult, 5); // fire_ice * chain_reaction
    }

    [Fact]
    public void GetSynergyDamageMultiplier_AllSynergies_MultipliesAll()
    {
        var synergies = new List<string>
        {
            "fire_ice", "arrow_rain", "arcane_support",
            "holy_purification", "chain_reaction", "kill_box",
            "legion", "titan_slayer",
        };
        double mult = SynergyDetector.GetSynergyDamageMultiplier(synergies);

        double expected = 1.2 * 1.3 * 1.25 * 1.35 * 1.2 * 1.4 * 1.2 * 1.3;
        Assert.Equal(expected, mult, 5);
    }

    [Theory]
    [InlineData("fire_ice", 1.2)]
    [InlineData("arrow_rain", 1.3)]
    [InlineData("arcane_support", 1.25)]
    [InlineData("holy_purification", 1.35)]
    [InlineData("chain_reaction", 1.2)]
    [InlineData("kill_box", 1.4)]
    [InlineData("legion", 1.2)]
    [InlineData("titan_slayer", 1.3)]
    public void GetSynergyDamageMultiplier_EachIndividual_ReturnsCorrectValue(
        string synId, double expected)
    {
        var synergies = new List<string> { synId };
        double mult = SynergyDetector.GetSynergyDamageMultiplier(synergies);
        Assert.Equal(expected, mult, 5);
    }

    // =========================================================================
    // DetectedSynergyDef record
    // =========================================================================

    [Fact]
    public void DetectedSynergyDef_IsRecord_WithExpectedFields()
    {
        var def = new DetectedSynergyDef("Test", new[] { "a", "b" }, 2, 1.5);
        Assert.Equal("Test", def.Name);
        Assert.Equal(new[] { "a", "b" }, def.RequiredTypes);
        Assert.Equal(2, def.MinCount);
        Assert.Equal(1.5, def.DamageMultiplier);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static GameState CreateState(params (GridPoint Pos, string Type)[] towers)
    {
        var state = new GameState();
        state.Structures.Clear();
        foreach (var (pos, towerType) in towers)
            state.Structures[pos.ToIndex(state.MapW)] = towerType;
        return state;
    }
}
