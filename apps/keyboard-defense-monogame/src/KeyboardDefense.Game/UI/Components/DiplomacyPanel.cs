using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;
using Myra.Graphics2D.UI;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Diplomacy panel showing faction standings, agreements, and actions.
/// Wires to Core/Data/FactionsData.cs and Core/World/Diplomacy.cs.
/// </summary>
public class DiplomacyPanel : BasePanel
{
    private readonly VerticalStackPanel _content;
    private GameState? _state;

    public DiplomacyPanel() : base(Locale.Tr("panels.diplomacy"))
    {
        RootWidget.Width = 600;
        RootWidget.Height = 520;

        _content = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        var scroll = new ScrollViewer
        {
            Content = _content,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(scroll);
    }

    public void Refresh(GameState state)
    {
        _state = state;
        _content.Widgets.Clear();

        var factionIds = FactionsData.GetFactionIds();
        if (factionIds.Count == 0)
        {
            _content.Widgets.Add(new Label
            {
                Text = "No factions discovered yet.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        // Active agreements summary
        int pactCount = 0, allianceCount = 0, warCount = 0;
        foreach (var (agreement, factions) in state.FactionAgreements)
        {
            if (agreement == "non_aggression") pactCount += factions.Count;
            else if (agreement == "alliance") allianceCount += factions.Count;
            else if (agreement == "war") warCount += factions.Count;
        }

        var summaryRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        summaryRow.Widgets.Add(new Label { Text = $"Pacts: {pactCount}", TextColor = ThemeColors.Info });
        summaryRow.Widgets.Add(new Label { Text = $"Alliances: {allianceCount}", TextColor = ThemeColors.Success });
        if (warCount > 0)
            summaryRow.Widgets.Add(new Label { Text = $"Wars: {warCount}", TextColor = ThemeColors.Error });
        _content.Widgets.Add(summaryRow);
        _content.Widgets.Add(new HorizontalSeparator());

        // Faction list
        foreach (string factionId in factionIds)
        {
            var def = FactionsData.GetFaction(factionId);
            if (def == null) continue;

            int relation = FactionsData.GetRelation(state, factionId);
            string status = FactionsData.GetRelationStatus(relation);

            var header = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
            header.Widgets.Add(new Label
            {
                Text = def.Name,
                TextColor = ThemeColors.Text,
                Width = 160,
            });
            header.Widgets.Add(new Label
            {
                Text = $"{relation:+#;-#;0}",
                TextColor = GetRelationColor(relation),
                Width = 50,
            });
            header.Widgets.Add(new Label
            {
                Text = $"[{status}]",
                TextColor = GetStatusColor(status),
                Width = 90,
            });

            // Agreement badges
            string agreements = GetAgreementBadges(state, factionId);
            if (!string.IsNullOrEmpty(agreements))
            {
                header.Widgets.Add(new Label
                {
                    Text = agreements,
                    TextColor = ThemeColors.AccentCyan,
                });
            }
            _content.Widgets.Add(header);

            // Action buttons
            var actions = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };

            if (relation >= Diplomacy.TradeThreshold)
            {
                var tradeBtn = ButtonFactory.Secondary("Trade", () => OnTrade(factionId));
                tradeBtn.Width = 70;
                tradeBtn.Height = 26;
                actions.Widgets.Add(tradeBtn);
            }
            if (relation >= Diplomacy.PactThreshold && !HasAgreement(state, "non_aggression", factionId))
            {
                var pactBtn = ButtonFactory.Secondary("Pact", () => OnPact(factionId));
                pactBtn.Width = 60;
                pactBtn.Height = 26;
                actions.Widgets.Add(pactBtn);
            }
            if (relation >= Diplomacy.AllianceThreshold && !HasAgreement(state, "alliance", factionId))
            {
                var allyBtn = ButtonFactory.Primary("Alliance", () => OnAlliance(factionId));
                allyBtn.Width = 80;
                allyBtn.Height = 26;
                actions.Widgets.Add(allyBtn);
            }

            var giftBtn = ButtonFactory.Ghost("Gift 10g", () => OnGift(factionId));
            giftBtn.Width = 70;
            giftBtn.Height = 26;
            actions.Widgets.Add(giftBtn);

            _content.Widgets.Add(actions);
            _content.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });
        }
    }

    private static bool HasAgreement(GameState state, string type, string factionId)
    {
        return state.FactionAgreements.TryGetValue(type, out var list) && list.Contains(factionId);
    }

    private static string GetAgreementBadges(GameState state, string factionId)
    {
        var badges = new List<string>();
        if (HasAgreement(state, "non_aggression", factionId)) badges.Add("NAP");
        if (HasAgreement(state, "alliance", factionId)) badges.Add("ALLY");
        if (HasAgreement(state, "war", factionId)) badges.Add("WAR");
        return string.Join(" ", badges);
    }

    private static Color GetRelationColor(int relation) => relation switch
    {
        >= 50 => ThemeColors.Success,
        >= 20 => ThemeColors.Info,
        >= -20 => ThemeColors.TextDim,
        >= -50 => ThemeColors.Warning,
        _ => ThemeColors.Error,
    };

    private static Color GetStatusColor(string status) => status switch
    {
        "allied" => ThemeColors.Success,
        "friendly" => ThemeColors.Info,
        "neutral" => ThemeColors.TextDim,
        "unfriendly" => ThemeColors.Warning,
        "hostile" => ThemeColors.Error,
        _ => ThemeColors.TextDim,
    };

    private void OnTrade(string factionId)
    {
        if (_state == null) return;
        Diplomacy.ProposeTrade(_state, factionId);
        Refresh(_state);
    }

    private void OnPact(string factionId)
    {
        if (_state == null) return;
        Diplomacy.ProposePact(_state, factionId);
        Refresh(_state);
    }

    private void OnAlliance(string factionId)
    {
        if (_state == null) return;
        Diplomacy.ProposeAlliance(_state, factionId);
        Refresh(_state);
    }

    private void OnGift(string factionId)
    {
        if (_state == null) return;
        Diplomacy.SendGift(_state, factionId, "gold", 10);
        Refresh(_state);
    }
}
