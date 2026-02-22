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
    public static GameController Instance => _instance ??= new();

    public GameState State { get; private set; }
    public List<string> LastEvents { get; } = new();

    public event Action<GameState>? StateChanged;
    public event Action<List<string>>? EventsEmitted;

    public GameController()
    {
        State = DefaultState.Create("default", true, useWorldSpec: true);
        SaveService.MigrateLegacySaves();
        TypingProfile.Instance.Load(SaveService.GetSavesDir());
        LessonProgress.Instance.Load(SaveService.GetSavesDir());
    }

    public void NewGame(string seed = "default")
    {
        State = DefaultState.Create(seed, true, useWorldSpec: true);
        LastEvents.Clear();
        LastEvents.Add($"New game started with seed '{seed}'.");
        StateChanged?.Invoke(State);
        EventsEmitted?.Invoke(LastEvents);
    }

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

    public void ApplyCommand(string command)
    {
        var intent = CommandParser.Parse(command);
        ApplyIntent(intent);
    }

    public void SaveTypingProfile()
    {
        TypingProfile.Instance.Save(SaveService.GetSavesDir());
        LessonProgress.Instance.Save(SaveService.GetSavesDir());
    }

    public void SaveGame() => SaveGame(0);

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

    public bool LoadGame() => LoadGame(0);

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

    public static string? GetSlotInfo(int slot)
    {
        return SaveService.ReadMeta(slot);
    }

    public static bool HasAnySave()
    {
        return SaveService.HasAnySave();
    }
}
