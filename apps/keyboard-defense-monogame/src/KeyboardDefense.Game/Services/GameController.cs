using System;
using System.Collections.Generic;
using KeyboardDefense.Core.Data;
using KeyboardDefense.Core.Intent;
using KeyboardDefense.Core.State;
using KeyboardDefense.Core.Typing;

namespace KeyboardDefense.Game.Services;

/// <summary>
/// Central game controller that owns the GameState and processes intents.
/// Ported from scripts/GameController.gd.
/// </summary>
public class GameController
{
    private static GameController? _instance;
    /// <summary>
    /// Gets the shared controller instance used by screens and services at runtime.
    /// </summary>
    public static GameController Instance => _instance ??= new();

    /// <summary>
    /// Gets the current deterministic game state snapshot being presented and mutated.
    /// </summary>
    public GameState State { get; private set; }
    /// <summary>
    /// Gets the most recent gameplay events emitted by the last applied action.
    /// </summary>
    public List<string> LastEvents { get; } = new();

    /// <summary>
    /// Raised after state transitions so listeners can refresh UI and dependent systems.
    /// </summary>
    public event Action<GameState>? StateChanged;
    /// <summary>
    /// Raised after commands or intents to expose user-facing event messages.
    /// </summary>
    public event Action<List<string>>? EventsEmitted;

    /// <summary>
    /// Initializes a controller with default state and loads persisted typing progression data.
    /// Call this during game startup before any gameplay screens begin issuing actions.
    /// </summary>
    public GameController()
    {
        State = DefaultState.Create("default", true, useWorldSpec: true);
        SaveService.MigrateLegacySaves();
        TypingProfile.Instance.Load(SaveService.GetSavesDir());
        LessonProgress.Instance.Load(SaveService.GetSavesDir());
    }

    /// <summary>
    /// Starts a fresh run using the specified seed and notifies listeners of the reset state.
    /// Call this when beginning a new campaign from menus or restart flows.
    /// </summary>
    public void NewGame(string seed = "default")
    {
        State = DefaultState.Create(seed, true, useWorldSpec: true);
        LastEvents.Clear();
        LastEvents.Add($"New game started with seed '{seed}'.");
        StateChanged?.Invoke(State);
        EventsEmitted?.Invoke(LastEvents);
    }

    /// <summary>
    /// Applies a parsed intent to the current state, handles save requests, and emits updates.
    /// Call this after input has already been transformed into an intent payload.
    /// </summary>
    public void ApplyIntent(Dictionary<string, object> intent)
    {
        var result = IntentApplier.Apply(State, intent);

        if (result.TryGetValue("state", out var stateObj) && stateObj is GameState newState)
            State = newState;

        LastEvents.Clear();
        if (result.TryGetValue("events", out var eventsObj) && eventsObj is List<string> events)
            LastEvents.AddRange(events);

        // Handle autosave requests
        if (result.TryGetValue("request", out var reqObj) && reqObj is Dictionary<string, object> request)
        {
            string kind = request.GetValueOrDefault("kind")?.ToString() ?? "";
            if (kind == "save" || kind == "autosave")
                SaveGame();
        }

        StateChanged?.Invoke(State);
        EventsEmitted?.Invoke(LastEvents);
    }

    /// <summary>
    /// Parses a text command and applies the resulting intent to the current game state.
    /// Call this from command-driven UI or debug input paths that submit raw command text.
    /// </summary>
    public void ApplyCommand(string command)
    {
        var intent = CommandParser.Parse(command);
        ApplyIntent(intent);
    }

    /// <summary>
    /// Persists typing profile and lesson progress data independently of full game saves.
    /// Call this when leaving typing-related flows or before shutdown to keep progression current.
    /// </summary>
    public void SaveTypingProfile()
    {
        TypingProfile.Instance.Save(SaveService.GetSavesDir());
        LessonProgress.Instance.Save(SaveService.GetSavesDir());
    }

    /// <summary>
    /// Saves the current game state to the default slot.
    /// Call this for generic save actions when no explicit slot selection is provided.
    /// </summary>
    public void SaveGame() => SaveGame(0);

    /// <summary>
    /// Saves the current game state and metadata to the specified save slot.
    /// Call this for manual save UI, autosave handling, or slot-specific save workflows.
    /// </summary>
    public void SaveGame(int slot)
    {
        try
        {
            string json = SaveManager.StateToJson(State);
            // Also save typing profile alongside game save
            SaveService.EnsureSaveDirectory();
            TypingProfile.Instance.Save(SaveService.GetSavesDir());
            SaveService.WriteSlot(slot, json);

            // Write metadata for the slot
            var meta = new
            {
                day = State.Day,
                phase = State.Phase,
                gold = State.Gold,
                hp = State.Hp,
                savedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm"),
            };
            string metaJson = Newtonsoft.Json.JsonConvert.SerializeObject(meta);
            SaveService.WriteMeta(slot, metaJson);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"SaveGame failed: {ex.Message}");
        }
    }

    /// <summary>
    /// Loads game data from the default slot.
    /// Call this for quick-continue flows that use the primary save slot.
    /// </summary>
    public bool LoadGame() => LoadGame(0);

    /// <summary>
    /// Loads game data from the specified slot and broadcasts resulting state or failure events.
    /// Call this from continue/load-game screens after the player selects a slot.
    /// </summary>
    public bool LoadGame(int slot)
    {
        string? json = SaveService.ReadSlot(slot);
        if (json == null) return false;

        var (ok, loadedState, error) = SaveManager.StateFromJson(json);
        if (!ok || loadedState == null)
        {
            LastEvents.Clear();
            LastEvents.Add($"Failed to load save: {error}");
            EventsEmitted?.Invoke(LastEvents);
            return false;
        }

        State = loadedState;
        LastEvents.Clear();
        LastEvents.Add("Game loaded.");
        StateChanged?.Invoke(State);
        EventsEmitted?.Invoke(LastEvents);
        return true;
    }

    /// <summary>
    /// Gets serialized metadata for a save slot, if present.
    /// Call this when populating load/save menus with slot summary details.
    /// </summary>
    public static string? GetSlotInfo(int slot)
    {
        return SaveService.ReadMeta(slot);
    }

    /// <summary>
    /// Determines whether any save data exists across available slots.
    /// Call this to decide whether continue/load options should be enabled in menus.
    /// </summary>
    public static bool HasAnySave()
    {
        return SaveService.HasAnySave();
    }
}
