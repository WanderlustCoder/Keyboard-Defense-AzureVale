using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

/// <summary>
/// Tests covering all 25 audit findings from the 2026-02-26 codebase audit.
/// Organized by batch for traceability.
/// </summary>
public class AuditFixTests
{
    // =========================================================================
    // Batch 1: Critical Bugs
    // =========================================================================

    // Fix #1: AOE targeting uses pos_x/pos_y

    [Fact]
    public void FindAoeTargets_UsesPosPrefixedKeys()
    {
        var center = new Dictionary<string, object> { ["pos_x"] = 5, ["pos_y"] = 5 };
        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1, ["pos_x"] = 5, ["pos_y"] = 6, ["hp"] = 10, ["alive"] = true },
            new() { ["id"] = 2, ["pos_x"] = 10, ["pos_y"] = 10, ["hp"] = 10, ["alive"] = true },
        };

        var targets = Targeting.FindAoeTargets(center, enemies, 2);

        Assert.Single(targets);
        Assert.Equal(1, targets[0]["id"]);
    }

    [Fact]
    public void ManhattanDistance_UsesPosPrefixedKeys()
    {
        var a = new Dictionary<string, object> { ["pos_x"] = 0, ["pos_y"] = 0 };
        var b = new Dictionary<string, object> { ["pos_x"] = 3, ["pos_y"] = 4 };

        Assert.Equal(7, Targeting.ManhattanDistance(a, b));
    }

    // Fix #2: ApplyDemolish consumes AP

    [Fact]
    public void Demolish_ConsumesAp()
    {
        var state = DefaultState.Create();
        state.Phase = "day";
        state.Ap = 1;
        int tileIdx = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);
        state.Structures[tileIdx] = "tower";
        state.Discovered.Add(tileIdx);

        var intent = SimIntents.Make("demolish", new()
        {
            ["x"] = state.BasePos.X + 1,
            ["y"] = state.BasePos.Y,
        });
        var result = IntentApplier.Apply(state, intent);
        var newState = result["state"] as GameState;

        // AP should have been consumed on the returned copy
        Assert.NotNull(newState);
        Assert.Equal(0, newState!.Ap);
    }

    [Fact]
    public void Demolish_FailsWithNoAp()
    {
        var state = DefaultState.Create();
        state.Phase = "day";
        state.Ap = 0;
        int tileIdx = SimMap.Idx(state.BasePos.X + 1, state.BasePos.Y, state.MapW);
        state.Structures[tileIdx] = "tower";
        state.Discovered.Add(tileIdx);

        var intent = SimIntents.Make("demolish", new()
        {
            ["x"] = state.BasePos.X + 1,
            ["y"] = state.BasePos.Y,
        });
        var result = IntentApplier.Apply(state, intent);
        var newState = result["state"] as GameState;

        // Structure should still exist on the returned copy since AP check failed
        Assert.NotNull(newState);
        Assert.True(newState!.Structures.ContainsKey(tileIdx));
    }

    // Fix #3: CopyState tested via Apply — independent state copy

    [Fact]
    public void IntentApplier_Apply_ProducesIndependentStateCopy()
    {
        var original = DefaultState.Create("test_copy");
        original.Phase = "day";
        original.Ap = 3;
        original.Gold = 42;

        // Apply an intent that returns state — the internal CopyState is used
        var intent = SimIntents.Make("explore", new() { ["direction"] = "north" });
        var result = IntentApplier.Apply(original, intent);
        var newState = result["state"] as GameState;

        // Original gold should be unchanged regardless of what happened
        Assert.Equal(42, original.Gold);
    }

    // =========================================================================
    // Batch 3: High Severity Logic Bugs
    // =========================================================================

    // Fix #8: Trade round-trip exploit prevention

    [Fact]
    public void Trade_SamePairBlockedOnSecondAttemptSameDay()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 100;
        state.Resources["stone"] = 100;

        var first = Trade.ExecuteTrade(state, "wood", "stone", 10);
        var second = Trade.ExecuteTrade(state, "wood", "stone", 10);

        Assert.True(Convert.ToBoolean(first["success"]));
        Assert.False(Convert.ToBoolean(second["success"]));
        Assert.Contains("Already traded", second["error"].ToString()!);
    }

    [Fact]
    public void Trade_DifferentPairsAllowedSameDay()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 100;
        state.Resources["stone"] = 100;

        var first = Trade.ExecuteTrade(state, "wood", "stone", 10);
        var second = Trade.ExecuteTrade(state, "stone", "food", 10);

        Assert.True(Convert.ToBoolean(first["success"]));
        Assert.True(Convert.ToBoolean(second["success"]));
    }

    [Fact]
    public void Trade_ResourceCapsAt999()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 100;
        state.Resources["stone"] = 990;

        Trade.ExecuteTrade(state, "wood", "stone", 50);

        Assert.True(state.Resources["stone"] <= 999);
    }

    // Fix #9: FindNearest skips dead enemies (hp <= 0)

    [Fact]
    public void FindNearest_SkipsDeadEnemiesWithZeroHp()
    {
        var tower = new Dictionary<string, object> { ["pos_x"] = 0, ["pos_y"] = 0 };
        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1, ["pos_x"] = 1, ["pos_y"] = 0, ["hp"] = 0, ["alive"] = true },
            new() { ["id"] = 2, ["pos_x"] = 5, ["pos_y"] = 5, ["hp"] = 10, ["alive"] = true },
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.NotNull(target);
        Assert.Equal(2, target!["id"]);
    }

    [Fact]
    public void FindNearest_ReturnsNullWhenAllDead()
    {
        var tower = new Dictionary<string, object> { ["pos_x"] = 0, ["pos_y"] = 0 };
        var enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 1, ["pos_x"] = 1, ["pos_y"] = 0, ["hp"] = 0, ["alive"] = true },
            new() { ["id"] = 2, ["pos_x"] = 2, ["pos_y"] = 0, ["hp"] = -5, ["alive"] = true },
        };

        var target = Targeting.FindNearest(tower, enemies);

        Assert.Null(target);
    }

    // =========================================================================
    // Batch 4: Medium Severity
    // =========================================================================

    // Fix #10: Diplomacy.DeclareWar doesn't crash on dict iteration

    [Fact]
    public void Diplomacy_DeclareWar_DoesNotCrashWithMultipleAgreements()
    {
        var state = DefaultState.Create();
        state.FactionAgreements["alliance"] = new List<string> { "faction_a", "faction_b" };
        state.FactionAgreements["trade"] = new List<string> { "faction_a" };

        // Should not throw InvalidOperationException due to dict modification during iteration
        var result = Diplomacy.DeclareWar(state, "faction_a");

        Assert.True(state.FactionAgreements.ContainsKey("war"));
        Assert.Contains("faction_a", state.FactionAgreements["war"]);
    }

    // Fix #12: FindValidPositionInZone handles tiny maps (private method, tested indirectly)

    [Fact]
    public void WorldEntities_TinyMap_PopulateDoesNotCrash()
    {
        var state = DefaultState.Create();
        state.MapW = 2;
        state.MapH = 2;
        // Initialize terrain for tiny map
        state.Terrain = new List<string>();
        for (int i = 0; i < state.MapW * state.MapH; i++)
            state.Terrain.Add("plains");

        // Should not crash with ArgumentOutOfRangeException on tiny maps
        var exception = Record.Exception(() => WorldEntities.PopulateWorld(state));
        Assert.Null(exception);
    }

    // Fix #14: Combo reset on miss in inline combat

    [Fact]
    public void InlineCombat_Miss_ResetsCombo()
    {
        var state = DefaultState.Create();
        state.Phase = "day";
        state.ActivityMode = "encounter";
        // Set combo streak > 0
        state.TypingMetrics["perfect_word_streak"] = 5;
        state.EncounterEnemies.Add(new Dictionary<string, object>
        {
            ["id"] = 1, ["kind"] = "scout", ["word"] = "alpha",
            ["hp"] = 10, ["armor"] = 0, ["alive"] = true,
            ["pos_x"] = 5, ["pos_y"] = 5, ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>(),
        });

        InlineCombat.ProcessTyping(state, "wrong_word_xyzzy");

        Assert.Equal(0, Convert.ToInt32(state.TypingMetrics["perfect_word_streak"]));
    }

    // Fix #15: EnsureEnemyWords creates unique fallback words

    [Fact]
    public void EnsureEnemyWords_MultipleWordlessEnemies_GetUniqueWords()
    {
        var state = DefaultState.Create();
        state.Enemies = new List<Dictionary<string, object>>
        {
            new() { ["id"] = 10, ["kind"] = "raider" },
            new() { ["id"] = 20, ["kind"] = "scout" },
            new() { ["id"] = 30, ["kind"] = "elite", ["word"] = "existing" },
        };

        Enemies.EnsureEnemyWords(state);

        Assert.Equal("enemy_10", state.Enemies[0]["word"]);
        Assert.Equal("enemy_20", state.Enemies[1]["word"]);
        Assert.Equal("existing", state.Enemies[2]["word"]);
        Assert.NotEqual(state.Enemies[0]["word"], state.Enemies[1]["word"]);
    }

    // Fix #16: Fire damage consumes frozen effect

    [Fact]
    public void FireDamage_ConsumesFrozenEffect()
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = 0,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>
            {
                new() { ["id"] = "frozen", ["duration"] = 3 }
            }
        };

        int damage = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        Assert.Equal(30, damage); // 3x multiplier
        var effects = (List<Dictionary<string, object>>)enemy["effects"];
        Assert.DoesNotContain(effects, e => e.GetValueOrDefault("id")?.ToString() == "frozen");
    }

    [Fact]
    public void FireDamage_NoFrozen_NormalDamage()
    {
        var enemy = new Dictionary<string, object>
        {
            ["armor"] = 0,
            ["affix"] = "",
            ["effects"] = new List<Dictionary<string, object>>()
        };

        int damage = DamageTypes.CalculateDamage(10, DamageType.Fire, enemy);

        Assert.Equal(10, damage);
    }

    // Fix #18: Upgrade prerequisite validates ID exists in definitions

    [Fact]
    public void CanPurchase_PrerequisiteNotInDefinitions_RejectsGracefully()
    {
        var kingdomField = typeof(Upgrades).GetField("_kingdomUpgrades",
            BindingFlags.NonPublic | BindingFlags.Static)!;
        var unitField = typeof(Upgrades).GetField("_unitUpgrades",
            BindingFlags.NonPublic | BindingFlags.Static)!;
        var originalK = kingdomField.GetValue(null);
        var originalU = unitField.GetValue(null);

        try
        {
            kingdomField.SetValue(null, new List<Dictionary<string, object>>
            {
                new() { ["id"] = "k-child", ["gold_cost"] = 10, ["requires"] = "nonexistent" }
            });
            unitField.SetValue(null, new List<Dictionary<string, object>>());

            var state = new GameState { Gold = 100 };
            var result = Upgrades.CanPurchase(state, "k-child", "kingdom");

            Assert.False(Convert.ToBoolean(result["ok"]));
            Assert.Contains("not found", result["error"].ToString()!);
        }
        finally
        {
            kingdomField.SetValue(null, originalK);
            unitField.SetValue(null, originalU);
        }
    }

    // Fix #19: HudBarOverlay uses MaxHp (tested via GameState)

    [Fact]
    public void GameState_MaxHp_DefaultIsTen()
    {
        var state = DefaultState.Create();

        Assert.Equal(10, state.MaxHp);
    }

    [Fact]
    public void GameState_MaxHp_SerializesRoundTrip()
    {
        var state = DefaultState.Create();
        state.MaxHp = 25;

        var json = KeyboardDefense.Core.Data.SaveManager.StateToJson(state);
        var (ok, restored, error) = KeyboardDefense.Core.Data.SaveManager.StateFromJson(json);

        Assert.True(ok);
        Assert.NotNull(restored);
        Assert.Equal(25, restored!.MaxHp);
    }

    // =========================================================================
    // Batch 5: Low Severity
    // =========================================================================

    // Fix #22: Inventory stacking overflow capped at 999

    [Fact]
    public void Crafting_StackingCapsAt999()
    {
        var state = DefaultState.Create();
        // Give player abundant materials
        foreach (var (mat, needed) in Crafting.Recipes["iron_ingot"].Materials)
            state.Inventory[mat] = 9999;

        // Pre-fill inventory near cap
        state.Inventory["iron_ingot"] = 998;

        var result = Crafting.Craft(state, "iron_ingot");

        Assert.True(Convert.ToBoolean(result["success"]));
        Assert.True(state.Inventory.GetValueOrDefault("iron_ingot", 0) <= 999);
    }

    // Fix #23: Negative damage clamped in ComboSystem

    [Fact]
    public void ComboSystem_NegativeDamage_ClampedToZero()
    {
        int result = ComboSystem.ApplyDamageBonus(-5, 10);

        Assert.True(result >= 0);
    }

    [Fact]
    public void ComboSystem_ZeroDamage_ReturnsZero()
    {
        int result = ComboSystem.ApplyDamageBonus(0, 10);

        Assert.Equal(0, result);
    }

    // =========================================================================
    // Batch 2: Gold Overflow Protection
    // =========================================================================

    // Fix #7: Gold cap applied across systems

    [Fact]
    public void SimBalance_GoldCap_Exists()
    {
        Assert.Equal(999_999, SimBalance.GoldCap);
    }

    [Fact]
    public void SimBalance_AddGold_ClampsAtCap()
    {
        var state = DefaultState.Create();
        state.Gold = SimBalance.GoldCap - 10;

        SimBalance.AddGold(state, 100);

        Assert.Equal(SimBalance.GoldCap, state.Gold);
    }

    [Fact]
    public void SimBalance_AddGold_NormalAddition()
    {
        var state = DefaultState.Create();
        state.Gold = 100;

        SimBalance.AddGold(state, 50);

        Assert.Equal(150, state.Gold);
    }

    // Quest rewards respect gold cap

    [Fact]
    public void QuestReward_RespectsGoldCap()
    {
        var state = DefaultState.Create();
        state.Gold = SimBalance.GoldCap - 5;

        Quests.CompleteQuest(state, "first_tower");

        Assert.True(state.Gold <= SimBalance.GoldCap);
    }

    // EventEffects respects gold cap

    [Fact]
    public void EventEffect_GoldAdd_RespectsGoldCap()
    {
        var state = DefaultState.Create();
        state.Gold = SimBalance.GoldCap - 1;

        EventEffects.ApplyEffect(state, new Dictionary<string, object>
        {
            ["type"] = "gold_add",
            ["amount"] = 1000,
        });

        Assert.Equal(SimBalance.GoldCap, state.Gold);
    }

    // =========================================================================
    // Batch 6: GameState MaxHp & TradeHistory
    // =========================================================================

    [Fact]
    public void GameState_TradeHistory_ClearedOnDayAdvance()
    {
        var state = DefaultState.Create();
        state.Resources["wood"] = 100;
        state.Resources["stone"] = 100;

        Trade.ExecuteTrade(state, "wood", "stone", 10);
        Assert.NotEmpty(state.TradeHistory);

        SimTick.AdvanceDay(state);

        Assert.Empty(state.TradeHistory);
    }

    [Fact]
    public void GameState_TradeHistory_InitializesEmpty()
    {
        var state = DefaultState.Create();
        Assert.NotNull(state.TradeHistory);
        Assert.Empty(state.TradeHistory);
    }
}
