using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Myra.Graphics2D.UI;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.State;

namespace KeyboardDefense.Game.UI.Components;

/// <summary>
/// Damage calculator panel that lets players preview and compare damage output
/// for different tower setups against various enemy types.
/// Uses real game formulas from TowerCombat, DamageTypes, and TypingTowerBonuses.
/// </summary>
public class DamageCalculatorPanel : BasePanel
{
    // =========================================================================
    // WPM PRESETS
    // =========================================================================
    private static readonly (string Label, int Wpm)[] WpmPresets =
    {
        ("Low (20)", 20),
        ("Medium (40)", 40),
        ("High (60)", 60),
        ("Expert (80+)", 80),
    };

    // Tower types that deal damage (exclude support/summoner/trap/shrine)
    private static readonly string[] DamageTowerIds =
    {
        TowerTypes.Arrow, TowerTypes.Magic, TowerTypes.Frost, TowerTypes.Cannon,
        TowerTypes.Multi, TowerTypes.Arcane, TowerTypes.Holy, TowerTypes.Siege,
        TowerTypes.PoisonTower, TowerTypes.Tesla, TowerTypes.Wordsmith, TowerTypes.Purifier,
    };

    private static readonly string[] EnemyKindIds =
    {
        "scout", "raider", "armored", "swarm", "tank",
        "berserker", "phantom", "champion", "healer", "elite",
    };

    // =========================================================================
    // STATE
    // =========================================================================
    private readonly ScrollViewer _scrollView;
    private readonly VerticalStackPanel _outputArea;

    // Setup A (left / primary)
    private int _towerIndexA;
    private int _levelA = 1;
    private int _wpmIndexA = 1; // Medium
    private int _enemyIndexA;

    // Setup B (right / comparison)
    private int _towerIndexB = 1;
    private int _levelB = 1;
    private int _wpmIndexB = 1;
    private int _enemyIndexB;

    private bool _comparisonMode;
    private GameState? _lastState;

    public DamageCalculatorPanel() : base(Locale.Tr("panels.damage_calculator"))
    {
        RootWidget.Width = DesignSystem.SizePanelLg;
        RootWidget.Height = 560;

        _outputArea = new VerticalStackPanel { Spacing = DesignSystem.SpaceSm };
        _scrollView = new ScrollViewer
        {
            Content = _outputArea,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch,
        };
        AddWidget(_scrollView);
    }

    public void Refresh(GameState state)
    {
        _lastState = state;
        RebuildUi();
    }

    // =========================================================================
    // UI CONSTRUCTION
    // =========================================================================

    private void RebuildUi()
    {
        _outputArea.Widgets.Clear();

        // --- Comparison toggle ---
        var toggleRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        var toggleBtn = ButtonFactory.Secondary(
            _comparisonMode ? "Single Mode" : "Compare Two",
            () => { _comparisonMode = !_comparisonMode; RebuildUi(); });
        toggleBtn.Width = 140;
        toggleBtn.Height = DesignSystem.SizeButtonSm;
        toggleRow.Widgets.Add(toggleBtn);
        _outputArea.Widgets.Add(toggleRow);
        _outputArea.Widgets.Add(new HorizontalSeparator());

        if (_comparisonMode)
        {
            BuildComparisonView();
        }
        else
        {
            BuildSingleView();
        }
    }

    private void BuildSingleView()
    {
        AddSectionHeader("Tower Setup");
        BuildInputSelectors(
            ref _towerIndexA, ref _levelA, ref _wpmIndexA, ref _enemyIndexA, "A");

        _outputArea.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });
        AddSectionHeader("Damage Output");

        var result = CalculateSetup(_towerIndexA, _levelA, _wpmIndexA, _enemyIndexA);
        BuildOutputDisplay(result);
    }

    private void BuildComparisonView()
    {
        // --- Setup A ---
        AddSectionHeader("Setup A");
        BuildInputSelectors(
            ref _towerIndexA, ref _levelA, ref _wpmIndexA, ref _enemyIndexA, "A");

        _outputArea.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });

        // --- Setup B ---
        AddSectionHeader("Setup B");
        BuildInputSelectors(
            ref _towerIndexB, ref _levelB, ref _wpmIndexB, ref _enemyIndexB, "B");

        _outputArea.Widgets.Add(new Panel { Height = DesignSystem.SpaceSm });
        AddSectionHeader("Comparison");

        var resultA = CalculateSetup(_towerIndexA, _levelA, _wpmIndexA, _enemyIndexA);
        var resultB = CalculateSetup(_towerIndexB, _levelB, _wpmIndexB, _enemyIndexB);
        BuildComparisonDisplay(resultA, resultB);
    }

    // =========================================================================
    // INPUT SELECTORS
    // =========================================================================

    private void BuildInputSelectors(
        ref int towerIdx, ref int level, ref int wpmIdx, ref int enemyIdx, string tag)
    {
        // Capture current values for closures
        int curTower = towerIdx;
        int curLevel = level;
        int curWpm = wpmIdx;
        int curEnemy = enemyIdx;

        // Tower type row
        var towerRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        towerRow.Widgets.Add(MakeFieldLabel("Tower:"));
        var prevTowerBtn = MakeNavButton("<", () =>
        {
            SetByTag(tag, "tower", (curTower - 1 + DamageTowerIds.Length) % DamageTowerIds.Length);
            RebuildUi();
        });
        towerRow.Widgets.Add(prevTowerBtn);

        string towerName = TowerTypes.GetTowerName(DamageTowerIds[curTower]);
        towerRow.Widgets.Add(MakeValueLabel(towerName, 160));

        var nextTowerBtn = MakeNavButton(">", () =>
        {
            SetByTag(tag, "tower", (curTower + 1) % DamageTowerIds.Length);
            RebuildUi();
        });
        towerRow.Widgets.Add(nextTowerBtn);
        _outputArea.Widgets.Add(towerRow);

        // Level row
        var levelRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        levelRow.Widgets.Add(MakeFieldLabel("Level:"));
        for (int i = 1; i <= SimBalance.TowerMaxLevel; i++)
        {
            int lv = i;
            var btn = ButtonFactory.Ghost(lv.ToString(), () =>
            {
                SetByTag(tag, "level", lv);
                RebuildUi();
            });
            btn.Width = 36;
            btn.Height = DesignSystem.SizeButtonSm;
            if (lv == curLevel)
            {
                // Highlight selected level
                var lbl = btn.Content as Label;
                if (lbl != null) lbl.TextColor = ThemeColors.Accent;
            }
            levelRow.Widgets.Add(btn);
        }
        _outputArea.Widgets.Add(levelRow);

        // WPM row
        var wpmRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        wpmRow.Widgets.Add(MakeFieldLabel("WPM:"));
        for (int i = 0; i < WpmPresets.Length; i++)
        {
            int idx = i;
            var btn = ButtonFactory.Ghost(WpmPresets[i].Label, () =>
            {
                SetByTag(tag, "wpm", idx);
                RebuildUi();
            });
            btn.Width = 100;
            btn.Height = DesignSystem.SizeButtonSm;
            if (idx == curWpm)
            {
                var lbl = btn.Content as Label;
                if (lbl != null) lbl.TextColor = ThemeColors.Accent;
            }
            wpmRow.Widgets.Add(btn);
        }
        _outputArea.Widgets.Add(wpmRow);

        // Enemy type row
        var enemyRow = new HorizontalStackPanel { Spacing = DesignSystem.SpaceXs };
        enemyRow.Widgets.Add(MakeFieldLabel("Enemy:"));
        var prevEnemyBtn = MakeNavButton("<", () =>
        {
            SetByTag(tag, "enemy", (curEnemy - 1 + EnemyKindIds.Length) % EnemyKindIds.Length);
            RebuildUi();
        });
        enemyRow.Widgets.Add(prevEnemyBtn);

        string enemyName = Capitalize(EnemyKindIds[curEnemy]);
        enemyRow.Widgets.Add(MakeValueLabel(enemyName, 120));

        var nextEnemyBtn = MakeNavButton(">", () =>
        {
            SetByTag(tag, "enemy", (curEnemy + 1) % EnemyKindIds.Length);
            RebuildUi();
        });
        enemyRow.Widgets.Add(nextEnemyBtn);
        _outputArea.Widgets.Add(enemyRow);
    }

    private void SetByTag(string tag, string field, int value)
    {
        if (tag == "A")
        {
            switch (field)
            {
                case "tower": _towerIndexA = value; break;
                case "level": _levelA = value; break;
                case "wpm": _wpmIndexA = value; break;
                case "enemy": _enemyIndexA = value; break;
            }
        }
        else
        {
            switch (field)
            {
                case "tower": _towerIndexB = value; break;
                case "level": _levelB = value; break;
                case "wpm": _wpmIndexB = value; break;
                case "enemy": _enemyIndexB = value; break;
            }
        }
    }

    // =========================================================================
    // DAMAGE CALCULATION (uses real game formulas)
    // =========================================================================

    private DamageResult CalculateSetup(int towerIdx, int level, int wpmIdx, int enemyIdx)
    {
        string towerId = DamageTowerIds[towerIdx];
        var towerDef = TowerTypes.GetTowerData(towerId);
        if (towerDef == null)
            return DamageResult.Empty;

        int wpm = WpmPresets[wpmIdx].Wpm;
        string enemyKind = EnemyKindIds[enemyIdx];
        var enemyDef = Enemies.EnemyKinds.GetValueOrDefault(enemyKind) ?? new EnemyKindDef();

        // Calculate base damage at level using SimBalance formula
        int baseDamage = SimBalance.CalculateTowerDamage(towerDef.Damage, level);

        // Typing speed multiplier from TypingTowerBonuses
        double typingMultiplier = CalculateTypingMultiplier(towerId, wpm);

        // Upgrade bonus multiplier (level scaling factor)
        double upgradeMult = Math.Pow(SimBalance.TowerUpgradeDamageMult, level - 1);

        // Build a simulated enemy dictionary for DamageTypes.CalculateDamage
        var enemyDict = new Dictionary<string, object>
        {
            ["kind"] = enemyKind,
            ["armor"] = enemyDef.Armor,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>(),
        };

        // Calculate damage after armor/type interactions
        int damageAfterArmor = DamageTypes.CalculateDamage(baseDamage, towerDef.DmgType, enemyDict);

        // Apply typing multiplier
        int finalDamage = Math.Max(1, (int)(damageAfterArmor * typingMultiplier));

        // Calculate effective DPS
        float effectiveCooldown = towerDef.Cooldown;
        if (effectiveCooldown <= 0f) effectiveCooldown = 1f;

        // Attack speed bonus from WPM
        double attackSpeedMult = 1.0 + (wpm / 200.0);
        attackSpeedMult = Math.Clamp(attackSpeedMult, 1.0, 2.0);
        float adjustedCooldown = (float)(effectiveCooldown / attackSpeedMult);

        // Multi-target or chain multipliers for DPS
        int effectiveHits = 1;
        if (towerDef.Target == TargetType.Multi)
            effectiveHits = towerDef.TargetCount;
        else if (towerDef.Target == TargetType.Chain)
            effectiveHits = towerDef.ChainCount;

        float dps = finalDamage * effectiveHits / adjustedCooldown;

        // Enemy HP at current game day
        int day = _lastState?.Day ?? 1;
        int threat = _lastState?.Threat ?? 0;
        int enemyHp = SimBalance.CalculateEnemyHp(day, threat) + enemyDef.HpBonus;

        // Time to kill
        float timeToKill = enemyHp / (dps > 0 ? dps : 1f);

        // Overkill
        int overkill = Math.Max(0, finalDamage - enemyHp);

        return new DamageResult
        {
            TowerName = towerDef.Name,
            TowerId = towerId,
            DamageType = towerDef.DmgType,
            BaseDamageRaw = towerDef.Damage,
            BaseDamageAtLevel = baseDamage,
            DamageAfterArmor = damageAfterArmor,
            TypingMultiplier = typingMultiplier,
            UpgradeMultiplier = upgradeMult,
            FinalDamage = finalDamage,
            Dps = dps,
            Cooldown = towerDef.Cooldown,
            AdjustedCooldown = adjustedCooldown,
            EffectiveHits = effectiveHits,
            TargetType = towerDef.Target,
            EnemyName = Capitalize(enemyKind),
            EnemyHp = enemyHp,
            EnemyArmor = enemyDef.Armor,
            TimeToKill = timeToKill,
            Overkill = overkill,
            Level = level,
            Wpm = wpm,
        };
    }

    /// <summary>
    /// Calculates the typing-based damage multiplier for a tower at a given WPM.
    /// Mirrors TypingTowerBonuses logic but uses assumed WPM instead of live metrics.
    /// </summary>
    private static double CalculateTypingMultiplier(string towerId, int wpm)
    {
        // Assume reasonable accuracy based on WPM tier
        double accuracy = wpm switch
        {
            >= 80 => 0.97,
            >= 60 => 0.93,
            >= 40 => 0.88,
            _ => 0.80,
        };

        // Combo count assumption based on WPM
        int combo = wpm switch
        {
            >= 80 => 25,
            >= 60 => 15,
            >= 40 => 8,
            _ => 3,
        };

        // Base combo multiplier (applied to all towers)
        double comboMult = 1.0 + (combo / 10) * 0.1;

        // Tower-specific bonus
        double towerBonus = towerId switch
        {
            TowerTypes.Wordsmith => GetWordsmithBonusCalc(wpm, accuracy),
            TowerTypes.Arcane => GetArcaneBonusCalc(accuracy),
            TowerTypes.Arrow or TowerTypes.Multi => GetAccuracyBonusCalc(accuracy, 0.2),
            TowerTypes.Magic => GetAccuracyBonusCalc(accuracy, 0.3),
            TowerTypes.Frost => GetAccuracyBonusCalc(accuracy, 0.25),
            TowerTypes.Holy or TowerTypes.Purifier => GetPerfectStreakBonusCalc(combo),
            TowerTypes.Tesla => GetChainDamageBonusCalc(combo),
            TowerTypes.Siege => GetSustainedBonusCalc(wpm),
            _ => 1.0,
        };

        return comboMult * towerBonus;
    }

    // Mirror of TypingTowerBonuses.GetWordsmithBonus
    private static double GetWordsmithBonusCalc(int wpm, double accuracy)
    {
        if (accuracy < TypingTowerBonuses.MinAccuracyForBonus) return 1.0;
        double wpmBonus = 1.0 + (wpm / TypingTowerBonuses.WordsmithWpmScale);
        double accMult = Math.Pow(accuracy, TypingTowerBonuses.WordsmithAccuracyPower);
        return wpmBonus * accMult;
    }

    // Mirror of TypingTowerBonuses.GetArcaneBonus
    private static double GetArcaneBonusCalc(double accuracy)
    {
        if (accuracy < TypingTowerBonuses.MinAccuracyForBonus) return 1.0;
        return 1.0 + (accuracy - TypingTowerBonuses.MinAccuracyForBonus)
            * (TypingTowerBonuses.ArcaneMaxAccuracyBonus - 1.0)
            / (1.0 - TypingTowerBonuses.MinAccuracyForBonus);
    }

    // Mirror of TypingTowerBonuses.GetAccuracyBonus
    private static double GetAccuracyBonusCalc(double accuracy, double maxBonus)
    {
        if (accuracy < TypingTowerBonuses.MinAccuracyForBonus) return 1.0;
        return 1.0 + (accuracy - TypingTowerBonuses.MinAccuracyForBonus)
            * maxBonus / (1.0 - TypingTowerBonuses.MinAccuracyForBonus);
    }

    // Mirror of TypingTowerBonuses.GetPerfectStreakBonus
    private static double GetPerfectStreakBonusCalc(int combo)
    {
        // Assume perfect streak roughly equals combo / 2
        int streak = combo / 2;
        return 1.0 + Math.Min(streak * 0.1, 0.5);
    }

    // Mirror of TypingTowerBonuses.GetChainDamageBonus
    private static double GetChainDamageBonusCalc(int combo)
    {
        return 1.0 + Math.Min(combo * 0.02, 0.5);
    }

    // Mirror of TypingTowerBonuses.GetSustainedBonus
    private static double GetSustainedBonusCalc(int wpm)
    {
        // Assume chars/sec from WPM (average 5 chars per word, 60 sec per min)
        double charsPerSec = wpm * 5.0 / 60.0;
        return 1.0 + Math.Min(charsPerSec * 0.05, 0.5);
    }

    // =========================================================================
    // OUTPUT DISPLAY
    // =========================================================================

    private void BuildOutputDisplay(DamageResult r)
    {
        AddStatRow("Tower", $"{r.TowerName} (Lv {r.Level})", ThemeColors.Accent);
        AddStatRow("Damage Type", DamageTypes.DamageTypeToString(r.DamageType), GetDamageTypeColor(r.DamageType));
        AddStatRow("Target Type", r.TargetType.ToString(), ThemeColors.TextDim);
        _outputArea.Widgets.Add(new HorizontalSeparator());

        AddStatRow("Base Damage (raw)", r.BaseDamageRaw.ToString(), ThemeColors.Text);
        AddStatRow("Upgrade Bonus", $"x{r.UpgradeMultiplier:F2}", r.UpgradeMultiplier > 1.0 ? ThemeColors.Success : ThemeColors.Text);
        AddStatRow("Base Damage (at level)", r.BaseDamageAtLevel.ToString(), ThemeColors.AccentBlue);
        AddStatRow("After Armor", r.DamageAfterArmor.ToString(), r.DamageAfterArmor < r.BaseDamageAtLevel ? ThemeColors.Error : ThemeColors.Text);
        AddStatRow("Typing Speed Bonus", $"x{r.TypingMultiplier:F2}", GetMultiplierColor(r.TypingMultiplier));
        AddStatRow("Final Damage/Hit", r.FinalDamage.ToString(), ThemeColors.Accent);
        _outputArea.Widgets.Add(new HorizontalSeparator());

        AddStatRow("Cooldown", $"{r.AdjustedCooldown:F2}s (base {r.Cooldown:F1}s)", ThemeColors.TextDim);
        if (r.EffectiveHits > 1)
            AddStatRow("Hits/Attack", r.EffectiveHits.ToString(), ThemeColors.AccentCyan);
        AddStatRow("Total DPS", $"{r.Dps:F1}", GetDpsColor(r.Dps));
        _outputArea.Widgets.Add(new HorizontalSeparator());

        AddStatRow("Enemy", $"{r.EnemyName} ({r.EnemyHp} HP, {r.EnemyArmor} Armor)", ThemeColors.Error);
        AddStatRow("Time to Kill", $"{r.TimeToKill:F1}s", GetTtkColor(r.TimeToKill));

        if (r.Overkill > 0)
            AddStatRow("Overkill", $"+{r.Overkill} HP", ThemeColors.Success);
        else
            AddStatRow("Overkill", "None (multi-hit needed)", ThemeColors.TextDim);
    }

    private void BuildComparisonDisplay(DamageResult a, DamageResult b)
    {
        AddCompHeader("", "Setup A", "Setup B");
        _outputArea.Widgets.Add(new HorizontalSeparator());

        AddCompRow("Tower", $"{a.TowerName} Lv{a.Level}", $"{b.TowerName} Lv{b.Level}");
        AddCompRow("Damage Type",
            DamageTypes.DamageTypeToString(a.DamageType),
            DamageTypes.DamageTypeToString(b.DamageType));
        AddCompRow("WPM", a.Wpm.ToString(), b.Wpm.ToString());
        _outputArea.Widgets.Add(new HorizontalSeparator());

        AddCompRowCompare("Base Dmg", a.BaseDamageAtLevel, b.BaseDamageAtLevel);
        AddCompRowCompare("After Armor", a.DamageAfterArmor, b.DamageAfterArmor);
        AddCompRowCompareF("Typing Bonus", a.TypingMultiplier, b.TypingMultiplier, "x");
        AddCompRowCompare("Final Dmg/Hit", a.FinalDamage, b.FinalDamage);
        AddCompRowCompareF("DPS", a.Dps, b.Dps);
        _outputArea.Widgets.Add(new HorizontalSeparator());

        AddCompRow("Enemy",
            $"{a.EnemyName} ({a.EnemyHp} HP)",
            $"{b.EnemyName} ({b.EnemyHp} HP)");
        AddCompRowCompareFInverse("Time to Kill", a.TimeToKill, b.TimeToKill, "s");

        if (a.Overkill > 0 || b.Overkill > 0)
            AddCompRowCompare("Overkill", a.Overkill, b.Overkill);
    }

    // =========================================================================
    // COMPARISON ROW HELPERS
    // =========================================================================

    private void AddCompHeader(string label, string colA, string colB)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        row.Widgets.Add(new Label { Text = label, TextColor = ThemeColors.TextDim, Width = 130 });
        row.Widgets.Add(new Label { Text = colA, TextColor = ThemeColors.AccentCyan, Width = 180 });
        row.Widgets.Add(new Label { Text = colB, TextColor = ThemeColors.AccentBlue, Width = 180 });
        _outputArea.Widgets.Add(row);
    }

    private void AddCompRow(string label, string valA, string valB)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        row.Widgets.Add(new Label { Text = label, TextColor = ThemeColors.TextDim, Width = 130 });
        row.Widgets.Add(new Label { Text = valA, TextColor = ThemeColors.Text, Width = 180 });
        row.Widgets.Add(new Label { Text = valB, TextColor = ThemeColors.Text, Width = 180 });
        _outputArea.Widgets.Add(row);
    }

    private void AddCompRowCompare(string label, int valA, int valB)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        row.Widgets.Add(new Label { Text = label, TextColor = ThemeColors.TextDim, Width = 130 });

        Color colorA = valA > valB ? ThemeColors.Success : valA < valB ? ThemeColors.Error : ThemeColors.Text;
        Color colorB = valB > valA ? ThemeColors.Success : valB < valA ? ThemeColors.Error : ThemeColors.Text;

        row.Widgets.Add(new Label { Text = valA.ToString(), TextColor = colorA, Width = 180 });
        row.Widgets.Add(new Label { Text = valB.ToString(), TextColor = colorB, Width = 180 });
        _outputArea.Widgets.Add(row);
    }

    private void AddCompRowCompareF(string label, double valA, double valB, string suffix = "")
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        row.Widgets.Add(new Label { Text = label, TextColor = ThemeColors.TextDim, Width = 130 });

        Color colorA = valA > valB + 0.01 ? ThemeColors.Success : valA < valB - 0.01 ? ThemeColors.Error : ThemeColors.Text;
        Color colorB = valB > valA + 0.01 ? ThemeColors.Success : valB < valA - 0.01 ? ThemeColors.Error : ThemeColors.Text;

        row.Widgets.Add(new Label { Text = $"{suffix}{valA:F2}", TextColor = colorA, Width = 180 });
        row.Widgets.Add(new Label { Text = $"{suffix}{valB:F2}", TextColor = colorB, Width = 180 });
        _outputArea.Widgets.Add(row);
    }

    /// <summary>Lower is better (e.g., time to kill).</summary>
    private void AddCompRowCompareFInverse(string label, double valA, double valB, string suffix = "")
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceSm };
        row.Widgets.Add(new Label { Text = label, TextColor = ThemeColors.TextDim, Width = 130 });

        Color colorA = valA < valB - 0.01 ? ThemeColors.Success : valA > valB + 0.01 ? ThemeColors.Error : ThemeColors.Text;
        Color colorB = valB < valA - 0.01 ? ThemeColors.Success : valB > valA + 0.01 ? ThemeColors.Error : ThemeColors.Text;

        row.Widgets.Add(new Label { Text = $"{valA:F1}{suffix}", TextColor = colorA, Width = 180 });
        row.Widgets.Add(new Label { Text = $"{valB:F1}{suffix}", TextColor = colorB, Width = 180 });
        _outputArea.Widgets.Add(row);
    }

    // =========================================================================
    // UI ELEMENT HELPERS
    // =========================================================================

    private void AddSectionHeader(string title)
    {
        _outputArea.Widgets.Add(new Panel { Height = DesignSystem.SpaceXs });
        _outputArea.Widgets.Add(new Label { Text = title, TextColor = ThemeColors.Accent });
        _outputArea.Widgets.Add(new HorizontalSeparator());
    }

    private void AddStatRow(string label, string value, Color valueColor)
    {
        var row = new HorizontalStackPanel { Spacing = DesignSystem.SpaceMd };
        row.Widgets.Add(new Label { Text = label, TextColor = ThemeColors.TextDim, Width = 200 });
        row.Widgets.Add(new Label { Text = value, TextColor = valueColor });
        _outputArea.Widgets.Add(row);
    }

    private static Label MakeFieldLabel(string text)
        => new() { Text = text, TextColor = ThemeColors.TextDim, Width = 60 };

    private static Label MakeValueLabel(string text, int width)
        => new() { Text = text, TextColor = ThemeColors.Text, Width = width, HorizontalAlignment = HorizontalAlignment.Center };

    private static Button MakeNavButton(string text, Action onClick)
    {
        var btn = ButtonFactory.Ghost(text, onClick);
        btn.Width = 32;
        btn.Height = DesignSystem.SizeButtonSm;
        return btn;
    }

    // =========================================================================
    // COLOR HELPERS
    // =========================================================================

    private static Color GetMultiplierColor(double mult)
    {
        if (mult >= 1.5) return ThemeColors.Success;
        if (mult >= 1.1) return ThemeColors.AccentCyan;
        return ThemeColors.Text;
    }

    private static Color GetDpsColor(float dps)
    {
        if (dps >= 10f) return ThemeColors.Success;
        if (dps >= 5f) return ThemeColors.AccentCyan;
        if (dps >= 2f) return ThemeColors.Warning;
        return ThemeColors.Error;
    }

    private static Color GetTtkColor(float ttk)
    {
        if (ttk <= 1f) return ThemeColors.Success;
        if (ttk <= 3f) return ThemeColors.AccentCyan;
        if (ttk <= 6f) return ThemeColors.Warning;
        return ThemeColors.Error;
    }

    private static Color GetDamageTypeColor(DamageType dt) => dt switch
    {
        DamageType.Physical => ThemeColors.Text,
        DamageType.Magical => ThemeColors.AccentBlue,
        DamageType.Holy => ThemeColors.Accent,
        DamageType.Lightning => ThemeColors.AccentCyan,
        DamageType.Poison => ThemeColors.Success,
        DamageType.Cold => ThemeColors.Info,
        DamageType.Fire => ThemeColors.Error,
        DamageType.Siege => ThemeColors.Warning,
        DamageType.Pure => ThemeColors.RarityLegendary,
        _ => ThemeColors.Text,
    };

    private static string Capitalize(string s)
        => string.IsNullOrEmpty(s) ? s : char.ToUpper(s[0]) + s[1..];

    // =========================================================================
    // RESULT DATA
    // =========================================================================

    private struct DamageResult
    {
        public string TowerName;
        public string TowerId;
        public DamageType DamageType;
        public int BaseDamageRaw;
        public int BaseDamageAtLevel;
        public int DamageAfterArmor;
        public double TypingMultiplier;
        public double UpgradeMultiplier;
        public int FinalDamage;
        public float Dps;
        public float Cooldown;
        public float AdjustedCooldown;
        public int EffectiveHits;
        public TargetType TargetType;
        public string EnemyName;
        public int EnemyHp;
        public int EnemyArmor;
        public float TimeToKill;
        public int Overkill;
        public int Level;
        public int Wpm;

        public static DamageResult Empty => new()
        {
            TowerName = "Unknown",
            TowerId = "",
            EnemyName = "Unknown",
        };
    }
}
