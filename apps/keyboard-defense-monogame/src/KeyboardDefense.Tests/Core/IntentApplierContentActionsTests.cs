using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Tests.Core;

[Collection("UpgradesSerial")]
public class IntentApplierContentActionsTests
{
    private static readonly FieldInfo KingdomUpgradesField =
        typeof(Upgrades).GetField("_kingdomUpgrades", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access Upgrades kingdom cache.");

    private static readonly FieldInfo UnitUpgradesField =
        typeof(Upgrades).GetField("_unitUpgrades", BindingFlags.NonPublic | BindingFlags.Static)
        ?? throw new InvalidOperationException("Could not access Upgrades unit cache.");

    [Fact]
    public void LessonShow_ReportsCurrentLessonId()
    {
        var state = CreateState();
        state.LessonId = "custom_lesson";

        var (_, events) = Apply(state, "lesson_show");

        Assert.Equal("Current lesson: custom_lesson", Assert.Single(events));
    }

    [Fact]
    public void LessonSet_MissingId_ReportsValidationError()
    {
        var state = CreateState();
        state.LessonId = "before";

        var (newState, events) = Apply(state, "lesson_set");

        Assert.Equal("before", newState.LessonId);
        Assert.Equal("No lesson ID specified.", Assert.Single(events));
    }

    [Fact]
    public void LessonSet_WithId_UpdatesLesson()
    {
        var state = CreateState();

        var (newState, events) = Apply(state, "lesson_set", new()
        {
            ["lesson_id"] = "after"
        });

        Assert.Equal("after", newState.LessonId);
        Assert.Equal("Lesson set to: after", Assert.Single(events));
    }

    [Fact]
    public void LessonNextAndPrev_EitherCycleOrReportNoLessons()
    {
        var state = CreateState();
        string before = state.LessonId;

        var (afterNext, nextEvents) = Apply(state, "lesson_next");
        Assert.Single(nextEvents);
        if (nextEvents[0] == "No lessons available.")
            Assert.Equal(before, afterNext.LessonId);
        else
            Assert.StartsWith("Lesson: ", nextEvents[0], StringComparison.Ordinal);

        var (afterPrev, prevEvents) = Apply(afterNext, "lesson_prev");
        Assert.Single(prevEvents);
        if (prevEvents[0] == "No lessons available.")
            Assert.Equal(afterNext.LessonId, afterPrev.LessonId);
        else
            Assert.StartsWith("Lesson: ", prevEvents[0], StringComparison.Ordinal);
    }

    [Fact]
    public void LessonSample_RespectsRequestedCountInOutput()
    {
        var state = CreateState();

        var (_, events) = Apply(state, "lesson_sample", new()
        {
            ["count"] = 4
        });

        string line = Assert.Single(events);
        string prefix = $"Sample words for '{state.LessonId}': ";
        Assert.StartsWith(prefix, line, StringComparison.Ordinal);
        string[] words = line[prefix.Length..].Split(", ", StringSplitOptions.RemoveEmptyEntries);
        Assert.Equal(4, words.Length);
    }

    [Fact]
    public void Enemies_WithAndWithoutEntries_ReportExpectedLines()
    {
        var emptyState = CreateState();
        var (_, emptyEvents) = Apply(emptyState, "enemies");
        Assert.Equal("No enemies on the field.", Assert.Single(emptyEvents));

        var populatedState = CreateState();
        populatedState.Enemies.Add(new Dictionary<string, object>
        {
            ["kind"] = "raider",
            ["word"] = "mist",
            ["hp"] = 3
        });
        populatedState.Enemies.Add(new Dictionary<string, object>
        {
            ["kind"] = "scout",
            ["word"] = "fern",
            ["hp"] = 1
        });

        var (_, populatedEvents) = Apply(populatedState, "enemies");

        Assert.Equal("Enemies (2):", populatedEvents[0]);
        Assert.Contains("  [raider] 'mist' HP:3", populatedEvents);
        Assert.Contains("  [scout] 'fern' HP:1", populatedEvents);
    }

    [Fact]
    public void InteractPoi_EventChoiceAndEventSkip_HandlePendingState()
    {
        var state = CreateState();

        var (noPendingState, interactEvents) = Apply(state, "interact_poi");
        Assert.Equal("No point of interest at cursor. Explore to discover POIs.", Assert.Single(interactEvents));

        var (_, choiceEvents) = Apply(noPendingState, "event_choice", new()
        {
            ["choice_id"] = "0"
        });
        Assert.Equal("No pending event.", Assert.Single(choiceEvents));

        noPendingState.PendingEvent["title"] = "A Fork in the Road";
        noPendingState.PendingEvent["choices"] = new List<object>();

        var (_, pendingInteractEvents) = Apply(noPendingState, "interact_poi");
        Assert.Equal("You already have a pending event. Use 'choice' or 'skip'.", Assert.Single(pendingInteractEvents));

        var (afterSkip, skipEvents) = Apply(noPendingState, "event_skip");
        Assert.Equal("Event skipped.", Assert.Single(skipEvents));
        Assert.Empty(afterSkip.PendingEvent);
    }

    [Fact]
    public void BuyUpgrade_UnknownUpgrade_ReturnsErrorMessage()
    {
        var state = CreateState();
        state.Gold = 999;

        var (newState, events) = Apply(state, "buy_upgrade", new()
        {
            ["category"] = "kingdom",
            ["upgrade_id"] = "missing-upgrade"
        });

        Assert.Equal(999, newState.Gold);
        Assert.Equal("Unknown upgrade.", Assert.Single(events));
    }

    [Fact]
    public void UiUpgrades_UsesOwnedMarkerForPurchasedUpgrade()
    {
        WithUpgrades(
            kingdom: new()
            {
                new Dictionary<string, object>
                {
                    ["id"] = "k-owned",
                    ["name"] = "Owned Upgrade",
                    ["gold_cost"] = 12
                }
            },
            unit: new(),
            action: () =>
            {
                var state = CreateState();
                state.PurchasedKingdomUpgrades.Add("k-owned");

                var (_, events) = Apply(state, "ui_upgrades", new()
                {
                    ["category"] = "kingdom"
                });

                Assert.Equal("Available kingdom upgrades:", events[0]);
                Assert.Contains("  Owned Upgrade [OWNED]", events);
            });
    }

    [Fact]
    public void ResearchShowStartAndCancel_ReflectResearchState()
    {
        var state = CreateState();
        state.Gold = 200;

        var (_, initialShowEvents) = Apply(state, "research_show");
        Assert.Contains("No active research.", initialShowEvents);

        var (afterStart, startEvents) = Apply(state, "research_start", new()
        {
            ["research_id"] = "improved_walls"
        });
        Assert.Equal("improved_walls", afterStart.ActiveResearch);
        Assert.Equal(150, afterStart.Gold);
        Assert.Equal("Research started: improved_walls", Assert.Single(startEvents));

        var (_, activeShowEvents) = Apply(afterStart, "research_show");
        Assert.Contains(activeShowEvents, line => line.StartsWith("Active research: improved_walls", StringComparison.Ordinal));

        var (afterCancel, cancelEvents) = Apply(afterStart, "research_cancel");
        Assert.Equal(string.Empty, afterCancel.ActiveResearch);
        Assert.Equal(0, afterCancel.ResearchProgress);
        Assert.Equal("Research cancelled: improved_walls", Assert.Single(cancelEvents));
    }

    [Fact]
    public void TradeShow_ListsAllResourceKeysAndUsageHint()
    {
        var state = CreateState();
        state.Resources["wood"] = 4;
        state.Resources["stone"] = 5;
        state.Resources["food"] = 6;

        var (_, events) = Apply(state, "trade_show");

        Assert.Equal("Trade rates:", events[0]);
        Assert.Contains("  wood: 4", events);
        Assert.Contains("  stone: 5", events);
        Assert.Contains("  food: 6", events);
        Assert.Equal("Usage: trade <amount> <resource> for <resource>", events[^1]);
    }

    [Fact]
    public void TradeExecute_SuccessAndFailurePaths()
    {
        var state = CreateState();
        state.Resources["wood"] = 6;
        state.Resources["stone"] = 1;

        var (afterSuccess, successEvents) = Apply(state, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 4
        });
        Assert.Equal(2, afterSuccess.Resources["wood"]);
        Assert.Equal(5, afterSuccess.Resources["stone"]);
        Assert.Equal("Traded 4 wood for 4 stone.", Assert.Single(successEvents));

        var (afterFailure, failureEvents) = Apply(afterSuccess, "trade_execute", new()
        {
            ["from_resource"] = "wood",
            ["to_resource"] = "stone",
            ["amount"] = 10
        });
        Assert.Equal(2, afterFailure.Resources["wood"]);
        Assert.Equal(5, afterFailure.Resources["stone"]);
        Assert.Equal("Not enough wood (have 2, need 10).", Assert.Single(failureEvents));
    }

    [Fact]
    public void GatherAtCursor_DayMountain_AddsStoneAndConsumesAp()
    {
        var state = CreateState();
        state.Phase = "day";
        state.Ap = 2;

        var pos = state.CursorPos;
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        state.Terrain[index] = SimMap.TerrainMountain;

        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);

        var (newState, events) = Apply(state, "gather_at_cursor");

        int gained = newState.Resources.GetValueOrDefault("stone", 0) - stoneBefore;
        Assert.Equal(1, newState.Ap);
        Assert.InRange(gained, 1, 3);
        Assert.Contains(events, line =>
            line.StartsWith("Gathered ", StringComparison.Ordinal)
            && line.Contains(" stone from mountain.", StringComparison.Ordinal));
    }

    [Fact]
    public void GatherAtCursor_NightAndNoAp_AreRejected()
    {
        var nightState = CreateState();
        nightState.Phase = "night";
        nightState.Ap = 2;

        var (afterNightAttempt, nightEvents) = Apply(nightState, "gather_at_cursor");
        Assert.Equal(2, afterNightAttempt.Ap);
        Assert.Equal("That action is only available during the day.", Assert.Single(nightEvents));

        var noApState = CreateState();
        noApState.Phase = "day";
        noApState.Ap = 0;

        var (afterNoApAttempt, noApEvents) = Apply(noApState, "gather_at_cursor");
        Assert.Equal(0, afterNoApAttempt.Ap);
        Assert.Equal("No action points remaining. Type 'end' to start the night.", Assert.Single(noApEvents));
    }

    [Fact]
    public void EngageEnemy_ReportsNoRoamingEnemy()
    {
        var state = CreateState();

        var (_, events) = Apply(state, "engage_enemy");

        Assert.Equal("No roaming enemy at cursor position.", Assert.Single(events));
    }

    [Fact]
    public void LootPreviewAndCollectLoot_ReportAndApplyRewards()
    {
        var state = CreateState();

        var (_, noPreviewEvents) = Apply(state, "loot_preview");
        Assert.Equal("No pending loot.", Assert.Single(noPreviewEvents));

        state.LootPending.Add(new Dictionary<string, object>
        {
            ["quality"] = "great",
            ["gold"] = 9,
            ["material"] = "herb",
            ["material_count"] = 2
        });

        var (_, previewEvents) = Apply(state, "loot_preview");
        Assert.Equal("Pending loot:", previewEvents[0]);
        Assert.Contains("  great: 9 gold", previewEvents);

        int goldBefore = state.Gold;
        var (afterCollect, collectEvents) = Apply(state, "collect_loot");
        Assert.Equal(goldBefore + 9, afterCollect.Gold);
        Assert.Equal(2, afterCollect.Inventory["herb"]);
        Assert.Empty(afterCollect.LootPending);
        Assert.Equal("Loot collected!", Assert.Single(collectEvents));

        var (_, noCollectEvents) = Apply(CreateState(), "collect_loot");
        Assert.Equal("No loot to collect.", Assert.Single(noCollectEvents));
    }

    [Fact]
    public void ExpeditionIntents_ListStartCancelStatus_BehaveAsImplemented()
    {
        var state = CreateState();

        var (_, listEvents) = Apply(state, "expeditions_list");
        Assert.Equal("Expeditions are not yet available.", Assert.Single(listEvents));

        var (_, startEvents) = Apply(state, "start_expedition", new()
        {
            ["type"] = "scout"
        });
        Assert.Equal("Expeditions are not yet available.", Assert.Single(startEvents));

        var (_, invalidCancelEvents) = Apply(state, "cancel_expedition", new()
        {
            ["id"] = 0
        });
        Assert.Equal("Invalid expedition ID.", Assert.Single(invalidCancelEvents));

        var (_, emptyStatusEvents) = Apply(state, "expedition_status");
        Assert.Equal("No active expeditions.", Assert.Single(emptyStatusEvents));

        state.ActiveExpeditions.Add(new Dictionary<string, object>
        {
            ["type"] = "scout",
            ["remaining"] = 3
        });

        var (_, statusEvents) = Apply(state, "expedition_status");
        Assert.Equal("Active expeditions:", statusEvents[0]);
        Assert.Contains("  [0] scout: 3 turns remaining", statusEvents);

        var (afterCancel, cancelEvents) = Apply(state, "cancel_expedition", new()
        {
            ["id"] = 0
        });
        Assert.Empty(afterCancel.ActiveExpeditions);
        Assert.Equal("Expedition cancelled.", Assert.Single(cancelEvents));
    }

    [Fact]
    public void HarvestNode_CollectsMappedResourceAndRemovesNode()
    {
        var state = CreateState();
        var pos = state.CursorPos;
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);

        state.ResourceNodes[index] = new Dictionary<string, object>
        {
            ["type"] = "iron",
            ["yield"] = 2
        };
        int stoneBefore = state.Resources.GetValueOrDefault("stone", 0);

        var (newState, events) = Apply(state, "harvest_node", new()
        {
            ["x"] = pos.X,
            ["y"] = pos.Y
        });

        Assert.Equal(stoneBefore + 2, newState.Resources["stone"]);
        Assert.False(newState.ResourceNodes.ContainsKey(index));
        Assert.Equal("Harvested 2 stone from iron node.", Assert.Single(events));
    }

    [Fact]
    public void NodesList_ReportsEmptyAndEnumeratesKnownNodes()
    {
        var emptyState = CreateState();
        emptyState.ResourceNodes.Clear();
        var (_, emptyEvents) = Apply(emptyState, "nodes_list");
        Assert.Equal("No resource nodes discovered.", Assert.Single(emptyEvents));

        var populatedState = CreateState();
        populatedState.ResourceNodes.Clear();
        var pos = populatedState.CursorPos;
        int index = SimMap.Idx(pos.X, pos.Y, populatedState.MapW);
        populatedState.ResourceNodes[index] = new Dictionary<string, object>
        {
            ["type"] = "timber",
            ["yield"] = 1
        };

        var (_, events) = Apply(populatedState, "nodes_list");
        Assert.Equal("Resource nodes (1):", events[0]);
        Assert.Contains($"  ({pos.X},{pos.Y}): timber", events);
    }

    [Fact]
    public void HeroLocaleTitleBadgeAndTargetingIntents_UpdateAndReportExpectedValues()
    {
        string originalLocale = Locale.CurrentLocale;
        try
        {
            var state = CreateState();

            var (_, heroShowEvents) = Apply(state, "hero_show");
            Assert.Equal("No hero selected. Available heroes:", heroShowEvents[0]);
            Assert.Contains(heroShowEvents, line => line.Contains("commander: Commander", StringComparison.Ordinal));

            var (afterHeroSet, heroSetEvents) = Apply(state, "hero_set", new()
            {
                ["hero_id"] = "commander"
            });
            Assert.Equal("commander", afterHeroSet.HeroId);
            Assert.Equal("Hero set to: Commander", Assert.Single(heroSetEvents));

            var (_, activeHeroEvents) = Apply(afterHeroSet, "hero_show");
            Assert.Equal("Active hero: commander", Assert.Single(activeHeroEvents));

            var (afterHeroClear, heroClearEvents) = Apply(afterHeroSet, "hero_clear");
            Assert.Equal(string.Empty, afterHeroClear.HeroId);
            Assert.Equal("Hero cleared.", Assert.Single(heroClearEvents));

            var (_, localeShowEvents) = Apply(state, "locale_show");
            Assert.Contains(localeShowEvents, line => line.StartsWith("Current locale: ", StringComparison.Ordinal));
            Assert.Contains(localeShowEvents, line => line.StartsWith("Supported: ", StringComparison.Ordinal));

            var (_, localeSetEvents) = Apply(state, "locale_set", new()
            {
                ["locale"] = "es"
            });
            Assert.Equal("es", Locale.CurrentLocale);
            Assert.Equal("Locale set to: es", Assert.Single(localeSetEvents));

            var (_, titlesShowEvents) = Apply(state, "titles_show");
            Assert.Contains("Active title: none", titlesShowEvents);
            Assert.Contains("No titles unlocked yet.", titlesShowEvents);

            var (_, lockedEquipEvents) = Apply(state, "title_equip", new()
            {
                ["title_id"] = "champion"
            });
            Assert.Equal("Title 'champion' not unlocked.", Assert.Single(lockedEquipEvents));

            state.UnlockedTitles.Add("champion");
            var (afterEquip, equipEvents) = Apply(state, "title_equip", new()
            {
                ["title_id"] = "champion"
            });
            Assert.Equal("champion", afterEquip.EquippedTitle);
            Assert.Equal("Title equipped: champion", Assert.Single(equipEvents));

            var (afterTitleClear, titleClearEvents) = Apply(afterEquip, "title_clear");
            Assert.Equal(string.Empty, afterTitleClear.EquippedTitle);
            Assert.Equal("Title cleared.", Assert.Single(titleClearEvents));

            state.UnlockedBadges.Add("first_blood");
            state.UnlockedBadges.Add("veteran");
            var (_, badgesEvents) = Apply(state, "badges_show");
            Assert.Equal("Badges: 2 unlocked", badgesEvents[0]);
            Assert.Contains("  first_blood", badgesEvents);
            Assert.Contains("  veteran", badgesEvents);

            var (afterInvalidTargeting, invalidTargetingEvents) = Apply(state, "set_targeting", new()
            {
                ["mode"] = "random"
            });
            Assert.Equal("nearest", afterInvalidTargeting.TargetingMode);
            Assert.StartsWith("Unknown targeting mode: random. Valid:", invalidTargetingEvents[0], StringComparison.Ordinal);

            var (afterValidTargeting, validTargetingEvents) = Apply(state, "set_targeting", new()
            {
                ["mode"] = "fastest"
            });
            Assert.Equal("fastest", afterValidTargeting.TargetingMode);
            Assert.Equal("Targeting mode set to: fastest.", Assert.Single(validTargetingEvents));
        }
        finally
        {
            Locale.SetLocale(originalLocale);
        }
    }

    private static GameState CreateState()
    {
        return DefaultState.Create();
    }

    private static (GameState State, List<string> Events) Apply(
        GameState state,
        string kind,
        Dictionary<string, object>? data = null)
    {
        var result = IntentApplier.Apply(state, SimIntents.Make(kind, data));
        var newState = Assert.IsType<GameState>(result["state"]);
        var events = Assert.IsType<List<string>>(result["events"]);
        return (newState, events);
    }

    private static void WithUpgrades(
        List<Dictionary<string, object>> kingdom,
        List<Dictionary<string, object>> unit,
        Action action)
    {
        object? originalKingdom = KingdomUpgradesField.GetValue(null);
        object? originalUnit = UnitUpgradesField.GetValue(null);

        try
        {
            KingdomUpgradesField.SetValue(null, kingdom);
            UnitUpgradesField.SetValue(null, unit);
            action();
        }
        finally
        {
            KingdomUpgradesField.SetValue(null, originalKingdom);
            UnitUpgradesField.SetValue(null, originalUnit);
        }
    }
}
