using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

public class DiplomacyCoreTests
{
    private const string FactionId = "elves";

    [Fact]
    public void Constants_HaveExpectedValues()
    {
        Assert.Equal(-100, Diplomacy.RelationMin);
        Assert.Equal(100, Diplomacy.RelationMax);
        Assert.Equal(10, Diplomacy.TradeThreshold);
        Assert.Equal(30, Diplomacy.PactThreshold);
        Assert.Equal(60, Diplomacy.AllianceThreshold);
        Assert.Equal(-50, Diplomacy.WarThreshold);
    }

    [Fact]
    public void GetRelation_UnknownFaction_ReturnsZero()
    {
        var state = CreateState();

        int relation = Diplomacy.GetRelation(state, "unknown_faction");

        Assert.Equal(0, relation);
    }

    [Fact]
    public void GetRelation_KnownFaction_ReturnsStoredValue()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 27;

        int relation = Diplomacy.GetRelation(state, FactionId);

        Assert.Equal(27, relation);
    }

    [Fact]
    public void ModifyRelation_AddsAmount()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 12;

        Diplomacy.ModifyRelation(state, FactionId, 8);

        Assert.Equal(20, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ModifyRelation_ClampAt100_FromNinetyFivePlusTen()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 95;

        Diplomacy.ModifyRelation(state, FactionId, 10);

        Assert.Equal(100, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ModifyRelation_ClampAtMinus100_FromMinusNinetyFiveMinusTen()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = -95;

        Diplomacy.ModifyRelation(state, FactionId, -10);

        Assert.Equal(-100, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposeTrade_RelationAtThreshold_SucceedsAndAddsFive()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 10;

        var result = Diplomacy.ProposeTrade(state, FactionId);

        Assert.True((bool)result["ok"]);
        Assert.Equal(15, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposeTrade_RelationBelowThreshold_Fails()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 9;

        var result = Diplomacy.ProposeTrade(state, FactionId);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Relations too low for trade.", result["error"]);
        Assert.Equal(9, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposeTrade_SuccessClampsRelationAtMax()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 98;

        var result = Diplomacy.ProposeTrade(state, FactionId);

        Assert.True((bool)result["ok"]);
        Assert.Equal(100, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposePact_RelationAtThreshold_SucceedsAddsAgreementAndTenRelation()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 30;

        var result = Diplomacy.ProposePact(state, FactionId);

        Assert.True((bool)result["ok"]);
        Assert.Contains(FactionId, state.FactionAgreements["non_aggression"]);
        Assert.Equal(40, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposePact_RelationBelowThreshold_Fails()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 29;

        var result = Diplomacy.ProposePact(state, FactionId);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Relations too low for non-aggression pact.", result["error"]);
        Assert.DoesNotContain(FactionId, state.FactionAgreements["non_aggression"]);
        Assert.Equal(29, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposePact_RepeatedCall_DoesNotDuplicateAgreement()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 30;

        var first = Diplomacy.ProposePact(state, FactionId);
        var second = Diplomacy.ProposePact(state, FactionId);

        Assert.True((bool)first["ok"]);
        Assert.True((bool)second["ok"]);
        Assert.Single(state.FactionAgreements["non_aggression"]);
        Assert.Equal(FactionId, state.FactionAgreements["non_aggression"][0]);
        Assert.Equal(50, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposeAlliance_RelationAtThreshold_SucceedsAddsAgreementAndFifteenRelation()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 60;

        var result = Diplomacy.ProposeAlliance(state, FactionId);

        Assert.True((bool)result["ok"]);
        Assert.Contains(FactionId, state.FactionAgreements["alliance"]);
        Assert.Equal(75, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposeAlliance_RelationBelowThreshold_Fails()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 59;

        var result = Diplomacy.ProposeAlliance(state, FactionId);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Relations too low for alliance.", result["error"]);
        Assert.DoesNotContain(FactionId, state.FactionAgreements["alliance"]);
        Assert.Equal(59, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void ProposeAlliance_RepeatedCall_DoesNotDuplicateAgreement()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 60;

        var first = Diplomacy.ProposeAlliance(state, FactionId);
        var second = Diplomacy.ProposeAlliance(state, FactionId);

        Assert.True((bool)first["ok"]);
        Assert.True((bool)second["ok"]);
        Assert.Single(state.FactionAgreements["alliance"]);
        Assert.Equal(FactionId, state.FactionAgreements["alliance"][0]);
        Assert.Equal(90, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void DeclareWar_AddsWar_RemovesOtherAgreements_AndReducesRelation()
    {
        var state = CreateState();
        state.FactionRelations[FactionId] = 40;
        state.FactionAgreements["trade"].Add(FactionId);
        state.FactionAgreements["non_aggression"].Add(FactionId);
        state.FactionAgreements["alliance"].Add(FactionId);

        var result = Diplomacy.DeclareWar(state, FactionId);

        Assert.True((bool)result["ok"]);
        Assert.Contains(FactionId, state.FactionAgreements["war"]);
        Assert.DoesNotContain(FactionId, state.FactionAgreements["trade"]);
        Assert.DoesNotContain(FactionId, state.FactionAgreements["non_aggression"]);
        Assert.DoesNotContain(FactionId, state.FactionAgreements["alliance"]);
        Assert.Equal(-10, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void DeclareWar_RepeatedCall_DoesNotDuplicateWarAgreement()
    {
        var state = CreateState();

        Diplomacy.DeclareWar(state, FactionId);
        Diplomacy.DeclareWar(state, FactionId);

        Assert.Single(state.FactionAgreements["war"]);
        Assert.Equal(FactionId, state.FactionAgreements["war"][0]);
        Assert.Equal(-100, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void SendGift_DeductsResource_AndAddsRelationByAmountDivFive()
    {
        var state = CreateState();
        state.Resources["wood"] = 20;

        var result = Diplomacy.SendGift(state, FactionId, "wood", 15);

        Assert.True((bool)result["ok"]);
        Assert.Equal(5, state.Resources["wood"]);
        Assert.Equal(3, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void SendGift_SmallAmount_GivesMinimumOneRelation()
    {
        var state = CreateState();
        state.Resources["wood"] = 4;

        var result = Diplomacy.SendGift(state, FactionId, "wood", 1);

        Assert.True((bool)result["ok"]);
        Assert.Equal(3, state.Resources["wood"]);
        Assert.Equal(1, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void SendGift_InsufficientResources_FailsWithoutMutatingState()
    {
        var state = CreateState();
        state.Resources["stone"] = 2;
        state.FactionRelations[FactionId] = 7;

        var result = Diplomacy.SendGift(state, FactionId, "stone", 3);

        Assert.False((bool)result["ok"]);
        Assert.Equal("Not enough stone.", result["error"]);
        Assert.Equal(2, state.Resources["stone"]);
        Assert.Equal(7, state.FactionRelations[FactionId]);
    }

    [Fact]
    public void DeclareWarThenProposeTrade_RequiresRebuildingRelation()
    {
        var state = CreateState();

        var war = Diplomacy.DeclareWar(state, FactionId);
        var blockedTrade = Diplomacy.ProposeTrade(state, FactionId);

        Diplomacy.ModifyRelation(state, FactionId, 60);
        var recoveredTrade = Diplomacy.ProposeTrade(state, FactionId);

        Assert.True((bool)war["ok"]);
        Assert.False((bool)blockedTrade["ok"]);
        Assert.Equal("Relations too low for trade.", blockedTrade["error"]);
        Assert.True((bool)recoveredTrade["ok"]);
        Assert.Equal(15, state.FactionRelations[FactionId]);
    }

    private static GameState CreateState()
    {
        var state = DefaultState.Create(seed: "diplomacy_tests");
        state.FactionRelations.Clear();
        foreach (List<string> agreementList in state.FactionAgreements.Values)
            agreementList.Clear();

        state.Resources["wood"] = 0;
        state.Resources["stone"] = 0;
        state.Resources["food"] = 0;

        return state;
    }
}
