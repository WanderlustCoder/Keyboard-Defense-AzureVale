using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.Intent;

public static partial class IntentApplier
{
    // --- Lessons ---
    private static void ApplyLessonShow(GameState state, List<string> events)
    {
        events.Add($"Current lesson: {state.LessonId}");
    }

    private static void ApplyLessonSet(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string lessonId = intent.GetValueOrDefault("lesson_id")?.ToString() ?? "";
        if (string.IsNullOrEmpty(lessonId))
        {
            events.Add("No lesson ID specified.");
            return;
        }
        state.LessonId = lessonId;
        events.Add($"Lesson set to: {lessonId}");
    }

    private static void ApplyLessonCycle(GameState state, int direction, List<string> events)
    {
        var ids = LessonsData.LessonIds();
        if (ids.Count == 0)
        {
            events.Add("No lessons available.");
            return;
        }
        var idsList = new List<string>(ids);
        int idx = idsList.IndexOf(state.LessonId);
        idx = (idx + direction + ids.Count) % ids.Count;
        state.LessonId = ids[idx];
        events.Add($"Lesson: {state.LessonId}");
    }

    private static void ApplyLessonSample(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        int count = Convert.ToInt32(intent.GetValueOrDefault("count", 3));
        var words = new List<string>();
        var used = new HashSet<string>();
        for (int i = 0; i < count; i++)
        {
            string word = WordPool.WordForEnemy(state.RngSeed, state.Day, "raider", i + 1, used, state.LessonId);
            words.Add(word);
            used.Add(word);
        }
        events.Add($"Sample words for '{state.LessonId}': {string.Join(", ", words)}");
    }

    // --- Enemies ---
    private static void ApplyEnemies(GameState state, List<string> events)
    {
        if (state.Enemies.Count == 0)
        {
            events.Add("No enemies on the field.");
            return;
        }
        events.Add($"Enemies ({state.Enemies.Count}):");
        foreach (var enemy in state.Enemies)
        {
            string word = enemy.GetValueOrDefault("word")?.ToString() ?? "???";
            int hp = Convert.ToInt32(enemy.GetValueOrDefault("hp", 0));
            string kind = enemy.GetValueOrDefault("kind")?.ToString() ?? "unknown";
            events.Add($"  [{kind}] '{word}' HP:{hp}");
        }
    }

    // --- POI / Events ---
    private static void ApplyInteractPoi(GameState state, List<string> events)
    {
        if (state.PendingEvent.Count > 0)
        {
            events.Add("You already have a pending event. Use 'choice' or 'skip'.");
            return;
        }
        events.Add("No point of interest at cursor. Explore to discover POIs.");
    }

    private static void ApplyEventChoice(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        if (state.PendingEvent.Count == 0)
        {
            events.Add("No pending event.");
            return;
        }
        int choiceIndex = 0;
        string choiceId = intent.GetValueOrDefault("choice_id")?.ToString() ?? "0";
        int.TryParse(choiceId, out choiceIndex);
        var result = Events.ResolveChoice(state, choiceIndex);
        string message = result.GetValueOrDefault("message")?.ToString() ?? result.GetValueOrDefault("error")?.ToString() ?? "Choice resolved.";
        events.Add(message);
    }

    private static void ApplyEventSkip(GameState state, List<string> events)
    {
        if (state.PendingEvent.Count == 0)
        {
            events.Add("No pending event to skip.");
            return;
        }
        state.PendingEvent.Clear();
        events.Add("Event skipped.");
    }

    // --- Economy ---
    private static void ApplyBuyUpgrade(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string category = intent.GetValueOrDefault("category")?.ToString() ?? "kingdom";
        string upgradeId = intent.GetValueOrDefault("upgrade_id")?.ToString() ?? "";
        var result = Upgrades.Purchase(state, upgradeId, category);
        string message = result.GetValueOrDefault("message")?.ToString() ?? result.GetValueOrDefault("error")?.ToString() ?? "Unknown result.";
        events.Add(message);
    }

    private static void ApplyUiUpgrades(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string category = intent.GetValueOrDefault("category")?.ToString() ?? "kingdom";
        events.Add($"Available {category} upgrades:");
        var upgrades = category == "kingdom" ? Upgrades.GetKingdomUpgrades() : Upgrades.GetUnitUpgrades();
        foreach (var upgrade in upgrades)
        {
            string id = upgrade.GetValueOrDefault("id")?.ToString() ?? "";
            string name = upgrade.GetValueOrDefault("name")?.ToString() ?? id;
            int cost = Convert.ToInt32(upgrade.GetValueOrDefault("gold_cost", 0));
            var purchased = category == "kingdom" ? state.PurchasedKingdomUpgrades : state.PurchasedUnitUpgrades;
            string status = purchased.Contains(id) ? " [OWNED]" : $" ({cost} gold)";
            events.Add($"  {name}{status}");
        }
    }

    private static void ApplyResearchShow(GameState state, List<string> events)
    {
        if (!string.IsNullOrEmpty(state.ActiveResearch))
        {
            events.Add($"Active research: {state.ActiveResearch} (progress: {state.ResearchProgress})");
        }
        else
        {
            events.Add("No active research.");
        }
        var available = ResearchData.GetAvailableResearch(state);
        if (available.Count > 0)
        {
            events.Add("Available:");
            foreach (string id in available)
            {
                var def = ResearchData.GetResearch(id);
                if (def != null)
                    events.Add($"  {def.Name} - {def.GoldCost} gold, {def.WavesRequired} waves");
            }
        }
    }

    private static void ApplyResearchStart(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string researchId = intent.GetValueOrDefault("research_id")?.ToString() ?? "";
        bool success = ResearchData.StartResearch(state, researchId);
        events.Add(success ? $"Research started: {researchId}" : $"Cannot start research: {researchId}");
    }

    private static void ApplyResearchCancel(GameState state, List<string> events)
    {
        if (string.IsNullOrEmpty(state.ActiveResearch))
        {
            events.Add("No active research to cancel.");
            return;
        }
        string cancelled = state.ActiveResearch;
        state.ActiveResearch = "";
        state.ResearchProgress = 0;
        events.Add($"Research cancelled: {cancelled}");
    }

    private static void ApplyTradeShow(GameState state, List<string> events)
    {
        events.Add("Trade rates:");
        foreach (string resource in GameState.ResourceKeys)
        {
            int have = state.Resources.GetValueOrDefault(resource, 0);
            events.Add($"  {resource}: {have}");
        }
        events.Add("Usage: trade <amount> <resource> for <resource>");
    }

    private static void ApplyTradeExecute(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string from = intent.GetValueOrDefault("from_resource")?.ToString() ?? "";
        string to = intent.GetValueOrDefault("to_resource")?.ToString() ?? "";
        int amount = Convert.ToInt32(intent.GetValueOrDefault("amount", 0));
        var result = Trade.ExecuteTrade(state, from, to, amount);
        string message = result.GetValueOrDefault("message")?.ToString() ?? result.GetValueOrDefault("error")?.ToString() ?? "Trade completed.";
        events.Add(message);
    }

    // --- Open-world quick actions ---
    private static void ApplyGatherAtCursor(GameState state, List<string> events)
    {
        if (!RequireDay(state, events)) return;
        if (!ConsumeAp(state, events)) return;
        var pos = state.CursorPos;
        string terrain = SimMap.GetTerrain(state, pos);
        string resource = terrain switch
        {
            SimMap.TerrainForest => "wood",
            SimMap.TerrainMountain => "stone",
            _ => "food"
        };
        int amount = SimRng.RollRange(state, 1, 3);
        state.Resources[resource] = state.Resources.GetValueOrDefault(resource, 0) + amount;
        events.Add($"Gathered {amount} {resource} from {terrain}.");
    }

    private static void ApplyEngageEnemy(GameState state, List<string> events)
    {
        events.Add("No roaming enemy at cursor position.");
    }

    // --- Resource gathering ---
    private static void ApplyLootPreview(GameState state, List<string> events)
    {
        if (state.LootPending.Count == 0)
        {
            events.Add("No pending loot.");
            return;
        }
        events.Add("Pending loot:");
        foreach (var lootEntry in state.LootPending)
        {
            string item = lootEntry.GetValueOrDefault("quality")?.ToString() ?? "unknown";
            int gold = Convert.ToInt32(lootEntry.GetValueOrDefault("gold", 0));
            events.Add($"  {item}: {gold} gold");
        }
    }

    private static void ApplyCollectLoot(GameState state, List<string> events)
    {
        if (state.LootPending.Count == 0)
        {
            events.Add("No loot to collect.");
            return;
        }
        foreach (var lootEntry in state.LootPending)
            Loot.CollectLoot(state, lootEntry);
        state.LootPending.Clear();
        events.Add("Loot collected!");
    }

    private static void ApplyExpeditionsList(GameState state, List<string> events)
    {
        events.Add("Expeditions are not yet available.");
    }

    private static void ApplyStartExpedition(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        events.Add("Expeditions are not yet available.");
    }

    private static void ApplyCancelExpedition(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        int expIdx = Convert.ToInt32(intent.GetValueOrDefault("id", -1));
        if (expIdx < 0 || expIdx >= state.ActiveExpeditions.Count)
        {
            events.Add("Invalid expedition ID.");
            return;
        }
        state.ActiveExpeditions.RemoveAt(expIdx);
        events.Add("Expedition cancelled.");
    }

    private static void ApplyExpeditionStatus(GameState state, List<string> events)
    {
        if (state.ActiveExpeditions.Count == 0)
        {
            events.Add("No active expeditions.");
            return;
        }
        events.Add("Active expeditions:");
        for (int i = 0; i < state.ActiveExpeditions.Count; i++)
        {
            var exp = state.ActiveExpeditions[i];
            string type = exp.GetValueOrDefault("type")?.ToString() ?? "unknown";
            int remaining = Convert.ToInt32(exp.GetValueOrDefault("remaining", 0));
            events.Add($"  [{i}] {type}: {remaining} turns remaining");
        }
    }

    private static void ApplyHarvestNode(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        var pos = IntentPosition(state, intent);
        int index = SimMap.Idx(pos.X, pos.Y, state.MapW);
        if (!state.ResourceNodes.TryGetValue(index, out var node))
        {
            events.Add("No resource node at that location.");
            return;
        }
        string nodeType = node.GetValueOrDefault("type")?.ToString() ?? "unknown";
        int yield = Convert.ToInt32(node.GetValueOrDefault("yield", 1));
        string resource = nodeType switch
        {
            "iron" => "stone",
            "herb" => "food",
            "timber" => "wood",
            _ => "wood"
        };
        state.Resources[resource] = state.Resources.GetValueOrDefault(resource, 0) + yield;
        state.ResourceNodes.Remove(index);
        events.Add($"Harvested {yield} {resource} from {nodeType} node.");
    }

    private static void ApplyNodesList(GameState state, List<string> events)
    {
        if (state.ResourceNodes.Count == 0)
        {
            events.Add("No resource nodes discovered.");
            return;
        }
        events.Add($"Resource nodes ({state.ResourceNodes.Count}):");
        foreach (var (idx, node) in state.ResourceNodes)
        {
            var pos = GridPoint.FromIndex(idx, state.MapW);
            string nodeType = node.GetValueOrDefault("type")?.ToString() ?? "unknown";
            events.Add($"  ({pos.X},{pos.Y}): {nodeType}");
        }
    }

    // --- Hero / Locale / Titles / Badges ---
    private static void ApplyHeroShow(GameState state, List<string> events)
    {
        if (string.IsNullOrEmpty(state.HeroId))
        {
            events.Add("No hero selected. Available heroes:");
            foreach (var (id, def) in HeroTypes.Heroes)
                events.Add($"  {id}: {def.Name} - {def.Description}");
            return;
        }
        events.Add($"Active hero: {state.HeroId}");
    }

    private static void ApplyHeroSet(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string heroId = intent.GetValueOrDefault("hero_id")?.ToString() ?? "";
        state.HeroId = heroId;
        var def = HeroTypes.GetHero(heroId);
        events.Add(def != null ? $"Hero set to: {def.Name}" : $"Hero set to: {heroId}");
    }

    private static void ApplyHeroClear(GameState state, List<string> events)
    {
        state.HeroId = "";
        events.Add("Hero cleared.");
    }

    private static void ApplyLocaleShow(List<string> events)
    {
        events.Add($"Current locale: {Locale.CurrentLocale}");
        events.Add($"Supported: {string.Join(", ", Locale.SupportedLocales)}");
    }

    private static void ApplyLocaleSet(Dictionary<string, object> intent, List<string> events)
    {
        string locale = intent.GetValueOrDefault("locale")?.ToString() ?? "";
        Locale.SetLocale(locale);
        events.Add($"Locale set to: {locale}");
    }

    private static void ApplyTitlesShow(GameState state, List<string> events)
    {
        events.Add($"Active title: {(string.IsNullOrEmpty(state.EquippedTitle) ? "none" : state.EquippedTitle)}");
        if (state.UnlockedTitles.Count > 0)
        {
            events.Add("Unlocked titles:");
            foreach (string title in state.UnlockedTitles)
                events.Add($"  {title}");
        }
        else
        {
            events.Add("No titles unlocked yet.");
        }
    }

    private static void ApplyTitleEquip(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string titleId = intent.GetValueOrDefault("title_id")?.ToString() ?? "";
        if (!state.UnlockedTitles.Contains(titleId))
        {
            events.Add($"Title '{titleId}' not unlocked.");
            return;
        }
        state.EquippedTitle = titleId;
        events.Add($"Title equipped: {titleId}");
    }

    private static void ApplyTitleClear(GameState state, List<string> events)
    {
        state.EquippedTitle = "";
        events.Add("Title cleared.");
    }

    private static void ApplyBadgesShow(GameState state, List<string> events)
    {
        events.Add($"Badges: {state.UnlockedBadges.Count} unlocked");
        foreach (string badge in state.UnlockedBadges)
            events.Add($"  {badge}");
    }

    // --- Tower targeting ---
    private static readonly HashSet<string> ValidTargetingModes = new()
    {
        "nearest", "strongest", "fastest", "weakest", "first"
    };

    private static void ApplySetTargeting(GameState state, Dictionary<string, object> intent, List<string> events)
    {
        string mode = intent.GetValueOrDefault("mode")?.ToString() ?? "";
        if (!ValidTargetingModes.Contains(mode))
        {
            events.Add($"Unknown targeting mode: {mode}. Valid: {string.Join(", ", ValidTargetingModes)}");
            return;
        }
        state.TargetingMode = mode;
        events.Add($"Targeting mode set to: {mode}.");
    }
}
