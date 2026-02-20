using System;
using System.Collections.Generic;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Core.World;

/// <summary>
/// Faction diplomacy: trades, pacts, alliances, and war.
/// Ported from sim/diplomacy.gd.
/// </summary>
public static class Diplomacy
{
    public const int RelationMin = -100;
    public const int RelationMax = 100;
    public const int TradeThreshold = 10;
    public const int PactThreshold = 30;
    public const int AllianceThreshold = 60;
    public const int WarThreshold = -50;

    public static int GetRelation(GameState state, string factionId)
        => state.FactionRelations.GetValueOrDefault(factionId, 0);

    public static void ModifyRelation(GameState state, string factionId, int amount)
    {
        int current = GetRelation(state, factionId);
        state.FactionRelations[factionId] = Math.Clamp(current + amount, RelationMin, RelationMax);
    }

    public static Dictionary<string, object> ProposeTrade(GameState state, string factionId)
    {
        int relation = GetRelation(state, factionId);
        if (relation < TradeThreshold)
            return new() { ["ok"] = false, ["error"] = "Relations too low for trade." };

        ModifyRelation(state, factionId, 5);
        return new() { ["ok"] = true, ["message"] = $"Trade established with {factionId}. Relations improved." };
    }

    public static Dictionary<string, object> ProposePact(GameState state, string factionId)
    {
        int relation = GetRelation(state, factionId);
        if (relation < PactThreshold)
            return new() { ["ok"] = false, ["error"] = "Relations too low for non-aggression pact." };

        if (!state.FactionAgreements.ContainsKey("non_aggression"))
            state.FactionAgreements["non_aggression"] = new();
        if (!state.FactionAgreements["non_aggression"].Contains(factionId))
            state.FactionAgreements["non_aggression"].Add(factionId);

        ModifyRelation(state, factionId, 10);
        return new() { ["ok"] = true, ["message"] = $"Non-aggression pact with {factionId}." };
    }

    public static Dictionary<string, object> ProposeAlliance(GameState state, string factionId)
    {
        int relation = GetRelation(state, factionId);
        if (relation < AllianceThreshold)
            return new() { ["ok"] = false, ["error"] = "Relations too low for alliance." };

        if (!state.FactionAgreements.ContainsKey("alliance"))
            state.FactionAgreements["alliance"] = new();
        if (!state.FactionAgreements["alliance"].Contains(factionId))
            state.FactionAgreements["alliance"].Add(factionId);

        ModifyRelation(state, factionId, 15);
        return new() { ["ok"] = true, ["message"] = $"Alliance formed with {factionId}!" };
    }

    public static Dictionary<string, object> DeclareWar(GameState state, string factionId)
    {
        if (!state.FactionAgreements.ContainsKey("war"))
            state.FactionAgreements["war"] = new();
        if (!state.FactionAgreements["war"].Contains(factionId))
            state.FactionAgreements["war"].Add(factionId);

        // Remove other agreements
        foreach (var (_, list) in state.FactionAgreements)
        {
            if (list != state.FactionAgreements.GetValueOrDefault("war"))
                list.Remove(factionId);
        }

        ModifyRelation(state, factionId, -50);
        return new() { ["ok"] = true, ["message"] = $"War declared on {factionId}!" };
    }

    public static Dictionary<string, object> SendGift(GameState state, string factionId, string resource, int amount)
    {
        int current = state.Resources.GetValueOrDefault(resource, 0);
        if (current < amount)
            return new() { ["ok"] = false, ["error"] = $"Not enough {resource}." };

        state.Resources[resource] = current - amount;
        int relationGain = Math.Max(1, amount / 5);
        ModifyRelation(state, factionId, relationGain);
        return new() { ["ok"] = true, ["message"] = $"Sent {amount} {resource} to {factionId}. Relations +{relationGain}." };
    }
}
