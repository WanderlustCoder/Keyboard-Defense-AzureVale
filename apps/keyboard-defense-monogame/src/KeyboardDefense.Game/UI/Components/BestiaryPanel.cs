using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Bestiary panel showing discovered enemies grouped by tier.
/// Enriched with tabs, encounter tracking, kill badges, and ability details.
/// </summary>
public class BestiaryPanel : BasePanel
{
    private static readonly Dictionary<EnemyTypes.Tier, string> TierNames = new()
    {
        [EnemyTypes.Tier.Minion] = "Minion",
        [EnemyTypes.Tier.Standard] = "Standard",
        [EnemyTypes.Tier.Elite] = "Elite",
        [EnemyTypes.Tier.Boss] = "Boss",
    };

    private static readonly Dictionary<EnemyTypes.Tier, Color> TierColors = new()
    {
        [EnemyTypes.Tier.Minion] = ThemeColors.TextDim,
        [EnemyTypes.Tier.Standard] = ThemeColors.Text,
        [EnemyTypes.Tier.Elite] = ThemeColors.Warning,
        [EnemyTypes.Tier.Boss] = ThemeColors.Error,
    };

    private readonly Label _summaryLabel;
    private readonly VerticalStackPanel _listArea;
    private readonly VerticalStackPanel _detailArea;
    private EnemyTypes.Tier _activeTier = EnemyTypes.Tier.Minion;
    private string _activeTab = "Enemies";
    private GameState? _lastState;

    // Track which enemies have been encountered and kill counts
    private readonly HashSet<string> _encounteredEnemies = new();
    private readonly Dictionary<string, int> _killCounts = new();

    public BestiaryPanel() : base(Locale.Tr("panels.bestiary"))
    {
        RootWidget.Width = 750;
        RootWidget.Height = 550;

        _summaryLabel = new Label
        {
            Text = "Enemies catalogued: 0",
            TextColor = ThemeColors.TextDim,
        };
        AddWidget(_summaryLabel);

        // Main tab bar (Enemies vs Abilities vs Categories)
        var mainTabBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        foreach (string tab in new[] { "Enemies", "Abilities", "Categories" })
        {
            string t = tab;
            var btn = ButtonFactory.Ghost(tab, () => SwitchMainTab(t));
            btn.Width = 90;
            btn.Height = DesignSystem.SizeButtonSm;
            mainTabBar.Widgets.Add(btn);
        }
        AddWidget(mainTabBar);

        // Tier filter bar
        var tabBar = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        foreach (var (tier, name) in TierNames)
        {
            var t = tier;
            var btn = ButtonFactory.Secondary(name, () => ShowTier(t));
            btn.Width = 100;
            btn.Height = DesignSystem.SizeButtonSm;
            tabBar.Widgets.Add(btn);
        }
        AddWidget(tabBar);

        AddWidget(new HorizontalSeparator());

        var split = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };

        _listArea = new VerticalStackPanel { Spacing = 2 };
        var listScroll = new ScrollViewer
        {
            Content = _listArea,
            Width = 240,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(listScroll);

        _detailArea = new VerticalStackPanel { Spacing = 4 };
        var detailScroll = new ScrollViewer
        {
            Content = _detailArea,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        split.Widgets.Add(detailScroll);

        AddWidget(split);
    }

    public void Refresh(GameState state)
    {
        _lastState = state;

        // Track encountered enemies from current state
        foreach (var enemy in state.Enemies)
        {
            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "";
            if (!string.IsNullOrEmpty(kind))
                _encounteredEnemies.Add(kind);
        }

        int total = EnemyTypes.Registry.Count;
        int encountered = _encounteredEnemies.Count;
        _summaryLabel.Text = $"Types: {total} | Encountered: {encountered} | Defeated: {state.EnemiesDefeated}";

        if (_activeTab == "Abilities")
            ShowAbilities();
        else if (_activeTab == "Categories")
            ShowCategories();
        else
            ShowTier(_activeTier);
    }

    private void SwitchMainTab(string tab)
    {
        _activeTab = tab;
        if (tab == "Abilities")
            ShowAbilities();
        else if (tab == "Categories")
            ShowCategories();
        else
            ShowTier(_activeTier);
    }

    private void ShowTier(EnemyTypes.Tier tier)
    {
        _activeTier = tier;
        _activeTab = "Enemies";
        _listArea.Widgets.Clear();
        _detailArea.Widgets.Clear();
        _detailArea.Widgets.Add(new Label
        {
            Text = "Select an enemy to view details.",
            TextColor = ThemeColors.TextDim,
            Wrap = true,
        });

        var filtered = EnemyTypes.Registry
            .Where(kv => kv.Value.Tier == tier)
            .ToList();

        if (filtered.Count == 0)
        {
            _listArea.Widgets.Add(new Label
            {
                Text = $"No {TierNames.GetValueOrDefault(tier, "Unknown")} enemies catalogued.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        Color tierColor = TierColors.GetValueOrDefault(tier, ThemeColors.Text);
        foreach (var (kind, def) in filtered)
        {
            string k = kind;
            var d = def;
            bool encountered = _encounteredEnemies.Contains(kind);
            int kills = _killCounts.GetValueOrDefault(kind, 0);

            // Build button text with kill badge
            string badge = kills > 0 ? $" [{kills}]" : "";
            Color textColor = encountered ? tierColor : ThemeColors.TextDisabled;

            var btnContent = new HorizontalStackPanel { Spacing = 4 };
            btnContent.Widgets.Add(new Label
            {
                Text = encountered ? def.Name : "???",
                TextColor = textColor,
            });
            if (kills > 0)
            {
                btnContent.Widgets.Add(new Label
                {
                    Text = $"x{kills}",
                    TextColor = ThemeColors.GoldAccent,
                });
            }

            var btn = new Button
            {
                Content = btnContent,
                Height = 28,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            btn.Click += (_, _) => ShowDetail(k, d, tierColor);
            _listArea.Widgets.Add(btn);
        }
    }

    private void ShowDetail(string kind, EnemyTypeDef def, Color tierColor)
    {
        _detailArea.Widgets.Clear();

        // Name and tier header
        _detailArea.Widgets.Add(new Label
        {
            Text = $"{def.Name}",
            TextColor = tierColor,
        });
        _detailArea.Widgets.Add(new Label
        {
            Text = $"Kind: {kind} | Tier: {TierNames.GetValueOrDefault(def.Tier, "?")}",
            TextColor = ThemeColors.TextDim,
        });
        _detailArea.Widgets.Add(new HorizontalSeparator());

        // Stats grid
        AddDetailStat("HP", def.Hp.ToString(), ThemeColors.HealGreen);
        AddDetailStat("Damage", def.Damage.ToString(), ThemeColors.DamageRed);
        AddDetailStat("Speed", def.Speed.ToString(), ThemeColors.AccentCyan);
        AddDetailStat("Armor", def.Armor.ToString(), ThemeColors.ShieldBlue);
        AddDetailStat("Gold", def.Gold.ToString(), ThemeColors.GoldAccent);

        _detailArea.Widgets.Add(new HorizontalSeparator());

        // Abilities
        _detailArea.Widgets.Add(new Label
        {
            Text = "Abilities:",
            TextColor = ThemeColors.Accent,
        });

        if (def.Abilities.Length > 0)
        {
            foreach (string ability in def.Abilities)
            {
                _detailArea.Widgets.Add(new Label
                {
                    Text = $"  - {ability}",
                    TextColor = ThemeColors.Text,
                });
            }
        }
        else
        {
            _detailArea.Widgets.Add(new Label
            {
                Text = "  None",
                TextColor = ThemeColors.TextDim,
            });
        }

        // Kill count
        int kills = _killCounts.GetValueOrDefault(kind, 0);
        _detailArea.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });
        _detailArea.Widgets.Add(new Label
        {
            Text = $"Kills: {kills}",
            TextColor = kills > 0 ? ThemeColors.GoldAccent : ThemeColors.TextDim,
        });
    }

    private void ShowAbilities()
    {
        _listArea.Widgets.Clear();
        _detailArea.Widgets.Clear();

        // Collect all unique abilities across all enemies
        var abilityMap = new Dictionary<string, List<string>>();
        foreach (var (kind, def) in EnemyTypes.Registry)
        {
            foreach (string ability in def.Abilities)
            {
                if (!abilityMap.ContainsKey(ability))
                    abilityMap[ability] = new();
                abilityMap[ability].Add(def.Name);
            }
        }

        if (abilityMap.Count == 0)
        {
            _listArea.Widgets.Add(new Label
            {
                Text = "No abilities catalogued.",
                TextColor = ThemeColors.TextDim,
            });
            return;
        }

        foreach (var (ability, enemies) in abilityMap.OrderBy(kv => kv.Key))
        {
            string a = ability;
            var el = enemies;
            var btn = new Button
            {
                Content = new Label { Text = ability, TextColor = ThemeColors.AccentCyan },
                Height = 28,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            btn.Click += (_, _) =>
            {
                _detailArea.Widgets.Clear();
                _detailArea.Widgets.Add(new Label
                {
                    Text = a,
                    TextColor = ThemeColors.AccentCyan,
                });
                _detailArea.Widgets.Add(new HorizontalSeparator());
                _detailArea.Widgets.Add(new Label
                {
                    Text = "Used by:",
                    TextColor = ThemeColors.TextDim,
                });
                foreach (string e in el)
                {
                    _detailArea.Widgets.Add(new Label
                    {
                        Text = $"  - {e}",
                        TextColor = ThemeColors.Text,
                    });
                }
            };
            _listArea.Widgets.Add(btn);
        }

        _detailArea.Widgets.Add(new Label
        {
            Text = "Select an ability to see which enemies use it.",
            TextColor = ThemeColors.TextDim,
            Wrap = true,
        });
    }

    private void ShowCategories()
    {
        _listArea.Widgets.Clear();
        _detailArea.Widgets.Clear();

        // Group enemies by category
        var categoryGroups = EnemyTypes.Registry
            .GroupBy(kv => kv.Value.Category)
            .OrderBy(g => g.Key)
            .ToList();

        foreach (var group in categoryGroups)
        {
            var category = group.Key;
            var enemies = group.ToList();
            string categoryName = category.ToString();
            var btn = new Button
            {
                Content = new Label
                {
                    Text = $"{categoryName} ({enemies.Count})",
                    TextColor = ThemeColors.Accent,
                },
                Height = 28,
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            var el = enemies;
            btn.Click += (_, _) =>
            {
                _detailArea.Widgets.Clear();
                _detailArea.Widgets.Add(new Label
                {
                    Text = $"Category: {categoryName}",
                    TextColor = ThemeColors.Accent,
                });
                _detailArea.Widgets.Add(new HorizontalSeparator());
                foreach (var entry in el)
                {
                    Color tc = TierColors.GetValueOrDefault(entry.Value.Tier, ThemeColors.Text);
                    _detailArea.Widgets.Add(new Label
                    {
                        Text = $"{entry.Value.Name} [{TierNames.GetValueOrDefault(entry.Value.Tier, "?")}] HP:{entry.Value.Hp} DMG:{entry.Value.Damage}",
                        TextColor = tc,
                    });
                }
            };
            _listArea.Widgets.Add(btn);
        }

        _detailArea.Widgets.Add(new Label
        {
            Text = "Select a category to see its enemies.",
            TextColor = ThemeColors.TextDim,
            Wrap = true,
        });
    }

    private void AddDetailStat(string label, string value, Color valueColor)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label
        {
            Text = label + ":",
            TextColor = ThemeColors.TextDim,
            Width = 80,
        });
        row.Widgets.Add(new Label
        {
            Text = value,
            TextColor = valueColor,
        });
        _detailArea.Widgets.Add(row);
    }

    public void RecordKill(string kind)
    {
        _killCounts[kind] = _killCounts.GetValueOrDefault(kind, 0) + 1;
        _encounteredEnemies.Add(kind);
    }
}
