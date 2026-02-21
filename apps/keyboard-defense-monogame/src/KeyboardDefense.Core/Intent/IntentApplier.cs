using System;
using System.Collections.Generic;
using System.Linq;
using KeyboardDefense.Core.Balance;
using KeyboardDefense.Core.Combat;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Economy;
using KeyboardDefense.Core.Progression;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;
using KeyboardDefense.Core.World;

namespace KeyboardDefense.Core.Intent;

/// <summary>
/// Applies intents to game state, producing new state and events.
/// Ported from sim/apply_intent.gd (~3700 lines).
/// Split into partial class by domain.
/// </summary>
public static partial class IntentApplier
{
    public static Dictionary<string, object> Apply(GameState state, Dictionary<string, object> intent)
    {
        var events = new List<string>();
        var newState = CopyState(state);
        var request = new Dictionary<string, object>();
        string kind = intent.GetValueOrDefault("kind")?.ToString() ?? "";

        switch (kind)
        {
            // --- Core ---
            case "help":
                events.AddRange(SimIntents.HelpLines());
                break;
            case "status":
                events.Add(FormatStatus(newState));
                break;
            case "seed":
                string seedValue = intent.GetValueOrDefault("seed")?.ToString() ?? "";
                SimRng.SeedState(newState, seedValue);
                events.Add($"Seed set to '{seedValue}'.");
                break;

            // --- Day actions ---
            case "gather":
                ApplyGather(newState, intent, events);
                break;
            case "build":
                ApplyBuild(newState, intent, events);
                break;
            case "explore":
                ApplyExplore(newState, events);
                break;
            case "end":
                if (ApplyEnd(newState, events))
                    request = new() { ["kind"] = "autosave", ["reason"] = "night" };
                break;

            // --- Night actions ---
            case "defend_input":
                if (ApplyDefendInput(newState, intent, events))
                    request = new() { ["kind"] = "autosave", ["reason"] = "dawn" };
                break;
            case "wait":
                if (ApplyWait(newState, events))
                    request = new() { ["kind"] = "autosave", ["reason"] = "dawn" };
                break;

            // --- Navigation ---
            case "move_player":
                ApplyMovePlayer(newState, intent, events);
                break;
            case "cursor":
                ApplyCursor(newState, intent, events);
                break;
            case "cursor_move":
                ApplyCursorMove(newState, intent, events);
                break;
            case "inspect":
                ApplyInspect(newState, intent, events);
                break;
            case "map":
                ApplyMap(newState, events);
                break;
            case "zone_show":
                ApplyZoneShow(newState, events);
                break;
            case "zone_summary":
                ApplyZoneSummary(newState, events);
                break;

            // --- Building ---
            case "demolish":
                ApplyDemolish(newState, intent, events);
                break;
            case "upgrade":
                ApplyUpgradeStructure(newState, intent, events);
                break;

            // --- Lessons ---
            case "lesson_show":
                ApplyLessonShow(newState, events);
                break;
            case "lesson_set":
                ApplyLessonSet(newState, intent, events);
                break;
            case "lesson_next":
                ApplyLessonCycle(newState, 1, events);
                break;
            case "lesson_prev":
                ApplyLessonCycle(newState, -1, events);
                break;
            case "lesson_sample":
                ApplyLessonSample(newState, intent, events);
                break;

            // --- Enemies ---
            case "enemies":
                ApplyEnemies(newState, events);
                break;

            // --- POI / Events ---
            case "interact_poi":
                ApplyInteractPoi(newState, events);
                break;
            case "event_choice":
                ApplyEventChoice(newState, intent, events);
                break;
            case "event_skip":
                ApplyEventSkip(newState, events);
                break;

            // --- Economy ---
            case "buy_upgrade":
                ApplyBuyUpgrade(newState, intent, events);
                break;
            case "ui_upgrades":
                ApplyUiUpgrades(newState, intent, events);
                break;
            case "research_show":
                ApplyResearchShow(newState, events);
                break;
            case "research_start":
                ApplyResearchStart(newState, intent, events);
                break;
            case "research_cancel":
                ApplyResearchCancel(newState, events);
                break;
            case "trade_show":
                ApplyTradeShow(newState, events);
                break;
            case "trade_execute":
                ApplyTradeExecute(newState, intent, events);
                break;

            // --- Open-world quick actions ---
            case "inspect_tile":
                ApplyInspectTile(newState, events);
                break;
            case "gather_at_cursor":
                ApplyGatherAtCursor(newState, events);
                break;
            case "engage_enemy":
                ApplyEngageEnemy(newState, events);
                break;

            // --- Resource gathering ---
            case "loot_preview":
                ApplyLootPreview(newState, events);
                break;
            case "collect_loot":
                ApplyCollectLoot(newState, events);
                break;
            case "expeditions_list":
                ApplyExpeditionsList(newState, events);
                break;
            case "start_expedition":
                ApplyStartExpedition(newState, intent, events);
                break;
            case "cancel_expedition":
                ApplyCancelExpedition(newState, intent, events);
                break;
            case "expedition_status":
                ApplyExpeditionStatus(newState, events);
                break;
            case "harvest_node":
                ApplyHarvestNode(newState, intent, events);
                break;
            case "nodes_list":
                ApplyNodesList(newState, events);
                break;

            // --- Hero / Locale / Titles ---
            case "hero_show":
                ApplyHeroShow(newState, events);
                break;
            case "hero_set":
                ApplyHeroSet(newState, intent, events);
                break;
            case "hero_clear":
                ApplyHeroClear(newState, events);
                break;
            case "locale_show":
                ApplyLocaleShow(events);
                break;
            case "locale_set":
                ApplyLocaleSet(intent, events);
                break;
            case "titles_show":
                ApplyTitlesShow(newState, events);
                break;
            case "title_equip":
                ApplyTitleEquip(newState, intent, events);
                break;
            case "title_clear":
                ApplyTitleClear(newState, events);
                break;
            case "badges_show":
                ApplyBadgesShow(newState, events);
                break;

            // --- Tower targeting ---
            case "set_targeting":
                ApplySetTargeting(newState, intent, events);
                break;

            // --- Session ---
            case "restart":
                return ApplyRestart(state, events);
            case "new":
                return ApplyNew(state, events);
            case "save":
                request = new() { ["kind"] = "save" };
                break;
            case "load":
                request = new() { ["kind"] = "load" };
                break;

            // --- UI-only ---
            case "ui_preview":
            {
                string building = intent.GetValueOrDefault("building")?.ToString() ?? "";
                events.Add(string.IsNullOrEmpty(building)
                    ? "Build preview cleared."
                    : $"Build preview set to: {building} (UI-only).");
                break;
            }
            case "ui_overlay":
            {
                string overlayName = intent.GetValueOrDefault("name")?.ToString() ?? "";
                bool enabled = Convert.ToBoolean(intent.GetValueOrDefault("enabled", false));
                events.Add($"{Capitalize(overlayName)} overlay: {(enabled ? "ON" : "OFF")} (UI-only).");
                break;
            }

            default:
                // Pass-through for UI intents that don't mutate state
                if (kind.StartsWith("ui_"))
                    events.Add($"UI action: {kind}");
                else
                    events.Add($"Unknown intent: {kind}");
                break;
        }

        var result = new Dictionary<string, object>
        {
            ["state"] = newState,
            ["events"] = events
        };
        if (request.Count > 0)
            result["request"] = request;
        return result;
    }

    // --- State copy ---
    private static GameState CopyState(GameState source)
    {
        // Deep copy via JSON round-trip for correctness
        string json = SaveManager.StateToJson(source);
        var (ok, copy, _) = SaveManager.StateFromJson(json);
        if (ok && copy != null)
            return copy;
        // Fallback: return source (mutations will affect original)
        return source;
    }

    // --- Common helpers ---
    private static bool RequireDay(GameState state, List<string> events)
    {
        if (state.Phase != "day")
        {
            events.Add("That action is only available during the day.");
            return false;
        }
        return true;
    }

    private static bool ConsumeAp(GameState state, List<string> events)
    {
        if (state.Ap <= 0)
        {
            events.Add("No action points remaining. Type 'end' to start the night.");
            return false;
        }
        state.Ap--;
        return true;
    }

    private static GridPoint IntentPosition(GameState state, Dictionary<string, object> intent)
    {
        if (intent.ContainsKey("x") && intent.ContainsKey("y"))
            return new GridPoint(Convert.ToInt32(intent["x"]), Convert.ToInt32(intent["y"]));
        return state.CursorPos;
    }

    private static bool HasResources(GameState state, Dictionary<string, int> cost)
    {
        foreach (var (resource, amount) in cost)
        {
            if (state.Resources.GetValueOrDefault(resource, 0) < amount)
                return false;
        }
        return true;
    }

    private static void ApplyCost(GameState state, Dictionary<string, int> cost)
    {
        foreach (var (resource, amount) in cost)
        {
            state.Resources[resource] = state.Resources.GetValueOrDefault(resource, 0) - amount;
        }
    }

    private static string FormatStatus(GameState state)
    {
        return $"Day {state.Day} | Phase: {state.Phase} | HP: {state.Hp} | AP: {state.Ap} | Gold: {state.Gold} | Threat: {state.Threat}";
    }

    private static string Capitalize(string s)
    {
        if (string.IsNullOrEmpty(s)) return s;
        return char.ToUpperInvariant(s[0]) + s[1..];
    }
}
